local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.4.3") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local mods = require("mods")
local parallax = require("parallax")

local parallaxExt = {}

---

--[[
  parse the given room list, returning a function of (roomname -> bool).
  this uses lua pattern matching so should be used sparingly!
]]
function parallaxExt.parseRoomList(list)
  -- handle trivial cases first for efficiency
  if not list or list == "" then
    return function(room) return false end
  elseif list == "*" then
    return function(room) return true end
  end

  local always_true = false

  -- split comma-separated room list into individual patterns
  local patterns = $(list:split(",")()):map(function(i, part)
    -- another trivial case
    if part == "*" then always_true = true end

    -- escape non-alphanumeric, non-* characters
    part := gsub([[([^%w*])]], [[%%%1]])
    -- change * to .*
    part := gsub([[%*]], [[.*]])
    -- force a match on the entire string, not just a substring
    return "^" .. part .. "$"
  end)()

  if always_true then
    return function(room) return true end
  end

  return function(room)
    room := gsub([[^lvl_]], "", 1)

    -- try to match over each pattern individually
    for i, pattern in ipairs(patterns) do
      if string.match(room, pattern) then return true end
    end
    return false
  end
end

---

--[[
  returns whether the given parallax is in the given room, caching values where possible.
]]
function parallaxExt.isInRoom(parallax, room)
  if not parallax or not room then return false end

  local ext = parallaxExt.get(parallax)
  -- create or recreate function caches if necessary
  if ext.only ~= parallax.only or not ext.f_only then
    -- set cache staleness detection value
    ext.only = parallax.only
    -- parse the room lists and create the functions
    ext.f_only = parallaxExt.parseRoomList(ext.only or "*")
    -- invalidate the room list cache
    ext.rooms = {}
  end
  if ext.exclude ~= parallax.exclude or not ext.f_exclude then
    -- set cache staleness detection values
    ext.exclude = parallax.exclude
    -- parse the room lists and create the functions
    ext.f_exclude = parallaxExt.parseRoomList(ext.exclude or "")
    -- invalidate the room list cache
    ext.rooms = {}
  end

  -- create room name cache if necessary
  if not ext.rooms then ext.rooms = {} end

  -- try to retrieve cached value
  if ext.rooms[room] ~= nil then
    return ext.rooms[room]
  end

  -- compute value for cache, and return it
  local result = ext.f_only(room) and not ext.f_exclude(room)
  ext.rooms[room] = result
  return result
end

local exts = {}

--[[
  get the extended data table for the given parallax, creating it if necessary
]]
function parallaxExt.get(parallax)
  if not parallax then return end

  if not exts[parallax] then
    exts[parallax] = {}
  end

  return exts[parallax]
end

---

return parallaxExt
