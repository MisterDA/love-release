--- macOS app release.
-- @module scripts.macos
-- @usage macos(project)

local fs = require "luarocks.fs"
local zip = require "brimworks.zip"
local Script = require "love-release.script"
local utils = require "love-release.utils"
local ver = utils.love.ver

local s = {}


local function validate(project)
  local valid, err = true, utils.io.err
  if type(project.identifier) ~= "string" or project.identifier == "" then
    err("macOS: No identifier specified (--uti).\n")
    valid = false
  end
  if not valid then os.exit(1) end
  return project
end

function s.script(project)
  local script = Script:new(validate(project))
  script:createLoveFile()
  fs.change_dir(project.releaseDirectory)

  local prefix, bin
  if project.loveVersion > ver'11.0' then
    prefix = "love-"..tostring(project.loveVersion).."-macos"
    bin = prefix..".zip"
  elseif project.loveVersion == ver'11.0' then
    prefix = "love-"..tostring(project.loveVersion)..".0-macos"
    bin = prefix..".zip"
  elseif project.loveVersion == ver'0.10.0' then
    utils.io.err("macOS: No LÖVE 0.10.0 binary available.\n")
    os.exit(1)
  elseif project.loveVersion >= ver'0.9.0' then
    prefix = "love-"..tostring(project.loveVersion).."-macos"
    bin = prefix.."x-x64.zip"
  else
    prefix = "love-"..tostring(project.loveVersion).."-macos"
    bin = prefix.."x-ub.zip"
  end
  local url = "https://github.com/love2d/love/releases/download/"..tostring(project.loveVersion).."/"..bin
  local cache = utils.cache.."/"..bin

  -- Can't cache the archive because luarocks functions use a HEAD
  -- request to Amazon AWS which will answer a 403.
  utils.download(url, cache, false)

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

  os.rename(bin, project.title.."-macos.zip")

  fs.pop_dir()
end


setmetatable(s, { __call = function(_, project) return s.script(project) end })

return s
