--- A love-release script.
-- @classmod script

local fs = require 'luarocks.fs'
local class = require 'middleclass'
local lfs = require "lfs"
local zip = require 'brimworks.zip'
local utils = require 'love-release.utils'

local Script = class('Script')


--- Current project.
Script.project = nil

--- Name of the LÖVE file.
Script.loveFile = nil

local function validate(project)
  local valid, err = true, utils.io.err
  if type(project.title) ~= "string" or project.title == "" then
    err("SCRIPT: No title specified.\n")
    valid = false
  end
  if type(project.package) ~= "string" or project.package == "" then
    err("SCRIPT: No package specified.\n")
    valid = false
  end
  if not type(project.loveVersion) then
    err("SCRIPT: No LÖVE version specified.\n")
    valid = false
  end
  if not valid then os.exit(1) end
  return project
end

function Script:initialize(project)
  self.project = validate(project)
  self.loveFile = project.title..'.love'
end

--- Creates a LÖVE file in the release directory of the current project.
function Script:createLoveFile()
  local ar = assert(zip.open(self.project.releaseDirectory.."/"..self.loveFile,
                             zip.OR(zip.CREATE, zip.CHECKCONS)))

  assert(fs.change_dir(self.project.projectDirectory))

  local attributes, stat
  for _, file in ipairs(self.project:fileList()) do
    attributes = assert(lfs.attributes(file))
    stat = ar:stat(file)

    -- file is not present in the filesystem nor the archive
    if not attributes and not stat then
      utils.io.err("BUILD: "..file.." is not present in the file system.\n")
    -- file is not present in the archive
    elseif attributes and not stat then
      utils.io.out("Add "..file.."\n")
      if attributes.mode == "directory" then
        ar:add_dir(file)
      else
        if self.project.compile and file:match(".lua$") then
          ar:add(file, "string", utils.lua.bytecode(file))
        else
          ar:add(file, "file", file)
        end
      end
    -- file in the filesystem is more recent than in the archive
    elseif attributes and stat and attributes.modification > stat.mtime + 5 then
      if attributes.mode == "file" then
        utils.io.out("Update "..file.."\n")
        if self.project.compile and file:match(".lua$") then
          ar:replace(assert(ar:name_locate(file)), "string",
                     utils.lua.bytecode(file))
        else
          ar:replace(assert(ar:name_locate(file)), "file", file)
        end
      end
    end
  end

  for i = 1, #ar do
    local file = ar:stat(i).name
    -- file is present in the archive, but not in the filesystem
    if not lfs.attributes(file) then
      utils.io.out("Delete "..file.."\n")
      ar:delete(i)
    end
  end

  ar:close()
  assert(fs.pop_dir())
end

return Script
