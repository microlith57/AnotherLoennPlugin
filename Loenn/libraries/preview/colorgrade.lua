local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.5.0") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local fileLocations = require("file_locations")
local utils = require("utils")
local modHandler = require("mods")

---

local preview = {}
preview.enabled = false

function preview.toggle()
  if preview.enabled then
    preview.enabled = false
    preview.currentColorgrade = nil
  else
    preview.enabled = true
  end
end

local importantBit = [[
  uniform VolumeImage colorgrade;

  vec4 grade(vec4 color) {
    return Texel(colorgrade, color.rgb) * color.a;
  }
]]

preview.pixShaderSource = importantBit .. [[
  vec4 effect(vec4 vcolor, Image tex, vec2 texcoord, vec2 pixcoord) {
    return grade(Texel(tex, texcoord) * vcolor);
  }
]]

preview.arrShaderSource = importantBit .. [[
  uniform ArrayImage MainTex;

  void effect() {
    love_PixelColor = grade(Texel(MainTex, VaryingTexCoord.xyz) * VaryingColor);
  }
]]

preview.pixShader = nil
preview.arrShader = nil
preview.currentColorgrade = nil
preview.textureValid = nil

function preview.setupShaders(state)
  if not preview.pixShader then
    preview.pixShader = love.graphics.newShader(preview.pixShaderSource)
    preview.currentColorgrade = nil
  end
  if not preview.arrShader then
    preview.arrShader = love.graphics.newShader(preview.arrShaderSource)
    preview.currentColorgrade = nil
  end

  if not state or not state.side or not state.side.meta then return end

  local colorgrade = state.side.meta.ColorGrade

  if preview.enabled and preview.currentColorgrade ~= colorgrade then
    preview.textureValid = false
    preview.currentColorgrade = colorgrade
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

      preview.pixShader:send("colorgrade", image)
      preview.arrShader:send("colorgrade", image)
      preview.textureValid = true
    end
  end
end

---

preview._orig_draw = love.graphics.draw
preview._mod_draw = function(drawable, a, b, c, d, e, f, g, h, i, j)
  if (drawable:typeOf("Image") and drawable:getTextureType() == "array")
    or (drawable:typeOf("SpriteBatch") and drawable:getTexture():getTextureType() == "array")
    or (drawable:typeOf("Mesh") and drawable:getTexture():getTextureType() == "array") then
    if love.graphics.getShader() ~= preview.arrShader then
      love.graphics.setShader(preview.arrShader)
    end
  else
    if love.graphics.getShader() ~= preview.pixShader then
      love.graphics.setShader(preview.pixShader)
    end
  end
  preview._orig_draw(drawable, a, b, c, d, e, f, g, h, i, j)
end

-- hope no-one uses drawInstanced!

preview._orig_drawLayer = love.graphics.drawLayer
preview._mod_drawLayer = function(texture, layerindex, a, b, c, d, e, f, g, h, i, j)
  love.graphics.setShader(preview.arrShader)
  preview._orig_drawLayer(texture, layerindex, a, b, c, d, e, f, g, h, i, j)
end

preview.orig_shader = nil

function preview.begin_preview(state)
  preview.setupShaders(state)
  if not preview.enabled or not preview.textureValid then
    return
  end

  preview.orig_shader = love.graphics.getShader()

  love.graphics.setShader(preview.pixShader)

  love.graphics.draw = preview._mod_draw
  love.graphics.drawLayer = preview._mod_drawLayer
end

function preview.end_preview()
  love.graphics.draw = preview._orig_draw
  love.graphics.drawLayer = preview._orig_drawLayer

  if preview.orig_shader then
    love.graphics.setShader(preview.orig_shader)
  end
end

---

return preview
