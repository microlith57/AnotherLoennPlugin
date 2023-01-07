local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.4.3") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")
local drawing = require("utils.drawing")
local atlases = require("atlases")

local parallaxExt = require("mods").requireFromPlugin("libraries.parallax_ext")

local canvasWidth = 320
local canvasHeight = 180

-- todo: turn off when opening a new map?
local preview = {}
preview.bg_enabled = false
preview.fg_enabled = false
preview.bg_canvas = nil
preview.fg_canvas = nil
preview.snap_to_room = true

function preview.toggle_bg()
  preview.bg_enabled = not preview.bg_enabled
end

function preview.toggle_fg()
  preview.fg_enabled = not preview.fg_enabled
end

function preview.toggle_snap()
  preview.snap_to_room = not preview.snap_to_room
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
      pos_x = math.min(math.max(room.x, pos_x), room.x + room.width - canvasWidth)
      pos_y = math.min(math.max(room.y, pos_y), room.y + room.height - canvasHeight - 4)
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

  -- don't render parallaxes that don't belong in the selected room
  if selectedRoom then
    if not parallaxExt.isInRoom(parallax, selectedRoom) then return end
  elseif (parallax.only and parallax.only ~= "*")
      or (parallax.exclude and parallax.exclude ~= "") then
    return
  end

  -- process faders; if the parallax is completely invisible, don't render it at all
  a *= parallaxExt.getFade(parallax, cam_x + canvasWidth / 2, cam_y + canvasHeight / 2)
  if a <= 0 then return end

  if tex == "darkswamp"
    or tex == "mist"
    or tex == "northernlights" -- todo: northernlights doesn't render; too big?
    or tex == "purplesunset"
    or tex == "vignette" then
    -- can't load Misc textures, so load a copy from Gameplay instead
    tex = "bgs/microlith57/AnotherLoennPlugin/" .. tex
  end

  local color = {1, 1, 1, a}
  if parallax.color then
    local success, r, g, b = utils.parseHexColor(parallax.color)
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
  draw the given canvas in the right place
]]
function preview.draw(state, canvas)
  if not canvas then return end

  local x, y = preview.previewPos(state)
  viewportHandler.drawRelativeTo(x, y, function()
    love.graphics.draw(canvas)
  end)
end

--[[
  render a styleground list onto the given canvas
]]
function preview.update(state, stylegrounds, canvas)
  local selectedItem = state.getSelectedRoom()
  local selectedRoom
  if selectedItem then selectedRoom = selectedItem.name end

  canvas:renderTo(function()
    love.graphics.clear(0, 0, 0, 0)

    for _, style in ipairs(stylegrounds) do
      local typ = utils.typeof(style)
      if typ == "parallax" then
        preview.renderParallax(state, selectedRoom, style)
      elseif typ == "apply" and style.children then
        preview.update(state, style.children, canvas)
      end
    end
  end)
end

function preview.draw_bg(state)
  -- draw the black background
  local x, y = preview.previewPos(state)
  viewportHandler.drawRelativeTo(x, y, function()
    drawing.callKeepOriginalColor(function()
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
    end)
  end)

  -- create the bg canvas if necessary, populate it, and draw it to the screen
  if not bg_canvas then
    bg_canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  end
  preview.update(state, state.map.stylesBg, bg_canvas)
  preview.draw(state, bg_canvas)
end

function preview.draw_fg(state)
  -- create the fg canvas if necessary, populate it, and draw it to the screen
  if not fg_canvas then
    fg_canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  end
  preview.update(state, state.map.stylesFg, fg_canvas)
  preview.draw(state, fg_canvas)
end

---

if celesteRender.___anotherLoennPlugin then
  celesteRender.___anotherLoennPlugin.unload()
end

--[[
  patch the drawMap function to also draw bg and fg stylegrounds if enabled
]]
local _orig_drawMap = celesteRender.drawMap
function celesteRender.drawMap(state)
  if state and state.map and preview.bg_enabled then
    preview.draw_bg(state)
  end

  _orig_drawMap(state)

  if state and state.map and preview.fg_enabled then
    preview.draw_fg(state)
  end
end

--[[
  patch the getRoomBackgroundColor function to return transparency if there are stylegrounds behind (so they aren't covered up)
]]
local _orig_getRoomBackgroundColor = celesteRender.getRoomBackgroundColor
function celesteRender.getRoomBackgroundColor(room, selected)
  if preview.bg_enabled then
    return {0, 0, 0, 0}
  else
    return _orig_getRoomBackgroundColor(room, selected)
  end
end

celesteRender.___anotherLoennPlugin = {
  unload = function()
    celesteRender.drawMap = _orig_drawMap
    celesteRender.getRoomBackgroundColor = _orig_getRoomBackgroundColor
  end
}

---

--[[
  add the menu options
]]

local menubar = require("ui.menubar").menubar
local viewMenu = $(menubar):find(menu -> menu[1] == "view")[2]

local checkbox_bg = $(viewMenu):find(item -> item[1] == "anotherloennplugin_styleground_preview_bg")
if not checkbox_bg then
  checkbox_bg = {}
  table.insert(viewMenu, checkbox_bg)
end

checkbox_bg[1] = "anotherloennplugin_styleground_preview_bg"
checkbox_bg[2] = preview.toggle_bg
checkbox_bg[3] = "checkbox"
checkbox_bg[4] = function() return preview.bg_enabled end

local checkbox_fg = $(viewMenu):find(item -> item[1] == "anotherloennplugin_styleground_preview_fg")
if not checkbox_fg then
  checkbox_fg = {}
  table.insert(viewMenu, checkbox_fg)
end

checkbox_fg[1] = "anotherloennplugin_styleground_preview_fg"
checkbox_fg[2] = preview.toggle_fg
checkbox_fg[3] = "checkbox"
checkbox_fg[4] = function() return preview.fg_enabled end

local checkbox_snap = $(viewMenu):find(item -> item[1] == "anotherloennplugin_styleground_preview_snap")
if not checkbox_snap then
  checkbox_snap = {}
  table.insert(viewMenu, checkbox_snap)
end

checkbox_snap[1] = "anotherloennplugin_styleground_preview_snap"
checkbox_snap[2] = preview.toggle_snap
checkbox_snap[3] = "checkbox"
checkbox_snap[4] = function() return preview.snap_to_room end

---

return preview
