--- Provides utility functions and constants.
-- @module utils

local cfg = require 'luarocks.core.cfg'
local fs = require 'luarocks.fs'
local dir = require 'luarocks.dir'

local utils = {}

assert(cfg.init())
fs.init()

--[[ CACHE ]]--

--- Cache directory.
utils.cache = nil

do
  local cache = dir.dir_name(cfg.local_cache) .. "/love-release"
  assert(fs.make_dir(cache))
  utils.cache = cache
end


--[[ LÖVE VERSION ]]--

utils.love = {}

local ver = {
  major = nil,
  minor = nil,
  patch = nil,
  str = nil
}
utils.love.ver = ver

function ver:new(str)
  local major, minor, patch = str:match("^(%d+)%.?(%d*)%.?(%d*)$")
  assert(type(major) == 'string',
         ("Could not extract version number(s) from %q"):format(str))
  local o = { major = tonumber(major),
              minor = tonumber(minor),
              patch = tonumber(patch),
              str = str }
  setmetatable(o, self)
  self.__index = self
  return o
end

function ver:__eq(other)
  return self.major == other.major and self.minor == other.minor and
    self.patch == other.patch
end

function ver:__lt(other)
  if self.major ~= other.major then return self.major < other.major end
  if self.minor ~= other.minor then return self.minor < other.minor end
  if self.patch ~= other.patch then return self.patch < other.patch end
  return false
end

function ver:__tostring()
  local buffer = { ("%d.%d"):format(self.major, self.minor) }
  if self.patch then table.insert(buffer, "." .. self.patch) end
  return table.concat(buffer)
end

setmetatable(ver, { __call = ver.new })

--- All supported LÖVE versions.
-- @local
utils.love.versionTable = {
  ver'11.5', ver'11.4', ver'11.3', ver'11.2', ver'11.1', ver'11.0',
  ver'0.10.2', ver'0.10.1', ver'0.10.0',
  ver'0.9.2', ver'0.9.1', ver'0.9.0',
  ver'0.8.0',
  ver'0.7.2', ver'0.7.1', ver'0.7.0',
  ver'0.6.2', ver'0.6.1', ver'0.6.0',
--[[
  ver'0.5.0',
  ver'0.4.0',
  ver'0.3.2', ver'0.3.1', ver'0.3.0',
  ver'0.2.1', ver'0.2.0',
  ver'0.1.1',
--]]
}

--- Last script LÖVE version.
utils.love.lastVersion = utils.love.versionTable[1]

--- First supported LÖVE version.
utils.love.minVersion = utils.love.versionTable[#utils.love.versionTable]

--- Checks if a LÖVE version exists and is supported.
-- @tparam ver version LÖVE version.
-- @treturn bool true is the version is supported.
function utils.love.isSupported(version)
  assert(getmetatable(version) == ver)
  if version >= utils.love.minVersion
  and version <= utils.love.lastVersion then
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
  return string:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?%z]', {
                       ['^'] = '%^'; ['$'] = '%$'; ['('] = '%(';
                       [')'] = '%)'; ['%'] = '%%'; ['.'] = '%.';
                       ['['] = '%['; [']'] = '%]'; ['*'] = '%*';
                       ['+'] = '%+'; ['-'] = '%-'; ['?'] = '%?';
                       ['\0'] = '%z';
  })
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


--[[ DOWNLOAD ]]--

--- Downloads and optionally caches a file. Will assert on download
-- failure.
-- @string url the document to download
-- @string dest where to write it
-- @bool cacheable cache it or not
function utils.download(url, dest, cacheable)
  if not fs.exists(dest) then
    local ok, msg = fs.download(url, dest, cacheable)
    if not ok then
      utils.io.err("Tried to download "..url.." to "..dest.."\n")
      assert(ok, msg)
    end
  end
end


return utils
