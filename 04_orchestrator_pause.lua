--=============================================================
-- BLOCK 4) ORCHESTRATOR (FORFEIT CONTROL) + PAUSE HELPERS
--=============================================================
Orchestrator = Orchestrator or {
    skipForfeitOnce  = false, -- skip the very next forfeit
    skipForfeitUntil = 0      -- block forfeits until this time
}

function ForfeitSafe()
    if Orchestrator.skipForfeitOnce then
        Orchestrator.skipForfeitOnce = false
        return false
    end
    if os.clock() < (Orchestrator.skipForfeitUntil or 0) then
        return false
    end
    FireSafe(RE_Forfeit)
    return true
end

-- Graceful Tower pause helper: spam pauseInfinite within a short window
function TryPauseInfinite(totalTime, every)
    totalTime     = tonumber(totalTime) or 2.0
    every         = math.max(tonumber(every) or 0.15, 0.05)
    local elapsed = 0
    while elapsed < totalTime do
        FireSafe(RE_PauseInf)
        task.wait(every)
        elapsed += every
    end
end
