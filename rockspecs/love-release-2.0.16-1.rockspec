package = "love-release"
version = "2.0.16-1"
rockspec_format = "3.0"
source = {
  url = "git://github.com/MisterDA/love-release.git",
  tag = "v2.0.16",
}
description = {
  summary = "Make LÖVE games releases easier",
  detailed = [[
love-release makes LÖVE games releases easier.
It automates LÖVE Game Distribution.
]],
  license = "MIT",
  homepage = "https://github.com/MisterDA/love-release",
}
dependencies = {
  "argparse",
  "loadconf >= 0.3.6",
  "lua",
  "luafilesystem",
  "lua-zip",
  "middleclass",
}
build = {
  type = "builtin",
  modules = {
    ["love-release.scripts.debian"] = "src/scripts/debian.lua",
    ["love-release.scripts.love"] = "src/scripts/love.lua",
    ["love-release.scripts.macos"] = "src/scripts/macos.lua",
    ["love-release.scripts.windows"] = "src/scripts/windows.lua",
    ["love-release.pipes.args"] = "src/pipes/args.lua",
    ["love-release.pipes.conf"] = "src/pipes/conf.lua",
    ["love-release.pipes.env"] = "src/pipes/env.lua",
    ["love-release.project"] = "src/project.lua",
    ["love-release.script"] = "src/script.lua",
    ["love-release.utils"] = "src/utils.lua",
  },
  install = {
    bin = {
      ["love-release"] = "src/main.lua"
    },
  },
}
