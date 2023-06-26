local mods = require("mods")
local v = require("utils.version_parser")
local meta = require("meta")
local config = require("utils.config")
local utils = require("utils")

--[[
  this code stolen & modified from Lönn Extended by JaThePlayer, licensed under the MIT license
]]
---

local extSettings = {}

local supportedLoennVersion = v("0.7.1")
local currentLoennVersion = meta.version

function extSettings.getPersistence(settingName, default)
  local settings = mods.getModPersistence()
  if not settingName then
    return settings
  end

  local value = settings[settingName]
  if value == nil then
    value = default
    settings[settingName] = default
  end

  return value
end

function extSettings.savePersistence()
  config.writeConfig(extSettings.getPersistence(), true)
end

function extSettings.get(settingName, default, namespace)
  local settings = mods.getModSettings()
  if not settingName then
    return settings
  end

  local target = settings
  if namespace then
    local nm = settings[namespace]
    if not nm then
      settings[namespace] = {}
      nm = settings[namespace]
    end

    target = nm
  end

  local value = target[settingName]
  if value == nil then
    value = default
    target[settingName] = default
  end

  if namespace then
    settings[namespace] = utils.deepcopy(target) -- since configMt:__newindex uses ~= behind the scenes to determine whether to save or not, we need to copy the table to make it save
  end

  return value
end

function extSettings.set(settingName, to, namespace)
  local settings = mods.getModSettings()
  if not settingName then
    return settings
  end

  local target = settings
  if namespace then
    local nm = settings[namespace]
    if not nm then
      settings[namespace] = {}
      nm = settings[namespace]
    end

    target = nm
  end

  target[settingName] = to

  if namespace then
    settings[namespace] = utils.deepcopy(target) -- since configMt:__newindex uses ~= behind the scenes to determine whether to save or not, we need to copy the table to make it save
  end
end

function extSettings.enabled()
  return supportedLoennVersion == currentLoennVersion or currentLoennVersion == v("0.0.0-dev")
end

function extSettings.featureEnabled(namespace, default)
  if default == nil then
    default = true
  end
  return extSettings.enabled() and extSettings.get("_enabled", default, namespace)
end

---

return extSettings
