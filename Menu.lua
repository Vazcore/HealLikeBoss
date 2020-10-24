local Core = nil

local function ShowAddonIcon(self)
  local ConfigWindow = UILib.createFrame(UIParent, "HLBConfigFrame", "UIPanelDialogTemplate", "CENTER", "CENTER", 0, 50, 600, 600)
  ConfigWindow:Hide()

  -- Title
  ConfigWindow.title = UILib.createText(ConfigWindow, "TOP","TOP", 10, -10, "Menu")

  ConfigWindow.StartButton = UILib.createButton(ConfigWindow, "TOP","TOP", 10, -100, 300, 40, "Start", function ()
    ConfigWindow:Hide()
    if Core.started ~= 0 then
      stopService(self)
    else
      openMainWidget(self)
    end
  end)

  ConfigWindow.SettingsButton = UILib.createButton(ConfigWindow, "TOP","TOP", 10, -150, 300, 40, "Settings", function ()
    ConfigWindow:Hide()
    Core.showSettingsWindow()
  end)

  ConfigWindow.SettingsButton = UILib.createButton(ConfigWindow, "TOP","TOP", 10, -200, 300, 40, "Key Mapping", function ()
    ConfigWindow:Hide()
    HLBKeyMappingFrame:Show()
  end)

  ConfigWindow.SettingsButton = UILib.createButton(ConfigWindow, "TOP","TOP", 10, -250, 300, 40, "Panel Display", function ()
    ConfigWindow:Hide()
    HLBDisplayPanelFrame:Show()
  end)

  -- Icon Menu
  local addonIconFrame = UILib.createFrame(UIParent, nil, nil, "TOPRIGHT", "TOPRIGHT", -140, 0,50,50, "Button")
  addonIconFrame.icon = UILib.createTexture(addonIconFrame, "BACKGROUND", 50,50,"TOPRIGHT","TOPRIGHT",0,0,614747)
  addonIconFrame:Show()
  addonIconFrame.icon:Show()
  addonIconFrame:SetScript("OnClick", function ()
    if Core.started ~= 0 then
      ConfigWindow.StartButton:SetText("Stop")
    else
      ConfigWindow.StartButton:SetText("Start")
    end
    ConfigWindow:Show()
  end)
end


function Menu_Init(core)
  Core = core
  local frame = MenuFrame
  ShowAddonIcon(Core.CoreFrame)
end