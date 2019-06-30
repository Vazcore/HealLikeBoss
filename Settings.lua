local Core = nil
local SettingsWindow = nil
local activeTab = nil

local function setColorTextForButton( button, disable )
  if disable then
    button:Disable()
  else
    button:Enable()
  end
end

local function onTabButtonClick( instance, button, down )
  if (instance.info.title ~= activeTab.info.title) then
    print("Clicked on tab: " .. instance.info.title)
    setColorTextForButton(activeTab, false)
    activeTab = instance  
    setColorTextForButton(activeTab, true)
  end
end

local function  Settings_CreateTabContent(parent)
  local tabContent = CreateFrame("Frame", nil, parent)
  tabContent:SetPoint("CENTER", parent, "LEFT", 0, 0)
  tabContent:SetSize(450, 300)
  return tabContent
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
    --parent["tab_button" .. n]:SetNormalFontObject("GameFontHighlight")

    -- register click on
    parent["tab_button" .. n]:RegisterForClicks("AnyUp")
    parent["tab_button" .. n]:SetScript("OnClick", onTabButtonClick)
  end

  activeTab = parent["tab_button" .. n]

  setColorTextForButton(activeTab, {1, 0.5, 0.25, 1.0})
end


local function CreateSettingsWindow(core)
  SettingsWindow = CreateFrame("Frame", "HLBSettingsFrame", UIParent, "UIPanelDialogTemplate");
  SettingsWindow:ClearAllPoints()
  SettingsWindow:SetSize(600, 400)
  SettingsWindow:SetPoint("CENTER", UIParent, "CENTER")
  SettingsWindow:Hide()

  -- Title
  SettingsWindow.title = SettingsWindow:CreateFontString(nill, "OVERLAY")
  SettingsWindow.title:SetFontObject("GameFontHighlight")
  SettingsWindow.title:SetPoint("LEFT", HLBSettingsFrameTitleBG, "LEFT", 5, -2)
  SettingsWindow.title:SetText("Settings")


  -- Create Frame
  SettingsWindow.spellListFrames = {}
  SettingsWindow.spellListFrames.spell1 = CreateFrame("Frame", "HLBSpellItem", SettingsWindow)
  SettingsWindow.spellListFrames.spell1:SetSize(250, 50)
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


  -- Add Spell Button
  SettingsWindow.addSpellButton = CreateFrame("Button", nil, SettingsWindow, "GameMenuButtonTemplate")
  SettingsWindow.addSpellButton:SetPoint("CENTER", SettingsWindow, "TOP", 0, -50)
  SettingsWindow.addSpellButton:SetSize(140, 40)
  SettingsWindow.addSpellButton:SetText("Add Spell")

  -- Kind of tab's buttons
  Settings_CreateTabs(SettingsWindow)

  return SettingsWindow

end

local function showSettingsWindow()
  if SettingsWindow then SettingsWindow:Show() else CreateSettingsWindow():Show() end
end

local function Settings_Methods(core)
  
  -- Opening (creating or showing) Settings Window
  core.showSettingsWindow = showSettingsWindow
  

end

function Settings_Init( core )
  Core = core
  Settings_Methods(Core)
end

local function createSpellRow( parentFrame )
  -- todo
end



function HealLikeBossAddSpell_OnClick()
  print("Adding Spell: " .. settingsTempData.lastSpellIcon.spellName)
  UserData.spells[settingsTempData.lastSpellIcon.spellName] = {
    coolDown = 0
  }
  if (UserData.spellList == nil) then
    UserData.spellList = {}
    table.insert(UserData.spellList, settingsTempData.lastSpellIcon)
  else
    table.insert(UserData.spellList, settingsTempData.lastSpellIcon)
  end
end