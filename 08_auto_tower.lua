--=============================================================
-- BLOCK 8) FEATURE: AUTO TOWER (Infinite) + WIN SUMMARY DETECTORS
--=============================================================
TabAutoTower:CreateSection("Auto Tower (Nightmare / Potion / Base)")

Tower = {
    enabled                   = false,
    mode                      = "nightmare",
    deckSlot                  = 1,
    useForfeitOnStart         = false,
    afterForfeitWait          = 0.25,
    interval                  = 2.0,

    -- pause spam (catch immediate post-win window to preserve floor)
    pauseSpamEnabled          = false,
    pauseSpamDelay            = 0.5,
    pauseSpamEvery            = 0.2,

    toggleRef                 = nil,
    deckDropdownRef           = nil,
    modeDropdownRef           = nil,
    intervalSliderRef         = nil,
    useForfeitToggleRef       = nil,
    pauseSpamEnabledToggleRef = nil,
    pauseSpamDelaySliderRef   = nil,
    pauseSpamEverySliderRef   = nil,
}

Tower.modeDropdownRef = TabAutoTower:CreateDropdown({
    Name          = "Mode",
    Options       = {
        "nightmare", "potion", "base", "ninja_village", "green_planet", "shibuya_station", "titans_city",
        "dimensional_fortress", "candy_island", "solo_city", "eminence_lookout", "invaded_ninja_village",
        "necromancer_graveyard"
    },
    CurrentOption = Tower.mode,
    Flag          = "TOWER_Mode",
    Callback      = function(opt)
        if typeof(opt) == "table" then opt = opt[1] end
        local newMode = tostring(opt or "nightmare")
        if Tower.enabled and newMode ~= Tower.mode then
            TryPauseInfinite(2.0, 0.15)
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

Tower.useForfeitToggleRef = TabAutoTower:CreateToggle({
    Name         = "Use Forfeit on Start (reset current battle)",
    CurrentValue = Tower.useForfeitOnStart,
    Flag         = "TOWER_UseForfeitOnStart",
    Callback     = function(v) Tower.useForfeitOnStart = v and true or false end
})

Tower.pauseSpamEnabledToggleRef = TabAutoTower:CreateToggle({
    Name         = "Pause Spam Enabled (preserve floor with pauseInfinite)",
    CurrentValue = Tower.pauseSpamEnabled,
    Flag         = "TOWER_PauseSpamEnabled",
    Callback     = function(v) Tower.pauseSpamEnabled = v and true or false end
})

Tower.pauseSpamDelaySliderRef = TabAutoTower:CreateSlider({
    Name         = "Pause Spam – Start After (s)",
    Range        = { 0, 8 },
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = Tower.pauseSpamDelay,
    Flag         = "TOWER_PauseSpamDelay",
    Callback     = function(v) Tower.pauseSpamDelay = v end
})

Tower.pauseSpamEverySliderRef = TabAutoTower:CreateSlider({
    Name         = "Pause Spam – Every (s)",
    Range        = { 0.1, 1.0 },
    Increment    = 0.05,
    Suffix       = "s",
    CurrentValue = Tower.pauseSpamEvery,
    Flag         = "TOWER_PauseSpamEvery",
    Callback     = function(v) Tower.pauseSpamEvery = v end
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
            TryPauseInfinite(2.0, 0.15)
        end
        Tower.enabled = state
        if not state then return end
        DisableOthers("TOWER")
        task.spawn(function()
            if Tower.useForfeitOnStart then
                ForfeitSafe(); task.wait(Tower.afterForfeitWait)
            end
            notify("Auto Tower", "Automation started.", 3, "tower-control")
            while Tower.enabled do
                FireSafe(RE_SetPartySlot, ("slot_%d"):format(Tower.deckSlot or 1))
                task.wait(0.5)
                FireSafe(RE_FightInf, Tower.mode)

                -- Spam pauseInfinite to catch post-win window without resetting floor
                local elapsed, spamTimer = 0, 0
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

--==================[ Win Summary Detectors ]==================--
-- Goal: Pause exactly when the Infinite Tower Summary pops (modal.current == 21)
local SummaryDetector = { enabled = true, debounceTs = 0, debounceGap = 1.0 }

local function TriggerPauseFromSummary()
    local now = os.clock()
    if now - (SummaryDetector.debounceTs or 0) < (SummaryDetector.debounceGap or 1.0) then return end
    SummaryDetector.debounceTs = now
    TryPauseInfinite(2.0, 0.15)
end

local function StartModalWatcher()
    local ok, producer = pcall(require, RS:WaitForChild("shared"):WaitForChild("producer"))
    if not ok or type(producer) ~= "table" then return end

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
            if cur == 21 then TriggerPauseFromSummary() end
            prevModal = cur
        end
    end

    if typeof(producer.changed) == "RBXScriptSignal" then
        producer.changed:Connect(check)
    elseif type(producer.subscribe) == "function" then
        producer.subscribe(check)
    else
        task.spawn(function()
            while true do
                check(); task.wait(0.05)
            end
        end)
    end
end

local function StartReactGuiWatcher()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local reactGui = pg:FindFirstChild("react")
    if not reactGui then
        pg.ChildAdded:Connect(function(child)
            if child.Name == "react" then reactGui = child end
        end)
    end

    local function isSummaryUi(inst)
        local n = string.lower(inst.Name or "")
        if n:find("summary") and (n:find("infinite") or n:find("tower")) then return true end
        local p, depth = inst.Parent, 0
        while p and depth < 4 do
            local pn = string.lower(p.Name or "")
            if pn:find("summary") and (pn:find("infinite") or pn:find("tower")) then return true end
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

task.spawn(StartModalWatcher)
task.spawn(StartReactGuiWatcher)
