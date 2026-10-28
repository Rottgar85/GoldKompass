-- GoldKompass Mehr: Gebiete-Vergleich mit Trend, Schnäppchen-Alarm, Inventar aller Charaktere, Wochen-Export.
-- Eigenes Fenster (Knopf "Mehr" im Plus-Fenster oder /gk mehr).
local GK = GoldKompass
local GOLD, RED = "|cffffd100", "|cffff5555"
local C_GREEN, C_RED, C_GOLD, C_BLUE = { 0.4, 1, 0.4 }, { 1, 0.35, 0.35 }, { 1, 0.82, 0 }, { 0.35, 0.65, 1 }
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}
local function G(c) return GK.FmtGold(c) end
local function PlainG(c) return string.format("%dg", floor((c or 0) / 10000 + 0.5)) end
local function DB() return GK.DB() end
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(GOLD .. "GoldKompass|r: " .. m) end
local function Today() return date("%Y-%m-%d") end
local function Me() return UnitName("player") .. "-" .. GetRealmName() end
local function Net(r) return r.net or r.total or 0 end
local function Strip(s)
    s = tostring(s or "")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", "")
    return s
end

-- Gebiet je Session merken -------------------------------------------------------------------
local function ZoneName()
    local z = GetRealZoneText()
    if not z or z == "" then z = GetZoneText() end
    return (z and z ~= "") and z or nil
end

local origStart, origStop = GK.FarmStart, GK.FarmStop
function GK.FarmStart(name)
    local had = GK.farm
    origStart(name)
    if not had and GK.farm then GK.farm.zone = ZoneName() end
end
function GK.FarmStop()
    local f = GK.farm
    local n = #DB().farms
    origStop()
    if f and #DB().farms > n then DB().farms[#DB().farms].zone = f.zone end
end

-- Gebiete: Durchschnitt netto pro Stunde und Trend ----------------------------------------------
local function AreaData()
    local map, order = {}, {}
    for _, r in ipairs(DB().farms) do
        if (r.secs or 0) >= 300 then
            local key = r.zone or r.name or "?"
            local a = map[key]
            if not a then a = { name = key, net = 0, secs = 0, n = 0, list = {} }; map[key] = a; order[#order + 1] = a end
            a.net, a.secs, a.n = a.net + Net(r), a.secs + r.secs, a.n + 1
            a.list[#a.list + 1] = r
        end
    end
    for _, a in ipairs(order) do
        a.ph = a.net / a.secs * 3600
        if a.n >= 4 then
            local rn, rs, on, os = 0, 0, 0, 0
            for i, r in ipairs(a.list) do
                if i > a.n - 2 then rn, rs = rn + Net(r), rs + r.secs else on, os = on + Net(r), os + r.secs end
            end
            local recent, older = rn / rs * 3600, on / os * 3600
            if older > 0 then
                local d = (recent - older) / older
                a.trend = d
                a.trendText = d <= -0.2 and (RED .. "schwächer|r") or (d >= 0.2 and "|cff66ff66stärker|r" or "stabil")
            end
        end
    end
    table.sort(order, function(a, b) return a.ph > b.ph end)
    return order
end
GK.AreaData = AreaData

-- Schnäppchen: Preis deutlich unter dem eigenen Schnitt ------------------------------------------
local function DipPct()
    local p = DB().opt.dipPct or 25
    return math.max(10, math.min(60, p)) / 100
end
local function DipInfo(id)
    local h = DB().hist and DB().hist[id]
    if not h then return end
    local latest
    for k in pairs(h) do if not latest or k > latest then latest = k end end
    local sum, m = 0, 0
    for k, v in pairs(h) do if k ~= latest then sum, m = sum + v, m + 1 end end
    if m < 2 then return end
    local avg, cur = sum / m, h[latest]
    if avg < 1000 then return end -- unter 10 Silber ist es kein Schnäppchen
    return cur, avg, (cur - avg) / avg
end
local function Dips()
    local out, pct = {}, DipPct()
    for id in pairs(DB().hist or {}) do
        local cur, avg, dev = DipInfo(id)
        if cur and dev <= -pct then out[#out + 1] = { id = id, cur = cur, avg = avg, dev = dev } end
    end
    table.sort(out, function(a, b) return a.dev < b.dev end)
    return out
end

local function ItemLink(id)
    local _, link = C_Item.GetItemInfo(id)
    return link or ("Item " .. id)
end
local function ItemName(id)
    local name = C_Item.GetItemInfo(id)
    local icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
    return (icon and ("|T" .. icon .. ":12|t ") or "") .. (name or ("Item " .. id))
end

local function Refresh_Prices()
    -- Preise der Material-Liste und der Taschen auffrischen, damit der Verlauf aktuell bleibt
    local seen, n = {}, 0
    local function touch(id)
        if id and not seen[id] and n < 200 then seen[id] = true; n = n + 1; pcall(GK.MarketPrice, id) end
    end
    for _, id in ipairs(DB().matList or {}) do touch(id) end
    for bag = 0, 5 do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then touch(info.itemID) end
        end
    end
end

local function DipCheck()
    local db = DB()
    if not db or db.opt.dip == false then return end
    Refresh_Prices()
    db.dipSeen = db.dipSeen or {}
    local today, shown = Today(), 0
    for k, v in pairs(db.dipSeen) do if v ~= today then db.dipSeen[k] = nil end end
    for _, e in ipairs(Dips()) do
        if db.dipSeen[e.id] ~= today and shown < 3 then
            db.dipSeen[e.id] = today
            shown = shown + 1
            if db.opt.alarmChat ~= false then
                Print(string.format("|cff66ff66Schnäppchen:|r %s jetzt %s, Schnitt %s (%d%%)", ItemLink(e.id), G(e.cur), G(e.avg), floor(e.dev * 100 - 0.5)))
            end
        end
    end
    if shown > 0 and db.opt.alarmSound and GK.PlayAlarmSound then pcall(GK.PlayAlarmSound) end
end

-- Inventar aller Charaktere ---------------------------------------------------------------------
local bankOpen = false
local scanTimer

local function CountBags(bags)
    local list = {}
    for _, bag in ipairs(bags) do
        local ok, slots = pcall(C_Container.GetContainerNumSlots, bag)
        for slot = 1, (ok and slots or 0) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then list[info.itemID] = (list[info.itemID] or 0) + (info.stackCount or 1) end
        end
    end
    return list
end

local function Scan()
    scanTimer = nil
    local db = DB()
    if not db then return end
    db.inv = db.inv or {}
    local key = Me()
    local rec = db.inv[key] or {}
    db.inv[key] = rec
    rec.bags = CountBags({ 0, 1, 2, 3, 4, 5 })
    if bankOpen then rec.bank = CountBags({ -1, 6, 7, 8, 9, 10, 11 }) end
    rec.ts = time()
    if GK.mehr and GK.mehr:IsShown() then GK.RefreshMehr() end
end
local function ScanSoon()
    if not scanTimer then scanTimer = C_Timer.NewTimer(2, Scan) end
end

local invCache, invCacheAt
local function InvData()
    if invCache and GetTime() - invCacheAt < 3 then return invCache end
    local total = {}
    for char, rec in pairs(DB().inv or {}) do
        for _, part in ipairs({ rec.bags or {}, rec.bank or {} }) do
            for id, n in pairs(part) do
                local t = total[id]
                if not t then t = { id = id, n = 0, chars = {} }; total[id] = t end
                t.n = t.n + n
                t.chars[char] = (t.chars[char] or 0) + n
            end
        end
    end
    local list = {}
    for _, t in pairs(total) do list[#list + 1] = t end
    invCache, invCacheAt = list, GetTime()
    return list
end

local function ShortChar(c) return (c:gsub("%-.*$", "")) end
local function CharText(t)
    local parts = {}
    for c, n in pairs(t.chars) do parts[#parts + 1] = { ShortChar(c), n } end
    table.sort(parts, function(a, b) return a[2] > b[2] end)
    local out = {}
    for i = 1, math.min(2, #parts) do out[#out + 1] = parts[i][1] .. " " .. parts[i][2] end
    if #parts > 2 then out[#out + 1] = "+" .. (#parts - 2) end
    return table.concat(out, ", ")
end

-- Wochen-Export (reiner Text zum Kopieren) -----------------------------------------------------------
local function ExportText()
    local d = GK.RecapData()
    local L = {}
    L[#L + 1] = "GoldKompass Wochenbericht " .. d.from .. " bis " .. d.to
    L[#L + 1] = "Erhalten: " .. PlainG(d.inn) .. "   Ausgegeben: " .. PlainG(d.out) .. "   Saldo: " .. PlainG(d.inn - d.out)
    if d.pinn > 0 then
        local p = floor((d.inn - d.pinn) / d.pinn * 100 + 0.5)
        L[#L + 1] = "Vorwoche erhalten: " .. PlainG(d.pinn) .. " (" .. (p >= 0 and "+" or "") .. p .. "%)"
    end
    if d.farm then
        L[#L + 1] = "Beste Farm: " .. (d.farm.name or "?") .. (d.farm.route and (" mit Route " .. d.farm.route) or "") .. ", " .. PlainG(d.ph) .. " pro Stunde"
    end
    if d.trophy then
        L[#L + 1] = "Teuerster Drop: " .. Strip(d.trophy.link) .. (d.trophy.n > 1 and (" x" .. d.trophy.n) or "") .. ", " .. PlainG(d.trophy.v)
    end
    local areas = AreaData()
    if #areas > 0 then
        L[#L + 1] = "Beste Gebiete (netto pro Stunde):"
        for i = 1, math.min(3, #areas) do
            L[#L + 1] = "  " .. i .. ". " .. areas[i].name .. ": " .. PlainG(areas[i].ph) .. " (" .. areas[i].n .. " Sessions)"
        end
    end
    local sum, _, warbank = GK.TotalGold()
    L[#L + 1] = "Gold aller Charaktere und Kriegsmeute-Bank: " .. PlainG(sum) .. (warbank > 0 and (" (Bank " .. PlainG(warbank) .. ")") or "")
    for _, g in ipairs(DB().goals or {}) do
        local target = g.gold * 10000
        if target > 0 then L[#L + 1] = "Sparziel " .. g.name .. ": " .. floor(math.max(sum / target, 0) * 100) .. "%" end
    end
    return table.concat(L, "\n")
end

-- Fenster ----------------------------------------------------------------------------------------------
local PW, PH, ROWS, RH, TOP = 470, 335, 14, 17, 78
local ROWW = PW - 20
local BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 }
local TABS = { { "gebiete", "Gebiete" }, { "schnaeppchen", "Schnäppchen" }, { "inventar", "Inventar" }, { "export", "Export" } }

local function Btn(parent, text, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 20); b:SetText(text)
    return b
end
local function Label(parent, text)
    local l = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    l:SetText(text)
    return l
end
local function add(L, l, r, frac, col) L[#L + 1] = { l, r, frac, col } end
local function hd(L, text) add(L, GOLD .. text .. "|r", "") end

local function Color()
    return COLORS[DB().opt.theme or "gold"] or COLORS.gold
end
local function Paint(f)
    local c = Color()
    f:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    for k, b in pairs(f.tabs) do
        b.line:SetColorTexture(c[1], c[2], c[3], 1)
        if k == GK.mehrTab then b.text:SetTextColor(c[1], c[2], c[3]) else b.text:SetTextColor(0.65, 0.65, 0.65) end
    end
end

function GK.BuildMehr()
    if GK.mehr then return end
    local f = CreateFrame("Frame", "GoldKompassMehrFrame", UIParent, "BackdropTemplate")
    f:SetSize(PW, PH)
    if GK.plus then f:SetPoint("TOPLEFT", GK.plus, "BOTTOMLEFT", 0, -4) else f:SetPoint("CENTER", 0, -40) end
    f:SetBackdrop(BACKDROP); f:SetBackdropColor(0.05, 0.05, 0.08, 0.94)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "GoldKompassMehrFrame")
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -9); title:SetText("GoldKompass · Mehr")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24); close:SetPoint("TOPRIGHT", 0, 0)

    f.tabs = {}
    local tw = (PW - 20) / #TABS
    for i, t in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(tw, 20); b:SetPoint("TOPLEFT", 10 + (i - 1) * tw, -28)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.text:SetPoint("CENTER"); b.text:SetText(t[2])
        b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetColorTexture(1, 0.82, 0, 1); b.line:SetHeight(2)
        b.line:SetPoint("BOTTOMLEFT"); b.line:SetPoint("BOTTOMRIGHT")
        local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
        b:SetScript("OnClick", function() GK.mehrTab = t[1]; GK.RefreshMehr() end)
        f.tabs[t[1]] = b
    end
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, 1, 1, 0.12); sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 10, -49); sep:SetPoint("TOPRIGHT", -10, -49)

    f.bits = { gebiete = {}, schnaeppchen = {}, inventar = {}, export = {} }

    -- Gebiete: nur Hinweis
    local gh = Label(f, "Nur eigene Sessions ab 5 Minuten. Trend ab 4 Sessions je Gebiet.")
    gh:SetPoint("TOPLEFT", 12, -56); gh:SetTextColor(0.6, 0.6, 0.6)
    f.bits.gebiete = { gh }

    -- Schnäppchen: Alarm an/aus, Schwelle
    local dipBtn = Btn(f, "Alarm", 80); dipBtn:SetPoint("TOPLEFT", 10, -53)
    dipBtn:SetScript("OnClick", function()
        DB().opt.dip = (DB().opt.dip == false)
        GK.RefreshMehr()
    end)
    local minus = Btn(f, "-", 26); minus:SetPoint("LEFT", dipBtn, "RIGHT", 10, 0)
    local plus = Btn(f, "+", 26); plus:SetPoint("LEFT", minus, "RIGHT", 2, 0)
    local function step(d) DB().opt.dipPct = math.max(10, math.min(60, (DB().opt.dipPct or 25) + d)); GK.RefreshMehr() end
    minus:SetScript("OnClick", function() step(-5) end)
    plus:SetScript("OnClick", function() step(5) end)
    local dipLbl = Label(f, ""); dipLbl:SetPoint("LEFT", plus, "RIGHT", 8, 0)
    f.dipBtn, f.dipLbl = dipBtn, dipLbl
    f.bits.schnaeppchen = { dipBtn, minus, plus, dipLbl }

    -- Inventar: Suchfeld
    local sl = Label(f, "Suche"); sl:SetPoint("TOPLEFT", 12, -57)
    local se = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    se:SetSize(200, 18); se:SetPoint("LEFT", sl, "RIGHT", 10, 0); se:SetAutoFocus(false)
    se:SetScript("OnEscapePressed", se.ClearFocus)
    se:SetScript("OnTextChanged", function() GK.RefreshMehr() end)
    local sh = Label(f, "Name oder Item-ID"); sh:SetPoint("LEFT", se, "RIGHT", 8, 0); sh:SetTextColor(0.6, 0.6, 0.6)
    f.search = se
    f.bits.inventar = { sl, se, sh }

    -- Export: Textfeld zum Kopieren
    local eh = Label(f, "Alles markieren, Strg+C kopiert, dann im Gilden-Chat oder Notizbuch einfügen.")
    eh:SetPoint("TOPLEFT", 12, -56); eh:SetTextColor(0.6, 0.6, 0.6)
    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 12, -76); sf:SetPoint("BOTTOMRIGHT", -30, 40)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true); eb:SetFontObject("ChatFontNormal"); eb:SetWidth(PW - 60); eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    sf:SetScrollChild(eb)
    local nb = Btn(f, "Neu erstellen", 110); nb:SetPoint("BOTTOMLEFT", 12, 12)
    nb:SetScript("OnClick", function() eb:SetText(ExportText()); eb:SetFocus(); eb:HighlightText() end)
    f.exportBox = eb
    f.bits.export = { eh, sf, nb }

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

    f:SetScript("OnShow", function() GK.RefreshMehr() end)
    f.acc = 0
    f:SetScript("OnUpdate", function(self, e)
        self.acc = self.acc + e
        if self.acc >= 1 then self.acc = 0; Paint(self) end -- Designwechsel mitnehmen
    end)
    GK.mehr = f
end

local function Render(L)
    for i, r in ipairs(GK.mehr.rows) do
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

local function TabAreas(L)
    local areas = AreaData()
    hd(L, "Gebiete im Vergleich (netto pro Stunde)")
    if #areas == 0 then
        add(L, "   Noch keine Session ab 5 Minuten. Im Hauptfenster Farm: Start und Stopp.", "")
        return
    end
    local top = math.max(areas[1].ph, 1)
    for i = 1, math.min(11, #areas) do
        local a = areas[i]
        add(L, i .. ". " .. a.name .. "  (" .. a.n .. "x)", G(a.ph) .. "/h  " .. (a.trendText or "|cff888888Trend offen|r"),
            math.max(a.ph, 0) / top, a.trend and a.trend <= -0.2 and C_RED or C_BLUE)
    end
    add(L, " ", "")
    add(L, "|cff999999Der Trend vergleicht deine letzten 2 Sessions mit den früheren dort.|r", "")
end

local function TabDips(f, L)
    local on = DB().opt.dip ~= false
    f.dipBtn:SetText(on and "Alarm: an" or "Alarm: aus")
    f.dipLbl:SetText("meldet ab " .. floor(DipPct() * 100 + 0.5) .. "% unter dem Schnitt")
    local list = Dips()
    hd(L, "Gerade unter dem eigenen Schnitt (" .. #list .. ")")
    if #list == 0 then
        add(L, "   Nichts auffällig. Der Verlauf füllt sich beim Spielen (mindestens 3 Tage je Item).", "")
        return
    end
    for i = 1, math.min(11, #list) do
        local e = list[i]
        add(L, "   " .. ItemName(e.id), G(e.cur) .. "  " .. floor(e.dev * 100 - 0.5) .. "%", math.min(1, -e.dev / 0.6), C_GREEN)
    end
    add(L, " ", "")
    add(L, "|cff999999Schnitt = frühere Tage aus deinem Preisverlauf. Das ist kein Kauftipp.|r", "")
end

local function TabInventory(f, L)
    local q = strlower(strtrim(f.search:GetText() or ""))
    local list = InvData()
    local chars = 0
    for _ in pairs(DB().inv or {}) do chars = chars + 1 end
    hd(L, "Inventar (" .. chars .. " Charaktere, Taschen und besuchte Bank)")
    if #list == 0 then
        add(L, "   Noch nichts erfasst. Taschen werden beim Spielen mitgezählt, die Bank beim Öffnen.", "")
        return
    end
    local found = {}
    for _, t in ipairs(list) do
        local ok = q == ""
        if not ok then
            local name = C_Item.GetItemInfo(t.id)
            ok = (name and strfind(strlower(name), q, 1, true)) or tostring(t.id) == q
        end
        if ok then found[#found + 1] = t end
    end
    table.sort(found, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.id < b.id end)
    if #found == 0 then add(L, "   Kein Treffer.", ""); return end
    local mx = found[1].n
    for i = 1, math.min(11, #found) do
        local t = found[i]
        add(L, ItemName(t.id) .. "  x" .. t.n, CharText(t), t.n / mx, C_BLUE)
    end
    if #found > 11 then add(L, "|cff999999... und " .. (#found - 11) .. " weitere. Oben suchen, um einzugrenzen.|r", "") end
end

function GK.RefreshMehr()
    local f = GK.mehr
    if not f or not f:IsShown() then return end
    local tab = GK.mehrTab
    if not f.tabs[tab] then tab = "gebiete" end
    GK.mehrTab = tab
    for name, list in pairs(f.bits) do
        for _, w in ipairs(list) do w:SetShown(name == tab) end
    end
    Paint(f)
    local L = {}
    if tab == "gebiete" then TabAreas(L)
    elseif tab == "schnaeppchen" then TabDips(f, L)
    elseif tab == "inventar" then TabInventory(f, L)
    else
        if f.exportBox:GetText() == "" then f.exportBox:SetText(ExportText()) end
    end
    Render(L)
end

function GK.OpenMehr(tab)
    GK.BuildMehr()
    if tab then GK.mehrTab = tab end
    if tab == "export" then GK.mehr.exportBox:SetText("") end
    GK.mehr:Show()
    GK.RefreshMehr()
end
function GK.ToggleMehr()
    GK.BuildMehr()
    if GK.mehr:IsShown() then GK.mehr:Hide() else GK.OpenMehr() end
end

-- Knopf "Mehr" im Plus-Fenster ----------------------------------------------------------------------------
local function AddMehrButton()
    local p = GK.plus
    if p and not p.mehrBtn then
        local b = Btn(p, "Mehr", 50); b:SetHeight(18)
        b:SetPoint("TOPRIGHT", p, "TOPRIGHT", -28, -5)
        b:SetScript("OnClick", function() GK.ToggleMehr() end)
        p.mehrBtn = b
    end
end
if type(GK.BuildPlus) == "function" then hooksecurefunc(GK, "BuildPlus", AddMehrButton) end
if type(GK.Refresh) == "function" then
    hooksecurefunc(GK, "Refresh", function() if GK.mehr and GK.mehr:IsShown() then GK.RefreshMehr() end end)
end

-- Befehle ------------------------------------------------------------------------------------------------------
GK.RegisterCommand("mehr", function() GK.ToggleMehr() end, "Mehr-Fenster (Gebiete, Schnäppchen, Inventar, Bericht)")
GK.RegisterCommand("gebiete", function() GK.OpenMehr("gebiete") end, "Gebiete im Vergleich")
GK.RegisterCommand("inventar", function() GK.OpenMehr("inventar") end, "Inventar aller Charaktere")
GK.RegisterCommand("bericht", function() GK.OpenMehr("export") end, "Wochenbericht zum Kopieren")
GK.RegisterCommand({ "dip", "schnaeppchen" }, function(arg)
    local db = DB()
    arg = strlower(arg or "")
    if arg == "an" then db.opt.dip = true; Print("Schnäppchen-Alarm ist an.")
    elseif arg == "aus" then db.opt.dip = false; Print("Schnäppchen-Alarm ist aus.")
    elseif tonumber(arg) then
        db.opt.dipPct = math.max(10, math.min(60, tonumber(arg)))
        Print("Schnäppchen ab " .. db.opt.dipPct .. "% unter dem Schnitt.")
    else GK.OpenMehr("schnaeppchen") end
end, "Schnäppchen-Alarm: dip an|aus|25")

-- Start: Ereignisse, Alarm-Takt ------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do
    ev:RegisterEvent(e)
end
local function IsBanker(t)
    return Enum and Enum.PlayerInteractionType and t == Enum.PlayerInteractionType.Banker
end
ev:SetScript("OnEvent", function(_, event, a1)
    local db = DB()
    if not db then return end
    if event == "PLAYER_LOGIN" then
        if db.opt.dip == nil then db.opt.dip = true end
        C_Timer.After(5, Scan)
        C_Timer.After(25, DipCheck)
        C_Timer.NewTicker(300, DipCheck)
    elseif event == "BAG_UPDATE_DELAYED" then ScanSoon()
    elseif event == "BANKFRAME_OPENED" then bankOpen = true; ScanSoon()
    elseif event == "BANKFRAME_CLOSED" then Scan(); bankOpen = false
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then if IsBanker(a1) then bankOpen = true; ScanSoon() end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then if IsBanker(a1) then Scan(); bankOpen = false end end
end)
