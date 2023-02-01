local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.featureEnabled("room_mover") then
  return {}
end

local viewportHandler = require("viewport_handler")
local loadedState = require("loaded_state")
local utils = require("utils")
local history = require("history")
local snapshot = require("structs.snapshot")

---

local tool = {
  _type = "tool",
  name = "anotherloennplugin_room_mover",
  group = "anotherloennplugin_room_mover",
  image = nil,
  layer = "anotherloennplugin_room_mover",
  validLayers = {
    "anotherloennplugin_room_mover"
  }
}

local dragging
local draggingStartX, draggingStartY
local origX, origY = 0, 0
local deltaX, deltaY = 0, 0
local itemBeforeMove
local tableItemsBeforeMove = {}
local targetType
local previousCursor

---

local function moveItem(item, orig_pos, itemType, dx, dy)
  if itemType == "room" then
    if not orig_pos.x or not orig_pos.y then return end
    local new_x, new_y = orig_pos.x + 8 * math.floor(dx), orig_pos.y + 8 * math.floor(dy)

    item.x = new_x
    item.y = new_y
  elseif itemType == "filler" then
    if not orig_pos.x or not orig_pos.y then return end
    local new_x, new_y = orig_pos.x + math.floor(dx), orig_pos.y + math.floor(dy)

    item.x = new_x
    item.y = new_y
  elseif itemType == "table" then
    for iitem, iitemType in pairs(item) do
      local iorig_pos = tableItemsBeforeMove[iitem]
      if iorig_pos and iorig_pos.x and iorig_pos.y and (iitemType == "room" or iitemType == "filler") then
        moveItem(iitem, iorig_pos, iitemType, dx, dy)
      end
    end
  end
end

---

function tool.mousepressed(x, y, button, istouch, presses)
  local item, itemType = loadedState.getSelectedItem()

  local canDrag = true
  if itemType == "room" then
    local cursorX, cursorY = viewportHandler.getRoomCoordinates(item, x, y)
    if cursorX < 0 or cursorX > item.width or cursorY < 0 or cursorY > item.height then
      canDrag = false
    end
  elseif itemType == "filler" then
    local cursorX, cursorY = viewportHandler.getMapCoordinates(x, y)
    if cursorX < item.x or cursorX > (item.x + item.width) * 8 or cursorY < item.y * 8 or cursorY > (item.y + item.height) * 8 then
      canDrag = false
    end
  elseif itemType == "table" then
    tableItemsBeforeMove = {}
    for iitem, iitemtype in pairs(item) do
      tableItemsBeforeMove[iitem] = {x = iitem.x, y = iitem.y}
      if iitemType == "room" then
        local cursorX, cursorY = viewportHandler.getRoomCoordinates(iitem, x, y)
        if cursorX < 0 or cursorX > item.width or cursorY < 0 or cursorY > item.height then
          canDrag = false
        end
      elseif iitemType == "filler" then
        local cursorX, cursorY = viewportHandler.getMapCoordinates(x, y)
        if cursorX < iitem.x or cursorX > (item.x + iitem.width) * 8 or cursorY < iitem.y * 8 or cursorY > (iitem.y + item.height) * 8 then
          canDrag = false
        end
      end
    end
  end

  if canDrag then
    dragging = true
    madeChanges = false
    deltaX, deltaY = 0, 0
    if item.x and item.y then
      origX, origY = item.x, item.y
    end
    itemBeforeMove = utils.deepcopy(item)
    targetType = itemType
  end
end

function tool.mousereleased(x, y, button, istouch, presses)
  local consume = not (not dragging)

  dragging = false

  if madeChanges then
    local item, itemType = loadedState.getSelectedItem()

    local data = {
      dx = deltaX,
      dy = deltaY,
      ox = itemBeforeMove.x,
      oy = itemBeforeMove.y
    }

    local function backward(data)
      moveItem(item, {x = data.ox, y = data.oy}, itemType, 0, 0)
    end
    local function forward(data)
      moveItem(item, {x = data.ox, y = data.oy}, itemType, data.dx, data.dy)
    end

    history.addSnapshot(snapshot.create("Room move", data, backward, forward))
    madeChanges = false
  end

  return consume
end

function tool.mousemoved(x, y, dx, dy, istouch)
  local item, itemType = loadedState.getSelectedItem()

  if dragging then
    if not item then
      return false
    end

    madeChanges = true

    local cursorX, cursorY = viewportHandler.getMapCoordinates(x, y)
    local tileX, tileY = cursorX / 8, cursorY / 8

    deltaX, deltaY = tileX - draggingStartX, tileY - draggingStartY
    moveItem(item, {x = origX, y = origY}, itemType, deltaX, deltaY)

    return true
  else
    local cursorX, cursorY = viewportHandler.getMapCoordinates(x, y)
    draggingStartX, draggingStartY = viewportHandler.pixelToTileCoordinates(cursorX, cursorY)
  end
end

function tool.editorMapTargetChanged()
  dragging = false

  if madeChanges then
    local item, itemType = loadedState.getSelectedItem()

    local data = {
      dx = deltaX,
      dy = deltaY,
      ox = itemBeforeMove.x,
      oy = itemBeforeMove.y
    }

    local function backward(data)
      moveItem(item, {x = data.ox, y = data.oy}, itemType, 0, 0)
    end
    local function forward(data)
      moveItem(item, {x = data.ox, y = data.oy}, itemType, data.dx, data.dy)
    end

    history.addSnapshot(snapshot.create("Room move", data, backward, forward))
    madeChanges = false
  end
end


---

return tool
