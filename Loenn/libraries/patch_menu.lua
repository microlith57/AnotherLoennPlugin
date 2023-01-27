local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.5.0") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local menubar = require("ui.menubar").menubar

local stylegroundPreview = require("mods").requireFromPlugin("libraries.preview.styleground")
local colorgradePreview = require("mods").requireFromPlugin("libraries.preview.colorgrade", "AnotherLoennPluginColorgrading")

---

local function submenu(menu, lang)
  local item = $(menu):find(item -> item[1] == lang)
  if not item then
    item = {}
    table.insert(menu, item)
  end
  item[1] = lang
  item[2] = {}
  return item[2]
end

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
local stylegroundMenu = submenu(viewMenu, "anotherloennplugin_preview_styleground")

checkbox(stylegroundMenu, "anotherloennplugin_preview_styleground_bg",
         stylegroundPreview.toggle_bg,
         function() return stylegroundPreview.bg_enabled end)

checkbox(stylegroundMenu, "anotherloennplugin_preview_styleground_fg",
         stylegroundPreview.toggle_fg,
         function() return stylegroundPreview.fg_enabled end)

checkbox(stylegroundMenu, "anotherloennplugin_preview_styleground_snap",
         stylegroundPreview.toggle_snap,
         function() return stylegroundPreview.snap_to_room end)

checkbox(stylegroundMenu, "anotherloennplugin_preview_styleground_anim",
         stylegroundPreview.toggle_anim,
         function() return stylegroundPreview.anim_start ~= nil end)

if colorgradePreview then
  local logging = require("logging")
  logging.warning("[AnotherLoennPlugin] ---")
  logging.warning("[AnotherLoennPlugin] Colorgrade preview enabled!")
  logging.warning("[AnotherLoennPlugin] Any problems you experience should be reported to microlith57#4004, even if they appear to be unrelated.")
  logging.warning("[AnotherLoennPlugin] Before reporting anything, first try moving the AnotherLoennPluginColorgrading plugin out of your Mods folder!")
  logging.warning("[AnotherLoennPlugin] ---")

  checkbox(viewMenu, "anotherloennplugin_preview_colorgrade",
          colorgradePreview.toggle,
          function() return colorgradePreview.enabled end)
end

---

return {}
