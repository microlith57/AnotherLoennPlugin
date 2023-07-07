local mods = require("mods")

local viewportHandler = require("viewport_handler")
local ui = require("ui.main")

local hotkeys = require("standard_hotkeys")
local hotkeyStruct = require("structs.hotkey")

local settings = mods.requireFromPlugin("modules.keyboard_pan.settings")

---

local device = {_enabled = true, _type = "device"}
local keys = {}

--[[
  pan the viewport using the configured keys (wasd by default)
]]
function device.update(dt)
  if ui.focusing then return end

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
end

---

local function callback() end

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
