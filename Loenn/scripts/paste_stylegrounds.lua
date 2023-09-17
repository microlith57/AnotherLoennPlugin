local state = require("loaded_state")
local utils = require("utils")
local snapshot = require("structs.snapshot")

local script = {
  name = "pasteStylegroundsFromClipboard",
  parameters = {
    replaceExistingStylegrounds = false,
    replaceOnly = "",
    addTags = ""
  },
  displayName = "Clipboard: Paste Stylegrounds",
  tooltip = "Pastes stylegrounds from the clipboard into the map.",
  tooltips = {
    replaceExistingStylegrounds = "Whether to replace the existing stylegrounds.",
    replaceOnly = "If not blank, replace the Only fields with this.",
    addTags = "Add these tags to all pasted stylegrounds."
  }
}

local function forward_replace(data)
  state.map.stylesFg = data.newFg
  state.map.stylesBg = data.newBg
end

local function forward_noreplace(data)
  for i, style in ipairs(data.newFg) do
    table.insert(state.map.stylesFg, style)
  end
  for i, style in ipairs(data.newBg) do
    table.insert(state.map.stylesBg, style)
  end
end

local function backward(data)
  state.map.stylesFg = data.oldFg
  state.map.stylesBg = data.oldBg
end

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

  local data = {
    oldFg = utils.deepcopy(state.map.stylesFg),
    oldBg = utils.deepcopy(state.map.stylesBg),
    newFg = {},
    newBg = {}
  }

  for i, style in ipairs(fromClipboard.fg or {}) do
    if args.replaceOnly ~= "" then
      style.only = args.replaceOnly
    end
    if args.addTags ~= "" then
      if style.tag ~= "" then
        style.tag = style.tag .. ','
      end
      style.tag = style.tag .. args.addTags
    end
    table.insert(data.newFg, style)
  end

  for i, style in ipairs(fromClipboard.bg or {}) do
    if args.replaceOnly ~= "" then
      style.only = args.replaceOnly
    end
    if args.addTags ~= "" then
      if style.tag ~= "" then
        style.tag = style.tag .. ','
      end
      style.tag = style.tag .. args.addTags
    end
    table.insert(data.newBg, style)
  end

  local forward = args.replaceExistingStylegrounds and forward_replace or forward_noreplace
  forward(data)

  return snapshot.create(script.name, data, backward, forward)
end

return script
