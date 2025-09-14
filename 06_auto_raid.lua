--=============================================================
-- BLOCK 6) FEATURE: AUTO RAID (Boss/Minion)
--=============================================================
TabAutoRaid:CreateSection("Auto Raid")

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
            if not state then return end
            DisableOthers(key)
            task.spawn(function()
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
            if not state then return end
            DisableOthers(key)
            task.spawn(function()
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
