local mods = require("mods")
local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")
local windows = require("ui.windows")

local motivational_message_module = {}

function motivational_message_module.init()
  local device = inputDevice.newInputDevice({}, mods.requireFromPlugin("modules.motivational_message.device"))
  local messageWindow = mods.requireFromPlugin("modules.motivational_message.window")
  local group = windows.windows['alp_motivational_message']

  device.messageWindow = messageWindow
  messageWindow.group = group

  local devices = sceneHandler.getCurrentScene().inputDevices
  local tool_device = require("input_devices.tool_device")
  local tool_device_index = $(devices):index(function(_, d)
    return d == tool_device
  end)

  -- add the device before the tool device
  table.insert(devices, tool_device_index, device)
end
return motivational_message_module
