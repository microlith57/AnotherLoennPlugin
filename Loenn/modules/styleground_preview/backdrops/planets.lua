local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

---

local loopWidth = 640
local loopHeight = 360

local big = {}
local small = {}

local render_planets = {}

local function mod(x, m)
  return math.fmod(math.fmod(x, m) + m, m)
end

return function(seed, planets, cam_x, cam_y, color, t)
  if #big == 0 then
    for i, name in ipairs({"big00", "big01", "big02"}) do
      big[i] = drawableSprite.fromTexture("bgs/10/" .. name, {
        depth = 0,
        justificationX = 0.5, justificationY = 0.5
      })
    end
  end
  if #small == 0 then
    for i, name in ipairs({"small00", "small01", "small02", "small03", "small04", "small05", "small06"}) do
      small[i] = drawableSprite.fromTexture("bgs/10/" .. name, {
        depth = 0,
        justificationX = 0.5, justificationY = 0.5
      })
    end
  end

  math.randomseed(seed)

  local sprites
  if planets.size == "big" then sprites = big else sprites = small end

  -- handle positioning
  local pos_x = (planets.x or 0) - cam_x * (planets.scrollx or 0)
  local pos_y = (planets.y or 0) - cam_y * (planets.scrolly or 0)

  -- handle speed
  if planets.speedx then pos_x += (planets.speedx * t) end
  if planets.speedy then pos_y += (planets.speedy * t) end

  for i=1, (planets.count or 32) do
    local sprite_index = math.random(#sprites)
    local sprite = sprites[sprite_index]
    sprite:setColor(color)

    local planet_x = math.random(loopWidth)
    local planet_y = math.random(loopHeight)

    sprite.x = mod(pos_x + planet_x, loopWidth) - 32
    sprite.y = mod(pos_y + planet_y, loopHeight) - 32

    sprite:draw()
  end
end
