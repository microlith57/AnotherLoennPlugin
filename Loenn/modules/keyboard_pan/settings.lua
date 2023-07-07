local v = require("utils.version_parser")

local handler = {}

handler.migrations = {
  {
    upto = v("0.3.0"),
    apply = function(settings)
      if settings.keyboard_pan then
        if settings.keyboard_pan.hotkey_left  == "a"
          and settings.keyboard_pan.hotkey_right == "d"
          and settings.keyboard_pan.hotkey_up       == "w"
          and settings.keyboard_pan.hotkey_down  == "s" then

          settings.keyboard_pan.hotkey_left  = "alt + a"
          settings.keyboard_pan.hotkey_right = "alt + d"
          settings.keyboard_pan.hotkey_up    = "alt + w"
          settings.keyboard_pan.hotkey_down  = "alt + s"

        end
      end
    end
  }
}

local defaults = {
  _enabled = true,
  hotkey_left  = "alt + a",
  hotkey_right = "alt + d",
  hotkey_up    = "alt + w",
  hotkey_down  = "alt + s",
  speed = 1024,
  time_after_each_keypress_to_allow_movement = 1
}

local renamings = {
  time_after_each_keypress_to_allow_movement = "timer_max"
}

function handler.load(settings)
  if not settings.keyboard_pan then
    settings.keyboard_pan = { _enabled = true }
  end

  for k, v in pairs(defaults) do
    if settings.keyboard_pan[k] == nil then
      settings.keyboard_pan[k] = v
    end

    handler[renamings[k] or k] = v
  end

  return settings.keyboard_pan._enabled
end

return handler
