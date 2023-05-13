local mods = require("mods")
local matrix = require("utils.matrix")
local brushHelper = require("brushes")

local matrixMt = getmetatable(matrix.filled("0", 1, 1))

local logging = require("logging")
logging.warning("[AnotherLoennPlugin] ---")
logging.warning("[AnotherLoennPlugin] Brush mask enabled! This tampers with matrix set operations, so could cause side effects!")
logging.warning("[AnotherLoennPlugin] Any problems you experience should be reported to microlith57#4004, even if they appear to be unrelated.")
logging.warning("[AnotherLoennPlugin] Before reporting anything, first try moving the AnotherLoennPluginBrushMask plugin out of your Mods folder!")
logging.warning("[AnotherLoennPlugin] ---")

---

if brushHelper.___anotherLoennPluginBrushMask then
  brushHelper.___anotherLoennPluginBrushMask.unload()
  brushHelper.___anotherLoennPluginBrushMask = {}
end

local settings = mods.requireFromPlugin("libraries.settings", "AnotherLoennPlugin")
if not settings.enabled("brush_mask") then
  return {}
end

---

local brushMask = {
  allow_air = true,
  allow_ground = true
}

---

function brushMask.toggle_allow_air()
  brushMask.allow_air = not brushMask.allow_air
  brushMask.consider_hooking()
end

function brushMask.toggle_allow_ground()
  brushMask.allow_ground = not brushMask.allow_ground
  brushMask.consider_hooking()
end

---

local orig_matrix_set0 = matrixMt.__index.set0
local orig_matrix_set = matrixMt.__index.set

-- only allow replacing air
local function hook_matrix_set0_a(self, x, y, value)
  if x >= 0 and x < self._width and y >= 0 and y < self._height and self[x + y * self._width + 1] == "0" then
    self[x + y * self._width + 1] = value
  end
end
local function hook_matrix_set_a(self, x, y, value)
  if x >= 1 and x <= self._width and y >= 0 and y <= self._height and self[(x - 1) + (y - 1) * self._width + 1] == "0" then
    self[(x - 1) + (y - 1) * self._width + 1] = value
  end
end

-- only allow replacing ground
local function hook_matrix_set0_g(self, x, y, value)
  if x >= 0 and x < self._width and y >= 0 and y < self._height and self[x + y * self._width + 1] ~= "0" then
    self[x + y * self._width + 1] = value
  end
end
local function hook_matrix_set_g(self, x, y, value)
  if x >= 1 and x <= self._width and y >= 0 and y <= self._height and self[(x - 1) + (y - 1) * self._width + 1] ~= "0" then
    self[(x - 1) + (y - 1) * self._width + 1] = value
  end
end

-- don't replace anything (why would you want this?)
local function hook_matrix_set0_n(self, x, y, value)
end
local function hook_matrix_set_n(self, x, y, value)
end

local hook_matrix_set0 = orig_matrix_set0
local hook_matrix_set = orig_matrix_set

---

local orig_placeTile = brushHelper.placeTile
local function hook_placeTile(room, x, y, material, layer)
  if layer == "tilesFg" or layer == "tilesBg" then
    matrixMt.__index.set0 = hook_matrix_set0
    matrixMt.__index.set = hook_matrix_set

    orig_placeTile(room, x, y, material, layer)

    matrixMt.__index.set0 = orig_matrix_set0
    matrixMt.__index.set = orig_matrix_set
  else
    orig_placeTile(room, x, y, material, layer)
  end
end

---

function brushMask.consider_hooking()
  if not brushMask.allow_air and not brushMask.allow_ground then
    brushHelper.placeTile = hook_placeTile

    hook_matrix_set0 = hook_matrix_set0_n
    hook_matrix_set = hook_matrix_set_n
  elseif brushMask.allow_air and not brushMask.allow_ground then
    brushHelper.placeTile = hook_placeTile

    hook_matrix_set0 = hook_matrix_set0_a
    hook_matrix_set = hook_matrix_set_a
  elseif not brushMask.allow_air and brushMask.allow_ground then
    brushHelper.placeTile = hook_placeTile

    hook_matrix_set0 = hook_matrix_set0_g
    hook_matrix_set = hook_matrix_set_g
  else
    -- brushMask.allow_air and brushMask.allow_ground
    brushHelper.placeTile = orig_placeTile

    hook_matrix_set0 = orig_matrix_set0_g
    hook_matrix_set = orig_matrix_set_g
  end
end

---

local menubar = require("ui.menubar").menubar

local function checkbox(menu, lang, toggle, active)
  local item = $(menu):find(item -> item[1] == lang)
  if not item then
    item = {}
    table.insert(menu, item)
  end
  item[1] = lang
  item[2] = toggle
  item[3] = "checkbox"
  item[4] = active
end

local editMenu = $(menubar):find(menu -> menu[1] == "edit")[2]

checkbox(editMenu, "anotherloennplugin_brush_mask_allow_air",
         brushMask.toggle_allow_air,
         function() return brushMask.allow_air end)

checkbox(editMenu, "anotherloennplugin_brush_mask_allow_ground",
         brushMask.toggle_allow_ground,
         function() return brushMask.allow_ground end)

---

brushHelper.___anotherLoennPluginBrushMask = {
  unload = function()
    brushHelper.placeTile = orig_placeTile

    hook_matrix_set0 = orig_matrix_set0_g
    hook_matrix_set = orig_matrix_set_g

    brushHelper.allow_air = true
    brushHelper.allow_ground = true
  end
}

---

return brushMask
