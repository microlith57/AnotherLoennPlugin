local mods = require("mods")
local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")
local windows = require("ui.windows")

local coords_view_module = {}

function coords_view_module.init()
  local device = inputDevice.newInputDevice({}, mods.requireFromPlugin("modules.coords_view.device"))
  local coordsWindow = mods.requireFromPlugin("modules.coords_view.window")
  local group = windows.windows['alp_coords_view']

  device.coordsWindow = coordsWindow
  coordsWindow.group = group

  local devices = sceneHandler.getCurrentScene().inputDevices
  local tool_device = require("input_devices.tool_device")
  local tool_device_index = $(devices):index(function(_, d)
    return d == tool_device
  end)

  -- add the device before the tool device
  table.insert(devices, tool_device_index, device)
end

return coords_view_module
