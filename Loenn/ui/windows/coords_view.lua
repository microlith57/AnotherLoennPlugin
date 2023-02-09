local mods = require("mods")

local ui = require("ui")
local uie = require("ui.elements")
local widgetUtils = require("ui.widgets.utils")

---

local coordsWindow = {}
local coordsWindowGroup = uie.group({})
local windowX, windowY = 0, 0

function coordsWindow.displayCoordinates()
  coordsWindow.content = uie.column({})
  coordsWindow.content.style.padding = 8

  local window = uie.window("Coordinate Viewer", coordsWindow.content):with({
    x = windowX,
    y = windowY,

    updateHidden = true
  }):hook({
    update = function(orig, self, dt)
      orig(self, dt)
      windowX, windowY = self.x, self.y
    end
  })
  window.titlebar.style.padding = 4

  coordsWindowGroup.parent:addChild(window)
  coordsWindowGroup:reflow()
  ui.root:recollect()

  return window
end

function coordsWindow.getWindow()
  local coordsDevice = mods.requireFromPlugin("input_devices.coords_view")
  coordsDevice.coordsWindow = coordsWindow

  return coordsWindowGroup
end

return coordsWindow
