-- GoldKompass Daten: Sicherung (Export/Import als Text), Speicher pruefen und aufraeumen, Selbsttest.
-- /gk sicherung, /gk speicher, /gk speicher aufraeumen, /gk selbsttest
-- Import fuehrt nie Code aus: ein eigener Leser prueft den Text Zeichen fuer Zeichen.
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local TITLE = "|cffffd100GoldKompass|r"
local function Print(m) print(TITLE .. ": " .. m) end
local function T(s) return GK.T and GK.T(s) or s end
local function DB() return GK.DB and GK.DB() end
local WHITE = "Interface\\Buttons\\WHITE8x8"

-- Daten <-> Text ----------------------------------------------------------------------------------------------
-- Format: n<Zahl>;  s<Laenge>:<Text>  T  F  { Schluessel Wert ... }
local function Ser(v, out, depth)
    depth = depth or 0
    local t = type(v)
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then v = 0 end
        out[#out + 1] = "n" .. string.format("%.17g", v) .. ";"
    elseif t == "string" then
        out[#out + 1] = "s" .. #v .. ":" .. v
    elseif t == "boolean" then
        out[#out + 1] = v and "T" or "F"
    elseif t == "table" and depth < 30 then
        out[#out + 1] = "{"
        for k, x in pairs(v) do
            local tk, tx = type(k), type(x)
            if (tk == "string" or tk == "number") and (tx == "string" or tx == "number" or tx == "boolean" or tx == "table") then
                Ser(k, out, depth + 1); Ser(x, out, depth + 1)
            end
        end
        out[#out + 1] = "}"
    end
end
local function Serialize(v) local out = {}; Ser(v, out); return table.concat(out) end

local function Deserialize(s)
    local pos, n = 1, #s
    local function val(depth)
        if depth > 30 then error("zu tief verschachtelt") end
        local c = s:sub(pos, pos)
        if c == "n" then
            local e = s:find(";", pos, true); if not e then error("Zahl ohne Ende") end
            local num = tonumber(s:sub(pos + 1, e - 1)); if not num then error("keine Zahl") end
            pos = e + 1; return num
        elseif c == "s" then
            local e = s:find(":", pos, true); if not e then error("Text ohne Laenge") end
            local len = tonumber(s:sub(pos + 1, e - 1)); if not len or len < 0 then error("falsche Laenge") end
            local str = s:sub(e + 1, e + len); if #str ~= len then error("Text abgeschnitten") end
            pos = e + 1 + len; return str
        elseif c == "T" then pos = pos + 1; return true
        elseif c == "F" then pos = pos + 1; return false
        elseif c == "{" then
            pos = pos + 1
            local t = {}
            while s:sub(pos, pos) ~= "}" do
                if pos > n then error("Tabelle ohne Ende") end
                local k = val(depth + 1)
                if type(k) ~= "string" and type(k) ~= "number" then error("falscher Schluessel") end
                t[k] = val(depth + 1)
            end
            pos = pos + 1
            return t
        end
        error("unbekanntes Zeichen an Stelle " .. pos)
    end
    local ok, res = pcall(val, 0)
    if not ok then return nil, res end
    if pos <= n then return nil, "Rest nach dem Ende" end
    return res
end

-- Base64, damit der Text keine Sonderzeichen (z. B. |) enthaelt, die das Eingabefeld umdeutet
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local DEC = {}
for i = 1, 64 do DEC[B64:byte(i)] = i - 1 end
local function Enc(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local v = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1, c2 = floor(v / 262144) % 64, floor(v / 4096) % 64
        local c3, c4 = floor(v / 64) % 64, v % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1) ..
            (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end
local function Dec(s)
    s = s:gsub("[^%w%+/=]", "")
    local out = {}
    for i = 1, #s, 4 do
        local a, b, c, d = s:byte(i, i + 3)
        local va, vb = DEC[a or 0], DEC[b or 0]
        if not va or not vb then return nil end
        local vc, vd = c and DEC[c], d and DEC[d]
        local v = va * 262144 + vb * 4096 + (vc or 0) * 64 + (vd or 0)
        out[#out + 1] = string.char(floor(v / 65536) % 256)
        if vc then out[#out + 1] = string.char(floor(v / 256) % 256) end
        if vd then out[#out + 1] = string.char(v % 256) end
    end
    return table.concat(out)
end

-- Sicherung: was gehoert zu "Einstellungen"
local SETTINGS = { "opt", "weekGoal", "goals", "matList", "alarms", "sellBlock", "sellMin", "myRoutes", "guildGoal",
    "guildGoalTs", "routeLast", "hudPos", "barPos", "angle", "navPos", "positions" }

local function ExportText(kind)
    local db = DB()
    local data
    if kind == "opt" then
        data = {}
        for _, k in ipairs(SETTINGS) do data[k] = db[k] end
    else
        data = db
    end
    return "GK1:" .. kind .. ":" .. Enc(Serialize(data))
end

local function ParseImport(text)
    text = strtrim(text or "")
    local kind, body = text:match("^GK1:(%a+):(.+)$")
    if not kind or (kind ~= "opt" and kind ~= "all") then return nil, "Das ist kein GoldKompass-Sicherungstext." end
    local raw = Dec(body)
    if not raw then return nil, "Der Text ist beschädigt (Zeichen fehlen oder sind falsch)." end
    local data, err = Deserialize(raw)
    if type(data) ~= "table" then return nil, "Der Text ist beschädigt: " .. tostring(err) end
    if data.opt ~= nil and type(data.opt) ~= "table" then return nil, "Die Einstellungen im Text sind ungültig." end
    return kind, data
end

local function ApplyImport(kind, data)
    local db = DB()
    if kind == "opt" then
        for _, k in ipairs(SETTINGS) do if data[k] ~= nil then db[k] = data[k] end end
    else
        for k in pairs(db) do db[k] = nil end
        for k, v in pairs(data) do db[k] = v end
        GK.Migrate(db)
    end
    Print(kind == "opt" and "Einstellungen übernommen." or "Alle Daten übernommen.")
    StaticPopupDialogs["GOLDKOMPASS_RELOAD"].text = T("GoldKompass: Damit alles wirkt, die Oberfläche jetzt neu laden?")
    StaticPopup_Show("GOLDKOMPASS_RELOAD")
end

StaticPopupDialogs["GOLDKOMPASS_IMPORT"] = {
    text = "GoldKompass: %s\n\nDie vorhandenen Werte werden dabei überschrieben. Fortfahren?",
    button1 = YES, button2 = NO,
    OnAccept = function(self, payload) if payload then ApplyImport(payload.kind, payload.data) end end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["GOLDKOMPASS_RELOAD"] = {
    text = "GoldKompass: Damit alles wirkt, die Oberfläche jetzt neu laden?",
    button1 = YES, button2 = NO,
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- Fenster fuer die Sicherung -------------------------------------------------------------------------------------
local tf
local function BuildTransfer()
    if tf then return end
    local f = CreateFrame("Frame", "GoldKompassTransfer", UIParent, "BackdropTemplate")
    f:SetSize(540, 380); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 2 })
    f:SetBackdropColor(0.04, 0.04, 0.07, 0.97); f:SetBackdropBorderColor(1, 0.82, 0, 1)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "GoldKompassTransfer")
    local band = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    band:SetPoint("TOPLEFT", 2, -2); band:SetPoint("TOPRIGHT", -2, -2); band:SetHeight(28); band:SetColorTexture(0.16, 0.13, 0.03, 0.9)
    local logo = f:CreateTexture(nil, "OVERLAY"); logo:SetSize(20, 20); logo:SetPoint("TOPLEFT", 8, -6); logo:SetTexture(GK.LOGO)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 6, 0); title:SetText("GoldKompass · Sicherung")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -2, -2)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 12, -38); hint:SetPoint("RIGHT", -12, 0); hint:SetJustifyH("LEFT")
    hint:SetText("Exportieren: Text wird markiert, mit Strg+C kopieren und z. B. in einer Textdatei aufheben.\n" ..
        "Importieren: Sicherungstext mit Strg+V unten einfügen und auf Importieren klicken.")

    local function Btn(text, w) local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); b:SetSize(w, 22); b:SetText(text); return b end
    local b1 = Btn("Einstellungen exportieren", 170); b1:SetPoint("TOPLEFT", 12, -70)
    local b2 = Btn("Alles exportieren", 130); b2:SetPoint("LEFT", b1, "RIGHT", 6, 0)
    local b3 = Btn("Importieren", 100); b3:SetPoint("LEFT", b2, "RIGHT", 6, 0)
    local b4 = Btn("Leeren", 70); b4:SetPoint("LEFT", b3, "RIGHT", 6, 0)

    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 12, -100); sf:SetPoint("BOTTOMRIGHT", -32, 32)
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, 2); bg:SetPoint("TOPLEFT", sf, -4, 4); bg:SetPoint("BOTTOMRIGHT", sf, 4, -4)
    bg:SetColorTexture(1, 1, 1, 0.04)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true); eb:SetFontObject("ChatFontNormal"); eb:SetWidth(480); eb:SetAutoFocus(false); eb:SetMaxLetters(0)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    sf:SetScrollChild(eb)
    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.status:SetPoint("BOTTOMLEFT", 12, 10); f.status:SetPoint("BOTTOMRIGHT", -12, 10); f.status:SetJustifyH("LEFT")

    local function Show(kind)
        local text = ExportText(kind)
        eb:SetText(text); eb:SetFocus(); eb:HighlightText()
        f.status:SetText(string.format("%s: %.1f KB. Jetzt Strg+C drücken.", kind == "opt" and "Einstellungen" or "Alle Daten", #text / 1024))
    end
    b1:SetScript("OnClick", function() Show("opt") end)
    b2:SetScript("OnClick", function() Show("all") end)
    b3:SetScript("OnClick", function()
        local kind, data = ParseImport(eb:GetText())
        if not kind then f.status:SetText("|cffff5555" .. T(data) .. "|r"); return end
        local what = kind == "opt" and "Einstellungen aus der Sicherung übernehmen." or "ALLE Daten aus der Sicherung übernehmen."
        StaticPopupDialogs["GOLDKOMPASS_IMPORT"].text = T("GoldKompass: %s\n\nDie vorhandenen Werte werden dabei überschrieben. Fortfahren?")
        StaticPopup_Show("GOLDKOMPASS_IMPORT", T(what), nil, { kind = kind, data = data })
    end)
    b4:SetScript("OnClick", function() eb:SetText(""); f.status:SetText("") end)
    tf = f
end
function GK.OpenTransfer()
    BuildTransfer()
    tf:Show()
end

-- Speicher ------------------------------------------------------------------------------------------------------------
local NAMES = {
    days = "Tagesbilanz", farms = "Farm-Sessions", hist = "Preisverlauf", inv = "Inventar aller Charaktere",
    groupLoot = "Gruppen-Beute", trophies = "Teuerste Funde", totalHist = "Gold-Verlauf", gained = "Wochengold",
    charGained = "Gold je Charakter", myRoutes = "Eigene Routen", routeStats = "Routen-Statistik", opt = "Einstellungen",
    chars = "Charaktere", session = "Laufende Session", alarms = "Preisalarme", sellBlock = "Verkaufs-Sperrliste",
}

function GK.ShowMemory()
    local db = DB()
    local parts, total = {}, 0
    for k, v in pairs(db) do
        local size = #Serialize(v)
        parts[#parts + 1] = { k = k, size = size }
        total = total + size
    end
    table.sort(parts, function(a, b) return a.size > b.size end)
    local ram
    if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
        pcall(UpdateAddOnMemoryUsage)
        local ok, kb = pcall(GetAddOnMemoryUsage, "GoldKompass")
        if ok and kb then ram = kb end
    end
    Print(string.format("Gespeicherte Daten: %.0f KB%s", total / 1024, ram and string.format(", Arbeitsspeicher: %.0f KB", ram) or ""))
    for i = 1, math.min(8, #parts) do
        local p = parts[i]
        print(string.format("   %-26s %6.1f KB", T(NAMES[p.k] or p.k), p.size / 1024))
    end
    print(T("   Aufräumen: /gk speicher aufraeumen"))
end

function GK.CleanMemory()
    local db = DB()
    local before = #Serialize(db)
    local now = time()
    -- Inventar von Charakteren, die seit 120 Tagen nicht mehr gespielt wurden
    for name, rec in pairs(db.inv or {}) do
        if type(rec) ~= "table" or (rec.ts or 0) < now - 120 * 86400 then db.inv[name] = nil end
    end
    -- Preisverlauf: Items ohne Eintrag in den letzten 30 Tagen
    local cut = date("%Y-%m-%d", now - 30 * 86400)
    for id, h in pairs(db.hist or {}) do
        local latest
        for day in pairs(h) do if not latest or day > latest then latest = day end end
        if not latest or latest < cut then db.hist[id] = nil end
    end
    -- Gruppen-Beute: die 50 wertvollsten behalten
    if type(db.groupLoot) == "table" then while #db.groupLoot > 50 do table.remove(db.groupLoot) end end
    db.dipSeen = nil
    -- Funde alter Sessions (aelter als 180 Tage) brauchen nur noch die Summen
    local fcut = date("%Y-%m-%d", now - 180 * 86400)
    for _, r in ipairs(db.farms or {}) do
        if (r.date or "") < fcut then r.items, r.ip = nil, nil end
    end
    local n = 0 -- Zaehler des Preisverlaufs neu bestimmen
    for _ in pairs(db.hist or {}) do n = n + 1 end
    db.histN = n
    local after = #Serialize(db)
    Print(string.format("Aufgeräumt: %.0f KB vorher, %.0f KB jetzt.", before / 1024, after / 1024))
end

-- Selbsttest ------------------------------------------------------------------------------------------------------------
function GK.SelfTest()
    local ok, bad, warn = 0, 0, 0
    local function line(state, text)
        local col = state == "ok" and "|cff66ff66OK|r" or state == "warn" and ("|cffffd100" .. T("Hinweis") .. "|r") or ("|cffff5555" .. T("FEHLT") .. "|r")
        if state == "ok" then ok = ok + 1 elseif state == "warn" then warn = warn + 1 else bad = bad + 1 end
        if state ~= "ok" then print("   " .. col .. "  " .. T(text)) end
    end
    Print("Selbsttest läuft ...")
    -- 1. Teile des Addons
    for _, fn in ipairs({ "Build", "Refresh", "Toggle", "FarmStart", "FarmStop", "RefreshHud", "BuildHud", "UpdateBar",
        "BuildOptions", "ToggleOptions", "OpenPlus", "OpenMehr", "OpenAnalyse", "SellHelper", "OpenRouteEditor", "TotalGold",
        "FmtGold", "MarketPrice", "LiveWeek", "BeuteShow", "RegisterCommand", "OpenPage", "ApplyScale", "OpenSettings",
        "OpenTransfer", "Migrate", "T" }) do
        line(type(GK[fn]) == "function" and "ok" or "bad", "Funktion GK." .. fn)
    end
    -- 2. Spielfunktionen, auf die GoldKompass baut
    local api = {
        { "C_Item.GetItemInfo", C_Item and C_Item.GetItemInfo }, { "C_Item.GetItemQualityByID", C_Item and C_Item.GetItemQualityByID },
        { "C_Container.GetContainerItemInfo", C_Container and C_Container.GetContainerItemInfo },
        { "C_Map.GetBestMapForUnit", C_Map and C_Map.GetBestMapForUnit }, { "C_Timer.NewTicker", C_Timer and C_Timer.NewTicker },
        { "GetMoney", GetMoney }, { "GetInboxInvoiceInfo", GetInboxInvoiceInfo }, { "C_ChatInfo.SendAddonMessage", C_ChatInfo and C_ChatInfo.SendAddonMessage },
        { "TooltipDataProcessor", TooltipDataProcessor }, { "Settings.RegisterCanvasLayoutCategory", Settings and Settings.RegisterCanvasLayoutCategory },
    }
    for _, a in ipairs(api) do line(a[2] and "ok" or "bad", "Spielfunktion " .. a[1]) end
    line(C_Bank and C_Bank.FetchDepositedMoney and "ok" or "warn", "Kriegsmeute-Bank (C_Bank.FetchDepositedMoney)")
    -- 3. Preisquellen und Zusatz-Addons
    local auc = Auctionator and Auctionator.API and Auctionator.API.v1
    line((auc or TSM_API) and "ok" or "warn", "Preisquelle: " .. (auc and "Auctionator " or "") .. (TSM_API and "TSM" or "") ..
        ((auc or TSM_API) and "" or "keine (es gilt der Händlerpreis)"))
    line(LibStub and LibStub("LibDataBroker-1.1", true) and "ok" or "warn", "Anzeige in Titan Panel/ElvUI/Bazooka (LibDataBroker)")
    -- 4. Spielversion passt zur .toc
    local game = select(4, GetBuildInfo())
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local toc = get and tonumber(get("GoldKompass", "Interface"))
    if toc and game then line(toc >= game and "ok" or "warn", "Interface-Nummer: .toc " .. toc .. ", Spiel " .. game) end
    -- 5. Daten
    local db = DB()
    line(db and "ok" or "bad", "Gespeicherte Daten geladen")
    if db then line((db.dbVersion or 0) >= GK.DB_VERSION and "ok" or "bad", "Datenversion " .. tostring(db.dbVersion)) end
    -- 6. Hauptfenster laesst sich bauen und (wenn offen) fuellen
    local okBuild, err = pcall(GK.Build)
    line(okBuild and "ok" or "bad", "Hauptfenster bauen" .. (okBuild and "" or (": " .. tostring(err))))
    if GK.frame and GK.frame:IsShown() then
        local okRef, err2 = pcall(GK.Refresh)
        line(okRef and "ok" or "bad", "Hauptfenster füllen" .. (okRef and "" or (": " .. tostring(err2))))
    elseif GK.frame then
        line("warn", "Hauptfenster füllen: nur prüfbar, wenn die Übersicht offen ist (/gk, dann /gk selbsttest)")
    end
    Print(string.format("Selbsttest fertig: %d in Ordnung, %d Hinweise, %d Fehler.", ok, warn, bad))
end

-- Befehle -----------------------------------------------------------------------------------------------------------------
GK.RegisterCommand({ "sicherung", "backup" }, function() GK.OpenTransfer() end, "Sicherung: Einstellungen oder alle Daten exportieren/importieren")
GK.RegisterCommand({ "speicher", "memory" }, function(arg)
    arg = strlower(arg or "")
    if arg == "aufraeumen" or arg == "aufräumen" or arg == "clean" then GK.CleanMemory() else GK.ShowMemory() end
end, "Speicher anzeigen, speicher aufraeumen räumt alte Daten weg")
GK.RegisterCommand({ "selbsttest", "selftest" }, function() GK.SelfTest() end, "Prüft, ob alle Teile und Spielfunktionen da sind")
