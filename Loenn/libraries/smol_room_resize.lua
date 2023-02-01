local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.featureEnabled("small_room_resize") then
  return {}
end

local roomStruct = require("structs.room")
local roomResizer = require("input_devices.room_resizer")
local keyboardHelper = require("utils.keyboard")

---

local modifier = settings.get("modifier", "ctrl", "small_room_resize")

---

if roomResizer.___anotherLoennPlugin then
  roomResizer.___anotherLoennPlugin.unload()
end

_orig_mousemoved = roomResizer.mousemoved
function roomResizer.mousemoved(x, y, dx, dy, istouch)
  -- if not holding ctrl, use the default behaviour
  if not keyboardHelper.modifierHeld(modifier) then
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

---

return {}