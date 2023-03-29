local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.featureEnabled("disable_camera_snap", false) then
  return {}
end

---

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")

---

if viewportHandler.___anotherLoennPlugin then
  viewportHandler.___anotherLoennPlugin.unload()
  viewportHandler.___anotherLoennPlugin = {}
end

local orig_moveToPosition = viewportHandler.moveToPosition
function viewportHandler.moveToPosition(x, y, scale, centered)
  -- orig_moveToPosition(x, y, scale, centered)
end

viewportHandler.___anotherLoennPlugin = {
  unload = function()
    viewportHandler.moveToPosition = orig_moveToPosition
  end
}

---

return {apply = apply}
