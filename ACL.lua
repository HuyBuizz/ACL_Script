--=============================================================
-- ASTRAL HUB – ALL-IN-ONE (Clean & Structured)
--  • MAIN (Global Boss)
--  • AUTO RAID (Boss + Minion + Deck before fight)
--  • AUTO TOWER (nightmare / potion / base + Deck)
--  • AUTO EXPLORATION (claim → start; per-difficulty inputs + single-run)
--  • MISC (Auto Claim, Auto Quest, Anti-AFK)
--  • CONFIG (Create / Reload / Save / Load / Delete)
--  • FULL Save/Load: AutoRaid, AutoExploration, AutoTower, GlobalBoss
--=============================================================

--====================[ Rayfield Window ]====================--
local Rayfield           = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window             = Rayfield:CreateWindow({
    Name                   = "Astral HUB",
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

--====================[ Services & Remotes ]====================--
local RS                 = game:GetService("ReplicatedStorage")
local WS                 = game:GetService("Workspace")
local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")

local Net                = RS:WaitForChild("shared/network@eventDefinitions")

-- Shared
local RE_Forfeit         = Net:WaitForChild("forfeitBattle")
local RE_SetPartySlot    = Net:WaitForChild("setPartySlot")

-- Auto Raid
local RE_Teleport        = Net:WaitForChild("teleport")
local RE_FightRaidBoss   = Net:WaitForChild("fightRaidBoss")
local RE_FightMinion     = Net:WaitForChild("fightRaidMinion")

-- Exploration
local RE_ClaimExpl       = Net:WaitForChild("claimExploration")
local RE_StartExpl       = Net:WaitForChild("startExploration")

-- Tower (Infinite)
local RE_ClaimInf        = Net:WaitForChild("claimInfinite")
local RE_FightInf        = Net:WaitForChild("fightInfinite")
local RE_PauseInf        = Net:WaitForChild("pauseInfinite")

-- Global Boss (Main)
local RE_FightGlobal     = Net:WaitForChild("fightGlobalBoss")

-- Optional
local RE_TouchPickup     = Net:FindFirstChild("touchedPickup")
local RE_ClaimDailyQuest = Net:WaitForChild("claimDailyQuest")

-- Story
local RE_FightStory      = Net:WaitForChild("fightStoryBoss")

local VIM                = game:GetService("VirtualInputManager")

--====================[ Utilities ]====================--
local function FireSafe(remote, ...)
    if not remote or typeof(remote.FireServer) ~= "function" then
        return false
    end
    local ok = pcall(remote.FireServer, remote, ...)
    return ok
end

local function Trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function notify(title, content, seconds, image)
    if Rayfield and Rayfield.Notify then
        Rayfield:Notify({
            Title = title or "Notification",
            Content = content or "",
            Duration = seconds or 4,
            Image =
                image or "rewind"
        })
    end
end

-- Orchestrator: quản lý Forfeit khi chuyển tính năng
local Orchestrator = {
    skipForfeitOnce = false, -- bỏ qua 1 lần Forfeit tiếp theo
    skipForfeitUntil = 0,    -- hoặc chặn Forfeit đến mốc thời gian này
}

local function ForfeitSafe()
    -- Skip nếu vừa chuyển từ Tower sang tính năng khác
    if Orchestrator.skipForfeitOnce then
        Orchestrator.skipForfeitOnce = false
        return false
    end
    -- Cooldown thời gian (tuỳ chọn)
    if os.clock() < (Orchestrator.skipForfeitUntil or 0) then
        return false
    end
    -- Thực sự forfeit
    FireSafe(RE_Forfeit)
    return true
end
--  ________   ______   _______
-- |        \ /      \ |       \
--  \$$$$$$$$|  $$$$$$\| $$$$$$$\
--    | $$   | $$__| $$| $$__/ $$
--    | $$   | $$    $$| $$    $$
--    | $$   | $$$$$$$$| $$$$$$$\
--    | $$   | $$  | $$| $$__/ $$
--    | $$   | $$  | $$| $$    $$
--     \$$    \$$   \$$ \$$$$$$$
local TabMain            = Window:CreateTab("MAIN", "frame")
local TabAutoRaid        = Window:CreateTab("AUTO RAID", "shield-alert")
local TabAutoTower       = Window:CreateTab("AUTO TOWER", "tower-control")
local TabAutoExploration = Window:CreateTab("AUTO EXPLORATION", "plane")
local TabAutoStory       = Window:CreateTab("AUTO STORY", "book-open")
local TabMisc            = Window:CreateTab("MISC", "dice-3")
local TabConfig          = Window:CreateTab("CONFIG", "file-cog")
--   ______  ________   ______  ________  ________
--  /      \|        \ /      \|        \|        \
-- |  $$$$$$\\$$$$$$$$|  $$$$$$\\$$$$$$$$| $$$$$$$$
-- | $$___\$$  | $$   | $$__| $$  | $$   | $$__
--  \$$    \   | $$   | $$    $$  | $$   | $$  \
--  _\$$$$$$\  | $$   | $$$$$$$$  | $$   | $$$$$
-- |  \__| $$  | $$   | $$  | $$  | $$   | $$_____
--  \$$    $$  | $$   | $$  | $$  | $$   | $$     \
--   \$$$$$$    \$$    \$$   \$$   \$$    \$$$$$$$$
-- Auto Raid
local BossAutos    = {}

-- Exploration
local RARITIES     = { "basic", "gold", "rainbow", "secret" }
local DIFFICULTIES = { "easy", "medium", "hard", "extreme", "nightmare", "celestial" }

local AutoEX       = {
    enabled             = false,
    betweenActions      = 0.5,
    betweenDifficulties = 1.0,
    betweenCycles       = 3.0,
    inputs              = {},
    controls            = { sliders = {}, diffs = {} },
    _busy               = {},
}
for _, diff in ipairs(DIFFICULTIES) do
    AutoEX.inputs[diff] = {
        { name = "", rarity = "basic" },
        { name = "", rarity = "basic" },
        { name = "", rarity = "basic" },
        { name = "", rarity = "basic" },
    }
    AutoEX._busy[diff] = false
end

-- Tower
local Tower = {
    enabled                   = false,
    mode                      = "nightmare", -- nightmare / potion / base
    deckSlot                  = 1,
    useForfeitOnStart         = false,       -- optional; can reset current battle if you want
    afterForfeitWait          = 0.25,
    -- afterClaimWait    = 0.35,
    interval                  = 2.0, -- outer loop pacing

    -- pause spam (catch immediate post-win window to preserve floor)
    pauseSpamEnabled          = false,
    pauseSpamDelay            = 0.5, -- seconds after fight start to begin spamming
    pauseSpamEvery            = 0.2, -- cadence

    toggleRef                 = nil,
    deckDropdownRef           = nil,
    modeDropdownRef           = nil,
    intervalSliderRef         = nil,
    useForfeitToggleRef       = nil,
    pauseSpamEnabledToggleRef = nil,
    pauseSpamDelaySliderRef   = nil,
    pauseSpamEverySliderRef   = nil,
}

-- Global Boss
local GlobalBoss = {
    enabled                   = false,
    deckSlot                  = 1,
    afterForfeitWait          = 0.25,
    interval                  = 2.0,
    bossId                    = 446,
    toggleRef                 = nil,
    deckDropdownRef           = nil,
    intervalSliderRef         = nil,
    useForfeitToggleRef       = nil,
    pauseSpamEnabledToggleRef = nil,
    pauseSpamDelaySliderRef   = nil,
    pauseSpamEverySliderRef   = nil,
}

--==================[ Cross-Feature Kill-Switch ]==================--
-- forward declare so functions above can reference it
local TryPauseInfinite

-- local function DisableOthers(exceptKey)
--     for key, s in pairs(BossAutos) do
--         if key ~= exceptKey and s.enabled and s.toggleRef and s.toggleRef.Set then
--             s.toggleRef:Set(false)
--         end
--     end
--     if exceptKey ~= "GLOBAL" and GlobalBoss.enabled and GlobalBoss.toggleRef and GlobalBoss.toggleRef.Set then
--         GlobalBoss.toggleRef:Set(false)
--     end
--     if exceptKey ~= "TOWER" and Tower.enabled and Tower.toggleRef and Tower.toggleRef.Set then
--         if TryPauseInfinite then TryPauseInfinite(2.0, 0.15) end
--         Orchestrator.skipForfeitOnce = true              -- bỏ qua đúng 1 lần Forfeit kế tiếp
--         Orchestrator.skipForfeitUntil = os.clock() + 3.0 -- thêm 3s an toàn (tùy chỉnh)
--         Tower.toggleRef:Set(false)
--     end
-- end

local function DisableOthers(exceptKey)
    for key, s in pairs(BossAutos) do
        if key ~= exceptKey and s.enabled and s.toggleRef and s.toggleRef.Set then
            s.toggleRef:Set(false)
        end
    end
    if exceptKey ~= "GLOBAL" and GlobalBoss.enabled and GlobalBoss.toggleRef and GlobalBoss.toggleRef.Set then
        GlobalBoss.toggleRef:Set(false)
    end
    if exceptKey ~= "TOWER" and Tower.enabled and Tower.toggleRef and Tower.toggleRef.Set then
        if TryPauseInfinite then TryPauseInfinite(2.0, 0.15) end
        Orchestrator.skipForfeitOnce = true
        Orchestrator.skipForfeitUntil = os.clock() + 3.0
        Tower.toggleRef:Set(false)
    end
    -- ⬇️ NEW: Auto Story
    if exceptKey ~= "STORY" and AutoStory and AutoStory.enabled and AutoStory.toggleRef and AutoStory.toggleRef.Set then
        AutoStory.toggleRef:Set(false)
    end
end


-- Helper: turn off all Auto Raid toggles (used by Auto Claim)
local function DisableAllAutoRaid()
    for key, s in pairs(BossAutos) do
        if s.enabled and s.toggleRef and s.toggleRef.Set then
            s.toggleRef:Set(false)
        end
    end
end

-- local function AS_ClickAnywhereCenter()
--     local cam = workspace.CurrentCamera
--     if not cam then return end
--     local vp = cam.ViewportSize
--     local x, y = math.floor(vp.X * 0.5), math.floor(vp.Y * 0.5)
--     VIM:SendMouseMoveEvent(x, y, game)
--     VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
--     task.wait(0.02)
--     VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
-- end

local function AS_ClickAnywhereCenter()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local x, y = math.floor(vp.X * 0.5), math.floor(vp.Y * 0.98)
    VIM:SendMouseMoveEvent(x, y, game)
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.02)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- Helper: lấy TextLabel outcome trong battleEndScreen
local function AS_GetBattleEndLabel()
    local react = AS_GetReact(); if not react then return nil end
    local bes = react:FindFirstChild("battleEndScreen"); if not bes then return nil end
    local f3 = bes:FindFirstChild("3"); if not f3 then return nil end
    local lbl = f3:FindFirstChild("2"); if not lbl then return nil end
    -- đảm bảo là TextLabel (phòng khi UI đổi class)
    if lbl.ClassName == "TextLabel" or (typeof(lbl) == "Instance" and lbl:IsA("TextLabel")) then
        return lbl
    end
    return nil
end

-- Graceful Tower pause helper: spam pauseInfinite within a short window
TryPauseInfinite = function(totalTime, every)
    totalTime = tonumber(totalTime) or 2.0
    every = math.max(tonumber(every) or 0.15, 0.05)
    local elapsed = 0
    while elapsed < totalTime do
        FireSafe(RE_PauseInf)
        task.wait(every)
        elapsed += every
    end
end

--==================[ AUTO RAID: BUILDERS ]==================--
local function CreateBossAuto(tab, key, prettyName, raidName, bossId)
    BossAutos[key] = {
        enabled          = false,
        interval         = 2.0,
        postTeleportWait = 2.0,
        bossId           = bossId,
        raidName         = raidName,
        isMinion         = false,
        deckSlot         = 1,
        toggleRef        = nil,
        deckDropdownRef  = nil,
    }

    tab:CreateSection("Auto " .. prettyName)

    tab:CreateSlider({
        Name         = ("Delay FIGHT (%s) (s)"):format(prettyName),
        Range        = { 0.5, 10 },
        Increment    = 0.5,
        Suffix       = "s",
        CurrentValue = BossAutos[key].interval,
        Flag         = key .. "_FightInterval",
        Callback     = function(v) BossAutos[key].interval = v end
    })

    local deckDD = tab:CreateDropdown({
        Name          = "Deck (1–8)",
        Options       = { "1", "2", "3", "4", "5", "6", "7", "8" },
        CurrentOption = tostring(BossAutos[key].deckSlot),
        Flag          = key .. "_DeckSlot",
        Callback      = function(opt)
            if typeof(opt) == "table" then opt = opt[1] end
            BossAutos[key].deckSlot = tonumber(opt) or 1
        end
    })
    BossAutos[key].deckDropdownRef = deckDD

    local toggle = tab:CreateToggle({
        Name         = "|🌟| Auto " .. prettyName,
        CurrentValue = false,
        Flag         = key .. "_AutoToggle",
        Callback     = function(state)
            local S = BossAutos[key]; S.enabled = state
            if state then
                DisableOthers(key)
                task.spawn(function()
                    -- FireSafe(RE_Forfeit)
                    ForfeitSafe()
                    task.wait(0.25)
                    FireSafe(RE_Teleport, S.raidName)
                    task.wait(S.postTeleportWait)
                    notify("Auto Raid", "Farming: " .. prettyName, 3, "tractor")
                    while S.enabled do
                        FireSafe(RE_SetPartySlot, ("slot_%d"):format(S.deckSlot or 1))
                        task.wait(0.5)
                        FireSafe(RE_FightRaidBoss, S.bossId)
                        local t = 0
                        while S.enabled and t < S.interval do
                            task.wait(0.1); t += 0.1
                        end
                    end
                end)
            end
        end
    })
    BossAutos[key].toggleRef = toggle
    TabAutoRaid:CreateDivider()
end

local function CollectMinionIds_CoF(prefix)
    local ids = {}
    local folder = WS:FindFirstChild("raid_creator_of_flames") or WS:WaitForChild("raid_creator_of_flames", 5)
    if not folder then return ids end
    prefix = string.lower(prefix or "infernal")
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            local nameLower = string.lower(child.Name)
            if string.sub(nameLower, 1, #prefix) == prefix then
                local sid = child:GetAttribute("serverEntityId")
                if typeof(sid) == "number" then table.insert(ids, sid) end
            end
        end
    end
    return ids
end

local function CreateMinionAuto(tab, key, prettyName, raidName, namePrefix)
    BossAutos[key] = {
        enabled          = false,
        interval         = 2.0,
        postTeleportWait = 2.0,
        raidName         = raidName,
        namePrefix       = namePrefix or "infernal",
        isMinion         = true,
        deckSlot         = 1,
        toggleRef        = nil,
        deckDropdownRef  = nil,
    }

    tab:CreateSection(prettyName)

    tab:CreateSlider({
        Name         = "Delay FIGHT Minion (s)",
        Range        = { 0.2, 10 },
        Increment    = 0.2,
        Suffix       = "s",
        CurrentValue = BossAutos[key].interval,
        Flag         = key .. "_FightInterval",
        Callback     = function(v) BossAutos[key].interval = v end
    })

    local deckDD = tab:CreateDropdown({
        Name          = "Deck (1–8)",
        Options       = { "1", "2", "3", "4", "5", "6", "7", "8" },
        CurrentOption = tostring(BossAutos[key].deckSlot),
        Flag          = key .. "_DeckSlot",
        Callback      = function(opt)
            if typeof(opt) == "table" then opt = opt[1] end
            BossAutos[key].deckSlot = tonumber(opt) or 1
        end
    })
    BossAutos[key].deckDropdownRef = deckDD

    local toggle = tab:CreateToggle({
        Name         = "|🌟| Auto Farm Minion (" .. BossAutos[key].namePrefix .. ")",
        CurrentValue = false,
        Flag         = key .. "_AutoToggle",
        Callback     = function(state)
            local S = BossAutos[key]; S.enabled = state
            if state then
                DisableOthers(key)
                task.spawn(function()
                    -- FireSafe(RE_Forfeit)
                    ForfeitSafe()
                    task.wait(0.25)
                    FireSafe(RE_Teleport, S.raidName)
                    task.wait(S.postTeleportWait)
                    notify("Auto Raid", "Farming minions: " .. prettyName, 3, "tractor")

                    local idx = 1
                    while S.enabled do
                        FireSafe(RE_SetPartySlot, ("slot_%d"):format(S.deckSlot or 1))
                        task.wait(0.5)
                        local ids = CollectMinionIds_CoF(S.namePrefix)
                        if #ids == 0 then
                            local d = math.max(0.5, S.interval * 0.5)
                            local t = 0
                            while S.enabled and t < d do
                                task.wait(0.1); t += 0.1
                            end
                        else
                            if idx > #ids then idx = 1 end
                            FireSafe(RE_FightMinion, ids[idx]); idx += 1
                            local t = 0
                            while S.enabled and t < S.interval do
                                task.wait(0.1); t += 0.1
                            end
                        end
                    end
                end)
            end
        end
    })
    BossAutos[key].toggleRef = toggle
    TabAutoRaid:CreateDivider()
end

-- Build Auto Raid sections
CreateBossAuto(TabAutoRaid, "ED", "Eternal Dragon", "raid_eternal_dragon", 373)
CreateBossAuto(TabAutoRaid, "SD", "Shadow Dragon", "raid_shadow_dragon", 370)
CreateBossAuto(TabAutoRaid, "Sword", "Sword Deity", "raid_sword_deity", 325)
CreateBossAuto(TabAutoRaid, "CoF", "Creator of Flames", "raid_creator_of_flames", 384)
CreateMinionAuto(TabAutoRaid, "CoFMinion", "Creator of Flames - Minions", "raid_creator_of_flames", "infernal")

--==================[ MAIN (GLOBAL BOSS) ]==================--
TabMain:CreateSection("Auto Global Boss")

GlobalBoss.deckDropdownRef = TabMain:CreateDropdown({
    Name          = "Deck (1–8)",
    Options       = { "1", "2", "3", "4", "5", "6", "7", "8" },
    CurrentOption = tostring(GlobalBoss.deckSlot),
    Flag          = "MAIN_Deck",
    Callback      = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end
        GlobalBoss.deckSlot = tonumber(opt) or 1
    end
})

GlobalBoss.intervalSliderRef = TabMain:CreateSlider({
    Name         = "Fight Delay (s)",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = GlobalBoss.interval,
    Flag         = "MAIN_Interval",
    Callback     = function(v) GlobalBoss.interval = v end
})

GlobalBoss.toggleRef = TabMain:CreateToggle({
    Name         = "|💀| Auto Global Boss",
    CurrentValue = false,
    Flag         = "MAIN_Toggle",
    Callback     = function(state)
        GlobalBoss.enabled = state
        if state then
            DisableOthers("GLOBAL")
            task.spawn(function()
                -- FireSafe(RE_Forfeit)
                ForfeitSafe()
                task.wait(GlobalBoss.afterForfeitWait)
                notify("Global Boss", "Automation started.", 3, "paw-print")
                while GlobalBoss.enabled do
                    FireSafe(RE_SetPartySlot, ("slot_%d"):format(GlobalBoss.deckSlot or 1))
                    task.wait(0.5)
                    FireSafe(RE_FightGlobal, GlobalBoss.bossId)
                    local t = 0
                    while GlobalBoss.enabled and t < GlobalBoss.interval do
                        task.wait(0.1); t += 0.1
                    end
                end
            end)
        end
    end
})

--==================[ AUTO TOWER ]==================--
TabAutoTower:CreateSection("Auto Tower (Nightmare / Potion / Base)")

Tower.modeDropdownRef = TabAutoTower:CreateDropdown({
    Name          = "Mode",
    Options       = { "nightmare", "potion", "base", "ninja_village", "green_planet", "shibuya_station", "titans_city",
        "dimensional_fortress", "candy_island", "solo_city",
        "eminence_lookout", "invaded_ninja_village", "necromancer_graveyard" },
    CurrentOption = Tower.mode,
    Flag          = "TOWER_Mode",
    Callback      = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end
        local newMode = tostring(opt or "nightmare")
        if Tower.enabled and newMode ~= Tower.mode then
            -- Pause gracefully before switching Tower mode
            if TryPauseInfinite then TryPauseInfinite(2.0, 0.15) end
        end
        Tower.mode = newMode
    end
})

Tower.deckDropdownRef = TabAutoTower:CreateDropdown({
    Name          = "Deck (1–8)",
    Options       = { "1", "2", "3", "4", "5", "6", "7", "8" },
    CurrentOption = tostring(Tower.deckSlot),
    Flag          = "TOWER_Deck",
    Callback      = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end
        Tower.deckSlot = tonumber(opt) or 1
    end
})

-- TabAutoTower:CreateSlider({
--     Name         = "Delay Claim → Fight (s)",
--     Range        = { 0.1, 3 },
--     Increment    = 0.05,
--     Suffix       = "s",
--     CurrentValue = Tower.afterClaimWait,
--     Flag         = "TOWER_AfterClaim",
--     Callback     = function(v) Tower.afterClaimWait = v end
-- })

-- Extra controls for pauseInfinite strategy
Tower.useForfeitToggleRef = TabAutoTower:CreateToggle({
    Name = "Use Forfeit on Start (reset current battle)",
    CurrentValue = Tower.useForfeitOnStart,
    Flag = "TOWER_UseForfeitOnStart",
    Callback = function(v) Tower.useForfeitOnStart = v and true or false end
})

Tower.pauseSpamEnabledToggleRef = TabAutoTower:CreateToggle({
    Name = "Pause Spam Enabled (preserve floor with pauseInfinite)",
    CurrentValue = Tower.pauseSpamEnabled,
    Flag = "TOWER_PauseSpamEnabled",
    Callback = function(v) Tower.pauseSpamEnabled = v and true or false end
})

Tower.pauseSpamDelaySliderRef = TabAutoTower:CreateSlider({
    Name = "Pause Spam – Start After (s)",
    Range = { 0, 8 },
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = Tower.pauseSpamDelay,
    Flag = "TOWER_PauseSpamDelay",
    Callback = function(v) Tower.pauseSpamDelay = v end
})

Tower.pauseSpamEverySliderRef = TabAutoTower:CreateSlider({
    Name = "Pause Spam – Every (s)",
    Range = { 0.1, 1.0 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = Tower.pauseSpamEvery,
    Flag = "TOWER_PauseSpamEvery",
    Callback = function(v) Tower.pauseSpamEvery = v end
})

Tower.intervalSliderRef = TabAutoTower:CreateSlider({
    Name         = "Fight Interval (s)",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = Tower.interval,
    Flag         = "TOWER_Interval",
    Callback     = function(v) Tower.interval = v end
})

Tower.toggleRef = TabAutoTower:CreateToggle({
    Name         = "|📔| Auto Tower",
    CurrentValue = false,
    Flag         = "TOWER_Toggle",
    Callback     = function(state)
        if Tower.enabled and not state then
            -- Turning Tower OFF: pause gracefully so progress is kept
            if TryPauseInfinite then TryPauseInfinite(2.0, 0.15) end
        end
        Tower.enabled = state
        if not state then return end
        DisableOthers("TOWER")
        task.spawn(function()
            if Tower.useForfeitOnStart then
                -- FireSafe(RE_Forfeit)
                ForfeitSafe()
                task.wait(Tower.afterForfeitWait)
            end
            notify("Auto Tower", "Automation started.", 3, "tower-control")
            while Tower.enabled do
                -- FireSafe(RE_ClaimInf, Tower.mode)
                -- task.wait(Tower.afterClaimWait)
                FireSafe(RE_SetPartySlot, ("slot_%d"):format(Tower.deckSlot or 1))
                task.wait(0.5)
                FireSafe(RE_FightInf, Tower.mode)

                -- Spam pauseInfinite after a short delay to catch the post-win window without resetting floor
                local elapsed = 0
                local spamTimer = 0
                while Tower.enabled and elapsed < Tower.interval do
                    task.wait(0.1)
                    elapsed += 0.1
                    if Tower.pauseSpamEnabled and elapsed >= Tower.pauseSpamDelay then
                        spamTimer += 0.1
                        if spamTimer >= Tower.pauseSpamEvery then
                            spamTimer = 0
                            FireSafe(RE_PauseInf)
                        end
                    end
                end
            end
        end)
    end
})

--==================[ AUTO EXPLORATION ]==================--
TabAutoExploration:CreateSection("Global Delays")

AutoEX.controls.sliders.betweenActions = TabAutoExploration:CreateSlider({
    Name         = "Delay Claim → Start (s)",
    Range        = { 0.1, 3 },
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = AutoEX.betweenActions,
    Flag         = "EX_betweenActions",
    Callback     = function(v) AutoEX.betweenActions = v end
})

AutoEX.controls.sliders.betweenDifficulties = TabAutoExploration:CreateSlider({
    Name         = "Delay Between Difficulties (s)",
    Range        = { 0.2, 5 },
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = AutoEX.betweenDifficulties,
    Flag         = "EX_betweenDiffs",
    Callback     = function(v) AutoEX.betweenDifficulties = v end
})

AutoEX.controls.sliders.betweenCycles = TabAutoExploration:CreateSlider({
    Name         = "Delay Between Cycles (s)",
    Range        = { 1, 20 },
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = AutoEX.betweenCycles,
    Flag         = "EX_betweenCycles",
    Callback     = function(v) AutoEX.betweenCycles = v end
})

local function NormalizeRarity(r)
    if typeof(r) == "table" then r = r[1] end
    r = tostring(r or ""):lower()
    if not table.find(RARITIES, r) then r = "basic" end
    return r
end

local function BuildPicks(conf)
    local arr = {}
    for i = 1, 4 do
        local e  = conf[i] or {}
        local nm = Trim(e.name)
        local rr = NormalizeRarity(e.rarity)
        if nm == "" then return nil, ("Missing card name #%d"):format(i) end
        table.insert(arr, nm .. ":" .. rr)
    end
    return arr
end

local function MakeExplorationUI(tab, diffKey)
    tab:CreateSection("Exploration – " .. string.upper(diffKey))
    AutoEX.controls.diffs[diffKey] = {}

    for i = 1, 4 do
        local ic = tab:CreateInput({
            Name                     = ("|🃏| Card Name #%d"):format(i),
            PlaceholderText          = "e.g. shadow_knight",
            RemoveTextAfterFocusLost = false,
            Flag                     = ("EX_%s_name_%d"):format(diffKey, i),
            CurrentValue             = AutoEX.inputs[diffKey][i].name or "",
            Callback                 = function(txt) AutoEX.inputs[diffKey][i].name = txt or "" end
        })
        local dd = tab:CreateDropdown({
            Name          = ("|🛠️| Rarity #%d"):format(i),
            Options       = RARITIES,
            CurrentOption = AutoEX.inputs[diffKey][i].rarity or "basic",
            Flag          = ("EX_%s_rarity_%d"):format(diffKey, i),
            Callback      = function(opt)
                if typeof(opt) == "table" then opt = opt[1] end
                AutoEX.inputs[diffKey][i].rarity = NormalizeRarity(opt)
            end
        })
        AutoEX.controls.diffs[diffKey][i] = { input = ic, dropdown = dd }
    end

    tab:CreateButton({
        Name = "Run Single: " .. string.upper(diffKey),
        Callback = function()
            if AutoEX._busy[diffKey] then
                warn("[Exploration] Busy: " .. diffKey); return
            end
            AutoEX._busy[diffKey] = true
            task.spawn(function()
                FireSafe(RE_ClaimExpl, diffKey)
                task.wait(AutoEX.betweenActions)
                local picks, err = BuildPicks(AutoEX.inputs[diffKey])
                if picks then
                    FireSafe(RE_StartExpl, diffKey, picks)
                    notify("Exploration", string.upper(diffKey) .. " started.", 3, "circle-play")
                else
                    warn("[Exploration] " .. diffKey .. " error: " .. tostring(err))
                    notify("Exploration", "Error: " .. tostring(err), 4, "rewind")
                end
                task.wait(0.25)
                AutoEX._busy[diffKey] = false
            end)
        end
    })
end

for _, diff in ipairs(DIFFICULTIES) do
    MakeExplorationUI(TabAutoExploration, diff)
end

TabAutoExploration:CreateSection("Automation")
TabAutoExploration:CreateToggle({
    Name         = "|✈️| Auto Exploration",
    CurrentValue = false,
    Flag         = "EX_AutoToggle",
    Callback     = function(state)
        AutoEX.enabled = state
        if not state then return end
        task.spawn(function()
            notify("Exploration", "Auto cycle started.", 3, "telescope")
            while AutoEX.enabled do
                for _, diff in ipairs(DIFFICULTIES) do
                    if not AutoEX.enabled then break end
                    FireSafe(RE_ClaimExpl, diff)
                    task.wait(AutoEX.betweenActions)
                    local picks, err = BuildPicks(AutoEX.inputs[diff])
                    if picks then
                        FireSafe(RE_StartExpl, diff, picks)
                    end
                    local t = 0
                    while AutoEX.enabled and t < AutoEX.betweenDifficulties do
                        task.wait(0.1); t += 0.1
                    end
                end
                local t = 0
                while AutoEX.enabled and t < AutoEX.betweenCycles do
                    task.wait(0.1); t += 0.1
                end
            end
        end)
    end
})

--==================[ CONFIG ]==================--
local CONFIG_FOLDER = "AstralHub"

local function HH_EnsureFolder()
    if isfolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end
HH_EnsureFolder()

local function HH_Path(file) return CONFIG_FOLDER .. "/" .. file end

local function HH_ListConfigs()
    local opts = {}
    if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
        for _, p in ipairs(listfiles(CONFIG_FOLDER)) do
            local name = p:match(".+[\\/](.+)$") or p
            if name and name:lower():match("%.json$") then table.insert(opts, name) end
        end
    end
    table.sort(opts)
    if #opts == 0 then return { "(no configs)" } end
    return opts
end

local function HH_SaveTableToJson(tbl, file)
    HH_EnsureFolder()
    local ok, data = pcall(HttpService.JSONEncode, HttpService, tbl)
    if not ok or not writefile then return false end
    writefile(HH_Path(file), data)
    return true
end

local function HH_LoadTableFromJson(file)
    local path = HH_Path(file)
    if not (isfile and isfile(path)) or not readfile then return nil end
    local data = readfile(path)
    local ok, tbl = pcall(HttpService.JSONDecode, HttpService, data)
    if not ok then return nil end
    return tbl
end

local function HH_CollectCurrentConfig()
    local cfg = {
        AutoRaid = { Bosses = {} },
        AutoExploration = {
            betweenActions      = AutoEX.betweenActions,
            betweenDifficulties = AutoEX.betweenDifficulties,
            betweenCycles       = AutoEX.betweenCycles,
            inputs              = {},
        },
        AutoTower = {
            mode              = Tower.mode,
            deckSlot          = Tower.deckSlot,
            interval          = Tower.interval,
            useForfeitOnStart = Tower.useForfeitOnStart,
            pauseSpamEnabled  = Tower.pauseSpamEnabled,
            pauseSpamDelay    = Tower.pauseSpamDelay,
            pauseSpamEvery    = Tower.pauseSpamEvery,
        },
        GlobalBoss = {
            deckSlot = GlobalBoss.deckSlot,
            interval = GlobalBoss.interval,
        }
    }

    for key, s in pairs(BossAutos) do
        cfg.AutoRaid.Bosses[key] = {
            interval         = s.interval,
            postTeleportWait = s.postTeleportWait,
            raidName         = s.raidName,
            bossId           = s.bossId,
            isMinion         = s.isMinion or false,
            enabled          = s.enabled and true or false,
            deckSlot         = tonumber(s.deckSlot) or 1,
        }
    end

    for diff, arr in pairs(AutoEX.inputs or {}) do
        cfg.AutoExploration.inputs[diff] = {}
        for i = 1, 4 do
            local e = arr[i] or {}
            cfg.AutoExploration.inputs[diff][i] = {
                name   = tostring(e.name or ""),
                rarity = tostring(e.rarity or "basic"),
            }
        end
    end


    -- Auto Story
    cfg.AutoStory = {
        deckSlot = AutoStory.deckSlot,
        intervalBetweenPlays = AutoStory.intervalBetweenPlays,
        outcomeTimeout = AutoStory.outcomeTimeout,
        pollEvery = AutoStory.pollEvery,
        chainNextOnCountdown = AutoStory.chainNextOnCountdown,
        countdownCheckDelay = AutoStory.countdownCheckDelay,
        countdownChildrenThresh = AutoStory.countdownChildrenThresh,
        retryDelayOnLost = AutoStory.retryDelayOnLost,
        autoDismissAfterWin = AutoStory.autoDismissAfterWin,
        autoDismissDelay = AutoStory.autoDismissDelay,
        bossIds = AutoStory.bossIds,
        diffOrder = AutoStory.diffOrder,
    }

    return cfg
end

local function HH_ApplyConfig(tbl)
    if not tbl then return end

    -- AutoRaid
    if tbl.AutoRaid and tbl.AutoRaid.Bosses then
        for key, v in pairs(tbl.AutoRaid.Bosses) do
            local S = BossAutos[key]
            if S then
                if type(v.interval) == "number" then S.interval = v.interval end
                if type(v.postTeleportWait) == "number" then S.postTeleportWait = v.postTeleportWait end
                if type(v.raidName) == "string" then S.raidName = v.raidName end
                if type(v.bossId) == "number" then S.bossId = v.bossId end
                if type(v.deckSlot) == "number" then
                    S.deckSlot = v.deckSlot
                    if S.deckDropdownRef and S.deckDropdownRef.Set then
                        S.deckDropdownRef:Set({ tostring(S.deckSlot) })
                    end
                end
            end
        end
    end

    -- AutoExploration
    if tbl.AutoExploration then
        local ex = tbl.AutoExploration
        if type(ex.betweenActions) == "number" then
            AutoEX.betweenActions = ex.betweenActions
            if AutoEX.controls.sliders.betweenActions then
                AutoEX.controls.sliders.betweenActions:Set(AutoEX.betweenActions)
            end
        end
        if type(ex.betweenDifficulties) == "number" then
            AutoEX.betweenDifficulties = ex.betweenDifficulties
            if AutoEX.controls.sliders.betweenDifficulties then
                AutoEX.controls.sliders.betweenDifficulties:Set(AutoEX.betweenDifficulties)
            end
        end
        if type(ex.betweenCycles) == "number" then
            AutoEX.betweenCycles = ex.betweenCycles
            if AutoEX.controls.sliders.betweenCycles then
                AutoEX.controls.sliders.betweenCycles:Set(AutoEX.betweenCycles)
            end
        end
        if type(ex.inputs) == "table" then
            for diff, arr in pairs(ex.inputs) do
                AutoEX.inputs[diff] = AutoEX.inputs[diff] or {}
                for i = 1, 4 do
                    AutoEX.inputs[diff][i]        = AutoEX.inputs[diff][i] or { name = "", rarity = "basic" }
                    local src                     = arr[i] or {}
                    AutoEX.inputs[diff][i].name   = tostring(src.name or "")
                    AutoEX.inputs[diff][i].rarity = tostring(src.rarity or "basic")
                    local refs                    = AutoEX.controls.diffs[diff] and AutoEX.controls.diffs[diff][i]
                    if refs then
                        if refs.input and refs.input.Set then refs.input:Set(AutoEX.inputs[diff][i].name) end
                        if refs.dropdown and refs.dropdown.Set then refs.dropdown:Set({ AutoEX.inputs[diff][i].rarity }) end
                    end
                end
            end
        end
    end

    -- AutoTower
    if tbl.AutoTower then
        if type(tbl.AutoTower.useForfeitOnStart) == "boolean" then
            Tower.useForfeitOnStart = tbl.AutoTower
                .useForfeitOnStart
        end
        if type(tbl.AutoTower.pauseSpamEnabled) == "boolean" then
            Tower.pauseSpamEnabled = tbl.AutoTower
                .pauseSpamEnabled
        end
        if type(tbl.AutoTower.pauseSpamDelay) == "number" then Tower.pauseSpamDelay = tbl.AutoTower.pauseSpamDelay end
        if type(tbl.AutoTower.pauseSpamEvery) == "number" then Tower.pauseSpamEvery = tbl.AutoTower.pauseSpamEvery end
        -- Reflect new Tower settings into UI
        if Tower.useForfeitToggleRef and Tower.useForfeitToggleRef.Set then
            Tower.useForfeitToggleRef:Set(Tower.useForfeitOnStart and true or false)
        end
        if Tower.pauseSpamEnabledToggleRef and Tower.pauseSpamEnabledToggleRef.Set then
            Tower.pauseSpamEnabledToggleRef:Set(Tower.pauseSpamEnabled and true or false)
        end
        if Tower.pauseSpamDelaySliderRef and Tower.pauseSpamDelaySliderRef.Set then
            Tower.pauseSpamDelaySliderRef:Set(Tower.pauseSpamDelay)
        end
        if Tower.pauseSpamEverySliderRef and Tower.pauseSpamEverySliderRef.Set then
            Tower.pauseSpamEverySliderRef:Set(Tower.pauseSpamEvery)
        end

        if type(tbl.AutoTower.mode) == "string" then
            Tower.mode = tbl.AutoTower.mode
            if Tower.modeDropdownRef and Tower.modeDropdownRef.Set then
                Tower.modeDropdownRef:Set({ Tower.mode })
            end
        end
        if type(tbl.AutoTower.deckSlot) == "number" then
            Tower.deckSlot = tbl.AutoTower.deckSlot
            if Tower.deckDropdownRef and Tower.deckDropdownRef.Set then
                Tower.deckDropdownRef:Set({ tostring(Tower.deckSlot) })
            end
        end
        if type(tbl.AutoTower.interval) == "number" then
            Tower.interval = tbl.AutoTower.interval
            if Tower.intervalSliderRef and Tower.intervalSliderRef.Set then
                Tower.intervalSliderRef:Set(Tower.interval)
            end
        end
    end

    -- AutoStory
    if tbl.AutoStory then
        local S = tbl.AutoStory
        if type(S.deckSlot) == "number" then
            AutoStory.deckSlot = S.deckSlot
            if AutoStory.deckDropdownRef and AutoStory.deckDropdownRef.Set then
                AutoStory.deckDropdownRef:Set({ tostring(AutoStory.deckSlot) })
            end
        end
        if type(S.intervalBetweenPlays) == "number" then
            AutoStory.intervalBetweenPlays = S.intervalBetweenPlays
            if AutoStory.intervalSliderRef and AutoStory.intervalSliderRef.Set then
                AutoStory.intervalSliderRef:Set(AutoStory.intervalBetweenPlays)
            end
        end
        if type(S.outcomeTimeout) == "number" then
            AutoStory.outcomeTimeout = S.outcomeTimeout
            if AutoStory.outcomeTimeoutSliderRef and AutoStory.outcomeTimeoutSliderRef.Set then
                AutoStory.outcomeTimeoutSliderRef:Set(AutoStory.outcomeTimeout)
            end
        end
        if type(S.pollEvery) == "number" then
            AutoStory.pollEvery = S.pollEvery
        end
        if type(S.chainNextOnCountdown) == "boolean" then
            AutoStory.chainNextOnCountdown = S.chainNextOnCountdown
            if AutoStory.chainToggleRef and AutoStory.chainToggleRef.Set then
                AutoStory.chainToggleRef:Set(AutoStory.chainNextOnCountdown and true or false)
            end
        end
        if type(S.countdownCheckDelay) == "number" then
            AutoStory.countdownCheckDelay = S.countdownCheckDelay
            if AutoStory.countdownDelaySliderRef and AutoStory.countdownDelaySliderRef.Set then
                AutoStory.countdownDelaySliderRef:Set(AutoStory.countdownCheckDelay)
            end
        end
        if type(S.countdownChildrenThresh) == "number" then
            AutoStory.countdownChildrenThresh = S.countdownChildrenThresh
            if AutoStory.countdownThreshSliderRef and AutoStory.countdownThreshSliderRef.Set then
                AutoStory.countdownThreshSliderRef:Set(AutoStory.countdownChildrenThresh)
            end
        end
        if type(S.retryDelayOnLost) == "number" then
            AutoStory.retryDelayOnLost = S.retryDelayOnLost
            if AutoStory.retryDelaySliderRef and AutoStory.retryDelaySliderRef.Set then
                AutoStory.retryDelaySliderRef:Set(AutoStory.retryDelayOnLost)
            end
        end
        if type(S.autoDismissAfterWin) == "boolean" then
            AutoStory.autoDismissAfterWin = S.autoDismissAfterWin
            if AutoStory.dismissAfterWinToggleRef and AutoStory.dismissAfterWinToggleRef.Set then
                AutoStory.dismissAfterWinToggleRef:Set(AutoStory.autoDismissAfterWin and true or false)
            end
        end
        if type(S.autoDismissDelay) == "number" then
            AutoStory.autoDismissDelay = S.autoDismissDelay
            if AutoStory.dismissDelaySliderRef and AutoStory.dismissDelaySliderRef.Set then
                AutoStory.dismissDelaySliderRef:Set(AutoStory.autoDismissDelay)
            end
        end
        if type(S.bossIds) == "table" then
            AutoStory.bossIds = S.bossIds
        end
        if type(S.diffOrder) == "table" then
            AutoStory.diffOrder = S.diffOrder
        end
    end

    -- GlobalBoss
    if tbl.GlobalBoss then
        if type(tbl.GlobalBoss.deckSlot) == "number" then
            GlobalBoss.deckSlot = tbl.GlobalBoss.deckSlot
            if GlobalBoss.deckDropdownRef and GlobalBoss.deckDropdownRef.Set then
                GlobalBoss.deckDropdownRef:Set({ tostring(GlobalBoss.deckSlot) })
            end
        end
        if type(tbl.GlobalBoss.interval) == "number" then
            GlobalBoss.interval = tbl.GlobalBoss.interval
            if GlobalBoss.intervalSliderRef and GlobalBoss.intervalSliderRef.Set then
                GlobalBoss.intervalSliderRef:Set(GlobalBoss.interval)
            end
        end
    end
end

--==================[ CONFIG UI ]==================--
TabConfig:CreateSection("Create new config in folder: " .. CONFIG_FOLDER)

local NewName = ""
TabConfig:CreateInput({
    Name = "Config File Name (without .json)",
    PlaceholderText = "e.g. MySetup",
    RemoveTextAfterFocusLost = false,
    CurrentValue = "",
    Callback = function(txt) NewName = tostring(txt or "") end
})

local SelectedFile = nil
local Dropdown_Config

local function HH_BuildDropdown(initialSelect)
    local opts = HH_ListConfigs()
    local pick = initialSelect
    if not pick or not table.find(opts, pick) then pick = opts[1] end
    Dropdown_Config = TabConfig:CreateDropdown({
        Name = "Configs in " .. CONFIG_FOLDER,
        Options = opts,
        CurrentOption = pick,
        Callback = function(opt)
            if typeof(opt) == "table" then opt = opt[1] end
            opt = tostring(opt or "")
            SelectedFile = (opt == "(no configs)") and nil or opt
        end
    })
    SelectedFile = (pick == "(no configs)") and nil or pick
end

local function HH_RefreshDropdown(selectName)
    local opts = HH_ListConfigs()
    local pick = selectName
    if not pick or not table.find(opts, pick) then pick = opts[1] end
    if Dropdown_Config and Dropdown_Config.Refresh then
        Dropdown_Config:Refresh(opts, (pick ~= "(no configs)") and pick or true)
        if pick ~= "(no configs)" and Dropdown_Config.Set then
            Dropdown_Config:Set(pick); SelectedFile = pick
        else
            SelectedFile = nil
        end
    else
        HH_BuildDropdown(pick)
    end
end

TabConfig:CreateButton({
    Name = "|🗃️| Create",
    Callback = function()
        local fn = (NewName:gsub("%s+", ""))
        if fn == "" then return end
        if not fn:lower():match("%.json$") then fn = fn .. ".json" end
        HH_EnsureFolder()
        local path = CONFIG_FOLDER .. "/" .. fn
        if isfile and isfile(path) then return end
        if HH_SaveTableToJson(HH_CollectCurrentConfig(), fn) then
            HH_RefreshDropdown(fn)
            notify("Config", "Created: " .. fn, 3, "badge-plus")
        end
    end
})

TabConfig:CreateSection("Select config")
HH_BuildDropdown(nil)

TabConfig:CreateButton({
    Name = "Reload Config List",
    Callback = function()
        HH_RefreshDropdown(SelectedFile)
        notify("Config", "Reload Successful", 3, "refresh-ccw")
    end
})

TabConfig:CreateSection("Actions")

TabConfig:CreateButton({
    Name = "|📁| Save to Selected Config",
    Callback = function()
        if not SelectedFile or SelectedFile == "" then return end
        if HH_SaveTableToJson(HH_CollectCurrentConfig(), SelectedFile) then
            notify("Config", "Save Successful", 3, "rewind")
        end
    end
})

TabConfig:CreateButton({
    Name = "|⬇️| Load from Selected Config",
    Callback = function()
        if not SelectedFile or SelectedFile == "" then return end
        local cfg = HH_LoadTableFromJson(SelectedFile)
        HH_ApplyConfig(cfg)
        notify("Config", "Load Successful", 3, "cog")
    end
})

local function HH_Delete(file)
    local path = CONFIG_FOLDER .. "/" .. file
    if not (isfile and isfile(path)) then return false end
    if delfile then
        delfile(path); return true
    else
        return false
    end
end

local _deleteArmed = false
TabConfig:CreateButton({
    Name = "|❌| Delete Selected Config (Press Twice to Confirm)",
    Callback = function()
        if not SelectedFile or SelectedFile == "" or SelectedFile == "(no configs)" then return end
        if not _deleteArmed then
            _deleteArmed = true
            notify("Delete Confirmation", "Press Delete again within 5s to confirm: " .. SelectedFile, 5, "trash")
            task.delay(5, function() _deleteArmed = false end)
            return
        end
        _deleteArmed = false
        if HH_Delete(SelectedFile) then
            SelectedFile = nil; HH_RefreshDropdown(nil)
            notify("Config", "Delete Successful", 3, "trash")
        end
    end
})


-- ==================[ Win Summary Detectors ]==================
-- Goal: Pause exactly when the Infinite Tower Summary pops (modal.current == 21)

local SummaryDetector = {
    enabled = true,
    debounceTs = 0,
    debounceGap = 1.0, -- seconds between triggers
}

local function TriggerPauseFromSummary()
    local now = os.clock()
    if now - (SummaryDetector.debounceTs or 0) < (SummaryDetector.debounceGap or 1.0) then
        return
    end
    SummaryDetector.debounceTs = now
    -- short, dense spam to reliably hit the server window
    if TryPauseInfinite then TryPauseInfinite(2.0, 0.15) end
end

local function StartModalWatcher()
    -- Try to read producer store (reflex/rodux) to watch modal.current==21
    local ok, producer = pcall(require,
        game:GetService("ReplicatedStorage"):WaitForChild("shared"):WaitForChild("producer"))
    if not ok or type(producer) ~= "table" then return end

    -- Try common APIs: getState(), changed, subscribe()
    local prevModal
    local function check()
        local stateOk, state = pcall(function()
            if type(producer.getState) == "function" then
                return producer.getState()
            elseif type(producer.store) == "table" and type(producer.store.getState) == "function" then
                return producer.store.getState()
            end
        end)
        if not stateOk or type(state) ~= "table" then return end
        local cur = state.modal and state.modal.current
        if cur ~= prevModal then
            -- edge: transitioning into summary (21)
            if cur == 21 then
                TriggerPauseFromSummary()
            end
            prevModal = cur
        end
    end

    -- Evented if possible
    if typeof(producer.changed) == "RBXScriptSignal" then
        producer.changed:Connect(function(...)
            check()
        end)
    elseif type(producer.subscribe) == "function" then
        -- expected to call our callback on any state change
        producer.subscribe(check)
    else
        -- fallback polling
        task.spawn(function()
            while true do
                check()
                task.wait(0.05)
            end
        end)
    end
end

local function StartReactGuiWatcher()
    local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local reactGui = pg:FindFirstChild("react")
    if not reactGui then
        -- in some games, react might mount a bit later
        pg.ChildAdded:Connect(function(child)
            if child.Name == "react" then
                reactGui = child
            end
        end)
    end

    local function isSummaryUi(inst)
        -- Heuristics: look at names containing "infinite", "summary", "tower"
        local n = string.lower(inst.Name or "")
        if n:find("summary") and (n:find("infinite") or n:find("tower")) then return true end
        -- also inspect ScreenGui/Frame parent chains
        local p = inst.Parent
        local depth = 0
        while p and depth < 4 do
            local pn = string.lower(p.Name or "")
            if pn:find("summary") and (pn:find("infinite") or pn:find("tower")) then
                return true
            end
            p = p.Parent; depth += 1
        end
        return false
    end

    local function hook(container)
        if not container then return end
        container.DescendantAdded:Connect(function(inst)
            if SummaryDetector.enabled and isSummaryUi(inst) then
                TriggerPauseFromSummary()
            end
        end)
    end

    hook(pg)
    if reactGui then hook(reactGui) end
end

-- Start both detectors (they're cheap; modal watcher is preferred, GUI watcher is fallback)
task.spawn(StartModalWatcher)
task.spawn(StartReactGuiWatcher)

-- ============================================================

--==================[ MISC ]==================--
TabMisc:CreateSection("Miscellaneous Settings")

-- Auto Claim Box/Potion
local LocalPlayer = Players.LocalPlayer

local function TouchPickups()
    local pickups = {}
    for _, obj in pairs(WS:GetChildren()) do
        if obj:IsA("Model") then
            local lname = obj.Name:lower()
            if lname:match("^potion_%d+$") or lname:match("^box_%d+$") then
                table.insert(pickups, obj)
            end
        end
    end
    return pickups
end

local function TeleportTo(obj)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local primary = obj.PrimaryPart or (obj:IsA("Model") and obj.PrimaryPart) or nil
    if primary then
        hrp.CFrame = primary.CFrame + Vector3.new(0, 5, 0)
    elseif obj.GetModelCFrame then
        hrp.CFrame = obj:GetModelCFrame() + Vector3.new(0, 5, 0)
    end
end

local autoClaim = false
TabMisc:CreateToggle({
    Name         = "Auto Claim Box/Potion",
    CurrentValue = false,
    Flag         = "AutoClaim",
    Callback     = function(Value)
        autoClaim = Value
        if autoClaim then
            DisableAllAutoRaid() -- ensure all Auto Raid toggles are off
            task.spawn(function()
                notify("Auto Claim", "Enabled", 2, "rewind")
                while autoClaim do
                    local pickups = TouchPickups()
                    for _, obj in ipairs(pickups) do
                        TeleportTo(obj)
                        task.wait(1)
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

-- Auto Claim Daily Quests
local autoQuest = false
TabMisc:CreateToggle({
    Name         = "Auto Claim Quest",
    CurrentValue = false,
    Flag         = "AutoQuest",
    Callback     = function(Value)
        autoQuest = Value
        if autoQuest then
            task.spawn(function()
                notify("Auto Quest", "Enabled", 2, "rewind")
                local questId = 1
                while autoQuest do
                    if RE_ClaimDailyQuest then RE_ClaimDailyQuest:FireServer(questId) end
                    questId = (questId % 6) + 1
                    task.wait(2)
                end
            end)
        end
    end
})

-- Anti AFK
local antiAFK = false
local VU      = game:GetService("VirtualUser")
local Player  = Players.LocalPlayer

TabMisc:CreateToggle({
    Name         = "Anti AFK",
    CurrentValue = false,
    Flag         = "AntiAFK",
    Callback     = function(Value)
        antiAFK = Value
        if antiAFK then
            task.spawn(function()
                notify("Anti AFK", "Enabled", 2, "rewind")
                while antiAFK do
                    Player.Idled:Wait()
                    if antiAFK then
                        VU:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        task.wait(0.5)
                        VU:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    end
                end
            end)
        end
    end
})

--==================[ AUTO STORY ]==================--
-- Tab mới + toggle chạy chuỗi boss theo độ khó: normal → medium → hard → extreme
-- (Tab created earlier in TABS section): TabAutoStory

-- Utils nhỏ, tránh nil-error khi dò UI react
local function AS_CountChildrenSafe(obj)
    if not obj or typeof(obj) ~= "Instance" then return 0 end
    local ok, kids = pcall(function() return obj:GetChildren() end)
    return ok and #kids or 0
end

local function AS_GetReact()
    local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    return pg:FindFirstChild("react")
end

-- local function AS_IsWin()
--     -- Win khi: react.rewardsPopup["2"]["2"] có >1 children
--     local react = AS_GetReact(); if not react then return false end
--     local rewards = react:FindFirstChild("rewardsPopup"); if not rewards then return false end
--     local f2 = rewards:FindFirstChild("2"); if not f2 then return false end
--     local inner = f2:FindFirstChild("2"); if not inner then return false end
--     return AS_CountChildrenSafe(inner) > 1
-- end

-- local function AS_IsLost()
--     -- Lost khi: xuất hiện react.battleEndScreen
--     local react = AS_GetReact(); if not react then return false end
--     return react:FindFirstChild("battleEndScreen") ~= nil
-- end

-- WIN khi: battleEndScreen xuất hiện và label = "Victory"
local function AS_IsWin()
    local lbl = AS_GetBattleEndLabel()
    if not lbl then return false end
    -- trim để tránh khoảng trắng vô tình
    local txt = tostring(lbl.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return txt == "Victory"
end

-- LOST khi: battleEndScreen xuất hiện và label = "Defeat"
local function AS_IsLost()
    local lbl = AS_GetBattleEndLabel()
    if not lbl then return false end
    local txt = tostring(lbl.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return txt == "Defeat"
end

local function AS_NotificationsChildren()
    local react = AS_GetReact(); if not react then return 0 end
    local notifications = react:FindFirstChild("notifications"); if not notifications then return 0 end
    return AS_CountChildrenSafe(notifications)
end

-- Trạng thái & thiết lập
AutoStory = {
    enabled                  = false,
    deckSlot                 = 1,
    intervalBetweenPlays     = 1.0,   -- nhịp giữa các lần gửi event (an toàn)
    outcomeTimeout           = 120.0, -- timeout chờ kết quả (s)
    pollEvery                = 0.2,   -- nhịp dò UI kết quả

    -- COUNTDOWN (nhảy độ khó kế sau ~2s nếu notifications > ngưỡng)
    chainNextOnCountdown     = true,
    countdownCheckDelay      = 2.0, -- ⬅️ theo góp ý của bạn (đợi ~2s rồi mới check)
    countdownChildrenThresh  = 2,

    -- LOST → đánh lại
    retryDelayOnLost         = 1.0,

    -- ⬇️ THÊM Ở ĐÂY
    autoDismissAfterWin      = true,
    autoDismissDelay         = 1.5,

    -- Danh sách boss tĩnh (SỬA THEO BẠN)
    -- Gợi ý: thêm/đổi id tuỳ ý; mặc định đưa ví dụ 308, 376.
    bossIds                  = { 308, 376, 331, 358, 458, 349, 322, 300, 363, 338 },

    -- Thứ tự độ khó
    diffOrder                = { "normal", "medium", "hard", "extreme" },

    -- Con trỏ hiện tại
    _bossIdx                 = 1,
    _diffIdx                 = 1,

    -- UI handles
    toggleRef                = nil,
    deckDropdownRef          = nil,
    intervalSliderRef        = nil,
    outcomeTimeoutSliderRef  = nil,
    retryDelaySliderRef      = nil,
    chainToggleRef           = nil,
    countdownDelaySliderRef  = nil,
    countdownThreshSliderRef = nil,
}

-- Helper: tiến độ độ khó/boss
local function AS_NextDifficultyOrBoss()
    AutoStory._diffIdx += 1
    if AutoStory._diffIdx > #AutoStory.diffOrder then
        AutoStory._diffIdx = 1
        AutoStory._bossIdx += 1
        if AutoStory._bossIdx > #AutoStory.bossIds then
            AutoStory._bossIdx = 1 -- lặp lại từ đầu danh sách boss
        end
    end
end

local function AS_CurrentBossAndDiff()
    local bossId = AutoStory.bossIds[AutoStory._bossIdx]
    local diff   = AutoStory.diffOrder[AutoStory._diffIdx]
    return bossId, diff
end

-- UI
TabAutoStory:CreateSection("Auto Story – Chain Boss by Difficulties")

AutoStory.deckDropdownRef = TabAutoStory:CreateDropdown({
    Name          = "Deck (1–8)",
    Options       = { "1", "2", "3", "4", "5", "6", "7", "8" },
    CurrentOption = tostring(AutoStory.deckSlot),
    Flag          = "STORY_Deck",
    Callback      = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end
        AutoStory.deckSlot = tonumber(opt) or 1
    end
})

AutoStory.intervalSliderRef = TabAutoStory:CreateSlider({
    Name         = "Delay between attempts (s)",
    Range        = { 0.2, 5 },
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = AutoStory.intervalBetweenPlays,
    Flag         = "STORY_Interval",
    Callback     = function(v) AutoStory.intervalBetweenPlays = v end
})

AutoStory.outcomeTimeoutSliderRef = TabAutoStory:CreateSlider({
    Name         = "Outcome Timeout (s)",
    Range        = { 10, 300 },
    Increment    = 5,
    Suffix       = "s",
    CurrentValue = AutoStory.outcomeTimeout,
    Flag         = "STORY_OutcomeTimeout",
    Callback     = function(v) AutoStory.outcomeTimeout = v end
})

AutoStory.retryDelaySliderRef = TabAutoStory:CreateSlider({
    Name         = "Retry Delay on LOST (s)",
    Range        = { 0.2, 5 },
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = AutoStory.retryDelayOnLost,
    Flag         = "STORY_RetryDelay",
    Callback     = function(v) AutoStory.retryDelayOnLost = v end
})

TabAutoStory:CreateSection("Countdown Logic")
AutoStory.chainToggleRef = TabAutoStory:CreateToggle({
    Name         = "Chain next on COUNTDOWN",
    CurrentValue = AutoStory.chainNextOnCountdown,
    Flag         = "STORY_ChainOnCountdown",
    Callback     = function(v) AutoStory.chainNextOnCountdown = v and true or false end
})

AutoStory.countdownDelaySliderRef = TabAutoStory:CreateSlider({
    Name         = "COUNTDOWN Check Delay (s)",
    Range        = { 0.5, 5 },
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = AutoStory.countdownCheckDelay,
    Flag         = "STORY_CountdownDelay",
    Callback     = function(v) AutoStory.countdownCheckDelay = v end
})

AutoStory.countdownThreshSliderRef = TabAutoStory:CreateSlider({
    Name         = "notifications children > (threshold)",
    Range        = { 1, 6 },
    Increment    = 1,
    CurrentValue = AutoStory.countdownChildrenThresh,
    Flag         = "STORY_CountdownThresh",
    Callback     = function(v) AutoStory.countdownChildrenThresh = math.floor(v) end
})

TabAutoStory:CreateSection("Rewards Auto Dismiss")
AutoStory.dismissAfterWinToggleRef = TabAutoStory:CreateToggle({
    Name = "Auto click to dismiss after WIN",
    CurrentValue = AutoStory.autoDismissAfterWin,
    Flag = "STORY_AutoDismissAfterWin",
    Callback = function(v) AutoStory.autoDismissAfterWin = v and true or false end
})

AutoStory.dismissDelaySliderRef = TabAutoStory:CreateSlider({
    Name         = "Dismiss delay after WIN (s)",
    Range        = { 0.5, 5 },
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = AutoStory.autoDismissDelay,
    Flag         = "STORY_AutoDismissDelay",
    Callback     = function(v) AutoStory.autoDismissDelay = v end
})


AutoStory.toggleRef = TabAutoStory:CreateToggle({
    Name         = "|📖| Auto Story",
    CurrentValue = false,
    Flag         = "STORY_Toggle",
    Callback     = function(state)
        AutoStory.enabled = state
        if not state then return end

        DisableOthers("STORY")

        task.spawn(function()
            notify("Auto Story", "Automation started.", 3, "book-open")
            -- reset con trỏ vòng chain
            AutoStory._bossIdx = 1
            AutoStory._diffIdx = 1

            while AutoStory.enabled do
                local bossId, diff = AS_CurrentBossAndDiff()

                -- Set Deck trước khi FIGHT
                FireSafe(RE_SetPartySlot, ("slot_%d"):format(AutoStory.deckSlot or 1))
                task.wait(0.25)

                -- Gửi fight
                FireSafe(RE_FightStory, bossId, diff)
                notify("Auto Story",
                    ("FIGHT boss %d @ %s"):format(tonumber(bossId or 0), tostring(diff)),
                    2, "swords")

                -- 1) COUNTDOWN: sau ~2s check notifications > thresh → chain NGAY độ khó kế
                local chainedByCountdown = false
                if AutoStory.chainNextOnCountdown then
                    task.wait(AutoStory.countdownCheckDelay)
                    if AS_NotificationsChildren() > (AutoStory.countdownChildrenThresh or 2) then
                        local curDiffIdx = AutoStory._diffIdx
                        AS_NextDifficultyOrBoss()
                        local _, nextDiff = AS_CurrentBossAndDiff()
                        notify("Auto Story",
                            ("COUNTDOWN detected → queued next: %s"):format(curDiffIdx == #AutoStory.diffOrder and
                                "next boss" or nextDiff),
                            2, "fast-forward")
                        chainedByCountdown = true
                    end
                end

                if not chainedByCountdown then
                    -- 2) Đợi outcome: WIN/LOST
                    local t = 0
                    local outcome -- "win" | "lost" | nil
                    while AutoStory.enabled and t < (AutoStory.outcomeTimeout or 120) do
                        if AS_IsWin() then
                            outcome = "win"; break
                        end
                        if AS_IsLost() then
                            outcome = "lost"; break
                        end
                        task.wait(AutoStory.pollEvery); t += AutoStory.pollEvery
                    end

                    if outcome == "win" then
                        -- ⬇️ ĐỢI X GIÂY RỒI CLICK BẤT KỲ ĐỂ ĐÓNG REWARDS
                        if AutoStory.autoDismissAfterWin then
                            task.spawn(function()
                                task.wait(AutoStory.autoDismissDelay or 1.5)
                                AS_ClickAnywhereCenter()
                            end)
                        end
                        task.wait(1) -- đợi UI ổn định
                        local lastWasExtreme = (AutoStory._diffIdx == #AutoStory.diffOrder)
                        AS_NextDifficultyOrBoss()
                        notify("Auto Story",
                            lastWasExtreme and "WIN → next boss" or "WIN → next difficulty",
                            2, "trophy")
                    elseif outcome == "lost" then
                        notify("Auto Story", "LOST → retry same boss & difficulty", 2, "rotate-ccw")
                        task.wait(AutoStory.retryDelayOnLost or 1.0)
                        -- không đổi con trỏ; loop sẽ gửi lại cùng boss/diff
                    else
                        -- Timeout: không thấy win/lost (có thể UI thay đổi), cứ thử độ khó kế tiếp để không kẹt
                        AS_NextDifficultyOrBoss()
                        notify("Auto Story", "Timeout outcome → moving on", 2, "alert-octagon")
                    end
                end

                -- Nhịp an toàn giữa các lần gửi
                local t2 = 0
                while AutoStory.enabled and t2 < (AutoStory.intervalBetweenPlays or 1.0) do
                    task.wait(0.1); t2 += 0.1
                end
            end
        end)
    end
})

-- Gợi ý hiển thị nhanh danh sách boss đang cấu hình
TabAutoStory:CreateSection("Boss List (static in code)")
TabAutoStory:CreateButton({
    Name = ("Current: %s"):format(table.concat(AutoStory.bossIds, ", ")),
    Callback = function()
        notify("Auto Story",
            "Để thay đổi bossIds, sửa trực tiếp trong code: AutoStory.bossIds = { ... }",
            5, "info")
    end
})
--==================[ /AUTO STORY ]==================--
