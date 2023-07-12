local mods = require("mods")
local celesteRender = require("celeste_render")

local preview = mods.requireFromPlugin("modules.styleground_preview.preview")

---

local styleground_preview_module = {}

---

-- find the right place to put the submenu
local menubar = require("ui.menubar").menubar
local viewMenu = $(menubar):find(menu -> menu[1] == "view")[2]
local previewMenu = $(viewMenu):find(menu -> menu[1] == "anotherloennplugin_styleground_preview")
if not previewMenu then
  previewMenu = {"anotherloennplugin_styleground_preview", {}}

  local layersIndex = $(viewMenu):index(menu -> menu[1] == "view_layer")
  table.insert(viewMenu, layersIndex + 1, previewMenu)
end

local function get_bg()   return preview.bg_enabled end
local function get_fg()   return preview.fg_enabled end
local function get_snap() return preview.snap_to_room end
local function get_anim() return preview.anim_start ~= nil end

-- populate the submenu
previewMenu[2] = {
  {"anotherloennplugin_styleground_preview_bg",   preview.toggle_bg,   "checkbox", get_bg},
  {"anotherloennplugin_styleground_preview_fg",   preview.toggle_fg,   "checkbox", get_fg},
  {"anotherloennplugin_styleground_preview_snap", preview.toggle_snap, "checkbox", get_snap},
  {"anotherloennplugin_styleground_preview_anim", preview.toggle_anim, "checkbox", get_anim}
}

---

-- if hook unload function is present, call it
if celesteRender.__anotherloennplugin_unload then
  celesteRender:__anotherloennplugin_unload()
end

function styleground_preview_module.init()
  -- apply a hook to draw the preview above and below the map
  local orig_celesterender_drawmap = celesteRender.drawMap
  function celesteRender.drawMap(state)
    if preview.bg_enabled then
      preview.draw(state, false)
    end
    orig_celesterender_drawmap(state)
    if preview.fg_enabled then
      preview.draw(state, true)
    end
  end

  -- apply a hook to hide the room backgrounds while the bg stylegrounds are being previewed
  local orig_getRoomBackgroundColor = celesteRender.getRoomBackgroundColor
  function celesteRender.getRoomBackgroundColor(room, selected, state)
    if preview.bg_enabled then
      return {0, 0, 0, 0}
    else
      return orig_getRoomBackgroundColor(room, selected, state)
    end
  end

  -- allow hooks to be unloaded later if ctrl+f5 is used
  function celesteRender.__anotherloennplugin_unload(self)
    self.drawMap = orig_celesterender_drawmap
    self.getRoomBackgroundColor = orig_getRoomBackgroundColor
    self.__anotherloennplugin_unload = nil
  end
end

---

return styleground_preview_module
