local ui = require("ui")
local uie = require("ui.elements")
local uiu = require("ui.utils")
local listWidgets = require("ui.widgets.lists")
local widgetUtils = require("ui.widgets.utils")

local utils = require("utils")
local tasks = require("utils.tasks")

local mods = require("mods")
local languageRegistry = require("language_registry")
local configs = require("configs")
local atlases = require("atlases")

local windowPersister = require("ui.window_postition_persister")
local windowPersisterName = "alp_texture_browser"
local windowPersisterNameDialog = "alp_texture_browser_dialog"

local WINDOW_STATIC_HEIGHT = 600
local WINDOW_STATIC_WIDTH = math.round(WINDOW_STATIC_HEIGHT * 4 / 3)
local MAX_MOD_NAME_WIDTH = 200

---

local textureBrowser = {}

---

local textureCache = {}
local textureBrowserGroup = uie.group({})
local externalAtlasLoaded = false
local atlasLoadTask

---

local function loadExternalAtlasIfNecessary()
  if externalAtlasLoaded or atlasLoadTask then return end

  -- this asset will never be requested, so won't be lazyloaded
  -- hence, if it's in the atlas, the whole external atlas must have been loaded
  if rawget(atlases.gameplay, "util/microlith57/AnotherLoennPlugin/lazy_loading_detector") then
    externalAtlasLoaded = true
    return
  end

  atlasLoadTask = tasks.newTask(function()
    atlases.loadExternalAtlas("Gameplay")
    externalAtlasLoaded = true
    atlasLoadTask = nil
  end)
end

local function getTextureData()
  if #textureCache > 0 then
    return textureCache
  end

  local language = languageRegistry.getLanguage()

  local buf = {}

  for name, sprite in pairs(atlases.gameplay) do
    local firstchar = name:sub(1, 1)
    if type(sprite) == "table"
      and firstchar ~= "_"
      and firstchar ~= "@"
      and not (firstchar == 'b' and utils.startsWith(name, "bgs/microlith57/AnotherLoennPlugin"))
      then

      local mod = ""
      if not sprite.internalFile then
        mod = mods.formatAssociatedMods(language, sprite.associatedMods)
        mod = mod:sub(2, #mod - 1)
      end

      table.insert(buf, {name = name, sprite = sprite, mod = mod})

    end
  end

  table.sort(buf, function(a, b)
    return a.name < b.name
  end)

  for i, entry in ipairs(buf) do
    textureCache[i] = {
      index = i,
      name = entry.name, sprite = entry.sprite,
      mod = (entry.mod ~= '' and entry.mod or 'Celeste')
    }
  end

  return textureCache
end

---

local function makeSearchRow(data)
  local searchRow = uie.row {
    uie.field(
      "",
      function(text) data.callbacks.setSearch(text) end
    )
      :with { placeholder = "Search" }
      :with(uiu.fillWidth(true)),

    -- todo: make this a dropown menu with a list/grid toggle and a "collapse animations" toggle,
    -- todo:   the latter of which hides anything that ends in a string of numbers that aren't all 0
    -- todo:   (i guess by adding another requirement to the search)
    uie.dropdown(
      {"List", "Grid"},
      function(_, mode) data.callbacks.setViewMode(mode == "List" and "list" or "grid") end
    )
      :with { width = 60 }
      :with(uiu.rightbound)
  }
    :with(uiu.fillWidth)
    :with { style = { padding = 4 } }

  -- todo implement searching
  -- todo implement up/down arrows, esc, enter (see searchFieldKeyRelease)

  return searchRow
end

local function makeListRow(data)
  local children = {
    -- mod name
    uie.column {uie.label()}
      :with {
        style = { padding = 4 },
        width = MAX_MOD_NAME_WIDTH,
        clip = true
      },
    -- texture name
    uie.column {uie.label()}
      :with {
        style = { padding = 4 },
        clip = true
      },
    -- resolution
    uie.column {uie.label()}
      :with {
        style = { padding = 4 }
      }
      :with(uiu.rightbound),
  }

  local li = uie.listItem(children[1])
    :with(uiu.fillWidth)
    :with {
      style = {
        padding = 0,
        spacing = 0,
      },
    }
  li:addChild(children[2])
  li:addChild(children[3])

  uiu.hook(li, {
    layoutLate = function(orig, self)
      local widest = data.widest_modname_so_far
      self.children[1].width = widest
      self.children[2].realX = widest + 8
      self.children[2].width = WINDOW_STATIC_WIDTH - widest - 16 - self.children[3].width
      orig(self)
    end
  })

  return li
end

local function makeList(data)
  data.widest_modname_so_far = 0

  local list = uie.magicList(
    getTextureData(),
    function(_, d, elem)
      if not d then return elem or makeListRow(data) end
      if not elem then elem = makeListRow(data) end

      local width = d.sprite.realWidth or d.sprite.width or "?"
      local height = d.sprite.realHeight or d.sprite.height or "?"

      elem.children[1].children[1].text = d.mod
      elem.children[2].children[1].text = d.name
      elem.children[3].children[1].text = width .. "×" .. height

      local widest = data.widest_modname_so_far
      if widest < MAX_MOD_NAME_WIDTH then
        local mod_width = elem.children[1].children[1]:calcWidth()

        if mod_width > widest then
          widest = math.min(MAX_MOD_NAME_WIDTH, mod_width)
          data.widest_modname_so_far = widest

          if elem.owner then
            elem.owner.layoutLate()
          end
        end
      end
      elem.children[1].width = widest
      elem.children[2].realX = widest + 4

      elem.data = d
      return elem
    end,
    function(_, d)
      data.selected = d.index
      print(data.selected)
      _, res = utils.serialize(d, false)
      print(res)
    end
  )
    :with(uiu.fillWidth)

  if data.selected then
    -- listWidgets.setSelection(list, data.selected, true)
    list:setSelectedIndex(data.selected, false)
    -- todo: scroll to selected
    -- todo: make this still work with search
  end

  local scrolled = uie.scrollbox(list)
    :with(uiu.fillWidth)
    :with(uiu.fillHeight)

  return scrolled
end

local function makeGrid(data)
  return uie.magicList({})
end

local function makeMainRow(data)
  local mainRow = uie.row {
    (data.viewMode == "list") and makeList(data) or makeGrid(data)
  }:with {
    width = WINDOW_STATIC_WIDTH,
    height = WINDOW_STATIC_HEIGHT
  }

  function data.callbacks.setViewMode(mode)
    data.viewMode = mode

    mainRow:removeChild(mainRow.children[1])
    mainRow:addChild((data.viewMode == "list") and makeList(data) or makeGrid(data))
  end

  return mainRow
end

local function makeDialogRow(data)
  local dialogRow = uie.row {
    uie.button("OK", function() end)
      :with { enabled = false }
  }:with(uiu.fillWidth)
  :with {
    style = { padding = 4 }
  }

  return dialogRow
end

---

function textureBrowser.browseTextures(isDialog)
  local language = languageRegistry.getLanguage()
  local windowTitle = tostring(language.ui.anotherloennplugin.texture_browser_window.window_title)

  local persisterName = isDialog and windowPersisterNameDialog or windowPersisterName
  local windowCloseCallback = windowPersister.getWindowCloseCallback(persisterName)

  ---

  local data = {
    callbacks = {},
    viewMode = "list",
  }

  local mainRowPlaceholder = uie.row {
    uie.label("loading modded assets, this might take a while...")
  }
    :with {
    width = WINDOW_STATIC_WIDTH,
    height = WINDOW_STATIC_HEIGHT
  }

  local layout = uie.column {
    makeSearchRow(data),
    mainRowPlaceholder,
    (isDialog and makeDialogRow(data) or nil)
  }

  local function putMainRowInWindow()
    mainRowPlaceholder:removeSelf()

    local row = makeMainRow(data)
    layout:addChild(row, 2)
  end

  loadExternalAtlasIfNecessary()
  if externalAtlasLoaded then
    putMainRowInWindow()
  else
    atlasLoadTask.callback = putMainRowInWindow
  end

  local window = uie.window(windowTitle, layout)
  window:reflow()

  ---

  windowPersister.trackWindow(persisterName, window)
  textureBrowserGroup.parent:addChild(window)
  widgetUtils.addWindowCloseButton(window, windowCloseCallback)

  return window
end

-- group to get access to the main group and sanely inject windows in it
function textureBrowser.getWindow()
  local textureBrowserLib = mods.requireFromPlugin("libraries.texture_browser")
  textureBrowserLib.textureBrowserWindow = textureBrowser

  return textureBrowserGroup
end

return textureBrowser
