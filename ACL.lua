--=============================================================
-- HIEU HUB – ALL-IN-ONE SCRIPT (Clean Structured)
--  • MAIN (Global Boss)
--  • AUTO RAID (Boss + Minion + Deck before fight)
--  • AUTO TOWER (nightmare / potion / base + Deck)
--  • AUTO EXPLORATION (claim → start; per-diff inputs + single-run)
--  • CONFIG (Create/Reload/Save/Load/Delete)
--  • FULL Save/Load: AutoRaid, AutoExploration, AutoTower, GlobalBoss
--=============================================================

--====================[ Rayfield Window ]====================--
local Rayfield           = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window             = Rayfield:CreateWindow({
    Name = "Astral HUB",
    Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by AczTeam",
    ShowText = "Rayfield", -- for mobile users to unhide rayfield, change if you'd like
    Theme = "Default",     -- Check https://docs.sirius.menu/rayfield/configuration/themes

    ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AstralHub", -- Create a custom folder for your hub/game
        FileName = "AstralHub"
    },

    Discord = {
        Enabled = false,         -- Prompt the user to join your Discord server if their executor supports it
        Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
        RememberJoins = true     -- Set this to false to make them join the discord every time they load it up
    },

    KeySystem = true, -- Set this to true to use our key system
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
        FileName = "AstralHubKey",                                    -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
        SaveKey = true,                                      -- The user's key will be saved, but if you change the key, they will be unable to use your script
        GrabKeyFromSite = false,                             -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
        Key = { "Hello" }                                    -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
})

--====================[ Services & Remotes ]====================--
local RS                 = game:GetService("ReplicatedStorage")
local WS                 = game:GetService("Workspace")
local HttpService        = game:GetService("HttpService")

local Net                = RS:WaitForChild("shared/network@eventDefinitions")

-- Shared remotes
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

-- Global Boss (Main)
local RE_FightGlobal     = Net:WaitForChild("fightGlobalBoss")

-- TouchedPickup
local RE_TouchPickup     = Net:FindFirstChild("touchedPickup")
local RE_ClaimDailyQuest = Net:WaitForChild("claimDailyQuest")

--====================[ Small Utils ]====================--
local function FireSafe(remote, ...)
    if not remote or typeof(remote.FireServer) ~= "function" then
        -- warn("[HieuHub] Invalid remote:", remote and remote.Name)
        return false
    end
    local ok, err = pcall(remote.FireServer, remote, ...)
    if not ok then
        -- warn("[HieuHub] Remote error", remote.Name, err)
        return false
    end
    return true
end

local function Trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

--=============================================================
--                          TABS
--=============================================================
local TabMain            = Window:CreateTab("MAIN", 4483362458)
local TabAutoRaid        = Window:CreateTab("AUTO RAID", 4483362458)
local TabAutoTower       = Window:CreateTab("AUTO TOWER", 4483362458)
local TabAutoExploration = Window:CreateTab("AUTO EXPLORAION", 4483362458)
local TabMisc            = Window:CreateTab("MISC", 4483362458)
local TabConfig          = Window:CreateTab("CONFIG", 4483362458)

--=============================================================
--                          STATE
--=============================================================
-- AUTO RAID (bosses + minion)
local BossAutos          = {} -- key -> {enabled, interval, postTeleportWait, bossId, raidName, isMinion?, deckSlot, toggleRef, deckDropdownRef}

-- local function DisableOthers(exceptKey)
--     for key, s in pairs(BossAutos) do
--         if key ~= exceptKey and s.enabled and s.toggleRef and s.toggleRef.Set then
--             s.toggleRef:Set(false)
--         end
--     end
-- end

-- EXPLORATION
local RARITIES           = { "basic", "gold", "rainbow", "secret" }
local DIFFICULTIES       = { "easy", "medium", "hard", "extreme", "nightmare", "celestial" }

local AutoEX             = {
    enabled             = false,
    betweenActions      = 0.5, -- claim→start
    betweenDifficulties = 1.0,
    betweenCycles       = 3.0,
    inputs              = {}, -- inputs[diff] = { {name,rarity} x4 }
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

-- TOWER
local Tower = {
    enabled           = false,
    mode              = "nightmare", -- nightmare / potion / base
    deckSlot          = 1,
    afterForfeitWait  = 0.25,
    afterClaimWait    = 0.35,
    interval          = 2.0,
    toggleRef         = nil,
    deckDropdownRef   = nil,
    modeDropdownRef   = nil,
    intervalSliderRef = nil,
}

-- MAIN (Global Boss)
local GlobalBoss = {
    enabled           = false,
    deckSlot          = 1,
    afterForfeitWait  = 0.25,
    interval          = 2.0,
    bossId            = 446,
    toggleRef         = nil,
    deckDropdownRef   = nil,
    intervalSliderRef = nil,
}

-- Hàm DisableOthers mở rộng
local function DisableOthers(exceptKey)
    -- Tắt tất cả Auto Raid khác
    for key, s in pairs(BossAutos) do
        if key ~= exceptKey and s.enabled and s.toggleRef and s.toggleRef.Set then
            s.toggleRef:Set(false)
        end
    end

    -- Nếu exceptKey không phải Global thì tắt Auto Global Boss
    if exceptKey ~= "GLOBAL" and GlobalBoss.enabled and GlobalBoss.toggleRef and GlobalBoss.toggleRef.Set then
        GlobalBoss.toggleRef:Set(false)
    end

    -- Nếu exceptKey không phải Tower thì tắt Auto Tower
    if exceptKey ~= "TOWER" and Tower.enabled and Tower.toggleRef and Tower.toggleRef.Set then
        Tower.toggleRef:Set(false)
    end
end

--=============================================================
--                  AUTO RAID: BUILDERS
--=============================================================
local function CreateBossAuto(tab, key, prettyName, raidName, bossId)
    BossAutos[key] = {
        enabled = false,
        interval = 2.0,
        postTeleportWait = 2.0,
        bossId = bossId,
        raidName = raidName,
        isMinion = false,
        deckSlot = 1,
        toggleRef = nil,
        deckDropdownRef = nil,
    }

    tab:CreateSection("Auto " .. prettyName)

    tab:CreateSlider({
        Name = ("Delay FIGHT (%s) (s)"):format(prettyName),
        Range = { 0.5, 10 },
        Increment = 0.5,
        Suffix = "s",
        CurrentValue = BossAutos[key].interval,
        Flag = key .. "_FightInterval",
        Callback = function(v) BossAutos[key].interval = v end
    })

    local deckDD = tab:CreateDropdown({
        Name = "Deck (1–8)",
        Options = { "1", "2", "3", "4", "5", "6", "7", "8" },
        CurrentOption = tostring(BossAutos[key].deckSlot),
        Flag = key .. "_DeckSlot",
        Callback = function(opt)
            if typeof(opt) == "table" then opt = opt[1] end
            BossAutos[key].deckSlot = tonumber(opt) or 1
        end
    })
    BossAutos[key].deckDropdownRef = deckDD

    local toggle = tab:CreateToggle({
        Name = "|🌟| Auto " .. prettyName,
        CurrentValue = false,
        Flag = key .. "_AutoToggle",
        Callback = function(state)
            local S = BossAutos[key]; S.enabled = state
            if state then
                DisableOthers(key)
                task.spawn(function()
                    FireSafe(RE_Forfeit)
                    task.wait(0.25)
                    FireSafe(RE_Teleport, S.raidName)
                    task.wait(S.postTeleportWait)
                    while S.enabled do
                        FireSafe(RE_SetPartySlot, ("slot_%d"):format(S.deckSlot or 1))
                        task.wait(0.5) -- đợi 0.5s để server kịp nhận set deck
                        FireSafe(RE_FightRaidBoss, S.bossId)
                        local t = 0; while S.enabled and t < S.interval do
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
        enabled = false,
        interval = 2.0,
        postTeleportWait = 2.0,
        raidName = raidName,
        namePrefix = namePrefix or "infernal",
        isMinion = true,
        deckSlot = 1,
        toggleRef = nil,
        deckDropdownRef = nil,
    }

    tab:CreateSection(prettyName)
    tab:CreateSlider({
        Name = "Delay FIGHT Minion (s)",
        Range = { 0.2, 10 },
        Increment = 0.2,
        Suffix = "s",
        CurrentValue = BossAutos[key].interval,
        Flag = key .. "_FightInterval",
        Callback = function(v) BossAutos[key].interval = v end
    })

    local deckDD = tab:CreateDropdown({
        Name = "Deck (1–8)",
        Options = { "1", "2", "3", "4", "5", "6", "7", "8" },
        CurrentOption = tostring(BossAutos[key].deckSlot),
        Flag = key .. "_DeckSlot",
        Callback = function(opt)
            if typeof(opt) == "table" then opt = opt[1] end
            BossAutos[key].deckSlot = tonumber(opt) or 1
        end
    })
    BossAutos[key].deckDropdownRef = deckDD

    local toggle = tab:CreateToggle({
        Name = "|🌟| Auto Farm Minion (" .. BossAutos[key].namePrefix .. ")",
        CurrentValue = false,
        Flag = key .. "_AutoToggle",
        Callback = function(state)
            local S = BossAutos[key]; S.enabled = state
            if state then
                DisableOthers(key)
                task.spawn(function()
                    FireSafe(RE_Forfeit)
                    task.wait(0.25)
                    FireSafe(RE_Teleport, S.raidName)
                    task.wait(S.postTeleportWait)

                    local idx = 1
                    while S.enabled do
                        FireSafe(RE_SetPartySlot, ("slot_%d"):format(S.deckSlot or 1))
                        task.wait(0.5) -- đợi 0.5s để server kịp nhận set deck
                        local ids = CollectMinionIds_CoF(S.namePrefix)
                        if #ids == 0 then
                            local d = math.max(0.5, S.interval * 0.5); local t = 0
                            while S.enabled and t < d do
                                task.wait(0.1); t += 0.1
                            end
                        else
                            if idx > #ids then idx = 1 end
                            FireSafe(RE_FightMinion, ids[idx]); idx += 1
                            local t = 0; while S.enabled and t < S.interval do
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

--=============================================================
--                  MAIN (GLOBAL BOSS)
--=============================================================
TabMain:CreateSection("Auto Global Boss")

GlobalBoss.deckDropdownRef = TabMain:CreateDropdown({
    Name = "Deck (1–8)",
    Options = { "1", "2", "3", "4", "5", "6", "7", "8" },
    CurrentOption = tostring(GlobalBoss.deckSlot),
    Flag = "MAIN_Deck",
    Callback = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end; GlobalBoss.deckSlot = tonumber(opt) or 1
    end
})
GlobalBoss.intervalSliderRef = TabMain:CreateSlider({
    Name = "Fight Delay (s)",
    Range = { 0.5, 10 },
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = GlobalBoss.interval,
    Flag = "MAIN_Interval",
    Callback = function(v) GlobalBoss.interval = v end
})
-- GlobalBoss.toggleRef = TabMain:CreateToggle({
--     Name = "Auto Global Boss (Forfeit → Deck → Fight)",
--     CurrentValue = false,
--     Flag = "MAIN_Toggle",
--     Callback = function(state)
--         GlobalBoss.enabled = state
--         if not state then return end
--         task.spawn(function()
--             FireSafe(RE_Forfeit)
--             task.wait(GlobalBoss.afterForfeitWait)
--             while GlobalBoss.enabled do
--                 FireSafe(RE_SetPartySlot, ("slot_%d"):format(GlobalBoss.deckSlot or 1))
--                 FireSafe(RE_FightGlobal, GlobalBoss.bossId)
--                 local t = 0; while GlobalBoss.enabled and t < GlobalBoss.interval do
--                     task.wait(0.1); t += 0.1
--                 end
--             end
--         end)
--     end
-- })

GlobalBoss.toggleRef = TabMain:CreateToggle({
    Name = "|💀| Auto Global Boss",
    CurrentValue = false,
    Flag = "MAIN_Toggle",
    Callback = function(state)
        GlobalBoss.enabled = state
        if state then
            -- Tắt Auto Raid khác
            DisableOthers("GLOBAL")

            -- Tắt Auto Tower nếu đang bật
            if Tower.enabled and Tower.toggleRef and Tower.toggleRef.Set then
                Tower.toggleRef:Set(false)
            end

            -- Vòng lặp fight
            task.spawn(function()
                FireSafe(RE_Forfeit)
                task.wait(GlobalBoss.afterForfeitWait)
                while GlobalBoss.enabled do
                    FireSafe(RE_SetPartySlot, ("slot_%d"):format(GlobalBoss.deckSlot or 1))
                    task.wait(0.5) -- đợi 0.5s để server kịp nhận set deck
                    FireSafe(RE_FightGlobal, GlobalBoss.bossId)
                    local t = 0; while GlobalBoss.enabled and t < GlobalBoss.interval do
                        task.wait(0.1); t += 0.1
                    end
                end
            end)
        end
    end
})

--=============================================================
--                       AUTO TOWER
--=============================================================
TabAutoTower:CreateSection("Auto Tower (Nightmare / Potion / Base)")

Tower.modeDropdownRef = TabAutoTower:CreateDropdown({
    Name = "Mode",
    Options = { "nightmare", "potion", "base" },
    CurrentOption = Tower.mode,
    Flag = "TOWER_Mode",
    Callback = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end; Tower.mode = tostring(opt or "nightmare")
    end
})
Tower.deckDropdownRef = TabAutoTower:CreateDropdown({
    Name = "Deck (1–8)",
    Options = { "1", "2", "3", "4", "5", "6", "7", "8" },
    CurrentOption = tostring(Tower.deckSlot),
    Flag = "TOWER_Deck",
    Callback = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end; Tower.deckSlot = tonumber(opt) or 1
    end
})
TabAutoTower:CreateSlider({
    Name = "Delay Claim → Fight (s)",
    Range = { 0.1, 3 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = Tower.afterClaimWait,
    Flag = "TOWER_AfterClaim",
    Callback = function(v) Tower.afterClaimWait = v end
})
Tower.intervalSliderRef = TabAutoTower:CreateSlider({
    Name = "Fight Interval (s)",
    Range = { 0.5, 10 },
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = Tower.interval,
    Flag = "TOWER_Interval",
    Callback = function(v) Tower.interval = v end
})
Tower.toggleRef = TabAutoTower:CreateToggle({
    Name = "|📔| Auto Tower",
    CurrentValue = false,
    Flag = "TOWER_Toggle",
    Callback = function(state)
        Tower.enabled = state
        if not state then return end
        -- Tắt Auto Raid khác
        DisableOthers("TOWER")
        task.spawn(function()
            FireSafe(RE_Forfeit); task.wait(Tower.afterForfeitWait)
            while Tower.enabled do
                FireSafe(RE_ClaimInf, Tower.mode); task.wait(Tower.afterClaimWait)
                FireSafe(RE_SetPartySlot, ("slot_%d"):format(Tower.deckSlot or 1))
                task.wait(0.5) -- đợi 0.5s để server kịp nhận set deck
                FireSafe(RE_FightInf, Tower.mode)
                local t = 0; while Tower.enabled and t < Tower.interval do
                    task.wait(0.1); t += 0.1
                end
            end
        end)
    end
})

--=============================================================
--                     AUTO EXPLORATION
--=============================================================
TabAutoExploration:CreateSection("Global Delays")
AutoEX.controls.sliders.betweenActions = TabAutoExploration:CreateSlider({
    Name = "Delay Claim → Start (s)",
    Range = { 0.1, 3 },
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = AutoEX.betweenActions,
    Flag = "EX_betweenActions",
    Callback = function(v) AutoEX.betweenActions = v end
})
AutoEX.controls.sliders.betweenDifficulties = TabAutoExploration:CreateSlider({
    Name = "Delay Between Difficulties (s)",
    Range = { 0.2, 5 },
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = AutoEX.betweenDifficulties,
    Flag = "EX_betweenDiffs",
    Callback = function(v) AutoEX.betweenDifficulties = v end
})
AutoEX.controls.sliders.betweenCycles = TabAutoExploration:CreateSlider({
    Name = "Delay Between Cycles (s)",
    Range = { 1, 20 },
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = AutoEX.betweenCycles,
    Flag = "EX_betweenCycles",
    Callback = function(v) AutoEX.betweenCycles = v end
})

local function NormalizeRarity(r)
    if typeof(r) == "table" then r = r[1] end
    r = tostring(r or ""):lower()
    if not table.find(RARITIES, r) then r = "basic" end
    return r
end

local function BuildPicks(conf) -- returns {"name:rarity", x4} or nil,err
    local arr = {}
    for i = 1, 4 do
        local e = conf[i] or {}
        local nm = Trim(e.name); local rr = NormalizeRarity(e.rarity)
        if nm == "" then return nil, ("Thiếu tên thẻ #%d"):format(i) end
        table.insert(arr, nm .. ":" .. rr)
    end
    return arr
end

local function MakeExplorationUI(tab, diffKey)
    tab:CreateSection("Exploration – " .. string.upper(diffKey))
    AutoEX.controls.diffs[diffKey] = {}

    for i = 1, 4 do
        local ic = tab:CreateInput({
            Name = ("|🃏| Card Name #%d"):format(i),
            PlaceholderText = "vd: shadow_knight",
            RemoveTextAfterFocusLost = false,
            Flag = ("EX_%s_name_%d"):format(diffKey, i),
            CurrentValue = AutoEX.inputs[diffKey][i].name or "",
            Callback = function(txt) AutoEX.inputs[diffKey][i].name = txt or "" end
        })
        local dd = tab:CreateDropdown({
            Name = ("|🛠️| Rarity #%d"):format(i),
            Options = RARITIES,
            CurrentOption = AutoEX.inputs[diffKey][i].rarity or "basic",
            Flag = ("EX_%s_rarity_%d"):format(diffKey, i),
            Callback = function(opt)
                if typeof(opt) == "table" then opt = opt[1] end; AutoEX.inputs[diffKey][i].rarity = NormalizeRarity(opt)
            end
        })
        AutoEX.controls.diffs[diffKey][i] = { input = ic, dropdown = dd }
    end

    tab:CreateButton({
        Name = "Run Single: " .. string.upper(diffKey),
        Callback = function()
            if AutoEX._busy[diffKey] then
                warn("[Exploration] Đang chạy: " .. diffKey); return
            end
            AutoEX._busy[diffKey] = true
            task.spawn(function()
                FireSafe(RE_ClaimExpl, diffKey)
                task.wait(AutoEX.betweenActions)
                local picks, err = BuildPicks(AutoEX.inputs[diffKey])
                if picks then
                    FireSafe(RE_StartExpl, diffKey, picks)
                else
                    warn("[Exploration] " .. diffKey .. " lỗi: " .. tostring(err))
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
    Name = "|✈️| Auto Exploration",
    CurrentValue = false,
    Flag = "EX_AutoToggle",
    Callback = function(state)
        AutoEX.enabled = state
        if not state then return end
        task.spawn(function()
            while AutoEX.enabled do
                for _, diff in ipairs(DIFFICULTIES) do
                    if not AutoEX.enabled then break end
                    FireSafe(RE_ClaimExpl, diff)
                    task.wait(AutoEX.betweenActions)
                    local picks, err = BuildPicks(AutoEX.inputs[diff])
                    if picks then
                        FireSafe(RE_StartExpl, diff, picks)
                    else
                        warn("[Exploration] " ..
                            diff .. " lỗi: " .. tostring(err))
                    end
                    local t = 0; while AutoEX.enabled and t < AutoEX.betweenDifficulties do
                        task.wait(0.1); t += 0.1
                    end
                end
                local t = 0; while AutoEX.enabled and t < AutoEX.betweenCycles do
                    task.wait(0.1); t += 0.1
                end
            end
        end)
    end
})

--=============================================================
--                         CONFIG TAB
--=============================================================
local CONFIG_FOLDER = "AstralHub"

local function HH_EnsureFolder()
    if isfolder and not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end
HH_EnsureFolder()

local function HH_Path(file) return CONFIG_FOLDER .. "/" .. file end

local function HH_ListConfigs()
    local opts = {}
    if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
        for _, p in ipairs(listfiles(CONFIG_FOLDER)) do
            local name = p:match(".+[\\/](.+)$") or p
            if name and name:lower():match("%.json$") then
                table.insert(opts, name)
            end
        end
    end
    table.sort(opts)
    if #opts == 0 then return { "(no configs)" } end
    return opts
end

local function HH_SaveTableToJson(tbl, file)
    HH_EnsureFolder()
    local ok, data = pcall(HttpService.JSONEncode, HttpService, tbl)
    if not ok then
        -- warn("[HieuHub] JSONEncode error:", data)
        return false
    end
    if not writefile then
        -- warn("[HieuHub] Executor không hỗ trợ writefile")
        return false
    end
    writefile(HH_Path(file), data)
    -- print("[HieuHub] Saved:", HH_Path(file))
    return true
end

local function HH_LoadTableFromJson(file)
    local path = HH_Path(file)
    if not (isfile and isfile(path)) then
        -- warn("[HieuHub] Không tìm thấy:", path)
        return nil
    end
    if not readfile then
        -- warn("[HieuHub] Executor không hỗ trợ readfile")
        return nil
    end
    local data = readfile(path)
    local ok, tbl = pcall(HttpService.JSONDecode, HttpService, data)
    if not ok then
        -- warn("[HieuHub] JSONDecode error:", tbl)
        return nil
    end
    -- print("[HieuHub] Loaded:", path)
    return tbl
end

local function HH_CollectCurrentConfig()
    local cfg = {
        AutoRaid = { Bosses = {} },
        AutoExploration = {
            betweenActions = AutoEX.betweenActions,
            betweenDifficulties = AutoEX.betweenDifficulties,
            betweenCycles = AutoEX.betweenCycles,
            inputs = {},
        },
        AutoTower = {
            mode = Tower.mode,
            deckSlot = Tower.deckSlot,
            interval = Tower.interval,
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
                -- không tự bật toggle để an toàn
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
        if type(tbl.AutoTower.mode) == "string" then
            Tower.mode = tbl.AutoTower.mode
            if Tower.modeDropdownRef and Tower.modeDropdownRef.Set then Tower.modeDropdownRef:Set({ Tower.mode }) end
        end
        if type(tbl.AutoTower.deckSlot) == "number" then
            Tower.deckSlot = tbl.AutoTower.deckSlot
            if Tower.deckDropdownRef and Tower.deckDropdownRef.Set then
                Tower.deckDropdownRef:Set({ tostring(Tower
                    .deckSlot) })
            end
        end
        if type(tbl.AutoTower.interval) == "number" then
            Tower.interval = tbl.AutoTower.interval
            if Tower.intervalSliderRef and Tower.intervalSliderRef.Set then Tower.intervalSliderRef:Set(Tower.interval) end
        end
    end

    -- GlobalBoss
    if tbl.GlobalBoss then
        if type(tbl.GlobalBoss.deckSlot) == "number" then
            GlobalBoss.deckSlot = tbl.GlobalBoss.deckSlot
            if GlobalBoss.deckDropdownRef and GlobalBoss.deckDropdownRef.Set then
                GlobalBoss.deckDropdownRef:Set({
                    tostring(GlobalBoss.deckSlot) })
            end
        end
        if type(tbl.GlobalBoss.interval) == "number" then
            GlobalBoss.interval = tbl.GlobalBoss.interval
            if GlobalBoss.intervalSliderRef and GlobalBoss.intervalSliderRef.Set then
                GlobalBoss.intervalSliderRef:Set(
                    GlobalBoss.interval)
            end
        end
    end
end

--========================[ CONFIG UI ]========================
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
    if not pick or not table.find(opts, pick) then
        pick = opts[1]
    end
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

function HH_RefreshDropdown(selectName)
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
        if fn == "" then
            -- warn("[HieuHub] Vui lòng nhập tên file");
            return
        end
        if not fn:lower():match("%.json$") then fn = fn .. ".json" end
        HH_EnsureFolder()
        local path = HH_Path(fn)
        if isfile and isfile(path) then
            -- warn("[HieuHub] File đã tồn tại:", path);
            return
        end
        if HH_SaveTableToJson(HH_CollectCurrentConfig(), fn) then
            HH_RefreshDropdown(fn)
        end
    end
})

TabConfig:CreateSection("Select config")
HH_BuildDropdown(nil)

TabConfig:CreateButton({
    Name = "Reload Config List",
    Callback = function()
        HH_RefreshDropdown(SelectedFile)
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({ Title = "Notification", Content = "Reload Successful", Duration = 4, Image = "rewind" })
        end
    end
})

TabConfig:CreateSection("Actions")
TabConfig:CreateButton({
    Name = "|📁| Save to Selected Config",
    Callback = function()
        if not SelectedFile or SelectedFile == "" then
            -- warn("[HieuHub] Chưa chọn file");
            return
        end
        if HH_SaveTableToJson(HH_CollectCurrentConfig(), SelectedFile) then
            if Rayfield and Rayfield.Notify then
                Rayfield:Notify({ Title = "Notification", Content = "Save Successful", Duration = 4, Image = "rewind" })
            end
        end
    end
})
TabConfig:CreateButton({
    Name = "|⬇️| Load from Selected Config",
    Callback = function()
        if not SelectedFile or SelectedFile == "" then
            -- warn("[HieuHub] Chưa chọn file");
            return
        end
        local cfg = HH_LoadTableFromJson(SelectedFile)
        HH_ApplyConfig(cfg)
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({ Title = "Notification", Content = "Load Successful", Duration = 4, Image = "rewind" })
        end
    end
})

-- Delete support
local function HH_Delete(file)
    local path = HH_Path(file)
    if not (isfile and isfile(path)) then
        -- warn("[HieuHub] Không tìm thấy:", path);
        return false
    end
    if delfile then
        delfile(path); print("[HieuHub] Deleted:", path); return true
    else
        -- warn("[HieuHub] Executor không hỗ trợ delfile");
        return false
    end
end

local _deleteArmed = false
TabConfig:CreateButton({
    Name = "|❌| Delete Selected Config (Press Twice to Confirm)",
    Callback = function()
        if not SelectedFile or SelectedFile == "" or SelectedFile == "(no configs)" then
            -- warn("[HieuHub] Chưa chọn file hợp lệ để xóa");
            return
        end
        if not _deleteArmed then
            _deleteArmed = true
            if Rayfield and Rayfield.Notify then
                Rayfield:Notify({
                    Title = "Delete Confirmation",
                    Content = "Press Delete again within 5s to confirm: : " ..
                        SelectedFile,
                    Duration = 5,
                    Image = "rewind"
                })
            end
            task.delay(5, function() _deleteArmed = false end)
            return
        end
        _deleteArmed = false
        if HH_Delete(SelectedFile) then
            SelectedFile = nil; HH_RefreshDropdown(nil)
            if Rayfield and Rayfield.Notify then
                Rayfield:Notify({ Title = "Notification", Content = "Delete Successful", Duration = 4, Image = "rewind" })
            end
        end
    end
})

--=============================================================
--                         MISC TAB
--=============================================================
TabMisc:CreateSection("Miscellaneous Settings")
-- Auto Claim Box and Potion in Workspace

local Players = game:GetService("Players")
local WS = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function TouchPickups()
    local pickups = {}
    for _, obj in pairs(WS:GetChildren()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:match("^potion_%d+$") or name:match("^box_%d+$") then
                table.insert(pickups, obj)
            end
        end
    end
    return pickups
end

-- Hàm dịch chuyển
local function TeleportTo(obj)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and obj:FindFirstChild("PrimaryPart") then
        hrp.CFrame = obj.PrimaryPart.CFrame + Vector3.new(0, 5, 0) -- dịch lên 5 để tránh kẹt
    elseif hrp and obj.PrimaryPart then
        hrp.CFrame = obj.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
    elseif hrp then
        hrp.CFrame = obj:GetModelCFrame() + Vector3.new(0, 5, 0)
    end
end

-- Auto toggle
local autoClaim = false

TabMisc:CreateToggle({
    Name = "Auto Claim Box/Potion",
    CurrentValue = false,
    Flag = "AutoClaim",
    Callback = function(Value)
        autoClaim = Value
        if autoClaim then
            task.spawn(function()
                while autoClaim do
                    local pickups = TouchPickups()
                    for _, obj in ipairs(pickups) do
                        TeleportTo(obj)
                        task.wait(1) -- đứng lại 0.5s để server kịp detect "touch"
                    end
                    task.wait(2)     -- refresh danh sách mỗi 2s
                end
            end)
        end
    end
})

--=============================================================
--                     AUTO CLAIM QUEST
--=============================================================
local autoQuest = false

TabMisc:CreateToggle({
    Name = "Auto Claim Quest",
    CurrentValue = false,
    Flag = "AutoQuest",
    Callback = function(Value)
        autoQuest = Value
        if autoQuest then
            task.spawn(function()
                local questId = 1
                while autoQuest do
                    local args = { questId }
                    RE_ClaimDailyQuest:FireServer(unpack(args))
                    -- print("Claimed Quest", questId)

                    -- tăng questId, reset về 1 khi > 6
                    questId = questId + 1
                    if questId > 6 then
                        questId = 1
                    end

                    task.wait(2) -- thời gian delay giữa mỗi lần claim (tùy chỉnh)
                end
            end)
        end
    end
})

--=============================================================
--                     ANTI AFK
--=============================================================
local antiAFK = false
local VU = game:GetService("VirtualUser")
local Player = game:GetService("Players").LocalPlayer

TabMisc:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        antiAFK = Value
        if antiAFK then
            task.spawn(function()
                while antiAFK do
                    -- Khi server phát hiện Idle thì tự click chuột
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
