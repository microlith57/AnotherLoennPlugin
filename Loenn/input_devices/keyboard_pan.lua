local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")

do
  local v = require("utils.version_parser")
  if v(settings.get("_config_version", "0.2.1")) < v("0.3.0") then
    local user_edited = (
      settings.get("hotkey_left",  "a", "keyboard_pan") ~= "a" or
      settings.get("hotkey_right", "d", "keyboard_pan") ~= "d" or
      settings.get("hotkey_up",    "w", "keyboard_pan") ~= "w" or
      settings.get("hotkey_down",  "s", "keyboard_pan") ~= "s"
    )

    if not user_edited then
      settings.set("hotkey_left",  "alt + a", "keyboard_pan")
      settings.set("hotkey_right", "alt + d", "keyboard_pan")
      settings.set("hotkey_up",    "alt + w", "keyboard_pan")
      settings.set("hotkey_down",  "alt + s", "keyboard_pan")
    end

    -- stopgap measure pending better settings code
    settings.set("_config_version", "0.3.0")
  end
end

local speed = tonumber(settings.get("speed", 1024, "keyboard_pan")) or 1024
local timer_max = tonumber(settings.get("time_after_each_keypress_to_allow_movement", 1, "keyboard_pan")) or 1

---

local viewportHandler = require("viewport_handler")
local hotkeyHandler = require("hotkey_handler")
local hotkeyStruct = require("structs.hotkey")

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
  if not key_pressed_timer or key_pressed_timer > timer_max then
    return
  end

  local viewport = viewportHandler.viewport
  local dx, dy = 0, 0

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
  -- we know we have focus now, so reset the timer
  key_pressed_timer = 0
end

keys.left = hotkeyStruct.createHotkey(
  settings.get("hotkey_left", "alt + a", "keyboard_pan"),
  callback)
keys.right = hotkeyStruct.createHotkey(
  settings.get("hotkey_right", "ctrl + d", "keyboard_pan"),
  callback)
keys.up = hotkeyStruct.createHotkey(
  settings.get("hotkey_up", "alt + w", "keyboard_pan"),
  callback)
keys.down = hotkeyStruct.createHotkey(
  settings.get("hotkey_down", "alt + s", "keyboard_pan"),
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
