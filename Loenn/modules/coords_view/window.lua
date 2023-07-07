local mods = require("mods")

local ui = require("ui")
local uie = require("ui.elements")
local widgetUtils = require("ui.widgets.utils")

---

local coordsWindow = {}
coordsWindow.group = nil -- added in ui/windows/coords_view.lua
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

  coordsWindow.group.parent:addChild(window)
  coordsWindow.group:reflow()
  ui.root:recollect()

  return window
end

return coordsWindow
