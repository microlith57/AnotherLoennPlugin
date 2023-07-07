local v = require("utils.version_parser")

---

local handler = {}

handler.migrations = {
  {
    upto = v("2.0.0"),
    apply = function(settings)
      if settings.debugrc then
        settings.debugrc_host = settings.debugrc.host
        settings.debugrc_port = settings.debugrc.port

        if not settings.teleporter then
          settings.teleporter = {
            _enabled = (settings.debugrc._enabled and settings.debugrc.teleporter)
          }
        end
      end
      settings.debugrc = nil

      settings.small_room_resize = nil
      settings.spike_rotate_flip = nil
      settings.parallax_filepicker = nil
    end
  }
}

function handler.load(settings)
  handler.debugrc_host = settings.debugrc_host or "localhost"
  handler.debugrc_port = settings.debugrc_port or "auto"

  -- root module is always enabled
  return true
end

return handler