--- Gather informations from the environment.
-- @module env
-- @usage env(project)

local fs = require 'luarocks.fs'
local utils = require 'love-release.utils'
local ver = utils.love.ver

local pipe = {}


--- Gets the version of the installed LÖVE.
-- @treturn ver LÖVE version.
-- @local
local function getSystemLoveVersion()
  local handle = io.popen('love --version')
  local result = handle:read("*a")
  handle:close()
  local version = result:match('%d+%.%d+%.%d+')
  if version then
    return ver(version)
  end
end

--- Gets the latest LÖVE version from the web.
-- @treturn ver LÖVE version.
-- @local
local function getWebLoveVersion()
  local releasesPath = utils.cache.."/releases.xml"

  local ok, err = fs.download("https://love2d.org/releases.xml",
                              releasesPath,
                              true)
  if ok then
    local releasesXml = io.open(releasesPath, "rb")
    local version = releasesXml:read("*a"):match("<title>(%d+%.%d+%.%d+)")
    releasesXml:close()
    return ver(version)
  else
    return nil, err
  end
end

--- Gets the latest LÖVE version from the script, the system and the web.
-- @tparam ver script script version.
-- @tparam ver system system version.
-- @tparam ver web web version.
-- @treturn ver the latest version.
-- @local
local function getLatestLoveVersion(script, system, web)
  local version = script
  if system and system >= script then
    version = system
  end
  if web and web > version then
    version = web
  end
  return version
end

function pipe.pipe(project)
  local err = utils.io.err

  -- checks for a main.lua file
  fs.change_dir(project.projectDirectory)
  if not fs.exists("main.lua") then
    err("ENV: No main.lua provided.\n")
    os.exit(1)
  end
  fs.pop_dir()

  -- title
  project:setTitle(project.projectDirectory:match("[^/]+$"))

  -- package
  project:setPackage(project.title:gsub("%W", "-"):lower())

  -- LÖVE version

  local systemLoveVersion = getSystemLoveVersion()
  local webLoveVersion = getWebLoveVersion()
  local scriptLoveVersion = utils.love.lastVersion
  local isSupported = utils.love.isSupported

  if systemLoveVersion and not isSupported(systemLoveVersion) then
    err("ENV: Your LÖVE installed version (" .. tostring(systemLoveVersion) ..
          ") is not supported by love-release (" .. tostring(scriptLoveVersion) ..
          ").\n")
    if systemLoveVersion > scriptLoveVersion then
      err("     You should update love-release.\n")
    elseif systemLoveVersion < scriptLoveVersion then
      err("     You should update LÖVE.\n")
    end
  end

  if webLoveVersion and not isSupported(webLoveVersion) then
    err("ENV: The upstream LÖVE version (" .. tostring(webLoveVersion) ..
          ") is not supported by love-release (" .. tostring(scriptLoveVersion) ..
          ").\n")
    err("     You should update love-release.\n")
  end

  project:setLoveVersion(getLatestLoveVersion(scriptLoveVersion,
                                              systemLoveVersion,
                                              webLoveVersion))

  return project
end


setmetatable(pipe, { __call = function(_, project) return pipe.pipe(project) end })

return pipe
