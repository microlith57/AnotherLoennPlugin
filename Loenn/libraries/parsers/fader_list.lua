local utils = require("utils")

---

--[[
  parse the given fader list, returning a table of values in groups of 4
]]
local function parse(list)
  local values = {}

  if not list or list == "" then
    return values
  end

  -- split the list into parts by ':'
  $(list:split(':')()):foreach(function(i, fader_str)
    -- split each part into two subparts for coords and fade amounts respectively
    local parts = fader_str:split(',')()
    if #parts ~= 2 then return end

    -- split each subpart further into two numbers, from and to
    local coord_part = parts[1]:split('-')()
    local fade_part = parts[2]:split('-')()
    if #coord_part ~= 2 or #fade_part ~= 2 then return end

    -- convert 'n' at the start to '-' before parsing coords
    coord_part[1] := gsub([[^n]], "-")
    coord_part[2] := gsub([[^n]], "-")

    table.insert(values, math.floor(tonumber(coord_part[1]))) -- coordFrom
    table.insert(values, math.floor(tonumber(coord_part[2]))) -- coordTo
    table.insert(values, tonumber(fade_part[1])) -- fadeFrom
    table.insert(values, tonumber(fade_part[2])) -- fadeTo
  end)

  return values
end

--[[
  get the fade value in [0, 1] for a fader at a given coordinate.
]]
local function process_fade(fader, coord)
  local a = 1

  if not fader or #fader < 4 then return a end

  for i=1, #fader, 4 do
    local coordFrom, coordTo, fadeFrom, fadeTo = fader[i], fader[i+1], fader[i+2], fader[i+3]
    if not (coordFrom and coordTo and fadeFrom and fadeTo) then return a end

    a *= (utils.clamp((coord - coordFrom) / (coordTo - coordFrom), 0, 1)
         * (fadeTo - fadeFrom)
         + fadeFrom)
  end

  return a
end

---

local faderListParser = {}
local cache = {}

function faderListParser.get(list, coord)
  if not list or list == "" then
    return 1
  end

  if not cache[list] then
    cache[list] = parse(list)
  end
  return process_fade(cache[list], coord)
end

function faderListParser.clear()
  for k, v in pairs(cache) do
    cache[k] = nil
  end
end

---

return faderListParser
