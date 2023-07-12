local mods = require("mods")
local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")

local utils = require("utils")

local snap_to_grid_module = {}

function snap_to_grid_module.init()
  local device = inputDevice.newInputDevice({}, mods.requireFromPlugin("modules.snap_to_grid.device"))

  local devices = sceneHandler.getCurrentScene().inputDevices
  local tool_device = require("input_devices.tool_device")
  local tool_device_index = $(devices):index(function(_, d)
    return d == tool_device
  end)

  -- add the device before the tool device
  table.insert(devices, tool_device_index, device)
end

return snap_to_grid_module
