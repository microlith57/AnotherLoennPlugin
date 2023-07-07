local mods = require("mods")
local state = require("loaded_state")
local utils = require("utils")
local matrixLib = require("utils.matrix")
local mapItemUtils = require("map_item_utils")
local snapshot = require("structs.snapshot")

local fillerStruct = require("structs.filler")
local roomStruct = require("structs.room")
local tilesStruct = require("structs.tiles")
local objectTilesStruct = require("structs.object_tiles")

---

local script = {
  name = "convertFillersToRooms",
  displayName = "Convert Fillers to Rooms",
  tooltip = "Makes all vanilla fillers into rooms, with tiles from the surrounding rooms.",
}

---

local function get_tile(tx, ty, rooms)
  for _, room in ipairs(state.map.rooms) do
    local room_tx, room_ty = math.floor(room.x / 8), math.floor(room.y / 8)
    local room_w, room_h = math.floor(room.width / 8), math.floor(room.height / 8)

    local x = tx - room_tx
    local y = ty - room_ty

    if room.tilesFg.matrix:inbounds0(x, y) then
      return room.tilesFg.matrix:get0Inbounds(x, y)
    end
  end

  return "0"
end

local function make_matrix(x, y, w, h)
  -- find rooms to get tiles from
  local rooms = {}
  for _, room in ipairs(state.map.rooms) do
    if room.tilesFg and room.tilesFg.matrix and
       utils.aabbCheckInline(x, y, w, h,
                             math.floor(room.x / 8) - 1,
                             math.floor(room.y / 8) - 1,
                             math.floor(room.width / 8) + 2,
                             math.floor(room.height / 8) + 2) then
      table.insert(rooms, room)
    end
  end

  -- create matrices to represent the 4 edges of the filler, from which materials will be drawn
  local border_top_bottom = matrixLib.filled("0", w, 2)
  local border_left_right = matrixLib.filled("0", 2, h)

  for i = 1, w do
    border_top_bottom:set(i, 1, get_tile(x + i - 1, y - 1, rooms))
    border_top_bottom:set(i, 2, get_tile(x + i - 1, y + h, rooms))
  end
  for j = 1, h do
    border_left_right:set(1, j, get_tile(x - 1, y + j - 1, rooms))
    border_left_right:set(1, j, get_tile(x + w, y + j - 1, rooms))
  end

  -- create and fill the result matrix
  local matrix = matrixLib.filled("0", w, h)

  for i = 1, w do
    for j = 1, h do
      -- find a material from the surrounding rooms' tiles:
      -- first check the tile immediately upwards, then the one to the left, then right, then downwards
      -- otherwise use tiletype 1
      local material = border_top_bottom:get(i, 1, "0")
      if material == "0" then
        material = border_left_right:get(i, 1, "0")
        if material == "0" then
          material = border_left_right:get(i, 2, "0")
          if material == "0" then
            material = border_top_bottom:get(i, 2, "1")
          end
        end
      end

      matrix:set(i, j, material)
    end
  end

  return matrix
end

local function convert(filler, name)
  local x, y = fillerStruct.getPosition(filler)
  local w, h = fillerStruct.getSize(filler)

  local matrix = make_matrix(filler.x, filler.y, filler.width, filler.height)

  local room = roomStruct.decode({
    name = name,
    x = x, y = y, width = w, height = h,
    __children = {
      {
        __name = "solids",
        innerText = tilesStruct.matrixToTileStringMinimized(matrix)
      },
      { __name = "bg", innerText = ""},
      { __name = "objtiles", innerText = "" },
      { __name = "fgtiles", innerText = "" },
      { __name = "bgtiles", innerText = "" },
    },
  })

  mapItemUtils.addItem(state.map, room)

  return room
end

---

function script.prerun()
  local prev = utils.deepcopy(state.map.fillers)
  local created_rooms = {}

  -- todo move forward, backward outside of prerun, and use data

  local function forward(data)
    local existing_fillers = $(state.map.rooms):filter(room -> room.name:sub(1, 8) == "_filler_")

    for _, filler in ipairs(state.map.fillers) do
      local x = (filler.x < 0 and "n" or "") .. math.abs(filler.x)
      local y = (filler.y < 0 and "n" or "") .. math.abs(filler.y)

      local name = "_filler_" .. x .. "_" .. y
      -- hope no-one does any weird naming trickery that invalidates this approach
      local taken = existing_fillers:count(room -> room.name:sub(1, #name) == name)

      if taken > 0 then
        name = name .. "_" .. tostring(taken)
      end

      created_rooms[name] = convert(filler, name)
    end

    state.map.fillers = {}
  end

  local function backward(data)
    state.map.fillers = prev

    for name, room in pairs(created_rooms) do
      mapItemUtils.deleteRoom(state.map, room)
    end

    created_rooms = {}
  end

  forward()

  return snapshot.create(script.name, {}, backward, forward)
end

---

return script
