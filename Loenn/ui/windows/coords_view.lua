local mods = require("mods")
local uie = require("ui.elements")

local group = uie.group({})

return {
  getWindow = function()
    local window = mods.requireFromPlugin("modules.coords_view.window")
    window.group = group

    return group
  end
}
