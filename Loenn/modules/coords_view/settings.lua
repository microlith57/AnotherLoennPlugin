local handler = {}

handler.defaults = {
  _enabled = true,
  cursor_length = 6,
  hotkey = "`"
}

handler.groups = {
  {
    title = "ui.anotherloennplugin_settings.group.general.coords_view",
    checkbox = "coords_view._enabled",
    fieldOrder = {
      "coords_view.hotkey",
      "coords_view.cursor_length",
    }
  }
}

handler.fieldInformation = {
  hotkey = { fieldType = "keyboard_hotkey" },
  cursor_length = { fieldType = "integer", minimumValue = 0 },
}

function handler.load(settings)
  if not settings.coords_view then
    settings.coords_view = { _enabled = true }
  end

  for k, v in pairs(handler.defaults) do
    if settings.coords_view[k] == nil then
      settings.coords_view[k] = v
    end

    handler[k] = v
  end

  return settings.coords_view._enabled
end

return handler
