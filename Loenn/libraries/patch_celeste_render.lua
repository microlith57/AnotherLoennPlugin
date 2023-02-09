local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.enabled() then
  return {}
end

local celesteRender = require("celeste_render")
local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")
local editorScene = require("scenes.editor")

local stylegroundPreview
if settings.featureEnabled("styleground_preview") then
  stylegroundPreview = mods.requireFromPlugin("libraries.preview.styleground")
end

local colorgradePreview
if settings.featureEnabled("colorgrade_preview") then
  colorgradePreview = mods.requireFromPlugin("libraries.preview.colorgrade", "AnotherLoennPluginColorgrading")
end

local snap_to_grid
if settings.featureEnabled("snap_to_grid") then
  snap_to_grid = mods.requireFromPlugin("input_devices.snap_to_grid")
end

local keyboard_pan
if settings.featureEnabled("keyboard_pan") then
  keyboard_pan = mods.requireFromPlugin("input_devices.keyboard_pan")
end

local coords_view
if settings.featureEnabled("coords_view") then
  coords_view = mods.requireFromPlugin("input_devices.coords_view")
end

---

function initial_setup()
  if snap_to_grid then
    inputDevice.newInputDevice(sceneHandler.getCurrentScene().inputDevices, snap_to_grid)
  end
  if keyboard_pan then
    inputDevice.newInputDevice(sceneHandler.getCurrentScene().inputDevices, keyboard_pan)
  end
  if coords_view then
    inputDevice.newInputDevice(sceneHandler.getCurrentScene().inputDevices, coords_view)
  end
end

---

if celesteRender.___anotherLoennPlugin then
  celesteRender.___anotherLoennPlugin.unload()
  celesteRender.___anotherLoennPlugin = {}
end

--[[
  patch the drawMap function to also draw bg and fg stylegrounds if enabled
]]
local _orig_drawMap = celesteRender.drawMap
function celesteRender.drawMap(state)
  if state and state.map then
    if not celesteRender.___anotherLoennPlugin.initial_setup then
      initial_setup()
      celesteRender.___anotherLoennPlugin.initial_setup = true
    end

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
