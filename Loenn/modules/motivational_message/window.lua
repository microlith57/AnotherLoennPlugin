local mods = require("mods")

local ui = require("ui")
local uie = require("ui.elements")
local widgetUtils = require("ui.widgets.utils")

local viewportHandler = require("viewport_handler")

local languageRegistry = require("language_registry")
local language = languageRegistry.getLanguage()

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "alp_motivational_message"

local settings = mods.requireFromPlugin("modules.motivational_message.settings")

---

local messageWindow = {active = false}
messageWindow.group = nil -- added in ui/windows/motivational_message.lua
local windowX, windowY = 0, 0

local window

function messageWindow.open()
  if window then return window end
  messageWindow.active = true

  local layout = uie.column {
    uie.label(settings.message)
  }:with {
    style = { padding = 8 }
  }

  window = uie.window(settings.title, layout)
  window.titlebar.style.padding = 4

  windowPersister.trackWindow(windowPersisterName, window)
  widgetUtils.preventOutOfBoundsMovement(window)

  messageWindow.group.parent:addChild(window)
  messageWindow.group:reflow()
  ui.root:recollect()

  return window
end

function messageWindow.close()
  if not window then return end
  messageWindow.active = false

  windowPersister.removeActiveWindow(windowPersisterName, window)
  window:removeSelf()
  window = nil
end

function messageWindow.toggle()
  if window then
    messageWindow.close()
  else
    return messageWindow.open()
  end
end

return messageWindow
