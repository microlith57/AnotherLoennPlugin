local meta = require("meta")
if meta.version >= version("0.4.3") then
    return
end

local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")
local drawing = require("utils.drawing")
local atlases = require("atlases")

local canvasWidth = 320
local canvasHeight = 180

-- todo: turn off when opening a new map?
local preview = {}
preview.bg_enabled = false
preview.fg_enabled = false
preview.bg_canvas = nil
preview.fg_canvas = nil

function preview.toggle_bg()
  preview.bg_enabled = not preview.bg_enabled
end

function preview.toggle_fg()
  preview.fg_enabled = not preview.fg_enabled
end

---

function preview.previewPos()
  local centre_x = (viewportHandler.viewport.x + viewportHandler.viewport.width / 2) / viewportHandler.viewport.scale
  local centre_y = (viewportHandler.viewport.y + viewportHandler.viewport.height / 2) / viewportHandler.viewport.scale

  return math.floor(centre_x - canvasWidth / 2), math.floor(centre_y - canvasHeight / 2)
end

---

-- todo: don't do this
local function room_in_list(room, list)
  if not room then return false end
  if not list or list == "" then return false end
  if list == "*" then return true end

  list = string.gsub(list, [[%*]], [[.*]])

  for i, part in ipairs(list:split(",")()) do
    -- worst possible way to do this
    local m = room:match(part)
    if m == room then return true end
  end

  return false
end

---

function preview.renderParallax(state, selectedRoom, parallax)
  -- todo: fadex, fadey

  if selectedRoom then
    if room_in_list(selectedRoom, parallax.exclude or "")
       or not room_in_list(selectedRoom, parallax.only or "*") then
      return
    end
  elseif parallax.only and parallax.only ~= "*" then
    return
  end

  local a = parallax.alpha or 1

  if a <= 0 then return end
  if parallax.texture == nil or parallax.texture == "" then return end

  -- todo: find another way to do this?
  local atlas = "Gameplay"
  if parallax.texture == "darkswamp"
    or parallax.texture == "mist"
    or parallax.texture == "northernlights"
    or parallax.texture == "purplesunset"
    or parallax.texture == "vignette" then
    atlas = "Misc"
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

  local sprite = drawableSprite.fromTexture(parallax.texture, {
    scaleX = (parallax.flipx and -1 or 1),
    scaleY = (parallax.flipy and -1 or 1),
    color = color,
    depth = 0,
    justificationX = 0.5, justificationY = 0.5,
    atlas = atlas,
  })

  if sprite then
    local cam_x, cam_y = preview.previewPos()

    local pos_x = (parallax.x or 0) - cam_x * (parallax.scrollx or 0)
    local pos_y = (parallax.y or 0) - cam_y * (parallax.scrolly or 0)

    -- review: this seems like it might be wrong in some situations, but i don't know why
    if parallax.loopx ~= false then
      local width = sprite.meta.width
      pos_x = math.fmod((math.fmod(pos_x, width) - width), width)
      pos_x = math.ceil(pos_x)
    end
    if parallax.loopy ~= false then
      local height = sprite.meta.height
      pos_y = math.fmod((math.fmod(pos_y, height) - height), height)
      pos_y = math.ceil(pos_y)
    end

    while pos_x <= canvasWidth do
      while pos_y <= canvasHeight do
        sprite.x = pos_x + (canvasWidth / 2)
        sprite.y = pos_y + (canvasHeight / 2)
        sprite:draw()

        if parallax.loopy == false then break end
        pos_y += sprite.meta.height
      end
      if parallax.loopx == false then break end
      pos_x += sprite.meta.width
    end
  end

  love.graphics.setBlendMode(orig_blendmode)
end

---

function preview.draw(canvas)
  if not canvas then return end

  local x, y = preview.previewPos()
  viewportHandler.drawRelativeTo(x, y, function()
    love.graphics.draw(canvas)
  end)
end

function preview.update(state, stylegrounds, canvas)
  local selectedItem, selectedItemType = state.getSelectedItem()
  local selectedRoom
  if selectedItemType ~= "table" and selectedItem then selectedRoom = selectedItem.name end

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

function preview.draw_outline(state)

end

function preview.draw_bg(state)
  local x, y = preview.previewPos()
  viewportHandler.drawRelativeTo(x, y, function()
    drawing.callKeepOriginalColor(function()
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
    end)
  end)

  if not bg_canvas then
    bg_canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  end
  preview.update(state, state.map.stylesBg, bg_canvas)
  preview.draw(bg_canvas)
end

function preview.draw_fg(state)
  local x, y = preview.previewPos()
  viewportHandler.drawRelativeTo(x, y, function()
    drawing.callKeepOriginalColor(function()
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("line", 0, 0, canvasWidth, canvasHeight)
    end)
  end)

  if not fg_canvas then
    fg_canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  end
  preview.update(state, state.map.stylesFg, fg_canvas)
  preview.draw(fg_canvas)
end

---

if celesteRender.___anotherLoennPlugin then
  celesteRender.___anotherLoennPlugin.unload()
end

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

---

return preview
