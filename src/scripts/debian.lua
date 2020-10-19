--- Debian package release.
-- @module scripts.debian
-- @usage debian(project)

local fs = require 'luarocks.fs'
local dir = require 'luarocks.dir'
local lfs = require 'lfs'
local Script = require 'love-release.script'
local utils = require 'love-release.utils'

local s = {}


local function validate(project)
  local valid, err = true, utils.io.err
  if type(project.author) ~= "string" or project.author == "" then
    err("DEBIAN: No author specified (--author).\n")
    valid = false
  end
  if type(project.description) ~= "string" or project.description == "" then
    err("DEBIAN: No description specified (--desc).\n")
    valid = false
  end
  if type(project.email) ~= "string" or project.email == "" then
    err("DEBIAN: No email specified (--email).\n")
    valid = false
  end
  if type(project.homepage) ~= "string" or project.homepage == "" then
    err("DEBIAN: No homepage specified (--url).\n")
    valid = false
  end
  if type(project.version) ~= "string" or project.version == "" then
    err("DEBIAN: No version specified (-v).\n")
    valid = false
  end
  if not valid then os.exit(1) end
  return project
end

-- Is it such a good design to load the Debian package into memory with
-- temporary files ?
function s.script(project)
  local ok1, err1 = fs.is_tool_available("fakeroot", "fakeroot", "-v")
  local ok2, err2 = fs.is_tool_available("dpkg-deb", "dpkg-deb")
  if not ok1 or not ok2 then
    if not ok1 then utils.io.err(err1) end
    if not ok2 then utils.io.err(err2) end
    os.exit(1)
  end

  local script = Script:new(validate(project))
  script:createLoveFile()

  local tempDir = assert(fs.make_temp_dir("debian"))
  local loveFileDeb = "/usr/share/games/"..project.package.."/"..script.loveFile
  local loveFileRel = project.releaseDirectory.."/"..script.loveFile
  local md5sums = {}

  local function writeFile(path, content, md5)
    local fullPath = tempDir..path
    assert(fs.make_dir(dir.dir_name(fullPath)))
    local file = assert(io.open(fullPath, "wb"))
    file:write(content)
    file:close()

    if md5 then
      md5sums[#md5sums+1] = { path = path, md5 = assert(fs.get_md5(fullPath)) }
    end
  end

  local function copyFile(orig, dest, md5)
    local fullPath = tempDir..dest
    assert(fs.make_dir(dir.dir_name(fullPath)))
    assert(fs.copy(orig, fullPath))

    if md5 then
      md5sums[#md5sums+1] = { path = dest, md5 = assert(fs.get_md5(fullPath)) }
    end
  end

  -- /DEBIAN/control
  writeFile("/DEBIAN/control",
            "Package: "..project.package.."\n"..
              "Version: "..project.version.."\n"..
              "Architecture: all\n"..
              "Maintainer: "..project.author.." <"..project.email..">\n"..
              "Installed-Size: "..
              math.floor(assert(lfs.attributes(loveFileRel, "size")) / 1024).."\n"..
              "Depends: love (>= "..tostring(project.loveVersion)..")\n"..
              "Priority: extra\n"..
              "Homepage: "..project.homepage.."\n"..
              "Description: "..project.description.."\n"
  )

  -- /usr/share/applications/${PACKAGE}.desktop
  writeFile("/usr/share/applications/"..project.package..".desktop",
            "[Desktop Entry]\n"..
              "Name="..project.title.."\n"..
              "Comment="..project.description.."\n"..
              "Exec="..project.package.."\n"..
              "Type=Application\n"..
              "Categories=Game;\n",
            true
  )

  -- /usr/bin/${PACKAGE}
  writeFile("/usr/bin/"..project.package,
            "#!/bin/sh\n"..
              "love '"..loveFileDeb:gsub("'", "\\'").."'\n",
            true
  )
  -- FIXME: escape this path?
  assert(fs.set_permissions(tempDir.."/usr/bin/"..project.package,
                            "exec", "all")) -- 755

  -- /usr/share/games/${PACKAGE}/${LOVE_FILE}
  copyFile(project.releaseDirectory.."/"..script.loveFile, loveFileDeb, true)

  -- /DEBIAN/md5sums
  local sum = ""
  for _, v in ipairs(md5sums) do
    sum = sum..v.md5.."  "..v.path.."\n"
  end
  writeFile("/DEBIAN/md5sums", sum)

  -- create the package
  local deb = project.releaseDirectory.."/"..project.package.."-"..
    project.version.."_all.deb"
  fs.delete(deb)
  assert(fs.execute("fakeroot dpkg-deb -b ", tempDir, deb),
         "DEBIAN: error while building the package.")

  fs.delete(tempDir)
end


setmetatable(s, { __call = function(_, project) return s.script(project) end })

return s
