local v = require("utils.version_parser")

local handler = {}

handler.migrations = {
  {
    upto = v("0.3.0"),
    apply = function(settings)
      if settings.keyboard_pan then
        if settings.keyboard_pan.hotkey_left     == "a"
          and settings.keyboard_pan.hotkey_right == "d"
          and settings.keyboard_pan.hotkey_up    == "w"
          and settings.keyboard_pan.hotkey_down  == "s" then

          settings.keyboard_pan.hotkey_left  = "alt + a"
          settings.keyboard_pan.hotkey_right = "alt + d"
          settings.keyboard_pan.hotkey_up    = "alt + w"
          settings.keyboard_pan.hotkey_down  = "alt + s"

        end
      end
    end
  },
  {
    upto = v("1.4.0"),
    apply = function(settings)
      if settings.keyboard_pan
        and settings.keyboard_pan.time_after_each_keypress_to_allow_movement then

        settings.keyboard_pan.time_after_each_keypress_to_allow_movement = nil

      end
    end
  }
}

handler.defaults = {
  _enabled = true,
  hotkey_left  = "alt + a",
  hotkey_right = "alt + d",
  hotkey_up    = "alt + w",
  hotkey_down  = "alt + s",
  speed = 1024
}

handler.groups = {
  {
    title = "ui.anotherloennplugin_settings.group.general.keyboard_pan",
    checkbox = "keyboard_pan._enabled",
    fieldOrder = {
      "keyboard_pan.hotkey_left",
      "keyboard_pan.hotkey_right",
      "keyboard_pan.hotkey_up",
      "keyboard_pan.hotkey_down",
      "keyboard_pan.speed",
    }
  }
}

handler.fieldInformation = {
  hotkey_left = { fieldType = "keyboard_hotkey" },
  hotkey_right = { fieldType = "keyboard_hotkey" },
  hotkey_up = { fieldType = "keyboard_hotkey" },
  hotkey_down = { fieldType = "keyboard_hotkey" },
  speed = { fieldType = "number", minimumValue = 0 },
}

function handler.load(settings)
  if not settings.keyboard_pan then
    settings.keyboard_pan = { _enabled = true }
  end

  for k, v in pairs(handler.defaults) do
    if settings.keyboard_pan[k] == nil then
      settings.keyboard_pan[k] = v
    end

    handler[k] = settings.keyboard_pan[k]
  end

  return settings.keyboard_pan._enabled
end

return handler
