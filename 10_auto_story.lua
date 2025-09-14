--=============================================================
-- BLOCK 10) FEATURE: AUTO STORY (Chain difficulties, countdown, auto-dismiss)
--=============================================================
TabAutoStory:CreateSection("Auto Story – Chain Boss by Difficulties")

-- Small helpers for react UI
local function AS_GetReact()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return nil end
    return pg:FindFirstChild("react")
end

local function AS_GetBattleEndLabel()
    local react = AS_GetReact(); if not react then return nil end
    local bes = react:FindFirstChild("battleEndScreen"); if not bes then return nil end
    local f3 = bes:FindFirstChild("3"); if not f3 then return nil end
    local lbl = f3:FindFirstChild("2"); if not lbl then return nil end
    if lbl.ClassName == "TextLabel" or (typeof(lbl) == "Instance" and lbl:IsA("TextLabel")) then
        return lbl
    end
    return nil
end

local function AS_IsWin()
    local lbl = AS_GetBattleEndLabel(); if not lbl then return false end
    local txt = Trim(lbl.Text)
    return txt == "Victory"
end

local function AS_IsLost()
    local lbl = AS_GetBattleEndLabel(); if not lbl then return false end
    local txt = Trim(lbl.Text)
    return txt == "Defeat"
end

local function AS_NotificationsChildren()
    local react = AS_GetReact(); if not react then return 0 end
    local notifications = react:FindFirstChild("notifications"); if not notifications then return 0 end
    return CountChildrenSafe(notifications)
end

AutoStory = {
    enabled                  = false,
    deckSlot                 = 1,
    intervalBetweenPlays     = 1.0,
    outcomeTimeout           = 120.0,
    pollEvery                = 0.2,

    chainNextOnCountdown     = true,
    countdownCheckDelay      = 2.0, -- wait ~2s before checking notifications
    countdownChildrenThresh  = 2,

    retryDelayOnLost         = 1.0,

    autoDismissAfterWin      = true,
    autoDismissDelay         = 1.5,

    allBossIds               = { 308, 376, 331, 358, 458, 349, 322, 300, 363, 338 },
    bossIds                  = { 308, 376, 331 },

    diffOrder                = { "normal", "medium", "hard", "extreme" },

    _bossIdx                 = 1,
    _diffIdx                 = 1,

    -- UI handles
    toggleRef                = nil,
    deckDropdownRef          = nil,
    bossDropdownRef          = nil,
    intervalSliderRef        = nil,
    outcomeTimeoutSliderRef  = nil,
    retryDelaySliderRef      = nil,
    chainToggleRef           = nil,
    countdownDelaySliderRef  = nil,
    countdownThreshSliderRef = nil,
    dismissAfterWinToggleRef = nil,
    dismissDelaySliderRef    = nil,
}

local function AS_CurrentBossAndDiff()
    local bossId = AutoStory.bossIds[AutoStory._bossIdx]
    local diff   = AutoStory.diffOrder[AutoStory._diffIdx]
    return bossId, diff
end

local function AS_NextDifficultyOrBoss()
    AutoStory._diffIdx += 1
    if AutoStory._diffIdx > #AutoStory.diffOrder then
        AutoStory._diffIdx = 1
        AutoStory._bossIdx += 1
        if AutoStory._bossIdx > #AutoStory.bossIds then
            AutoStory._bossIdx = 1
        end
    end
end

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

AutoStory.bossDropdownRef = TabAutoStory:CreateDropdown({
    Name            = "Select Bosses",
    Options         = AutoStory.allBossIds,
    MultipleOptions = true,
    CurrentOption   = AutoStory.bossIds,
    Flag            = "STORY_BossSelection",
    Callback        = function(selected)
        if typeof(selected) == "table" then AutoStory.bossIds = selected else AutoStory.bossIds = { selected } end
        AutoStory._bossIdx, AutoStory._diffIdx = 1, 1
        notify("Auto Story", ("Selected bosses: %s"):format(table.concat(AutoStory.bossIds, ", ")), 3, "info")
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
    Name         = "Auto click to dismiss after WIN",
    CurrentValue = AutoStory.autoDismissAfterWin,
    Flag         = "STORY_AutoDismissAfterWin",
    Callback     = function(v) AutoStory.autoDismissAfterWin = v and true or false end
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
            AutoStory._bossIdx, AutoStory._diffIdx = 1, 1
            while AutoStory.enabled do
                local bossId, diff = AS_CurrentBossAndDiff()
                if not bossId then
                    notify("Auto Story", "No boss selected! Enable at least one boss.", 3, "alert-octagon")
                    break
                end

                -- Set deck & fight
                FireSafe(RE_SetPartySlot, ("slot_%d"):format(AutoStory.deckSlot or 1))
                task.wait(0.25)
                FireSafe(RE_FightStory, bossId, diff)
                notify("Auto Story", ("FIGHT boss %d @ %s"):format(tonumber(bossId or 0), tostring(diff)), 2, "swords")

                -- 1) COUNTDOWN fast-chain
                local chainedByCountdown = false
                if AutoStory.chainNextOnCountdown then
                    task.wait(AutoStory.countdownCheckDelay)
                    if AS_NotificationsChildren() > (AutoStory.countdownChildrenThresh or 2) then
                        local lastDiffIdx = AutoStory._diffIdx
                        AS_NextDifficultyOrBoss()
                        local _, nextDiff = AS_CurrentBossAndDiff()
                        local msg = (lastDiffIdx == #AutoStory.diffOrder) and "next boss" or nextDiff
                        notify("Auto Story", ("COUNTDOWN detected → queued next: %s"):format(msg), 2, "fast-forward")
                        chainedByCountdown = true
                    end
                end

                if not chainedByCountdown then
                    -- 2) Outcome wait
                    local t, outcome = 0, nil -- "win" | "lost" | nil
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
                        if AutoStory.autoDismissAfterWin then
                            task.spawn(function()
                                task.wait(AutoStory.autoDismissDelay or 1.5)
                                ClickAnywhereBottom()
                            end)
                        end
                        task.wait(1)
                        local lastWasExtreme = (AutoStory._diffIdx == #AutoStory.diffOrder)
                        AS_NextDifficultyOrBoss()
                        notify("Auto Story", lastWasExtreme and "WIN → next boss" or "WIN → next difficulty", 2, "trophy")
                    elseif outcome == "lost" then
                        notify("Auto Story", "LOST → retry same boss & difficulty", 2, "rotate-ccw")
                        task.wait(AutoStory.retryDelayOnLost or 1.0)
                        -- pointers unchanged → loop retries
                    else
                        -- timeout fallback: advance so we don't get stuck
                        AS_NextDifficultyOrBoss()
                    end
                end

                -- pacing between plays
                local t2 = 0
                while AutoStory.enabled and t2 < (AutoStory.intervalBetweenPlays or 1.0) do
                    task.wait(0.1); t2 += 0.1
                end
            end
        end)
    end
})
