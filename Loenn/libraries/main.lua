local mods = require("mods")
local meta = require("meta")
local logging = require("logging")
local v = require("utils.version_parser")
local tasks = require("utils.tasks")

local currentLoennVersion = meta.version
local supportedLoennVersion = mods.requireFromPlugin("consts.loenn_version")
local currentVersion = mods.requireFromPlugin("consts.version")

---

-- version check
--
-- can be bypassed by either a using development version of lönn,
-- or using a development version of this plugin,
-- or by editing the consts/loenn_version.lua file
--
-- doing any of these is at your own risk
if supportedLoennVersion ~= currentLoennVersion
  and currentLoennVersion ~= v("0.0.0-dev")
  and currentVersion ~= v("0.0.0-dev") then

  logging.error("[AnotherLoennPlugin] refusing to load; expected loenn " .. tostring(supportedLoennVersion) .. " but got " .. tostring(currentLoennVersion))
  return {}
end

logging.info("[AnotherLoennPlugin] plugin version " .. tostring(currentVersion))

---

local modules = mods.requireFromPlugin("libraries.modules")

-- load settings
local settings = mods.requireFromPlugin("libraries.settings")
for _, m in ipairs(modules) do
  m.enabled, m.settings = settings.loadModuleSettings(m.name)
end
settings.doneLoading()

-- load enabled modules
for _, m in ipairs(modules) do
  if m.enabled then
    logging.info("[AnotherLoennPlugin] loading module " .. m.name)
    local res = mods.requireFromPlugin("modules." .. m.name .. ".main")
    if res then
      m.module = res
    end
  end
end

---

local initialised = false

local sceneHandler = require("scene_handler")
local orig_sceneHandler_changeScene = sceneHandler.changeScene

local function init_all()
  if not initialised then
    for _, m in ipairs(modules) do
      if m.enabled and m.module and m.module.init then
        logging.info("[AnotherLoennPlugin] initialising module " .. m.name)
        m.module.init()
      end
    end
  end
  initialised = true
  sceneHandler.changeScene = orig_sceneHandler_changeScene
end

function sceneHandler.changeScene(name)
  local res = orig_sceneHandler_changeScene(name)

  if res and name == "Editor" then
    init_all()
  end

  return res
end

tasks.newTask(function()
  while not initialised and sceneHandler.currentScene ~= "Editor" do
    tasks.delayProcessing()
  end
  init_all()
end)

if sceneHandler.currentScene == "Editor" then
  init_all()
end

---

return {}