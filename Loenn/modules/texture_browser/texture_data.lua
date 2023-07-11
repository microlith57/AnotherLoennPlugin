local utils = require("utils")
local tasks = require("utils.tasks")

local languageRegistry = require("language_registry")
local atlases = require("atlases")
local logging = require("logging")

local language = languageRegistry.getLanguage()

---

local textureData = {
  externalAtlasReady = false
}

local textureList = {}
local atlasLoadTask

local callbacks = {}

---

function textureData.loadExternalAtlasIfNecessary(callback)
  if textureData.externalAtlasReady then
    callback()
    return
  elseif atlasLoadTask then
    table.insert(callbacks, callback)
    return
  end

  -- this asset will never be requested, so won't be lazyloaded
  -- hence, if it's in the atlas, the whole external atlas must have been loaded
  if rawget(atlases.gameplay, "util/microlith57/AnotherLoennPlugin/lazy_loading_detector") then
    textureData.externalAtlasReady = true
    return
  end

  atlasLoadTask = tasks.newTask(function()
    local t1 = love.timer.getTime()
    atlases.loadExternalAtlas("Gameplay")
    local t2 = love.timer.getTime()

    logging.info("[AnotherLoennPlugin] loading external gameplay atlas took " .. math.ceil((t2 - t1) * 1000) .. "ms")

    textureData.externalAtlasReady = true
    atlasLoadTask = nil
  end, function()
    for _, cb in ipairs(callbacks) do
      cb()
    end
    callbacks = {}
  end)

  table.insert(callbacks, callback)
end

function textureData.getTextureData()
  if #textureList > 0 then
    return textureList
  end

  local buf = {}

  for name, sprite in pairs(atlases.gameplay) do
    local firstchar = name:sub(1, 1)
    if type(sprite) == "table"
      and firstchar ~= "_"
      and firstchar ~= "@"
      and not (firstchar == 'b' and utils.startsWith(name, "bgs/microlith57/AnotherLoennPlugin"))
      then

      local mods = {}
      if sprite.internalFile then
        mods[1] = tostring(language.mods.Celeste.name)
      else
        for i, mod in ipairs(sprite.associatedMods) do
          mods[i] = tostring(language.mods[mod].name._exists and language.mods[mod].name or mod)
        end
      end

      table.insert(buf, {name = name, sprite = sprite, associatedMods = mods})

    end
  end

  table.sort(buf, function(a, b)
    return a.name < b.name
  end)

  local current_anim = {}
  local current_anim_basename

  for i, entry in ipairs(buf) do
    item = {
      index = i,
      name = entry.name, sprite = entry.sprite, associatedMods = entry.associatedMods
    }

    local name = entry.name
    local frame_str = name:match("[^%d](%d+)$")
    if frame_str then
      local basename = name:sub(1, #name - #frame_str)
      item.frame = tonumber(frame_str)

      if current_anim_basename ~= basename then
        current_anim = {
          basename = basename
        }
        current_anim_basename = basename
        item.firstFrame = true
      else
        item.firstFrame = false

        if not current_anim.resolutionInconsistent then
          local first = current_anim[1]
          if first and first.sprite then
            -- check to see if resolutions are the same
            local f_width  = first.sprite.realWidth  or first.sprite.width  or "?"
            local f_height = first.sprite.realHeight or first.sprite.height or "?"
            local i_width  = item.sprite.realWidth   or item.sprite.width   or "?"
            local i_height = item.sprite.realHeight  or item.sprite.height  or "?"

            if f_width ~= i_width or f_height ~= i_height then
              -- they aren't, so mark for later
              current_anim.resolutionInconsistent = true
            end
          else
            -- first frame is bad, something's definitely wrong; might as well blame this
            current_anim.numberingWrong = true
          end
        end
      end

      if not current_anim.numberingWrong and item.frame ~= #current_anim then
        -- this frame is frame n, so should go in slot n+1 in the animation (due to lua indexing)
        -- but this won't be the case with table.insert, so the frames must be wrong somehow (start at nonzero, have gaps, or wrong order)
        -- so, mark this in the anim
        current_anim.numberingWrong = true
      end
      table.insert(current_anim, item)

      item.anim = current_anim
    end

    textureList[i] = item
  end

  logging.info("[AnotherLoennPlugin] loaded " .. #textureList .. " atlas entries")

  return textureList
end

return textureData
