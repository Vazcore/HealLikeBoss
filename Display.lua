local Core = nil
local activePosition = nil

local function RenderSpellList()
  local DisplayPanel = UILib.createFrame(UIParent, "HLBDisplayPanelSpellsFrame", "UIPanelDialogTemplate", "CENTER", "CENTER", 0, 50, 800, 700)
  DisplayPanel:Hide()
  Core.PlayerSpells = UILib.getAllPlayerSpells()

  -- Title
  DisplayPanel.title = UILib.createText(DisplayPanel, "TOP", "TOP", 10,-10,"Pick spell")
  DisplayPanel.container = UILib.createFrame(
    DisplayPanel, nil,nil,"TOPLEFT","TOPLEFT",50,-45,760,680
  )
  DisplayPanel.container.spells = {}
  local row = 0
  local column = 0
  for k,v in pairs(Core.PlayerSpells) do
    if v[2] then
      local frame = UILib.createFrame(
        DisplayPanel.container, nil, nil, "TOPLEFT", "TOPLEFT",
        column * 140, -(row * 95), 140, 90
      )
      frame.spellId = v[3]
      UILib.createBackDrop(frame)
      frame.icon = UILib.createTexture(frame, "OVERLAY", 40, 40, "CENTER", "CENTER", 0,10, v[2])
      frame.title = UILib.createText(frame, "CENTER", "BOTTOM", 0,15,v[1])

      column = column + 1
      if k % 5 == 0 then
        column = 0
        row = row + 1
      end
      frame:SetScript("OnMouseDown", function ()
        activePosition.selectBtn:Hide()
        activePosition.icon:Show()
        activePosition.icon:SetTexture(v[2])
        activePosition.position[6] = v[2]
        activePosition = nil
        DisplayPanel:Hide()
        HLBDisplayPanelFrame:Show()
      end)
      table.insert(DisplayPanel.container.spells, frame)
    end
  end
end

local function RenderPanel()
  local DisplayPanel = UILib.createFrame(UIParent, "HLBDisplayPanelFrame", "UIPanelDialogTemplate", "CENTER", "CENTER", 0, 50, 600, 600)
  DisplayPanel:Hide()

  -- Title
  DisplayPanel.title = UILib.createText(DisplayPanel, "TOP", "TOP", 10,-10,"Panel Display")

  local positions = {
    {0, 0, "Top-Left", "TOPLEFT", "TOPLEFT",nil}, {170, 0, "Top-Center", "CENTER", "TOP",nil}, {340, 0, "Top-Right", "TOPRIGHT", "TOPRIGHT",nil},
    {0, 120, "Bottom-Left", "BOTTOMLEFT", "BOTTOMLEFT",nil}, {170, 120, "Bottom-Center", "CENTER", "BOTTOM",nil}, {340, 120, "Bottom-Right", "BOTTOMRIGHT", "BOTTOMRIGHT",nil}
  }
  Core.positions = positions

  DisplayPanel.container = UILib.createFrame(
    DisplayPanel, nil,nil,"TOPLEFT","TOPLEFT",55,-50,560,580
  )
  DisplayPanel.container.positions = {}

  local function onChoosePosition(buffPos)
    HLBDisplayPanelSpellsFrame:Show()
    HLBDisplayPanelFrame:Hide()
    activePosition = buffPos
  end

  for k,v in pairs(positions) do
    local buffPos = UILib.createFrame(DisplayPanel.container, nil, nil, "TOPLEFT", "TOPLEFT", v[1], (-1 * v[2]), 150,100)
    UILib.createBackDrop(buffPos)
    buffPos.title = UILib.createText(buffPos, "TOP", "TOP", 0,-10,v[3])
    buffPos.selectBtn = UILib.createButton(buffPos, "TOP","TOP",0, -30,100,40,"Select spell", function()
      onChoosePosition(buffPos)
    end)
    buffPos.position = v
    buffPos.icon = UILib.createTexture(
      buffPos, "OVERLAY", 40,40,"CENTER","CENTER",0,0,nil
    )
    buffPos:SetScript("OnMouseDown", function()
      onChoosePosition(buffPos)
    end)
    buffPos.icon:Hide()
    table.insert(DisplayPanel.container.positions, buffPos)
  end
  
end

function DisplayPanel_init(core)
  Core = core
  RenderPanel()
  RenderSpellList()
end
