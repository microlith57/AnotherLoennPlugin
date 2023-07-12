local handler = {}

local defaults = {
  _enabled = true,
  grid_spacing_x = 8,
  grid_spacing_y = 8,
  hotkey_snapLeft    = "ctrl + shift + left",
  hotkey_snapRight   = "ctrl + shift + right",
  hotkey_snapUp      = "ctrl + shift + up",
  hotkey_snapDown    = "ctrl + shift + down",
  hotkey_snapNeutral = "shift + s",
  hotkey_toggle_grid = "ctrl + shift + g",
  snapping_mode = "individual"
}

local renamings = {
  hotkey_snapLeft    = "hotkey_left",
  hotkey_snapRight   = "hotkey_right",
  hotkey_snapUp      = "hotkey_up",
  hotkey_snapDown    = "hotkey_down",
  hotkey_snapNeutral = "hotkey_neutral",
  hotkey_toggle_grid = "hotkey_grid"
}

function handler.load(settings)
  if not settings.snap_to_grid then
    settings.snap_to_grid = { _enabled = true }
  end

  for k, v in pairs(defaults) do
    if settings.snap_to_grid[k] == nil then
      settings.snap_to_grid[k] = v
    end

    handler[renamings[k] or k] = v
  end

  return settings.snap_to_grid._enabled
end

return handler
