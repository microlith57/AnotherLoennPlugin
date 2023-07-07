local textureBrowser = {}

textureBrowser.textureBrowserWindow = nil

function textureBrowser.browseTextures(isDialog)
  -- coerce to bool
  isDialog = not (not isDialog)

  if textureBrowser.textureBrowserWindow then
    textureBrowser.textureBrowserWindow.browseTextures(isDialog)
  end
end

return textureBrowser
