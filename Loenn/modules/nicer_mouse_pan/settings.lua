local v = require("utils.version_parser")

local handler = {}
handler.migrations = {}

local defaults = {
  _enabled = true,
  grab_mouse = true,
  override_ui = true,
  wrap_mode = "wrap",
  wrap_mode_when_tool_action_pressed = "cushion",
  wrap_margin = 25,
  enable_autoscroll = true,
  autoscroll_button = 3,
  autoscroll_speed = 5,
  autoscroll_widget_radius = 15,
}

function handler.load(settings)
  if not settings.nicer_mouse_pan then
   settings.nicer_mouse_pan = { _enabled = true }
  end

  for k, v in pairs(defaults) do
    if settings.nicer_mouse_pan[k] == nil then
      settings.nicer_mouse_pan[k] = v
    end

    handler[k] = v
  end

  return settings.nicer_mouse_pan._enabled
end

return handler
