local configs = require("configs")
local tools = require("tools")
local selectionUtils = require("selections")

local selection = {}

function selection.getSelections()
  if configs.editor.toolActionButton == configs.editor.contextMenuButton then
    -- code we want is unreachable
    return
  end

  local selections

  local orig_getContextSelections = selectionUtils.getContextSelections
  function selectionUtils.getContextSelections(room, layer, x, y, sels)
    selections = sels
  end
  tools.currentTool.mouseclicked(-1024, -1024, configs.editor.contextMenuButton)
  selectionUtils.getContextSelections = orig_getContextSelections

  return selections
end

return selection
