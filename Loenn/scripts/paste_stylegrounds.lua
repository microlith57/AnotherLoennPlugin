local state = require("loaded_state")
local utils = require("utils")
local snapshot = require("structs.snapshot")

local script = {
  name = "pasteStylegroundsFromClipboard",
  parameters = {
    replaceExistingStylegrounds = false
  },
  displayName = "Clipboard: Paste Stylegrounds",
  tooltip = "Pastes stylegrounds from the clipboard into the map.",
  tooltips = {
    replaceExistingStylegrounds = "Whether to replace the existing stylegrounds."
  }
}

function script.prerun(args)
  local oldStylesFg = utils.deepcopy(state.map.stylesFg)
  local oldStylesBg = utils.deepcopy(state.map.stylesBg)

  local clipboard = love.system.getClipboardText(text)
  if not clipboard or clipboard:sub(1, 1) ~= "{" or clipboard:sub(-1, -1) ~= "}" then
    -- no arbitrary code execution allowed!
    return false
  end
  local success, fromClipboard = utils.unserialize(clipboard, true, 3)
  if not success then return false end

  local function forward(data)
    state.map.stylesFg = fromClipboard.fg
    state.map.stylesBg = fromClipboard.bg
  end

  local function forward_noreplace(data)
    for i, style in ipairs(fromClipboard.fg) do
      table.insert(state.map.stylesFg, style)
    end
    for i, style in ipairs(fromClipboard.bg) do
      table.insert(state.map.stylesBg, style)
    end
  end

  local function backward(data)
    state.map.stylesFg = oldStylesFg
    state.map.stylesBg = oldStylesBg
  end

  if args.replaceExistingStylegrounds then
    forward()
    return snapshot.create(script.name, {}, backward, forward)
  else
    forward_noreplace()
    return snapshot.create(script.name, {}, backward, forward_noreplace)
  end
end

return script
