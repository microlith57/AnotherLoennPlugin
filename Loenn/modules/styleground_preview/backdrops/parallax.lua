local drawableSprite = require("structs.drawable_sprite")

local canvasWidth = 320
local canvasHeight = 180

return function(id, parallax, cam_x, cam_y, color, t)
  local tex = parallax.texture
  -- don't render invisible parallaxes
  if not tex or tex == "" then return end

  -- can't load Misc textures, so load a copy from Gameplay instead
  if tex == "darkswamp"
    or tex == "mist"
    or tex == "northernlights"
    or tex == "purplesunset"
    or tex == "vignette" then
    tex = "bgs/microlith57/AnotherLoennPlugin/" .. tex
  end

  -- todo "bgs/MaxHelpingHand/animatedParallax/"

  -- get the texture from the atlas
  local sprite = drawableSprite.fromTexture(tex, {
    scaleX = (parallax.flipx and -1 or 1),
    scaleY = (parallax.flipy and -1 or 1),
    color = color,
    depth = 0,
    justificationX = 0.5, justificationY = 0.5, -- needed for flipping to work correctly
  })
  if not sprite then return end

  -- handle blendmode
  local orig_blendmode = love.graphics.getBlendMode()
  if parallax.blendmode == "additive" then
    love.graphics.setBlendMode("add")
  else
    love.graphics.setBlendMode("alpha")
  end

  local width, height = sprite.meta.realWidth, sprite.meta.realHeight

  -- handle positioning
  local pos_x = (parallax.x or 0) - cam_x * (parallax.scrollx or 0)
  local pos_y = (parallax.y or 0) - cam_y * (parallax.scrolly or 0)

  -- handle speed
  if parallax.speedx then pos_x += (parallax.speedx * t) end
  if parallax.speedy then pos_y += (parallax.speedy * t) end

  local repeats_x, repeats_y = 0, 0

  -- reposition looping stylegrounds, and figure out how many times to draw them
  if parallax.loopx ~= false then
    pos_x = math.fmod((math.fmod(pos_x, width) - width), width)
    pos_x = math.ceil(pos_x)
    repeats_x = math.ceil((canvasWidth - pos_x) / width) - 1
  end
  if parallax.loopy ~= false then
    pos_y = math.fmod((math.fmod(pos_y, height) - height), height)
    pos_y = math.ceil(pos_y)
    repeats_y = math.ceil((canvasHeight - pos_y) / height) - 1
  end

  -- do the actual drawing
  for i=0, repeats_x do
    for j=0, repeats_y do
      sprite.x = pos_x + (width / 2) + (i * width)
      sprite.y = pos_y + (height / 2) + (j * height)
      sprite:draw()
    end
  end

  love.graphics.setBlendMode(orig_blendmode)
end
