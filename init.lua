-- AstralHub remote bootstrap (không cần init.lua)
local OWNER, REPO = "HuyBuizz", "ACL_Script"
local SUBDIR = "Blocks/"   -- nếu bạn để 12 file ở root repo, đổi thành "".

local FILES = {
  "01_bootstrap_ui.lua","02_services_remotes.lua","03_utilities.lua","04_orchestrator_pause.lua",
  "05_kill_switch.lua","06_auto_raid.lua","07_main_global_boss.lua","08_auto_tower.lua",
  "09_auto_exploration.lua","10_auto_story.lua","11_misc.lua","12_config.lua",
}

-- HTTP đa nền tảng
local function http_get(url)
  -- executor APIs phổ biến
  local rq = (http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request))
  if rq then
    local r = rq({Url=url, Method="GET", Headers={["User-Agent"]="Roblox"}})
    if r and r.Body and #r.Body > 0 then return r.Body end
  end
  -- fallback Roblox
  local ok, res = pcall(function() return game:HttpGet(url) end)
  if ok and type(res) == "string" and #res > 0 then return res end
  error("HttpGet fail: "..url)
end

-- các mirror URL (thử lần lượt)
local MIRRORS = {
  function(f) return ("https://raw.githubusercontent.com/%s/%s/main/%s%s"):format(OWNER, REPO, SUBDIR, f) end,
  function(f) return ("https://github.com/%s/%s/raw/main/%s%s"):format(OWNER, REPO, SUBDIR, f) end,
  -- dự phòng: nếu file không nằm trong SUBDIR mà ở root
  function(f) return ("https://raw.githubusercontent.com/%s/%s/main/%s"):format(OWNER, REPO, f) end,
  function(f) return ("https://github.com/%s/%s/raw/main/%s"):format(OWNER, REPO, f) end,
}

local loaded = 0
for _, fname in ipairs(FILES) do
  local src
  for _, mk in ipairs(MIRRORS) do
    local url = mk(fname)
    local ok, body = pcall(http_get, url)
    if ok and body and #body > 0 and not body:find("<!DOCTYPE html>") then
      src = body; break
    end
  end
  assert(src, ("[AstralHub] tải thất bại mọi mirror cho: %s\n→ Kiểm tra tên/thư mục trên GitHub (Blocks/%s) hoặc repo private."):format(fname, fname))
  local chunk, err = loadstring(src, "="..fname); assert(chunk, err)
  local okRun, runErr = pcall(chunk); assert(okRun, ("Run %s lỗi: %s"):format(fname, tostring(runErr)))
  loaded += 1
end

if typeof(notify)=="function" then
  notify("Astral HUB", ("Loaded %d/12 blocks (remote)"):format(loaded), 4, "check-circle")
else
  print(("[Astral HUB] Loaded %d/12 blocks (remote)"):format(loaded))
end
