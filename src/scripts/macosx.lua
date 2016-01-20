--- MacOS X app release.
-- @module scripts.macosx
-- @usage macosx(project)

local fs = require "luarocks.fs"
local semver = require "semver"
local zip = require "brimworks.zip"
local Script = require "love-release.script"
local utils = require "love-release.utils"

local s = {}


local function validate(project)
  local valid, err = true, utils.io.err
  if type(project.identifier) ~= "string" or project.identifier == "" then
    err("DEBIAN: No author specified.\n")
    valid = false
  end
  if not valid then os.exit(1) end
  return project
end

function s.script(project)
  local script = Script:new(validate(project))
  script:createLoveFile()
  fs.change_dir(project.releaseDirectory)

  local prefix = "love-"..tostring(project.loveVersion).."-macosx-"
  local bin
  if project.loveVersion >= semver'0.9.0' then
    bin = prefix.."x64.zip"
  else
    bin = prefix.."ub.zip"
  end
  local url = "https://bitbucket.org/rude/love/downloads/"..bin
  local cache = utils.cache.."/"..bin

  -- Can't cache the archive because luarocks functions use a HEAD request to
  -- Amazon AWS which will answer a 403.
  -- assert(fs.download(url, cache, true))
  if not fs.exists(cache) then
    assert(fs.download(url, cache))
  end

  fs.delete(bin)
  assert(fs.copy(cache, bin))

  -- local ar = assert(zip.open(bin, zip.OR(zip.CHECKCONS)))
  local ar = zip.open(bin)

  local infoPlistIndex = assert(ar:name_locate("love.app/Contents/Info.plist"))
  local infoPlistSize = assert(ar:stat(infoPlistIndex).size)
  local infoPlistHandle = assert(ar:open(infoPlistIndex))
  local infoPlist = assert(infoPlistHandle:read(infoPlistSize))
  infoPlistHandle:close()
  infoPlist = infoPlist
      :gsub("\n\t<key>UTExportedTypeDeclarations</key>.*</array>",
            "")
      :gsub("(CFBundleIdentifier.-<string>)(.-)(</string>)",
         "%1"..project.identifier.."%3")
      :gsub("(CFBundleName.-<string>)(.-)(</string>)",
            "%1"..project.title..".love%3")

  ar:add("love.app/Contents/Resources/"..script.loveFile,
         "file", script.loveFile)

  local app = project.title..".app"
  for i = 1, #ar do
    ar:rename(i, ar:stat(i).name:gsub("^love%.app", app))
  end

  ar:close()

  -- for unknown reason, replacing the Info.plist content earlier would cause
  -- random crashes
  ar = zip.open(bin)
  assert(ar:replace(infoPlistIndex, "string", infoPlist))
  ar:close()

  os.rename(bin, project.title.."-macosx.zip")

  fs.pop_dir()
end


setmetatable(s, {
  __call = function(_, project) return s.script(project) end,
})

return s
