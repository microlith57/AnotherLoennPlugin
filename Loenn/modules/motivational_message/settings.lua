local handler = {}

handler.defaults = {
  _enabled = true,
  hotkey = "=",
  title = "KINDWOLF (its/her) says:",
  message = "HI! IM KINDWOLF. TAKE SOME TIME TODAY TO REMIND\nURSELF U R WORTHY OF LOVE AND U CAN DO IT!\nMAP THAT COBWOB! WRITE THAT STORY! U ROCK!"
}

handler.groups = {
  {
    title = "ui.anotherloennplugin_settings.group.general.motivational_message",
    checkbox = "motivational_message._enabled",
    fieldOrder = {
      "motivational_message.hotkey",
    }
  }
}

handler.fieldInformation = {
  hotkey = { fieldType = "keyboard_hotkey" },
}

function handler.load(settings)
  if not settings.motivational_message then
    settings.motivational_message = { _enabled = true }
  end

  for k, v in pairs(handler.defaults) do
    if settings.motivational_message[k] == nil then
      settings.motivational_message[k] = v
    end

    handler[k] = settings.motivational_message[k]
  end

  return settings.motivational_message._enabled
end

return handler
