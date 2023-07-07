local mods = require("mods")

local backdrop_renderers = {
  parallax = mods.requireFromPlugin("modules.styleground_preview.backdrops.parallax"),
  planets = mods.requireFromPlugin("modules.styleground_preview.backdrops.planets"),
}

return backdrop_renderers
