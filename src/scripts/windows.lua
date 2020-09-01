--- Windows exe release.
-- @module scripts.windows
-- @usage windows(project)

local fs = require "luarocks.fs"
local zip = require "brimworks.zip"
local Script = require "love-release.script"
local utils = require "love-release.utils"
local ver = utils.love.ver

local s = {}


local function release(script, project, arch)
  local prefix, dir, bin
  if project.loveVersion == ver'11.2' or
  project.loveVersion == ver'11.1' then
    prefix = "love-"..tostring(project.loveVersion)
    dir = prefix..".0-win"..arch.."/"
    prefix = prefix.."-win"
    bin = prefix..arch..".zip"
  elseif project.loveVersion == ver'11.0' then
    prefix = "love-"..tostring(project.loveVersion)..".0-win"
    dir, bin = prefix..arch.."/", prefix..arch..".zip"
  elseif project.loveVersion <= ver'0.8.0' then
    prefix = "love-"..tostring(project.loveVersion).."-win"
    if arch == 32 then
      bin = prefix.."-x86.zip"
      dir = prefix.."-x86/"
    elseif arch == 64 then
      bin = prefix.."-x64.zip"
      dir = prefix.."-x64/"
    end
  else
    prefix = "love-"..tostring(project.loveVersion).."-win"
    dir, bin = prefix..arch.."/", prefix..arch..".zip"
  end
  local url = "https://github.com/love2d/love/releases/download/"..tostring(project.loveVersion).."/"..bin
  local cache = utils.cache.."/"..bin

  -- Can't cache the archive because luarocks functions use a HEAD
  -- request to Amazon AWS which will answer a 403.
  utils.download(url, cache, false)

  fs.delete(bin)
  assert(fs.copy(cache, bin))

  local gameHandle = assert(io.open(script.loveFile, "rb"))
  local game = gameHandle:read("*a")
  gameHandle:close()

  -- local ar = assert(zip.open(bin, zip.OR(zip.CHECKCONS)))
  local msg
  local ar, exeHandle, stat, exe
  ar, msg = zip.open(bin)
  if not ar then assert(ar, bin..": "..msg) end

  exeHandle, msg = ar:open(dir.."love.exe")
  if not exeHandle then assert(exeHandle, dir.."love.exe: "..msg) end
  stat, msg = ar:stat(dir.."love.exe")
  if not stat then assert(stat, dir.."love.exe: "..msg) end
  exe, msg = exeHandle:read(stat.size)
  if not exe then assert(exe, stat.size..": "..msg) end
  exeHandle:close()

  ar:add(dir..project.package..".exe", "string", exe..game)
  ar:delete(dir.."love.exe")
  ar:delete(dir.."lovec.exe")
  ar:delete(dir.."readme.txt")
  ar:delete(dir.."changes.txt")

  for i = 1, #ar do
    stat = ar:stat(i)
    if stat then
      ar:rename(i, stat.name:gsub(
                  "^"..utils.lua.escape_string_regex(dir),
                  project.title.."-win"..arch.."/"))
    end
  end

  ar:close()

  os.rename(bin, project.title.."-win"..arch..".zip")
end

function s.script(project, arch)
  local script = Script:new(project)
  script:createLoveFile()
  fs.change_dir(project.releaseDirectory)
  if arch == 32 then
    release(script, project, 32)
  end
  if arch == 64 and project.loveVersion >= ver'0.8.0' then
    release(script, project, 64)
  end
  fs.pop_dir()
end


setmetatable(s, { __call = function(_, project, arch) return s.script(project, arch) end })

return s
