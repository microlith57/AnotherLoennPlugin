local mods = require("mods")
local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")

local utils = require("utils")

local nicer_mouse_pan_module = {}

function nicer_mouse_pan_module.init()
  local device = inputDevice.newInputDevice({}, mods.requireFromPlugin("modules.nicer_mouse_pan.device"))

  local devices = sceneHandler.getCurrentScene().inputDevices
  local viewport_device = require("input_devices.viewport_device")
  local viewport_device_index = $(devices):index(function(_, d)
    return d == viewport_device
  end)

  -- add the device before the viewport device
  table.insert(devices, viewport_device_index, device)
  table.insert(devices, 1, device.earlier_device)
  device._hook()
end

return nicer_mouse_pan_module
