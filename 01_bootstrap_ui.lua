--=============================================================
-- BLOCK 1) BOOTSTRAP / UI (Rayfield + Window + Tabs)
--=============================================================
local Rayfield     = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window       = Rayfield:CreateWindow({
    Name                   = "Astral HUB - Ver 1.0.5",
    Icon                   = 0,
    LoadingTitle           = "Rayfield Interface Suite",
    LoadingSubtitle        = "by AczTeam",
    ShowText               = "Rayfield",
    Theme                  = "Default",
    ToggleUIKeybind        = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,

    ConfigurationSaving    = {
        Enabled    = true,
        FolderName = "AstralHub",
        FileName   = "AstralHub"
    },

    Discord                = {
        Enabled       = false,
        Invite        = "noinvitelink",
        RememberJoins = true
    },

    KeySystem              = true,
    KeySettings            = {
        Title           = "Untitled",
        Subtitle        = "Key System",
        Note            = "No method of obtaining the key is provided",
        FileName        = "AstralHubKey",
        SaveKey         = true,
        GrabKeyFromSite = false,
        Key             = { "Hello" }
    }
})

-- Tabs (exported as globals for subsequent blocks)
TabMain            = Window:CreateTab("MAIN", "frame")
TabAutoRaid        = Window:CreateTab("AUTO RAID", "shield-alert")
TabAutoTower       = Window:CreateTab("AUTO TOWER", "tower-control")
TabAutoExploration = Window:CreateTab("AUTO EXPLORATION", "plane")
TabAutoStory       = Window:CreateTab("AUTO STORY", "book-open")
TabMisc            = Window:CreateTab("MISC", "dice-3")
TabConfig          = Window:CreateTab("CONFIG", "file-cog")
RayfieldNotify     = Rayfield and Rayfield.Notify
