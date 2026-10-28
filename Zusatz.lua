-- GoldKompass Zusatz: Tagesuebersicht beim Login, BoE-Ton erst ab Mindestwert,
-- Erinnerung an Post und Auktionshaus, Gold pro Stunde je Charakter.
-- Der Export der Sessions (/gk export) gibt es schon in Extras.lua.
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end
local function G(c) return GK.FmtGold(c) end
local function Me() return UnitName("player") .. "-" .. GetRealmName() end

-- 1. Tagesuebersicht ------------------------------------------------------------------
function GK.ShowSummary()
    local DB = GK.DB()
    if not DB then return end
    local d = DB.days[date("%Y-%m-%d", time() - 86400)]
    if d then
        Print(string.format("Gestern: eingenommen %s, ausgegeben %s, Saldo %s.", G(d.inn), G(-d.out), G(d.inn - d.out)))
    else
        Print("Gestern: keine Aufzeichnung.")
    end
    if DB.weekGoal then
        local net = GK.LiveWeek()
        local pct = floor(math.max(net, 0) / (DB.weekGoal * 10000) * 100)
        Print(string.format("Wochenziel: %s von %s (%d%%).", G(net), G(DB.weekGoal * 10000), pct))
    else
        Print("Kein Wochenziel gesetzt (/gk ziel 5000).")
    end
end

-- 2. BoE-Ton erst ab Mindestwert (/gk boe <Gold>, 0 = immer) -----------------------------
local origBoE = GK.IsBoE
if origBoE then
    function GK.IsBoE(id)
        if not origBoE(id) then return false end
        local o = GK.DB() and GK.DB().opt
        local min = ((o and o.boeMin) or 0) * 10000
        if min <= 0 then return true end
        local v = GK.MarketPrice(id) or select(11, C_Item.GetItemInfo(id)) or 0
        return v >= min
    end
end

-- 3. Erinnerungen: Post und Auktionshaus ---------------------------------------------------
local aev = CreateFrame("Frame")
pcall(aev.RegisterEvent, aev, "OWNED_AUCTIONS_UPDATED") -- gibt es nicht in jeder Spielversion
aev:SetScript("OnEvent", function()
    pcall(function()
        local DB = GK.DB()
        if not DB or not C_AuctionHouse or not C_AuctionHouse.GetOwnedAuctions then return end
        DB.ahExpire = DB.ahExpire or {}
        local earliest, sold
        for _, a in ipairs(C_AuctionHouse.GetOwnedAuctions() or {}) do
            if a.status == 1 then sold = true
            elseif a.timeLeftSeconds then
                earliest = math.min(earliest or math.huge, a.timeLeftSeconds)
            end
        end
        DB.ahExpire[Me()] = (earliest or sold) and { at = time() + (earliest or 0), sold = sold and true or false } or nil
    end)
end)

local function Reminders()
    local DB = GK.DB()
    -- Schalter "Post/Auktions-Erinnerung" (Optionen): aus = keine Meldung
    if DB and DB.opt and DB.opt.reminders == false then return end
    if HasNewMail and HasNewMail() then Print("Neue Post im Briefkasten.") end
    local e = DB and DB.ahExpire and DB.ahExpire[Me()]
    if e and time() >= e.at then
        Print("Deine Auktionen sind vermutlich abgelaufen oder verkauft. Schau im Auktionshaus und in der Post nach.")
        DB.ahExpire[Me()] = nil
    end
end

-- 4. Gold pro Stunde je Charakter -----------------------------------------------------------------
local origStop = GK.FarmStop
function GK.FarmStop()
    local n = #GK.DB().farms
    origStop()
    local f = GK.DB().farms
    if #f > n then f[#f].char = Me() end
end

function GK.ShowCharHour()
    local by, order = {}, {}
    for _, r in ipairs(GK.DB().farms) do
        local k = r.char or "Aeltere Sessions (ohne Charakter)"
        local c = by[k]
        if not c then c = { name = k, net = 0, secs = 0, n = 0 }; by[k] = c; order[#order + 1] = c end
        c.net = c.net + (r.net or r.total or 0); c.secs = c.secs + (r.secs or 0); c.n = c.n + 1
    end
    if #order == 0 then Print("Noch keine beendete Farm-Session."); return end
    table.sort(order, function(a, b)
        return (a.secs > 0 and a.net / a.secs or 0) > (b.secs > 0 and b.net / b.secs or 0)
    end)
    Print("Gold pro Stunde je Charakter (Durchschnitt, netto):")
    for i, c in ipairs(order) do
        Print(string.format("%d. %s: %s/h (%d Sessions)", i, c.name, G(c.secs > 0 and c.net / c.secs * 3600 or 0), c.n))
    end
end

-- Befehle ---------------------------------------------------------------------------------------------------
GK.RegisterCommand({ "tag", "day" }, function() GK.ShowSummary() end, "Tagesübersicht (gestern und Wochenziel)")
GK.RegisterCommand("login", function()
    local o = GK.DB().opt
    o.loginSum = not o.loginSum
    Print("Tagesuebersicht beim Login " .. (o.loginSum and "an" or "aus") .. ".")
end, "Tagesübersicht beim Login an/aus")
GK.RegisterCommand("boe", function(arg)
    local v = tonumber((arg:gsub(",", "."))) or 0
    GK.DB().opt.boeMin = v > 0 and v or 0
    Print(v > 0 and ("BoE-Ton nur ab " .. G(v * 10000) .. " Wert.") or "BoE-Ton bei jedem BoE-Item.")
end, "BoE-Ton erst ab X Gold Wert (0 = immer)")
GK.RegisterCommand({ "charstd", "charhour" }, function() GK.ShowCharHour() end, "Gold pro Stunde je Charakter")

-- Start -------------------------------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, event, isInitial)
    local DB = GK.DB()
    if event == "PLAYER_LOGIN" then
        if DB.opt.loginSum == nil then DB.opt.loginSum = true end
        if DB.opt.boeMin == nil then DB.opt.boeMin = 0 end
        if DB.opt.reminders == nil then DB.opt.reminders = true end
    elseif event == "PLAYER_ENTERING_WORLD" and isInitial and DB and DB.opt.loginSum ~= false then
        C_Timer.After(6, function() pcall(GK.ShowSummary); pcall(Reminders) end)
    end
end)


-- Ton und Meldung, sobald das Wochenziel erreicht ist (einmal je Woche und Ziel)
do
    local GKx = GoldKompass
    local function WeekKey()
        local wd = date("*t").wday
        local back = (wd + 5) % 7
        return date("%Y-%m-%d", time() - back * 86400)
    end
    local origUpdate = GKx.UpdateBar
    function GKx.UpdateBar()
        origUpdate()
        local db = GKx.DB and GKx.DB()
        if not db or not db.weekGoal or not GKx.LiveWeek then return end
        local net = GKx.LiveWeek()
        if net >= db.weekGoal * 10000 then
            local key = WeekKey() .. ":" .. db.weekGoal
            if db.goalDone ~= key then
                db.goalDone = key
                if GKx.PlayAlarmSound then GKx.PlayAlarmSound() end
                print("|cffffd100GoldKompass|r: |cff66ff66Wochenziel erreicht!|r")
            end
        end
    end
end

-- Zusaetzlich zur Meldung: Raidwarnung mitten im Bild und der Alarmton (Raidwarnungs-Ton)
do
    local GKy = GoldKompass
    local prevUpdate = GKy.UpdateBar
    function GKy.UpdateBar()
        local db = GKy.DB and GKy.DB()
        local before = db and db.goalDone
        prevUpdate()
        db = GKy.DB and GKy.DB()
        if db and db.goalDone and db.goalDone ~= before then
            pcall(PlaySound, SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
            pcall(RaidNotice_AddMessage, RaidWarningFrame, "WOCHENZIEL ERREICHT!", ChatTypeInfo["RAID_WARNING"])
        end
    end
end

-- Der Meilenstein-Ton aus Extras2 meldet das Ziel bei 100% ebenfalls. Damit es nicht doppelt kommt,
-- gilt 100% dort als erledigt, sobald das Ziel erreicht ist; Ton, Raidwarnung und Meldung kommen von hier.
do
    local GKz = GoldKompass
    local nextUpdate = GKz.UpdateBar
    function GKz.UpdateBar()
        local db = GKz.DB and GKz.DB()
        if db and db.weekGoal and db.ms and db.ms.goal == db.weekGoal and GKz.LiveWeek then
            if GKz.LiveWeek() >= db.weekGoal * 10000 then db.ms.done = db.ms.done or {}; db.ms.done[100] = true end
        end
        nextUpdate()
    end
end
