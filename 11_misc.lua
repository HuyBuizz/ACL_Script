--=============================================================
-- BLOCK 11) FEATURE: MISC (Auto Claim, Auto Quest, Anti-AFK)
--=============================================================
TabMisc:CreateSection("Miscellaneous Settings")

-- Auto Claim Box/Potion (teleport & touch)
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
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
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
    Callback     = function(v)
        autoClaim = v
        if not autoClaim then return end
        DisableAllAutoRaid()
        task.spawn(function()
            notify("Auto Claim", "Enabled", 2, "rewind")
            while autoClaim do
                for _, obj in ipairs(TouchPickups()) do
                    TeleportTo(obj)
                    task.wait(1)
                end
                task.wait(2)
            end
        end)
    end
})

-- Auto Claim Daily Quests
local autoQuest = false
TabMisc:CreateToggle({
    Name         = "Auto Claim Quest",
    CurrentValue = false,
    Flag         = "AutoQuest",
    Callback     = function(v)
        autoQuest = v
        if not autoQuest then return end
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
})

-- Anti AFK
local antiAFK = false
local VU      = game:GetService("VirtualUser")
TabMisc:CreateToggle({
    Name         = "Anti AFK",
    CurrentValue = false,
    Flag         = "AntiAFK",
    Callback     = function(v)
        antiAFK = v
        if not antiAFK then return end
        task.spawn(function()
            notify("Anti AFK", "Enabled", 2, "rewind")
            while antiAFK do
                LocalPlayer.Idled:Wait()
                if antiAFK then
                    VU:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(0.5)
                    VU:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end
            end
        end)
    end
})
