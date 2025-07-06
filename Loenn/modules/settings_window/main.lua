local mods = require("mods")
local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")
local windows = require("ui.windows")

local settings_window_module = {}

function settings_window_module.init()
  local group = windows.windows['alp_settings']

  local settingsWindow = mods.requireFromPlugin("modules.settings_window.window")
  settingsWindow.group = group

  ---

  local menubar = require("ui.menubar").menubar
  local viewMenu = $(menubar):find(menu -> menu[1] == "view")[2]
  local menuItem = $(viewMenu):find(menu -> menu[1] == "anotherloennplugin_settings")

  if not menuItem then
    menuItem = {"anotherloennplugin_settings", nil}
    table.insert(viewMenu, menuItem)
  end

  menuItem[2] = function()
    settingsWindow.editSettings()
  end
end

return settings_window_module
