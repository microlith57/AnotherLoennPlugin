local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")

-- options:
-- * `individual` (like ahorn)
-- * `first` (snaps first item's position to grid; moves others by same amount)
-- * `centroid` (snaps selection's centre of mass to grid)
local snapMode = settings.get("snapping_mode", "individual", "snap_to_grid")
if snapMode ~= "individual" and snapMode ~= "first" and snapMode ~= "centroid" then
  snapMode = "individual"
end

---

local tools = require("tools")
local configs = require("configs")
local selectionUtils = require("selections")
local selectionItemUtils = require("selection_item_utils")
local hotkeyHandler = require("hotkey_handler")
local history = require("history")
local toolUtils = require("tool_utils")
local snapshotUtils = require("snapshot_utils")

---

local device = {_enabled = true, _type = "device"}
local mouse_x, mouse_y

-- function device.draw()
-- todo: render grid
-- end

function device.mousemoved(x, y, dx, dy, istouch)
  mouse_x, mouse_y = x, y
end

---

--[[
  from a selection's position, obtain the (dx, dy) to move it by.
  if a direction is specified, it will always be moved in that direction
]]
local function getSnapDelta(x, y, dir)
  -- todo: custom grid size & offset

  local x_offset = x % 8
  local y_offset = y % 8

  if dir == "left" then
    return -x_offset, 0
  elseif dir == "right" then
    return (8 - x_offset) % 8, 0
  elseif dir == "up" then
    return 0, -y_offset
  elseif dir == "down" then
    return 0, (8 - y_offset) % 8
  else
    local dx, dy = 0, 0

    if x_offset <= (8 / 2) then
      dx = -x_offset
    else
      dx = (8 - x_offset) % 8
    end

    if y_offset <= (8 / 2) then
      dy = -y_offset
    else
      dy = (8 - y_offset) % 8
    end

    return dx, dy
  end
end

---

--[[
  snap each selected item to the grid individually
]]
local function snapIndividual(room, layer, selections, dir)
  local rerender = false

  for i, sel in ipairs(selections) do
    dx, dy = getSnapDelta(sel.x, sel.y, dir)
    rerender = selectionItemUtils.moveSelection(room, layer, sel, dx, dy) or rerender
  end

  return rerender
end

--[[
  snap the first item selected to the grid, moving the others by the same amount
]]
local function snapFirst(room, layer, selections, dir)
  local rerender = false

  dx, dy = getSnapDelta(selections[1].x, selections[1].y, dir)
  for i, sel in ipairs(selections) do
    rerender = selectionItemUtils.moveSelection(room, layer, sel, dx, dy) or rerender
  end

  return rerender
end

--[[
  move the selected items so that their centre of mass is snapped to grid
]]
local function snapCentroid(room, layer, selections, dir)
  local rerender = false

  local sum_x = 0
  local sum_y = 0
  local n = 0
  for i, sel in ipairs(selections) do
    sum_x = sum_x + sel.x
    sum_y = sum_y + sel.y
    n = n + 1
  end

  dx, dy = getSnapDelta(math.floor((sum_x / n) + 0.5), math.floor((sum_y / n) + 0.5), dir)
  for i, sel in ipairs(selections) do
    rerender = selectionItemUtils.moveSelection(room, layer, sel, dx, dy) or rerender
  end

  return rerender
end

---

--[[
  obtain the current selection, and snap it to the grid using one of the above methods.
]]
local function snap(dir)
  if tools.currentToolName ~= "selection" then
    return
  end

  local layer = tools.currentTool.layer
  if layer ~= "entities" and layer ~= "triggers" and layer ~= "decalsFg" and layer ~= "decalsBg" then
    return
  end

  local room
  local layer
  local selections

  -- hehe :3c
  local orig_getContextSelections = selectionUtils.getContextSelections
  function selectionUtils.getContextSelections(r, l, _x, _y, sels)
    room = r
    layer = l
    selections = sels
  end
  tools.currentTool.mouseclicked(mouse_x, mouse_y, configs.editor.contextMenuButton, false, {})
  selectionUtils.getContextSelections = orig_getContextSelections

  if not selections or #selections == 0 then
    return
  end

  local function forward()
    if snapMode == "individual" then
      return snapIndividual(room, layer, selections, dir)
    elseif snapMode == "first" then
      return snapFirst(room, layer, selections, dir)
    elseif snapMode == "centroid" then
      return snapCentroid(room, layer, selections, dir)
    end
  end

  local snapshot, redraw = snapshotUtils.roomLayerSnapshot(forward, room, layer, "Snap to grid")

  if redraw then
    history.addSnapshot(snapshot)
    toolUtils.redrawTargetLayer(room, layer)
  end
end

---

local function snapLeft()
  snap("left")
end
local function snapRight()
  snap("right")
end
local function snapUp()
  snap("up")
end
local function snapDown()
  snap("down")
end
local function snapNeutral()
  snap("neutral")
end

---

local gridSnapHotkeys = {}

hotkeyHandler.createAndRegisterHotkey(
  settings.get("hotkey_snapLeft", "ctrl + shift + left", "snap_to_grid"),
  snapLeft,
  gridSnapHotkeys
)
hotkeyHandler.createAndRegisterHotkey(
  settings.get("hotkey_snapRight", "ctrl + shift + right", "snap_to_grid"),
  snapRight,
  gridSnapHotkeys
)
hotkeyHandler.createAndRegisterHotkey(
  settings.get("hotkey_snapUp", "ctrl + shift + up", "snap_to_grid"),
  snapUp,
  gridSnapHotkeys
)
hotkeyHandler.createAndRegisterHotkey(
  settings.get("hotkey_snapDown", "ctrl + shift + down", "snap_to_grid"),
  snapDown,
  gridSnapHotkeys
)
hotkeyHandler.createAndRegisterHotkey(
  settings.get("hotkey_snapNeutral", "shift + s", "snap_to_grid"),
  snapNeutral,
  gridSnapHotkeys
)
-- hotkeyHandler.createAndRegisterHotkey(
--   settings.get("hotkey_toggle_grid", "ctrl + shift + g", "snap_to_grid"),
--   device.toggle_grid,
--   gridSnapHotkeys
-- )

-- add the hotkeys
local _orig_createHotkeyDevice = hotkeyHandler.createHotkeyDevice
function hotkeyHandler.createHotkeyDevice(hotkeys)
  for i, hotkey in ipairs(gridSnapHotkeys) do
    table.insert(hotkeys, hotkey)
  end
  hotkeyHandler.createHotkeyDevice = _orig_createHotkeyDevice
  return _orig_createHotkeyDevice(hotkeys)
end

---

return device
