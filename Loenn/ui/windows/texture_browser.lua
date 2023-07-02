local ui = require("ui")
local uie = require("ui.elements")
local uiu = require("ui.utils")
local listWidgets = require("ui.widgets.lists")
local widgetUtils = require("ui.widgets.utils")

local utils = require("utils")
local tasks = require("utils.tasks")
local textSearching = require("utils.text_search")

local mods = require("mods")
local languageRegistry = require("language_registry")
local configs = require("configs")
local atlases = require("atlases")
local persistence = require("persistence")

local windowPersister = require("ui.window_postition_persister")
local windowPersisterName = "alp_texture_browser"
local windowPersisterNameDialog = "alp_texture_browser_dialog"

local SCROLLBOX_STATIC_HEIGHT = 600
local SCROLLBOX_STATIC_WIDTH = math.round(SCROLLBOX_STATIC_HEIGHT * 4 / 3)
local MAX_MOD_NAME_WIDTH = 200

local language = languageRegistry.getLanguage()

local RESOLUTION_SEP = "×"

---

local textureBrowser = {}

---

local textureListUnfiltered = {}
local textureBrowserGroup = uie.group({})
local externalAtlasLoaded = false
local atlasLoadTask

---

-- todo: if only showing vanilla assets, don't bother to call this (-> no loading screen)
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
  if #textureListUnfiltered > 0 then
    return textureListUnfiltered
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
      item.basename = basename
      item.frame = tonumber(frame_str)

      if current_anim_basename ~= basename then
        current_anim = {}
        current_anim_basename = basename
      end

      current_anim[item.frame] = item
      item.anim = current_anim
    end

    textureListUnfiltered[i] = item
  end

  return textureListUnfiltered
end

---

local function getScore(item, searchParts, caseSensitive, fuzzy)
  local totalScore = 0
  local hasMatch = false

  -- Always match with empty search
  if #searchParts == 0 then
    return math.huge
  end

  for _, part in ipairs(searchParts) do
    local mode = part.mode

    if mode == "name" then
      local search = part.text
      local text = item.name
      local score = textSearching.searchScore(text, search, caseSensitive, fuzzy)

      if score then
        totalScore = totalScore + score
        hasMatch = true
      end

    elseif mode == "modName" then
      -- If we have additional search text it should search for entries within the given mod
      local associatedMods = item.associatedMods
      local searchModName = part.text
      local search = part.additional
      local text = item.name

      if associatedMods then
        for _, modName in ipairs(associatedMods) do
          local modScore = textSearching.searchScore(modName, searchModName, caseSensitive, fuzzy)
          local score = textSearching.searchScore(text, search, caseSensitive, fuzzy)

          -- Only include the additional search if it matches
          if modScore and (score or #search == 0) then
            totalScore = totalScore + modScore + (score or 0)
            hasMatch = true
          end
        end
      end
    end
  end

  if hasMatch then
    return totalScore
  end
end

local function prepareSearch(search)
  local parts = {}
  local searchStringParts = search:split("|")()

  for _, searchPart in ipairs(searchStringParts) do
    if utils.startsWith(searchPart, "@") then
      -- First space or the end of the string, used to extract additional search terms
      local spaceIndex = utils.findCharacter(searchPart, " ") or #searchPart + 1

      table.insert(parts, {
        mode = "modName",
        text = string.sub(searchPart, 2, spaceIndex - 1),
        additional = string.sub(searchPart, spaceIndex + 1)
      })
    else
      table.insert(parts, {
        mode = "name",
        text = searchPart
      })
    end
  end

  -- Remove empty entries, just causes issues
  for i = #parts, 1, -1 do
    if #parts[i].text == 0 then
      table.remove(parts, i)
    end
  end

  return parts
end

---

local function makeSearchRow(data)
  local searchField = uie.field(
    data.searchText,
    function(el, new, old)
      data.searchText = new
      if data.callbacks.filterList then
        data.callbacks.filterList(new)
      end
    end
  )
    :with { placeholder = "Search", enabled = false }
    :with(uiu.fillWidth(true))

  data.searchField = searchField

  local searchRow = uie.row {
      searchField,

    -- todo: make this a dropown menu with a list/grid toggle and a "collapse animations" toggle,
    -- todo:   the latter of which hides anything that ends in a string of numbers that aren't all 0
    -- todo:   (i guess by adding another requirement to the search)
    -- todo: language-ify List & Grid
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

---

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
      self.children[2].width = SCROLLBOX_STATIC_WIDTH - widest - 16 - self.children[3].width
      orig(self)
    end
  })

  return li
end

local function addSearchFieldHooks(data, list, searchField)
  searchField:hook({
    onKeyRelease = function(orig, self, key, ...)
      local exitKey = configs.ui.searching.searchExitKey
      local exitClearKey = configs.ui.searching.searchExitAndClearKey

      local nextResultKey = configs.ui.searching.searchNextResultKey
      local previousResultKey = configs.ui.searching.searchPreviousResultKey

      if key == exitClearKey then
        if data.isDialog then
          -- todo: close dialog and accept
        else
          self:setText("")
          widgetUtils.focusMainEditor()
        end

      elseif key == exitKey then
        widgetUtils.focusMainEditor()

      elseif key == nextResultKey then
        if list.selectedIndex < #list.data then
            listWidgets.setSelection(list, list.selectedIndex + 1)
        end

      elseif key == previousResultKey then
        if list.selectedIndex > 1 then
            listWidgets.setSelection(list, list.selectedIndex - 1)
        end

      else
        orig(self, key, ...)
      end
    end
  })
end

local function makeList(data)
  data.widest_modname_so_far = 0

  local items = getTextureData()
  local searchField = data.searchField

  local list = uie.magicList(
    items,
    function(_, d, elem)
      if not elem then elem = makeListRow(data) end
      if not d then return elem end

      local width  = d.sprite.realWidth  or d.sprite.width  or "?"
      local height = d.sprite.realHeight or d.sprite.height or "?"

      elem.children[1].children[1].text = table.concat(d.associatedMods, ", ")
      elem.children[2].children[1].text = d.name
      elem.children[3].children[1].text = width .. RESOLUTION_SEP .. height

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
      data.selected = d
    end
  )
    :with(uiu.fillWidth)
    :with {
      searchField = searchField,
      options = {
        searchScore = getScore,
        searchRawItem = true,
        searchPreprocessor = prepareSearch
      },
      _magicList = true
    }
  searchField.enabled = true
  addSearchFieldHooks(data, list, searchField)

  listWidgets.updateItems(list, items, data.selected)

  function data.callbacks.filterList(text)
    listWidgets.updateItems(list, items, data.selected)

    if not data.isDialog then
      persistence["anotherloennplugin_texture_browser_search"] = text
    end
  end

  uiu.hook(list, {
    onKeyPress = function(orig, self, key)
      if not data.selected or not data.selected.name then return orig(self) end

      local hotkeyModifierHeld = false

      if love.system.getOS == "OS X" then
          hotkeyModifierHeld = love.keyboard.isDown("rgui", "lgui")
      else
          hotkeyModifierHeld = love.keyboard.isDown("rctrl", "lctrl")
      end

      if hotkeyModifierHeld and key == "c" then
        love.system.setClipboardText(data.selected.name)
      end

      return orig(self, key)
    end
  })

  local scrolled = uie.scrollbox(list)
    :with(uiu.fillWidth)
    :with(uiu.fillHeight)

  return scrolled
end

---

local function makeGrid(data)
  return uie.magicList({})
end

---

local function makeMainRow(data)
  local mainRow = uie.row {
    (data.viewMode == "list") and makeList(data) or makeGrid(data)
  }:with {
    width = SCROLLBOX_STATIC_WIDTH,
    height = SCROLLBOX_STATIC_HEIGHT
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

function textureBrowser.browseTextures(isDialog, initialSearch)
  local language = languageRegistry.getLanguage()
  local windowTitle = tostring(language.ui.anotherloennplugin.texture_browser_window.window_title)

  local persisterName = isDialog and windowPersisterNameDialog or windowPersisterName
  local windowCloseCallback = windowPersister.getWindowCloseCallback(persisterName)

  ---

  if not isDialog then
    initialSearch = persistence["anotherloennplugin_texture_browser_search"]
  end

  local data = {
    callbacks = {},
    viewMode = "list",
    searchText = initialSearch,
    isDialog = isDialog
  }

  -- loading text
  --
  -- this will only be visible the first time the window is opened, as the rest of the time it is replaced during
  -- the current frame
  local mainRowPlaceholder = uie.row {
    uie.label(tostring(language.ui.anotherloennplugin.texture_browser_window.loading_assets))
  }
    :with {
      width = SCROLLBOX_STATIC_WIDTH,
      height = SCROLLBOX_STATIC_HEIGHT
    }

  uiu.hook(mainRowPlaceholder.children[1], {
    layoutLate = function(orig, self)
      self.realX = math.floor((self.parent.width - self.width) / 2)
      self.realY = math.floor((self.parent.height - self.height) / 2)
      orig(self)
    end
  })

  -- main layout
  local layout = uie.column {
    makeSearchRow(data),
    mainRowPlaceholder,
    (isDialog and makeDialogRow(data) or nil)
  }

  local function replacePlaceholder()
    mainRowPlaceholder:removeSelf()

    local row = makeMainRow(data)
    layout:addChild(row, 2)
  end

  loadExternalAtlasIfNecessary()
  if externalAtlasLoaded then
    replacePlaceholder()
  else
    atlasLoadTask.callback = replacePlaceholder
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
