local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.5.1") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local fileLocations = require("file_locations")
local utils = require("utils")
local uiu = require("ui.utils")
local modHandler = require("mods")
local viewportHandler = require("viewport_handler")

---

local col_preview = {}
col_preview.enabled = false

function col_preview.toggle()
  if col_preview.enabled then
    col_preview.enabled = false
    col_preview.unload()
  else
    col_preview.enabled = true
  end
end

col_preview.shaderSource = [[
  uniform VolumeImage colorgrade;

  vec4 grade(vec4 color) {
    return Texel(colorgrade, color.rgb) * color.a;
  }

  vec4 effect(vec4 vcolor, Image tex, vec2 texcoord, vec2 pixcoord) {
    return grade(Texel(tex, texcoord) * vcolor);
  }
]]

col_preview.shader = nil
col_preview.currentColorgrade = nil
col_preview.textureValid = nil

function col_preview.setupShader(state)
  if not col_preview.shader then
    col_preview.shader = love.graphics.newShader(col_preview.shaderSource)
    col_preview.currentColorgrade = nil
  end

  if not state or not state.side or not state.side.meta then return end

  local colorgrade = state.side.meta.ColorGrade

  if col_preview.enabled and col_preview.currentColorgrade ~= colorgrade then
    col_preview.textureValid = false
    col_preview.currentColorgrade = colorgrade
    local path = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Graphics", "ColorGrading", colorgrade) .. ".png"
    local fileData, err = love.filesystem.newFileData(utils.readAll(path, "rb"), colorgrade .. ".png")
    if not fileData then
      local path = utils.joinpath(modHandler.commonModContent, "Graphics", "ColorGrading", colorgrade) .. ".png"
      fileData, err = love.filesystem.newFileData(utils.readAll(path, "rb"), colorgrade .. ".png")
      if not fileData then return end
    end

    local imageData = love.image.newImageData(fileData)

    if imageData and imageData:getWidth() == 16 * 16 and imageData:getHeight() == 16 then
      -- create volume image
      local layers = {}
      for z=0, 15 do
        local layer = love.image.newImageData(16, 16)
        table.insert(layers, layer)

        for y=0, 15 do
          for x=0, 15 do
            local r, g, b, a = imageData:getPixel(x + 16 * z, y)
            layer:setPixel(x, y, r, g, b, a)
          end
        end
      end

      local image = love.graphics.newVolumeImage(layers)
      image:setFilter("linear", "linear")

      col_preview.shader:send("colorgrade", image)
      col_preview.textureValid = true
    end
  end
end

---

col_preview.canvas = nil
local prev_canvas
local resize_timer = 0

function col_preview.begin_preview(state)
  if resize_timer > 0 then
    resize_timer -= 1
  end

  col_preview.setupShader(state)
  if not col_preview.enabled or not col_preview.textureValid then
    return
  end

  local viewport = viewportHandler.viewport

  if not col_preview.canvas
     or (resize_timer <= 0 and
         (col_preview.canvas:getWidth() ~= viewport.width or
          col_preview.canvas:getWidth() ~= viewport.width)) then
    resize_timer = 15
    col_preview.canvas = love.graphics.newCanvas(viewport.width, viewport.height)
  end

  prev_canvas = love.graphics.getCanvas()
  love.graphics.setCanvas(col_preview.canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.push()
  -- love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
  -- love.graphics.scale(viewport.scale, viewport.scale)
end

function col_preview.end_preview()
  if not col_preview.enabled or not col_preview.textureValid then
    return
  end

  local viewport = viewportHandler.viewport

  love.graphics.pop()
  love.graphics.setCanvas(prev_canvas)
  love.graphics.push()
  -- love.graphics.translate(math.floor(viewport.x), math.floor(viewport.y))
  -- love.graphics.scale(1 / viewport.scale, 1 / viewport.scale)
  local prev_shader = love.graphics.getShader()
  love.graphics.setShader(col_preview.shader)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(col_preview.canvas, 0, 0)
  love.graphics.setBlendMode("alpha", "alphamultiply")
  love.graphics.setShader(prev_shader)
  love.graphics.pop()
end

function col_preview.unload()
  col_preview.currentColorgrade = nil
  col_preview.textureValid = nil
  col_preview.canvas = nil
  resize_timer = 0
end

---

return col_preview
