--=============================================================
-- BLOCK 3) UTILITIES & NOTIFY HELPERS
--=============================================================
function FireSafe(remote, ...)
    if not remote or typeof(remote.FireServer) ~= "function" then return false end
    local ok = pcall(remote.FireServer, remote, ...)
    return ok
end

function Trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function notify(title, content, seconds, image)
    if RayfieldNotify then
        RayfieldNotify({
            Title = title or "Notification",
            Content = content or "",
            Duration = seconds or 4,
            Image = image or "rewind"
        })
    end
end

-- Click anywhere (bottom center) — used to auto-dismiss rewards
function ClickAnywhereBottom()
    local cam = workspace.CurrentCamera; if not cam then return end
    local vp = cam.ViewportSize
    local x, y = math.floor(vp.X * 0.5), math.floor(vp.Y * 0.98)
    VIM:SendMouseMoveEvent(x, y, game)
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.02)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- Safe child count
function CountChildrenSafe(obj)
    if not obj or typeof(obj) ~= "Instance" then return 0 end
    local ok, kids = pcall(function() return obj:GetChildren() end)
    return ok and #kids or 0
end
