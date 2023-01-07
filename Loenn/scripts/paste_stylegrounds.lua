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
    -- yolo
    state.map.stylesFg = fromClipboard.fg
    state.map.stylesBg = fromClipboard.bg
  end

  local function backward(data)
    state.map.stylesFg = oldStylesFg
    state.map.stylesBg = oldStylesBg
  end

  forward()

  return snapshot.create(script.name, {}, backward, forward)
end

return script
