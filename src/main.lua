--- love-release main.
-- @script love-release

local argparse = require 'argparse'

local tasks = {
  "run",
}

local parser = argparse()
    :name "love-release"
    :description "Makes LÖVE games releases easier !"
    :epilog "For more info, see https://github.com/MisterDA/love-release"

parser:flag("--version", "Show love-release version and exit.")
      :target("show_version")

parser:command_target("task")

for _, name in ipairs(tasks) do
  local task = require('love-release.tasks.'..name)
  task.genCommand(parser, name)
  tasks[name] = task
end

local args = parser:parse()

if args.show_version then
  local show = require 'luarocks.show'
  local _, version = show.pick_installed_rock("love-release")
  io.write("love-release "..version.."\n")
  os.exit(0)
end

for _, name in ipairs(tasks) do
  if name == args.task then
    local task = tasks[name]:new()
    task:execute()
    os.exit(0)
  end
end

io.write("Could not find task '"..args.task.."'.")
os.exit(1)
