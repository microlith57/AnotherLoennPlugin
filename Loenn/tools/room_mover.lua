local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.5.1") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local cursorUtils = require("utils.cursor")
local viewportHandler = require("viewport_handler")
local loadedState = require("loaded_state")
local utils = require("utils")
local history = require("history")
local snapshot = require("structs.snapshot")

---

local tool = {
  _type = "tool",
  name = "room_mover",
  group = "room_mover",
  image = nil,
  layer = "room_mover",
  validLayers = {
    "room_mover"
  }
}

local dragging
local draggingStartX
local draggingStartY
local deltaX
local deltaY
local itemBeforeMove
local targetType
local previousCursor

---

local function moveItem(item, orig_item, itemType, dx, dy)
  if itemType == "room" then
    local orig_x, orig_y = orig_item.x, orig_item.y
    local new_x, new_y = orig_x + 8 * math.floor(dx), orig_y + 8 * math.floor(dy)

    item.x = new_x
    item.y = new_y
  elseif itemType == "filler" then
    local orig_x, orig_y = orig_item.x, orig_item.y
    local new_x, new_y = orig_x + dx, orig_y + dy

    item.x = new_x
    item.y = new_y
  else
    -- todo
  end
end

local function updateCursor()
  local cursor = cursorUtils.getDefaultCursor()

  if dragging then
    cursor = cursorUtils.useMoveCursor()
  end

  previousCursor = cursorUtils.setCursor(cursor, previousCursor)
end

---

function tool.mousepressed(x, y, button, istouch, presses)
  local item, itemType = loadedState.getSelectedItem()

  if itemType == "room" then
    local cursorX, cursorY = viewportHandler.getRoomCoordinates(item, x, y)
    if cursorX < 0 or cursorX > item.width or cursorY < 0 or cursorY > item.height then
      return false
    end
  elseif itemType == "filler" then
    local cursorX, cursorY = viewportHandler.getRoomCoordinates(item, x, y)
    if cursorX < 0 or cursorX > item.width * 8 or cursorY < 0 or cursorY > item.height * 8 then
      return false
    end
  else
    -- todo
    return false
  end

  dragging = true
  madeChanges = false
  itemBeforeMove = utils.deepcopy(item)
  targetType = itemType
end

function tool.mousereleased(x, y, button, istouch, presses)
  local consume = not (not dragging)

  dragging = false

  if madeChanges then
    local item, itemType = loadedState.getSelectedItem()
    local orig_item = utils.deepcopy(itemBeforeMove)

    local data = {
      dx = deltaX,
      dy = deltaY
    }

    local function backward(data)
      moveItem(item, orig_item, itemType, 0, 0)
    end
    local function forward(data)
      moveItem(item, orig_item, itemType, data.dx, data.dy)
    end

    history.addSnapshot(snapshot.create("Room move", data, backward, forward))
    madeChanges = false
  end

  return consume
end

function tool.mousemoved(x, y, dx, dy, istouch)
  local item, itemType = loadedState.getSelectedItem()

  if dragging then
    madeChanges = true

    local cursorX, cursorY = viewportHandler.getMapCoordinates(x, y)
    local tileX, tileY = viewportHandler.pixelToTileCoordinates(cursorX, cursorY)
    deltaX, deltaY = tileX - draggingStartX, tileY - draggingStartY

    moveItem(item, itemBeforeMove, itemType, deltaX, deltaY)

    -- updateCursor()
    return true
  else
    -- updateCursor()
    local cursorX, cursorY = viewportHandler.getMapCoordinates(x, y)
    draggingStartX, draggingStartY = viewportHandler.pixelToTileCoordinates(cursorX, cursorY)
  end
end

---

return tool
