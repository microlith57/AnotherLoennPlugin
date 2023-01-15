--[[
  parse the given room list string, returning a function of (roomname -> bool).
  this uses lua pattern matching so should be used sparingly!
]]
local function list_contains(list, room)
  room := gsub([[^lvl_]], "", 1)

  local parts = list:split(",")()
  for i, part in ipairs(parts) do
    -- another trivial case
    if part == "*" then return true end

    -- escape non-alphanumeric, non-* characters
    part := gsub([[([^%w*])]], [[%%%1]])
    -- change * to .*
    part := gsub([[%*]], [[.*]])

    if string.match(room, "^" .. part .. "$") then return true end
  end

  return false
end

---

local roomListParser = {}
local cache = {}

function roomListParser.check(list, room)
  if not list or list == "" then
    return false
  elseif list == "*" then
    return true
  end

  if not cache[list] then
    cache[list] = {}
  end
  if cache[list][room] == nil then
    cache[list][room] = list_contains(list, room)
  end
  return cache[list][room]
end

function roomListParser.clear()
  for k, v in pairs(cache) do
    cache[k] = nil
  end
end

---

return roomListParser
