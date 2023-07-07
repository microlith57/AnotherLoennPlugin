local modules = {
  -- { name = "coords_view" },
  { name = "keyboard_pan" },
  { name = "room_mover" },
  { name = "snap_to_grid" },
  { name = "styleground_preview" },
  { name = "teleporter" }
}

setmetatable(modules, {
  __index = function(self, index)
    if type(index) == 'string' then
      local res = $(self):find(function(i, m)
        return m.name == index
      end)
      return res
    end
  end
})

return modules
