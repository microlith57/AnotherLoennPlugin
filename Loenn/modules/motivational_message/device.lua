local mods = require("mods")
local viewportHandler = require("viewport_handler")
local drawing = require("utils.drawing")
local loadedState = require("loaded_state")

local ui = require("ui")
local uie = require("ui.elements")

local hotkeyHandler = require("hotkey_handler")

local settings = mods.requireFromPlugin("modules.motivational_message.settings")

---

local device = {_enabled = true, _type = "device"}

---

hotkeyHandler.addHotkey("global", settings.hotkey, function() device.messageWindow.toggle() end)

---

return device
