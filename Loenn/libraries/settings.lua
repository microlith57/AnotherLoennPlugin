local mods = require("mods")
local utils = require("utils")
local v = require("utils.version_parser")
local config = require("utils.config")
local logging = require("logging")

local currentVersion = mods.requireFromPlugin("consts.version")

---

local alp_settings = {}
local settings = mods.getModSettings()

alp_settings.by_module = {}

if settings._config_version == "1.7.0" then
  -- i made an oopsy...
  logging.info("[AnotherLoennPlugin] retconning v1.7.0 to v1.6.1")
  settings._config_version = "1.6.1"
  config.writeConfig(settings)
end

local lastSavedWith = settings._config_version and v(settings._config_version) or v("0.0.0")

if currentVersion ~= v("0.0.0-dev") then
  if lastSavedWith > currentVersion then
    error(
      "[AnotherLoennPlugin] the plugin settings file was last saved with at least version " .. tostring(lastSavedWith) .. ", and isn't backwards compatible with " .. tostring(currentVersion) .. " (older)!"
    )
  end
end

local migratingTo = lastSavedWith
local function willUpdateConfigVersion(new)
  if migratingTo > currentVersion then
    error(
      "[AnotherLoennPlugin] trying to migrate to version " .. tostring(migratingTo) .. " but only on version " .. tostring(currentVersion) .. "; this should never happen!"
    )
  end
  if migratingTo < new then
    migratingTo = new
  end
end

---

local function loadSettings(module_settings, first_load)
  first_load = first_load or false
  if first_load then
    -- run all migrations associated with the module
    for _, migration in ipairs(module_settings.migrations or {}) do
      if migration.upto > lastSavedWith then
        migration.apply(settings, lastSavedWith)
        willUpdateConfigVersion(migration.upto)
      end
    end
  end

  -- load the module's settings
  local enabled = module_settings.load(settings, first_load)

  -- ensure any changes in either migrations or loading are committed
  config.writeConfig(settings)

  return enabled
end
-- load the root module's settings immediately
loadSettings(mods.requireFromPlugin("modules.root_settings"))

---

function alp_settings.loadModuleSettings(name, first_load)
  -- get the settings handler
  -- todo: silence warnings
  local module_settings = mods.requireFromPlugin("modules." .. name .. ".settings")

  -- ...or a default
  if not module_settings or type(module_settings) ~= "table" then
    module_settings = {}

    function module_settings.load(s)
      if not settings[name] then
        settings[name] = { _enabled = true }
      elseif settings[name]._enabled == nil then
        settings[name]._enabled = true
      end

      return settings[name]._enabled
    end
  end

  -- run migrations and load the settings
  local enabled = loadSettings(module_settings, first_load)

  alp_settings.by_module[name] = {
    enabled = enabled,
    settings = module_settings
  }

  return enabled, module_settings
end

function alp_settings.doneLoading()
  -- if any migrations were run, update the config version to the migrated-to version
  --
  -- any migration represents a break in backwards compatibility, so this means that the file won't be opened in
  -- plugin versions older than the most recent migration
  if migratingTo > lastSavedWith then
    logging.info("[AnotherLoennPlugin] migrations from " .. tostring(lastSavedWith) .. " to " .. tostring(migratingTo) .. " applied!")
    settings._config_version = tostring(migratingTo)
  end
end

function alp_settings.loadAll(modules)
  for _, m in ipairs(modules) do
    m.enabled, m.settings = alp_settings.loadModuleSettings(m.name, true)
  end
  alp_settings.doneLoading()
end

function alp_settings.reloadAll(modules)
  for _, m in ipairs(modules) do
    m.enabled, m.settings = alp_settings.loadModuleSettings(m.name, false)
  end
end

function alp_settings.get()
  return utils.deepcopy(settings)
end

function alp_settings.set(data)
  settings = utils.deepcopy(data)

  modules = mods.requireFromPlugin("libraries.modules")
  alp_settings.reloadAll(modules)
end

---

return alp_settings
