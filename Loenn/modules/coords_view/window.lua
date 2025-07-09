local mods = require("mods")

local ui = require("ui")
local uie = require("ui.elements")
local widgetUtils = require("ui.widgets.utils")

local viewportHandler = require("viewport_handler")

local languageRegistry = require("language_registry")
local language = languageRegistry.getLanguage()

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "alp_coords_view"

---

local baseOrder = {
  "screen",
  "world",
  "world_tiles",
  "world_snap",
  "room",
  "room_tiles",
  "room_snap",
}

local order = baseOrder -- settings.rows

local labels = {}
for _, k in ipairs(order) do
  table.insert(labels, {
    uie.label(tostring(language.ui.anotherloennplugin.coords_window.rows[k])),
    uie.label("")
  })
end

---

local coordsWindow = {active = false}
coordsWindow.group = nil -- added in ui/windows/coords_view.lua
local windowX, windowY = 0, 0

local window

function coordsWindow.open()
  if window then return window end
  coordsWindow.active = true

  local layout = uie.row {
    uie.column {}, uie.column {}
  }:with {
    style = { padding = 8 }
  }

  for i, pair in ipairs(labels) do
    local left, right = table.unpack(pair)
    layout.children[1]:addChild(left)
    layout.children[2]:addChild(right)
  end

  window = uie.window("Coordinate Viewer", layout)
  window.titlebar.style.padding = 4

  windowPersister.trackWindow(windowPersisterName, window)
  widgetUtils.preventOutOfBoundsMovement(window)

  coordsWindow.group.parent:addChild(window)
  coordsWindow.group:reflow()
  ui.root:recollect()

  return window
end

function coordsWindow.updateCoords(values)
  for i, k in ipairs(order) do
    local right = labels[i][2]

    if values[k] then
      right.text = values[k][1] .. ", " .. values[k][2]
    else
      right.text = ""
    end
  end
end

function coordsWindow.close()
  if not window then return end
  coordsWindow.active = false

  windowPersister.removeActiveWindow(windowPersisterName, window)
  window:removeSelf()
  window = nil
end

function coordsWindow.toggle()
  if window then
    coordsWindow.close()
  else
    return coordsWindow.open()
  end
end

return coordsWindow
