local meta = require("meta")
if meta.version >= version("0.4.3") then
    return
end

local mods = require("mods")
local parallax = require("parallax")
local utils = require("utils")

if parallax.___anotherLoennPlugin then
  parallax.___anotherLoennPlugin.unload()
end

local _orig_fieldInformation = parallax.fieldInformation
local fieldInformation_texture = {
  fieldType = "path",
  filePickerExtensions = {"png"},
  allowMissingPath = true, -- todo: implement proper resolver
  relativeToMod = false,
  filenameProcessor = function(filename)
    local modPath = mods.getFilenameModPath(filename)
    if modPath then
      -- texture is from a mod, so get its path within that mod
      filename = string.sub(filename, #modPath + 2)
    else
      -- texture is (probably) from the graphics dump, so get its path within that
      -- todo: better check?
      local index = string.find(filename, "Graphics")
      if index then
        filename = string.sub(filename, index)
      else
        -- oopsy, this isn't from either of those places
        -- reject it!
        return false
      end
    end

    -- Discard leading "Graphics/Atlases/Gameplay/" and file extension
    local filename, ext = utils.splitExtension(filename)
    local parts = utils.splitpath(filename, "/")

    return utils.convertToUnixPath(utils.joinpath(unpack(parts, 4)))
  end
}

function parallax.fieldInformation(style)
  local orig = _orig_fieldInformation(style)
  local copy = table.shallowcopy(orig)
  copy.texture = fieldInformation_texture
  return copy
end

parallax.___anotherLoennPlugin = {
  unload = function()
    parallax.fieldInformation = _orig_fieldInformation
  end
}
