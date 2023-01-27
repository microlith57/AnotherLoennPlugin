local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.5.0") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local celesteRender = require("celeste_render")

local stylegroundPreview = require("mods").requireFromPlugin("libraries.preview.styleground")
local colorgradePreview = require("mods").requireFromPlugin("libraries.preview.colorgrade", "AnotherLoennPluginColorgrading")

---

if celesteRender.___anotherLoennPlugin then
  celesteRender.___anotherLoennPlugin.unload()
end

--[[
  patch the drawMap function to also draw bg and fg stylegrounds if enabled
]]
local _orig_drawMap = celesteRender.drawMap
function celesteRender.drawMap(state)
  if state and colorgradePreview and colorgradePreview.enabled then
    colorgradePreview.begin_preview(state)
  end
  if state and state.map and stylegroundPreview.bg_enabled then
    stylegroundPreview.draw(state, false)
  end

  _orig_drawMap(state)

  if state and state.map and stylegroundPreview.fg_enabled then
    stylegroundPreview.draw(state, true)
  end
  if state and colorgradePreview and colorgradePreview.enabled then
    colorgradePreview.end_preview(state)
  end
end

--[[
  patch the getRoomBackgroundColor function to return transparency if there are stylegrounds behind (so they aren't covered up)
]]
local _orig_getRoomBackgroundColor = celesteRender.getRoomBackgroundColor
function celesteRender.getRoomBackgroundColor(room, selected)
  if stylegroundPreview.bg_enabled then
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

return {}
