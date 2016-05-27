--- Run a LÖVE project.
-- @classmod RunTask

local Task = require 'love-release.task'
local cfg = require 'luarocks.cfg'
local fs = require 'luarocks.fs'
local class = require 'middleclass'

local RunTask = class('RunTask', Task)

function RunTask.static.genCommand(parser, name)
  return Task.genCommand(parser, name)
    :description("Runs this project.")
end

function RunTask:initialize()
  Task.initialize(self, "run")
end

function RunTask:execute()
  Task.execute(self)
  local exit
  local available, msg = fs.is_tool_available("love", "LÖVE")
  if cfg.platforms.unix then
    if available then
      exit = fs.execute("love", ".")
    elseif cfg.platforms.macosx then
      exit = fs.execute("/Applications/love.app/Contents/MacOS/love", ".")
    end
  elseif cfg.platforms.windows then
    if available then
      exit = fs.execute("love", ".")
    elseif fs.exists(os.getenv("PROGRAMFILES").."\\LOVE\\love.exe") then
      exit = fs.execute(os.getenv("PROGRAMFILES").."\\LOVE\\love.exe", ".")
    elseif fs.exists(os.getenv("PROGRAMFILES(x86)").."\\LOVE\\love.exe") then
      exit = fs.execute(os.getenv("PROGRAMFILES(x86)").."\\LOVE\\love.exe", ".")
    end
  elseif not available then
    io.write(msg)
    os.exit(1)
  end
  if not exit then
    io.write("Failed to run LÖVE.")
  end
end

return RunTask
