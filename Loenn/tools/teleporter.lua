local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.featureEnabled("debugrc") or not settings.get("teleporter", true, "debugrc") then
  return
end

---

local state = require("loaded_state")
local configs = require("configs")
local viewportHandler = require("viewport_handler")
local keyboardHelper = require("utils.keyboard")
local drawableSprite = require("structs.drawable_sprite")

local debugrc = mods.requireFromPlugin("libraries.debugrc")
if not debugrc.enabled then
  return
end

---

local tool = {
  _type = "tool",
  name = "anotherloennplugin_teleporter",
  group = "placement_end",
  layer = "anotherloennplugin_teleport_keep_session",
  validLayers = {
    "anotherloennplugin_teleport_instant",
    "anotherloennplugin_teleport_respawn"
  }
}

---

local playerSprite = drawableSprite.fromTexture("characters/player/sitDown00", {justification = {0.5, 1.0}})

local function transformCoords(room, x, y, precise)
  local mx, my = viewportHandler.getRoomCoordinates(room, x, y)
  if not precise then
    mx = math.floor(mx / 8 + 0.5) * 8
    my = math.floor(my / 8 + 1) * 8
  end

  if mx < 0 or my < 0 or mx >= room.width or my >= room.height then
    return
  end

  return mx, my
end

---

function tool.draw()
  local room = state.getSelectedRoom()

  if room then
    local mx, my = transformCoords(room, x, y, keyboardHelper.modifierHeld(configs.editor.precisionModifier))
    if not mx then
      return
    end

    playerSprite.x = mx
    playerSprite.y = my - 16
    viewportHandler.drawRelativeTo(
      room.x,
      room.y,
      function()
        playerSprite:draw()
      end
    )
  end
end

function tool.mousepressed(x, y, button, _istouch, _presses)
  if button ~= configs.editor.toolActionButton then
    return
  end

  local room = state.getSelectedRoom()

  if room then
    local mx, my = transformCoords(room, x, y, keyboardHelper.modifierHeld(configs.editor.precisionModifier))
    if not mx then
      return
    end

    local data = {
      level = room.name,
      x = tostring(mx),
      y = tostring(my),
      forcenew = tostring(tool.layer == "anotherloennplugin_teleport_replace_session")
    }

    if tool.layer == "anotherloennplugin_teleport_respawn" then
      debugrc.request("/respawn")
    end

    debugrc.request("/tp?level=" .. room.name .. "&x=" .. mx .. "&y=" .. my)
  end
end

return tool
