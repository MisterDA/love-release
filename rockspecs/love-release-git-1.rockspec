package = "love-release"
version = "git-1"
source = {
  url = "git://github.com/MisterDA/love-release",
  branch = "love-release-3",
}
description = {
  summary = "Make LÖVE games releases easier",
  detailed = [[
love-release make LÖVE games releases easier.
It automates LÖVE Game Distribution.
]],
  license = "MIT",
  homepage = "https://github.com/MisterDA/love-release",
}
dependencies = {
  "argparse ~> 0.5",
  "middleclass ~> 4",
}
build = {
  type = "builtin",
  modules = {
    ["love-release.task"] = "src/task.lua",
  },
  install = {
    bin = {
      ["love-release"] = "src/main.lua",
    },
  },
}
