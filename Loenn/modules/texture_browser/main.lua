local mods = require("mods")
local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")
local windows = require("ui.windows")

local texture_browser_module = {}

function texture_browser_module.init()
  local textureBrowserWindow = mods.requireFromPlugin("modules.texture_browser.window")
  local group = windows.windows['alp_texture_browser']
  textureBrowserWindow.group = group

  ---

  local menubar = require("ui.menubar").menubar
  local viewMenu = $(menubar):find(menu -> menu[1] == "view")[2]
  local menuItem = $(viewMenu):find(menu -> menu[1] == "anotherloennplugin_texture_browser")

  if not menuItem then
    menuItem = {"anotherloennplugin_texture_browser", nil}
    table.insert(viewMenu, menuItem)
  end

  menuItem[2] = function()
    textureBrowserWindow.browseTextures()
  end
end

return texture_browser_module
