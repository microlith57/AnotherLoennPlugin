local module_settings = {}

function module_settings.load(settings)
  if not settings.texture_browser then
    settings.texture_browser = { _enabled = false, _auto_enable_once_stable = true }
  elseif settings.texture_browser._enabled == nil then
    settings.texture_browser._enabled = false
    settings.texture_browser._auto_enable_once_stable = true
  end

  return settings.texture_browser._enabled
end

return module_settings
