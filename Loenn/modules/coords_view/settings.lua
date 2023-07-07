local handler = {}

local defaults = {
  _enabled = true,
  cursor_length = 6,
  hotkey = "`"
}

function handler.load(settings)
  if not settings.coords_view then
    settings.coords_view = { _enabled = true }
  end

  for k, v in pairs(defaults) do
    if settings.coords_view[k] == nil then
      settings.coords_view[k] = v
    end

    handler[k] = v
  end

  return settings.coords_view._enabled
end

return handler
