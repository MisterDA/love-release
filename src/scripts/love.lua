--- LÖVE file release.
-- @module scripts.love
-- @usage love(project)

local Script = require "love-release.script"

local s = {}


function s.script(project)
  local script = Script:new(project)
  script:createLoveFile()
end


setmetatable(s, { __call = function(_, project) return s.script(project) end })

return s
