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
device.coordsWindow = nil

local activeWindow = false

local mouseX, mouseY = 0, 0
local worldX, worldY = 0, 0
local tileX, tileY = 0, 0
local roomX, roomY
local roomTileX, roomTileY

---

local function updateCoords(force)
  -- todo move to window file
  if not activeWindow then
    return
  end

  local viewport = viewportHandler.viewport

  local new_worldX, new_worldY = viewportHandler.getMapCoordinates(mouseX + 0.5 * viewport.scale, mouseY + 0.5 * viewport.scale)

  if not force and new_worldX == worldX and new_worldY == worldY then
    return
  end

  worldX, worldY = new_worldX, new_worldY
  tileX, tileY = math.floor(worldX / 8 + 0.4), math.floor(worldY / 8 + 0.4)

  local room = loadedState.getSelectedRoom()
  if room then
    roomX, roomY = worldX - room.x, worldY - room.y
    roomTileX, roomTileY = math.floor(roomX / 8 + 0.4), math.floor(roomY / 8 + 0.4)
  else
    roomX, roomY, roomTileX, roomTileY = nil, nil, nil, nil
  end

  function set(index, text)
    if device.coordsWindow.content.children[index] then
      device.coordsWindow.content.children[index]:setText(text)
    else
      device.coordsWindow.content:addChild(uie.label(text))
    end
  end

  function unset(index)
    if device.coordsWindow.content.children[index] then
      device.coordsWindow.content.children[index]:removeSelf()
    end
  end

  -- todo use table instead

  set(1, "screen: (" .. tostring(mouseX) .. ", " .. tostring(mouseY) .. ")")
  set(2, "world:          (" .. tostring(worldX) .. ", " .. tostring(worldY) .. ")")
  set(3, "world / 8:     (" .. tostring(tileX) .. ", " .. tostring(tileY) .. ")")
  set(4, "world, snap: (" .. tostring(tileX * 8) .. ", " .. tostring(tileY * 8) .. ")")

  if roomX and roomY then
    set(5, "room:           (" .. tostring(roomX) .. ", " .. tostring(roomY) .. ")")
    set(6, "room / 8:      (" .. tostring(roomTileX) .. ", " .. tostring(roomTileY) .. ")")
    set(7, "room, snap:  (" .. tostring(roomTileX * 8) .. ", " .. tostring(roomTileY * 8) .. ")")
  else
    unset(5)
    unset(6)
    unset(7)
  end
end

---

function device.mousemoved(x, y, dx, dy, istouch)
  local viewport = viewportHandler.viewport

  if x >= 0 and y >= 0 and x < viewport.width and y < viewport.height then
    if mouseX ~= x or mouseY ~= y then
      mouseX, mouseY = x, y
      updateCoords(true)
    end
  end
end

function device.draw()
  if not activeWindow then
    return
  end

  updateCoords()

  local viewport = viewportHandler.viewport

  drawing.callKeepOriginalColor(
    function()
      local lineWidth = love.graphics.getLineWidth()
      love.graphics.setLineWidth(lineWidth / viewport.scale)

      love.graphics.push()
      love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
      love.graphics.scale(viewport.scale)

      local length = settings.cursor_length / viewport.scale

      local coarseX, coarseY = tileX * 8, tileY * 8
      love.graphics.setColor(255, 0, 0, 255)
      love.graphics.line(coarseX - length, coarseY, coarseX + length, coarseY)
      love.graphics.line(coarseX, coarseY - length, coarseX, coarseY + length)

      love.graphics.setColor(255, 255, 0, 255)
      love.graphics.line(worldX - length, worldY, worldX + length, worldY)
      love.graphics.line(worldX, worldY - length, worldX, worldY + length)

      love.graphics.pop()
      love.graphics.setLineWidth(lineWidth)
    end
  )
end

---

local function toggleCoordsWindow()
  if activeWindow then
    ui.root:recollect()
    activeWindow:removeSelf()
    activeWindow = false
  else
    activeWindow = device.coordsWindow.displayCoordinates()
    updateCoords(true)
  end
end

---

table.insert(hotkeys, hotkeyStruct.createHotkey(settings.hotkey, toggleCoordsWindow))

---

return device
