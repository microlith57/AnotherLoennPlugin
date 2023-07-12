local mods = require("mods")
local v = require("utils.version_parser")
local config = require("utils.config")
local logging = require("logging")

local currentVersion = mods.requireFromPlugin("consts.version")
local alp_utils = mods.requireFromPlugin("libraries.utils")

---

local alp_settings = {}
local settings = mods.getModSettings()

local lastSavedWith = settings._config_version and v(settings._config_version) or v("0.0.0")
if currentVersion ~= v("0.0.0-dev") then
  if lastSavedWith > currentVersion then
    error(
      "[AnotherLoennPlugin] the plugin settings file was last saved with a newer version, and isn't backwards compatible with this one!"
    )
  end
end

local migratingTo = lastSavedWith
local function willUpdateConfigVersion(new)
  if migratingTo < new then
    migratingTo = new
  end
end

---

local function loadSettings(module_settings)
  -- run all migrations associated with the module
  for _, migration in ipairs(module_settings.migrations or {}) do
    if migration.upto > lastSavedWith then
      migration.apply(settings, lastSavedWith)
      willUpdateConfigVersion(migration.upto)
    end
  end

  -- load the module's settings
  local enabled = module_settings.load(settings)

  -- ensure any changes in either migrations or loading are committed
  config.writeConfig(settings)

  return enabled
end
-- load the root module's settings immediately
loadSettings(mods.requireFromPlugin("modules.root_settings"))

---

function alp_settings.loadModuleSettings(name)
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
  local enabled = loadSettings(module_settings)
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

---

return alp_settings
