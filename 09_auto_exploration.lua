--=============================================================
-- BLOCK 9) FEATURE: AUTO EXPLORATION
--=============================================================
TabAutoExploration:CreateSection("Global Delays")

RARITIES     = { "basic", "gold", "rainbow", "secret" }
DIFFICULTIES = { "easy", "medium", "hard", "extreme", "nightmare", "celestial" }

AutoEX       = {
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
                    local picks = select(1, BuildPicks(AutoEX.inputs[diff]))
                    if picks then FireSafe(RE_StartExpl, diff, picks) end
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
