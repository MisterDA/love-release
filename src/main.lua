--- love-release main.
-- @script love-release

local Args = require 'love-release.pipes.args'
local conf = require 'love-release.pipes.conf'
local env = require 'love-release.pipes.env'
local Project = require 'love-release.project'

local p = Project:new()
local args = Args:new()
args(conf(env(args(p))))

return 0
