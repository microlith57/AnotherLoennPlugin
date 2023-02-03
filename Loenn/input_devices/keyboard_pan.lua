local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")

local speed = tonumber(settings.get("speed", 1024, "keyboard_pan")) or 1024
local timer_max = tonumber(settings.get("time_after_each_keypress_to_allow_movement", 1, "keyboard_pan")) or 1

---

local viewportHandler = require("viewport_handler")
local hotkeyHandler = require("hotkey_handler")
local hotkeyStruct = require("structs.hotkey")

---

local device = {_enabled = true, _type = "device"}
local subpixel_x, subpixel_y = 0, 0
local key_pressed_timer
local keys = {}

function device.update(dt)
  if not key_pressed_timer or key_pressed_timer > timer_max then
    return
  end

  local viewport = viewportHandler.viewport
  local dx, dy = subpixel_x, subpixel_y

  if keys.left and hotkeyStruct.hotkeyActive(keys.left) then
    dx -= speed * dt
  end
  if keys.right and hotkeyStruct.hotkeyActive(keys.right) then
    dx += speed * dt
  end
  if keys.up and hotkeyStruct.hotkeyActive(keys.up) then
    dy -= speed * dt
  end
  if keys.down and hotkeyStruct.hotkeyActive(keys.down) then
    dy += speed * dt
  end

  viewport.x += dx
  viewport.y += dy

  key_pressed_timer += dt
end

---

local function callback()
  key_pressed_timer = 0
end

keys.left = hotkeyStruct.createHotkey(
  settings.get("hotkey_left", "a", "keyboard_pan"),
  callback)
keys.right = hotkeyStruct.createHotkey(
  settings.get("hotkey_right", "d", "keyboard_pan"),
  callback)
keys.up = hotkeyStruct.createHotkey(
  settings.get("hotkey_up", "w", "keyboard_pan"),
  callback)
keys.down = hotkeyStruct.createHotkey(
  settings.get("hotkey_down", "s", "keyboard_pan"),
  callback)

-- add the hotkeys
local _orig_createHotkeyDevice = hotkeyHandler.createHotkeyDevice
function hotkeyHandler.createHotkeyDevice(hotkeys)
  for dir, hotkey in pairs(keys) do
    table.insert(hotkeys, hotkey)
  end
  hotkeyHandler.createHotkeyDevice = _orig_createHotkeyDevice
  return _orig_createHotkeyDevice(hotkeys)
end

---

return device
