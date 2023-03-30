local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.featureEnabled("room_mover") then
  return nil -- not {}, because that would result in an empty tool
end

local viewportHandler = require("viewport_handler")
local state = require("loaded_state")
local utils = require("utils")
local history = require("history")
local snapshot = require("structs.snapshot")

---

local tool = {
  _type = "tool",
  name = "anotherloennplugin_room_mover",
  group = "placement_end",
  image = nil,
  layer = "anotherloennplugin_move_rooms",
  validLayers = {
    "anotherloennplugin_move_rooms"
  }
}

local moving = {} -- list of { room, orig_x, orig_y }
local startX, startY = 0, 0
local currentX, currentY = 0, 0

---

local function moveRoom(room, orig_x, orig_y, dx, dy)
  require("logging").info("moving "..room.name.." by "..dx..","..dy)

  room.x = math.floor((orig_x + dx) / 8) * 8
  room.y = math.floor((orig_y + dy) / 8) * 8

  return (room.x ~= orig_x) or (room.y ~= orig_y)
end

---

local function cancel(rooms)
  local any = (#rooms > 0)

  for i, v in ipairs(rooms) do
    local room, orig_x, orig_y = unpack(v)
    room.x, room.y = orig_x, orig_y
    rooms[i] = nil
  end

  require("logging").info("cancelled move")
  return any
end

---

function tool.mousepressed(x, y, _button, _istouch, _presses)
  currentX, currentY = viewportHandler.getMapCoordinates(x, y)

  require("logging").info("mousepressed @ "..x..","..y)

  if #moving > 0 then
    cancel(moving)
  end

  local sel, selType = state.getSelectedItem()

  if selType == "room" then
    -- moving one room

    if currentX < sel.x or currentX >= sel.x + sel.width or
       currentY < sel.y or currentY >= sel.y + sel.height then
      return false
    end

    table.insert(moving, {sel, sel.x, sel.y})
  elseif selType == "table" then
    -- moving several things, hopefully all of which are rooms
    local hovered = false

    for subsel, subselType in pairs(sel) do
      if subselType == "room" then
        if currentX >= subsel.x and currentX < subsel.x + subsel.width and
           currentY >= subsel.y and currentY < subsel.y + subsel.height then
          hovered = true
        end

        table.insert(moving, {subsel, subsel.x, subsel.y})
      else
        cancel(moving)
        return false
      end
    end

    if not hovered then
      cancel(moving)
      return false
    end
  else
    return false
  end

  if #moving > 0 then
    require("logging").info("began move")
    startX, startY = currentX, currentY
    return true
  else
    return false
  end
end

function tool.mousereleased(x, y, _button, _istouch, _presses)
  currentX, currentY = viewportHandler.getMapCoordinates(x, y)
  local dx, dy = currentX - startX, currentY - startY

  require("logging").info("mousereleased @ "..x..","..y.."; δ="..dx..","..dy)

  if #moving == 0 then
    return false
  end

  local data = {
    rooms = {}, -- map of { room.name = { orig_x, orig_y } }
    dx = dx, dy = dy
  }
  for i, v in ipairs(moving) do
    local room, orig_x, orig_y = unpack(v)
    data.rooms[room.name] = {orig_x, orig_y}
  end

  local function backward(data)
    for _, room in ipairs(state.map.rooms) do
      if data.rooms[room.name] then
        room.x, room.y = unpack(data.rooms[room.name])
      end
    end
  end

  local function forward(data)
    local dx, dy = data.dx, data.dy

    for _, room in ipairs(state.map.rooms) do
      if data.rooms[room.name] then
        local orig_x, orig_y = unpack(data.rooms[room.name])
        moveRoom(room, orig_x, orig_y, dx, dy)
      end
    end
  end

  local modified = false

  for i, v in ipairs(moving) do
    local room, orig_x, orig_y = unpack(v)
    modified = moveRoom(room, orig_x, orig_y, dx, dy) or modified
    moving[i] = nil
  end

  if not modified then return false end

  require("logging").info("committed move")
  history.addSnapshot(snapshot.create("Room move", data, backward, forward))
  return true
end

function tool.mousemoved(x, y, _dx, _dy, _istouch)
  currentX, currentY = viewportHandler.getMapCoordinates(x, y)
  local dx, dy = currentX - startX, currentY - startY

  if #moving == 0 then
    return false
  end

  for i, v in pairs(moving) do
    local room, orig_x, orig_y = unpack(v)
    moveRoom(room, orig_x, orig_y, dx, dy)
  end

  return true
end

function tool.editorMapTargetChanged()
  -- tool.mousereleased(currentX, currentY)
  cancel(moving)
end

---

return tool
