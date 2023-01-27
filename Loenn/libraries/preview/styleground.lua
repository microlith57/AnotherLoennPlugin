local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.5.0") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local viewportHandler = require("viewport_handler")
local utils = require("utils")
local drawing = require("utils.drawing")
local atlases = require("atlases")

local room_list = require("mods").requireFromPlugin("libraries.parsers.room_list")
local fader_list = require("mods").requireFromPlugin("libraries.parsers.fader_list")

local backdrop_renderers = require("mods").requireFromPlugin("libraries.preview.backdrop_renderers")

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
  render a single styleground onto the given canvas
]]
function preview.render(seed, style, room, cam_x, cam_y, t)
  local typ = utils.typeof(style)
  local name = style._name
  if typ ~= "parallax" then
    if typ ~= "effect" or not backdrop_renderers[name] then return end
  end

  if room then
    if not room_list.check(style.only or "*", room)
        or room_list.check(style.exclude or "", room) then return end
  else
    if (style.only and style.only ~= "*")
       or (style.exclude and style.exclude ~= "") then return end
  end

  local a = style.alpha or 1
  -- process faders; if the style is completely invisible, don't render it at all
  a *= fader_list.get(style.fadex or "", cam_x + canvasWidth / 2)
     * fader_list.get(style.fadey or "", cam_y + canvasHeight / 2)
  if a <= 0 then return end

  local color = {1, 1, 1, a}
  if style.color then
    local success, r, g, b = utils.parseHexColor(tostring(style.color))
    if success then
      color[1] = r
      color[2] = g
      color[3] = b
    end
  end

  if typ == "parallax" then
    backdrop_renderers.parallax(seed, style, cam_x, cam_y, color, t)
  else
    backdrop_renderers[name](seed, style, cam_x, cam_y, color, t)
  end
end

--[[
  render a styleground list onto the given canvas
]]
function preview.renderAll(state, stylegrounds, canvas, selectedRoom, props)
  local cam_x, cam_y = preview.previewPos(state)
  local t = 0
  if preview.anim_start then
    t = love.timer.getTime() - preview.anim_start
  end

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
      local seed = tonumber(tostring(style):sub(10), 16)

      preview.render(seed, copy, selectedRoom, cam_x, cam_y, t)
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
