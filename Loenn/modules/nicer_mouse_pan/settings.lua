local v = require("utils.version_parser")

local handler = {}
handler.migrations = {}

handler.defaults = {
  _enabled = true,
  grab_mouse = true,
  override_ui = true,
  wrap_mode = "wrap",
  wrap_mode_when_tool_action_pressed = "cushion",
  wrap_margin = 25,
  enable_autoscroll = true,
  autoscroll_button = 3,
  autoscroll_speed = 20,
  autoscroll_power = 1.3,
  autoscroll_widget_radius = 15,
}

handler.groups = {
  {
    title = "ui.anotherloennplugin_settings.group.general.nicer_mouse_pan",
    checkbox = "nicer_mouse_pan._enabled",
    fieldOrder = {
      "nicer_mouse_pan.wrap_mode",
      "nicer_mouse_pan.wrap_mode_when_tool_action_pressed",
      "nicer_mouse_pan.wrap_margin",
      "nicer_mouse_pan.grab_mouse",
      "spacer",
      "nicer_mouse_pan.enable_autoscroll",
      "nicer_mouse_pan.autoscroll_button",
      "nicer_mouse_pan.autoscroll_speed",
      "nicer_mouse_pan.autoscroll_power",
      "nicer_mouse_pan.autoscroll_widget_radius",
    }
  }
}

local wrapOptions = {
  {"Wrap", "wrap"},
  {"Cushion", "cushion"},
  {"No wrapping", "none"}
}
local wrapInfo = {
  fieldType = "string",
  editable = false,
  options = wrapOptions
}

handler.fieldInformation = {
  wrap_mode = wrapInfo,
  wrap_mode_when_tool_action_pressed = wrapInfo,
  wrap_margin = { fieldType = "integer", minimumValue = 1 },
  grab_mouse = { fieldType = "boolean" },
  enable_autoscroll = { fieldType = "boolean" },
  autoscroll_button = { fieldType = "mouse_button" },
  autoscroll_speed = { fieldType = "number" },
  autoscroll_power = { fieldType = "number" },
  autoscroll_widget_radius = { fieldType = "integer", minimumValue = 4 },
}

function handler.load(settings)
  if not settings.nicer_mouse_pan then
   settings.nicer_mouse_pan = { _enabled = true }
  end

  for k, v in pairs(handler.defaults) do
    if settings.nicer_mouse_pan[k] == nil then
      settings.nicer_mouse_pan[k] = v
    end

    handler[k] = v
  end

  return settings.nicer_mouse_pan._enabled
end

return handler
