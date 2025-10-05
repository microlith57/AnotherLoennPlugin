local mods = require("mods")
local utils = require("utils")
local selectionUtils = require("selections")
local selection = mods.requireFromPlugin("libraries.selection")

---

local script = {}

script.name = "decimateSelection"
script.displayName = "Decimate Selection"
script.useSelections = true
script.parameters = {
  probabilityToKeep = 0.2
}
script.tooltips = {
  probabilityToKeep = "Probability in [0, 1] that each entity will be kept in the selection."
}

function script.run(room, args)
  local probability = args.probabilityToKeep
  local selected = selection.getSelections()

  local toRemove = {}

  for i = #selected, 1, -1 do
    if probability == 0 or math.random() > probability then
      table.remove(selected, i)
    end
  end
end

---

return script
