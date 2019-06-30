local Core = {}
local mmyGuid = UnitGUID("player")
local handlers = {}
local addonName = "HealLikeBoss"

local settingsFrame = nil


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

function Core_getCore()
  return Core
end


-----CONSOLE COMMANDS-------


local function openMainWidget( self )
  self:Show()
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
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
    end

  end

end

------------------------
local function initData()
  UserData = {
    spells = {}
  }
end

local function proccessData()
  print("Data is loaded")
  print(UserData)
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


function handlers.COMBAT_LOG_EVENT_UNFILTERED( self, event, ... )

  local timestamp, subevent, hideCaster, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags = CombatLogGetCurrentEventInfo();
  local spellId = select(12, CombatLogGetCurrentEventInfo())

  if (srcGUID == mmyGuid and subevent == "SPELL_CAST_SUCCESS") then
    local spellName, _, spellIcon = GetSpellInfo(spellId)
    if Core.Settings_OnSpellSuccess then
      Core.Settings_OnSpellSuccess(spellId, spellName, spellIcon)
    end
    self.BG:SetTexture(spellIcon)
  end
end

function allHandlers(self, event, ...)
  return handlers[event](self, event, ...)
end


function Core_RegisterMainEventHandlers(self)
  Core.CoreFrame = self
  
  self:RegisterEvent("ADDON_LOADED");
  self:RegisterEvent("PLAYER_LOGOUT");
  
  self:SetScript("OnEvent", allHandlers)

  
  self:SetPoint("TOP", UIParent, "TOP")

end









