--=============================================================
-- Astral HUB - init.lua
-- Loads 12 structured blocks in order.
-- Place this file in the same folder as the 01_* ... 12_* files.
--=============================================================

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

local function runfile(path)
  -- Try loadfile (if available), else use readfile+loadstring (common in Roblox executors)
  if typeof(loadfile) == "function" then
    local fn, err = loadfile(path)
    if not fn then
      warn(("[Astral HUB] loadfile failed for %s: %s"):format(path, tostring(err)))
      return false
    end
    local ok, res = pcall(fn)
    if not ok then
      warn(("[Astral HUB] executing %s failed: %s"):format(path, tostring(res)))
      return false
    end
    return true
  elseif typeof(readfile) == "function" and typeof(loadstring) == "function" then
    local okRead, content = pcall(readfile, path)
    if not okRead then
      warn(("[Astral HUB] readfile failed for %s: %s"):format(path, tostring(content)))
      return false
    end
    local chunk, err = loadstring(content, "=" .. path)
    if not chunk then
      warn(("[Astral HUB] loadstring failed for %s: %s"):format(path, tostring(err)))
      return false
    end
    local okRun, res = pcall(chunk)
    if not okRun then
      warn(("[Astral HUB] executing %s failed: %s"):format(path, tostring(res)))
      return false
    end
    return true
  else
    warn("[Astral HUB] No supported file loader found (need loadfile or readfile+loadstring).")
    return false
  end
end

local loaded, total = 0, #files
for _, f in ipairs(files) do
  if runfile(f) then
    loaded += 1
  else
    warn(("[Astral HUB] Skipped %s due to error."):format(f))
  end
end

-- Try to notify in-UI if available
local function try_notify(title, content, seconds, image)
  if typeof(notify) == "function" then
    notify(title, content, seconds, image)
  else
    print(("[Astral HUB] %s - %s"):format(title or "Init", content or ""))
  end
end

try_notify("Astral HUB", ("Loaded %d/%d blocks"):format(loaded, total), 4, "check-circle")
