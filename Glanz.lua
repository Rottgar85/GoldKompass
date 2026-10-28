-- GoldKompass Glanz: schoeneres Aussehen mit Bildern aus dem Spiel.
-- 1. Drei Kacheln im Reiter Heute (Gold heute, Gold pro Stunde, Wochenziel mit Balken)
-- 2. Symbole an den Reitern, aktiver Reiter farbig hinterlegt
-- 3. Charaktername in der Kopfzeile
-- 4. Farm-Fenster: Funde als Symbole mit Rahmen in Qualitaetsfarbe, Balken fuer das Zeitlimit
-- 5. Wochenleiste: Striche bei 25/50/75 % und Betraege mit Muenzsymbol
-- Aendert nur das Aussehen; jede Stelle ist in pcall, ein Fehler hier laesst das Addon unberuehrt.
local GK = GoldKompass
local WHITE = "Interface\\Buttons\\WHITE8x8"
local ICONS = "Interface\\Icons\\"
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}
local function DB() return GK.DB and GK.DB() end
local function Theme()
    local db = DB()
    return COLORS[db and db.opt and db.opt.theme or "gold"] or COLORS.gold
end
local function Short(c) return GK.FmtGoldShort and GK.FmtGoldShort(c) or tostring(floor((c or 0) / 10000)) end
local function Num(c) return GK.Thousands and GK.Thousands(floor((c or 0) / 10000)) or tostring(floor((c or 0) / 10000)) end

local TAB_ICONS = {
    heute = "INV_Misc_Coin_01", woche = "INV_Misc_Note_01", farm = "INV_Pick_02",
    beute = "INV_Misc_Bag_08", chars = "INV_Misc_Head_Human_01", gruppe = "Ability_Warrior_BattleShout",
}
local TILE_H, TILE_TOP, ROW_TOP, RH = 46, 53, 78, 17

-- Kacheln ------------------------------------------------------------------------------------------------------
local function Tile(parent, icon, label)
    local t = CreateFrame("Button", nil, parent, "BackdropTemplate")
    t:SetHeight(TILE_H)
    t:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    t:SetBackdropColor(0.106, 0.125, 0.2, 1); t:SetBackdropBorderColor(0.18, 0.21, 0.31, 1)
    t.icon = t:CreateTexture(nil, "ARTWORK"); t.icon:SetSize(14, 14); t.icon:SetPoint("TOPLEFT", 6, -5)
    t.icon:SetTexture(ICONS .. icon); t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    t.label = t:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    t.label:SetPoint("LEFT", t.icon, "RIGHT", 4, 0); t.label:SetText(label)
    t.value = t:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t.value:SetPoint("TOPLEFT", 6, -21); t.value:SetJustifyH("LEFT")
    t.sub = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t.sub:SetPoint("TOPRIGHT", -6, -6); t.sub:SetJustifyH("RIGHT"); t.sub:SetWordWrap(false)
    local hl = t:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.05)
    return t
end

local function AddBar(t)
    t.barBg = t:CreateTexture(nil, "ARTWORK")
    t.barBg:SetPoint("BOTTOMLEFT", 6, 5); t.barBg:SetPoint("BOTTOMRIGHT", -6, 5); t.barBg:SetHeight(4)
    t.barBg:SetColorTexture(0.16, 0.18, 0.25, 1)
    t.bar = t:CreateTexture(nil, "OVERLAY")
    t.bar:SetPoint("TOPLEFT", t.barBg, "TOPLEFT"); t.bar:SetPoint("BOTTOMLEFT", t.barBg, "BOTTOMLEFT"); t.bar:SetWidth(1)
end

local function BuildMain()
    local f = GK.frame
    if not f or f.gkGlanz or not f.tabs then return end
    f.gkGlanz = true

    -- Kacheln (nur im Reiter Heute sichtbar)
    local w = (f:GetWidth() - 20 - 12) / 3
    f.tiles = {
        Tile(f, "INV_Misc_Coin_02", "Heute"),
        Tile(f, "INV_Misc_PocketWatch_01", "Pro Stunde"),
        Tile(f, "INV_Misc_Map_01", "Woche"),
    }
    for i, t in ipairs(f.tiles) do
        t:SetWidth(w); t:SetPoint("TOPLEFT", 10 + (i - 1) * (w + 6), -TILE_TOP); t:Hide()
    end
    AddBar(f.tiles[3])
    f.tiles[2]:SetScript("OnClick", function() GK.tab = "farm"; GK.Refresh() end)
    f.tiles[3]:SetScript("OnClick", function() GK.tab = "woche"; GK.Refresh() end)

    -- Reiter: Symbol vor dem Namen, Hintergrund fuer den aktiven Reiter
    for k, b in pairs(f.tabs) do
        b.gkBg = b:CreateTexture(nil, "BACKGROUND"); b.gkBg:SetAllPoints(); b.gkBg:SetColorTexture(0.16, 0.13, 0.03, 0.9); b.gkBg:Hide()
        if TAB_ICONS[k] then
            b.text:ClearAllPoints(); b.text:SetPoint("CENTER", 7, 0)
            b.gkIcon = b:CreateTexture(nil, "ARTWORK"); b.gkIcon:SetSize(12, 12)
            b.gkIcon:SetPoint("RIGHT", b.text, "LEFT", -3, 0)
            b.gkIcon:SetTexture(ICONS .. TAB_ICONS[k]); b.gkIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end

    -- Charaktername in der Kopfzeile, rechts neben dem Titel
    for i = 1, select("#", f:GetRegions()) do
        local r = select(i, f:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" and r:GetText() == "GoldKompass" then
            f.gkChar = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            f.gkChar:SetPoint("LEFT", r, "RIGHT", 10, -1); f.gkChar:SetTextColor(0.79, 0.65, 0.29)
            f.gkChar:SetText(UnitName("player") .. " · " .. GetRealmName())
            break
        end
    end
end

local function UpdateTiles(f, show)
    for _, t in ipairs(f.tiles) do t:SetShown(show) end
    if not show then return end
    local db = DB()
    local tc = Theme()
    -- 1. Gold heute: Saldo, darunter Einnahmen und Ausgaben
    local d = db.days[date("%Y-%m-%d")] or { inn = 0, out = 0 }
    local t1 = f.tiles[1]
    t1.value:SetText(Short((d.inn or 0) - (d.out or 0)))
    t1.sub:SetText("|cff66ff66+" .. Num(d.inn) .. "|r  |cffff5555-" .. Num(d.out) .. "|r")
    -- 2. Gold pro Stunde der laufenden Farm
    local t2, fm = f.tiles[2], GK.farm
    if fm then
        local secs = GetTime() - fm.start
        local total = fm.money + fm.value - (fm.costs or 0)
        t2.value:SetText(secs > 30 and (Short(total / secs * 3600) .. "|cff9aa0b4/h|r") or "|cff9aa0b4...|r")
        t2.sub:SetText(string.format("%d:%02d", floor(secs / 60), floor(secs % 60)))
    else
        t2.value:SetText("|cff9aa0b4–|r"); t2.sub:SetText("keine Farm")
    end
    -- 3. Wochenziel mit Balken
    local t3, goal = f.tiles[3], db.weekGoal
    -- Betrag "13.114 / 100.000" ist zu lang fuer die Kopfzeile neben "Woche": in die Zeile der Prozentzahl, rechts
    if not t3.gkSubMoved then
        t3.gkSubMoved = true
        t3.sub:ClearAllPoints(); t3.sub:SetPoint("RIGHT", t3, "TOPRIGHT", -6, -30)
    end
    if goal and goal > 0 and GK.LiveWeek then
        local net = GK.LiveWeek()
        local pct = net / (goal * 10000)
        t3.value:SetText(floor(math.max(pct, 0) * 100) .. "%")
        t3.sub:SetText(Num(net) .. " / " .. Num(goal * 10000))
        local full = t3.barBg:GetWidth()
        t3.bar:SetWidth(math.max(1, math.min(1, math.max(pct, 0)) * full))
        if pct >= 1 then t3.bar:SetColorTexture(0.4, 0.84, 0.4, 1) else t3.bar:SetColorTexture(0.65, 0.3, 0.72, 1) end
        t3.bar:Show()
    else
        t3.value:SetText("|cff9aa0b4–|r"); t3.sub:SetText("kein Ziel"); t3.bar:Hide()
    end
    for _, t in ipairs(f.tiles) do t.label:SetTextColor(0.6, 0.63, 0.71) end
    f.tiles[2].value:SetTextColor(tc[1], tc[2], tc[3])
end

local function OnRefresh()
    local f = GK.frame
    if not f or not f:IsShown() then return end
    BuildMain()
    if not f.gkGlanz then return end
    local tab = GK.tab
    local heute = tab == "heute"
    UpdateTiles(f, heute)
    -- Zeilen im Reiter Heute unter die Kacheln schieben, sonst an ihren alten Platz
    local off = heute and (TILE_H + 4) or 0
    if f.gkRowOff ~= off then
        f.gkRowOff = off
        for i, r in ipairs(f.rows) do
            local y = -ROW_TOP - off - (i - 1) * RH
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 10, y); r:SetPoint("TOPRIGHT", -10, y)
        end
    end
    for k, b in pairs(f.tabs) do
        if b.gkBg then b.gkBg:SetShown(k == tab) end
        if b.gkIcon then b.gkIcon:SetDesaturated(k ~= tab); b.gkIcon:SetAlpha(k == tab and 1 or 0.7) end
    end
end

-- Farm-Fenster: Funde als Symbole ---------------------------------------------------------------------------------
local SLOTS, SLOT = 5, 32

local function BuildHudSlots()
    local h = GK.hud
    if not h or h.gkSlots then return end
    for _, r in ipairs(h.rows or {}) do r.name:Hide(); r.val:Hide() end
    h:SetHeight(102)
    h.gkSlots = {}
    for i = 1, SLOTS do
        local s = CreateFrame("Button", nil, h, "BackdropTemplate")
        s:SetSize(SLOT, SLOT); s:SetPoint("TOPLEFT", 8 + (i - 1) * (SLOT + 6), -53)
        s:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 2 })
        s:SetBackdropColor(0.1, 0.1, 0.12, 1)
        s.icon = s:CreateTexture(nil, "ARTWORK")
        s.icon:SetPoint("TOPLEFT", 2, -2); s.icon:SetPoint("BOTTOMRIGHT", -2, 2); s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        s.count = s:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        s.count:SetPoint("BOTTOMRIGHT", -2, 2); s.count:SetJustifyH("RIGHT")
        s:RegisterForDrag("LeftButton")
        s:SetScript("OnDragStart", function() local fn = h:GetScript("OnDragStart"); if fn then fn(h) end end) -- beachtet die Sperre
        s:SetScript("OnDragStop", function() local fn = h:GetScript("OnDragStop"); if fn then fn(h) end end)
        s:SetScript("OnEnter", function(self)
            if not self.itemId then return end
            GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetItemByID(self.itemId)
            if self.value then GameTooltip:AddLine(" "); GameTooltip:AddDoubleLine("GoldKompass", GK.FmtGold(self.value), 1, 0.82, 0) end
            GameTooltip:Show()
        end)
        s:SetScript("OnLeave", GameTooltip_Hide)
        s:Hide()
        h.gkSlots[i] = s
    end
    -- Balken fuer das Zeitlimit (/gk dauer)
    h.gkLimitBg = h:CreateTexture(nil, "ARTWORK")
    h.gkLimitBg:SetPoint("BOTTOMLEFT", 8, 7); h.gkLimitBg:SetPoint("BOTTOMRIGHT", -8, 7); h.gkLimitBg:SetHeight(4)
    h.gkLimitBg:SetColorTexture(0.16, 0.18, 0.25, 1)
    h.gkLimit = h:CreateTexture(nil, "OVERLAY")
    h.gkLimit:SetPoint("TOPLEFT", h.gkLimitBg); h.gkLimit:SetPoint("BOTTOMLEFT", h.gkLimitBg); h.gkLimit:SetWidth(1)
end

local function OnRefreshHud()
    local h, fm = GK.hud, GK.farm
    if not h or not fm then return end
    BuildHudSlots()
    -- die Text-Treffflaechen aus Tooltip.lua sind durch die Symbole ersetzt
    for _, r in ipairs(h.rows or {}) do if r.gkHit then r.gkHit:Hide() end end
    local min = ((DB().opt.minValue) or 0) * 10000
    local list = {}
    for id, n in pairs(fm.items) do
        local v = (fm.price[id] or 0) * n
        if v >= min then list[#list + 1] = { id = id, n = n, v = v } end
    end
    table.sort(list, function(a, b) return a.v > b.v end)
    for i, s in ipairs(h.gkSlots) do
        local it = list[i]
        if it then
            s.itemId, s.value = it.id, it.v
            s.icon:SetTexture(C_Item.GetItemIconByID(it.id) or (ICONS .. "INV_Misc_QuestionMark"))
            local q = C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(it.id)
            local r, g, b = 0.6, 0.6, 0.6
            if q and C_Item.GetItemQualityColor then r, g, b = C_Item.GetItemQualityColor(q) end
            s:SetBackdropBorderColor(r, g, b, 1)
            s.count:SetText(it.n > 1 and it.n or "")
            s:Show()
        else
            s.itemId, s.value = nil, nil
            s:Hide()
        end
    end
    local lim = tonumber(DB().opt.farmMinutes) or 0
    if lim > 0 then
        local frac = math.max(0, math.min(1, (GetTime() - fm.start) / (lim * 60)))
        local tc = Theme()
        h.gkLimit:SetColorTexture(tc[1], tc[2], tc[3], 1)
        h.gkLimit:SetWidth(math.max(1, frac * h.gkLimitBg:GetWidth()))
        h.gkLimitBg:Show(); h.gkLimit:Show()
    else
        h.gkLimitBg:Hide(); h.gkLimit:Hide()
    end
end

-- Wochenleiste: Meilenstein-Striche und Betraege mit Muenzsymbol ------------------------------------------------------
local function OnUpdateBar()
    local b = _G.GoldKompassWeekBar
    local db = DB()
    if not b or not b:IsShown() or not b.sb or not db then return end
    if not b.gkTicks then
        b:SetHeight(16)
        b.gkTicks = {}
        for i = 1, 3 do
            local t = b.sb:CreateTexture(nil, "OVERLAY"); t:SetColorTexture(1, 0.82, 0, 0.6); t:SetWidth(1)
            b.gkTicks[i] = t
        end
    end
    local w = b.sb:GetWidth()
    for i, t in ipairs(b.gkTicks) do
        t:ClearAllPoints()
        t:SetPoint("TOP", b.sb, "TOPLEFT", w * i / 4, 0); t:SetPoint("BOTTOM", b.sb, "BOTTOMLEFT", w * i / 4, 0)
    end
    local goal = db.weekGoal
    if goal and goal > 0 and GK.LiveWeek then
        local net = GK.LiveWeek()
        local pct = floor(math.max(net / (goal * 10000), 0) * 100)
        b.text:SetText(string.format("Woche: %s%s von %s%s · %d%%", Num(net), GK.GOLD_ICON or "g", Num(goal * 10000), GK.GOLD_ICON or "g", pct))
    end
end

-- Einhaengen ---------------------------------------------------------------------------------------------------------
local function Safe(fn) return function() pcall(fn) end end
if type(GK.Refresh) == "function" then hooksecurefunc(GK, "Refresh", Safe(OnRefresh)) end
if type(GK.RefreshHud) == "function" then hooksecurefunc(GK, "RefreshHud", Safe(OnRefreshHud)) end
if type(GK.UpdateBar) == "function" then hooksecurefunc(GK, "UpdateBar", Safe(OnUpdateBar)) end
