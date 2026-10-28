-- GoldKompass Kompakt: schlankes Fenster (6 Reiter) und schlanke Optionen.
-- Ersetzt die breiten Fenster der anderen Dateien; die Daten- und Rechenlogik bleibt dort.
local GK = GoldKompass
local GOLD, RED = "|cffffd100", "|cffff5555"
local C_GREEN, C_RED, C_GOLD, C_PURPLE = { 0.4, 1, 0.4 }, { 1, 0.35, 0.35 }, { 1, 0.82, 0 }, { 0.65, 0.2, 0.75 }
local function G(c) return GK.FmtGold(c) end
local function Me() return UnitName("player") .. "-" .. GetRealmName() end
local function Num(s) s = tostring(s or ""):gsub(",", "."); return tonumber(s) end
local function Net(r) return r.net or r.total or 0 end

local W, H = 470, 380
local ROWS, RH, TOP = 16, 17, 78
local ROWW = W - 20
local BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }
local TABS = { { "heute", "Heute" }, { "woche", "Woche" }, { "farm", "Farm" }, { "beute", "Beute" }, { "chars", "Chars" }, { "gruppe", "Gruppe" } }
local ALIAS = { verlauf = "woche", historie = "farm", taschen = "beute", funde = "beute" }

local function Btn(parent, text, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 20); b:SetText(text)
    return b
end
local function Edit(parent, w)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(w, 18); e:SetAutoFocus(false); e:SetScript("OnEscapePressed", e.ClearFocus)
    return e
end
local function Label(parent, text)
    local l = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    l:SetText(text)
    return l
end
local function Panel(frame)
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.94)
    frame:SetBackdropBorderColor(0.45, 0.36, 0, 1)
end

-- Zeilenliste: add(L, links, rechts, Balken 0..1, Farbe)
local function add(L, l, r, frac, col) L[#L + 1] = { l, r, frac, col } end
local function hd(L, text) add(L, GOLD .. text .. "|r", "") end

-- Fenster -------------------------------------------------------------------------------
function GK.Build()
    if GK.frame then return end
    local f = CreateFrame("Frame", "GoldKompassFrame", UIParent, "BackdropTemplate")
    f:SetSize(W, H); f:SetPoint("CENTER"); Panel(f)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "GoldKompassFrame")
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -9); title:SetText("GoldKompass")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24); close:SetPoint("TOPRIGHT", 0, 0)
    local ob = Btn(f, "Optionen", 66); ob:SetHeight(18); ob:SetPoint("TOPRIGHT", -28, -5)
    ob:SetScript("OnClick", function() GK.ToggleOptions() end)
    f.optBtn = ob

    f.tabs = {}
    local tw = (W - 20) / #TABS
    for i, t in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(tw, 20); b:SetPoint("TOPLEFT", 10 + (i - 1) * tw, -28)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.text:SetPoint("CENTER"); b.text:SetText(t[2])
        b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetColorTexture(1, 0.82, 0, 1); b.line:SetHeight(2)
        b.line:SetPoint("BOTTOMLEFT"); b.line:SetPoint("BOTTOMRIGHT")
        local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
        b:SetScript("OnClick", function() GK.tab = t[1]; GK.Refresh() end)
        f.tabs[t[1]] = b
    end
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, 1, 1, 0.12); sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 10, -49); sep:SetPoint("TOPRIGHT", -10, -49)

    f.bits = { farm = {}, woche = {}, beute = {} }

    -- Farm: Start/Stopp oben, Kosten/Filter/Export unten
    f.start = Btn(f, "Start", 64); f.start:SetPoint("TOPLEFT", 10, -53)
    f.start:SetScript("OnClick", function() GK.FarmStart(); GK.Refresh() end)
    f.stop = Btn(f, "Stopp", 64); f.stop:SetPoint("LEFT", f.start, "RIGHT", 4, 0)
    f.stop:SetScript("OnClick", function() GK.FarmStop(); GK.Refresh() end)
    f.zone = Label(f, ""); f.zone:SetPoint("LEFT", f.stop, "RIGHT", 10, 0)
    local l1 = Label(f, "Kosten (g)"); l1:SetPoint("BOTTOMLEFT", 12, 10)
    local cost = Edit(f, 46); cost:SetPoint("LEFT", l1, "RIGHT", 8, 0)
    local cb = Btn(f, "Abziehen", 64); cb:SetPoint("LEFT", cost, "RIGHT", 4, 0)
    local function Book() GK.AddCost(Num(cost:GetText())); cost:SetText(""); cost:ClearFocus() end
    cb:SetScript("OnClick", Book); cost:SetScript("OnEnterPressed", Book)
    local l2 = Label(f, "Items ab (g)"); l2:SetPoint("LEFT", cb, "RIGHT", 14, 0)
    local flt = Edit(f, 40); flt:SetPoint("LEFT", l2, "RIGHT", 8, 0)
    local function SetFilter()
        local v = Num(flt:GetText()) or 0
        GK.DB().opt.minValue = v > 0 and v or 0
        flt:ClearFocus(); GK.RefreshHud(); GK.Refresh()
    end
    flt:SetScript("OnEnterPressed", SetFilter); flt:SetScript("OnEditFocusLost", SetFilter)
    local xb = Btn(f, "Export", 54); xb:SetPoint("BOTTOMRIGHT", -10, 8)
    xb:SetScript("OnClick", function() GK.ShowExport() end)
    f.filterBox = flt
    f.bits.farm = { f.start, f.stop, f.zone, l1, cost, cb, l2, flt, xb }

    -- Woche: Ziel
    local gl = Label(f, "Wochenziel (g)"); gl:SetPoint("TOPLEFT", 12, -57)
    local ge = Edit(f, 70); ge:SetPoint("LEFT", gl, "RIGHT", 10, 0)
    local gb = Btn(f, "Setzen", 64); gb:SetPoint("LEFT", ge, "RIGHT", 4, 0)
    local function Goal() GK.SetGoal(Num(ge:GetText())); ge:ClearFocus() end
    gb:SetScript("OnClick", Goal); ge:SetScript("OnEnterPressed", Goal)
    f.goalBox = ge
    f.bits.woche = { gl, ge, gb }

    -- Beute: Verkaufshelfer
    local sb = Btn(f, "Verkaufshelfer", 110); sb:SetPoint("TOPLEFT", 10, -53)
    sb:SetScript("OnClick", function() GK.SellHelper(false) end)
    f.bits.beute = { sb }

    f.rows = {}
    for i = 1, ROWS do
        local r = CreateFrame("Frame", nil, f)
        r:SetPoint("TOPLEFT", 10, -TOP - (i - 1) * RH); r:SetPoint("TOPRIGHT", -10, -TOP - (i - 1) * RH); r:SetHeight(RH - 1)
        r.bar = r:CreateTexture(nil, "BACKGROUND")
        r.bar:SetPoint("TOPLEFT"); r.bar:SetPoint("BOTTOMLEFT"); r.bar:SetWidth(1)
        r.r = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.r:SetPoint("RIGHT", -4, 0); r.r:SetJustifyH("RIGHT")
        r.l = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.l:SetPoint("LEFT", 4, 0); r.l:SetPoint("RIGHT", r.r, "LEFT", -6, 0); r.l:SetJustifyH("LEFT"); r.l:SetWordWrap(false)
        f.rows[i] = r
    end

    -- Fehler beim Fuellen melden, ohne das Oeffnen des Fensters aufzuhalten
    f:SetScript("OnShow", function()
        local ok, err = pcall(GK.Refresh)
        if not ok then geterrorhandler()(err) end
    end)
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, e)
        self.elapsed = self.elapsed + e
        if self.elapsed > 1 then
            self.elapsed = 0
            if GK.farm and (GK.tab == "farm" or GK.tab == "heute" or GK.tab == "gruppe") then pcall(GK.Refresh) end
        end
    end)
    GK.frame = f
end

local function Render(L)
    for i, r in ipairs(GK.frame.rows) do
        local d = L[i]
        if d then
            r:Show(); r.l:SetText(d[1] or ""); r.r:SetText(d[2] or "")
            if d[3] then
                local c = d[4] or C_GOLD
                r.bar:SetColorTexture(c[1], c[2], c[3], 0.28)
                r.bar:SetWidth(math.max(1, math.min(1, d[3]) * ROWW)); r.bar:Show()
            else
                r.bar:Hide()
            end
        else
            r:Hide()
        end
    end
end

-- Inhalte der Reiter ------------------------------------------------------------------------
local function TabHeute(L, DB)
    local d = DB.days[date("%Y-%m-%d")] or { inn = 0, out = 0, cat = {} }
    if not DB.opt.record then add(L, RED .. "Aufzeichnung ist aus (Optionen).|r", "") end
    add(L, "Gold gesamt (Charaktere und Kriegsmeute-Bank)", G((GK.TotalGold())))
    add(L, "Heute eingenommen", G(d.inn))
    add(L, "Heute ausgegeben", G(-d.out))
    add(L, "Saldo heute", G(d.inn - d.out))
    add(L, " ", "")
    hd(L, "Woher / wohin heute")
    local cats, mx = {}, 1
    for k, v in pairs(d.cat or {}) do cats[#cats + 1] = { k, v }; mx = math.max(mx, math.abs(v)) end
    table.sort(cats, function(a, b) return math.abs(a[2]) > math.abs(b[2]) end)
    for i = 1, math.min(8, #cats) do
        add(L, "   " .. cats[i][1], G(cats[i][2]), math.abs(cats[i][2]) / mx, cats[i][2] >= 0 and C_GREEN or C_RED)
    end
    if #cats == 0 then add(L, "   Noch nichts aufgezeichnet.", "") end
end

local function TabWoche(L, DB, f)
    if not f.goalBox:HasFocus() then f.goalBox:SetText(DB.weekGoal and tostring(DB.weekGoal) or "") end
    local net, cnt = GK.LiveWeek()
    local goal = DB.weekGoal
    hd(L, DB.opt.weekFarmOnly and "Wochenziel (Netto aus Farm-Sessions)" or "Wochenziel (erhaltenes Gold seit Montag)")
    if goal then
        local pct = net / (goal * 10000)
        add(L, G(net) .. " von " .. G(goal * 10000), floor(math.max(pct, 0) * 100) .. "%", pct, pct >= 1 and C_GREEN or C_PURPLE)
        add(L, pct >= 1 and "|cff66ff66Ziel erreicht!|r" or ("Noch offen: " .. G(goal * 10000 - net)), cnt .. " Sessions")
    else
        add(L, "Kein Ziel gesetzt: oben Betrag eintragen.", "")
        add(L, "Diese Woche bisher", G(net))
    end
    add(L, " ", "")
    hd(L, "Letzte 7 Tage (Saldo)")
    local days, mx, si, so = {}, 1, 0, 0
    for i = 6, 0, -1 do
        local t = time() - i * 86400
        local d = DB.days[date("%Y-%m-%d", t)]
        local n = d and (d.inn - d.out) or 0
        if d then si, so = si + d.inn, so + d.out end
        days[#days + 1] = { date("%a %d.%m.", t), n }
        mx = math.max(mx, math.abs(n))
    end
    for _, v in ipairs(days) do add(L, v[1], G(v[2]), math.abs(v[2]) / mx, v[2] >= 0 and C_GREEN or C_RED) end
    add(L, "Summe 7 Tage: ein " .. G(si) .. "  aus " .. G(so), G(si - so))
    -- Vergleich mit den 7 Tagen davor
    local prev = 0
    for i = 7, 13 do
        local d = DB.days[date("%Y-%m-%d", time() - i * 86400)]
        if d then prev = prev + d.inn - d.out end
    end
    local cur = si - so
    local trend
    if prev > 0 then
        local pct = floor((cur - prev) / prev * 100 + 0.5)
        trend = (pct >= 0 and "|cff66ff66+" or "|cffff5959") .. pct .. " %|r"
    else
        trend = cur > 0 and "|cff66ff66neu|r" or "-"
    end
    add(L, "Vergleich zu den 7 Tagen davor (" .. G(prev) .. ")", trend)
    -- Rekorde (Rekorde.lua)
    local r = DB.records
    if r then
        add(L, " ", "")
        hd(L, "Deine Rekorde")
        if r.hour then add(L, "Beste Farm-Stunde" .. (r.hourName and ("  (" .. r.hourName .. ")") or ""), G(r.hour)) end
        if r.day then add(L, "Bester Tag  (" .. (r.dayDate or "") .. ")", G(r.day)) end
        if r.week then add(L, "Beste Woche  (" .. (r.weekDate or "") .. ")", G(r.week)) end
    end
    -- Auktionshaus-Verkaeufe seit Montag (aus den Verkaufsbriefen, siehe GoldKompass.lua)
    local ws, sales = date("%Y-%m-%d", time() - ((date("*t").wday + 5) % 7) * 86400), 0
    for day, dd in pairs(DB.days) do
        if day >= ws and dd.cat then sales = sales + (dd.cat["Auktionshaus-Verkauf"] or 0) end
    end
    add(L, "Auktionshaus-Verkäufe diese Woche", G(sales))
end

local function TabFarm(L, DB, f)
    f.zone:SetText("Ort: " .. GOLD .. (GetRealZoneText() or "?") .. "|r")
    if not f.filterBox:HasFocus() then
        f.filterBox:SetText((DB.opt.minValue or 0) > 0 and tostring(DB.opt.minValue) or "")
    end
    local fm = GK.farm
    if fm then
        local secs = GetTime() - fm.start
        local costs = fm.costs or 0
        local total = fm.money + fm.value - costs
        add(L, GOLD .. "Läuft:|r " .. fm.name, string.format("%d:%02d", floor(secs / 60), floor(secs % 60)))
        add(L, "Rohgold", G(fm.money))
        add(L, "Item-Wert", G(fm.value))
        if costs > 0 then add(L, "Kosten", G(-costs)) end
        add(L, "Gold pro Stunde", G(secs > 30 and total / secs * 3600 or 0))
    else
        add(L, "Keine Session aktiv. Start startet eine für deinen Ort.", "")
    end
    local zones, order = {}, {}
    for _, r in ipairs(DB.farms) do
        local z = zones[r.name]
        if not z then z = { name = r.name, net = 0, secs = 0, n = 0 }; zones[r.name] = z; order[#order + 1] = z end
        z.net = z.net + Net(r); z.secs = z.secs + (r.secs or 0); z.n = z.n + 1
    end
    table.sort(order, function(a, b) return (a.secs > 0 and a.net / a.secs or 0) > (b.secs > 0 and b.net / b.secs or 0) end)
    hd(L, "Beste Gebiete (netto pro Stunde)")
    if #order == 0 then add(L, "   Noch keine beendete Session.", "") end
    local top = order[1] and order[1].secs > 0 and order[1].net / order[1].secs or 1
    for i = 1, math.min(3, #order) do
        local z = order[i]
        local ph = z.secs > 0 and z.net / z.secs * 3600 or 0
        add(L, i .. ". " .. z.name .. "  (" .. z.n .. "x)", G(ph) .. "/h", top > 0 and (ph / 3600) / top or 0)
    end
    hd(L, "Letzte Sessions")
    local total = #DB.farms
    for i = total, math.max(1, total - 1), -1 do
        local r = DB.farms[i]
        if r then add(L, (r.date or "?") .. "  " .. (r.name or "?"), G(Net(r)) .. "  " .. floor((r.secs or 0) / 60) .. " Min") end
    end
    if GK.Recommend then
        for _, line in ipairs(GK.Recommend()) do add(L, line, "") end
    end
end

local function TabBeute(L, DB)
    local total, top = GK.BagsValue()
    add(L, "Wert deiner Taschen", G(total))
    local bank = DB.bank and DB.bank[Me()]
    add(L, "Bank beim letzten Besuch", bank and G(bank.v) or "Bank einmal öffnen")
    hd(L, "Wertvollste Stapel")
    local mx = top[1] and top[1].v > 0 and top[1].v or 1
    for i = 1, math.min(6, #top) do add(L, "   " .. (top[i].link or "?"), G(top[i].v), top[i].v / mx) end
    hd(L, "Teuerste Funde")
    local t = DB.trophies or {}
    if #t == 0 then add(L, "   Noch nichts erfasst.", "") end
    for i = 1, math.min(5, #t) do
        local r = t[i]
        add(L, string.format("%d. %s%s  (%s)", i, r.link, r.n > 1 and (" x" .. r.n) or "", r.date), G(r.v))
    end
end

local function TabChars(L, DB)
    local list, total, money = {}, 0, 0
    for name, c in pairs(DB.chars) do
        local w = GK.CharWeek(name)
        list[#list + 1] = { name = name, week = w, money = c.money or 0 }
        total = total + w; money = money + (c.money or 0)
    end
    table.sort(list, function(a, b) return a.week > b.week end)
    local mx = 1
    for _, c in ipairs(list) do mx = math.max(mx, c.week) end
    hd(L, "Erhaltenes Gold diese Woche")
    for i = 1, math.min(7, #list) do add(L, i .. ". " .. list[i].name, G(list[i].week), list[i].week / mx) end
    add(L, "Alle zusammen", G(total))
    add(L, " ", "")
    add(L, GOLD .. "Gold auf den Charakteren|r", G(money))
    table.sort(list, function(a, b) return a.money > b.money end)
    for i = 1, math.min(4, #list) do add(L, "   " .. list[i].name, G(list[i].money)) end
    add(L, "Kriegsmeute-Bank", DB.warbank and G(DB.warbank.money) or "Bank einmal öffnen")
end

local function TabGruppe(L)
    hd(L, "Gruppen-Farm (alle brauchen GoldKompass)")
    if not (GK.Channel and GK.Channel()) then
        add(L, "   Du bist in keiner Gruppe.", "")
        return
    end
    local rows, fm = {}, GK.farm
    if fm then
        rows[#rows + 1] = { who = UnitName("player") .. " (du)", zone = fm.name, tot = fm.money + fm.value - (fm.costs or 0), secs = GetTime() - fm.start }
    end
    local n = 0
    for who, p in pairs(GK.peers) do
        if GetTime() - p.t < 30 then
            n = n + 1
            if p.farming then
                rows[#rows + 1] = { who = who, zone = p.zone, tot = (p.money or 0) + (p.value or 0) - (p.costs or 0), secs = p.secs or 0 }
            end
        end
    end
    if #rows == 0 then add(L, "   Niemand farmt gerade. Start drücken, dann sehen es die anderen.", "") end
    local all, maxSecs, mx = 0, 0, 1
    for _, r in ipairs(rows) do all = all + r.tot; maxSecs = math.max(maxSecs, r.secs); mx = math.max(mx, r.tot) end
    table.sort(rows, function(a, b) return a.tot > b.tot end)
    for i, r in ipairs(rows) do
        add(L, i .. ". " .. r.who .. "  " .. (r.zone or "?"),
            G(r.tot) .. "  " .. G(r.secs > 30 and r.tot / r.secs * 3600 or 0) .. "/h", r.tot / mx)
    end
    if #rows > 0 then
        add(L, " ", "")
        add(L, "Gemeinsam: " .. G(all) .. "  pro Kopf: " .. G(all / #rows), G(maxSecs > 30 and all / maxSecs * 3600 or 0) .. "/h")
    end
    add(L, "GoldKompass-Spieler in der Gruppe", tostring(n))
end

function GK.Refresh()
    if GK.UpdateBar then GK.UpdateBar() end
    local f = GK.frame
    if not f or not f:IsShown() then return end
    local tab = ALIAS[GK.tab] or GK.tab
    if not f.tabs[tab] then tab = "heute" end
    GK.tab = tab
    for k, b in pairs(f.tabs) do
        local on = k == tab
        b.line:SetShown(on)
        if on then b.text:SetTextColor(1, 0.82, 0) else b.text:SetTextColor(0.65, 0.65, 0.65) end
    end
    for name, list in pairs(f.bits) do
        for _, w in ipairs(list) do w:SetShown(name == tab) end
    end
    local DB, L = GK.DB(), {}
    if tab == "heute" then TabHeute(L, DB)
    elseif tab == "woche" then TabWoche(L, DB, f)
    elseif tab == "farm" then TabFarm(L, DB, f)
    elseif tab == "beute" then TabBeute(L, DB)
    elseif tab == "chars" then TabChars(L, DB)
    else TabGruppe(L) end
    Render(L)
end

-- Optionen: ein Panel über dem Fenster, zwei Spalten ---------------------------------------------
local OPTS = {
    { "record", "Gold aufzeichnen" }, { "farm", "Farm-Rechner" }, { "minimap", "Minimap-Button" }, { "welcome", "Begrüßung beim Login" },
    { "weekBar", "Wochenleiste zeigen" }, { "barLock", "Leiste sperren" }, { "autoRepair", "Reparatur als Kosten" }, { "weekFarmOnly", "Woche nur aus Farm" },
    { "lootSound", "Ton bei BoE-Beute" }, { "rareLoot", "Einblendung blau/episch" }, { "milestones", "Meilenstein-Ton" }, { "logoutSum", "Tagesbilanz beim Logout" },
    { "tipCompare", "Preise im Tooltip" }, { "sellHelper", "Verkaufshelfer" }, { "reminders", "Post/Auktions-Erinnerung" }, { "groupShare", "Gruppe: Daten teilen" },
    { "groupAutoJoin", "Gruppe: automatisch mit" }, { "alarm", "Preisalarm" }, { "alarmSound", "Alarm: Ton" }, { "alarmPopup", "Alarm: Einblendung" },
    { "alarmChat", "Alarm: Chat" },
}
local SOURCES = { { "auctionator", "Auctionator" }, { "tsmMarket", "TSM Marktwert" }, { "tsmMin", "TSM Mindestgebot" } }

function GK.BuildOptions()
    if GK.optFrame then return end
    GK.Build()
    local f = CreateFrame("Frame", "GoldKompassOptionsFrame", GK.frame, "BackdropTemplate")
    f:SetAllPoints(GK.frame); f:SetFrameLevel(GK.frame:GetFrameLevel() + 20); Panel(f)
    f:SetBackdropColor(0.05, 0.05, 0.08, 1)
    f:EnableMouse(true); f:Hide()
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -9); title:SetText("GoldKompass · Optionen")
    local back = Btn(f, "Fertig", 60); back:SetHeight(18); back:SetPoint("TOPRIGHT", -8, -5)
    back:SetScript("OnClick", function() f:Hide() end)

    f.checks = {}
    local per = math.ceil(#OPTS / 2)
    for i, c in ipairs(OPTS) do
        local col, row = floor((i - 1) / per), (i - 1) % per
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetSize(22, 22); cb:SetPoint("TOPLEFT", 10 + col * 228, -34 - row * 22)
        cb.text:SetText(c[2]); cb.text:SetFontObject("GameFontHighlightSmall")
        cb:SetScript("OnClick", function(self)
            GK.DB().opt[c[1]] = self:GetChecked() and true or false
            GK.ApplyOptions(); GK.UpdateBar()
        end)
        f.checks[c[1]] = cb
    end

    local y = -34 - per * 22 - 12
    local l1 = Label(f, "Alarm-Sound"); l1:SetPoint("TOPLEFT", 14, y)
    local dd = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", 110, y + 5); dd:SetWidth(210)
    dd:SetupMenu(function(_, root)
        root:SetScrollMode(320)
        for _, s in ipairs(GK.SoundList()) do
            root:CreateRadio(GK.T and GK.T(s.name) or s.name, function() return GK.DB().opt.sound == s.id end,
                function() GK.DB().opt.sound = s.id; GK.PlayAlarmSound(s.id) end)
        end
    end)
    local test = Btn(f, "Test", 56); test:SetPoint("LEFT", dd, "RIGHT", 6, 0)
    test:SetScript("OnClick", function() GK.PlayAlarmSound() end)
    f.soundDD = dd

    y = y - 32
    local l2 = Label(f, "Preisquelle"); l2:SetPoint("TOPLEFT", 14, y)
    local sd = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
    sd:SetPoint("TOPLEFT", 110, y + 5); sd:SetWidth(210)
    sd:SetupMenu(function(_, root)
        for _, s in ipairs(SOURCES) do
            root:CreateRadio(GK.T and GK.T(s[2]) or s[2], function() return GK.DB().opt.source == s[1] end,
                function() GK.DB().opt.source = s[1] end)
        end
    end)
    f.sourceDD = sd

    y = y - 32
    local l3 = Label(f, "Wertwarner ab (g, 0 = aus)"); l3:SetPoint("TOPLEFT", 14, y)
    local eb = Edit(f, 60); eb:SetPoint("TOPLEFT", 190, y + 4)
    local function Set()
        local v = Num(eb:GetText()) or 0
        GK.DB().opt.valueWarn = v > 0 and v or 0
        eb:ClearFocus()
    end
    eb:SetScript("OnEnterPressed", Set); eb:SetScript("OnEditFocusLost", Set)
    f.warnBox = eb

    f.note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.note:SetPoint("BOTTOMLEFT", 12, 10); f.note:SetWidth(W - 24); f.note:SetJustifyH("LEFT")
    f:SetScript("OnShow", function() GK.RefreshOptions() end)
    GK.optFrame = f
end

function GK.RefreshOptions()
    local f = GK.optFrame
    if not f then return end
    local o = GK.DB().opt
    for k, cb in pairs(f.checks) do cb:SetChecked(o[k] and true or false) end
    f.soundDD:GenerateMenu(); f.sourceDD:GenerateMenu()
    if not f.warnBox:HasFocus() then f.warnBox:SetText((o.valueWarn or 0) > 0 and tostring(o.valueWarn) or "") end
    local msg = ""
    if o.source == "auctionator" and not (Auctionator and Auctionator.API) then
        msg = RED .. "Auctionator nicht gefunden.|r Ersatz: Händlerpreis."
    elseif o.source ~= "auctionator" and not TSM_API then
        msg = RED .. "TSM nicht gefunden.|r Ersatz: Auctionator oder Händlerpreis."
    end
    f.note:SetText(msg)
end

-- Kleines Farm-Fenster (ersetzt das groessere aus GoldKompass.lua) -----------------------------------
local HUD_ITEMS = 5
function GK.BuildHud()
    if GK.hud then return end
    local h = CreateFrame("Frame", "GoldKompassFarmHud", UIParent, "BackdropTemplate")
    h:SetSize(220, 50 + HUD_ITEMS * 14); Panel(h); h:SetBackdropColor(0.05, 0.05, 0.08, 0.72)
    h:SetMovable(true); h:EnableMouse(true); h:RegisterForDrag("LeftButton"); h:SetClampedToScreen(true)
    h:SetScript("OnDragStart", h.StartMoving)
    h:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        GK.DB().hudPos = { p, rp, x, y }
    end)
    local pos = GK.DB().hudPos
    if pos then h:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else h:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0) end
    h.title = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h.title:SetPoint("TOPLEFT", 8, -6); h.title:SetWidth(170); h.title:SetJustifyH("LEFT"); h.title:SetWordWrap(false)
    local x = CreateFrame("Button", nil, h, "UIPanelCloseButton")
    x:SetSize(18, 18); x:SetPoint("TOPRIGHT", 0, 0)
    x:SetScript("OnClick", function() GK.FarmStop(); GK.Refresh() end)
    h.info = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h.info:SetPoint("TOPLEFT", 8, -20); h.info:SetJustifyH("LEFT"); h.info:SetSpacing(2)
    h.rows = {}
    for i = 1, HUD_ITEMS do
        local val = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        val:SetPoint("TOPRIGHT", -8, -44 - (i - 1) * 14); val:SetJustifyH("RIGHT")
        local name = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        name:SetPoint("TOPLEFT", 8, -44 - (i - 1) * 14); name:SetPoint("RIGHT", val, "LEFT", -4, 0)
        name:SetJustifyH("LEFT"); name:SetWordWrap(false)
        h.rows[i] = { name = name, val = val }
    end
    h.elapsed = 0
    h:SetScript("OnUpdate", function(self, e)
        self.elapsed = self.elapsed + e
        if self.elapsed >= 1 then self.elapsed = 0; GK.RefreshHud() end
    end)
    h:Hide()
    GK.hud = h
end

function GK.RefreshHud()
    local h, fm = GK.hud, GK.farm
    if not h or not fm then return end
    local secs = GetTime() - fm.start
    local total = fm.money + fm.value - (fm.costs or 0)
    h.title:SetText(fm.name)
    h.info:SetText(string.format("%d:%02d   %s/h\nRoh %s   Items %s", floor(secs / 60), floor(secs % 60),
        G(secs > 30 and total / secs * 3600 or 0), G(fm.money), G(fm.value)))
    local min = (GK.DB().opt.minValue or 0) * 10000
    local list = {}
    for id, n in pairs(fm.items) do
        local v = (fm.price[id] or 0) * n
        if v >= min then list[#list + 1] = { id = id, n = n, v = v } end
    end
    table.sort(list, function(a, b) return a.v > b.v end)
    for i, r in ipairs(h.rows) do
        local it = list[i]
        if it then
            local name = C_Item.GetItemInfo(it.id) or ("Item " .. it.id)
            local icon = C_Item.GetItemIconByID(it.id)
            r.name:SetText((icon and ("|T" .. icon .. ":12|t ") or "") .. name .. (it.n > 1 and (" x" .. it.n) or ""))
            r.val:SetText(G(it.v))
        else
            r.name:SetText(""); r.val:SetText("")
        end
    end
end

-- Wochenleiste: schmal und im gleichen Stil ----------------------------------------------------------
local origUpdateBar, barStyled = GK.UpdateBar, false
function GK.UpdateBar()
    if origUpdateBar then origUpdateBar() end
    local b = _G.GoldKompassWeekBar
    if b and not barStyled then
        barStyled = true
        b:SetSize(300, 14)
        b:SetBackdropColor(0.05, 0.05, 0.08, 0.8); b:SetBackdropBorderColor(0.45, 0.36, 0, 1)
        if b.sb then b.sb:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8") end
    end
end
