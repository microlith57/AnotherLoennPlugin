local mods = require("mods")

local teleporter_module = {}

do
  -- check if debugrc works, this tool doesn't make sense without it
  local debugrc = mods.requireFromPlugin("libraries.debugrc")
  if not debugrc then return end
end

function teleporter_module.loadTool()
  teleporter_module.tool = mods.requireFromPlugin("modules.teleporter.tool")
  return teleporter_module.tool
end

return teleporter_module
