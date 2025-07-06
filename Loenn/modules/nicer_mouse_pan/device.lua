local mods = require("mods")
local configs = require("configs")
local viewportHandler = require("viewport_handler")
local drawing = require("utils.drawing")

local ui = require("ui")

local settings = mods.requireFromPlugin("modules.nicer_mouse_pan.settings")

---

local device = {_enabled = true, _type = "device"}
device.earlier_device = {_enabled = true, _type = "device"}

local lastWrapDx, lastWrapDy = 0, 0
local grabbing = false

local function wrap(s, ds, min, max, mode)
  if ds < 0 and s < min then
    if mode == "wrap" then
      return max - s
    elseif mode == "cushion" then
      return min - s
    end
  elseif ds > 0 and s > max then
    if mode == "wrap" then
      return min - s
    elseif mode == "cushion" then
      return max - s
    end
  end

  return 0
end

--[[
  whenever certain actions are being performed (eg. panning), ensure the cursor stays inside the window, by wrapping it around the window
]]
function device.mousedragmoved(x, y, dx, dy, button, istouch)
  if already_mousedragmoved then return end

  local movementButton = configs.editor.canvasMoveButton
  local canvasZoomExtentsButton = configs.editor.canvasZoomExtentsButton
  local viewport = viewportHandler.viewport

  if button == movementButton then
    grabbing = true
    if settings.grab_mouse and not love.mouse.isGrabbed() then
      love.mouse.setGrabbed(true)
    end

    viewport.x += lastWrapDx
    viewport.y += lastWrapDy
    dx -= lastWrapDx
    dy -= lastWrapDy

    lastWrapDx, lastWrapDy = 0, 0

    local thisWrapDx = wrap(x, dx, settings.wrap_margin, viewport.width - settings.wrap_margin, settings.wrap_mode)
    local thisWrapDy = wrap(y, dy, settings.wrap_margin, viewport.height - settings.wrap_margin, settings.wrap_mode)

    if thisWrapDx ~= 0 then
      love.mouse.setX(x + thisWrapDx)
    end
    if thisWrapDy ~= 0 then
      love.mouse.setY(y + thisWrapDy)
    end

    lastWrapDx, lastWrapDy = thisWrapDx, thisWrapDy
  elseif button == canvasZoomExtentsButton then
    -- ...
  end
end

function device.mousereleased(x, y, button, istouch, presses)
  local movementButton = configs.editor.canvasMoveButton

  if button == movementButton then
    if grabbing then
      grabbing = false
      love.mouse.setGrabbed(false)
    end
  end
end

---

function device._hook()
  if ui.__anotherloennplugin_unload then
    ui.__anotherloennplugin_unload()
  end

  prev_ui_mousemoved = ui.mousemoved
  function ui.mousemoved(...)
    prev_ui_mousemoved(...)

    if grabbing and settings.override_ui then
      ui.hovering = false
      return false
    end
  end
end

---

return device
