--- Provides utility functions and constants.
-- @module utils

local cfg = require 'luarocks.cfg'
local fs = require 'luarocks.fs'
local semver = require 'semver'

local utils = {}


--[[ CACHE ]]--

--- Cache directory.
utils.cache = nil

do
  local cache
  if cfg.platforms.windows then
     cache = os.getenv("APPDATA")
  else
     cache = os.getenv("HOME").."/.cache"
  end
  cache = fs.absolute_name(cache.."/love-release")
  assert(fs.make_dir(cache))
  utils.cache = cache
end


--[[ LÖVE VERSION ]]--

utils.love = {}

--- All supported LÖVE versions.
-- @local
utils.love.versionTable = {
  semver'11.0.0',
  semver'0.10.2', semver'0.10.1', semver'0.10.0',
  semver'0.9.2', semver'0.9.1', semver'0.9.0',
  semver'0.8.0',
  semver'0.7.2', semver'0.7.1', semver'0.7.0',
  semver'0.6.2', semver'0.6.1', semver'0.6.0',
--[[
  semver'0.5.0',
  semver'0.4.0',
  semver'0.3.2', semver'0.3.1', semver'0.3.0',
  semver'0.2.1', semver'0.2.0',
  semver'0.1.1',
--]]
}

--- Last script LÖVE version.
function utils.love.lastVersion()
  return utils.love.versionTable[1]
end

--- First supported LÖVE version.
function utils.love.minVersion()
  return utils.love.versionTable[#utils.love.versionTable]
end

--- Checks if a LÖVE version exists and is supported.
-- @tparam semver version LÖVE version.
-- @treturn bool true is the version is supported.
function utils.love.isSupported(version)
  if version >= utils.love.minVersion()
      and version <= utils.love.lastVersion() then
    for _, v in ipairs(utils.love.versionTable) do
      if version == v then
        return true
      end
    end
  end
  return false
end

--[[ LUA ]]--

utils.lua = {}

--- Compiles a file to LuaJIT bytecode.
-- @string file file path.
-- @treturn string bytecode.
function utils.lua.bytecode(file)
  if package.loaded.jit then
    return string.dump(assert(loadfile(file)), true)
  else
    local handle = io.popen('luajit -b '..file..' -')
    local result = handle:read("*a")
    handle:close()
    return result
  end
end

--- Escapes a string to use as a regex.
-- @string string to escape.
function utils.lua.escape_string_regex(string)
  -- ^$()%.[]*+-?
  return string:gsub('%%', '%%%%'):gsub('^%^', '%%^'):gsub('%$$', '%%$')
                :gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.')
                :gsub('%[', '%%['):gsub('%]', '%%]'):gsub('%*', '%%*')
                :gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%?', '%%?')
end


--[[ IO ]]--

local stdout = io.output(io.stdout)
local stderr = io.output(io.stderr)
utils.io = {}

--- Prints a message to stdout.
-- @string string the message.
function utils.io.out(string)
  stdout:write(string)
end

--- Prints a message to stderr.
-- @string string the message.
function utils.io.err(string)
  stderr:write(string)
end


return utils
