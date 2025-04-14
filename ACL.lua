local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Anime Card Clash - HieuHUB",
    Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by DuckHieu",
    Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil, -- Create a custom folder for your hub/game
        FileName = "Big Hub"
    },

    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },

    KeySystem = false -- Set this to true to use our key system
})
-- ─────────────────────────────────────────────────────────────────────────
-- ─██████──────────██████─██████████████─██████████─██████──────────██████─
-- ─██░░██████████████░░██─██░░░░░░░░░░██─██░░░░░░██─██░░██████████──██░░██─
-- ─██░░░░░░░░░░░░░░░░░░██─██░░██████░░██─████░░████─██░░░░░░░░░░██──██░░██─
-- ─██░░██████░░██████░░██─██░░██──██░░██───██░░██───██░░██████░░██──██░░██─
-- ─██░░██──██░░██──██░░██─██░░██████░░██───██░░██───██░░██──██░░██──██░░██─
-- ─██░░██──██░░██──██░░██─██░░░░░░░░░░██───██░░██───██░░██──██░░██──██░░██─
-- ─██░░██──██████──██░░██─██░░██████░░██───██░░██───██░░██──██░░██──██░░██─
-- ─██░░██──────────██░░██─██░░██──██░░██───██░░██───██░░██──██░░██████░░██─
-- ─██░░██──────────██░░██─██░░██──██░░██─████░░████─██░░██──██░░░░░░░░░░██─
-- ─██░░██──────────██░░██─██░░██──██░░██─██░░░░░░██─██░░██──██████████░░██─
-- ─██████──────────██████─██████──██████─██████████─██████──────────██████─
-- ─────────────────────────────────────────────────────────────────────────
local function ExportMinimalCardData()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local cardsModule = require(ReplicatedStorage.TS.card.cards)

    local function extractMinimalCardData(cards)
        local result = {}

        for key, card in pairs(cards) do
            result[tostring(key)] = {
                name = card.name,
                index = card.index,
                denominator = card.denominator,
                id = card.id,
                pureId = card.pureId,
                isSupport = card.isSupport,
                support = card.support,
                stats = card.stats and {
                    DAMAGE = card.stats.DAMAGE,
                    HEALTH = card.stats.HEALTH
                } or nil
            }
        end

        return result
    end

    local function exportToJSON(data, fileName)
        local folderPath = "ACL/DATA"
        if not isfolder("ACL") then
            makefolder("ACL")
        end
        if not isfolder(folderPath) then
            makefolder(folderPath)
        end

        local success, encoded = pcall(function()
            return HttpService:JSONEncode(data)
        end)

        if success then
            writefile(folderPath .. "/" .. fileName, encoded)
            print("✅ Đã xuất JSON tại:", folderPath .. "/" .. fileName)
        else
            warn("❌ Không thể encode JSON:", encoded)
        end
    end

    if cardsModule and cardsModule.Cards then
        local minimalData = extractMinimalCardData(cardsModule.Cards)
        exportToJSON(minimalData, "cards_only.json")
    else
        warn("⚠️ Không tìm thấy cardsModule.Cards")
    end
end

ExportMinimalCardData()
-- ▀▀█▀▀ ─█▀▀█ ░█─▄▀ ░█▀▀▀ 　 ░█▀▀▄ ─█▀▀█ ▀▀█▀▀ ─█▀▀█
-- ─░█── ░█▄▄█ ░█▀▄─ ░█▀▀▀ 　 ░█─░█ ░█▄▄█ ─░█── ░█▄▄█
-- ─░█── ░█─░█ ░█─░█ ░█▄▄▄ 　 ░█▄▄▀ ░█─░█ ─░█── ░█─░█

local vim = game:GetService("VirtualInputManager")

local function pressKey(keyCode)
    vim:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.1) -- giữ phím một chút
    vim:SendKeyEvent(false, keyCode, false, game)
end


-- /////////////////////////////////////////////////////////////////////////////

local function OpenExplorationUI()
    local prompt = workspace:FindFirstChild("lobby") and workspace.lobby:FindFirstChild("npc") and
        workspace.lobby.npc:FindFirstChild("exploration") and
        workspace.lobby.npc.exploration:FindFirstChild("HumanoidRootPart") and
        workspace.lobby.npc.exploration.HumanoidRootPart:FindFirstChildWhichIsA("ProximityPrompt")

    if prompt then
        fireproximityprompt(prompt)
        task.wait(1.5)
    end
end

local explorationData = {} -- Biến toàn cục để lưu dữ liệu exploration

local function TakeDataExploration()
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")

    -- Hàm loại bỏ thẻ HTML như <b>...</b>
    local function stripHTML(str)
        return str:gsub("<.->", ""):match("^%s*(.-)%s*$")
    end

    -- Truy cập ScrollingFrame
    local scrollingFrame = Players.LocalPlayer.PlayerGui.exploration.Transition.Frame.Frame:GetChildren()[2].Frame.Frame
        .Frame.ScrollingFrame

    -- Gom các TextButton lại với LayoutOrder
    local buttonsWithLayer = {}

    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
            table.insert(buttonsWithLayer, {
                button = child,
                layerOrder = child.LayoutOrder
            })
        end
    end

    -- Sắp xếp theo LayoutOrder
    table.sort(buttonsWithLayer, function(a, b)
        return a.layerOrder < b.layerOrder
    end)

    -- Mảng gốc chứa raw text
    local explorationList = {}

    for _, item in ipairs(buttonsWithLayer) do
        local textButton = item.button
        local layer = item.layerOrder

        local challengeData = {
            layerOrder = layer,
            details = {}
        }

        for _, subChild in ipairs(textButton:GetChildren()) do
            if subChild:IsA("TextLabel") then
                local lines = string.split(subChild.Text, "\n")
                for _, line in ipairs(lines) do
                    if not string.find(line:lower(), "click to see details") then
                        table.insert(challengeData.details, line)
                    end
                end
            end
        end

        table.insert(explorationList, challengeData)
    end

    -- Biến lưu kết quả cuối cùng theo định dạng mong muốn
    explorationData = {}

    for _, entry in ipairs(explorationList) do
        local details = entry.details
        if #details >= 3 then
            local difficulty = stripHTML(details[1])
            local rarity = ""
            local duration = ""
            local remainingtime = ""

            for _, line in ipairs(details) do
                local cleanLine = stripHTML(line):lower()

                if cleanLine:find("minimum required rarity") then
                    rarity = line:match(":%s*<b>(.-)</b>") or stripHTML(line:match(":%s*(.+)"))
                elseif cleanLine:find("duration") then
                    duration = line:match(":%s*<b>(.-)</b>") or stripHTML(line:match(":%s*(.+)"))
                elseif cleanLine:find("ends in") then
                    -- remainingtime = line:match("<b>(.-)</b>") or stripHTML(line:match("in%s*(.+)"))
                    local timeText = line:match("<b>(.-)</b>") or stripHTML(line:match("in%s*(.+)"))
                    if timeText then
                        local hours = tonumber(timeText:match("(%d+)h")) or 0
                        local minutes = tonumber(timeText:match("(%d+)m")) or 0
                        local seconds = tonumber(timeText:match("(%d+)s")) or 0
                        remainingtime = tostring(hours * 3600 + minutes * 60 + seconds)
                    end
                elseif cleanLine == "available" then
                    remainingtime = "AVAILABLE"
                elseif cleanLine == "ready to claim" then
                    remainingtime = "READY TO CLAIM"
                end
            end

            explorationData[difficulty] = {
                difficulty = difficulty,
                minimumrequired = rarity,
                duration = duration,
                remainingtime = remainingtime
            }
        end
    end

    -- In ra màn hình nội dung của explorationData
    -- for difficulty, data in pairs(explorationData) do
    --     print("Difficulty: " .. difficulty)
    --     print("  Minimum Required Rarity: " .. (data.minimumrequired or "N/A"))
    --     print("  Duration: " .. (data.duration or "N/A"))
    --     print("  Remaining Time: " .. (data.remainingtime or "N/A"))
    --     print("-----------------------------")
    -- end

    -- -- Chuyển sang JSON
    -- local jsonResult = HttpService:JSONEncode(explorationData)

    -- -- Ghi vào file
    -- local fileName = "explorationObjectData.json"
    -- writefile(fileName, jsonResult)

    -- print("✅ Dữ liệu đã được lưu vào file: " .. fileName)

    pressKey(Enum.KeyCode.BackSlash)
    task.wait(0.1) -- đợi một chút
    pressKey(Enum.KeyCode.Return)
    -- task.spawn(UpdateParagraphInfo)
end

local function UpdateRemainingTime()
    local lastUpdate = os.time() -- thời gian thực (UNIX timestamp)
    while true do
        local currentTime = os.time()
        local elapsedTime = currentTime - lastUpdate
        if elapsedTime >= 1 then
            for _, data in pairs(explorationData) do
                if tonumber(data.remainingtime) then
                    local timeLeft = tonumber(data.remainingtime)
                    if timeLeft > 0 then
                        timeLeft = timeLeft - elapsedTime
                        if timeLeft <= 0 then
                            data.remainingtime = "READY TO CLAIM"
                        else
                            data.remainingtime = tostring(timeLeft)
                        end
                    end
                end
            end
            lastUpdate = currentTime
        end
        task.wait(0.2)
    end
end

local function formatCardName(name)
    -- Chuyển chữ thường, loại bỏ khoảng trắng đầu/cuối
    name = name:lower():gsub("^%s*(.-)%s*$", "%1")
    -- Thay dấu cách bằng dấu gạch dưới
    name = name:gsub("%s+", "_")
    -- Loại bỏ ký tự đặc biệt (nếu cần, tuỳ yêu cầu game)
    name = name:gsub("[^a-z0-9_]", "")
    return name
end

local Main = Window:CreateTab("MAIN", 4483362458)
local Paragraph = Main:CreateParagraph({
    Title = "DATA",
    Content = "Lấy dữ liệu về EXPLORATION."
})
local Button = Main:CreateButton({
    Name = "Take Data Exploration",
    Callback = function()
        OpenExplorationUI()
        TakeDataExploration()
        -- UpdateRemainingTime()
        -- ExportMinimalCardData()
    end
})

task.spawn(function()
    task.wait(1)
    print("🔄 Đang tự động lấy dữ liệu Exploration...")

    OpenExplorationUI()

    task.wait(1)

    TakeDataExploration()

    task.spawn(UpdateRemainingTime)

    print("✅ Dữ liệu Exploration đã được lấy tự động.")
end)

local Divider = Main:CreateDivider()
-- ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
-- ─██████████████─████████──████████─██████████████─██████─────────██████████████─████████████████───██████████████─██████████████─██████████─██████████████─██████──────────██████─
-- ─██░░░░░░░░░░██─██░░░░██──██░░░░██─██░░░░░░░░░░██─██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░██─██░░██████████──██░░██─
-- ─██░░██████████─████░░██──██░░████─██░░██████░░██─██░░██─────────██░░██████░░██─██░░████████░░██───██░░██████░░██─██████░░██████─████░░████─██░░██████░░██─██░░░░░░░░░░██──██░░██─
-- ─██░░██───────────██░░░░██░░░░██───██░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██────██░░██───██░░██──██░░██─────██░░██───────██░░██───██░░██──██░░██─██░░██████░░██──██░░██─
-- ─██░░██████████───████░░░░░░████───██░░██████░░██─██░░██─────────██░░██──██░░██─██░░████████░░██───██░░██████░░██─────██░░██───────██░░██───██░░██──██░░██─██░░██──██░░██──██░░██─
-- ─██░░░░░░░░░░██─────██░░░░░░██─────██░░░░░░░░░░██─██░░██─────────██░░██──██░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░██─────██░░██───────██░░██───██░░██──██░░██─██░░██──██░░██──██░░██─
-- ─██░░██████████───████░░░░░░████───██░░██████████─██░░██─────────██░░██──██░░██─██░░██████░░████───██░░██████░░██─────██░░██───────██░░██───██░░██──██░░██─██░░██──██░░██──██░░██─
-- ─██░░██───────────██░░░░██░░░░██───██░░██─────────██░░██─────────██░░██──██░░██─██░░██──██░░██─────██░░██──██░░██─────██░░██───────██░░██───██░░██──██░░██─██░░██──██░░██████░░██─
-- ─██░░██████████─████░░██──██░░████─██░░██─────────██░░██████████─██░░██████░░██─██░░██──██░░██████─██░░██──██░░██─────██░░██─────████░░████─██░░██████░░██─██░░██──██░░░░░░░░░░██─
-- ─██░░░░░░░░░░██─██░░░░██──██░░░░██─██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░░░░░██─██░░██──██░░██─────██░░██─────██░░░░░░██─██░░░░░░░░░░██─██░░██──██████████░░██─
-- ─██████████████─████████──████████─██████─────────██████████████─██████████████─██████──██████████─██████──██████─────██████─────██████████─██████████████─██████──────────██████─
-- ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

-- ░█▀▀▄ ░█▀▀▀ ░█─── ░█▀▀▀█ ░█──░█
-- ░█─░█ ░█▀▀▀ ░█─── ░█──░█ ░█▄▄▄█
-- ░█▄▄▀ ░█▄▄▄ ░█▄▄█ ░█▄▄▄█ ──░█──
local HttpService = game:GetService("HttpService")
local isClaiming = false -- Cờ kiểm soát trạng thái CLAIM
-- Đọc dữ liệu từ file JSON
local function loadCardData()
    local filePath = "ACL/DATA/cards_only.json"
    if isfile(filePath) then
        local jsonContent = readfile(filePath)
        return HttpService:JSONDecode(jsonContent)
    else
        warn("❌ Không tìm thấy file cards_only.json")
        return {}
    end
end

local cardData = loadCardData()

local function getDenominator(cardId)
    for _, data in pairs(cardData) do
        if data.id == cardId then
            return data.denominator
        end
    end
    return 0
end

-- -- Hàm chuyển tên nhập thành định dạng card chuẩn (vd: "fire dragon" -> "fire_dragon")
-- local function formatCardName(name)
--     return string.lower(name):gsub("%s+", "_")
-- end

-- Yêu cầu tối thiểu theo độ khó
local minimumRequired = {
    easy = 10000,
    medium = 1000000,
    hard = 10000000,
    extreme = 100000000,
    nightmare = 1000000000
}

-- UI Rayfield
local Exploration = Window:CreateTab("EXPLORATION", 4483362458)

local ParagraphInfo = Exploration:CreateParagraph({
    Title = "📊 INFORMATION",
    Content = "🔄 Loading data..."
})

-- Hàm chuyển đổi thời gian từ giây sang định dạng h m s
local function formatTime(seconds)
    seconds = tonumber(seconds) or 0
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02dh %02dm %02ds", hours, minutes, secs)
end

local function UpdateParagraphInfo()
    while true do
        local content = "📋 Exploration Status\n\n"

        -- Duyệt qua từng độ khó và lấy remainingtime
        for difficulty, data in pairs(explorationData) do
            local timeText = data.remainingtime or "N/A"

            -- Chuyển đổi thời gian nếu remainingtime là số
            if tonumber(timeText) then
                timeText = formatTime(tonumber(timeText))
            end

            content = content .. "🌟 " .. difficulty .. ": `" .. timeText .. "`\n"
        end

        -- Cập nhật nội dung của ParagraphInfo
        ParagraphInfo:Set({
            Title = "📊 INFORMATION",
            Content = content
        })

        task.wait(1) -- Cập nhật mỗi giây
    end
end

local Paragraph = Exploration:CreateParagraph({
    Title = "DELOY",
    Content = "Deploy thẻ vào từng độ khó tương ứng."
})

local difficulties = { "EASY", "MEDIUM", "HARD", "EXTREME", "NIGHTMARE" }
local rarities = { "basic", "gold", "rainbow", "secret" }
local deployInputs = {} -- key: difficulty, value: {cardInputs = {}, rarityDropdowns = {}}

for _, difficulty in ipairs(difficulties) do
    local section = Exploration:CreateSection("🔄 Deploy - " .. difficulty)
    local cardInputs = {}
    local rarityDropdowns = {}

    -- Gắn dữ liệu input + dropdown vào deployInputs
    deployInputs[difficulty] = {
        cardInputs = cardInputs,
        rarityDropdowns = rarityDropdowns
    }

    for i = 1, 4 do
        table.insert(cardInputs, Exploration:CreateInput({
            Name = "🃏 Card " .. i .. " Name",
            PlaceholderText = "Enter card name",
            RemoveTextAfterFocusLost = false,
            Callback = function(value)
                cardInputs[i].Value = value
            end
        }))

        table.insert(rarityDropdowns, Exploration:CreateDropdown({
            Name = "↘️ Card " .. i .. " Rarity",
            Options = rarities,
            CurrentOption = { "basic" },
            MultipleOptions = false,
            Callback = function(option)
                local value
                if type(option) == "table" then
                    value = option.Name or option.Value or option[1]
                elseif type(option) == "string" then
                    value = option
                end
                rarityDropdowns[i].Value = tostring(value or "basic")
            end
        }))
    end

    Exploration:CreateButton({
        Name = "Deploy to " .. difficulty,
        Callback = function()
            local difficultyKey = string.lower(difficulty)
            local minRequired = minimumRequired[difficultyKey]
            local args = { difficultyKey, {} }

            for i = 1, 4 do
                local rawName = cardInputs[i].Value or ""
                local name = formatCardName(rawName)
                local rarity = rarityDropdowns[i].Value or "basic"

                -- print("🔍 Card Input " .. i .. ":", rawName)
                -- print("🔍 Formatted Name:", name)
                -- print("🔍 Rarity:", rarity)

                local fullId = (rarity == "basic") and name or (name .. ":" .. rarity)
                -- print("🔍 FullId:", fullId)

                local denom = getDenominator(fullId)
                -- print("Thẻ '" .. fullId .. "' có denominator: " .. denom)

                -- Nếu denom = 0, chỉ Notify và dừng lại
                if denom == 0 then
                    Rayfield:Notify({
                        Title = "Card Not Found",
                        Content = "The card ID **'" .. fullId ..
                            "'** does not exist in the data. Please check the card name and rarity.",
                        Duration = 6.5,
                        Image = "AlertCircle" -- Lucide Icon for warning
                    })
                    return                    -- Dừng lại nếu không tìm thấy cardId
                end

                if denom < minRequired then
                    -- warn("⚠️ Thẻ '" .. fullId .. "' không đủ sức mạnh để deploy vào " .. difficulty)
                    Rayfield:Notify({
                        Title = "Not Enough Denom",
                        Content = "Thẻ '" .. fullId .. "' không đủ sức mạnh để deploy vào " .. difficulty,
                        Duration = 6.5,
                        Image = "triangle-alert"
                    })
                    return
                end

                table.insert(args[2], fullId)
            end

            game:GetService("ReplicatedStorage"):WaitForChild("JZ0")
                :WaitForChild("171e5a3a-8c09-493b-8c8e-c1f2cf4376bd"):FireServer(unpack(args))

            print("✅ Deploy sent for", difficulty)
        end
    })
    local Divider = Exploration:CreateDivider()

    -- local testCardId = "green_bomber:secret"
    -- local denom = getDenominator(testCardId)
    -- print("Denominator for '" .. testCardId .. "': " .. denom)
end

-- ─█▀▀█ ░█─░█ ▀▀█▀▀ ░█▀▀▀█ 　 ░█▀▀▄ ░█▀▀▀ ░█─── ░█▀▀▀█ ░█──░█
-- ░█▄▄█ ░█─░█ ─░█── ░█──░█ 　 ░█─░█ ░█▀▀▀ ░█─── ░█──░█ ░█▄▄▄█
-- ░█─░█ ─▀▄▄▀ ─░█── ░█▄▄▄█ 　 ░█▄▄▀ ░█▄▄▄ ░█▄▄█ ░█▄▄▄█ ──░█──
local Paragraph = Exploration:CreateParagraph({
    Title = "AUTO DELOY",
    Content = "Tự động triển khai thẻ vào từng độ khó tương ứng."
})

-- Tạo Toggle cho Auto Deploy
local autoDeployEnabled = false
local autoDeployTask = nil

-- Hàm chuyển đổi thời gian từ định dạng "6h", "2d", "5m" thành giây
local function convertDurationToSeconds(duration)
    local hours, days, minutes = 0, 0, 0

    -- Kiểm tra xem duration có phải là dạng "6h", "2d", "5m" hay không và phân tích nó
    if string.match(duration, "h$") then
        hours = tonumber(string.match(duration, "(%d+)h")) or 0
    elseif string.match(duration, "d$") then
        days = tonumber(string.match(duration, "(%d+)d")) or 0
    elseif string.match(duration, "m$") then
        minutes = tonumber(string.match(duration, "(%d+)m")) or 0
    end

    -- Tính ra giây từ giờ, ngày và phút
    return (days * 24 * 3600) + (hours * 3600) + (minutes * 60)
end

local function startAutoDeployTask()
    autoDeployTask = task.spawn(function()
        print("🟢 AutoDeploy task đã bắt đầu!")

        local deployQueue = {}

        while autoDeployEnabled do
            -- Nếu CLAIM đang hoạt động, chờ 1 giây rồi kiểm tra lại
            if isClaiming then
                task.wait(2)
            else
                -- Các logic khác ở đây...
            end

            -- Nếu hàng đợi trống, quét explorationData để tìm các nhiệm vụ AVAILABLE
            if #deployQueue == 0 then
                for difficulty, data in pairs(explorationData) do
                    if data.remainingtime == "AVAILABLE" then
                        table.insert(deployQueue, difficulty)
                    end
                end
            end

            -- Nếu có nhiệm vụ trong hàng đợi thì xử lý từng cái một
            if #deployQueue > 0 then
                local difficulty = table.remove(deployQueue, 1)
                local data = explorationData[difficulty]
                local success = true
                local difficultyKey = string.lower(difficulty)
                local minRequired = minimumRequired[difficultyKey]
                local args = { difficultyKey, {} }

                for i = 1, 4 do
                    local rawName = deployInputs[difficulty].cardInputs[i].Value or ""
                    local name = formatCardName(rawName)
                    local rarity = deployInputs[difficulty].rarityDropdowns[i].Value or "basic"
                    local fullId = (rarity == "basic") and name or (name .. ":" .. rarity)
                    local denom = getDenominator(fullId)

                    if denom == 0 or denom < minRequired then
                        success = false
                        break
                    end

                    table.insert(args[2], fullId)
                end

                if success then
                    game:GetService("ReplicatedStorage"):WaitForChild("JZ0"):WaitForChild(
                        "171e5a3a-8c09-493b-8c8e-c1f2cf4376bd"):FireServer(unpack(args))
                    task.wait(0.3)
                    print("✅ Deploy sent for", difficulty)
                    Rayfield:Notify({
                        Title = "Auto Deploy",
                        Content = "Đã triển khai thẻ vào độ khó: " .. difficulty,
                        Duration = 4,
                        Image = "check"
                    })

                    local durationInSeconds = convertDurationToSeconds(data.duration) + 6
                    data.remainingtime = durationInSeconds
                end
            end

            task.wait(1)
        end

        print("🔴 AutoDeploy task đã dừng!")
        autoDeployTask = nil
    end)
end

-- Toggle UI để bật/tắt Auto Deploy
Exploration:CreateToggle({
    Name = "⚙️ Auto Deploy",
    CurrentValue = false,
    Callback = function(state)
        autoDeployEnabled = state
        print("⚙️ AutoDeploy hiện tại:", autoDeployEnabled and "🟢 BẬT" or "🔴 TẮT")

        if autoDeployEnabled then
            -- Kiểm tra xem có dữ liệu exploration không và bắt đầu auto deploy task
            if next(explorationData) ~= nil then
                startAutoDeployTask()
            else
                print("❌ Không có dữ liệu exploration. Không thể triển khai tự động.")
            end
        else
            -- Dừng auto deploy nếu tắt toggle
            if autoDeployTask then
                print("🛑 Tắt AutoDeploy.")
                autoDeployEnabled = false
                task.cancel(autoDeployTask)
                autoDeployTask = nil
            end
        end
    end
})

local Divider = Exploration:CreateDivider()

-- ─█▀▀█ ░█─░█ ▀▀█▀▀ ░█▀▀▀█ 　 ░█▀▀█ ░█─── ─█▀▀█ ▀█▀ ░█▀▄▀█
-- ░█▄▄█ ░█─░█ ─░█── ░█──░█ 　 ░█─── ░█─── ░█▄▄█ ░█─ ░█░█░█
-- ░█─░█ ─▀▄▄▀ ─░█── ░█▄▄▄█ 　 ░█▄▄█ ░█▄▄█ ░█─░█ ▄█▄ ░█──░█

local autoClaimEnabled = false
local autoClaimTask = nil

local function claimMission(info)
    isClaiming = true -- Bắt đầu CLAIM
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local args = { info.difficulty:lower() }

    local claimEvent = replicatedStorage:WaitForChild("JZ0"):WaitForChild("4964b823-bc36-4e56-a57e-8531f145d655")
    claimEvent:FireServer(unpack(args))

    print("✅ → Đã claim nhiệm vụ:", info.difficulty)
    explorationData[info.difficulty].remainingtime = "AVAILABLE"
    task.wait(1)
    isClaiming = false -- Kết thúc CLAIM
end

-- local function startAutoClaimTask()
--     if autoClaimTask then
--         return
--     end

--     autoClaimTask = task.spawn(function()
--         print("🟢 AutoClaim task đã bắt đầu!")

--         local claimQueue = {}

--         while autoClaimEnabled do
--             -- Nếu hàng đợi trống thì quét dữ liệu để tìm các nhiệm vụ READY TO CLAIM
--             if #claimQueue == 0 then
--                 for _, info in pairs(explorationData) do
--                     if info.remainingtime == "READY TO CLAIM" then
--                         table.insert(claimQueue, info)
--                     end
--                 end
--                 if #claimQueue == 0 then
--                     -- print("❌ Không có nhiệm vụ nào READY TO CLAIM.")
--                 end
--             end

--             -- Nếu có nhiệm vụ trong hàng đợi thì claim từng cái một
--             if #claimQueue > 0 then
--                 local info = table.remove(claimQueue, 1)
--                 claimMission(info)
--             end

--             task.wait(1) -- Delay để tránh spam server
--         end

--         print("🔴 AutoClaim task đã dừng!")
--         autoClaimTask = nil
--     end)
-- end

local function startAutoClaimTask()
    if autoClaimTask then
        return
    end

    autoClaimTask = task.spawn(function()
        print("🟢 AutoClaim task đã bắt đầu!")

        while autoClaimEnabled do
            local claimQueue = {}

            -- Quét dữ liệu để tìm các nhiệm vụ "READY TO CLAIM"
            for _, info in pairs(explorationData) do
                if info.remainingtime == "READY TO CLAIM" then
                    table.insert(claimQueue, info)
                end
            end

            -- Xử lý từng nhiệm vụ trong hàng đợi
            for _, info in ipairs(claimQueue) do
                claimMission(info) -- Gọi hàm claimMission để xử lý nhiệm vụ
                task.wait(2)       -- Thêm delay giữa các lần claim để tránh spam server
            end

            task.wait(1) -- Delay để tránh quét liên tục
        end

        print("🔴 AutoClaim task đã dừng!")
        autoClaimTask = nil
    end)
end

-- UI
local Paragraph = Exploration:CreateParagraph({
    Title = "AUTO CLAIM",
    Content = "Tự động claim phần thưởng nhiệm vụ."
})

Exploration:CreateToggle({
    Name = "⚙️ Auto Claim",
    CurrentValue = false,
    Callback = function(Value)
        autoClaimEnabled = Value
        print("⚙️ AutoClaim hiện tại:", autoClaimEnabled and "🟢 BẬT" or "🔴 TẮT")
        if autoClaimEnabled then
            startAutoClaimTask()
        end
    end
})

local Divider = Exploration:CreateDivider()

-- ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
-- ─██████████████───██████████████─██████████████─██████████████─██████─────────██████████████────██████████████─██████████████─██████████████───
-- ─██░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────██░░░░░░░░░░██────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██───
-- ─██░░██████░░██───██░░██████░░██─██████░░██████─██████░░██████─██░░██─────────██░░██████████────██████░░██████─██░░██████░░██─██░░██████░░██───
-- ─██░░██──██░░██───██░░██──██░░██─────██░░██─────────██░░██─────██░░██─────────██░░██────────────────██░░██─────██░░██──██░░██─██░░██──██░░██───
-- ─██░░██████░░████─██░░██████░░██─────██░░██─────────██░░██─────██░░██─────────██░░██████████────────██░░██─────██░░██████░░██─██░░██████░░████─
-- ─██░░░░░░░░░░░░██─██░░░░░░░░░░██─────██░░██─────────██░░██─────██░░██─────────██░░░░░░░░░░██────────██░░██─────██░░░░░░░░░░██─██░░░░░░░░░░░░██─
-- ─██░░████████░░██─██░░██████░░██─────██░░██─────────██░░██─────██░░██─────────██░░██████████────────██░░██─────██░░██████░░██─██░░████████░░██─
-- ─██░░██────██░░██─██░░██──██░░██─────██░░██─────────██░░██─────██░░██─────────██░░██────────────────██░░██─────██░░██──██░░██─██░░██────██░░██─
-- ─██░░████████░░██─██░░██──██░░██─────██░░██─────────██░░██─────██░░██████████─██░░██████████────────██░░██─────██░░██──██░░██─██░░████████░░██─
-- ─██░░░░░░░░░░░░██─██░░██──██░░██─────██░░██─────────██░░██─────██░░░░░░░░░░██─██░░░░░░░░░░██────────██░░██─────██░░██──██░░██─██░░░░░░░░░░░░██─
-- ─████████████████─██████──██████─────██████─────────██████─────██████████████─██████████████────────██████─────██████──██████─████████████████─
-- ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
-- UI Rayfield
local Battle = Window:CreateTab("BATTLE", 4483362458)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cờ điều khiển
local isAutoDeck = false
local isAutoEternal = false
local isAutoShadow = false
local isAutoTower = false

-- Deck đã chọn
local deckSelections = {
    eternal = "1",
    shadow = "1",
    tower = "1",
    nightmare = "1"
}

-- Hàm equip deck
local function equipDeck(deckNumber)
    local args = { tonumber(deckNumber) }
    -- ReplicatedStorage:WaitForChild("kQR"):WaitForChild("c845550a-9342-4afd-b7e0-5e5fa5a5b845"):FireServer(unpack(args))
    ReplicatedStorage:WaitForChild("JZ0"):WaitForChild("9174b6a5-c4d5-4bd5-a793-9486b75f6f7f"):FireServer(unpack(args))
end

local Paragraph = Battle:CreateParagraph({
    Title = "AUTO DECK",
    Content = "Tự động trang bị deck cho từng chế độ.\n⚠️Chọn deck cho mỗi chế độ tại SELECT DECK."
})

-- AUTO DECK Toggle
Battle:CreateToggle({
    Name = "AUTO DECK",
    CurrentValue = false,
    Flag = "ToggleAutoDeck",
    Callback = function(Value)
        isAutoDeck = Value
    end
})

local Divider = Battle:CreateDivider()
local Paragraph = Battle:CreateParagraph({
    Title = "SELECT DECK",
    Content = "Chọn deck cho từng chế độ.\n⚠️ Để sử dụng hãy bật AUTO DECK."
})

-- Deck Dropdowns
Battle.Dropdowns = {}

Battle.Dropdowns["ENTERNAL DRAGON"] = Battle:CreateDropdown({
    Name = "ENTERNAL DRAGON",
    Options = { "1", "2", "3" },
    CurrentOption = { deckSelections.eternal },
    Callback = function(Options)
        deckSelections.eternal = Options[1]
    end
})

Battle.Dropdowns["SHADOW DRAGON"] = Battle:CreateDropdown({
    Name = "SHADOW DRAGON",
    Options = { "1", "2", "3" },
    CurrentOption = { deckSelections.shadow },
    Callback = function(Options)
        deckSelections.shadow = Options[1]
    end
})

Battle.Dropdowns["NIGHTMARE TOWER"] = Battle:CreateDropdown({
    Name = "NIGHTMARE TOWER",
    Options = { "1", "2", "3" },
    CurrentOption = { deckSelections.nightmare },
    Callback = function(Options)
        deckSelections.nightmare = Options[1]
    end
})

Battle.Dropdowns["INFINITY TOWER"] = Battle:CreateDropdown({
    Name = "INFINITY TOWER",
    Options = { "1", "2", "3" },
    CurrentOption = { deckSelections.tower },
    Callback = function(Options)
        deckSelections.tower = Options[1]
    end
})

local Divider = Battle:CreateDivider()
local Paragraph = Battle:CreateParagraph({
    Title = "AUTO BATTLE",
    Content = "Tự động chiến đấu với các chế độ."
})

-- AUTO ETERNAL DRAGON
Battle:CreateToggle({
    Name = "ETERNAL DRAGON",
    CurrentValue = false,
    Flag = "ToggleEternalDragon",
    Callback = function(Value)
        isAutoEternal = Value
        if Value then
            task.spawn(function()
                while isAutoEternal do
                    if isAutoDeck then
                        equipDeck(deckSelections.eternal)
                        task.wait(1) -- chờ 1s cho chắc
                    end
                    local args = { "eternal_dragon" }
                    ReplicatedStorage:WaitForChild("JZ0"):WaitForChild("9efaaa87-7d74-4d63-8466-8bb11b0391ad")
                        :FireServer(unpack(args))
                    task.wait(5)
                end
            end)
        end
    end
})

-- AUTO SHADOW DRAGON
Battle:CreateToggle({
    Name = "SHADOW DRAGON",
    CurrentValue = false,
    Flag = "ToggleShadowDragon",
    Callback = function(Value)
        isAutoShadow = Value
        if Value then
            task.spawn(function()
                while isAutoShadow do
                    if isAutoDeck then
                        equipDeck(deckSelections.shadow)
                        task.wait(1)
                    end
                    local args = { "shadow_dragon" }
                    ReplicatedStorage:WaitForChild("JZ0"):WaitForChild("9efaaa87-7d74-4d63-8466-8bb11b0391ad")
                        :FireServer(unpack(args))
                    task.wait(5)
                end
            end)
        end
    end
})

-- AUTO NIGHTMARE TOWER
Battle:CreateToggle({
    Name = "NIGHTMARE TOWER",
    CurrentValue = false,
    Flag = "ToggleNightmareTower",
    Callback = function(Value)
        isAutoTower = Value
        if Value then
            task.spawn(function()
                while isAutoTower do
                    local Players = game:GetService("Players")
                    local player = Players.LocalPlayer
                    local playerGui = player:WaitForChild("PlayerGui")
                    local summaryGui = playerGui:FindFirstChild("infinite-tower-floor-summary")
                    if summaryGui then
                        -- Tìm TextLabel trong TextButton
                        local textButton = summaryGui:FindFirstChild("Transition", true)
                            and summaryGui.Transition:FindFirstChild("Frame", true)
                            and summaryGui.Transition.Frame.Frame:GetChildren()[2]
                            and summaryGui.Transition.Frame.Frame:GetChildren()[2].Frame
                            and summaryGui.Transition.Frame.Frame:GetChildren()[2].Frame.Frame:GetChildren()[7]
                            and summaryGui.Transition.Frame.Frame:GetChildren()[2].Frame.Frame:GetChildren()[7]
                            :FindFirstChild(
                                "TextButton")

                        if textButton and textButton:FindFirstChild("TextLabel") then
                            local textLabel = textButton.TextLabel
                            if textLabel.Text == "RESTART" then
                                pressKey(Enum.KeyCode.BackSlash)
                                task.wait(0.1) -- đợi một chút
                                pressKey(Enum.KeyCode.Return)
                            else
                            end
                        else
                        end
                    else
                    end

                    if isAutoDeck then
                        equipDeck(deckSelections.nightmare)
                        task.wait(1)
                    end

                    local args = { "nightmare_tower" }
                    ReplicatedStorage:WaitForChild("JZ0"):WaitForChild("8979e7ea-9775-4c4c-8568-ceac4fe26b11")
                        :FireServer(unpack(args))
                    task.wait(5)
                end
            end)
        end
    end
})

-- AUTO INFINITY TOWER
Battle:CreateToggle({
    Name = "INFINITY TOWER",
    CurrentValue = false,
    Flag = "ToggleInfinityTower",
    Callback = function(Value)
        isAutoTower = Value
        if Value then
            task.spawn(function()
                while isAutoTower do
                    if isAutoDeck then
                        equipDeck(deckSelections.tower)
                        task.wait(1)
                    end
                    ReplicatedStorage:WaitForChild("kQR"):WaitForChild("60ed7d69-2cac-467c-9695-6ab3e77159b9")
                        :FireServer()
                    task.wait(5)
                end
            end)
        end
    end
})

-- ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
-- ─██████████████─██████████████─██████──────────██████─██████████████─██████████─██████████████────██████████████─██████████████─██████████████───
-- ─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██████████──██░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░██────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██───
-- ─██░░██████████─██░░██████░░██─██░░░░░░░░░░██──██░░██─██░░██████████─████░░████─██░░██████████────██████░░██████─██░░██████░░██─██░░██████░░██───
-- ─██░░██─────────██░░██──██░░██─██░░██████░░██──██░░██─██░░██───────────██░░██───██░░██────────────────██░░██─────██░░██──██░░██─██░░██──██░░██───
-- ─██░░██─────────██░░██──██░░██─██░░██──██░░██──██░░██─██░░██████████───██░░██───██░░██────────────────██░░██─────██░░██████░░██─██░░██████░░████─
-- ─██░░██─────────██░░██──██░░██─██░░██──██░░██──██░░██─██░░░░░░░░░░██───██░░██───██░░██──██████────────██░░██─────██░░░░░░░░░░██─██░░░░░░░░░░░░██─
-- ─██░░██─────────██░░██──██░░██─██░░██──██░░██──██░░██─██░░██████████───██░░██───██░░██──██░░██────────██░░██─────██░░██████░░██─██░░████████░░██─
-- ─██░░██─────────██░░██──██░░██─██░░██──██░░██████░░██─██░░██───────────██░░██───██░░██──██░░██────────██░░██─────██░░██──██░░██─██░░██────██░░██─
-- ─██░░██████████─██░░██████░░██─██░░██──██░░░░░░░░░░██─██░░██─────────████░░████─██░░██████░░██────────██░░██─────██░░██──██░░██─██░░████████░░██─
-- ─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██████████░░██─██░░██─────────██░░░░░░██─██░░░░░░░░░░██────────██░░██─────██░░██──██░░██─██░░░░░░░░░░░░██─
-- ─██████████████─██████████████─██████──────────██████─██████─────────██████████─██████████████────────██████─────██████──██████─████████████████─
-- ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local playerName = Players.LocalPlayer.Name

local configRoot = "ACL"
local configFolder = configRoot .. "/UserConfig"
local configDropdown, selectedConfig, newConfigName

-- Tạo folder nếu chưa có
if not isfolder(configRoot) then
    makefolder(configRoot)
end
if not isfolder(configFolder) then
    makefolder(configFolder)
end

-- Trả về đường dẫn đầy đủ đến file JSON
local function getFilePath(fileName)
    if type(fileName) ~= "string" or fileName == "" then
        warn("⚠️ Tên file không hợp lệ:", fileName)
        return nil
    end
    return configFolder .. "/" .. fileName .. ".json"
end

-- Hàm lấy dữ liệu từ InputCards (Input và Dropdown)
local function getInputCardsData(deployInputs)
    if type(deployInputs) ~= "table" then
        warn("⚠️ deployInputs không hợp lệ. Phải là một bảng.")
        return {}
    end

    local inputCardsData = {}
    for difficulty, inputs in pairs(deployInputs) do
        inputCardsData[difficulty] = {}
        for i = 1, 4 do
            local cardName = inputs.cardInputs[i] and inputs.cardInputs[i].Value or ""
            local cardRarity = inputs.rarityDropdowns[i] and inputs.rarityDropdowns[i].Value or "basic"
            table.insert(inputCardsData[difficulty], {
                name = cardName,
                rarity = cardRarity
            })
        end
    end
    return inputCardsData
end

-- Hàm điền lại dữ liệu vào InputCards
local function setInputCardsData(deployInputs, data)
    for difficulty, cards in pairs(data) do
        if deployInputs[difficulty] then
            for i, card in ipairs(cards) do
                if deployInputs[difficulty].cardInputs[i] and deployInputs[difficulty].rarityDropdowns[i] then
                    deployInputs[difficulty].cardInputs[i]:Set(card.name or "")
                    deployInputs[difficulty].rarityDropdowns[i]:Set(card.rarity or "basic")
                end
            end
        end
    end
end

-- Hàm lưu JSON
local function saveJSON(fileName, deployInputs)
    local path = getFilePath(fileName)
    if not path then
        warn("❌ Không thể lưu file vì đường dẫn không hợp lệ.")
        return
    end

    -- Kiểm tra deployInputs trước khi lấy dữ liệu
    local inputCardsData = getInputCardsData(deployInputs)
    local wrappedData = {
        InputCards = inputCardsData,    -- Lưu thông tin InputCards
        DeckSelections = deckSelections -- Lưu trạng thái của các dropdown
    }

    writefile(path, HttpService:JSONEncode(wrappedData))
    print("📁 File đã được lưu tại:", path)
end

-- Hàm đọc JSON
-- local function loadJSON(fileName, deployInputs)
--     local path = getFilePath(fileName)
--     if path and isfile(path) then
--         local rawData = HttpService:JSONDecode(readfile(path))
--         if rawData.InputCards then
--             setInputCardsData(deployInputs, rawData.InputCards) -- Điền lại dữ liệu vào InputCards
--         end
--         return rawData.Deloy                                    -- Trả về dữ liệu bên trong "Deloy"
--     end
--     return nil
-- end

-- Hàm đọc JSON
local function loadJSON(fileName, deployInputs)
    local path = getFilePath(fileName)
    if path and isfile(path) then
        local rawData = HttpService:JSONDecode(readfile(path))

        -- Điền lại dữ liệu vào InputCards
        if rawData.InputCards then
            setInputCardsData(deployInputs, rawData.InputCards)
        end

        -- Điền lại dữ liệu vào DeckSelections
        if rawData.DeckSelections then
            deckSelections = rawData.DeckSelections

            -- Cập nhật giá trị của dropdowns
            if Battle and Battle.Dropdowns then
                if Battle.Dropdowns["ENTERNAL DRAGON"] then
                    Battle.Dropdowns["ENTERNAL DRAGON"]:Set({ deckSelections.eternal or "1" })
                end
                if Battle.Dropdowns["SHADOW DRAGON"] then
                    Battle.Dropdowns["SHADOW DRAGON"]:Set({ deckSelections.shadow or "1" })
                end
                if Battle.Dropdowns["INFINITY TOWER"] then
                    Battle.Dropdowns["INFINITY TOWER"]:Set({ deckSelections.tower or "1" })
                end
                if Battle.Dropdowns["NIGHTMARE TOWER"] then
                    Battle.Dropdowns["NIGHTMARE TOWER"]:Set({ deckSelections.nightmare or "1" })
                end
            end
        end

        print("✅ Đã load config:", fileName)
        return rawData
    end
    return nil
end

-- Hàm xóa file JSON
local function deleteJSON(fileName)
    local path = getFilePath(fileName)
    if path and isfile(path) then
        delfile(path)
    end
end

-- Lấy danh sách file JSON trong folder
local function listConfigFiles()
    local files = listfiles(configFolder)
    local names = {}
    for _, filePath in ipairs(files) do
        local name = filePath:match("([^/\\]+)%.json$")
        if name then
            table.insert(names, name)
        end
    end
    return names
end

-- UI Rayfield
local Config = Window:CreateTab("CONFIG", 4483362458)

local Paragraph = Config:CreateParagraph({
    Title = "TẠO MỚI CONFIG",
    Content = "Nhập tên và tạo mới config.\n⚠️ Tên config không được trùng lặp với các config đã có."
})

Config:CreateInput({
    Name = "Nhập tên Config mới",
    PlaceholderText = "VD: fireteam_alpha",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        newConfigName = Value
    end
})

Config:CreateButton({
    Name = "🆕 Tạo Config Mới",
    Callback = function()
        if not newConfigName or newConfigName == "" then
            warn("⚠️ Vui lòng nhập tên config!")
            return
        end

        -- Làm mới lại deployInputs
        for difficulty, inputs in pairs(deployInputs) do
            for i = 1, 4 do
                if inputs.cardInputs[i] then
                    inputs.cardInputs[i]:Set("") -- Đặt lại giá trị input card name
                end
                if inputs.rarityDropdowns[i] then
                    inputs.rarityDropdowns[i]:Set("basic") -- Đặt lại giá trị dropdown rarity
                end
            end
        end

        deckSelections = {
            eternal = "1",
            shadow = "1",
            tower = "1",
            nightmare = "1"
        }

        saveJSON(newConfigName, deployInputs)

        Rayfield:Notify({
            Title = "✅ Tạo Thành Công",
            Content = "Đã tạo config: " .. newConfigName,
            Duration = 3
        })

        configDropdown:Refresh(listConfigFiles(), true)
    end
})

local Divider = Config:CreateDivider()
local Paragraph = Config:CreateParagraph({
    Title = "QUẢN LÝ CONFIG",
    Content = "Chọn config để lưu, load hoặc xoá."
})

configDropdown = Config:CreateDropdown({
    Name = "📂 Chọn Config",
    Options = listConfigFiles(),
    CurrentOption = nil,
    Image = "folder",
    Callback = function(Value)
        if type(Value) == "table" then
            selectedConfig = Value[1] or nil
        elseif type(Value) == "string" then
            selectedConfig = Value
        else
            warn("⚠️ Giá trị không hợp lệ từ dropdown:", typeof(Value))
            selectedConfig = nil
        end
    end
})

Config:CreateButton({
    Name = "💾 Lưu Config",
    Callback = function()
        if not selectedConfig then
            warn("⚠️ Chưa chọn config để lưu!")
            return
        end

        saveJSON(selectedConfig, deployInputs)

        Rayfield:Notify({
            Title = "✅ Đã Lưu",
            Content = "Đã lưu config: " .. selectedConfig,
            Duration = 3,
            Image = "download"
        })
    end
})

Config:CreateButton({
    Name = "🗑️ Xoá Config",
    Callback = function()
        if not selectedConfig then
            warn("⚠️ Chưa chọn config để xoá!")
            return
        end

        deleteJSON(selectedConfig)

        Rayfield:Notify({
            Title = "🗑️ Đã Xoá",
            Content = "Đã xoá config: " .. selectedConfig,
            Duration = 3,
            Image = "eraser"
        })

        configDropdown:Refresh(listConfigFiles(), true)
    end
})

Config:CreateButton({
    Name = "📥 Load Config",
    Callback = function()
        if not selectedConfig then
            warn("⚠️ Chưa chọn config để load!")
            return
        end

        loadJSON(selectedConfig, deployInputs)

        Rayfield:Notify({
            Title = "✅ Đã Load",
            Content = "Config đã được áp dụng.",
            Duration = 3,
            Image = "upload"
        })
    end
})

Divider = Config:CreateDivider()
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

local antiAfkEnabled = false
local afkConnection = nil

-- Rayfield UI Section
local Paragraph = Config:CreateParagraph({
    Title = "ANTI AFK",
    Content = "Ngăn bị kick khi không hoạt động."
})

Config:CreateToggle({
    Name = "⚙️ Anti-AFK",
    CurrentValue = false,
    Callback = function(state)
        antiAfkEnabled = state
        print("⚙️ Anti-AFK hiện tại:", antiAfkEnabled and "🟢 BẬT" or "🔴 TẮT")

        if antiAfkEnabled then
            afkConnection = Players.LocalPlayer.Idled:Connect(function()
                print("⚠️ Bị phát hiện AFK, đang xử lý...")

                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)

                print("✅ Đã gửi tín hiệu giữ hoạt động.")
            end)
        else
            if afkConnection then
                afkConnection:Disconnect()
                afkConnection = nil
                print("🛑 Đã tắt Anti-AFK.")
            end
        end
    end
})

UpdateParagraphInfo()
