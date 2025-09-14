--=============================================================
-- BLOCK 7) FEATURE: MAIN (GLOBAL BOSS)
--=============================================================
TabMain:CreateSection("Auto Global Boss")

GlobalBoss = {
    enabled           = false,
    deckSlot          = 1,
    afterForfeitWait  = 0.25,
    interval          = 2.0,
    bossId            = 446,

    toggleRef         = nil,
    deckDropdownRef   = nil,
    intervalSliderRef = nil,
}

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
        if not state then return end
        DisableOthers("GLOBAL")
        task.spawn(function()
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
})
