local utils = require("utils")
local has_req, req = utils.tryrequire("lib.luajit-request.luajit-request")

if not has_req then
  return
end

local yaml = require("lib.yaml")

---

local debugrc = {
  -- host = settings.get("host", "localhost", "debugrc"),
  -- port = tonumber(settings.get("port", "auto", "debugrc"))
  host = "localhost",
  port = nil
}

if not debugrc.port then
  -- todo: better port finder
  debugrc.port = 32270
end

function debugrc.base_url()
  return "http://" .. debugrc.host .. ":" .. debugrc.port
end

function debugrc.request(endpoint, query)
  local res = req.send(debugrc.base_url() .. endpoint, query)
  if res then
    return res.code == 200, res.body, res
  else
    return false, nil, nil
  end
end

---

return debugrc
