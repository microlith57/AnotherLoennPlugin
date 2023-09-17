local mods = require("mods")
local utils = require("utils")
local selectionUtils = require("selections")
local selection = mods.requireFromPlugin("libraries.selection")

---

local script = {}

script.name = "extendSelectionSimple"
script.displayName = "Extend Selection (Simple)"
script.useSelections = true

function script.run(room, args)
  local selected = selection.getSelections()

  local selectionsByLayerAndName = {
    entities = {},
    triggers = {},
    decalsFg = {},
    decalsBg = {}
  }
  local any = {}

  for _, sel in ipairs(selected) do
    local layer = selectionsByLayerAndName[sel.layer]

    if layer and sel.item then
      any[sel.layer] = true

      local name = sel.item._name or sel.item.texture

      layer[name] = layer[name] or {alreadySelected = {}}
      layer[name].alreadySelected[sel.item] = true
    end
  end

  for layer, _ in pairs(any) do
    for _, item in ipairs(room[layer]) do
      local byName = selectionsByLayerAndName[layer][item._name or item.texture]
      if byName and not byName.alreadySelected[item] then
        selectionUtils.getSelectionsForItem(room, layer, item, selected)
      end
    end
  end
end

---

return script
