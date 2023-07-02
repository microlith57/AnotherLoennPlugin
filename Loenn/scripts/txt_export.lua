local state = require("loaded_state")
local sideStruct = require("structs.side")

local utils = require("utils")
local filesystem = require("utils.filesystem")
local tasks = require("utils.tasks")

---

local script = {
  name = "txtExport",
  parameters = {
    pretty = false
  },
  displayName = ".txt export",
  tooltip = "Export the current map as a .txt file. The specific format is unique to Lönn.",
  tooltips = {
    pretty = "Whether to expand the format to be more readable. Increases filesize."
  }
}

function script.prerun(args)
  if not state.side then return false end

  -- tasks.newTask(
  --   function() return sideStruct.encodeTaskable(state.side) end,
  --   function(encodeTask)
  --     if encodeTask.success and encodeTask.result then
  --       print(#encodeTask.result.__children)

  --       local success, export = utils.serialize(encodeTask.result, args.pretty)
  --       if not success then return false end

  --       filesystem.saveDialog(state.filename, "txt", function(filename)
  --         local io_w = io.open(filename, "w")
  --         if not io_w then return false end

  --         io_w:write(export)
  --         io_w:close()

  --         return true
  --       end)
  --     end
  --   end
  -- )

  local success, export = utils.serialize(state.side, args.pretty)
  if not success then return false end

  filesystem.saveDialog(state.filename, "txt", function(filename)
    local io_w = io.open(filename, "w")
    if not io_w then return false end

    io_w:write(export)
    io_w:close()

    return true
  end)

  return true
end

---

return script