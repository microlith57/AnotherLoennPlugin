local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.4.3") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local viewportHandler = require("viewport_handler")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")
local drawing = require("utils.drawing")
local atlases = require("atlases")

local room_list = require("mods").requireFromPlugin("libraries.parsers.room_list")
local fader_list = require("mods").requireFromPlugin("libraries.parsers.fader_list")

---

local canvasWidth = 320
local canvasHeight = 180

-- todo: turn off when opening a new map?
local preview = {}
preview.bg_enabled = false
preview.fg_enabled = false
preview.bg_canvas = nil
preview.fg_canvas = nil
preview.snap_to_room = true
preview.anim_start = nil

function preview.toggle_bg()
  preview.bg_enabled = not preview.bg_enabled
  if not preview.bg_enabled and not preview.fg_enabled then
    room_list.clear()
    fader_list.clear()
  end
end

function preview.toggle_fg()
  preview.fg_enabled = not preview.fg_enabled
  if not preview.bg_enabled and not preview.fg_enabled then
    room_list.clear()
    fader_list.clear()
  end
end

function preview.toggle_snap()
  preview.snap_to_room = not preview.snap_to_room
end

function preview.toggle_anim()
  if preview.anim_start == nil then
    preview.anim_start = love.timer.getTime()
  else
    preview.anim_start = nil
  end
end

---

--[[
  get the position of the top-left corner of the preview rectangle, snapping to the selected room's bounds if necessary
]]
function preview.previewPos(state)
  local centre_x = (viewportHandler.viewport.x + viewportHandler.viewport.width / 2) / viewportHandler.viewport.scale
  local centre_y = (viewportHandler.viewport.y + viewportHandler.viewport.height / 2) / viewportHandler.viewport.scale

  local pos_x = math.floor(centre_x - canvasWidth / 2)
  local pos_y = math.floor(centre_y - canvasHeight / 2)

  if preview.snap_to_room and state then
    local room = state.getSelectedRoom()
    if room and room.x and room.y and room.width and room.height then
      pos_x = utils.clamp(room.x, pos_x, room.x + room.width - canvasWidth)
      pos_y = utils.clamp(room.y, pos_y, room.y + room.height - canvasHeight - 4)
    end
  end

  return pos_x, pos_y
end

---

--[[
  render the given parallax like celeste would.
  currently missing fadex, fadey on purpose
]]
function preview.renderParallax(state, selectedRoom, parallax)
  local a = parallax.alpha or 1
  local tex = parallax.texture
  local cam_x, cam_y = preview.previewPos(state)

  -- don't render invisible parallaxes
  if not tex or tex == "" then return end

  -- process faders; if the parallax is completely invisible, don't render it at all
  a *= fader_list.get(parallax.fadex or "", cam_x + canvasWidth / 2)
     * fader_list.get(parallax.fadey or "", cam_y + canvasHeight / 2)
  if a <= 0 then return end

  if tex == "darkswamp"
    or tex == "mist"
    or tex == "northernlights"
    or tex == "purplesunset"
    or tex == "vignette" then
    -- can't load Misc textures, so load a copy from Gameplay instead
    tex = "bgs/microlith57/AnotherLoennPlugin/" .. tex
  end

  local color = {1, 1, 1, a}
  if parallax.color then
    local success, r, g, b = utils.parseHexColor(tostring(parallax.color))
    if success then
      color[1] = r
      color[2] = g
      color[3] = b
    end
  end

  local orig_blendmode = love.graphics.getBlendMode()
  if parallax.blendmode == "additive" then
    love.graphics.setBlendMode("add")
  else
    love.graphics.setBlendMode("alpha")
  end

  -- get the texture from the atlas
  local sprite = drawableSprite.fromTexture(tex, {
    scaleX = (parallax.flipx and -1 or 1),
    scaleY = (parallax.flipy and -1 or 1),
    color = color,
    depth = 0,
    justificationX = 0.5, justificationY = 0.5, -- needed for flipping to work correctly
  })

  if sprite then
    local width, height = sprite.meta.realWidth, sprite.meta.realHeight

    -- handle positioning
    local pos_x = (parallax.x or 0) - cam_x * (parallax.scrollx or 0)
    local pos_y = (parallax.y or 0) - cam_y * (parallax.scrolly or 0)

    if preview.anim_start then
      if parallax.speedx then
        pos_x += ((love.timer.getTime() - preview.anim_start) * parallax.speedx)
      end
      if parallax.speedy then
        pos_y += ((love.timer.getTime() - preview.anim_start) * parallax.speedy)
      end
    end

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

    for i=0, repeats_x, 1 do
      for j=0, repeats_y, 1 do
        sprite.x = pos_x + (width / 2) + (i * width)
        sprite.y = pos_y + (height / 2) + (j * height)
        sprite:draw()
      end
    end
  end

  love.graphics.setBlendMode(orig_blendmode)
end

---

--[[
  render a styleground list onto the given canvas
]]
function preview.renderAll(state, stylegrounds, canvas, selectedRoom, props)
  for _, style in ipairs(stylegrounds) do
    local typ = utils.typeof(style)
    if typ == "apply" and style.children then
      -- recurse over this group's children, passing on the properties of this group and upper-level groups
      local new_props = table.shallowcopy(props)
      for k, v in pairs(style) do
        if k ~= "_type" and k ~= "children" then
          new_props[k] = v
        end
      end

      preview.renderAll(state, style.children, canvas, selectedRoom, new_props)
    else
      local copy = table.shallowcopy(props)
      for k, v in pairs(style) do
        copy[k] = v
      end

      if (selectedRoom
          and room_list.check(copy.only, selectedRoom)
          and not room_list.check(copy.exclude, selectedRoom))
        or ((copy.only or "*") == "*"
            and (copy.exclude or "") == "") then
        if typ == "parallax" then
          preview.renderParallax(state, selectedRoom, copy)
        else
          -- todo
        end
      end
    end
  end
end

--[[
  create a canvas if necessary, populate it, and draw it to the screen
]]
function preview.draw(state, isFg)
  local selectedItem = state.getSelectedRoom()
  local selectedRoom
  if selectedItem then selectedRoom = selectedItem.name end

  local canvas, stylegrounds
  if isFg then
    if not fg_canvas then
      fg_canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
    end
    canvas = fg_canvas
    stylegrounds = state.map.stylesFg
  else
    if not bg_canvas then
      bg_canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
    end
    canvas = bg_canvas
    stylegrounds = state.map.stylesBg
  end

  canvas:renderTo(function()
    if isFg then
      love.graphics.clear(0, 0, 0, 0)
    else
      love.graphics.clear(0, 0, 0, 255)
    end

    preview.renderAll(state, stylegrounds, canvas, selectedRoom, {})
  end)

  local x, y = preview.previewPos(state)
  viewportHandler.drawRelativeTo(x, y, function()
    love.graphics.draw(canvas)
  end)
end

---

return preview
