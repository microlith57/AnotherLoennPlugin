local meta = require("meta")
local version = require("utils.version_parser")
if meta.version ~= version("0.4.3") and meta.version ~= version("0.0.0-dev") then
  return {}
end

local roomStruct = require("structs.room")
local roomResizer = require("input_devices.room_resizer")
local keyboardHelper = require("utils.keyboard")
local configs = require("configs")

if roomResizer.___anotherLoennPlugin then
  roomResizer.___anotherLoennPlugin.unload()
end

_orig_mousemoved = roomResizer.mousemoved
function roomResizer.mousemoved(x, y, dx, dy, istouch)
  -- if not holding ctrl, use the default behaviour
  if not keyboardHelper.modifierHeld(configs.editor.precisionModifier) then
    return _orig_mousemoved(x, y, dx, dy, istouch)
  end

  -- store the original minimum size...
  local orig_minWidth = roomStruct.recommendedMinimumWidth
  roomStruct.recommendedMinimumWidth = 8
  local orig_minHeight = roomStruct.recommendedMinimumHeight
  roomStruct.recommendedMinimumHeight = 8

  local res = _orig_mousemoved(x, y, dx, dy, istouch)

  -- ...and restore it after
  roomStruct.recommendedMinimumWidth = orig_minWidth
  roomStruct.recommendedMinimumHeight = orig_minHeight

  return res
end

roomResizer.___anotherLoennPlugin = {
  unload = function()
    roomResizer.mousemoved = _orig_mousemoved
  end
}
