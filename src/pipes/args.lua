--- Gather informations from the CLI
-- @module args
-- @usage args(project)

local argparse = require 'argparse'
local class = require 'middleclass'
local utils = require 'love-release.utils'

local Args = class('Args')


Args.pre = true

Args.args = nil

function Args:initialize()
  self.pre = Args.pre

  local parser = argparse()
    :name "love-release"
    :description "Makes LÖVE games releases easier !"
    :epilog "For more info, see https://github.com/MisterDA/love-release"


  parser:argument("release", "Project release directory.")
        :args "?"
  parser:argument("source", "Project source directory.")
        :args "?"

  parser:flag("-D", "Debian package.")
        :target "debian"
  parser:flag("-M", "macOS application.")
        :target "macos"
  parser:option("-W", "Windows executable.")
        :target "windows"
        :args "0-1"
        :count "0-2"
        :argname "32|64"

  parser:option("-a --author", "Author full name. Required for Debian.")
  parser:flag("-b", "Compile new or updated files to LuaJIT bytecode.")
        :target("compile")
  parser:option("-d --desc", "Project description. Required for Debian.")
  parser:option("-e --email", "Author email. Required for Debian.")
  parser:option("-l --love", "LÖVE version to use.")
        :target("loveVersion")
  parser:option("-p --package", "Package and command name.")
  parser:option("-t --title", "Project title.")
  parser:option("-u --url", "Project homepage url. Required for Debian.")
  parser:option("--uti", "Project Uniform Type Identifier. Required for macOS.")
  parser:option("-v", "Project version. Required for Debian.")
        :target("version")
  parser:option("-x --exclude", "Exclude file patterns."):count("*")
        :target("excludeFileList")

  self.args = parser:parse()
end


function Args:__call(project)
  local args = self.args

  if self.pre then
    if args.source then project:setProjectDirectory(args.source) end
    if args.release then project:setReleaseDirectory(args.release) end
    self.pre = false
    return project
  end

  if args.author then project:setAuthor(args.author) end
  if args.compile then project:setCompile(true) end
  if args.desc then project:setDescription(args.desc) end
  if args.email then project:setEmail(args.email) end
  if args.loveVersion then
    args.loveVersion = utils.love.ver(args.loveVersion)
    assert(utils.love.isSupported(args.loveVersion),
           "ARGS: "..tostring(args.loveVersion).." is not supported.\n")
    project:setLoveVersion(args.loveVersion)
  end
  if args.package then project:setPackage(args.package) end
  if args.title then project:setTitle(args.title) end
  if args.url then project:setHomepage(args.url) end
  if args.uti then project:setIdentifier(args.uti) end
  if args.version then project:setVersion(args.version) end
  if #args.excludeFileList >= 1 then project:setExcludeFileList(args.excludeFileList) end

  if project.projectDirectory == project.releaseDirectory then
    project:setReleaseDirectory(project.releaseDirectory.."/releases")
  end

  print(project)

  local script
  script = require 'love-release.scripts.love'
  script(project)
  if args.macos then
    script = require 'love-release.scripts.macos'
    script(project)
  end
  if #args.windows > 0 then
    local win = args.windows
    local win32 = win[1][1] == "32" or (win[2] and win[2][1] == "32")
    local win64 = win[1][1] == "64" or (win[2] and win[2][1] == "64")
    if not win32 and not win64 then
      win32, win64 = true, true
    end
    script = require 'love-release.scripts.windows'
    if win32 then script(project, 32) end
    if win64 then script(project, 64) end
  end
  if args.debian then
    script = require 'love-release.scripts.debian'
    script(project)
  end

  return project
end


return Args
