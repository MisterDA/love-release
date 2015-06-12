function love.conf(t)
    t.identity = nil                   -- The name of the save directory (string)
                                       -- love-release requires [a-z0-9_] characters. Cannot begin with a number.
    t.version = "0.9.2"                -- The LÖVE version this game was made for (string)
    t.game_version = nil               -- The version of your game (string)
    t.icon = nil                       -- The path to the executable icons (string)
    t.console = false                  -- Attach a console (boolean, Windows only)
 
    t.title = "Untitled"               -- The name of the game (string)
    t.author = "Unnamed"               -- The name of the author (string)
    t.email = nil                      -- The email of the author (string)
    t.url = nil                        -- The website of the game (string)
    t.description = nil                -- The description of the game (string)
 
    -- OS to release your game on. Use a table if you want to overwrite the options, or just the OS name.
    -- Available OS are "love", "windows", "osx", "debian" and "android".
    -- A LÖVE file is created if none is specified.
    t.os = {
        "love",
        windows = {
            x86       = true,
            x64       = true,
            installer = false,
            appid     = nil,
        },
        "osx",
        "debian",
        "android",
    }
 
    -- t.window.*
    -- t.modules.*
end
