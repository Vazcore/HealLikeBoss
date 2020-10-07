UILib = {}

UILib.createBackDrop = function ( frame )
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16, 
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  });
  frame:SetBackdropColor(0,0,0,1);
end

UILib.createText = function( ... )
  local parent, pos1, pos2, ox, oy, text = ...

  local t = parent:CreateFontString(nil, "OVERLAY")
  t:SetFontObject("GameFontHighlight")
  t:SetPoint(pos1, parent, pos2, ox, oy)
  t:SetText(text)
  return t
end

UILib.createButton = function( ... )
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

UILib.createFrame = function ( ... )
  local parent, name, template, pos1, pos2, ox, oy, w, h, type  = ...
  local frame = CreateFrame(type ~= nil and type or "Frame", name, parent, template)
  frame:SetSize(w, h)
  frame:SetPoint(pos1, parent, pos2, ox, oy)

  return frame
end

UILib.createTexture = function ( ... )
  local parent, type, w, h, pos1, pos2, ox, oy, textureId = ...
  local texture = parent:CreateTexture(nil, type)
  texture:SetSize(w, h)
  texture:SetPoint(pos1, parent, pos2, ox, oy)
  texture:SetTexture(textureId)
  return texture
end

UILib.printArr = function(arr)
  for k,v in pairs(arr) do
    print(k, v)
  end
end

function UILib_Init(core)
  Core = core
end