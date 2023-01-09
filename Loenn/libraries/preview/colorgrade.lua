local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.4.3") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local loadedState = require("loaded_state")
local fileLocations = require("file_locations")
local utils = require("utils")

---

local preview = {}
preview.enabled = false

function preview.toggle()
  if preview.enabled then
    preview.enabled = false
    preview.current = nil
  else
    preview.enabled = true
  end
end

-- todo: swap between this and an ArrayImage one somehow???
preview.shaderSource = [===[
vec4 effect(vec4 vcolor, Image tex, vec2 texcoord, vec2 pixcoord) {
  return Texel(tex, texcoord) * vcolor;
}
]===]
preview.shader = nil
preview.current = nil

function preview.setShader()
  if not preview.shader then
    preview.shader = love.graphics.newShader(preview.shaderSource)
    preview.current = nil
  end

  -- local colorgrade = loadedState.side.ColorGrade
  local colorgrade = "golden"

  if preview.current ~= colorgrade then
    preview.current = colorgrade
    -- todo: support modded colorgrades
    local path =
      utils.joinpath(fileLocations.getCelesteDir(), "Content", "Graphics", "ColorGrading", colorgrade) .. ".png"
    local success, image = pcall(utils.newImage, path, false)

    if success then
    -- preview.shader:send("colorgrade", image)
    end
  end

  love.graphics.setShader(preview.shader)
end

---

return preview
