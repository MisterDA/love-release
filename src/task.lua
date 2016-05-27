--- Provides an abstract class for tasks.
-- @classmod Task

local class = require 'middleclass'

local Task = class('Task')

--- Generates the command used by argparse.
-- @param parser the argparse parser
-- @string name the name of this task
-- @return the command
function Task.static.genCommand(parser, name)
  return parser:command(name)
end

--- Initializes this task.
-- @string name the name of this task
-- @param dependencies the list of this task's dependencies
function Task:initialize(name, dependencies)
  self.name = name
  self.dependencies = dependencies or {}
end

--- Executes this task.
-- Subclasses *must* call this function first when reimplementing it as it will execute this task's
-- dependencies.
function Task:execute()
  for dep in ipairs(self.dependencies) do
    dep:execute()
  end
end

--- Gets the name of this task.
-- @return its name
function Task:getName()
  print(self)
  return self.name
end

--- Gets the dependencies of this task.
-- @return its list of dependencies
function Task:getDependencies()
  return self.dependencies
end

return Task
