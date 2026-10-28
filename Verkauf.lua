-- GoldKompass Verkauf: Verkaufshelfer in eigenem Fenster (Knopf "Verkaufshelfer" im Reiter Beute oder /gk verkauf).
-- Sortiert die Taschen in "Ins Auktionshaus" (Marktpreis nach 5% Gebuehr hoeher als der Haendlerpreis, nicht gebunden)
-- und "Zum Haendler". Graue Items lassen sich bei offenem Haendler per Knopf verkaufen.
-- Klick auf eine Zeile sperrt den Gegenstand (taucht nicht mehr auf, wird nie grau verkauft); Klick in "Gesperrt" hebt auf.
-- Feld "Mindestgewinn" (in Gold, mit OK oder Enter bestaetigen): ab welchem Mehrerloes ein Item als Auktionshaus-Tipp gilt.
-- Liefert auch GK.BagsValue fuer den Reiter Beute.
local GK = GoldKompass
local GOLD = "|cffffd100"
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}
local function G(c) return GK.FmtGold(c) end
local function DB() return GK.DB() end
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(GOLD .. "GoldKompass|r: " .. m) end

local PW, PH, ROWS, RH, TOP = 470, 335, 13, 17, 54
local ROWW = PW - 20
local BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 }
local AH_CUT = 0.95

local merchantOpen = false
local frame
local offset = 0
local lines = {}
local grayCount = 0
local pendingRefresh = false

-- Gespeicherte Einstellungen (Sperrliste, Mindestgewinn) ------------------------------------------
local function Block()
    local db = DB()
    if not db then return {} end
    db.sellBlock = db.sellBlock or {}
    return db.sellBlock
end

local function MinGain() -- in Kupfer
    local db = DB()
    return db and tonumber(db.sellMin) or 0
end

local function MinText() -- Gold als Zahl fuers Eingabefeld
    return string.format("%g", MinGain() / 10000)
end

-- Taschen einlesen ------------------------------------------------------------------------------
local function Vendor(id)
    return select(11, C_Item.GetItemInfo(id)) or 0
end

local function Scan()
    local stacks, order = {}, {}
    for bag = 0, 5 do
        local ok, slots = pcall(C_Container.GetContainerNumSlots, bag)
        for slot = 1, (ok and slots or 0) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local key = info.itemID .. (info.isBound and "b" or "u")
                local s = stacks[key]
                if not s then
                    s = { id = info.itemID, n = 0, link = info.hyperlink, icon = info.iconFileID, bound = info.isBound and true or false, q = info.quality or 0 }
                    stacks[key] = s; order[#order + 1] = s
                end
                s.n = s.n + (info.stackCount or 1)
            end
        end
    end
    return order
end

local function FreeSlots()
    local free, total = 0, 0
    for bag = 0, 5 do
        local ok, slots = pcall(C_Container.GetContainerNumSlots, bag)
        if ok and slots and slots > 0 then
            total = total + slots
            free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0)
        end
    end
    return free, total
end

local function Classify()
    local ah, vendor, blocked, gray = {}, {}, {}, 0
    local ahSum, vSum = 0, 0
    local block, minGain = Block(), MinGain()
    for _, s in ipairs(Scan()) do
        local vp = Vendor(s.id)
        if block[s.id] then
            s.each = vp; s.v = vp * s.n
            blocked[#blocked + 1] = s
        else
            local mp = (not s.bound) and GK.MarketPrice and GK.MarketPrice(s.id) or nil
            if mp and mp * AH_CUT > vp and (mp * AH_CUT - vp) * s.n >= minGain then
                s.each, s.v = mp, mp * s.n
                ah[#ah + 1] = s; ahSum = ahSum + s.v
            elseif vp > 0 then
                s.each, s.v = vp, vp * s.n
                vendor[#vendor + 1] = s; vSum = vSum + s.v
                if s.q == 0 then gray = gray + s.v end
            end
        end
    end
    local function byValue(a, b) return a.v > b.v end
    table.sort(ah, byValue); table.sort(vendor, byValue); table.sort(blocked, byValue)
    return ah, vendor, ahSum, vSum, gray, blocked
end

-- fuer den Reiter Beute in Kompakt.lua: Gesamtwert der Taschen und die wertvollsten Stapel
function GK.BagsValue()
    local total, top = 0, {}
    for _, s in ipairs(Scan()) do
        local price = (GK.MarketPrice and GK.MarketPrice(s.id)) or Vendor(s.id)
        local v = (price or 0) * s.n
        total = total + v
        top[#top + 1] = { link = s.link, v = v }
    end
    table.sort(top, function(a, b) return a.v > b.v end)
    return total, top
end

-- Fenster ----------------------------------------------------------------------------------------
local function Btn(parent, text, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 20); b:SetText(text)
    return b
end

local function Color()
    local db = DB()
    return COLORS[db and db.opt and db.opt.theme or "gold"] or COLORS.gold
end

-- Mindestgewinn aus dem Eingabefeld uebernehmen (Gold, Komma oder Punkt erlaubt)
local function ApplyMin(f)
    local db = DB()
    if not db then return end
    local txt = (f.minBox:GetText() or ""):gsub(",", "."):gsub("%s", "")
    local g = txt == "" and 0 or tonumber(txt)
    if not g or g < 0 then
        Print("Bitte eine Zahl in Gold eingeben, zum Beispiel 5 oder 2,5.")
        f.minBox:SetText(MinText())
        return
    end
    db.sellMin = math.floor(g * 10000 + 0.5)
    f.minBox:SetText(MinText())
    f.minBox:ClearFocus()
    Print("Mindestgewinn: " .. (db.sellMin > 0 and G(db.sellMin) or "keiner") .. ".")
    GK.RefreshSell()
end

local function Build()
    if frame then return end
    local f = CreateFrame("Frame", "GoldKompassSellFrame", UIParent, "BackdropTemplate")
    f:SetSize(PW, PH)
    local anchor = (GK.plus and GK.plus:IsShown() and GK.plus) or (GK.frame and GK.frame:IsShown() and GK.frame)
    if anchor then f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, 0) else f:SetPoint("CENTER", 0, 20) end
    f:SetBackdrop(BACKDROP); f:SetBackdropColor(0.05, 0.05, 0.08, 0.94)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:EnableMouseWheel(true)
    tinsert(UISpecialFrames, "GoldKompassSellFrame")
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -9); title:SetText("GoldKompass · Verkaufshelfer")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24); close:SetPoint("TOPRIGHT", 0, 0)
    local refresh = Btn(f, "Neu laden", 80); refresh:SetHeight(18)
    refresh:SetPoint("TOPRIGHT", -30, -5)
    refresh:SetScript("OnClick", function() GK.RefreshSell() end)

    f.sum = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.sum:SetPoint("TOPLEFT", 12, -32); f.sum:SetPoint("TOPRIGHT", -12, -32)
    f.sum:SetJustifyH("LEFT"); f.sum:SetWordWrap(false)
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(1, 1, 1, 0.12); sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 10, -49); sep:SetPoint("TOPRIGHT", -10, -49)

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
        r:SetScript("OnEnter", function(self)
            if self.link then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetHyperlink(self.link)
                GameTooltip:AddLine(self.blocked and "Klick: Sperre aufheben" or "Klick: nie wieder vorschlagen", 0.6, 0.6, 0.6)
                GameTooltip:Show()
            end
        end)
        r:SetScript("OnLeave", GameTooltip_Hide)
        r:SetScript("OnClick", function(self)
            if not self.itemId then return end
            local block = Block()
            if self.blocked then block[self.itemId] = nil else block[self.itemId] = true end
            GameTooltip_Hide()
            GK.RefreshSell()
        end)
        f.rows[i] = r
    end

    f.sell = Btn(f, "Graue Items verkaufen", 170); f.sell:SetPoint("BOTTOMLEFT", 10, 10)
    f.sell:SetScript("OnClick", function() GK.SellGray() end)

    -- Mindestgewinn: Zahl in Gold eintippen, OK klicken oder Enter druecken
    f.ok = Btn(f, "OK", 44); f.ok:SetPoint("BOTTOMRIGHT", -10, 10)
    f.ok:SetScript("OnClick", function() ApplyMin(f) end)
    f.minBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.minBox:SetSize(62, 20); f.minBox:SetPoint("RIGHT", f.ok, "LEFT", -8, 0)
    f.minBox:SetAutoFocus(false); f.minBox:SetMaxLetters(9); f.minBox:SetJustifyH("CENTER")
    f.minBox:SetScript("OnEnterPressed", function() ApplyMin(f) end)
    f.minBox:SetScript("OnEscapePressed", function(self) self:SetText(MinText()); self:ClearFocus() end)
    f.minLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.minLabel:SetPoint("RIGHT", f.minBox, "LEFT", -8, 0); f.minLabel:SetText("Mindestgewinn (Gold):")

    f.note = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.note:SetPoint("BOTTOMLEFT", 10, 36); f.note:SetPoint("BOTTOMRIGHT", -10, 36)
    f.note:SetJustifyH("LEFT"); f.note:SetTextColor(0.6, 0.6, 0.6)

    f:SetScript("OnMouseWheel", function(_, d)
        local max = math.max(0, #lines - ROWS)
        offset = math.max(0, math.min(max, offset - d * 3))
        GK.RefreshSell(true)
    end)
    f:SetScript("OnShow", function() offset = 0; f.minBox:SetText(MinText()); GK.RefreshSell() end)
    frame = f
end

function GK.RefreshSell(keepScan)
    local f = frame
    if not f or not f:IsShown() then return end
    local c = Color()
    f:SetBackdropBorderColor(c[1], c[2], c[3], 1)

    if not keepScan then
        local ah, vendor, ahSum, vSum, gray, blocked = Classify()
        grayCount = gray
        lines = {}
        local top = math.max(ah[1] and ah[1].v or 0, vendor[1] and vendor[1].v or 0, 1)
        local function add(l, r, frac, col, link, id, isBlocked) lines[#lines + 1] = { l, r, frac, col, link, id, isBlocked } end
        local function item(s, col, isBlocked)
            add("   |T" .. (s.icon or 134400) .. ":12|t " .. (s.link or ("Item " .. s.id)) .. "  x" .. s.n, G(s.v), s.v / top, col, s.link, s.id, isBlocked)
        end
        add(GOLD .. "Ins Auktionshaus|r  (" .. #ah .. ")", G(ahSum))
        if #ah == 0 then add("   Nichts, das dort genug mehr bringt als beim Händler.", "") end
        for _, s in ipairs(ah) do item(s, { 0.35, 0.65, 1 }) end
        add(" ", "")
        add(GOLD .. "Zum Händler|r  (" .. #vendor .. ")", G(vSum))
        if #vendor == 0 then add("   Nichts mit Händlerwert.", "") end
        for _, s in ipairs(vendor) do item(s, { 0.4, 0.9, 0.5 }) end
        if #blocked > 0 then
            add(" ", "")
            add(GOLD .. "Gesperrt|r  (" .. #blocked .. ")  |cff999999Klick hebt die Sperre auf|r", "")
            for _, s in ipairs(blocked) do item(s, { 0.6, 0.6, 0.6 }, true) end
        end
        local free, total = FreeSlots()
        local freeTxt = (free <= 5 and "|cffff6666" or "|cffffffff") .. free .. "/" .. total .. "|r"
        f.sum:SetText("Auktionshaus: " .. G(ahSum) .. "   Händler: " .. G(vSum) .. "   Grau: " .. G(gray) .. "   Frei: " .. freeTxt)
        f.free = free
    end

    offset = math.max(0, math.min(math.max(0, #lines - ROWS), offset))
    for i, r in ipairs(f.rows) do
        local d = lines[offset + i]
        if d then
            r:Show(); r.l:SetText(d[1]); r.r:SetText(d[2]); r.link = d[5]; r.itemId = d[6]; r.blocked = d[7]
            if d[3] then
                local col = d[4]
                r.bar:SetColorTexture(col[1], col[2], col[3], 0.28)
                r.bar:SetWidth(math.max(1, math.min(1, d[3]) * ROWW)); r.bar:Show()
            else
                r.bar:Hide()
            end
        else
            r:Hide(); r.link = nil; r.itemId = nil; r.blocked = nil
        end
    end

    f.sell:SetEnabled(merchantOpen and grayCount > 0)
    if f.free and f.free <= 5 then f.note:SetText("|cffff6666Taschen fast voll: nur noch " .. f.free .. " freie Plätze.|r")
    elseif not merchantOpen then f.note:SetText("Zum Verkaufen erst einen Händler öffnen.")
    elseif grayCount <= 0 then f.note:SetText("Keine graue Ware in den Taschen.")
    else f.note:SetText("Verkauft nur graue Items (" .. G(grayCount) .. "), gesperrte bleiben.") end
end

-- Graue Items beim offenen Haendler verkaufen (nur auf Knopfdruck) ----------------------------------
function GK.SellGray()
    if not merchantOpen then Print("Erst einen Händler öffnen."); return end
    local n, sum = 0, 0
    local block = Block()
    for bag = 0, 5 do
        local ok, slots = pcall(C_Container.GetContainerNumSlots, bag)
        for slot = 1, (ok and slots or 0) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == 0 and not info.hasNoValue and info.itemID and not block[info.itemID] then
                sum = sum + Vendor(info.itemID) * (info.stackCount or 1)
                n = n + 1
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end
    Print(n > 0 and (n .. " graue Stapel verkauft, zusammen " .. G(sum) .. ".") or "Keine graue Ware gefunden.")
    C_Timer.After(0.6, function() GK.RefreshSell() end)
end

-- Oeffnen ---------------------------------------------------------------------------------------------
function GK.SellHelper(forceClose)
    Build()
    if forceClose == true or (forceClose ~= "open" and frame:IsShown()) then frame:Hide(); return end
    if GK.frame and not GK.frame.gkSellHook then
        GK.frame.gkSellHook = true
        GK.frame:HookScript("OnHide", function()
            if GK.navSwitching then return end -- Seitenwechsel im Ein-Fenster-Modus (Fenster.lua)
            if frame and frame:IsShown() then frame:Hide() end
        end)
    end
    frame:Show()
end

-- GK.SellHelper wird unten noch um den Optionsschalter erweitert; daher hier zur Laufzeit nachschlagen
GK.RegisterCommand({ "verkauf", "verkaufshelfer" }, function() GK.SellHelper() end, "Verkaufshelfer: was ins Auktionshaus, was zum Händler")

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "MERCHANT_SHOW", "MERCHANT_CLOSED", "GET_ITEM_INFO_RECEIVED" }) do ev:RegisterEvent(e) end
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then return end
    if event == "MERCHANT_SHOW" then merchantOpen = true
    elseif event == "MERCHANT_CLOSED" then merchantOpen = false end
    if not (frame and frame:IsShown()) then return end
    if event == "GET_ITEM_INFO_RECEIVED" then
        -- Item-Daten kommen nachgeladen: gebuendelt neu zeichnen, damit Preise nicht fehlen
        if pendingRefresh then return end
        pendingRefresh = true
        C_Timer.After(0.5, function() pendingRefresh = false; GK.RefreshSell() end)
        return
    end
    GK.RefreshSell()
end)

-- Schalter "Verkaufshelfer" (Optionen): aus = Fenster und Verkaufsknopf sind gesperrt. Standard: an.
do
    local origSellHelper, origSellGray = GK.SellHelper, GK.SellGray
    local function Enabled()
        local db = DB()
        return not (db and db.opt and db.opt.sellHelper == false)
    end
    function GK.SellHelper(...)
        if not Enabled() then
            if frame and frame:IsShown() then frame:Hide() end
            Print("Der Verkaufshelfer ist in den Optionen ausgeschaltet.")
            return
        end
        return origSellHelper(...)
    end
    function GK.SellGray(...)
        if not Enabled() then Print("Der Verkaufshelfer ist in den Optionen ausgeschaltet."); return end
        return origSellGray(...)
    end
    local sev = CreateFrame("Frame")
    sev:RegisterEvent("PLAYER_LOGIN")
    sev:SetScript("OnEvent", function()
        local db = DB()
        if db and db.opt and db.opt.sellHelper == nil then db.opt.sellHelper = true end
    end)
end
