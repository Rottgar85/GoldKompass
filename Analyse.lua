-- GoldKompass Analyse: Gold-Verlauf als Linie (30 / 90 / 365 Tage) und Items pro Stunde je Gebiet.
-- Eigenes Fenster: /gk verlauf, /gk items, Knopf "Verlauf" im Reiter Woche, Knopf "Items/h" im Reiter Farm.
-- Datenquellen: DB.totalHist (Tagesstand des Gesamtgolds, GoldKompass.lua), DB.days (Tagesbilanz, fuer Tage vor
-- dem ersten Tagesstand geschaetzt) und rec.items / rec.ip der Farm-Sessions (werden hier beim Stopp gespeichert).
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local GOLD = "|cffffd100"
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}
local function DB() return GK.DB() end
local function G(c) return GK.FmtGold(c) end
local function Theme()
    local db = DB()
    return COLORS[db and db.opt.theme or "gold"] or COLORS.gold
end
local function Short(c) -- kurze Goldangabe fuer Achsen: 950g, 12.5k, 1.2M
    local g = (c or 0) / 10000
    local a = math.abs(g)
    if a >= 1e6 then return string.format("%.1fM", g / 1e6) end
    if a >= 1e4 then return string.format("%.0fk", g / 1e3) end
    if a >= 1e3 then return string.format("%.1fk", g / 1e3) end
    return string.format("%dg", g >= 0 and floor(g + 0.5) or -floor(-g + 0.5))
end

local W, H = 560, 390
local CHART_L, CHART_T, CHART_R, CHART_B = 64, 92, 16, 46   -- Abstaende der Diagrammflaeche zum Fensterrand
local ROWS, RH, ROW_TOP = 14, 19, 92
local RANGES = { { 30, "30 Tage" }, { 90, "90 Tage" }, { 365, "1 Jahr" } }
local frame

-- Gold-Verlauf: Tageswerte -----------------------------------------------------------------------------------
-- Rueckgabe: Liste { key, label, v, est } vom aeltesten zum neuesten Tag. Fehlt der Tagesstand, wird er aus dem
-- naechsten Tag minus dessen Saldo geschaetzt. Vor dem ersten aufgezeichneten Tag beginnt die Liste nicht.
local function Earliest()
    local first
    local db = DB()
    for k in pairs(db.totalHist or {}) do if not first or k < first then first = k end end
    for k in pairs(db.days or {}) do if not first or k < first then first = k end end
    return first
end

local function Series(days)
    local db = DB()
    local hist, dayTbl = db.totalHist or {}, db.days or {}
    local t0 = date("*t"); t0.hour, t0.min, t0.sec = 12, 0, 0
    local noon = time(t0) -- Mittag, damit Sommer-/Winterzeit keinen Tag verschiebt
    local first = Earliest() or date("%Y-%m-%d")
    local rev = {}
    local nextVal, nextKey
    for i = 0, days - 1 do
        local t = noon - i * 86400
        local key = date("%Y-%m-%d", t)
        if key < first then break end
        local v, est = hist[key], false
        if not v then
            if i == 0 then
                v = GK.TotalGold()
            else
                local nd = dayTbl[nextKey]
                v = nextVal - (nd and ((nd.inn or 0) - (nd.out or 0)) or 0)
                est = true
            end
        end
        rev[#rev + 1] = { key = key, label = date("%d.%m.", t), v = v, est = est }
        nextVal, nextKey = v, key
    end
    local out = {}
    for i = #rev, 1, -1 do out[#out + 1] = rev[i] end
    return out
end

-- Items pro Stunde: Farm-Sessions nach Gebiet zusammenfassen ----------------------------------------------------
local function ItemZones()
    local zones, order = {}, {}
    for _, r in ipairs(DB().farms or {}) do
        if type(r.items) == "table" and (r.secs or 0) > 0 then
            local key = r.zone or r.name or "?"
            local z = zones[key]
            if not z then z = { name = key, secs = 0, n = 0, items = {}, price = {} }; zones[key] = z; order[#order + 1] = z end
            z.secs, z.n = z.secs + r.secs, z.n + 1
            for id, cnt in pairs(r.items) do
                z.items[id] = (z.items[id] or 0) + cnt
                if r.ip and r.ip[id] then z.price[id] = r.ip[id] end
            end
        end
    end
    table.sort(order, function(a, b) return a.secs > b.secs end)
    return order
end

-- Beim Stopp die Funde der Session speichern (die 40 wertvollsten), damit Items pro Stunde rechnen kann
local origStop = GK.FarmStop
function GK.FarmStop(...)
    local f = GK.farm
    local farms = DB() and DB().farms
    local n = farms and #farms or 0
    local result = origStop(...)
    farms = DB() and DB().farms
    if f and farms and #farms > n then
        local rec = farms[#farms]
        local list = {}
        for id, cnt in pairs(f.items or {}) do list[#list + 1] = { id = id, n = cnt, v = (f.price and f.price[id] or 0) * cnt } end
        table.sort(list, function(a, b) return a.v > b.v end)
        rec.items, rec.ip = {}, {}
        for i = 1, math.min(40, #list) do
            local e = list[i]
            rec.items[e.id] = e.n
            rec.ip[e.id] = f.price and f.price[e.id] or 0
        end
    end
    return result
end

-- Fenster ------------------------------------------------------------------------------------------------------
local function Btn(parent, text, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 20); b:SetText(text)
    return b
end

local function ItemName(id)
    local name = C_Item.GetItemInfo(id)
    local icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
    return (icon and ("|T" .. icon .. ":14|t ") or "") .. (name or ("Item " .. id))
end

local function Build()
    if frame then return end
    local f = CreateFrame("Frame", "GoldKompassAnalyseFrame", UIParent, "BackdropTemplate")
    f:SetSize(W, H)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    f:SetBackdropColor(0.04, 0.04, 0.07, 0.97)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "GoldKompassAnalyseFrame")
    f:Hide()

    local band = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    band:SetPoint("TOPLEFT", 2, -2); band:SetPoint("TOPRIGHT", -2, -2); band:SetHeight(28)
    band:SetColorTexture(0.16, 0.13, 0.03, 0.9)
    local logo = f:CreateTexture(nil, "OVERLAY")
    logo:SetSize(20, 20); logo:SetPoint("TOPLEFT", 8, -6); logo:SetTexture(GK.LOGO)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 6, 0); title:SetText("GoldKompass · Analyse")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24); close:SetPoint("TOPRIGHT", -2, -2)

    -- Reiter
    f.tabs = {}
    local TABS = { { "verlauf", "Gold-Verlauf" }, { "items", "Items pro Stunde" } }
    local tw = (W - 20) / #TABS
    for i, t in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(tw, 22); b:SetPoint("TOPLEFT", 10 + (i - 1) * tw, -34)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); b.text:SetPoint("CENTER"); b.text:SetText(t[2])
        b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetHeight(2)
        b.line:SetPoint("BOTTOMLEFT"); b.line:SetPoint("BOTTOMRIGHT")
        local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
        b:SetScript("OnClick", function() GK.OpenAnalyse(t[1]) end)
        f.tabs[t[1]] = b
    end
    f.bits = { verlauf = {}, items = {} }

    -- Verlauf: Zeitraum-Knoepfe, Info-Zeile, Diagramm
    local prev
    for _, r in ipairs(RANGES) do
        local b = Btn(f, r[2], 72)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("TOPLEFT", 12, -62) end
        b:SetScript("OnClick", function() DB().opt.chartDays = r[1]; GK.RefreshAnalyse() end)
        f.bits.verlauf[#f.bits.verlauf + 1] = b
        prev = b
    end
    f.info = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.info:SetPoint("LEFT", prev, "RIGHT", 12, 0); f.info:SetPoint("RIGHT", -12, 0)
    f.info:SetJustifyH("RIGHT"); f.info:SetWordWrap(false)
    f.bits.verlauf[#f.bits.verlauf + 1] = f.info

    local c = CreateFrame("Frame", nil, f)
    c:SetPoint("TOPLEFT", CHART_L, -CHART_T); c:SetPoint("BOTTOMRIGHT", -CHART_R, CHART_B)
    local cbg = c:CreateTexture(nil, "BACKGROUND"); cbg:SetAllPoints(); cbg:SetColorTexture(1, 1, 1, 0.03)
    c.lines, c.grid, c.ylab, c.xlab = {}, {}, {}, {}
    for i = 1, 4 do
        local g = c:CreateTexture(nil, "BORDER"); g:SetColorTexture(1, 1, 1, 0.08); g:SetHeight(1)
        c.grid[i] = g
        local l = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); l:SetJustifyH("RIGHT")
        c.ylab[i] = l
    end
    for i = 1, 3 do
        local l = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        c.xlab[i] = l
    end
    c.vline = c:CreateTexture(nil, "OVERLAY"); c.vline:SetColorTexture(1, 1, 1, 0.35); c.vline:SetWidth(1)
    c.dot = c:CreateTexture(nil, "OVERLAY"); c.dot:SetSize(7, 7); c.dot:SetColorTexture(1, 1, 1, 1)
    c.vline:Hide(); c.dot:Hide()
    c.empty = c:CreateFontString(nil, "OVERLAY", "GameFontDisable"); c.empty:SetPoint("CENTER")
    f.note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.note:SetPoint("BOTTOMLEFT", 12, 10); f.note:SetPoint("BOTTOMRIGHT", -12, 10); f.note:SetJustifyH("LEFT")
    c:EnableMouse(true)
    c:SetScript("OnEnter", function(self) self.hover = true end)
    c:SetScript("OnLeave", function(self) self.hover = false; self.vline:Hide(); self.dot:Hide(); GK.RefreshAnalyse(true) end)
    c:SetScript("OnUpdate", function(self)
        if not self.hover or not self.pts or #self.pts == 0 then return end
        local x = GetCursorPosition() / self:GetEffectiveScale() - self:GetLeft()
        local w = self:GetWidth()
        local n = #self.pts
        local i = n == 1 and 1 or math.max(1, math.min(n, floor(x / w * (n - 1) + 1.5)))
        local p = self.pts[i]
        self.vline:ClearAllPoints(); self.vline:SetPoint("TOP", self, "TOPLEFT", p.x, 0); self.vline:SetPoint("BOTTOM", self, "BOTTOMLEFT", p.x, 0)
        self.dot:ClearAllPoints(); self.dot:SetPoint("CENTER", self, "BOTTOMLEFT", p.x, p.y)
        self.vline:Show(); self.dot:Show()
        local d = p.d
        f.info:SetText(d.label .. "  " .. G(d.v) .. (d.est and "  |cff999999(geschätzt)|r" or ""))
    end)
    f.chart = c
    f.bits.verlauf[#f.bits.verlauf + 1] = c
    f.bits.verlauf[#f.bits.verlauf + 1] = f.note

    -- Items: Gebiet waehlen
    local left = Btn(f, "<", 26); left:SetPoint("TOPLEFT", 12, -62)
    local right = Btn(f, ">", 26); right:SetPoint("LEFT", left, "RIGHT", 4, 0)
    f.zoneText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.zoneText:SetPoint("LEFT", right, "RIGHT", 10, 0); f.zoneText:SetPoint("RIGHT", -12, 0)
    f.zoneText:SetJustifyH("LEFT"); f.zoneText:SetWordWrap(false)
    left:SetScript("OnClick", function() f.zoneIdx = (f.zoneIdx or 1) - 1; GK.RefreshAnalyse() end)
    right:SetScript("OnClick", function() f.zoneIdx = (f.zoneIdx or 1) + 1; GK.RefreshAnalyse() end)
    f.bits.items = { left, right, f.zoneText }
    f.rows = {}
    for i = 1, ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetPoint("TOPLEFT", 10, -ROW_TOP - (i - 1) * RH); r:SetPoint("TOPRIGHT", -10, -ROW_TOP - (i - 1) * RH); r:SetHeight(RH - 1)
        r.bar = r:CreateTexture(nil, "BACKGROUND"); r.bar:SetPoint("TOPLEFT"); r.bar:SetPoint("BOTTOMLEFT"); r.bar:SetWidth(1)
        if i % 2 == 0 then local z = r:CreateTexture(nil, "BACKGROUND", nil, -2); z:SetAllPoints(); z:SetColorTexture(1, 1, 1, 0.03) end
        local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
        r.r = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); r.r:SetPoint("RIGHT", -4, 0); r.r:SetJustifyH("RIGHT")
        r.l = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        r.l:SetPoint("LEFT", 4, 0); r.l:SetPoint("RIGHT", r.r, "LEFT", -6, 0); r.l:SetJustifyH("LEFT"); r.l:SetWordWrap(false)
        r:SetScript("OnEnter", function(self)
            if not self.itemId then return end
            GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetItemByID(self.itemId); GameTooltip:Show()
        end)
        r:SetScript("OnLeave", GameTooltip_Hide)
        f.rows[i] = r
    end

    f:SetScript("OnShow", function() GK.RefreshAnalyse() end)
    frame = f
end

-- Zeichnen: Gold-Verlauf -----------------------------------------------------------------------------------------
local function GetLine(c, i)
    local l = c.lines[i]
    if not l then l = c:CreateLine(nil, "ARTWORK"); l:SetThickness(2); c.lines[i] = l end
    return l
end

local function DrawChart(f, keepInfo)
    local c = f.chart
    for _, l in ipairs(c.lines) do l:Hide() end
    for _, g in ipairs(c.grid) do g:Hide() end
    for _, l in ipairs(c.ylab) do l:Hide() end
    for _, l in ipairs(c.xlab) do l:Hide() end
    c.pts = {}
    local days = DB().opt.chartDays or 30
    local s = Series(days)
    if #s < 2 then
        c.empty:SetText("Noch zu wenig Daten. Der Verlauf füllt sich ab heute jeden Tag.")
        c.empty:Show(); f.info:SetText(""); f.note:SetText("")
        return
    end
    c.empty:Hide()
    local lo, hi = math.huge, -math.huge
    for _, d in ipairs(s) do lo = math.min(lo, d.v); hi = math.max(hi, d.v) end
    if hi - lo < 10000 then hi = hi + 5000; lo = lo - 5000 end
    local pad = (hi - lo) * 0.08
    lo, hi = lo - pad, hi + pad
    local w, h = c:GetWidth(), c:GetHeight()
    local tc = Theme()
    -- Raster und Achsen
    for i = 1, 4 do
        local frac = (i - 1) / 3
        local y = frac * h
        local g = c.grid[i]
        g:ClearAllPoints(); g:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, y); g:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, y); g:Show()
        local l = c.ylab[i]
        l:ClearAllPoints(); l:SetPoint("RIGHT", c, "BOTTOMLEFT", -6, y); l:SetText(Short(lo + frac * (hi - lo))); l:Show()
    end
    local n = #s
    for i, idx in ipairs({ 1, floor((n + 1) / 2), n }) do
        local l = c.xlab[i]
        l:ClearAllPoints(); l:SetPoint("TOP", c, "BOTTOMLEFT", (idx - 1) / (n - 1) * w, -4); l:SetText(s[idx].label); l:Show()
    end
    -- Linie: geschaetzte Abschnitte grau, echte in der Designfarbe
    for i, d in ipairs(s) do
        c.pts[i] = { x = (i - 1) / (n - 1) * w, y = (d.v - lo) / (hi - lo) * h, d = d }
    end
    for i = 2, n do
        local a, b = c.pts[i - 1], c.pts[i]
        local l = GetLine(c, i - 1)
        l:SetStartPoint("BOTTOMLEFT", c, a.x, a.y); l:SetEndPoint("BOTTOMLEFT", c, b.x, b.y)
        if b.d.est then l:SetColorTexture(0.6, 0.6, 0.6, 0.7) else l:SetColorTexture(tc[1], tc[2], tc[3], 1) end
        l:Show()
    end
    c.dot:SetColorTexture(tc[1], tc[2], tc[3], 1)
    if not keepInfo or not c.hover then
        local diff = s[n].v - s[1].v
        f.info:SetText("Veränderung in " .. n .. " Tagen: " .. G(diff))
    end
    local firstReal
    for _, d in ipairs(s) do if not d.est then firstReal = d; break end end
    if s[1].est then
        f.note:SetText("Grau: aus der Tagesbilanz geschätzt (vor dem " .. (firstReal and firstReal.label or "heutigen Tag") ..
            "). Ab jetzt speichert GoldKompass jeden Tag den echten Stand.")
    else
        f.note:SetText("Gold aller Charaktere und der Kriegsmeute-Bank, jeweils der letzte Stand des Tages.")
    end
end

-- Zeichnen: Items pro Stunde ---------------------------------------------------------------------------------------
local function DrawItems(f)
    local zones = ItemZones()
    for _, r in ipairs(f.rows) do r:Hide(); r.itemId = nil end
    if #zones == 0 then
        f.zoneText:SetText("Noch keine Daten")
        local r = f.rows[1]
        r.l:SetText("Beende eine Farm-Session (ab dieser Version), dann erscheinen hier ihre Funde."); r.r:SetText(""); r.bar:Hide(); r:Show()
        return
    end
    -- Startauswahl: das aktuelle Gebiet, falls es Daten hat
    if not f.zoneIdx then
        local here = GetRealZoneText()
        for i, z in ipairs(zones) do if z.name == here then f.zoneIdx = i end end
        f.zoneIdx = f.zoneIdx or 1
    end
    if f.zoneIdx < 1 then f.zoneIdx = #zones elseif f.zoneIdx > #zones then f.zoneIdx = 1 end
    local z = zones[f.zoneIdx]
    f.zoneText:SetText(string.format("%s%s|r   %d Sessions, %d Min   (%d/%d)", GOLD, z.name, z.n, floor(z.secs / 60), f.zoneIdx, #zones))
    local list = {}
    for id, cnt in pairs(z.items) do
        local ph = cnt / z.secs * 3600
        list[#list + 1] = { id = id, ph = ph, vph = ph * (z.price[id] or 0) }
    end
    table.sort(list, function(a, b) return a.vph > b.vph end)
    local mx = list[1] and list[1].vph > 0 and list[1].vph or 1
    local tc = Theme()
    local total = 0
    for _, e in ipairs(list) do total = total + e.vph end
    for i = 1, math.min(ROWS - 1, #list) do
        local e, r = list[i], f.rows[i]
        r.itemId = e.id
        r.l:SetText(ItemName(e.id))
        r.r:SetText(string.format("%.1f / h   %s / h", e.ph, G(e.vph)))
        r.bar:SetColorTexture(tc[1], tc[2], tc[3], 0.22); r.bar:SetWidth(math.max(1, e.vph / mx * (W - 20))); r.bar:Show()
        r:Show()
    end
    local r = f.rows[math.min(ROWS - 1, #list) + 1]
    r.l:SetText(GOLD .. "Item-Wert zusammen|r"); r.r:SetText(G(total) .. " / h"); r.bar:Hide(); r:Show()
end

function GK.RefreshAnalyse(keepInfo)
    local f = frame
    if not f or not f:IsShown() then return end
    local tab = f.tab or "verlauf"
    local tc = Theme()
    f:SetBackdropBorderColor(tc[1], tc[2], tc[3], 1)
    for k, b in pairs(f.tabs) do
        b.line:SetColorTexture(tc[1], tc[2], tc[3], 1); b.line:SetShown(k == tab)
        if k == tab then b.text:SetTextColor(tc[1], tc[2], tc[3]) else b.text:SetTextColor(0.65, 0.65, 0.65) end
    end
    for name, list in pairs(f.bits) do
        for _, w in ipairs(list) do w:SetShown(name == tab) end
    end
    if tab == "verlauf" then
        for _, r in ipairs(f.rows) do r:Hide() end
        DrawChart(f, keepInfo)
    else
        DrawItems(f)
    end
end

function GK.OpenAnalyse(tab)
    Build()
    local f = frame
    if tab then f.tab = tab end
    if not f:IsShown() then
        f:ClearAllPoints()
        if GK.frame and GK.frame:IsShown() then f:SetPoint("TOPLEFT", GK.frame, "TOPRIGHT", 6, 0) else f:SetPoint("CENTER") end
        f:Show() -- OnShow zeichnet
    else
        GK.RefreshAnalyse()
    end
end

-- Knoepfe im Hauptfenster: "Verlauf" im Reiter Woche, "Items/h" im Reiter Farm -------------------------------------
local origBuild = GK.Build
function GK.Build(...)
    origBuild(...)
    local m = GK.frame
    if not m or m.gkAnalyseBtns or not m.bits then return end
    m.gkAnalyseBtns = true
    local wb = m.bits.woche and m.bits.woche[#m.bits.woche]
    if wb then
        local b = Btn(m, "Verlauf", 70); b:SetPoint("LEFT", wb, "RIGHT", 4, 0)
        b:SetScript("OnClick", function() GK.OpenAnalyse("verlauf") end)
        table.insert(m.bits.woche, b); b:Hide()
    end
    local xb = m.bits.farm and m.bits.farm[#m.bits.farm]
    if xb then
        local b = Btn(m, "Items/h", 64); b:SetPoint("RIGHT", xb, "LEFT", -4, 0)
        b:SetScript("OnClick", function() GK.OpenAnalyse("items") end)
        table.insert(m.bits.farm, b); b:Hide()
    end
end

-- Befehle ------------------------------------------------------------------------------------------------------------
GK.RegisterCommand("verlauf", function() GK.OpenAnalyse("verlauf") end, "Gold-Verlauf als Linie (30/90/365 Tage)")
GK.RegisterCommand({ "items", "itemsproh" }, function() GK.OpenAnalyse("items") end, "Items pro Stunde je Gebiet")
GK.CommandAlias.history = "verlauf"
