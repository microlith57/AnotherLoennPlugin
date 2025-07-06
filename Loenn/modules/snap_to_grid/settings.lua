local v = require("utils.version_parser")

local handler = {}

local function rename(settings, from, to)
  for _, k in pairs(from) do
    if settings[k] and not settings[to] then
      settings[to] = settings[k]
    end
    settings[k] = nil
  end
end

handler.migrations = {
  {
    upto = v("1.6.1"),
    apply = function(settings)
      if settings.snap_to_grid then
        dirs = {
          {"left", "Left"},
          {"right", "Right"},
          {"up", "Up"},
          {"down", "Down"},
          {"neutral", "Neutral"}
        }

        for _, v in ipairs(dirs) do
          dir, Dir = table.unpack(v)
          rename(settings, {"hotkey_" .. dir, "hotkey_snap" .. Dir}, "hotkey_snap_" .. dir)
        end

        rename(settings, {"hotkey_grid"}, "hotkey_toggle_grid")
      end
    end
  }
}

handler.defaults = {
  _enabled = true,
  grid_spacing_x = 8,
  grid_spacing_y = 8,
  hotkey_snap_left    = "ctrl + shift + left",
  hotkey_snap_right   = "ctrl + shift + right",
  hotkey_snap_up      = "ctrl + shift + up",
  hotkey_snap_down    = "ctrl + shift + down",
  hotkey_snap_neutral = "shift + s",
  hotkey_toggle_grid  = "ctrl + shift + g",
  snapping_mode = "individual"
}

handler.groups = {
  {
    title = "ui.anotherloennplugin_settings.group.general.snap_to_grid",
    checkbox = "snap_to_grid._enabled",
    fieldOrder = {
      "snap_to_grid.grid_spacing_x",
      "snap_to_grid.grid_spacing_y",
      "spacer",
      "snap_to_grid.hotkey_snap_left",
      "snap_to_grid.hotkey_snap_right",
      "snap_to_grid.hotkey_snap_up",
      "snap_to_grid.hotkey_snap_down",
      "snap_to_grid.hotkey_snap_neutral",
      "snap_to_grid.hotkey_toggle_grid",
      "snap_to_grid.snapping_mode",
    }
  }
}

handler.fieldInformation = {
  grid_spacing_x = { fieldType = "integer", minimumValue = 1 },
  grid_spacing_y = { fieldType = "integer", minimumValue = 1 },
  hotkey_snap_left = { fieldType = "keyboard_hotkey" },
  hotkey_snap_right = { fieldType = "keyboard_hotkey" },
  hotkey_snap_up = { fieldType = "keyboard_hotkey" },
  hotkey_snap_down = { fieldType = "keyboard_hotkey" },
  hotkey_snap_neutral = { fieldType = "keyboard_hotkey" },
  hotkey_toggle_grid = { fieldType = "keyboard_hotkey" },
  snapping_mode = {
    fieldType = "string",
    editable = false,
    options = {
      {"Individual", "individual"},
      {"First", "first"},
      {"Centroid", "centroid"},
    }
  },
}

function handler.load(settings)
  if not settings.snap_to_grid then
    settings.snap_to_grid = { _enabled = true }
  end

  for k, v in pairs(handler.defaults) do
    if settings.snap_to_grid[k] == nil then
      settings.snap_to_grid[k] = v
    end

    handler[k] = settings.snap_to_grid[k]
  end

  return settings.snap_to_grid._enabled
end

return handler
