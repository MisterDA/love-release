--- Windows exe release.
-- @module scripts.windows
-- @usage windows(project)

local fs = require "luarocks.fs"
local zip = require "misterda.zip"
local Script = require "love-release.script"
local utils = require "love-release.utils"
local ver = utils.love.ver

local s = {}


local function release(script, project, arch)
  local prefix = "love-"..tostring(project.loveVersion).."-win"
  local dir, bin
  if project.loveVersion.major == 11 then
     bin = prefix..arch..".zip"
     prefix = "love-"..tostring(project.loveVersion)..".0-win"
     dir = prefix..arch.."/"
  elseif project.loveVersion >= ver'0.9.0' then
    bin = prefix..arch..".zip"
    dir = prefix..arch.."/"
  else
    if arch == 32 then
      bin = prefix.."-x86.zip"
      dir = prefix.."-x86/"
    elseif arch == 64 then
      bin = prefix.."-x64.zip"
      dir = prefix.."-x64/"
    end
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

  local gameHandle = assert(io.open(script.loveFile, "rb"))
  local game = gameHandle:read("*a")
  gameHandle:close()

  -- local ar = assert(zip.open(bin, zip.OR(zip.CHECKCONS)))
  local ar = zip.open(bin)

  local exeHandle = assert(ar:open(dir.."love.exe"))
  local exe = assert(exeHandle:read(assert(ar:stat(dir.."love.exe")).size))
  exeHandle:close()

  ar:add(dir..project.package..".exe", "string", exe..game)
  ar:delete(dir.."love.exe")

  local stat
  for i = 1, #ar do
    stat = ar:stat(i)
    if stat then
      ar:rename(i, stat.name:gsub(
          "^"..utils.lua.escape_string_regex(dir),
          utils.lua.escape_string_regex(project.title).."-win"..arch.."/"))
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


setmetatable(s, {
  __call = function(_, project, arch) return s.script(project, arch) end,
})

return s
