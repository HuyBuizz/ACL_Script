--=============================================================
-- BLOCK 5) CROSS-FEATURE KILL-SWITCH
--=============================================================
BossAutos  = BossAutos or {}  -- Auto Raid buckets
Tower      = Tower or {}      -- defined in Block 8
GlobalBoss = GlobalBoss or {} -- defined in Block 7
AutoStory  = AutoStory or {}  -- defined in Block 10

function DisableAllAutoRaid()
    for _, s in pairs(BossAutos) do
        if s.enabled and s.toggleRef and s.toggleRef.Set then
            s.toggleRef:Set(false)
        end
    end
end

function DisableOthers(exceptKey)
    -- Auto Raid entries
    for key, s in pairs(BossAutos) do
        if key ~= exceptKey and s.enabled and s.toggleRef and s.toggleRef.Set then
            s.toggleRef:Set(false)
        end
    end
    -- Global Boss
    if exceptKey ~= "GLOBAL" and GlobalBoss.enabled and GlobalBoss.toggleRef and GlobalBoss.toggleRef.Set then
        GlobalBoss.toggleRef:Set(false)
    end
    -- Tower
    if exceptKey ~= "TOWER" and Tower.enabled and Tower.toggleRef and Tower.toggleRef.Set then
        TryPauseInfinite(2.0, 0.15)
        Orchestrator.skipForfeitOnce  = true
        Orchestrator.skipForfeitUntil = os.clock() + 3.0
        Tower.toggleRef:Set(false)
    end
    -- Story
    if exceptKey ~= "STORY" and AutoStory and AutoStory.enabled and AutoStory.toggleRef and AutoStory.toggleRef.Set then
        AutoStory.toggleRef:Set(false)
    end
end
