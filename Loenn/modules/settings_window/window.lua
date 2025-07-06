local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local mods = require("mods")
local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local config = require("utils.config")
local tabbedWindow = require("ui.widgets.tabbed_window")
local themes = require("ui.themes")
local debugUtils = require("debug_utils")

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "anotherloennplugin_settings_window"

local settings = mods.requireFromPlugin("libraries.settings")

---

local settingsWindow = {}

local baseFieldInformation = {
  ["spacer"] = {
      fieldType = "spacer"
  },
}

local settingsWindowGroup = uiElements.group({}):with({
    editSettings = settingsWindow.editSettings
})

local function prepareFormData()
    return settings.get()
end

local function saveSettings(formFields)
    local newSettings = form.getFormData(formFields)
    local oldSettings = rawget(configs, "data")

    utils.mergeTables(oldSettings, newSettings)

    settings.set(newSettings)
end

local function prepareTabForm(language, tabData, fieldInformation, formData, buttons)
    local tab = {}
    local fieldNames = {}

    local titleParts = tabData.title:split(".")()
    local titleLanguage = utils.getPath(language, titleParts)
    local title = tostring(titleLanguage)

    local fieldGroups = tabData.groups
    local fieldOrder = tabData.fieldOrder

    for _, name in ipairs(fieldOrder or {}) do
        table.insert(fieldNames, name)
    end

    for _, group in ipairs(fieldGroups or {}) do
        -- Use title name as language path
        if group.title then
            local groupTitleParts = group.title:split(".")()
            local groupLanguageName = utils.getPath(language, groupTitleParts)

            group.title = tostring(groupLanguageName)
        end

        for _, name in ipairs(group.fieldOrder) do
            table.insert(fieldNames, name)
        end
    end

    for _, field in ipairs(fieldNames) do
        if not fieldInformation[field] then
            fieldInformation[field] = {}
        end

        local baseLanguage = language.settings
        local nameParts = form.getNameParts(field)
        local fieldLanguageKey = nameParts[#nameParts]

        -- Go down every part besides the last
        for i = 1, #nameParts - 1 do
            baseLanguage = baseLanguage[nameParts[i]]
        end

        local settingsAttributes = baseLanguage.attribute
        local settingsDescriptions = baseLanguage.description

        local displayName = tostring(settingsAttributes[fieldLanguageKey])
        local tooltipText = tostring(settingsDescriptions[fieldLanguageKey])

        local fieldDefault = utils.getPath(defaultConfigData, nameParts)

        if fieldDefault then
            local settingsWindowLanguage = language.ui.settings_window
            local defaultFormatString = tostring(settingsWindowLanguage.defaultTooltipFormat)

            if type(fieldDefault) == "boolean" then
                fieldDefault = fieldDefault and tostring(settingsWindowLanguage.defaultValueEnabled) or tostring(settingsWindowLanguage.defaultValueDisabled)
            end

            tooltipText = string.format(defaultFormatString, tooltipText, fieldDefault)
        end

        fieldInformation[field].displayName = displayName
        fieldInformation[field].tooltipText = tooltipText
    end

    local tabForm, tabFields = form.getForm(buttons, formData, {
        fields = fieldInformation,
        groups = fieldGroups,
        fieldOrder = fieldOrder,
        ignoreUnordered = true,
    })

    tab.title = title
    tab.content = tabForm
    tab.fields = tabFields
    tab.fieldNames = fieldNames

    return tab
end

function settingsWindow.editSettings()
    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.settings_window.window_title)

    local formData = prepareFormData()
    local fieldInformation = utils.deepcopy(defaultFieldInformation)

    local tabs = {}
    local allFields = {}

    local buttons = {
        {
            text = tostring(language.ui.settings_window.save_changes),
            formMustBeValid = true,
            callback = function()
                saveSettings(allFields)
            end
        }
    }

    for _, tabData in ipairs(defaultTabForms) do
        local tab = prepareTabForm(language, utils.deepcopy(tabData), fieldInformation, formData, buttons)

        table.insert(tabs, tab)
    end

    for _, tab in ipairs(tabs) do
        for _, field in ipairs(tab.fields) do
            table.insert(allFields, field)
        end
    end

    local window = tabbedWindow.createWindow(windowTitle, tabs)
    local windowCloseCallback = windowPersister.getWindowCloseCallback(windowPersisterName)

    windowPersister.trackWindow(windowPersisterName, window)
    settingsWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window, windowCloseCallback)
    widgetUtils.preventOutOfBoundsMovement(window)
    tabbedWindow.prepareScrollableWindow(window)
    form.addTitleChangeHandler(window, windowTitle, allFields)

    return window
end

return settingsWindow
