--- Gather informations from the LÖVE conf.lua file.
-- @module conf
-- @usage conf(project)

local fs = require 'luarocks.fs'
local loadconf = require 'loadconf'
local utils = require 'love-release.utils'
local ver = utils.love.ver

local pipe = {}

function pipe.pipe(project)
  local err = utils.io.err

  -- checks for a conf.lua file
  fs.change_dir(project.projectDirectory)
  if not fs.exists("conf.lua") then
    err("CONF: No conf.lua provided.\n")
    return project
  end
  local conf = assert(loadconf.parse_file("conf.lua"))
  fs.pop_dir()

  local function setString(key, value)
    if type(value) == "string" then
      project["set"..key](project, value)
    end
  end

  local function setTable(key, value)
    if type(value) == "table" then
      project["set"..key](project, value)
    end
  end

  local function setLoveVersion(v)
    if type(v) == "string" and v ~= "" then
      local version = ver(v)
      if not utils.love.isSupported(version) then
        local scriptLoveVersion = project.loveVersion
        err("CONF: Your LÖVE conf version ("..v
              .. ") is not supported by love-release ("..tostring(scriptLoveVersion)
              .. ").\n")
        if version > scriptLoveVersion then
          err("      You should update love-release.\n")
        elseif version < scriptLoveVersion then
          err("      You should update your project.\n")
        end
      end
      project:setLoveVersion(version)
    end
  end

  -- extract LÖVE standard fields
  setString("Title", conf.title)
  setString("Package", conf.package)
  setLoveVersion(conf.version)

  -- extract love-release fields
  local releases = conf.releases
  if type(releases) == "table" then
    setString("Title", releases.title)
    setString("Package", releases.package)
    setLoveVersion(releases.loveVersion)
    setString("Version", releases.version)
    setString("Author", releases.author)
    setString("Email", releases.email)
    setString("Description", releases.description)
    setString("Homepage", releases.homepage)
    setString("Identifier", releases.identifier)
    setString("ReleaseDirectory", releases.releaseDirectory)
    setTable("ExcludeFileList", releases.excludeFileList)
  end

  return project
end


setmetatable(pipe, { __call = function(_, project) return pipe.pipe(project) end })

return pipe
