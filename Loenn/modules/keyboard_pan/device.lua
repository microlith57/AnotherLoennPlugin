local mods = require("mods")

local viewportHandler = require("viewport_handler")

local hotkeys = require("standard_hotkeys")
local hotkeyStruct = require("structs.hotkey")

local settings = mods.requireFromPlugin("modules.keyboard_pan.settings")

---

local device = {_enabled = true, _type = "device"}
local key_pressed_timer
local keys = {}

--[[
  pan the viewport using the configured keys (wasd by default)

  this checks key_pressed_timer to make sure the viewport actually has focus,
  to (mostly) avoid panning while in textboxes.
]]
function device.update(dt)
  -- only proceed if one of the keys has been pressed recently enough,
  -- which means we probably have focus
  if not key_pressed_timer or key_pressed_timer > settings.timer_max then
    -- todo: check focus properly
    return
  end

  local viewport = viewportHandler.viewport
  local dx, dy = 0, 0

  if keys.left and hotkeyStruct.hotkeyActive(keys.left) then
    dx -= settings.speed * dt
  end
  if keys.right and hotkeyStruct.hotkeyActive(keys.right) then
    dx += settings.speed * dt
  end
  if keys.up and hotkeyStruct.hotkeyActive(keys.up) then
    dy -= settings.speed * dt
  end
  if keys.down and hotkeyStruct.hotkeyActive(keys.down) then
    dy += settings.speed * dt
  end

  viewport.x += dx
  viewport.y += dy

  key_pressed_timer += dt
end

---

local function callback()
  -- we know we have focus now, so reset the timer
  key_pressed_timer = 0
end

keys.left  = hotkeyStruct.createHotkey(settings.hotkey_left, callback)
keys.right = hotkeyStruct.createHotkey(settings.hotkey_right, callback)
keys.up    = hotkeyStruct.createHotkey(settings.hotkey_up, callback)
keys.down  = hotkeyStruct.createHotkey(settings.hotkey_down, callback)

table.insert(hotkeys, keys.left)
table.insert(hotkeys, keys.right)
table.insert(hotkeys, keys.up)
table.insert(hotkeys, keys.down)

---

return device
