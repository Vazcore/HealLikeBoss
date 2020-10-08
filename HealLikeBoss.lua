local Core = {}
local mmyGuid = UnitGUID("player")
local handlers = {}
local addonName = "HealLikeBoss"
local loaded = false

local settingsFrame = nil

-- Curret Action for Healer
Core.action = nil
Core.started = 0
Core.handlers = handlers

-- Core: Possible Healer Situations
Core.situations = {}
Core.situations.lowDamage = {
  title = "Low Damage"
}
Core.situations.averageDamage = {
  title = "Average Damage"
}
Core.situations.highDamage = {
  title = "High Damage"
}
Core.situations.criticalDamage = {
  title = "Critical Damage"
}

Core.situationPerHealthCorrelation = {
  [80] = "Average Damage",
  [50] = "High Damage",
  [25] = "Critical Damage"
}

Core.targetFrameConfig = {
  width = 200,
  height = 50,
  hWidth = 186,
  hHeight = 40,
  color = {0.2,0.5,1},
  outOfRangeColor = {0.1,0.1,0.1},
  updateTime = 0.5
}

Core.UserDataCheck = function( ... )
  if UserData.cdSpells == nil then
    UserData.cdSpells = {}
  end
end

Core.sortSpellsByPriority = function()
  for k,v in pairs(UserData.spells) do
    table.sort(UserData.spells[k], function( a, b )
      return a.priority < b.priority
    end)
  end

  for k,v in pairs(UserData.bundles) do
    table.sort(UserData.bundles[k], function( a, b )
      return a.priority < b.priority
    end)
  end
end

Core.sortSpellsByPriorityInsideOfBundle = function(bundle)
  table.sort(bundle.spells, function( a, b )
    return a.priority < b.priority
  end)
end

Core.Settings_GetSpellById = function(spId)
  local spell = nil
  for i,v in pairs(UserData.spells) do
    for k,val in pairs(v) do
      if val.spId == spId then
        spell = val
        return spell
      end
    end
  end
  return spell
end

Core.findSpellsInBundle = function( spId, bundle )
  for k,v in pairs(bundle.spells) do
    if v.spId == spId then
      return v
    end
  end
end

Core.findBundleById = function ( id, situation )
  for k,v in pairs(UserData.bundles[situation]) do
    if v.id == id then
      return v
    end
  end
end

Core.findBundleByPriority = function ( priority, situation )
  for k,v in pairs(UserData.bundles[situation]) do
    if v.priority == priority then
      return v
    end
  end
end

function Core_getCore()
  return Core
end

function Core_CheckIfIsRaid()
  local isRaid = UnitHealth("raid1") > 0
  return isRaid
end

local function Core_getPlayerWithLowestHealth( players )
  local lowest = {
    player = nil,
    healthPercent = 100,
    averageHealthPercent = 100
  }
  local countPlayers = 0
  local totalHealthPercent = 0

  for k,v in pairs(players) do
    countPlayers = countPlayers + 1
    local currentHealthPercent = (v.health / v.max_health) * 100
    totalHealthPercent = totalHealthPercent + currentHealthPercent

    if currentHealthPercent <= lowest.healthPercent then
      lowest.player = v
      lowest.healthPercent = currentHealthPercent
    end
  end
  lowest.averageHealthPercent = totalHealthPercent / countPlayers
  return lowest
end

local function Core_GetCurrentSitution( playerInfo )
  local avgHealthPercent = playerInfo.averageHealthPercent
  local situation = "Low Damage"
  for k,v in pairs(Core.situationPerHealthCorrelation) do
    if avgHealthPercent <= k then
      situation = v
    end
  end
  return situation
end

local function Core_getActionForHealer( players )
  local playerWithLowestHealth = Core_getPlayerWithLowestHealth(players)
  local situation = Core_GetCurrentSitution(playerWithLowestHealth)
  return {player = playerWithLowestHealth, situation = situation}
end

local function Core_CreatePlayerData( guid, searchPrefix )
  local health = UnitHealth(searchPrefix)
  local max_health = UnitHealthMax(searchPrefix)
  local name = UnitName(searchPrefix)
  local playerModel = {
    guid = guid,
    searchPrefix = searchPrefix,
    health = health,
    max_health = max_health,
    name = name
  }
  return playerModel
end

local function Core_GetCurrentAction( isRaid )
  local searchPrefix = "party"
  local players_count = 5
  local players = {}
  if isRaid then
    searchPrefix = "raid"
    players_count = 40
  end

  for i=1,players_count do
    local guid = UnitGUID(searchPrefix .. i)
    if guid then
      players[guid] = Core_CreatePlayerData(guid, searchPrefix..i)
    end
  end

  -- Add host player
  players[mmyGuid] = Core_CreatePlayerData(mmyGuid, "player")

  local actionForHealer = Core_getActionForHealer(players)
  Core.action = actionForHealer
  return actionForHealer
end

local function Core_InitKeysMapping(self)
  self:SetAttribute("type1", "spell")
  self:SetAttribute("type2", "spell")
  self:SetAttribute("spell1", "Regrowth")
  self:SetAttribute("spell2", "Power Word: Shield")
  self:RegisterForClicks("AnyDown")
end

local function Core_PickSpell( action )
  for k,v in pairs(UserData.spells[action.situation]) do
    if UserData.cdSpells[v.spId] == nil then
      return v
    end
  end
end

function Core_UpdateSpellLogo( spell )
  Core.CoreFrame.BG:SetTexture(spell.spIcon)
end

local function hideAllBuffs(positions)
  for k,v in pairs(positions) do
    v:SetTexture(nil)
  end
end

local function displayBuffIfExist(positions, spellIcon)
  for k,v in pairs(positions) do
    if v.icon == spellIcon then
      v:SetTexture(spellIcon)
    end
  end
end

local function displayBuffs(self, unitId)
  local i = 1
  local buff = UnitBuff(unitId, i)
  hideAllBuffs(self.positions)
  while buff do
    local name, rank, icon, spellType, duration, unitCaster = UnitBuff(unitId, i)
    displayBuffIfExist(self.positions, rank)
    i = i + 1
    buff = UnitBuff(unitId, i)
  end
end

local function renderAllBuffs(bars)
  for k,v in pairs(bars) do
    if v ~= nil and v.playerData ~= nil then
      displayBuffs(v, v.playerData.searchPrefix)
    end
  end
end

local function updateBuffIcons(bars)
  for i,bar in pairs(bars) do
    for j,pos in pairs(bar.positions) do
      pos.icon = Core.positions[j][6]
    end
  end
end

local function Core_UpdateTagetBars( self, action )
  local isInPartyOrRaid = UILib.isPlayerInPartyOrRaid("player")
  if (isInPartyOrRaid) then
    local searchPrefix = Core_CheckIfIsRaid() and "raid" or "party"
    for k,v in pairs(self.tagetHealthBars) do
      local guid = UnitGUID(searchPrefix .. k)
      if guid then
        local playerData = Core_CreatePlayerData(guid, searchPrefix .. k)
        local healthPercent = (playerData.health / playerData.max_health) * 100
        local width = (Core.targetFrameConfig.hWidth/100) * healthPercent
        local isInRange = UnitInRange(searchPrefix .. k)
        v.playerInfo:SetText(playerData.name .. ", " .. playerData.searchPrefix)
        v.health:SetWidth(width)
        v.playerData = playerData
        v.guid = guid

        if (isInRange == false) then
          v.health:SetColorTexture(unpack(Core.targetFrameConfig.outOfRangeColor))
        else
          v.health:SetColorTexture(unpack(Core.targetFrameConfig.color))
        end
      else
        UILib.print("Error missing: ", self.tagetHealthBars.playerData.name)
      end
    end
  else 
    local playerData = Core_CreatePlayerData(mmyGuid, "player")
    local healthPercent = (playerData.health / playerData.max_health) * 100
    local width = (Core.targetFrameConfig.hWidth/100) * healthPercent
    self.tagetHealthBars[1].playerInfo:SetText(playerData.name)
    self.tagetHealthBars[1].health:SetWidth(width)
    self.tagetHealthBars[1].playerData = playerData
    self.tagetHealthBars[1].guid = mmyGuid
  end

  renderAllBuffs(self.tagetHealthBars)
end

local function Core_OnUpdateBattle( self, elapsed )
  local isRaid = Core_CheckIfIsRaid()
  local currentActionData = Core_GetCurrentAction(isRaid)

  Core_ClearCooldowns()
  Core_UpdateTagetBars(self, currentActionData)
  
  local spell = Core_PickSpell(currentActionData)
  Core_UpdateSpellLogo(spell)
end

local function Core_CreateTargetHealthBar( self, columns, rows )
  local tagetHealthBar = CreateFrame("Button", nil, self, "SecureActionButtonTemplate")

  tagetHealthBar:SetSize(Core.targetFrameConfig.width, Core.targetFrameConfig.height)
  tagetHealthBar:SetPoint("CENTER", UIParent, "CENTER",  columns * (Core.targetFrameConfig.hWidth + 10), Core.targetFrameConfig.height * rows)
  UILib.createBackDrop(tagetHealthBar)

  tagetHealthBar.health = tagetHealthBar:CreateTexture(nil, "ARTWORK")
  tagetHealthBar.health:SetSize(Core.targetFrameConfig.hWidth, Core.targetFrameConfig.hHeight)
  tagetHealthBar.health:SetPoint("LEFT", tagetHealthBar, "TOPLEFT", 7, -25)
  tagetHealthBar.health:SetColorTexture(unpack(Core.targetFrameConfig.color))
  
  tagetHealthBar.playerInfo = UILib.createText(tagetHealthBar, "LEFT", "CENTER", -20, 0, "")

  tagetHealthBar.positions = {}
  for k,v in pairs(Core.positions) do
    local position = UILib.createTexture(tagetHealthBar, "OVERLAY", 20,20, v[4],v[5], 0,0,v[6])
    position.icon = v[6]
    table.insert(tagetHealthBar.positions, position)
  end

  tagetHealthBar.playerData = nil
  tagetHealthBar.guid = nil
 
  RegisterUnitWatch(tagetHealthBar)

  return tagetHealthBar
end

local function updateUnitForHealthBars(self, unitId)
  self:SetAttribute("unit", unitId)
end

local function updateKeyMappingsForHealthBars(healthBars)
  for k,bar in pairs(healthBars) do
    Core_InitKeysMapping(bar)
  end
end

local function renderAllHealthBars(self)
  self.tagetHealthBars = {}
  local rows = 1
  local columns = 1
  local players_count = 40
  local bar = nil
  for i=1, players_count do
    bar = Core_CreateTargetHealthBar(self, columns, rows)
    table.insert(self.tagetHealthBars, bar);
    columns = columns + 1
    if i % 4 == 0 then
      rows = rows + 1
      columns = 1
    end
  end

  updateKeyMappingsForHealthBars(self.tagetHealthBars)
end

local function Core_InitHealthBars(self)
  local isRaid = Core_CheckIfIsRaid();
  local searchPrefix = "party"
  local playerData = nil;
  local players_count = 5
  local count = 1
  local rows = 1
  local columns = 1
  local isInPartyOrRaid = UILib.isPlayerInPartyOrRaid("player")
  if isRaid then
    searchPrefix = "raid"
    players_count = 40
  end

  if isInPartyOrRaid then
    for i=1,players_count do
      local guid = UnitGUID(searchPrefix .. i)
      if guid then
        playerData = Core_CreatePlayerData(guid, searchPrefix..i)
        updateUnitForHealthBars(self.tagetHealthBars[count], playerData.searchPrefix)
        count = count + 1
      end
    end
  else
    -- Add host player
    playerData = Core_CreatePlayerData(mmyGuid, "player")
    updateUnitForHealthBars(self.tagetHealthBars[count], "player")
  end

  updateBuffIcons(self.tagetHealthBars)
end


-----CONSOLE COMMANDS-------

function openMainWidget( self )
  self:Show()
  self.BG:Show()
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  Core.started = 1
  
  Core_InitHealthBars(self)

  local elapsedTime = 0
  local frameRerenderTime = 0
  self:SetScript("OnUpdate", function( self, elapsed )
    elapsedTime = elapsedTime + elapsed
    frameRerenderTime = frameRerenderTime + elapsed
    if elapsedTime > Core.targetFrameConfig.updateTime then
      elapsedTime = 0
      return Core_OnUpdateBattle(self, elapsed)
    end

    if frameRerenderTime > 10 then
      frameRerenderTime = 0
      local isInCombat = InCombatLockdown()
      UILib.print("In Combat", isInCombat)
      if isInCombat == false then
        Core_InitHealthBars(self)
      end
    end
  end)
end

function stopService(self)
  self:Hide()
  self.BG:Hide()
  Core.started = 0
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:SetScript("OnUpdate", nil)
end

local function initConsoleCommands(self)

  SLASH_HEAL_LIKE_BOSS_CONSOLE1 = "/hlkb"
  SLASH_HEAL_LIKE_BOSS_CONSOLE2 = "/heallikeboss"

  SlashCmdList["HEAL_LIKE_BOSS_CONSOLE"] = function( msg )
    local command = msg:match("(%S+)")
    
    if (command == "start") then
      openMainWidget(self)
    elseif command == "settings" then
      UILib.print("Open settings")
      Core.showSettingsWindow()
    elseif command == "stop" then
      stopService(self)
    end

  end

end

------------------------
local function initData()
  UserData = {
    spells = {},
    cdSpells={},
    bundles={}
  }
  Core.UserDataCheck()
end

local function proccessData()
  UILib.print("Data is loaded")
  Core.UserDataCheck()
  
  -- sort by priority
  Core.sortSpellsByPriority()
end

local function printAllArgs( ... )
  local params = {...}
  for k,v in pairs(params) do
    UILib.print(v)
  end
end

function handlers.ADDON_LOADED( self, event, addon )
  if addon == addonName then
    if UserData == nil then
      initData()
    else
      proccessData()
    end

    initConsoleCommands(self)
    renderAllHealthBars(self)
    RenderSpellList()
  end
end

function Core_Update_Cooldowns( spellId, ... )
  local spellName, _, spellIcon = ...
  local currentTime = GetTime()
  local spellModel = Core.Settings_GetSpellById(spellId)

  if (spellModel == nil) then
    local start, duration = GetSpellCooldown(spellId)
    spellModel = {cd = duration}
  end

  UserData.cdSpells[spellId] = currentTime + spellModel.cd
end

function Core_ClearCooldowns()
  local currentTime = GetTime()
  for k,v in pairs(UserData.cdSpells) do
    if (currentTime > v) then
      UserData.cdSpells[k] = nil
    end
  end
end

function handlers.RAID_ROSTER_UPDATE(self, event, ...)
  -- local arg1 = ...
  -- UILib.print(arg1)
end

function handlers.COMBAT_LOG_EVENT_UNFILTERED( self, event, ... )

  local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
  local spellId = select(12, CombatLogGetCurrentEventInfo())

  if (mmyGuid == sourceGUID) then
    --UILib.print(destName)
  end
  

  if (sourceGUID == mmyGuid and subevent == "SPELL_CAST_SUCCESS") then
    local spellName, _, spellIcon = GetSpellInfo(spellId)
    Core_Update_Cooldowns(spellId)
    if Core.Settings_OnSpellSuccess then
      Core.Settings_OnSpellSuccess(spellId, spellName, spellIcon)
    end
  end
end

function allHandlers(self, event, ...)
  return handlers[event](self, event, ...)
end


function Core_RegisterMainEventHandlers(self)
  Core.CoreFrame = self
  
  self:RegisterEvent("ADDON_LOADED")
  self:RegisterEvent("PLAYER_LOGOUT")
  self:RegisterEvent("RAID_ROSTER_UPDATE")
  self:RegisterEvent("PLAYER_LOGIN")
  
  self:SetScript("OnEvent", allHandlers)
  
  self:SetPoint("TOP", UIParent, "TOP")


end









