local mods = require("mods")

local room_mover_module = {}

function room_mover_module.loadTool()
  room_mover_module.tool = mods.requireFromPlugin("modules.room_mover.tool")
  return room_mover_module.tool
end

return room_mover_module
