local utils = require("utils")

---

local alp_utils = {}

---

-- returns thing[key] if thing is a table, or nil otherwise.
function alp_utils.try_index(thing, key)
  if type(thing) == "table" then
    return thing[key]
  end
end

-- dig into a table; eg dig(table, 1, 2, 3) is table[1][2][3], except that it returns nil instead of erroring if it
-- fails to index something.
function alp_utils.dig(table, ...)
  local path = {...}

  if #path == 0 then
    return table
  else
    local target = table

    for i=1, #path do
      target = alp_utils.try_index(target, path[i])
      if target == nil then return end
    end

    return target
  end
end

-- eg. dig(table, val, 1, 2, 3) means table[1][2][3] = val, except that it returns false instead of erroring
function alp_utils.dig_set(table, value, ...)
  local path = {...}

  local target = alp_utils.dig(settings, table.unpack(path, 1, #path - 1))
  if not target or type(target) ~= "table" then return false end

  target[path[#path]] = value
  return true
end

-- make sure that dig(table, ...) would return a table, creating tables as necessary.
-- this will not replace a non-table with a table; it returns (false, nil) if it hits such a value.
-- if it succeeded, it returns true and the result you'd get from dig(table, ...).
function alp_utils.mktable_p(table, ...)
  local path = {}

  if #path == 0 then
    return table
  else
    local target = table

    for i=1, #path do
      if target[path[i]] == nil then
        target[path[i]] = {}
      end

      local target = target[path[i]]
      if type(target) ~= table then
        return false, nil
      end
    end

    return true, target
  end
end

---

return alp_utils