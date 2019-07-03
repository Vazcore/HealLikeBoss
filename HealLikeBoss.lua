local Core = {}
local mmyGuid = UnitGUID("player")
local handlers = {}
local addonName = "HealLikeBoss"

local settingsFrame = nil

-- Curret Action for Healer
Core.action = nil

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
  color = {0.2,0.5,1}
}

Core.UserDataCheck = function( ... )
  if UserData.cdSpells == nil then
    UserData.cdSpells = {}
  end
end

Core.createBackDrop = function ( frame )
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16, 
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  });
  frame:SetBackdropColor(0,0,0,1);
end

Core.createText = function( ... )
  local parent, pos1, pos2, ox, oy, text = ...

  local t = parent:CreateFontString(nil, "OVERLAY")
  t:SetFontObject("GameFontHighlight")
  t:SetPoint(pos1, parent, pos2, ox, oy)
  t:SetText(text)
  return t
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

Core.createButton = function( ... )
  local parent, pos1, pos2, ox, oy, w, h, text, onClick = ...
  local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  button:SetPoint(pos1, parent, pos2, ox, oy)
  button:SetSize(w, h)
  button:SetText(text)

  if onClick then
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", onClick)
  end
  
  return button
end

Core.createFrame = function ( ... )
  local parent, name, template, pos1, pos2, ox, oy, w, h  = ...
  local frame = CreateFrame("Frame", name, parent, template)
  frame:SetSize(w, h)
  frame:SetPoint(pos1, parent, pos2, ox, oy)

  return frame
end


function Core_getCore()
  return Core
end

function Core_CheckIfIsRaid()
  local isRaid = UnitHealth("raid1") > 0
  return isRaid
end

function Core_getPlayerWithLowestHealth( players )
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

function Core_GetCurrentSitution( playerInfo )
  local avgHealthPercent = playerInfo.averageHealthPercent
  local situation = "Low Damage"
  for k,v in pairs(Core.situationPerHealthCorrelation) do
    if avgHealthPercent <= k then
      situation = v
    end
  end
  return situation
end

function Core_getActionForHealer( players )
  local playerWithLowestHealth = Core_getPlayerWithLowestHealth(players)
  local situation = Core_GetCurrentSitution(playerWithLowestHealth)
  return {player = playerWithLowestHealth, situation = situation}
end

function Core_CreatePlayerData( guid, searchPrefix )
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

function Core_GetCurrentAction( isRaid )
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

function Core_SetClickBehaviour(spell, action)
  if spell then
    Core.tagetHealthBar:SetAttribute("type", "spell")
    Core.tagetHealthBar:SetAttribute("unit", action.player.player.searchPrefix)
    Core.tagetHealthBar:SetAttribute("spell", spell.spName)
  end
end

function Core_PickSpell( action )
  for k,v in pairs(UserData.spells[action.situation]) do
    if UserData.cdSpells[v.spId] == nil then
      return v
    end
  end
end

function Core_UpdateSpellLogo( spell )
  Core.CoreFrame.BG:SetTexture(spell.spIcon)
end

function Core_UpdateTagetBar( action )
  --print(action.player.player.name)
  Core.tagetHealthBar.playerInfo:SetText(action.player.player.name)
  --Core.tagetHealthBar.health:ClearAllPoints();
  local width = (Core.targetFrameConfig.hWidth/100) * action.player.healthPercent
  Core.tagetHealthBar.health:SetWidth(width)
end

function Core_OnUpdateBattle( self, elapsed )
  local isRaid = Core_CheckIfIsRaid()
  local currentActionData = Core_GetCurrentAction(isRaid)

  Core_ClearCooldowns()
  Core_UpdateTagetBar(currentActionData)
  local spell = Core_PickSpell(currentActionData)
  Core_UpdateSpellLogo(spell)
  Core_SetClickBehaviour(spell, currentActionData)
end

function Core_CreateTargetHealthBar( self )
  
  self.tagetHealthBar = CreateFrame("Button", "HealthBar", self, "SecureUnitButtonTemplate")

  self.tagetHealthBar:SetSize(Core.targetFrameConfig.width, Core.targetFrameConfig.height)
  self.tagetHealthBar:SetPoint("CENTER", self, "BOTTOMLEFT", 40, -40)
  Core.createBackDrop(self.tagetHealthBar)

  self.tagetHealthBar.health = self.tagetHealthBar:CreateTexture(nil, "OVERLAY")
  self.tagetHealthBar.health:SetSize(Core.targetFrameConfig.hWidth, Core.targetFrameConfig.hHeight)
  self.tagetHealthBar.health:SetPoint("LEFT", self.tagetHealthBar, "TOPLEFT", 7, -25)
  self.tagetHealthBar.health:SetColorTexture(unpack(Core.targetFrameConfig.color))

  self.tagetHealthBar.playerInfo = Core.createText(self.tagetHealthBar, "LEFT", "CENTER", -20, 0, "")
 
  RegisterUnitWatch(self.tagetHealthBar)

  Core.tagetHealthBar = self.tagetHealthBar


end


-----CONSOLE COMMANDS-------


local function openMainWidget( self )
  self:Show()
  self.BG:Show()
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

  Core_CreateTargetHealthBar(self)

  local elapsedTime = 0
  self:SetScript("OnUpdate", function( self, elapsed )
    elapsedTime = elapsedTime + elapsed
    if elapsedTime > 1 then
      elapsedTime = 0
      return Core_OnUpdateBattle(self, elapsed)
    end
  end)
end

local function stopService()
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

local function initConsoleCommands(self)

  SLASH_HEAL_LIKE_BOSS_CONSOLE1 = "/hlkb"
  SLASH_HEAL_LIKE_BOSS_CONSOLE2 = "/heallikeboss"

  SlashCmdList["HEAL_LIKE_BOSS_CONSOLE"] = function( msg )
    local command = msg:match("(%S+)")
    
    if (command == "start") then
      openMainWidget(self)
    elseif command == "settings" then
      print("Open settings")
      Core.showSettingsWindow()
    elseif command == "stop" then
      stopService()
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
  print("Data is loaded")
  Core.UserDataCheck()
  
  -- sort by priority
  Core.sortSpellsByPriority()
end

local function printAllArgs( ... )
  local params = {...}
  for k,v in pairs(params) do
    print(v)
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


function handlers.COMBAT_LOG_EVENT_UNFILTERED( self, event, ... )

  local timestamp, subevent, hideCaster, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags = CombatLogGetCurrentEventInfo()
  local spellId = select(12, CombatLogGetCurrentEventInfo())

  if (srcGUID == mmyGuid and subevent == "SPELL_CAST_SUCCESS") then
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
  
  self:SetScript("OnEvent", allHandlers)
  
  self:SetPoint("TOP", UIParent, "TOP")

end









