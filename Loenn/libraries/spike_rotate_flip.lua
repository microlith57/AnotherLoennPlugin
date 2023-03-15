local mods = require("mods")

local settings = mods.requireFromPlugin("libraries.settings")
if not settings.featureEnabled("spike_rotate_flip") then
  return {}
end

-- options:
-- * `centroid` (centre of the entity)
-- * `position` (true position of the entity, i.e. the top right)
local pivot_mode = settings.get("rotation_pivot", "centroid", "spike_rotate_flip")
if pivot_mode ~= "centroid" and pivot_mode ~= "position" then
  pivot_mode = "centroid"
end

local entities = require("entities")

---

-- direction -> index mapping; adding 1 to index = 90° rotation
local directions = {
  "spikesUp",
  "spikesRight",
  "spikesDown",
  "spikesLeft"
}

local trigger_directions = {
  "triggerSpikesUp",
  "triggerSpikesRight",
  "triggerSpikesDown",
  "triggerSpikesLeft"
}

-- index -> direction mapping
local directions_T = {
  ["spikesUp"] = 1,
  ["spikesRight"] = 2,
  ["spikesDown"] = 3,
  ["spikesLeft"] = 4
}

local trigger_directions_T = {
  ["triggerSpikesUp"] = 1,
  ["triggerSpikesRight"] = 2,
  ["triggerSpikesDown"] = 3,
  ["triggerSpikesLeft"] = 4
}

---

-- generic rotation function for any spike direction
local function spike_rotate(room, entity, direction)
  local index = directions_T[entity._name]
  index = ((index + direction - 1) % 4) + 1
  entity._name = directions[index]

  local horizontal = entity._name == "spikesLeft" or entity._name == "spikesRight"
  if horizontal then
    -- rotating horizontal -> vertical
    if entity.width then
      entity.height = entity.width
      entity.width = nil
    end

    if pivot_mode == "centroid" then
      local offset = math.floor((entity.height / 2) / 8) * 8
      entity.x += offset
      entity.y -= offset
    end
  else
    -- rotating vertical -> horizontal
    if entity.height then
      entity.width = entity.height
      entity.height = nil
    end

    if pivot_mode == "centroid" then
      local offset = math.floor((entity.width / 2) / 8) * 8
      entity.y += offset
      entity.x -= offset
    end
  end

  return true
end

-- generic rotation function for any trigger spike direction
local function trigger_spike_rotate(room, entity, direction)
  local index = trigger_directions_T[entity._name]
  index = ((index + direction - 1) % 4) + 1
  entity._name = trigger_directions[index]

  local horizontal = entity._name == "triggerSpikesLeft" or entity._name == "triggerSpikesRight"
  if horizontal then
    -- rotating horizontal -> vertical
    if entity.width then
      entity.height = entity.width
      entity.width = nil
    end

    if pivot_mode == "centroid" then
      local offset = math.floor((entity.height / 2) / 8) * 8
      entity.x += offset
      entity.y -= offset
    end
  else
    -- rotating vertical -> horizontal
    if entity.height then
      entity.width = entity.height
      entity.height = nil
    end

    if pivot_mode == "centroid" then
      local offset = math.floor((entity.width / 2) / 8) * 8
      entity.y += offset
      entity.x -= offset
    end
  end

  return true
end

-- generic flip function for any spike direction
local function spike_flip(room, entity, horizontal, vertical)
  if horizontal then
    if entity._name == "spikesLeft" then
      entity._name = "spikesRight"
    elseif entity._name == "spikesRight" then
      entity._name = "spikesLeft"
    end
  end

  if vertical then
    if entity._name == "spikesUp" then
      entity._name = "spikesDown"
    elseif entity._name == "spikesDown" then
      entity._name = "spikesUp"
    end
  end

  return true
end

-- generic flip function for any trigger spike direction
local function trigger_spike_flip(room, entity, horizontal, vertical)
  if horizontal then
    if entity._name == "triggerSpikesLeft" then
      entity._name = "triggerSpikesRight"
    elseif entity._name == "triggerSpikesRight" then
      entity._name = "triggerSpikesLeft"
    end
  end

  if vertical then
    if entity._name == "triggerSpikesUp" then
      entity._name = "triggerSpikesDown"
    elseif entity._name == "triggerSpikesDown" then
      entity._name = "triggerSpikesUp"
    end
  end

  return true
end

---

--[[
  one-time patching rotation & flip functions, because applying the
  rotate/flip functions only worked when i did it this way for some reason
]]

if entities.___anotherLoennPlugin then
  entities.___anotherLoennPlugin.unload()
  entities.___anotherLoennPlugin = nil
end

local orig_rotateSelection = entities.rotateSelection
function entities.rotateSelection(room, layer, selection, direction)
  for _, name in ipairs(directions) do
    local handler = entities.registeredEntities[name]
    if not handler.rotate then
      handler.rotate = spike_rotate
    end
  end

  for _, name in ipairs(trigger_directions) do
    local handler = entities.registeredEntities[name]
    if not handler.rotate then
      handler.rotate = trigger_spike_rotate
    end
  end

  entities.rotateSelection = orig_rotateSelection
  return orig_rotateSelection(room, layer, selection, direction)
end

local orig_flipSelection = entities.flipSelection
function entities.flipSelection(room, layer, selection, horizontal, vertical)
  for _, name in ipairs(directions) do
    local handler = entities.registeredEntities[name]
    if not handler.flip then
      handler.flip = spike_flip
    end
  end

  for _, name in ipairs(trigger_directions) do
    local handler = entities.registeredEntities[name]
    if not handler.flip then
      handler.flip = trigger_spike_flip
    end
  end

  entities.flipSelection = orig_flipSelection
  return orig_flipSelection(room, layer, selection, horizontal, vertical)
end

entities.___anotherLoennPlugin = {
  unload = function()
    for _, name in ipairs(directions) do
      local handler = entities.registeredEntities[name]
      if handler.rotate == rotate then
        handler.rotate = nil
      end
      if handler.flip == flip then
        handler.flip = nil
      end
    end

    for _, name in ipairs(trigger_directions) do
      local handler = entities.registeredEntities[name]
      if handler.rotate == rotate then
        handler.rotate = nil
      end
      if handler.flip == flip then
        handler.flip = nil
      end
    end

    entities.rotateSelection = orig_rotateSelection
    entities.flipSelection = orig_flipSelection
  end
}

---

return {}
