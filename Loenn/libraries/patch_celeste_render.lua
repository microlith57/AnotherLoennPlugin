local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.enabled() then
  return {}
end

local celesteRender = require("celeste_render")

local stylegroundPreview
if settings.featureEnabled("styleground_preview") then
  stylegroundPreview = mods.requireFromPlugin("libraries.preview.styleground")
end

local colorgradePreview
if settings.featureEnabled("colorgrade_preview") then
  colorgradePreview = mods.requireFromPlugin("libraries.preview.colorgrade", "AnotherLoennPluginColorgrading")
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
  if state and state.map then
    if colorgradePreview and colorgradePreview.enabled then
      colorgradePreview.begin_preview(state)
    end
    if stylegroundPreview and stylegroundPreview.bg_enabled then
      stylegroundPreview.draw(state, false)
    end
  end

  _orig_drawMap(state)

  if state and state.map then
    if stylegroundPreview and stylegroundPreview.fg_enabled then
      stylegroundPreview.draw(state, true)
    end
    if colorgradePreview and colorgradePreview.enabled then
      colorgradePreview.end_preview(state)
    end
  end
end

--[[
  patch the getRoomBackgroundColor function to return transparency if there are stylegrounds behind (so they aren't covered up)
]]
local _orig_getRoomBackgroundColor = celesteRender.getRoomBackgroundColor
function celesteRender.getRoomBackgroundColor(room, selected)
  if stylegroundPreview and stylegroundPreview.bg_enabled then
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
