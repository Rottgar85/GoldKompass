-- GoldKompass Sitzung: Pause fuer die Farm-Session und Wiederherstellen nach /reload oder Neustart.
-- Pause: die Zeit steht, Funde und Gold waehrend der Pause zaehlen nicht. Befehl: /gk pause
-- Wiederherstellen: die Session wird alle 5 Sekunden gespeichert (DB.session). Nach dem Laden kommt sie zurueck,
-- wenn sie nicht aelter als 2 Stunden ist. Stopp loescht den gespeicherten Stand.
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end
local function DB() return GK.DB and GK.DB() end
local MAX_AGE = 2 * 3600

local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = Copy(x) end
    return t
end

-- Pause -----------------------------------------------------------------------------------------------------
local function Snapshot(fm)
    fm.snap = { money = fm.money, value = fm.value, soul = fm.soul, costs = fm.costs, items = Copy(fm.items), price = Copy(fm.price) }
end

function GK.FarmPause()
    local fm = GK.farm
    if not fm then Print("Keine Session aktiv."); return end
    if fm.paused then
        local s = fm.snap
        if s then
            fm.money, fm.value, fm.soul, fm.costs = s.money, s.value, s.soul, s.costs
            fm.items, fm.price = s.items, s.price
        end
        fm.paused, fm.snap = nil, nil
        Print("Pause beendet, die Session laeuft weiter. Funde waehrend der Pause wurden nicht mitgezaehlt.")
    else
        Snapshot(fm)
        fm.paused = true
        Print("Session pausiert. Zeit und Funde stehen, bis du nochmal /gk pause eingibst oder den Knopf drueckst.")
    end
    if GK.RefreshHud then pcall(GK.RefreshHud) end
    if GK.UpdateControl then pcall(GK.UpdateControl) end
    if GK.Refresh then pcall(GK.Refresh) end
end

local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(_, e)
    local fm = GK.farm
    if fm and fm.paused then fm.start = fm.start + e end
end)

-- Pause-Knopf und Anzeige im Farm-Fenster ---------------------------------------------------------------------
-- Die Zeit-Anzeige wird von mehreren Stellen gesetzt; damit sie in der Pause nicht zwischen PAUSE und Restzeit
-- hin und her springt, wird ihr SetText so ersetzt, dass in der Pause immer PAUSE steht.
local function HudUpdate()
    local h = GK.hud
    if not h then return end
    if not h.gkPause then
        local b = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
        b:SetSize(22, 16); b:SetPoint("TOPRIGHT", -20, -3)
        b:SetScript("OnClick", function() GK.FarmPause() end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(GK.farm and GK.farm.paused and "Weiter" or "Pause")
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        h.gkPause = b
        h.title:SetWidth(90)
    end
    local t = h.gkTime
    if t and not t.gkWrapped then
        t.gkWrapped = true
        t:ClearAllPoints(); t:SetPoint("TOPRIGHT", -46, -6)
        local raw = t.SetText
        t.SetText = function(self, txt)
            if GK.farm and GK.farm.paused then txt = "|cffffa040PAUSE|r" end
            raw(self, txt)
        end
    end
    local fm = GK.farm
    h.gkPause:SetText(fm and fm.paused and ">" or "II")
    if t and fm and fm.paused then t:SetText("") end
end
if type(GK.RefreshHud) == "function" then hooksecurefunc(GK, "RefreshHud", function() pcall(HudUpdate) end) end
C_Timer.NewTicker(1, function() pcall(HudUpdate) end)

-- Speichern und Wiederherstellen ---------------------------------------------------------------------------------
local function Save()
    local db, fm = DB(), GK.farm
    if not db or not fm then return end
    local s = { saved = time(), elapsed = GetTime() - fm.start }
    for k, v in pairs(fm) do
        if k ~= "start" then s[k] = Copy(v) end
    end
    db.session = s
end

local function Restore()
    local db = DB()
    local s = db and db.session
    if not s or GK.farm then return end
    if time() - (s.saved or 0) > MAX_AGE then
        db.session = nil
        return
    end
    pcall(GK.FarmStart, s.name)
    local fm = GK.farm
    if not fm then return end
    for k, v in pairs(s) do
        if k ~= "saved" and k ~= "elapsed" then fm[k] = Copy(v) end
    end
    fm.items, fm.price = fm.items or {}, fm.price or {}
    fm.start = GetTime() - (s.elapsed or 0)
    Print("Session wiederhergestellt: " .. tostring(fm.name) .. (fm.paused and " (pausiert)" or "") .. ".")
    if GK.RefreshHud then pcall(GK.RefreshHud) end
    if GK.Refresh then pcall(GK.Refresh) end
end

if type(GK.FarmStop) == "function" then
    hooksecurefunc(GK, "FarmStop", function()
        local db = DB()
        if db and not GK.farm then db.session = nil end
    end)
end

-- Stopp waehrend der Pause: erst den Stand von vor der Pause zurueckholen, sonst zaehlen Funde aus der Pause mit
do
    local origStop = GK.FarmStop
    function GK.FarmStop(...)
        local fm = GK.farm
        if fm and fm.paused then
            local s = fm.snap
            if s then
                fm.money, fm.value, fm.soul, fm.costs = s.money, s.value, s.soul, s.costs
                fm.items, fm.price = s.items, s.price
            end
            fm.paused, fm.snap = nil, nil
        end
        return origStop(...)
    end
end

GK.RegisterCommand("pause", function() GK.FarmPause() end, "Farm-Session pausieren / fortsetzen")

C_Timer.NewTicker(5, Save)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then Save(); return end
    C_Timer.After(3, Restore)
end)
