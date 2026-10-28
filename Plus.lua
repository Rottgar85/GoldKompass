-- GoldKompass Plus: Routes-Anbindung, Preisverlauf, Wochen-Rückblick, Sparziele, Material-Tracker, Farb-Designs.
-- Eigenes Zusatzfenster (Knopf "Plus" im Hauptfenster oder /gk plus). Die Routes-Daten werden nur gelesen.
local GK = GoldKompass
local GOLD, RED = "|cffffd100", "|cffff5555"
local C_GREEN, C_RED, C_GOLD, C_PURPLE = { 0.4, 1, 0.4 }, { 1, 0.35, 0.35 }, { 1, 0.82, 0 }, { 0.65, 0.2, 0.75 }
local function G(c) return GK.FmtGold(c) end
local function Num(s) s = tostring(s or ""):gsub(",", "."); return tonumber(s) end
local function DB() return GK.DB() end
local function Net(r) return r.net or r.total or 0 end
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(GOLD .. "GoldKompass|r: " .. m) end
local function Today() return date("%Y-%m-%d") end

-- Designs -----------------------------------------------------------------------------------
local THEMES = {
    gold = { "Gold", 1, 0.82, 0 }, blau = { "Blau", 0.35, 0.65, 1 }, gruen = { "Grün", 0.4, 0.9, 0.5 },
    violett = { "Violett", 0.75, 0.45, 1 }, rot = { "Rot", 1, 0.4, 0.4 },
}
local THEME_ORDER = { "gold", "blau", "gruen", "violett", "rot" }
local function Theme()
    local db = DB()
    return THEMES[db and db.opt.theme or "gold"] or THEMES.gold
end

local function ApplyTheme()
    if not DB() then return end
    local t = Theme()
    local r, g, b = t[2], t[3], t[4]
    local function border(fr)
        if fr and fr.SetBackdropBorderColor then fr:SetBackdropBorderColor(r * 0.55, g * 0.55, b * 0.55, 1) end
    end
    border(GK.frame); border(GK.optFrame); border(GK.plus); border(GK.hud); border(_G.GoldKompassWeekBar)
    if GK.frame then
        for k, btn in pairs(GK.frame.tabs) do
            btn.line:SetColorTexture(r, g, b, 1)
            if k == GK.tab then btn.text:SetTextColor(r, g, b) end
        end
    end
    if GK.plus then
        for k, btn in pairs(GK.plus.tabs) do
            btn.line:SetColorTexture(r, g, b, 1)
            if k == GK.plusTab then btn.text:SetTextColor(r, g, b) else btn.text:SetTextColor(0.65, 0.65, 0.65) end
        end
    end
end
GK.ApplyTheme = ApplyTheme

local function SetTheme(k)
    if not THEMES[k] then return end
    DB().opt.theme = k
    ApplyTheme()
end

-- Preisverlauf ------------------------------------------------------------------------------
local function Record(id, price)
    local d = DB()
    d.hist = d.hist or {}
    local h = d.hist[id]
    local day = Today()
    if not h then
        if (d.histN or 0) >= 500 then return end
        h = {}; d.hist[id] = h; d.histN = (d.histN or 0) + 1
    end
    if h[day] == price then return end
    h[day] = price
    local cut = date("%Y-%m-%d", time() - 30 * 86400)
    for k in pairs(h) do if k < cut then h[k] = nil end end
end

local origPrice = GK.MarketPrice
if origPrice then
    function GK.MarketPrice(id)
        local v = origPrice(id)
        local db = DB()
        if v and db and db.opt.priceHistory ~= false then Record(id, v) end
        return v
    end
end

-- aktueller Preis, Schnitt der früheren Tage, Abweichung, Anzahl Tage
local function HistInfo(id)
    local db = DB()
    local h = db and db.hist and db.hist[id]
    if not h then return end
    local latest, n = nil, 0
    for k in pairs(h) do n = n + 1; if not latest or k > latest then latest = k end end
    local sum, m = 0, 0
    for k, v in pairs(h) do if k ~= latest then sum = sum + v; m = m + 1 end end
    if m < 2 then return end
    local avg, cur = sum / m, h[latest]
    if avg <= 0 then return end
    return cur, avg, (cur - avg) / avg, n
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
        local db = DB()
        if not db or tt ~= GameTooltip or not data or not data.id then return end
        if db.opt.priceHistory == false then return end
        pcall(GK.MarketPrice, data.id)
        local cur, avg, dev, n = HistInfo(data.id)
        if not cur then return end
        local label
        if dev <= -0.15 then label = "|cff66ff66niedrig|r"
        elseif dev >= 0.15 then label = "|cffff7777hoch|r"
        else label = "normal" end
        tt:AddLine(string.format("GoldKompass: %s, Schnitt %s (%d Tage), %s", G(cur), G(avg), n, label), 1, 0.82, 0)
    end)
end

-- Wochen-Rückblick -------------------------------------------------------------------------
local function Range(a, b)
    local keys, inn, out = {}, 0, 0
    for i = a, b do
        local k = date("%Y-%m-%d", time() - i * 86400)
        keys[k] = true
        local d = DB().days[k]
        if d then inn = inn + (d.inn or 0); out = out + (d.out or 0) end
    end
    return keys, inn, out
end

function GK.RecapData()
    local mo = (tonumber(date("%w")) + 6) % 7
    local keys, inn, out = Range(mo + 1, mo + 7)
    local _, pinn = Range(mo + 8, mo + 14)
    local bestFarm, bestPh
    for _, r in ipairs(DB().farms) do
        if keys[r.date or ""] and (r.secs or 0) >= 300 then
            local ph = Net(r) / r.secs * 3600
            if not bestPh or ph > bestPh then bestFarm, bestPh = r, ph end
        end
    end
    local trophy
    for _, r in ipairs(DB().trophies or {}) do
        if keys[r.date or ""] and (not trophy or r.v > trophy.v) then trophy = r end
    end
    return {
        inn = inn, out = out, pinn = pinn, farm = bestFarm, ph = bestPh, trophy = trophy,
        from = date("%d.%m.", time() - (mo + 7) * 86400), to = date("%d.%m.", time() - (mo + 1) * 86400),
        weekKey = date("%Y-%m-%d", time() - mo * 86400),
    }
end

local function RecapLines()
    local d, L = GK.RecapData(), {}
    L[#L + 1] = { GOLD .. "Letzte Woche " .. d.from .. " bis " .. d.to .. "|r", "" }
    L[#L + 1] = { "Erhalten", G(d.inn) }
    L[#L + 1] = { "Ausgegeben", G(-d.out) }
    L[#L + 1] = { "Saldo", G(d.inn - d.out) }
    local cmp = "keine Daten"
    if d.pinn > 0 then
        local p = floor((d.inn - d.pinn) / d.pinn * 100 + 0.5)
        cmp = (p >= 0 and "+" or "") .. p .. "%"
    end
    L[#L + 1] = { "Vorwoche erhalten: " .. G(d.pinn), cmp }
    if d.farm then
        L[#L + 1] = { "Beste Farm: " .. (d.farm.name or "?") .. (d.farm.route and (" · " .. d.farm.route) or ""), G(d.ph) .. "/h" }
    else
        L[#L + 1] = { "Beste Farm: keine Session von mindestens 5 Minuten", "" }
    end
    if d.trophy then
        L[#L + 1] = { "Teuerster Drop: " .. d.trophy.link .. (d.trophy.n > 1 and (" x" .. d.trophy.n) or ""), G(d.trophy.v) }
    else
        L[#L + 1] = { "Teuerster Drop: keiner erfasst", "" }
    end
    return L
end

function GK.PrintRecap()
    for _, l in ipairs(RecapLines()) do Print(l[1] .. (l[2] ~= "" and ("  " .. l[2]) or "")) end
end

-- Routes-Anbindung (nur lesen) -------------------------------------------------------------
local function CurMap() return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") end
local function MapName(id)
    local i = id and C_Map.GetMapInfo(id)
    return i and i.name or tostring(id)
end
local function RoutesIn(map)
    local g = RoutesDB and RoutesDB.global
    local z = g and g.routes and map and g.routes[map]
    local out = {}
    if type(z) == "table" then
        for name, rd in pairs(z) do
            if type(name) == "string" and type(rd) == "table" and type(rd.route) == "table" then
                out[#out + 1] = { name = name, n = #rd.route }
            end
        end
    end
    return out
end
local function RouteExists(map, name)
    for _, r in ipairs(RoutesIn(map)) do if r.name == name then return true end end
end
local function Stat(map, name)
    local s = DB().routeStats
    return s and s[map .. "|" .. name]
end

local origStart, origStop = GK.FarmStart, GK.FarmStop
function GK.FarmStart(name)
    local had = GK.farm
    origStart(name)
    if had or not GK.farm then return end
    local map = CurMap()
    local sel = GK.routeSel
    local pick
    if map and sel and sel.map == map and RouteExists(map, sel.name) then pick = sel.name
    elseif map then
        local last = DB().routeLast and DB().routeLast[map]
        if last and RouteExists(map, last) then pick = last end
    end
    if pick then
        GK.farm.route = { map = map, name = pick }
        DB().routeLast = DB().routeLast or {}
        DB().routeLast[map] = pick
        Print("Route für diese Session: " .. GOLD .. pick .. "|r")
    end
end
function GK.FarmStop()
    local f = GK.farm
    local n = #DB().farms
    origStop()
    if f and f.route and #DB().farms > n then
        local rec = DB().farms[#DB().farms]
        rec.route, rec.map = f.route.name, f.route.map
        local s = DB().routeStats or {}
        DB().routeStats = s
        local key = f.route.map .. "|" .. f.route.name
        local st = s[key] or { map = f.route.map, name = f.route.name, net = 0, secs = 0, n = 0 }
        s[key] = st
        st.net, st.secs, st.n = st.net + Net(rec), st.secs + (rec.secs or 0), st.n + 1
    end
end

local origHud = GK.RefreshHud
function GK.RefreshHud()
    if origHud then origHud() end
    local h, fm = GK.hud, GK.farm
    if h and fm and fm.route then h.title:SetText(fm.name .. " · " .. fm.route.name) end
    if h then ApplyTheme() end
end

-- Sparziele ------------------------------------------------------------------------------------
local function TotalGold()
    return (GK.TotalGold()) -- Charaktere und Kriegsmeute-Bank
end
local function AvgDaily()
    local sum = 0
    for i = 0, 6 do
        local d = DB().days[date("%Y-%m-%d", time() - i * 86400)]
        if d then sum = sum + (d.inn or 0) - (d.out or 0) end
    end
    return sum / 7
end

-- Material ---------------------------------------------------------------------------------------
local function MatCount(id)
    if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(id, true) or 0 end
    return GetItemCount(id, true) or 0
end
local function MatBase(id)
    local d = DB()
    if not d.matBase or d.matBase.day ~= Today() then d.matBase = { day = Today(), c = {} } end
    if d.matBase.c[id] == nil then d.matBase.c[id] = MatCount(id) end
    return d.matBase.c[id]
end
local function ParseItem(text)
    text = strtrim(text or "")
    if text == "" then return end
    local n = tonumber(text)
    if n then return n end
    return (C_Item.GetItemInfoInstant(text))
end

-- Fenster --------------------------------------------------------------------------------------------
local PW, PH, ROWS, RH, TOP = 470, 335, 14, 17, 78
local ROWW = PW - 20
local BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }
local PTABS = { { "routen", "Routen" }, { "ziele", "Ziele" }, { "mats", "Material" }, { "preise", "Preise" }, { "rueck", "Rückblick" } }

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
local function add(L, l, r, frac, col, click) L[#L + 1] = { l, r, frac, col, click } end
local function hd(L, text) add(L, GOLD .. text .. "|r", "") end

function GK.BuildPlus()
    if GK.plus then return end
    local f = CreateFrame("Frame", "GoldKompassPlusFrame", UIParent, "BackdropTemplate")
    f:SetSize(PW, PH)
    if GK.frame then f:SetPoint("TOPLEFT", GK.frame, "TOPRIGHT", 4, 0) else f:SetPoint("CENTER") end
    f:SetBackdrop(BACKDROP); f:SetBackdropColor(0.05, 0.05, 0.08, 0.94)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "GoldKompassPlusFrame")
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -9); title:SetText("GoldKompass · Plus")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24); close:SetPoint("TOPRIGHT", 0, 0)

    f.tabs = {}
    local tw = (PW - 20) / #PTABS
    for i, t in ipairs(PTABS) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(tw, 20); b:SetPoint("TOPLEFT", 10 + (i - 1) * tw, -28)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.text:SetPoint("CENTER"); b.text:SetText(t[2])
        b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetColorTexture(1, 0.82, 0, 1); b.line:SetHeight(2)
        b.line:SetPoint("BOTTOMLEFT"); b.line:SetPoint("BOTTOMRIGHT")
        local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
        b:SetScript("OnClick", function() GK.plusTab = t[1]; GK.RefreshPlus() end)
        f.tabs[t[1]] = b
    end
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, 1, 1, 0.12); sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 10, -49); sep:SetPoint("TOPRIGHT", -10, -49)

    f.bits = { routen = {}, ziele = {}, mats = {}, preise = {}, rueck = {} }

    -- Routen: Karte öffnen, Auswahl lösen
    local mapBtn = Btn(f, "Karte öffnen", 96); mapBtn:SetPoint("TOPLEFT", 10, -53)
    mapBtn:SetScript("OnClick", function()
        local map = CurMap()
        if map and OpenWorldMap then pcall(OpenWorldMap, map) elseif ToggleWorldMap then ToggleWorldMap() end
    end)
    local clrBtn = Btn(f, "Auswahl lösen", 96); clrBtn:SetPoint("LEFT", mapBtn, "RIGHT", 4, 0)
    clrBtn:SetScript("OnClick", function() GK.routeSel = nil; GK.RefreshPlus() end)
    local hint = Label(f, "Route anklicken, dann Start im Hauptfenster"); hint:SetPoint("LEFT", clrBtn, "RIGHT", 10, 0)
    hint:SetTextColor(0.6, 0.6, 0.6)
    f.bits.routen = { mapBtn, clrBtn, hint }

    -- Ziele: Name, Betrag, Merken, Löschen
    local gl = Label(f, "Ziel"); gl:SetPoint("TOPLEFT", 12, -57)
    local gName = Edit(f, 110); gName:SetPoint("LEFT", gl, "RIGHT", 8, 0)
    local gl2 = Label(f, "Gold"); gl2:SetPoint("LEFT", gName, "RIGHT", 10, 0)
    local gAmt = Edit(f, 64); gAmt:SetPoint("LEFT", gl2, "RIGHT", 8, 0)
    local gSave = Btn(f, "Merken", 56); gSave:SetPoint("LEFT", gAmt, "RIGHT", 4, 0)
    local gDel = Btn(f, "Löschen", 56); gDel:SetPoint("LEFT", gSave, "RIGHT", 2, 0)
    gSave:SetScript("OnClick", function()
        local gold = Num(gAmt:GetText())
        local name = strtrim(gName:GetText())
        if not gold or gold <= 0 then Print("Bitte einen Betrag in Gold eintragen."); return end
        if name == "" then name = "Ziel" end
        local list = DB().goals or {}
        DB().goals = list
        local done
        for _, g in ipairs(list) do
            if strlower(g.name) == strlower(name) then g.name, g.gold, done = name, gold, true end
        end
        if not done then
            if #list >= 6 then Print("Mehr als sechs Ziele gehen nicht."); return end
            list[#list + 1] = { name = name, gold = gold }
        end
        gName:SetText(""); gAmt:SetText(""); gName:ClearFocus(); gAmt:ClearFocus()
        GK.RefreshPlus()
    end)
    gDel:SetScript("OnClick", function()
        local list = DB().goals or {}
        local name = strtrim(gName:GetText())
        for i = #list, 1, -1 do
            if name == "" or strlower(list[i].name) == strlower(name) then table.remove(list, i); break end
        end
        gName:SetText(""); gName:ClearFocus()
        GK.RefreshPlus()
    end)
    f.bits.ziele = { gl, gName, gl2, gAmt, gSave, gDel }

    -- Material: Item einfügen oder Shift-Klick
    local mEdit = Edit(f, 190); mEdit:SetPoint("TOPLEFT", 16, -55)
    GK.matEdit = mEdit
    local mAdd = Btn(f, "Merken", 56); mAdd:SetPoint("LEFT", mEdit, "RIGHT", 6, 0)
    local mDel = Btn(f, "Weg", 44); mDel:SetPoint("LEFT", mAdd, "RIGHT", 2, 0)
    local mHint = Label(f, "Item-ID, Name oder Shift-Klick"); mHint:SetPoint("LEFT", mDel, "RIGHT", 8, 0)
    mHint:SetTextColor(0.6, 0.6, 0.6)
    mAdd:SetScript("OnClick", function()
        local id = ParseItem(mEdit:GetText())
        if not id then Print("Dieses Item kenne ich nicht. Item-ID oder Link einfügen."); return end
        local list = DB().matList or {}
        DB().matList = list
        for _, v in ipairs(list) do if v == id then mEdit:SetText(""); GK.RefreshPlus(); return end end
        if #list >= 12 then Print("Mehr als zwölf Materialien gehen nicht."); return end
        list[#list + 1] = id
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        MatBase(id)
        mEdit:SetText(""); mEdit:ClearFocus(); GK.RefreshPlus()
    end)
    mDel:SetScript("OnClick", function()
        local id = ParseItem(mEdit:GetText())
        local list = DB().matList or {}
        for i = #list, 1, -1 do
            if id and list[i] == id then table.remove(list, i); break end
        end
        mEdit:SetText(""); mEdit:ClearFocus(); GK.RefreshPlus()
    end)
    f.bits.mats = { mEdit, mAdd, mDel, mHint }

    -- Rückblick
    local rb = Btn(f, "Im Chat zeigen", 110); rb:SetPoint("TOPLEFT", 10, -53)
    rb:SetScript("OnClick", function() GK.PrintRecap() end)
    f.bits.rueck = { rb }

    f.rows = {}
    for i = 1, ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetPoint("TOPLEFT", 10, -TOP - (i - 1) * RH); r:SetPoint("TOPRIGHT", -10, -TOP - (i - 1) * RH); r:SetHeight(RH - 1)
        r.bar = r:CreateTexture(nil, "BACKGROUND")
        r.bar:SetPoint("TOPLEFT"); r.bar:SetPoint("BOTTOMLEFT"); r.bar:SetWidth(1)
        local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
        r.r = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.r:SetPoint("RIGHT", -4, 0); r.r:SetJustifyH("RIGHT")
        r.l = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.l:SetPoint("LEFT", 4, 0); r.l:SetPoint("RIGHT", r.r, "LEFT", -6, 0); r.l:SetJustifyH("LEFT"); r.l:SetWordWrap(false)
        r:SetScript("OnClick", function(self) if self.click then self.click() end end)
        f.rows[i] = r
    end

    f:SetScript("OnShow", function() GK.RefreshPlus() end)
    GK.plus = f
    ApplyTheme()
end

local function Render(L)
    for i, r in ipairs(GK.plus.rows) do
        local d = L[i]
        if d then
            r:Show(); r.l:SetText(d[1] or ""); r.r:SetText(d[2] or "")
            r.click = d[5]; r:EnableMouse(d[5] ~= nil)
            if d[3] then
                local c = d[4] or C_GOLD
                r.bar:SetColorTexture(c[1], c[2], c[3], 0.28)
                r.bar:SetWidth(math.max(1, math.min(1, d[3]) * ROWW)); r.bar:Show()
            else
                r.bar:Hide()
            end
        else
            r:Hide(); r.click = nil
        end
    end
end

-- Inhalte -------------------------------------------------------------------------------------------------
local function TabRoutes(L)
    local map = CurMap()
    local sel = GK.routeSel
    hd(L, "Routen in " .. MapName(map))
    if not RoutesDB then
        add(L, RED .. "Routes ist nicht geladen.|r", "")
        add(L, "   Routes muss als Addon aktiv sein.", "")
    else
        local list = RoutesIn(map)
        if #list == 0 then
            add(L, "   Hier gibt es noch keine Route. Lege sie in Routes an.", "")
        else
            local top = 1
            for _, r in ipairs(list) do
                local st = Stat(map, r.name)
                r.ph = st and st.secs > 0 and st.net / st.secs * 3600 or nil
                if r.ph and r.ph > top then top = r.ph end
            end
            table.sort(list, function(a, b)
                if (a.ph or -1) ~= (b.ph or -1) then return (a.ph or -1) > (b.ph or -1) end
                return a.name < b.name
            end)
            for i = 1, math.min(7, #list) do
                local r = list[i]
                local on = sel and sel.map == map and sel.name == r.name
                local st = Stat(map, r.name)
                local name = r.name
                add(L, (on and (GOLD .. "> |r") or "   ") .. name .. "  (" .. r.n .. " Punkte)",
                    st and (G(r.ph or 0) .. "/h  " .. st.n .. "x") or "noch nicht gefarmt",
                    r.ph and math.max(r.ph, 0) / top or nil, C_PURPLE,
                    function() GK.routeSel = { map = map, name = name }; GK.RefreshPlus() end)
            end
        end
    end
    if GK.farm and GK.farm.route then
        add(L, GOLD .. "Läuft mit Route:|r " .. GK.farm.route.name, "")
    elseif sel and sel.map == map then
        add(L, "Gewählt: " .. sel.name .. " (gilt beim nächsten Start)", "")
    end
    add(L, " ", "")
    hd(L, "Beste Routen (netto pro Stunde)")
    local all = {}
    for _, st in pairs(DB().routeStats or {}) do
        if st.secs and st.secs > 0 then all[#all + 1] = { st = st, ph = st.net / st.secs * 3600 } end
    end
    table.sort(all, function(a, b) return a.ph > b.ph end)
    if #all == 0 then add(L, "   Noch keine Session mit Route beendet.", "") end
    local mx = all[1] and all[1].ph > 0 and all[1].ph or 1
    for i = 1, math.min(5, #all) do
        local a = all[i]
        add(L, i .. ". " .. a.st.name .. " · " .. MapName(a.st.map), G(a.ph) .. "/h  " .. a.st.n .. "x", math.max(a.ph, 0) / mx)
    end
end

local function TabGoals(L)
    local cur, avg = TotalGold(), AvgDaily()
    hd(L, "Sparziele (Charaktere und Kriegsmeute-Bank)")
    add(L, "Du hast", G(cur))
    add(L, "Schnitt pro Tag (7 Tage)", G(avg))
    add(L, " ", "")
    local goals = DB().goals or {}
    if #goals == 0 then add(L, "   Noch kein Ziel. Name und Betrag oben eintragen.", "") end
    for _, g in ipairs(goals) do
        local target = g.gold * 10000
        local pct = target > 0 and cur / target or 0
        add(L, g.name .. "  (" .. G(target) .. ")", floor(math.max(pct, 0) * 100) .. "%", pct, pct >= 1 and C_GREEN or C_GOLD)
        local miss = target - cur
        local eta
        if miss <= 0 then eta = "|cff66ff66Ziel erreicht!|r"
        elseif avg > 0 then
            local days = math.ceil(miss / avg)
            eta = "etwa " .. days .. " Tage (bis " .. date("%d.%m.", time() + days * 86400) .. ")"
        else
            eta = "kein Plus in den letzten 7 Tagen"
        end
        add(L, "   Noch " .. G(math.max(miss, 0)), eta)
    end
end

local function ItemName(id)
    local name = C_Item.GetItemInfo(id)
    local icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
    return (icon and ("|T" .. icon .. ":12|t ") or "") .. (name or ("Item " .. id))
end

local function TabMats(L)
    local list = DB().matList or {}
    hd(L, "Material (Bestand inkl. Bank, Wert nach Preisquelle)")
    if #list == 0 then add(L, "   Noch nichts gewählt. Item oben einfügen.", ""); return end
    local total, mx, rows = 0, 1, {}
    for _, id in ipairs(list) do
        local n = MatCount(id)
        local price = GK.MarketPrice(id)
        if not price then
            local sell = select(11, C_Item.GetItemInfo(id))
            price = sell or 0
        end
        local base = MatBase(id)
        rows[#rows + 1] = { id = id, n = n, v = n * price, plus = n - base }
        total = total + n * price
        mx = math.max(mx, n * price)
    end
    for _, r in ipairs(rows) do
        local d = r.plus
        local ds = d > 0 and ("|cff66ff66+" .. d .. "|r") or (d < 0 and (RED .. d .. "|r") or "±0")
        add(L, ItemName(r.id) .. "  x" .. r.n, G(r.v) .. "  " .. ds .. " heute", r.v / mx)
    end
    add(L, " ", "")
    add(L, "Gesamtwert", G(total))
end

local lastScan = -999
local function TabPrices(L)
    if GetTime() - lastScan > 60 then
        lastScan = GetTime()
        for bag = 0, 4 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID then pcall(GK.MarketPrice, info.itemID) end
            end
        end
    end
    local low, high, count = {}, {}, 0
    for id in pairs(DB().hist or {}) do
        local cur, avg, dev, n = HistInfo(id)
        if cur then
            count = count + 1
            local e = { id = id, cur = cur, avg = avg, dev = dev }
            if dev <= -0.1 then low[#low + 1] = e elseif dev >= 0.1 then high[#high + 1] = e end
        end
    end
    hd(L, "Preisverlauf (" .. count .. " Items mit mindestens 3 Tagen)")
    if count == 0 then
        add(L, "   Noch zu wenig Daten. Der Verlauf füllt sich beim Spielen.", "")
        add(L, "   Preise werden aus Beute, Taschen und Tooltips erfasst.", "")
        return
    end
    table.sort(low, function(a, b) return a.dev < b.dev end)
    table.sort(high, function(a, b) return a.dev > b.dev end)
    hd(L, "Preis unter dem Schnitt")
    if #low == 0 then add(L, "   Nichts auffällig.", "") end
    for i = 1, math.min(5, #low) do
        local e = low[i]
        add(L, "   " .. ItemName(e.id), G(e.cur) .. "  " .. floor(e.dev * 100 + 0.5) .. "%", math.min(1, -e.dev / 0.6), C_GREEN)
    end
    hd(L, "Preis über dem Schnitt")
    if #high == 0 then add(L, "   Nichts auffällig.", "") end
    for i = 1, math.min(5, #high) do
        local e = high[i]
        add(L, "   " .. ItemName(e.id), G(e.cur) .. "  +" .. floor(e.dev * 100 + 0.5) .. "%", math.min(1, e.dev / 0.6), C_RED)
    end
end

function GK.RefreshPlus()
    local f = GK.plus
    if not f or not f:IsShown() then return end
    local tab = GK.plusTab
    if not f.tabs[tab] then tab = "routen" end
    GK.plusTab = tab
    for name, list in pairs(f.bits) do
        for _, w in ipairs(list) do w:SetShown(name == tab) end
    end
    ApplyTheme()
    local L = {}
    if tab == "routen" then TabRoutes(L)
    elseif tab == "ziele" then TabGoals(L)
    elseif tab == "mats" then TabMats(L)
    elseif tab == "preise" then TabPrices(L)
    else
        for _, l in ipairs(RecapLines()) do add(L, l[1], l[2]) end
    end
    Render(L)
end

function GK.OpenPlus(tab)
    GK.BuildPlus()
    if tab then GK.plusTab = tab end
    GK.plus:Show()
    GK.RefreshPlus()
end
function GK.TogglePlus()
    GK.BuildPlus()
    if GK.plus:IsShown() then GK.plus:Hide() else GK.OpenPlus() end
end

-- Einhängen in vorhandene Funktionen ----------------------------------------------------------------------
local origBuild = GK.Build
function GK.Build()
    origBuild()
    local f = GK.frame
    if f and not f.plusBtn then
        local b = Btn(f, "Plus", 50); b:SetHeight(18)
        b:SetPoint("TOPRIGHT", f, "TOPRIGHT", -98, -5)
        b:SetScript("OnClick", function() GK.TogglePlus() end)
        f.plusBtn = b
        ApplyTheme()
    end
end

local origRefresh = GK.Refresh
function GK.Refresh()
    origRefresh()
    ApplyTheme()
    if GK.plus and GK.plus:IsShown() then GK.RefreshPlus() end
end

local origBar = GK.UpdateBar
function GK.UpdateBar()
    if origBar then origBar() end
    ApplyTheme()
end

local origOptions = GK.BuildOptions
function GK.BuildOptions()
    origOptions()
    local f = GK.optFrame
    if f and not f.themeDD then
        local l = Label(f, "Design"); l:SetPoint("TOPLEFT", 272, -352)
        local dd = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
        dd:SetPoint("TOPLEFT", 322, -347); dd:SetWidth(130)
        dd:SetupMenu(function(_, root)
            for _, k in ipairs(THEME_ORDER) do
                root:CreateRadio(GK.T and GK.T(THEMES[k][1]) or THEMES[k][1], function() return (DB().opt.theme or "gold") == k end,
                    function() SetTheme(k) end)
            end
        end)
        f.themeDD = dd
        f:HookScript("OnShow", function() dd:GenerateMenu() end)
    end
end

-- Shift-Klick auf ein Item füllt das Material-Feld ---------------------------------------------------------
local function InsertHook(link)
    local e = GK.matEdit
    if e and link and e:IsVisible() and e:HasFocus() then e:Insert(link) end
end
if _G.ChatEdit_InsertLink then pcall(hooksecurefunc, "ChatEdit_InsertLink", InsertHook) end
if _G.ChatFrameUtil and ChatFrameUtil.InsertLink then pcall(hooksecurefunc, ChatFrameUtil, "InsertLink", InsertHook) end

-- Befehle (/gk ziel liegt in Woche.lua: mit Betrag Wochenziel, ohne Betrag Sparziele) ----------------------------------
GK.RegisterCommand("plus", function() GK.TogglePlus() end, "Plus-Fenster (Routen, Ziele, Material, Preise)")
GK.RegisterCommand({ "route", "routen" }, function() GK.OpenPlus("routen") end, "Routen im Plus-Fenster")
GK.RegisterCommand({ "ziele", "sparen" }, function() GK.OpenPlus("ziele") end, "Sparziele")
GK.RegisterCommand({ "mats", "material" }, function() GK.OpenPlus("mats") end, "Material-Tracker")
GK.RegisterCommand("preise", function() GK.OpenPlus("preise") end, "Preisverlauf")
GK.RegisterCommand({ "rueckblick", "rückblick" }, function() GK.PrintRecap() end, "Wochen-Rückblick im Chat")
GK.RegisterCommand("design", function(arg)
    arg = strlower(arg or "")
    if THEMES[arg] then SetTheme(arg); Print("Design: " .. THEMES[arg][1])
    else Print("Designs: gold, blau, gruen, violett, rot (/gk design blau)") end
end, "Farbe: design gold|blau|gruen|violett|rot")

-- Start: Rückblick ------------------------------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    local db = DB()
    if not db then return end
    if db.opt.theme == nil then db.opt.theme = "gold" end
    C_Timer.After(2, ApplyTheme)
    C_Timer.After(8, function()
        local d = GK.RecapData()
        if db.lastRecap ~= d.weekKey then
            db.lastRecap = d.weekKey
            if db.opt.recap ~= false and (d.inn > 0 or d.out > 0) then GK.PrintRecap() end
        end
    end)
end)
