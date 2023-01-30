local script = {}

script.name = "fixLightbeams"
script.displayName = "Fix Ahorn-Bugged Lightbeams"

function script.run(room, args)
  for _, entity in ipairs(room.entities) do
    if entity._name == "lightbeam" then
      entity.nodes = nil
    end
  end
end

return script
