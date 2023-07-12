local mods = require("mods")
local viewportHandler = require("viewport_handler")
local drawing = require("utils.drawing")
local loadedState = require("loaded_state")

local ui = require("ui")
local uie = require("ui.elements")

local hotkeys = require("standard_hotkeys")
local hotkeyStruct = require("structs.hotkey")

local settings = mods.requireFromPlugin("modules.coords_view.settings")

---

local device = {_enabled = true, _type = "device"}

local sx, sy
local wx, wy
local tx, ty
local rx, ry
local rtx, rty

---

local function tile(x, y)
  return math.floor(x / 8 + 0.4), math.floor(y / 8 + 0.4)
end

local function getCoords(x, y)
  sx, sy = x or sx, y or sy
  if not sx or not sy then
    sx, sy = viewportHandler.getMousePosition()
  end

  local map_x, map_y = viewportHandler.getMapCoordinates(sx, sy)
  wx, wy = math.floor(map_x + 0.4), math.floor(map_y + 0.4)
  tx, ty = tile(wx, wy)

  local res = {
    screen = {sx, sy},
    world = {wx, wy},
    world_tiles = {tx, ty},
    world_snap = {tx * 8, ty * 8}
  }

  local room = loadedState.getSelectedRoom()
  if room then
    rx, ry = wx - room.x, wy - room.y
    rtx, rty = tile(rx, ry)

    res.room = {rx, ry}
    res.room_tiles = {rtx, rty}
    res.room_snap = {rtx * 8, rty * 8}
  else
    rx, ry = nil, nil
  end

  return res
end

function device.mousemoved(x, y, dx, dy, istouch)
  if not device.coordsWindow or not device.coordsWindow.active then return end

  local viewport = viewportHandler.viewport

  if x >= 0 and y >= 0 and x < viewport.width and y < viewport.height then
    device.coordsWindow.updateCoords(getCoords(x, y))
  end
end

function device.draw()
  if not device.coordsWindow or not device.coordsWindow.active then return end

  device.coordsWindow.updateCoords(getCoords())

  local viewport = viewportHandler.viewport

  drawing.callKeepOriginalColor(
    function()
      local lineWidth = love.graphics.getLineWidth()
      love.graphics.setLineWidth(lineWidth / viewport.scale)

      love.graphics.push()
      love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
      love.graphics.scale(viewport.scale)

      local length = settings.cursor_length / viewport.scale

      love.graphics.setColor(255, 0, 0, 255)
      love.graphics.line(tx * 8 - length, ty * 8, tx * 8 + length, ty * 8)
      love.graphics.line(tx * 8, ty * 8 - length, tx * 8, ty * 8 + length)

      love.graphics.setColor(255, 255, 0, 255)
      love.graphics.line(wx - length, wy, wx + length, wy)
      love.graphics.line(wx, wy - length, wx, wy + length)

      love.graphics.pop()
      love.graphics.setLineWidth(lineWidth)
    end
  )
end

---

table.insert(hotkeys, hotkeyStruct.createHotkey(settings.hotkey, function() device.coordsWindow.toggle() end))

---

return device
