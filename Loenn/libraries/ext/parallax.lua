local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.4.3") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local utils = require("utils")
local parallax = require("parallax")

local parallaxExt = {}

---

--[[
  parse the given fader list, returning a table of tables of values
]]
function parallaxExt.parseFaderList(list)
  local faders = {}

  if not list or list == "" then
    return faders
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

    table.insert(faders, {
      coordFrom = math.floor(tonumber(coord_part[1])),
      coordTo   = math.floor(tonumber(coord_part[2])),
      fadeFrom  = tonumber(fade_part[1]),
      fadeTo    = tonumber(fade_part[2])
    })
  end)

  return faders
end

---

--[[
  get the fade value in [0, 1] for a parallax at a given x, y focus point, caching parsed values where possible.
]]
function parallaxExt.getFade(parallax, x, y)
  if not parallax then return 1 end

  local ext = parallaxExt.get(parallax)

  -- create or recreate fader caches if necessary
  if ext.fadex ~= parallax.fadex or not ext.f_fadex then
    -- set cache staleness detection value
    ext.fadex = parallax.fadex
    -- parse the fader list
    ext.f_fadex = parallaxExt.parseFaderList(ext.fadex or "")
  end
  if ext.fadey ~= parallax.fadey or not ext.f_fadey then
    -- set cache staleness detection value
    ext.fadey = parallax.fadey
    -- parse the fader list
    ext.f_fadey = parallaxExt.parseFaderList(ext.fadey or "")
  end

  -- perform the fade
  local alpha = 1
  for i, fader in ipairs(ext.f_fadex) do
    -- simulate Calc.ClampedMap
    alpha = alpha
          * (utils.clamp((x - fader.coordFrom) / (fader.coordTo - fader.coordFrom), 0, 1)
             * (fader.fadeTo - fader.fadeFrom)
             + fader.fadeFrom)
  end
  for i, fader in ipairs(ext.f_fadey) do
    -- simulate Calc.ClampedMap
    alpha = alpha
          * (utils.clamp((y - fader.coordFrom) / (fader.coordTo - fader.coordFrom), 0, 1)
            * (fader.fadeTo - fader.fadeFrom)
            + fader.fadeFrom)
  end
  return alpha
end

---

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

function parallaxExt.clear_all()
  exts = {}
end

---

return parallaxExt
