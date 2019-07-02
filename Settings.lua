local Core = nil
local SettingsWindow = nil
local activeTab = nil
local lastSpell = nil

local function createSpellModel( spId, spName, spIcon, cd, priority, group, bundle )
  local model = {
    spId = spId,
    spName = spName,
    spIcon=spIcon,
    cd=cd,
    priority = priority or 0,
    group=group,
    bundle=bundle or nil
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

  activeTab.bundles = activeTab.bundles or {}
  for k,v in pairs(activeTab.bundles) do
    local bundle = v.model
    if bundle then
      v:ClearAllPoints()
      v:SetPoint("LEFT", activeTab.content, "TOPLEFT", 30, bundle.priority * -50)
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

  for i,val in pairs(UserData.bundles[activeTab.info.title]) do
    if val.priority > priority then
      val.priority = val.priority - 1
    end
  end
end

local function onPriorityUp( self )
  -- body
end

function deleteSpellFromBucketList( self )
  for k,v in pairs(SettingsWindow.bundleWindow.spells) do
    -- TODO
    print(self.spId)
  end
end

function onDeleteSpell( self )
  if activeTab.mode == "spells" then
    for k,v in pairs(UserData.spells[activeTab.info.title]) do
      if v.spId == self.spId then
        table.remove(UserData.spells[activeTab.info.title], k)
        activeTab.spellList["spell_" .. v.spId]:Hide()
        FixPriorityAfterDeletion(k)
        rerenderSpellPositions()
      end
    end
    Core.sortSpellsByPriority()
  else
    deleteSpellFromBucketList(self)
  end
end

function onDeleteBundle( self )
  for k,v in pairs(UserData.bundles[activeTab.info.title]) do
    if v.id == self.id then
      table.remove(UserData.bundles[activeTab.info.title], k)
      activeTab.bundles[v.id]:Hide()
      FixPriorityAfterDeletion(v.priority)
      rerenderSpellPositions()
    end
  end
  Core.sortSpellsByPriority()
end

function onEditBundle(self)
  initBundleWindow(self.model)
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
  spell.name.text = Core.createText(spell.name, "LEFT", "TOPLEFT", 50, -25, spellModel.spName)

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

local function createBundleRow( parentFrame, bundleModel )
   -- Create Bundke frame
  local spell = CreateFrame("Frame", nil, parentFrame)
  spell:SetSize(400, 50)
  spell:SetPoint("LEFT", parentFrame, "TOPLEFT", 30, bundleModel.priority * -50)

  -- bundle icon
  spell.icon = CreateFrame("Frame", nil, spell)
  spell.icon:SetSize(40,40)
  spell.icon:SetPoint("LEFT", spell, "BOTTOMLEFT", 0,0)
  spell.icon.texture = spell.icon:CreateTexture(nil, "BACKGROUND")
  spell.icon.texture:SetSize(40,40)
  spell.icon.texture:SetPoint("LEFT", spell.icon, "TOPLEFT", 0, 0)
  spell.icon.texture:SetTexture(bundleModel.icon)

  -- bundle spName
  spell.name = CreateFrame("Frame", nil, spell)
  spell.name:SetSize(100, 50)
  spell.name:SetPoint("LEFT", spell.icon, "TOPLEFT", 0, 0)
  spell.name.text = Core.createText(spell.name, "LEFT", "TOPLEFT", 50, -25, bundleModel.name)

  -- Priority

  spell.priorityDown= createButton(
    spell, "LEFT", spell.name.text, "TOPLEFT", 100, -20, 30, 20, "-", onPriorityDown
  )
  spell.priorityDown.id = bundleModel.id

  spell.priorityUp= createButton(
    spell, "LEFT", spell.name.text, "TOPLEFT", 100, 0, 30, 20, "+", onPriorityUp
  )
  spell.priorityUp.id = bundleModel.id

  spell.delete = createButton(
    spell, "LEFT", spell.priorityUp, "TOPRIGHT", 20, -20, 50, 30, "Delete", onDeleteBundle
  )
  spell.delete.id = bundleModel.id

  spell.openBundle = createButton(
    spell, "LEFT", spell.priorityUp, "TOPRIGHT", 80, -20, 40, 30, "Edit", onEditBundle
  )
  spell.openBundle.model = bundleModel
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
    activeTab.spellList["spell_" .. v.spId] = createSpellRow(activeTab.content, v, v.priority);
    activeTab.spellCount = i
  end
end

local function renderSpellsInBucketList(bundle)
  SettingsWindow.bundleWindow.spells = {}

  for i,v in pairs(bundle.spells) do
    SettingsWindow.bundleWindow.spells[bundle.id] = createSpellRow(SettingsWindow.bundleWindow, v, v.priority)
  end
end

local function renderBundleList(fromIndex)
  local bundles = UserData.bundles[activeTab.info.title]
  activeTab.bundles = {}
  activeTab.bundlesCount = 0
  
  if bundles then
    for k,v in pairs(UserData.bundles[activeTab.info.title]) do
      activeTab.bundles[v.id] = {}
      activeTab.bundles[v.id] = createBundleRow(activeTab.content, v, v.priority)
      activeTab.bundles[v.id].model = v
      activeTab.bundles[v.id].spellCount = table.getn(v.spells)
      activeTab.bundlesCount = activeTab.bundlesCount + 1
      activeTab.spellCount = activeTab.spellCount  + 1
    end
  end
end

local function addSpellToWindow( spellModel )
  -- Adding Spell Row to active Tab
  if activeTab.spellList == nil then
    activeTab.spellList = {}
  end
  activeTab.spellList["spell_"..spellModel.spId] = createSpellRow(activeTab.content, spellModel, activeTab.spellCount)
end

function addSpellToBundleWindow( spellModel, bundle )
  bundle.spells[spellModel.spId] = createSpellRow(SettingsWindow.bucketWindow, spellModel, bundle.spellCount)
end

local function onAddIntoSpells()
  local spellId, spellName, spellIcon  = unpack(lastSpell)
  local start, duration = GetSpellCooldown(spellId)
  local spellCount = activeTab.spellCount + 1
  local spellModel = createSpellModel(spellId, spellName, spellIcon, duration, spellCount, activeTab.info.title)
  -- Adding data to User Data
  if spellId and activeTab.spells[spellId] == nil then
    table.insert(UserData.spells[activeTab.info.title], spellModel)
    activeTab.spells[spellId] = spellModel.cd
    activeTab.spellCount = spellCount
    addSpellToWindow(spellModel)
    Core.sortSpellsByPriority()
  else
    showError("Such spell is already added")
  end
end

local function onAddIntoBundle()
  local spellId, spellName, spellIcon  = unpack(lastSpell)
  local start, duration = GetSpellCooldown(spellId)
  local bundle = activeTab.bundles[activeTab.bundlesCount]
  bundle.spellCount = bundle.spellCount + 1
  local spellModel = createSpellModel(spellId, spellName, spellIcon, duration, bundle.spellCount, activeTab.info.title)

  if spellId and bundle.spells[spellId] == nil then
    table.insert(UserData.bundles[activeTab.info.title][activeTab.bundlesCount].spells, spellModel)
    activeTab.spells[spellId] = spellModel.cd
    addSpellToBundleWindow(spellModel, SettingsWindow.bundleWindow.spells)
  else
    showError("Such spell is already added to this Bundle")
  end
end

local function onAddSpell(self, ...)

  if (UserData.spells[activeTab.info.title] == nil) then
    UserData.spells[activeTab.info.title] = {}
  end

  if activeTab.mode == "spells" then
    onAddIntoSpells()
  elseif activeTab.mode == "bundle" then
    onAddIntoBundle()
  end

  
end

local function Settings_OnSpellSuccess( spellId, spellName, spellIcon )
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetTexture(spellIcon)
  lastSpell = {spellId, spellName, spellIcon}
end



local function initTabContent( tabButton )
  local tab = tabButton.content
  tabButton.spells = {}
  tabButton.spellList = {}
  tabButton.spellCount = 0

  if UserData.spells[tabButton.info.title] == nil then
    UserData.spells[tabButton.info.title] = {}
  end
  if UserData.bundles[tabButton.info.title] == nil then
    UserData.bundles[tabButton.info.title] = {}
  end
  renderSpellList()
  renderBundleList()  
  tab.init = true

  Settings_CreateBundles(activeTab)

  tab.title = Core.createText(tab, "LEFT", "TOPLEFT", 240, 0, (tabButton.info.title .. " Tab"))
  tab.desc = Core.createText(tab, "LEFT", "TOPLEFT", 240, -10, "|c0000FF00Cast spell in order to add it")

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

function setBundleWindowText(index)
  SettingsWindow.bundleWindow.title:SetText("|c0000FF00Cast spell in order to add it to Bundle #" .. index)
end

local function createBundleWindow(index)
  local bundleWindow = Core.createFrame(SettingsWindow, nil, nil, "LEFT", "TOPLEFT", 7, -350, 593, 500)
  bundleWindow.title = Core.createText(bundleWindow, "RIGHT", "TOPRIGHT", -135, 20, "|c0000FF00Cast spell in order to add it to Bundle #")
  Core.createBackDrop(bundleWindow)
  bundleWindow:Hide()

  bundleWindow.close = Core.createButton(bundleWindow, "LEFT", "TOPRIGHT", -100, -30, 70, 40, "Close", closeBundleWindow)

  bundleWindow.spells = Core.createFrame(bundleWindow, nil, nil, "LEFT", "TOPLEFT", 0, 0, 593, 500)

  return bundleWindow
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
    parent["tab_button" .. n].mode="spells"


    -- register click on
    parent["tab_button" .. n]:RegisterForClicks("AnyUp")
    parent["tab_button" .. n]:SetScript("OnClick", onTabButtonClick)
  end

  activeTab = parent["tab_button" .. n]
  activeTab.spells = {}

  setColorTextForButton(activeTab, {1, 0.5, 0.25, 1.0})
end

function Settings_CreateBundles( activeTab )
  if activeTab.bundles == nil then
    activeTab.bundles = {}
    activeTab.bundlesCount = 0
  end
end

function createBundleModel(index)
  local spellName, _, spellIcon = GetSpellInfo(301758)
  return {
    id = index,
    name = "Bundle #" .. index,
    icon=spellIcon,
    priority = activeTab.spellCount,
    spells = {}
  }
end

function initBundleWindow( bundle )
  activeTab.content:Hide()
  SettingsWindow.addBundleButton:Hide()
  SettingsWindow.bundleWindow:Show()
  setBundleWindowText(bundle.id)
  activeTab.mode = "bundle"

  if bundle then
    renderSpellsInBucketList(bundle)
  end
end

function closeBundleWindow( )
  activeTab.content:Show()
  SettingsWindow.addBundleButton:Show()
  SettingsWindow.bundleWindow:Hide()
  activeTab.mode = "spells"
end

local function onAddBundle()
  activeTab.bundlesCount = activeTab.bundlesCount + 1
  activeTab.spellCount = activeTab.spellCount + 1
  activeTab.bundles[activeTab.bundlesCount] = {}
  activeTab.bundles[activeTab.bundlesCount].model = createBundleModel(activeTab.bundlesCount)
  activeTab.bundles[activeTab.bundlesCount].spellCount = 0
  activeTab.bundles[activeTab.bundlesCount].spells = {}

  initBundleWindow(activeTab.bundles[activeTab.bundlesCount].model)

  if (UserData.bundles[activeTab.info.title] == nil) then
    UserData.bundles[activeTab.info.title] = {}
  end

  if UserData.bundles[activeTab.info.title][activeTab.bundlesCount] == nil then
    UserData.bundles[activeTab.info.title][activeTab.bundlesCount] = activeTab.bundles[activeTab.bundlesCount].model
  end
end


local function CreateSettingsWindow(core)
  SettingsWindow = Core.createFrame(UIParent, "HLBSettingsFrame", "UIPanelDialogTemplate", "CENTER", "CENTER", 0, 50, 600, 600)

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
  SettingsWindow.spellListFrames.spell1.spellIconFrame = Core.createFrame(SettingsWindow.spellListFrames.spell1, nil, nil, "LEFT", "LEFT", 0, 0, 50, 50)


  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture =
    SettingsWindow.spellListFrames.spell1.spellIconFrame:CreateTexture(nil, "BACKGROUND")
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetHeight(50)
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetWidth(50)
  SettingsWindow.spellListFrames.spell1.spellIconFrame.texture:SetPoint("LEFT", SettingsWindow.spellListFrames.spell1.spellIconFrame, "LEFT", 0, 0)
  SetPortraitTexture(SettingsWindow.spellListFrames.spell1.spellIconFrame.texture, "player")

  --Error
  SettingsWindow.spellListFrames.spell1.error = Core.createText(SettingsWindow.spellListFrames.spell1, "CENTER", "TOP", 0, 0, "")


  -- Add Spell Button
  SettingsWindow.addSpellButton = Core.createButton(SettingsWindow, "LEFT", "TOPLEFT", 80, -65, 140, 40, "Add Spell", onAddSpell)

  -- Create Bundle
  SettingsWindow.addBundleButton = Core.createButton(SettingsWindow, "LEFT", "TOPRIGHT", -120, -65, 100, 40, "Add Bundle", onAddBundle)

  -- Kind of tab's buttons
  Settings_CreateTabs(SettingsWindow)
  Settings_CreateBundles(activeTab)
  SettingsWindow.bundleWindow = createBundleWindow(activeTab.bundlesCount + 1)

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

