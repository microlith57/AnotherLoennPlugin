local ui = require("ui")
local uie = require("ui.elements")
local widgetUtils = require("ui.widgets.utils")

---

local tooltip = {}

local PREVIEW_MAX_WIDTH, PREVIEW_MAX_HEIGHT = 320 * 2, 180 * 2
local MAX_SCALE = 6

---

local tooltip_target

local function updateTooltip(orig, self, dt)
  orig(self, dt)

  local cursorX, cursorY = love.mouse.getPosition()
  local hovered = ui.hovering

  local data = hovered and hovered.anotherloennplugin_texture_browser_tooltip
  if hovered and data and #data == 4 then
    if tooltip_target ~= hovered then
      local sprite = data[1]

      if #self.image_row.children > 0 then
        self.image_row:removeChild(self.image_row.children[1])
      end
      local imageElem = uie.image(sprite.image, sprite.quad, sprite.layer)
      self.image_row:addChild(imageElem)
      imageElem:calcSize()
      imageElem:layout()

      local scale = MAX_SCALE
      local width, height = data.width, data.height
      while (width * scale) > PREVIEW_MAX_WIDTH or (height * scale) > PREVIEW_MAX_HEIGHT do
        if scale > 1 then
          scale -= 1
        else
          scale /= 2
        end
      end
      imageElem:setScale(scale)
      imageElem.parent.width = math.ceil(width * scale)
      imageElem.parent.height = math.ceil(height * scale)
      imageElem.x = -data.offsetX * scale
      imageElem.y = -data.offsetY * scale

      self.labels[1].text = data[2]
      self.labels[2].text = data[3]
      self.labels[3].text = data[4] .. " (viewing at ".. scale .."×)"

      self:layout()
      self:reflow()
    end

    tooltip_target = hovered
    widgetUtils.moveWindow(self, cursorX + 4, cursorY - self.height)
  else
    tooltip_target = nil
    widgetUtils.moveWindow(self, -1024, -1024, 0, false)
  end
end

function tooltip.makeTooltip()
  local image_row = uie.row {}
  local labels = {
    uie.label(""), uie.label(""), uie.label("")
  }

  tooltip.tooltip = uie.panel {
    uie.column {
      image_row,    -- image
      uie.row {labels[1]}, -- mod
      uie.row {labels[2]}, -- texture
      uie.row {labels[3]}  -- resolution, frames, etc
    }
  }
    :with {
      interactive = -2,
      updateHidden = true,
      image_row = image_row,
      labels = labels
    }
    :hook {
      update = updateTooltip
    }

  ui.root:addChild(tooltip.tooltip)
  return tooltip.tooltip
end

---

return tooltip