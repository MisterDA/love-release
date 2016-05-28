--- Provides utility functions and constants.
-- @module utils

local cfg = require 'luarocks.cfg'
local fs = require 'luarocks.fs'

local utils = {}


--[[ CACHE ]]--

--- Cache directory.
utils.cache = nil

do
  local cache
  if cfg.platforms.windows then
    local localappdata = os.getenv("LOCALAPPDATA")
    if not localappdata then
      -- for Windows versions below Vista
      localappdata = os.getenv("USERPROFILE").."/Local Settings/Application Data"
    end
    cache = localappdata.."/love-release"
  elseif cfg.platforms.unix then
    cache = cfg.home.."/.cache/love-release"
  else
    io.write("love-release could not find a cache directory.")
    os.exit(1)
  end
  assert(fs.make_dir(cache))
  utils.cache = cache
end


return utils
