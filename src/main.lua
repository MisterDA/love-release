--- love-release main.
-- @script love-release

local conf = require 'love-release.pipes.conf'
local env = require 'love-release.pipes.env'
local Project = require 'love-release.project'
local p = Project:new()
conf(env(p))

print(p)

local script
script = require 'love-release.scripts.love'
script(p)
script = require 'love-release.scripts.macosx'
script(p)
script = require 'love-release.scripts.windows'
script(p)
script = require 'love-release.scripts.debian'
script(p)
