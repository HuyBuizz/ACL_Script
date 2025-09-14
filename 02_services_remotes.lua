--=============================================================
-- BLOCK 2) SERVICES, REMOTES & GLOBAL SHORTCUTS
--=============================================================
Players            = game:GetService("Players")
RS                 = game:GetService("ReplicatedStorage")
WS                 = game:GetService("Workspace")
HttpService        = game:GetService("HttpService")
VIM                = game:GetService("VirtualInputManager")

LocalPlayer        = Players.LocalPlayer

local Net          = RS:WaitForChild("shared/network@eventDefinitions")
-- Shared
RE_Forfeit         = Net:WaitForChild("forfeitBattle")
RE_SetPartySlot    = Net:WaitForChild("setPartySlot")
-- Auto Raid
RE_Teleport        = Net:WaitForChild("teleport")
RE_FightRaidBoss   = Net:WaitForChild("fightRaidBoss")
RE_FightMinion     = Net:WaitForChild("fightRaidMinion")
-- Exploration
RE_ClaimExpl       = Net:WaitForChild("claimExploration")
RE_StartExpl       = Net:WaitForChild("startExploration")
-- Tower (Infinite)
RE_ClaimInf        = Net:WaitForChild("claimInfinite")
RE_FightInf        = Net:WaitForChild("fightInfinite")
RE_PauseInf        = Net:WaitForChild("pauseInfinite")
-- Global Boss (Main)
RE_FightGlobal     = Net:WaitForChild("fightGlobalBoss")
-- Optional
RE_TouchPickup     = Net:FindFirstChild("touchedPickup")
RE_ClaimDailyQuest = Net:WaitForChild("claimDailyQuest")
-- Story
RE_FightStory      = Net:WaitForChild("fightStoryBoss")
