local mods = require("mods")
local alp_utils = mods.requireFromPlugin("libraries.utils")
local modules = mods.requireFromPlugin("libraries.modules")

---

-- actual tool is in modules/teleporter/tool.lua
local teleporter = alp_utils.dig(modules, 'teleporter', 'module')

if teleporter then
  return teleporter.loadTool()
end
