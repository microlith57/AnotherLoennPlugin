local mods = require("mods")
local utils = require("utils")
local configs = require("configs")
local viewportHandler = require("viewport_handler")
local drawing = require("utils.drawing")
local colors = require("consts.colors")

local ui = require("ui")

local settings = mods.requireFromPlugin("modules.nicer_mouse_pan.settings")

---

local device = {_enabled = true, _type = "device"}
device.earlier_device = {_enabled = true, _type = "device"}

local grabbing = false
local lastWrapDx, lastWrapDy = 0, 0

local autoscroll_mode
local autoscrollX, autoscrollY = 0, 0

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

---

function device.mouseclicked(x, y, button, istouched, presses)
  local autoscrollButton = settings.autoscroll_button or configs.editor.canvasZoomExtentsButton

  if autoscroll_mode then
    autoscroll_mode = nil
    return true
  end

  if button == autoscrollButton and presses == 1 then
    autoscroll_mode = "click"
    autoscrollX, autoscrollY = x, y
    return true
  end
end

function device.mousedragmoved(x, y, dx, dy, button, istouch)
  local actionButton = configs.editor.toolActionButton
  local movementButton = configs.editor.canvasMoveButton
  local autoscrollButton = settings.autoscroll_button
  local viewport = viewportHandler.viewport

  if button == autoscrollButton then
    if not autoscroll_mode then
      autoscroll_mode = "drag"
      autoscrollX, autoscrollY = x, y
    end
    return true
  end

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

    mode = settings.wrap_mode
    if love.mouse.isDown(actionButton) then
      mode = settings.wrap_mode_when_tool_action_pressed
    end

    local thisWrapDx = wrap(x, dx, settings.wrap_margin, viewport.width - settings.wrap_margin, mode)
    local thisWrapDy = wrap(y, dy, settings.wrap_margin, viewport.height - settings.wrap_margin, mode)

    if thisWrapDx ~= 0 then
      love.mouse.setX(x + thisWrapDx)
    end
    if thisWrapDy ~= 0 then
      love.mouse.setY(y + thisWrapDy)
    end

    lastWrapDx, lastWrapDy = thisWrapDx, thisWrapDy
  end
end

function device.mousereleased(x, y, button, istouch, presses)
  local movementButton = configs.editor.canvasMoveButton
  local autoscrollButton = settings.autoscroll_button

  if button == movementButton then
    if grabbing then
      grabbing = false
      love.mouse.setGrabbed(false)
    end
  elseif button == autoscrollButton and autoscroll_mode == "drag" then
    autoscroll_mode = nil
  end
end

device.earlier_device.mousereleased = device.mousereleased

function device.update(dt)
  local viewport = viewportHandler.viewport

  if autoscroll_mode then
    local x, y = viewportHandler.getMousePosition()
    local dx, dy = autoscrollX - x, autoscrollY - y
    local r = settings.autoscroll_widget_radius

    local delta_sq = math.pow(dx, 2) + math.pow(dy, 2)
    if delta_sq <= math.pow(r, 2) then
      return
    end

    local power, speed = settings.autoscroll_power, settings.autoscroll_speed

    local ax, ay = math.abs(dx / r), math.abs(dy / r)
    local avx, avy = math.pow(ax, power) * speed, math.pow(ay, power) * speed
    local vx, vy = utils.sign(dx) * avx, utils.sign(dy) * avy

    viewport.x -= vx * dt
    viewport.y -= vy * dt
  end
end

local function lerp(a,b,t) return a+(b-a)*t end

local function chevron(x, y, r, theta, sel, fac)
  fac = utils.clamp(fac, 0, 1)
  if sel then
    local ra, ga, ba = table.unpack(colors.resizeTriangleColor)
    local rb, gb, bb = table.unpack(colors.roomBorderColors[1])
    love.graphics.setColor(
      lerp(ra, rb, fac),
      lerp(ga, gb, fac),
      lerp(ba, bb, fac)
    )
  else
    love.graphics.setColor(colors.resizeTriangleColor)
  end

  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(theta)
  love.graphics.translate(0, r - 4)
  love.graphics.line(
    -4, -4,
     0,  0,
     4, -4
  )
  love.graphics.pop()
end

function device.earlier_device.draw()
  if autoscroll_mode then
    drawing.callKeepOriginalColor(function()
      local x, y, r = autoscrollX, autoscrollY, settings.autoscroll_widget_radius
      local mx, my = viewportHandler.getMousePosition()
      local dx, dy = x - mx, y - my
      local delta = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
      local sel = delta > r

      love.graphics.setColor(colors.roomBackgroundColors[1])
      love.graphics.circle("fill", x, y, r)

      -- dot
      if sel then
        love.graphics.setColor(colors.resizeTriangleColor)
      else
        love.graphics.setColor(colors.roomBorderColors[1])
      end
      love.graphics.circle("fill", x, y, 2)

      -- chevrons
      if r >= 14 then
        chevron(x, y, r, math.pi * 0.0, sel, -dy / delta)
        chevron(x, y, r, math.pi * 0.5, sel,  dx / delta)
        chevron(x, y, r, math.pi * 1.0, sel,  dy / delta)
        chevron(x, y, r, math.pi * 1.5, sel, -dx / delta)
      end

      -- border
      love.graphics.setColor(colors.roomBorderColors[1])
      love.graphics.circle("line", x, y, r)
    end)
  end
end

---

function device._hook()
  if ui.__anotherloennplugin_unload then
    ui.__anotherloennplugin_unload()
  end

  prev_ui_mousemoved = ui.mousemoved
  function ui.mousemoved(...)
    local res = prev_ui_mousemoved(...)

    if (grabbing or autoscroll_mode) and settings.override_ui then
      ui.hovering = false
      return false
    end

    return res
  end

  function ui.__anotherloennplugin_unload()
    ui.mousemoved = prev_ui_mousemoved
  end
end

---

return device
