local Core = nil
local mmyGuid = UnitGUID("player")
local defaultIconId = 614747

local function onEventsHanlder(self, event, ...)
  local timestamp, subevent, hideCaster, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags = CombatLogGetCurrentEventInfo()
  local spellId = select(12, CombatLogGetCurrentEventInfo())
  if srcGUID == mmyGuid and subevent == "SPELL_CAST_SUCCESS" then
    local spellName, _, spellIcon = GetSpellInfo(spellId)
    HLBKeyMappingFrame.icon:SetTexture(spellIcon)
    HLBKeyMappingFrame.addRowBtn:Enable()
  end
end

local function onAddRow(self)
  local parent = self:GetParent()
  -- to do : local row = UILib.createFrame(parent.listFrame, nil, );
end

local function RenderKeyMappingWindow()
  local KeyMappingWindow = UILib.createFrame(UIParent, "HLBKeyMappingFrame", "UIPanelDialogTemplate", "CENTER", "CENTER", 0, 50, 600, 600)
  KeyMappingWindow:Hide()

  -- Title
  KeyMappingWindow.title = UILib.createText(KeyMappingWindow, "TOP", "TOP", 10,-10,"Key Mapping")
  
  -- Spel Icon
  KeyMappingWindow.icon = UILib.createTexture(KeyMappingWindow, "OVERLAY", 50,50,"TOP", "TOP",0,-40,defaultIconId);
  KeyMappingWindow.icon:Show()
  -- Spell Introduction Text
  KeyMappingWindow.iconText = UILib.createText(KeyMappingWindow, "TOP", "TOP", -90, -60,"Current Spell Used:")
  KeyMappingWindow:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  KeyMappingWindow:SetScript("OnEvent", onEventsHanlder)

  -- Add Row Mapping Button
  KeyMappingWindow.addRowBtn = UILib.createButton(KeyMappingWindow, "CENTER", "TOP", 0, -115, 200, 40, "Add Key Mapping", onAddRow)
  KeyMappingWindow.addRowBtn:Disable()

  -- Add Container for Key Mappings
  KeyMappingWindow.listFrame = UILib.createFrame(KeyMappingWindow, nil, nil, "BOTTOM", "BOTTOM", 0, 15, 550, 450)
  --KeyMappingWindow.listFrame.rows = {}
  UILib.createBackDrop(KeyMappingWindow.listFrame)
end

function KeyMapping_init(core)
  Core = core
  RenderKeyMappingWindow()
end