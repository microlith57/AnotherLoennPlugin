local mods = require("mods")

local viewportHandler = require("viewport_handler")
local history = require("history")
local snapshotUtils = require("snapshot_utils")

local state = require("loaded_state")
local drawing = require("utils.drawing")
local colors = require("consts.colors")

local tools = require("tools")
local toolUtils = require("tool_utils")
local selectionItemUtils = require("selection_item_utils")

local alp_utils = mods.requireFromPlugin("libraries.utils")
local selections = mods.requireFromPlugin("libraries.selection")

---

local settings = mods.requireFromPlugin("modules.snap_to_grid.settings")

---

local spacing_x, spacing_y = settings.grid_spacing_x, settings.grid_spacing_x

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
local function snapIndividual(room, layer, sels, dir)
  local dxs, dys = {}, {}

  local function forward()
    local modified = false

    for i, sel in ipairs(sels) do
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

    for i, sel in ipairs(sels) do
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
local function snapFirst(room, layer, sels, dir)
  local dx, dy = 0, 0

  local function forward()
    local rerender = false

    local sel = sels[1]
    dx, dy = getSnapDelta(sel.item and sel.item.x or sel.x, sel.item and sel.item.y or sel.y, dir)

    for i, sel in ipairs(sels) do
      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, dx, dy) then
        rerender = true
      end
    end

    return rerender
  end

  local function backward()
    local rerender = false

    for i, sel in ipairs(sels) do
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
local function snapCentroid(room, layer, sels, dir)
  local dx, dy = 0, 0

  local function forward()
    local sum_x = 0
    local sum_y = 0
    local n = 0
    for i, sel in ipairs(sels) do
      sum_x = sum_x + (sel.item and sel.item.x or sel.x)
      sum_y = sum_y + (sel.item and sel.item.y or sel.y)
      n = n + 1
    end
    dx, dy = getSnapDelta(math.floor((sum_x / n) + 0.5), math.floor((sum_y / n) + 0.5), dir)

    local rerender = false

    for i, sel in ipairs(sels) do
      if (dx ~= 0 or dy ~= 0) and selectionItemUtils.moveSelection(room, layer, sel, dx, dy) then
        rerender = true
      end
    end

    return rerender
  end

  local function backward()
    local rerender = false

    for i, sel in ipairs(sels) do
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

  local room = state.getSelectedRoom()

  local sels = selections.getSelections()
  if not sels or #sels == 0 then
    return
  end

  local forward, backward

  if settings.snapping_mode == "individual" then
    forward, backward = snapIndividual(room, layer, sels, dir)
  elseif settings.snapping_mode == "first" then
    forward, backward = snapFirst(room, layer, sels, dir)
  elseif settings.snapping_mode == "centroid" then
    forward, backward = snapCentroid(room, layer, sels, dir)
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

local hotkey_left    = alp_utils.addHotkey(settings.hotkey_left, snapLeft)
local hotkey_right   = alp_utils.addHotkey(settings.hotkey_right, snapRight)
local hotkey_up      = alp_utils.addHotkey(settings.hotkey_up, snapUp)
local hotkey_down    = alp_utils.addHotkey(settings.hotkey_down, snapDown)
local hotkey_neutral = alp_utils.addHotkey(settings.hotkey_neutral, snapNeutral)
local hotkey_grid    = alp_utils.addHotkey(settings.hotkey_grid, toggle_grid)

---

return device
