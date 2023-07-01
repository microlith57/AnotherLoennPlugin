local ui = require("ui")
local uie = require("ui.elements")
local uiu = require("ui.utils")
local listWidgets = require("ui.widgets.lists")
local widgetUtils = require("ui.widgets.utils")

local mods = require("mods")
local utils = require("utils")
local languageRegistry = require("language_registry")
local configs = require("configs")
local atlases = require("atlases")

local windowPersister = require("ui.window_postition_persister")
local windowPersisterName = "alp_texture_browser"
local windowPersisterNameDialog = "alp_texture_browser_dialog"

local WINDOW_STATIC_HEIGHT = 640

---

local textureBrowser = {}

---

local textureCache = {}
local textureBrowserGroup = uie.group({})

---

local function getTextureData()
  if #textureCache > 0 then
    return textureCache
  end

  for name, sprite in pairs(atlases.gameplay) do
    if type(sprite) == "table" and sprite.internalFile then
      table.insert(textureCache, {
        index = (#textureCache + 1),
        name = name, sprite = sprite
      })
    end
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

local function makeList(data)
  local list = uie.magicList(
    getTextureData(),
    function(_, d, elem)
      if not elem then
        elem = uie.listItem()
      end
      elem.data = d

      if not elem.label then
        elem.label = uie.row { uie.label( --[[ -- todo -- ]] ) }
      end

      return elem
    end,
    function(_, d)
      data.selected = d.index
      print(data.selected)
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
    width = math.round(WINDOW_STATIC_HEIGHT * (4/3)),
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
  if not atlases.gameplay then
    return
  end

  local language = languageRegistry.getLanguage()
  local windowTitle = tostring(language.ui.anotherloennplugin.texture_browser_window.window_title)

  local persisterName = isDialog and windowPersisterNameDialog or windowPersisterName
  local windowCloseCallback = windowPersister.getWindowCloseCallback(persisterName)

  ---

  local data = {
    callbacks = {},
    viewMode = "list",
  }

  local layout = uie.column {
    makeSearchRow(data),
    makeMainRow(data),
    (isDialog and makeDialogRow(data) or nil)
  }

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
