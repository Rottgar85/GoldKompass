-- GoldKompass Gilde: gemeinsames Wochenziel der Gilde.
-- Jeder teilt (nur wenn er es einschaltet) sein Wochengold ueber den Gildenkanal, das Ziel gilt fuer alle mit dem Addon.
-- Befehle: /gk gilde | /gk gilde ziel <Gold> | /gk gilde an | /gk gilde aus
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass Gilde|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end
local function G(c) return GK.FmtGold(c) end
local PREFIX = "GoldKompassG"
local SEND_EVERY = 60

local peers = {}   -- [Name] = { week = "JJJJ-MM-TT", net = Kupfer, t = GetTime() }

local function WeekKey()
    local wd = date("*t").wday
    local back = (wd + 5) % 7
    return date("%Y-%m-%d", time() - back * 86400)
end

local function Send(msg)
    if not IsInGuild() then return end
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "GUILD")
end

local function MyNet()
    local ok, net = pcall(GK.LiveWeek)
    return ok and math.max(net or 0, 0) or 0
end

local function SendMine()
    local DB = GK.DB()
    if not DB or not DB.opt.guildShare then return end
    Send(string.format("W|%s|%d", WeekKey(), MyNet()))
end

local function Totals()
    local wk = WeekKey()
    local DB = GK.DB()
    local rows, sum = {}, 0
    local me = UnitName("player")
    rows[#rows + 1] = { who = me .. " (du)", net = MyNet() }
    sum = rows[1].net
    for who, p in pairs(peers) do
        if p.week == wk then
            rows[#rows + 1] = { who = who, net = p.net }
            sum = sum + p.net
        end
    end
    table.sort(rows, function(a, b) return a.net > b.net end)
    return sum, rows
end

local function Reached()
    local DB = GK.DB()
    if not DB or not DB.guildGoal then return end
    local sum = Totals()
    if sum >= DB.guildGoal * 10000 then
        local key = WeekKey() .. ":" .. DB.guildGoal
        if DB.guildGoalDone ~= key then
            DB.guildGoalDone = key
            if GK.PlayAlarmSound then GK.PlayAlarmSound() end
            pcall(PlaySound, SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
            pcall(RaidNotice_AddMessage, RaidWarningFrame, "GILDEN-WOCHENZIEL ERREICHT!", ChatTypeInfo["RAID_WARNING"])
            Print("|cff66ff66Gilden-Wochenziel erreicht!|r")
        end
    end
end

local function Show()
    local DB = GK.DB()
    local sum, rows = Totals()
    if DB.guildGoal then
        local pct = floor(sum / (DB.guildGoal * 10000) * 100)
        Print(string.format("Diese Woche: %s von %s (%d%%).", G(sum), G(DB.guildGoal * 10000), pct))
    else
        Print("Diese Woche: " .. G(sum) .. ". Kein Gildenziel gesetzt (/gk gilde ziel 50000).")
    end
    for i = 1, math.min(10, #rows) do
        Print(string.format("%d. %s  %s", i, rows[i].who, G(rows[i].net)))
    end
    if not DB.opt.guildShare then Print("Du teilst dein Wochengold nicht. Einschalten: /gk gilde an") end
    if #rows == 1 then Print("Von anderen ist noch nichts angekommen (sie brauchen GoldKompass und muessen /gk gilde an gesetzt haben).") end
end

GK.RegisterCommand("gilde", function(rest)
    local sub, arg = rest:match("^(%S*)%s*(.-)$")
    sub = strlower(sub or "")
    local d = GK.DB()
    if sub == "ziel" then
        local v = tonumber((arg:gsub(",", "."))) or 0
        if v <= 0 then Print("So: /gk gilde ziel 50000   (Gold)"); return end
        d.guildGoal, d.guildGoalTs = v, time()
        Print("Gildenziel: " .. G(v * 10000) .. " (wird an die Gilde geschickt).")
        Send(string.format("Z|%d|%d", v, d.guildGoalTs))
    elseif sub == "an" then
        d.opt.guildShare = true
        Print("Du teilst jetzt dein Wochengold mit der Gilde."); SendMine()
    elseif sub == "aus" then
        d.opt.guildShare = false
        Print("Du teilst dein Wochengold nicht mehr.")
    else
        Show()
    end
end, "Gilden-Wochenziel: gilde, gilde ziel 50000, gilde an|aus")

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    local DB = GK.DB and GK.DB()
    if event == "PLAYER_LOGIN" then
        DB = GK.DB()
        if DB.opt.guildShare == nil then DB.opt.guildShare = false end
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
        C_Timer.After(15, SendMine)
        C_Timer.NewTicker(SEND_EVERY, function() SendMine(); Reached() end)

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = a1, a2, a3, a4
        if GK.IsSecret(prefix) or GK.IsSecret(msg) or GK.IsSecret(sender) then return end
        if prefix ~= PREFIX or channel ~= "GUILD" or not DB then return end
        local who = Ambiguate(sender, "short")
        if who == UnitName("player") then return end
        local kind, x, y = msg:match("^(%a)|([^|]*)|?(.*)$")
        if kind == "W" then
            local net = tonumber(y)
            if net and #x == 10 then peers[who] = { week = x, net = net, t = GetTime() } end
        elseif kind == "Z" then
            local goal, ts = tonumber(x), tonumber(y)
            if goal and ts and goal > 0 and ts > (DB.guildGoalTs or 0) then
                DB.guildGoal, DB.guildGoalTs = goal, ts
                Print(who .. " hat das Gildenziel auf " .. G(goal * 10000) .. " gesetzt.")
            end
        end
    end
end)

-- Das Gildenziel regelmaessig erneut senden, damit auch neue Mitglieder es bekommen (aeltere Zeitmarke wird ignoriert)
local zev = CreateFrame("Frame")
zev:RegisterEvent("PLAYER_LOGIN")
zev:SetScript("OnEvent", function()
    C_Timer.NewTicker(300, function()
        local d = GK.DB()
        if d and d.opt.guildShare and d.guildGoal and d.guildGoalTs then
            Send(string.format("Z|%d|%d", d.guildGoal, d.guildGoalTs))
        end
    end)
end)
