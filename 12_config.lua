--=============================================================
-- BLOCK 12) CONFIG: Save / Load / Create / Delete (.json)
--=============================================================
local CONFIG_FOLDER = "AstralHub"

local function EnsureFolder()
    if isfolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end
EnsureFolder()

local function Path(file) return CONFIG_FOLDER .. "/" .. file end

local function ListConfigs()
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

local function SaveTableToJson(tbl, file)
    EnsureFolder()
    local ok, data = pcall(HttpService.JSONEncode, HttpService, tbl)
    if not ok or not writefile then return false end
    writefile(Path(file), data)
    return true
end

local function LoadTableFromJson(file)
    local path = Path(file)
    if not (isfile and isfile(path)) or not readfile then return nil end
    local data = readfile(path)
    local ok, tbl = pcall(HttpService.JSONDecode, HttpService, data)
    if not ok then return nil end
    return tbl
end

local function CollectCurrentConfig()
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
        },
        AutoStory = {
            deckSlot                = AutoStory.deckSlot,
            intervalBetweenPlays    = AutoStory.intervalBetweenPlays,
            outcomeTimeout          = AutoStory.outcomeTimeout,
            pollEvery               = AutoStory.pollEvery,
            chainNextOnCountdown    = AutoStory.chainNextOnCountdown,
            countdownCheckDelay     = AutoStory.countdownCheckDelay,
            countdownChildrenThresh = AutoStory.countdownChildrenThresh,
            retryDelayOnLost        = AutoStory.retryDelayOnLost,
            autoDismissAfterWin     = AutoStory.autoDismissAfterWin,
            autoDismissDelay        = AutoStory.autoDismissDelay,
            bossIds                 = AutoStory.bossIds,
            diffOrder               = AutoStory.diffOrder,
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

local function ApplyConfig(tbl)
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
        if type(tbl.AutoTower.useForfeitOnStart) == "boolean" then Tower.useForfeitOnStart = tbl.AutoTower
            .useForfeitOnStart end
        if type(tbl.AutoTower.pauseSpamEnabled) == "boolean" then Tower.pauseSpamEnabled = tbl.AutoTower
            .pauseSpamEnabled end
        if type(tbl.AutoTower.pauseSpamDelay) == "number" then Tower.pauseSpamDelay = tbl.AutoTower.pauseSpamDelay end
        if type(tbl.AutoTower.pauseSpamEvery) == "number" then Tower.pauseSpamEvery = tbl.AutoTower.pauseSpamEvery end

        if Tower.useForfeitToggleRef and Tower.useForfeitToggleRef.Set then Tower.useForfeitToggleRef:Set(Tower
            .useForfeitOnStart and true or false) end
        if Tower.pauseSpamEnabledToggleRef and Tower.pauseSpamEnabledToggleRef.Set then Tower.pauseSpamEnabledToggleRef
                :Set(Tower.pauseSpamEnabled and true or false) end
        if Tower.pauseSpamDelaySliderRef and Tower.pauseSpamDelaySliderRef.Set then Tower.pauseSpamDelaySliderRef:Set(
            Tower.pauseSpamDelay) end
        if Tower.pauseSpamEverySliderRef and Tower.pauseSpamEverySliderRef.Set then Tower.pauseSpamEverySliderRef:Set(
            Tower.pauseSpamEvery) end

        if type(tbl.AutoTower.mode) == "string" then
            Tower.mode = tbl.AutoTower.mode
            if Tower.modeDropdownRef and Tower.modeDropdownRef.Set then Tower.modeDropdownRef:Set({ Tower.mode }) end
        end
        if type(tbl.AutoTower.deckSlot) == "number" then
            Tower.deckSlot = tbl.AutoTower.deckSlot
            if Tower.deckDropdownRef and Tower.deckDropdownRef.Set then Tower.deckDropdownRef:Set({ tostring(Tower
                .deckSlot) }) end
        end
        if type(tbl.AutoTower.interval) == "number" then
            Tower.interval = tbl.AutoTower.interval
            if Tower.intervalSliderRef and Tower.intervalSliderRef.Set then Tower.intervalSliderRef:Set(Tower.interval) end
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
            if AutoStory.intervalSliderRef and AutoStory.intervalSliderRef.Set then AutoStory.intervalSliderRef:Set(
                AutoStory.intervalBetweenPlays) end
        end
        if type(S.outcomeTimeout) == "number" then
            AutoStory.outcomeTimeout = S.outcomeTimeout
            if AutoStory.outcomeTimeoutSliderRef and AutoStory.outcomeTimeoutSliderRef.Set then AutoStory
                    .outcomeTimeoutSliderRef:Set(AutoStory.outcomeTimeout) end
        end
        if type(S.pollEvery) == "number" then AutoStory.pollEvery = S.pollEvery end
        if type(S.chainNextOnCountdown) == "boolean" then
            AutoStory.chainNextOnCountdown = S.chainNextOnCountdown
            if AutoStory.chainToggleRef and AutoStory.chainToggleRef.Set then AutoStory.chainToggleRef:Set(AutoStory
                .chainNextOnCountdown and true or false) end
        end
        if type(S.countdownCheckDelay) == "number" then
            AutoStory.countdownCheckDelay = S.countdownCheckDelay
            if AutoStory.countdownDelaySliderRef and AutoStory.countdownDelaySliderRef.Set then AutoStory
                    .countdownDelaySliderRef:Set(AutoStory.countdownCheckDelay) end
        end
        if type(S.countdownChildrenThresh) == "number" then
            AutoStory.countdownChildrenThresh = S.countdownChildrenThresh
            if AutoStory.countdownThreshSliderRef and AutoStory.countdownThreshSliderRef.Set then AutoStory
                    .countdownThreshSliderRef:Set(AutoStory.countdownChildrenThresh) end
        end
        if type(S.retryDelayOnLost) == "number" then
            AutoStory.retryDelayOnLost = S.retryDelayOnLost
            if AutoStory.retryDelaySliderRef and AutoStory.retryDelaySliderRef.Set then AutoStory.retryDelaySliderRef
                    :Set(AutoStory.retryDelayOnLost) end
        end
        if type(S.autoDismissAfterWin) == "boolean" then
            AutoStory.autoDismissAfterWin = S.autoDismissAfterWin
            if AutoStory.dismissAfterWinToggleRef and AutoStory.dismissAfterWinToggleRef.Set then AutoStory
                    .dismissAfterWinToggleRef:Set(AutoStory.autoDismissAfterWin and true or false) end
        end
        if type(S.autoDismissDelay) == "number" then
            AutoStory.autoDismissDelay = S.autoDismissDelay
            if AutoStory.dismissDelaySliderRef and AutoStory.dismissDelaySliderRef.Set then AutoStory
                    .dismissDelaySliderRef:Set(AutoStory.autoDismissDelay) end
        end
        if type(S.bossIds) == "table" then
            AutoStory.bossIds  = S.bossIds
            AutoStory._bossIdx = 1; AutoStory._diffIdx = 1
            if AutoStory.bossDropdownRef then
                if AutoStory.bossDropdownRef.Set then AutoStory.bossDropdownRef:Set(AutoStory.bossIds) end
                if AutoStory.bossDropdownRef.Refresh and AutoStory.allBossIds then
                    AutoStory.bossDropdownRef:Refresh(AutoStory.allBossIds, AutoStory.bossIds)
                end
            end
        end
        if type(S.diffOrder) == "table" then AutoStory.diffOrder = S.diffOrder end
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

local function BuildDropdown(initialSelect)
    local opts = ListConfigs()
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

local function RefreshDropdown(selectName)
    local opts = ListConfigs()
    local pick = selectName
    if not pick or not table.find(opts, pick) then pick = opts[1] end
    if Dropdown_Config and Dropdown_Config.Refresh then
        Dropdown_Config:Refresh(opts, (pick ~= "(no configs)") and pick or true)
        if pick ~= "(no configs)" and Dropdown_Config.Set then
            Dropdown_Config:Set(pick)
            SelectedFile = pick
        else
            SelectedFile = nil
        end
    else
        BuildDropdown(pick)
    end
end

TabConfig:CreateButton({
    Name = "|🗃️| Create",
    Callback = function()
        local fn = (NewName:gsub("%s+", ""))
        if fn == "" then return end
        if not fn:lower():match("%.json$") then fn = fn .. ".json" end
        EnsureFolder()
        local path = CONFIG_FOLDER .. "/" .. fn
        if isfile and isfile(path) then return end
        if SaveTableToJson(CollectCurrentConfig(), fn) then
            RefreshDropdown(fn)
            notify("Config", "Created: " .. fn, 3, "badge-plus")
        end
    end
})

TabConfig:CreateSection("Select config")
BuildDropdown(nil)

TabConfig:CreateButton({
    Name = "Reload Config List",
    Callback = function()
        RefreshDropdown(SelectedFile)
        notify("Config", "Reload Successful", 3, "refresh-ccw")
    end
})

TabConfig:CreateSection("Actions")

TabConfig:CreateButton({
    Name = "|📁| Save to Selected Config",
    Callback = function()
        if not SelectedFile or SelectedFile == "" then return end
        if SaveTableToJson(CollectCurrentConfig(), SelectedFile) then
            notify("Config", "Save Successful", 3, "rewind")
        end
    end
})

TabConfig:CreateButton({
    Name = "|⬇️| Load from Selected Config",
    Callback = function()
        if not SelectedFile or SelectedFile == "" then return end
        local cfg = LoadTableFromJson(SelectedFile)
        ApplyConfig(cfg)
        notify("Config", "Load Successful", 3, "cog")
    end
})

local function DeleteConfig(file)
    local path = CONFIG_FOLDER .. "/" .. file
    if not (isfile and isfile(path)) then return false end
    if delfile then
        delfile(path); return true
    else return false end
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
        if DeleteConfig(SelectedFile) then
            SelectedFile = nil; RefreshDropdown(nil)
            notify("Config", "Delete Successful", 3, "trash")
        end
    end
})
