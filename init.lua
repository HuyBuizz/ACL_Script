-- Astral HUB remote init: tải 12 block từ GitHub RAW và thực thi theo thứ tự
local BASE = "https://raw.githubusercontent.com/HuyBuizz/ACL_Script/main/Blocks/"

local files = {
  "01_bootstrap_ui.lua",
  "02_services_remotes.lua",
  "03_utilities.lua",
  "04_orchestrator_pause.lua",
  "05_kill_switch.lua",
  "06_auto_raid.lua",
  "07_main_global_boss.lua",
  "08_auto_tower.lua",
  "09_auto_exploration.lua",
  "10_auto_story.lua",
  "11_misc.lua",
  "12_config.lua",
}

local loaded, total = 0, #files
for _, f in ipairs(files) do
  local url = BASE .. f
  local okGet, src = pcall(function() return game:HttpGet(url) end)
  assert(okGet and type(src)=="string" and #src>0, ("[AstralHub] HttpGet fail: %s"):format(url))

  local chunk, err = loadstring(src, "="..f)
  assert(chunk, ("[AstralHub] loadstring fail %s: %s"):format(f, tostring(err)))

  local okRun, runErr = pcall(chunk)
  assert(okRun, ("[AstralHub] executing %s failed: %s"):format(f, tostring(runErr)))

  loaded += 1
end

if typeof(notify)=="function" then
  notify("Astral HUB", ("Loaded %d/%d blocks (remote)"):format(loaded, total), 4, "check-circle")
else
  print(("[Astral HUB] Loaded %d/%d blocks (remote)"):format(loaded, total))
end
