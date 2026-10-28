-- GoldKompass Start: Startseite im Reiter "Heute" mit den drei wichtigsten Zahlen.
-- Laeuft als letzte Datei und zeichnet nach jedem Refresh nur den Reiter "Heute" neu.
-- Bei einem Fehler bleibt die bisherige Anzeige stehen; der Fehler wird einmal im Chat gemeldet.
local GK = GoldKompass
local GOLD = "|cffffd100"
local GREEN, RED, PURPLE, YELLOW = { 0.4, 1, 0.4 }, { 1, 0.35, 0.35 }, { 0.65, 0.2, 0.75 }, { 1, 0.82, 0 }
local reported

local function Report(where, err)
    if reported then return end
    reported = true
    print("|cffffd100GoldKompass Start|r Fehler (" .. where .. "): " .. tostring(err))
end

local function G(c) return GK.FmtGold and GK.FmtGold(c) or tostring(c or 0) end

local function Build(DB)
    local L = {}
    local function add(l, r, frac, col) L[#L + 1] = { l, r, frac, col } end

    local d = DB.days[date("%Y-%m-%d")] or { inn = 0, out = 0, cat = {} }

    -- Gold heute, Gold pro Stunde und Wochenziel stehen in den drei Kacheln darueber (Glanz.lua)
    local total, chars, warbank = GK.TotalGold()
    add("Gold gesamt (Charaktere und Kriegsmeute-Bank)", G(total))
    add("   davon Kriegsmeute-Bank", DB.warbank and G(warbank) or "Bank einmal öffnen")
    add(" ", "")

    -- Woher / wohin, kurz
    add(GOLD .. "Woher / wohin heute|r", "")
    local cats, mx = {}, 1
    for k, v in pairs(d.cat or {}) do cats[#cats + 1] = { k, v }; mx = math.max(mx, math.abs(v)) end
    table.sort(cats, function(a, b) return math.abs(a[2]) > math.abs(b[2]) end)
    for i = 1, math.min(7, #cats) do
        add("   " .. cats[i][1], G(cats[i][2]), math.abs(cats[i][2]) / mx, cats[i][2] >= 0 and GREEN or RED)
    end
    if #cats == 0 then add("   Noch nichts aufgezeichnet.", "") end
    if not DB.opt.record then add("|cffff5555Aufzeichnung ist aus (Optionen).|r", "") end
    return L
end

local function Paint(f, L)
    local width = (f:GetWidth() or 470) - 20
    for i, r in ipairs(f.rows) do
        local d = L[i]
        if d then
            r:Show(); r.l:SetText(d[1] or ""); r.r:SetText(d[2] or "")
            if d[3] and r.bar then
                local c = d[4] or YELLOW
                r.bar:SetColorTexture(c[1], c[2], c[3], 0.28)
                r.bar:SetWidth(math.max(1, math.min(1, d[3]) * width)); r.bar:Show()
            elseif r.bar then
                r.bar:Hide()
            end
        else
            r:Hide()
        end
    end
end

local function Draw()
    local f = GK.frame
    if not f or not f:IsShown() or GK.tab ~= "heute" or not f.rows then return end
    local DB = GK.DB and GK.DB()
    if not DB then return end
    local ok, L = pcall(Build, DB)
    if not ok then return Report("Build", L) end
    local ok2, err = pcall(Paint, f, L)
    if not ok2 then Report("Anzeige", err) end
end

if type(GK.Refresh) == "function" then
    hooksecurefunc(GK, "Refresh", Draw)
else
    print("|cffffd100GoldKompass Start|r: GK.Refresh nicht gefunden, Startseite aus.")
end

-- Kein eigener Takt: keine spaetere Datei ersetzt GK.Refresh, und das Hauptfenster (Kompakt.lua) ruft Refresh
-- bei laufender Farm jede Sekunde auf, damit "Gold pro Stunde" hier aktuell bleibt.
