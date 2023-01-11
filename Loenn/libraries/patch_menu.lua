local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.4.3") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local menubar = require("ui.menubar").menubar

local stylegroundPreview = require("mods").requireFromPlugin("libraries.preview.styleground")
local colorgradePreview = require("mods").requireFromPlugin("libraries.preview.colorgrade", "AnotherLoennPluginColorgrading")

---

local function checkbox(menu, lang, toggle, active)
  local item = $(menu):find(item -> item[1] == lang)
  if not item then
    item = {}
    table.insert(menu, item)
  end
  item[1] = lang
  item[2] = toggle
  item[3] = "checkbox"
  item[4] = active
end

---

--[[
  add the menu options
]]

local viewMenu = $(menubar):find(menu -> menu[1] == "view")[2]

checkbox(viewMenu, "anotherloennplugin_styleground_preview_bg",
         stylegroundPreview.toggle_bg,
         function() return stylegroundPreview.bg_enabled end)

checkbox(viewMenu, "anotherloennplugin_styleground_preview_fg",
         stylegroundPreview.toggle_fg,
         function() return stylegroundPreview.fg_enabled end)

checkbox(viewMenu, "anotherloennplugin_styleground_preview_snap",
         stylegroundPreview.toggle_snap,
         function() return stylegroundPreview.snap_to_room end)

checkbox(viewMenu, "anotherloennplugin_styleground_preview_anim",
         stylegroundPreview.toggle_anim,
         function() return stylegroundPreview.anim_start ~= nil end)

if colorgradePreview then
  checkbox(viewMenu, "anotherloennplugin_colorgrade_preview",
          colorgradePreview.toggle,
          function() return colorgradePreview.enabled end)
end

---

return {}
