local mods = require("mods")
local alp_utils = mods.requireFromPlugin("libraries.utils")
local modules = mods.requireFromPlugin("libraries.modules")

---

-- actual tool is in modules/room_mover/tool.lua
local room_mover = alp_utils.dig(modules, 'room_mover', 'module')

if room_mover then
  return room_mover.loadTool()
end
