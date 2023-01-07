local state = require("loaded_state")
local utils = require("utils")

local script = {
  name = "copyStylegroundsToClipboard",
  parameters = {
    convertApplyGroupsToFlattenedList = true
  },
  displayName = "Clipboard: Copy Stylegrounds",
  tooltip = "Copies stylegrounds from the map into the clipboard.",
  tooltips = {
    convertApplyGroupsToFlattenedList = "Whether to flatten groups of stylegrounds so that everything is all on one level."
  }
}

local function flatten(styles)
  local result = {}

  local function recursive_add_to_list(style, props)
    if style._type == "apply" then
      -- this is a group, so recurse over its childen, applying the group properties (possibly on top of higher-level group properties)
      local new_props = table.shallowcopy(props)
      for k, v in pairs(style) do
        if k ~= "_type" and k ~= "children" then
          new_props[k] = v
        end
      end

      for i, child in ipairs(style.children) do
        recursive_add_to_list(child, new_props)
      end
    else
      -- this is a normal styleground, so apply anything we have saved up and put it in the list
      table.insert(result, ($(style) .. $(props))())
    end
  end

  for i, style in ipairs(styles) do
    recursive_add_to_list(style, {})
  end

  return result
end

function script.prerun(args)
  local stylesFg = utils.deepcopy(state.map.stylesFg)
  local stylesBg = utils.deepcopy(state.map.stylesBg)

  if args.convertApplyGroupsToFlattenedList then
    stylesFg = flatten(stylesFg)
    stylesBg = flatten(stylesBg)
  end

  local success, text = utils.serialize({
    fg = stylesFg,
    bg = stylesBg
  })

  if success then
    love.system.setClipboardText(text)
  end
end

return script
