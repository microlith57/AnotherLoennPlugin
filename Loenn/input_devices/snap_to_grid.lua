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

local spacing_x = math.ceil(tonumber(settings.get("grid_spacing_x", 8, "snap_to_grid")) or 8)
local spacing_y = math.ceil(tonumber(settings.get("grid_spacing_y", 8, "snap_to_grid")) or 8)

---

local tools = require("tools")
local configs = require("configs")
local selectionUtils = require("selections")
local selectionItemUtils = require("selection_item_utils")
local hotkeyHandler = require("hotkey_handler")
local history = require("history")
local toolUtils = require("tool_utils")
local snapshotUtils = require("snapshot_utils")
local viewportHandler = require("viewport_handler")
local drawing = require("utils.drawing")
local colors = require("consts.colors")

---

local device = {_enabled = true, _type = "device"}
local mouse_x, mouse_y

device.display_grid = false
local function toggle_grid()
  device.display_grid = not device.display_grid
end

function device.draw()
  if not device.display_grid then
    return
  end

  local viewport = viewportHandler.viewport

  if viewport.scale < 1 then
    return
  end

  drawing.callKeepOriginalColor(
    function()
      local col = colors.roomBorderDefault
      love.graphics.setColor(col[1], col[2], col[3], 0.2)

      local x_min = -(math.floor(viewport.x) % (spacing_x * viewport.scale))
      local x_max = math.ceil(viewport.width)
      local y_min = -(math.floor(viewport.y) % (spacing_y * viewport.scale))
      local y_max = math.ceil(viewport.height)

      for x = x_min, x_max, spacing_x * viewport.scale do
        love.graphics.line(x, 0, x, viewport.height)
      end

      for y = y_min, y_max, spacing_y * viewport.scale do
        love.graphics.line(0, y, viewport.width, y)
      end
    end
  )
end

function device.mousemoved(x, y, dx, dy, istouch)
  -- for later...
  mouse_x, mouse_y = x, y
end

---

--[[
  from a selection's position, obtain the (dx, dy) to move it by.
  if a direction is specified, it will always be moved in that direction
]]
local function getSnapDelta(x, y, dir)
  local x_offset = x % spacing_x
  local y_offset = y % spacing_y

  if dir == "left" then
    return -x_offset, 0
  elseif dir == "right" then
    return (spacing_x - x_offset) % spacing_x, 0
  elseif dir == "up" then
    return 0, -y_offset
  elseif dir == "down" then
    return 0, (spacing_y - y_offset) % spacing_y
  else
    local dx, dy = 0, 0

    if x_offset <= (spacing_x / 2) then
      dx = -x_offset
    else
      dx = (spacing_x - x_offset) % spacing_x
    end

    if y_offset <= (spacing_y / 2) then
      dy = -y_offset
    else
      dy = (spacing_y - y_offset) % spacing_y
    end

    return dx, dy
  end
end

---

--[[
  snap each selected item to the grid individually
]]
local function snapIndividual(room, layer, selections, dir)
  local dxs, dys = {}, {}

  local function forward()
    local modified = false

    for i, sel in ipairs(selections) do
      local dx, dy = getSnapDelta(sel.item and sel.item.x or sel.x, sel.item and sel.item.y or sel.y, dir)
      dxs[i], dys[i] = dx, dy

      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, dx, dy) then
        modified = true
      end
    end

    return modified
  end

  local function backward()
    local modified = false

    for i, sel in ipairs(selections) do
      local dx, dy = dxs[i], dys[i]
      if not dx or not dy then
        break
      end

      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, -dx, -dy) then
        modified = true
      end
    end

    return modified
  end

  return forward, backward
end

--[[
  snap the first item selected to the grid, moving the others by the same amount
]]
local function snapFirst(room, layer, selections, dir)
  local dx, dy = 0, 0

  local function forward()
    local rerender = false

    local sel = selections[1]
    dx, dy = getSnapDelta(sel.item and sel.item.x or sel.x, sel.item and sel.item.y or sel.y, dir)

    for i, sel in ipairs(selections) do
      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, dx, dy) then
        rerender = true
      end
    end

    return rerender
  end

  local function backward()
    local rerender = false

    for i, sel in ipairs(selections) do
      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, -dx, -dy) then
        rerender = true
      end
    end

    return rerender
  end

  return forward, backward
end

--[[
  move the selected items so that their centre of mass is snapped to grid
]]
local function snapCentroid(room, layer, selections, dir)
  local dx, dy = 0, 0

  local function forward()
    local sum_x = 0
    local sum_y = 0
    local n = 0
    for i, sel in ipairs(selections) do
      sum_x = sum_x + (sel.item and sel.item.x or sel.x)
      sum_y = sum_y + (sel.item and sel.item.y or sel.y)
      n = n + 1
    end
    dx, dy = getSnapDelta(math.floor((sum_x / n) + 0.5), math.floor((sum_y / n) + 0.5), dir)

    local rerender = false

    for i, sel in ipairs(selections) do
      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, dx, dy) then
        rerender = true
      end
    end

    return rerender
  end

  local function backward()
    local rerender = false

    for i, sel in ipairs(selections) do
      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, -dx, -dy) then
        rerender = true
      end
    end

    return rerender
  end

  return forward, backward
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
    -- this is probably tile selection or something, which we don't support
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
  -- this is why the mouse position was saved earlier
  tools.currentTool.mouseclicked(mouse_x, mouse_y, configs.editor.contextMenuButton, false, {})
  selectionUtils.getContextSelections = orig_getContextSelections

  if not selections or #selections == 0 then
    return
  end

  local forward, backward

  if snapMode == "individual" then
    forward, backward = snapIndividual(room, layer, selections, dir)
  elseif snapMode == "first" then
    forward, backward = snapFirst(room, layer, selections, dir)
  elseif snapMode == "centroid" then
    forward, backward = snapCentroid(room, layer, selections, dir)
  else
    return -- unreachable
  end

  local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Snapped to grid")

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
hotkeyHandler.createAndRegisterHotkey(
  settings.get("hotkey_toggle_grid", "ctrl + shift + g", "snap_to_grid"),
  toggle_grid,
  gridSnapHotkeys
)

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
