local Core = nil
local SettingsWindow = nil
local activeTab = nil
local lastSpell = nil

local function createSpellModel( spId, spName, spIcon, cd, priority, group )
  local model = {
    spId = spId,
    spName = spName,
    spIcon=spIcon,
    cd=cd,
    priority = priority or 0,
    group=group
  }
  return model
end

local function showError( msg )
  SettingsWindow.spellListFrames.spell1.error:SetText("|cFFFF0000" .. msg)
end

local function hideError( msg )
  SettingsWindow.spellListFrames.spell1.error:SetText("")
end

function  createButton( ... )
  local parent, pos1, posParent, pos2, ox, oy, w, h, text, callback = ...

  local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  button:SetPoint(pos1, posParent, pos2, ox, oy)
  button:SetSize(w, h)
  button:SetText(text)
  button:RegisterForClicks("AnyUp")
  button:SetScript("OnClick", callback)

  return button  
end

function rerenderSpellPositions()
  for k,v in pairs(activeTab.spellList) do
    local spell = Settings_GetSpellById(v.delete.spId)
    if spell then
      v:ClearAllPoints()
      v:SetPoint("LEFT", activeTab.content, "TOPLEFT", 30, spell.priority * -50)
    end
  end
end

local function onPriorityDown( self )
  local selfSpell = Settings_GetSpellById(self.spellId)
  local lowerPriorityIndex = selfSpell.priority + 1
  local lowerSpell = Settings_GetSpellByPriority(lowerPriorityIndex)

  if selfSpell.priority and lowerSpell.priority then
    lowerSpell.priority = selfSpell.priority
    selfSpell.priority = lowerPriorityIndex
  end

  rerenderSpellPositions()
end

function FixPriorityAfterDeletion( priority )
  for k,v in pairs(UserData.spells[activeTab.info.title]) do
    if v.priority > priority then
      v.priority = v.priority - 1
    end
  end
end

local function onPriorityUp( self )
  -- body
end

function onDeleteSpell( self )
  for k,v in pairs(UserData.spells[activeTab.info.title]) do
    if v.spId == self.spId then
      table.remove(UserData.spells[activeTab.info.title], k)
      activeTab.spellList["spell_" .. v.spId]:Hide()
      FixPriorityAfterDeletion(k)
      rerenderSpellPositions()
    end
  end
end

local function createSpellRow( parentFrame, spellModel, index )
  -- Create Spell frame
  local spell = CreateFrame("Frame", nil, parentFrame)
  spell:SetSize(400, 50)
  spell:SetPoint("LEFT", parentFrame, "TOPLEFT", 30, spellModel.priority * -50)

  -- spell icon
  spell.icon = CreateFrame("Frame", nil, spell)
  spell.icon:SetSize(40,40)
  spell.icon:SetPoint("LEFT", spell, "BOTTOMLEFT", 0,0)
  spell.icon.texture = spell.icon:CreateTexture(nil, "BACKGROUND")
  spell.icon.texture:SetSize(40,40)
  spell.icon.texture:SetPoint("LEFT", spell.icon, "TOPLEFT", 0, 0)
  spell.icon.texture:SetTexture(spellModel.spIcon)

  -- spell spName
  spell.name = CreateFrame("Frame", nil, spell)
  spell.name:SetSize(100, 50)
  spell.name:SetPoint("LEFT", spell.icon, "TOPLEFT", 0, 0)
  spell.name.text = createText(spell.name, "LEFT", "TOPLEFT", 50, -25, spellModel.spName)

  -- Priority

  spell.priorityDown= createButton(
    spell, "LEFT", spell.name.text, "TOPLEFT", 100, -20, 30, 20, "-", onPriorityDown
  )
  spell.priorityDown.spellId = spellModel.spId

  spell.priorityUp= createButton(
    spell, "LEFT", spell.name.text, "TOPLEFT", 100, 0, 30, 20, "+", onPriorityUp
  )
  spell.priorityUp.spellId = spellModel.spId

  spell.delete = createButton(
    spell, "LEFT", spell.priorityUp, "TOPRIGHT", 20, -20, 50, 30, "Delete", onDeleteSpell
  )
  spell.delete.spId = spellModel.spId


  return spell
end

function Settings_UpdatePriority( spellId, priority )
  for i,v in pairs(UserData.spells[activeTab.info.title]) do
    if v.spId == spellId then
      v.priority = priority
    end
  end
end

function Settings_GetSpellById( spId )
  local spell = nil
  for i,v in pairs(UserData.spells[activeTab.info.title]) do
    if v.spId == spId then
      spell = v
    end
  end
  return spell
end

function Settings_GetSpellByPriority( priority )
  local spell = nil
  for i,v in pairs(UserData.spells[activeTab.info.title]) do
    if v.priority == priority then
      spell = v
    end
  end
  return spell
end

local function renderSpellList()
  activeTab.spellList = {}
  for i,v in pairs(UserData.spells[activeTab.info.title]) do
    activeTab.spells[v.spId] = v.cd
    activeTab.spellList["spell_" .. v.spId] = createSpellRow(activeTab.content, v, i);
    activeTab.spellCount = i
  end
end

local function addSpellToWindow( spellModel )
  -- Adding Spell Row to active Tab
  if activeTab.spellList == nil then
    activeTab.spellList = {}
  end
  activeTab.spellList["spell_"..spellModel.spId] = createSpellRow(activeTab.content, spellModel, activeTab.spellCount)
end

local function onAddSpell(self, ...)
  local spellId, spellName, spellIcon  = unpack(lastSpell)
  local start, duration = GetSpellCooldown(spellId)
  local spellCount = activeTab.spellCount + 1
  local spellModel = createSpellModel(spellId, spellName, spellIcon, duration, spellCount, activeTab.info.title)

  if (UserData.spells[activeTab.info.title] == nil) then
    UserData.spells[activeTab.info.title] = {}
  end

  -- Adding data to User Data
  if spellId and activeTab.spells[spellId] == nil then
    table.insert(UserData.spells[activeTab.info.title], spellModel)
    activeTab.spells[spellId] = spellModel.cd
    activeTab.spellCount = spellCount
    addSpellToWindow(spellModel)
  else
    showError("Such spell is already added")
  end
end

local function Settings_OnSpellSuccess( spellId, spellName, spellIcon )
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetTexture(spellIcon)
  lastSpell = {spellId, spellName, spellIcon}
end

function createText( ... )
  local parent, pos1, pos2, ox, oy, text = ...

  local t = parent:CreateFontString(nil, "OVERLAY")
  t:SetFontObject("GameFontHighlight")
  t:SetPoint(pos1, parent, pos2, ox, oy)
  t:SetText(text)
  return t
end

local function initTabContent( tabButton )
  local tab = tabButton.content
  tabButton.spells = {}
  tabButton.spellList = {}
  tabButton.spellCount = 0

  if UserData.spells[tabButton.info.title] == nil then
    UserData.spells[tabButton.info.title] = {}
  else
    renderSpellList()
  end
  tab.init = true

  tab.title = createText(tab, "LEFT", "TOPLEFT", 240, 0, (tabButton.info.title .. " Tab"))
  tab.desc = createText(tab, "LEFT", "TOPLEFT", 240, -10, "|c0000FF00Cast spell in order to add it")

end

local function setColorTextForButton( button, disable )
  if disable then
    button:Disable()
    button.content:Show()
    if (button.content.init ~= true) then
      initTabContent(button)
    end
  else
    button:Enable()
    button.content:Hide()
  end
end

local function onTabButtonClick( instance, button, down )
  if (instance.info.title ~= activeTab.info.title) then
    print("Clicked on tab: " .. instance.info.title)
    setColorTextForButton(activeTab, false)
    activeTab = instance  
    setColorTextForButton(activeTab, true)

    hideError()
  end
end

local function  Settings_CreateTabContent(parent)
  local tabContent = CreateFrame("Frame", nil, parent)
  tabContent:SetPoint("LEFT", SettingsWindow, "TOPLEFT", 0, -210)
  tabContent:SetSize(600, 300)
  return tabContent
end

function createBackDrop( frame )
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16, 
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  });
  frame:SetBackdropColor(0,0,0,1);
end

local function  Settings_CreateTabs(parent)
  local n = 0;
  for i,v in pairs(Core.situations) do
    n = n + 1;
    parent["tab_button" .. n] = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    parent["tab_button" .. n]:SetPoint("CENTER", parent, "BOTTOMLEFT", (n*120), 30)
    parent["tab_button" .. n]:SetSize(110, 30)
    parent["tab_button" .. n]:SetText(v.title)
    parent["tab_button" .. n].info = v
    parent["tab_button" .. n].content = Settings_CreateTabContent(parent["tab_button" .. n])


    -- register click on
    parent["tab_button" .. n]:RegisterForClicks("AnyUp")
    parent["tab_button" .. n]:SetScript("OnClick", onTabButtonClick)
  end

  activeTab = parent["tab_button" .. n]
  activeTab.spells = {}

  setColorTextForButton(activeTab, {1, 0.5, 0.25, 1.0})
end


local function CreateSettingsWindow(core)
  SettingsWindow = CreateFrame("Frame", "HLBSettingsFrame", UIParent, "UIPanelDialogTemplate");
  SettingsWindow:ClearAllPoints()
  SettingsWindow:SetSize(600, 600)
  SettingsWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
  SettingsWindow:Hide()

  -- Title
  SettingsWindow.title = SettingsWindow:CreateFontString(nil, "OVERLAY")
  SettingsWindow.title:SetFontObject("GameFontHighlight")
  SettingsWindow.title:SetPoint("LEFT", HLBSettingsFrameTitleBG, "LEFT", 5, -2)
  SettingsWindow.title:SetText("Settings")


  -- Create Frame
  SettingsWindow.spellListFrames = {}
  SettingsWindow.spellListFrames.spell1 = CreateFrame("Frame", "HLBSpellItem", SettingsWindow)
  SettingsWindow.spellListFrames.spell1:SetSize(500, 50)
  SettingsWindow.spellListFrames.spell1:SetPoint("LEFT", HLBSettingsFrameTitleBG, "LEFT", 20, -50)

  -- Spell Icon
  SettingsWindow.spellListFrames.spell1.spellIconFrame = CreateFrame("Frame", nil, SettingsWindow.spellListFrames.spell1)
  SettingsWindow.spellListFrames.spell1.spellIconFrame:SetSize(50, 50)
  SettingsWindow.spellListFrames.spell1.spellIconFrame:SetPoint("LEFT", SettingsWindow.spellListFrames.spell1, "LEFT", 0, 0)

  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture =
    SettingsWindow.spellListFrames.spell1.spellIconFrame:CreateTexture(nil, "BACKGROUND")
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetHeight(50)
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetWidth(50)
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetPoint("LEFT", SettingsWindow.spellListFrames.spell1.spellIconFrame, "LEFT", 0, 0)
  SetPortraitTexture(SettingsWindow.spellListFrames.spell1.spellIconFrame.texture, "player")

  --Error
  SettingsWindow.spellListFrames.spell1.error = createText(SettingsWindow.spellListFrames.spell1, "CENTER", "TOP", 0, 0, "")


  -- Add Spell Button
  SettingsWindow.addSpellButton = CreateFrame("Button", nil, SettingsWindow, "GameMenuButtonTemplate")
  SettingsWindow.addSpellButton:SetPoint("LEFT", SettingsWindow, "TOPLEFT", 80, -65)
  SettingsWindow.addSpellButton:SetSize(140, 40)
  SettingsWindow.addSpellButton:SetText("Add Spell")
  SettingsWindow.addSpellButton:RegisterForClicks("AnyUp")
  SettingsWindow.addSpellButton:SetScript("OnClick", onAddSpell)

  -- Kind of tab's buttons
  Settings_CreateTabs(SettingsWindow)

  return SettingsWindow

end

local function showSettingsWindow()
  if SettingsWindow then SettingsWindow:Show() else CreateSettingsWindow():Show() end

  Core.CoreFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

local function Settings_Methods(core)
  
  -- Opening (creating or showing) Settings Window
  core.showSettingsWindow = showSettingsWindow

  -- On Player Spell Successfull
  core.Settings_OnSpellSuccess = Settings_OnSpellSuccess
  

end

function Settings_Init( core )
  Core = core
  Settings_Methods(Core)
end

