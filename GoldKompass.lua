-- GoldKompass: Goldverlauf aufzeichnen + Farm-Rechner (Gold pro Stunde)
local addonName = ...
local GK = {}
GoldKompass = GK
local TITLE = "|cffffd100GoldKompass|r"
GK.LOGO = "Interface\\AddOns\\GoldKompass\\Media\\Logo"   -- eigenes Logo (Media\Logo.tga)

-- Beschriftungen fuer die Tastenbelegung (Bindings.xml): Esc > Optionen > Tastenbelegung > AddOns > GoldKompass
local EN = GetLocale() ~= "deDE"
BINDING_HEADER_GOLDKOMPASS = "GoldKompass"
BINDING_NAME_GOLDKOMPASS_TOGGLE = EN and "Open/close window" or "Fenster öffnen/schließen"
BINDING_NAME_GOLDKOMPASS_FARM = EN and "Start/stop farm session" or "Farm-Session starten/stoppen"
BINDING_NAME_GOLDKOMPASS_PAUSE = EN and "Pause/resume farm session" or "Farm-Session pausieren/fortsetzen"
-- Chat-Ausgaben ueber GK.Out (Sprache.lua uebersetzt dort), das globale print bleibt unberuehrt
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end

local function Mny(c)
    c = c or 0
    local neg = c < 0
    c = math.abs(c)
    local t = string.format("%dg %02ds", floor(c / 10000), floor((c % 10000) / 100))
    return neg and ("|cffff5555-" .. t .. "|r") or ("|cff66ff66" .. t .. "|r")
end
local function Plain(c) -- ohne Farbe
    c = c or 0
    return string.format("%dg", floor(c / 10000))
end
local function Today() return date("%Y-%m-%d") end
local function Me() return UnitName("player") .. "-" .. GetRealmName() end
local function Zone()
    local z = GetRealZoneText()
    if not z or z == "" then z = GetZoneText() end
    return (z and z ~= "") and z or "Unbekannt"
end

local DB, last
local ctx = {}         -- offene Kontexte: Haendler, Auktionshaus, Post, Handel
local lastQuest = 0

-- Optionen ----------------------------------------------------------------------
local DEFAULTS = {
    record = true, farm = true, minimap = true,
    alarm = true, alarmSound = true, alarmPopup = true, alarmChat = true,
    welcome = true, source = "auctionator",
}
function GK.DB() return DB end

-- Preisquelle: Auctionator oder TSM, mit Rueckfall -------------------------------
local function FromAuctionator(id)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if api and api.GetAuctionPriceByItemID then
        local ok, v = pcall(api.GetAuctionPriceByItemID, addonName, id)
        if ok and type(v) == "number" and v > 0 then return v end
    end
end
local function FromTSM(key, id)
    if TSM_API and TSM_API.GetCustomPriceValue then
        local ok, v = pcall(TSM_API.GetCustomPriceValue, key, "i:" .. id)
        if ok and type(v) == "number" and v > 0 then return v end
    end
end
function GK.MarketPrice(id)
    local src = DB and DB.opt and DB.opt.source or "auctionator"
    if src == "tsmMarket" then return FromTSM("DBMarket", id) or FromAuctionator(id)
    elseif src == "tsmMin" then return FromTSM("DBMinBuyout", id) or FromAuctionator(id) end
    return FromAuctionator(id) or FromTSM("DBMarket", id)
end

-- Item-Wert: Marktpreis, sonst Haendlerpreis ---------------------------------------
local function ItemValue(id)
    local v = GK.MarketPrice(id)
    if v then return v end
    local _, _, _, _, _, _, _, _, _, _, sell = C_Item.GetItemInfo(id)
    return sell or 0
end

-- Gesamtgold: alle Charaktere plus Kriegsmeute-Bank ------------------------------------------
-- Rueckgabe: gesamt, nur Charaktere, nur Kriegsmeute-Bank
function GK.TotalGold()
    local sum = 0
    for _, c in pairs(DB and DB.chars or {}) do sum = sum + (c.money or 0) end
    local wb = DB and DB.warbank and DB.warbank.money or 0
    return sum + wb, sum, wb
end

-- Tagesstand des Gesamtgolds fuer den Gold-Verlauf (Analyse.lua)
local function SnapTotal()
    if not DB then return end
    DB.totalHist = DB.totalHist or {}
    DB.totalHist[Today()] = GK.TotalGold()
end
GK.SnapTotal = SnapTotal

local function ReadWarbank()
    if not (DB and C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account) then return end
    local ok, v = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
    if ok and type(v) == "number" then DB.warbank = { money = v, ts = time() } end
end

-- Gold-Aufzeichnung: der einzige Goldzaehler des Addons -------------------------------------------
-- Fuellt DB.days (Tagesbilanz mit Quellen), DB.gained (erhaltenes Gold fuer das Wochenziel),
-- DB.charGained (erhaltenes Gold je Charakter) und das Rohgold der Farm-Session.
local TRANSFER, AH_SALE = "Kriegsmeute-Bank", "Auktionshaus-Verkauf"
local mailSales = {}   -- gerade geleerte AH-Verkaufsbriefe: { money = Kupfer oder false, t = GetTime() }

local function NoteMail(index)
    if not index or not GetInboxInvoiceInfo then return end
    local ok, invoiceType = pcall(GetInboxInvoiceInfo, index)
    if not ok or invoiceType ~= "seller" then return end
    local money = select(5, GetInboxHeaderInfo(index))
    mailSales[#mailSales + 1] = { money = (money and money > 0) and money or false, t = GetTime() }
end
if TakeInboxMoney then hooksecurefunc("TakeInboxMoney", NoteMail) end
if AutoLootMailItem then hooksecurefunc("AutoLootMailItem", NoteMail) end

local function Category(delta)
    if ctx.bank then return TRANSFER end
    if ctx.merchant then return "Haendler" end
    if ctx.ah then return "Auktionshaus" end
    if ctx.mail then
        if delta > 0 then
            local now = GetTime()
            for i = #mailSales, 1, -1 do
                local s = mailSales[i]
                if now - s.t > 10 then
                    table.remove(mailSales, i)
                elseif s.money == delta or s.money == false then
                    table.remove(mailSales, i)
                    return AH_SALE
                end
            end
        end
        return "Post"
    end
    if ctx.trade then return "Handel" end
    if GetTime() - lastQuest < 3 then return "Quests" end
    return "Looten / Sonstiges"
end

local function Day()
    local d = DB.days[Today()]
    if not d then d = { inn = 0, out = 0, cat = {} }; DB.days[Today()] = d end
    return d
end

local function OnMoney()
    local now = GetMoney()
    local delta = now - last
    last = now
    DB.chars[Me()] = { money = now, ts = time() }
    SnapTotal()
    if delta == 0 then return end
    local c = Category(delta)
    local today = Today()
    if DB.opt.record then
        local d = Day()
        -- Ein- und Auszahlungen bei der Kriegsmeute-Bank sind kein Verdienst und keine Ausgabe
        if c ~= TRANSFER then
            if delta > 0 then d.inn = d.inn + delta else d.out = d.out - delta end
        end
        d.cat[c] = (d.cat[c] or 0) + delta
    end
    -- Erhaltenes Gold (Wochenziel, Charaktere): alles ausser Haendler, Auktionshaus, Handel und Bank
    if delta > 0 and not (ctx.merchant or ctx.ah or ctx.trade or ctx.bank) then
        DB.gained[today] = (DB.gained[today] or 0) + delta
        local cg = DB.charGained[Me()] or {}
        DB.charGained[Me()] = cg
        cg[today] = (cg[today] or 0) + delta
    end
    -- Rohgold der Farm-Session: Loot, Quests und Sonstiges; nicht Haendler, Auktionshaus, Post, Handel
    if GK.farm and (c == "Quests" or c == "Looten / Sonstiges") then GK.farm.money = GK.farm.money + delta end
    if GK.UpdateBar then GK.UpdateBar() end
end

-- Farm-Session -----------------------------------------------------------------
local function Pat(s)
    s = s:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    s = s:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    return "^" .. s .. "$"
end
local PAT_ONE, PAT_MANY = Pat(LOOT_ITEM_SELF), Pat(LOOT_ITEM_SELF_MULTIPLE)

local function OnLoot(msg)
    if not GK.farm or GK.IsSecret(msg) or type(msg) ~= "string" then return end
    local link, n = msg:match(PAT_MANY)
    if not link then link = msg:match(PAT_ONE); n = 1 end
    if not link then return end
    local id = C_Item.GetItemInfoInstant(link)
    if not id then return end
    n = tonumber(n) or 1
    local f = GK.farm
    f.items[id] = (f.items[id] or 0) + n
    local _, _, _, _, _, _, _, _, _, _, sell, _, _, bindType = C_Item.GetItemInfo(id)
    if bindType == 1 then
        -- seelengebunden: nicht handelbar, zaehlt mit dem Haendlerpreis als Rohgold
        f.price[id] = sell or 0
        f.money = f.money + f.price[id] * n
        f.soul = (f.soul or 0) + f.price[id] * n
    else
        f.price[id] = ItemValue(id)
        f.value = f.value + f.price[id] * n
    end
end

-- Kleines, verschiebbares, durchsichtiges Farm-Fenster -----------------------------------
local HUD_ITEMS = 10
function GK.BuildHud()
    if GK.hud then return end
    local h = CreateFrame("Frame", "GoldKompassFarmHud", UIParent, "BackdropTemplate")
    h:SetSize(260, 96 + HUD_ITEMS * 16)
    h:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    h:SetBackdropColor(0, 0, 0, 0.45); h:SetBackdropBorderColor(1, 0.82, 0, 0.5)
    h:SetMovable(true); h:EnableMouse(true); h:RegisterForDrag("LeftButton"); h:SetClampedToScreen(true)
    h:SetScript("OnDragStart", h.StartMoving)
    h:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        DB.hudPos = { p, rp, x, y }
    end)
    local pos = DB.hudPos
    if pos then h:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else h:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0) end

    h.title = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h.title:SetPoint("TOPLEFT", 8, -6); h.title:SetWidth(210); h.title:SetJustifyH("LEFT"); h.title:SetWordWrap(false)
    local x = CreateFrame("Button", nil, h, "UIPanelCloseButton")
    x:SetSize(20, 20); x:SetPoint("TOPRIGHT", 0, 0)
    x:SetScript("OnClick", function() GK.FarmStop(); GK.Refresh() end)
    h.info = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h.info:SetPoint("TOPLEFT", 8, -24); h.info:SetJustifyH("LEFT"); h.info:SetSpacing(2)
    h.head = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h.head:SetPoint("TOPLEFT", 8, -74); h.head:SetText("Top 10 Items")
    h.rows = {}
    for i = 1, HUD_ITEMS do
        local name = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        name:SetPoint("TOPLEFT", 8, -90 - (i - 1) * 16); name:SetWidth(170); name:SetJustifyH("LEFT"); name:SetWordWrap(false)
        local val = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        val:SetPoint("TOPRIGHT", -8, -90 - (i - 1) * 16); val:SetJustifyH("RIGHT")
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
    local total = fm.money + fm.value
    h.title:SetText(fm.name)
    h.info:SetText(string.format("Zeit: %d:%02d\nRohgold: %s\nItem-Wert: %s\nGold/Stunde: %s",
        floor(secs / 60), floor(secs % 60), Mny(fm.money), Mny(fm.value), Mny(secs > 30 and total / secs * 3600 or 0)))
    local list = {}
    for id, n in pairs(fm.items) do list[#list + 1] = { id = id, n = n, v = (fm.price[id] or 0) * n } end
    table.sort(list, function(a, b) return a.v > b.v end)
    for i, r in ipairs(h.rows) do
        local it = list[i]
        if it then
            local name = C_Item.GetItemInfo(it.id) or ("Item " .. it.id)
            local icon = C_Item.GetItemIconByID(it.id)
            r.name:SetText((icon and ("|T" .. icon .. ":12|t ") or "") .. name .. (it.n > 1 and (" x" .. it.n) or ""))
            r.val:SetText(Mny(it.v))
        else
            r.name:SetText(""); r.val:SetText("")
        end
    end
end

function GK.FarmStart(name)
    if not DB.opt.farm then Print("Der Farm-Rechner ist in den Optionen ausgeschaltet (/gk optionen)."); return end
    if GK.farm then Print("Es laeuft schon eine Session."); return end
    name = (name and name ~= "") and name or Zone()
    GK.farm = { name = name, start = GetTime(), money = 0, value = 0, items = {}, price = {} }
    GK.BuildHud()
    GK.hud:Show(); GK.RefreshHud()
    Print("Farm-Session gestartet: " .. name)
end

function GK.FarmStop()
    local f = GK.farm
    if not f then Print("Keine Session aktiv."); return end
    f.secs = GetTime() - f.start
    local total = f.money + f.value
    local rec = { name = f.name, secs = f.secs, total = total, perHour = f.secs > 0 and total / f.secs * 3600 or 0, date = Today() }
    table.insert(DB.farms, rec)
    GK.farm = nil
    if GK.hud then GK.hud:Hide() end
    Print(string.format("%s beendet: %s in %d Min = %s pro Stunde", rec.name, Plain(total), floor(rec.secs / 60), Plain(rec.perHour)))
end

-- Fenster ------------------------------------------------------------------------
local ROWS = 18
local TOP = -92
function GK.Build()
    if GK.frame then return end
    local f = CreateFrame("Frame", "GoldKompassFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(520, 100 + ROWS * 18 + 20); f:SetPoint("CENTER")
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.TitleText:SetText("GoldKompass")
    tinsert(UISpecialFrames, "GoldKompassFrame")
    f:Hide()

    GK.tab = "heute"
    local prev
    for _, t in ipairs({ { "heute", "Heute" }, { "verlauf", "Verlauf" }, { "farm", "Farm" } }) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(90, 22); b:SetText(t[2])
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("TOPLEFT", 12, -30) end
        b:SetScript("OnClick", function() GK.tab = t[1]; GK.Refresh() end)
        prev = b
    end
    local ob = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ob:SetSize(90, 22); ob:SetText("Optionen"); ob:SetPoint("TOPRIGHT", -12, -30)
    ob:SetScript("OnClick", function() GK.ToggleOptions() end)

    -- Farm-Bedienung oben: Start / Stopp und der aktuelle Ort
    f.start = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.start:SetSize(90, 22); f.start:SetPoint("TOPLEFT", 12, -58); f.start:SetText("Start")
    f.start:SetScript("OnClick", function() GK.FarmStart(); GK.Refresh() end)
    f.stop = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.stop:SetSize(90, 22); f.stop:SetPoint("LEFT", f.start, "RIGHT", 4, 0); f.stop:SetText("Stopp")
    f.stop:SetScript("OnClick", function() GK.FarmStop(); GK.Refresh() end)
    f.zone = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.zone:SetPoint("LEFT", f.stop, "RIGHT", 12, 0); f.zone:SetJustifyH("LEFT")

    f.rows = {}
    for i = 1, ROWS do
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", 16, TOP - (i - 1) * 18); fs:SetJustifyH("LEFT")
        f.rows[i] = fs
    end

    f:SetScript("OnShow", function() GK.Refresh() end)
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, e)
        self.elapsed = self.elapsed + e
        if self.elapsed > 1 and GK.farm and GK.tab == "farm" then self.elapsed = 0; GK.Refresh() end
    end)
    GK.frame = f
end

local function Lines(list)
    for i, fs in ipairs(GK.frame.rows) do fs:SetText(list[i] or "") end
end

function GK.Refresh()
    local f = GK.frame
    if not f or not f:IsShown() then return end
    local farmTab = GK.tab == "farm"
    f.start:SetShown(farmTab); f.stop:SetShown(farmTab); f.zone:SetShown(farmTab)
    f.zone:SetText("Ort: |cffffd100" .. Zone() .. "|r")
    local L = {}
    if GK.tab == "heute" then
        local d = Day()
        local sum = 0
        for _, c in pairs(DB.chars) do sum = sum + (c.money or 0) end
        if not DB.opt.record then L[#L + 1] = "|cffff5555Aufzeichnung ist aus (/gk optionen).|r" end
        L[#L + 1] = "Gold gesamt (alle Charaktere): " .. Mny(sum)
        L[#L + 1] = "Heute eingenommen: " .. Mny(d.inn) .. "    ausgegeben: " .. Mny(-d.out) .. "    Saldo: " .. Mny(d.inn - d.out)
        L[#L + 1] = " "
        L[#L + 1] = "|cffffd100Woher / wohin heute|r"
        local cats = {}
        for k, v in pairs(d.cat) do cats[#cats + 1] = { k, v } end
        table.sort(cats, function(a, b) return math.abs(a[2]) > math.abs(b[2]) end)
        for _, c in ipairs(cats) do if #L < 11 then L[#L + 1] = string.format("   %-20s %s", c[1], Mny(c[2])) end end
        L[#L + 1] = " "
        L[#L + 1] = "|cffffd100Charaktere|r"
        for name, c in pairs(DB.chars) do if #L < ROWS then L[#L + 1] = string.format("   %-26s %s", name, Mny(c.money)) end end
    elseif GK.tab == "verlauf" then
        L[#L + 1] = "|cffffd100Saldo der letzten 14 Tage|r"
        local maxv = 1
        local days = {}
        for i = 13, 0, -1 do
            local key = date("%Y-%m-%d", time() - i * 86400)
            local d = DB.days[key]
            local net = d and (d.inn - d.out) or 0
            days[#days + 1] = { date("%d.%m.", time() - i * 86400), net }
            maxv = math.max(maxv, math.abs(net))
        end
        for _, v in ipairs(days) do
            local bar = string.rep("|", floor(math.abs(v[2]) / maxv * 30))
            local col = v[2] >= 0 and "|cff66ff66" or "|cffff5555"
            L[#L + 1] = string.format("%s  %s%s|r  %s", v[1], col, bar, Mny(v[2]))
        end
    else
        local fm = GK.farm
        if fm then
            local secs = GetTime() - fm.start
            local total = fm.money + fm.value
            L[#L + 1] = "|cffffd100Laeuft:|r " .. fm.name .. string.format("  (%d:%02d)", floor(secs / 60), floor(secs % 60))
            L[#L + 1] = "Rohgold: " .. Mny(fm.money) .. "    Item-Wert: " .. Mny(fm.value)
            if (fm.soul or 0) > 0 then L[#L + 1] = "   davon seelengebundene Ware (Haendlerwert): " .. Mny(fm.soul) end
            L[#L + 1] = "Gold pro Stunde: " .. Mny(secs > 30 and total / secs * 3600 or 0)
        else
            L[#L + 1] = "Keine Session aktiv. Start drueckt eine Session fuer deinen aktuellen Ort."
        end
        L[#L + 1] = " "
        L[#L + 1] = "|cffffd100Beste Farm-Sessions (Gold pro Stunde)|r"
        local sorted = {}
        for _, r in ipairs(DB.farms) do sorted[#sorted + 1] = r end
        table.sort(sorted, function(a, b) return a.perHour > b.perHour end)
        for i = 1, math.min(10, #sorted) do
            local r = sorted[i]
            L[#L + 1] = string.format("%2d. %-22.22s %s/h  (%d Min)", i, r.name, Mny(r.perHour), floor(r.secs / 60))
        end
    end
    Lines(L)
end

-- Fenster an/aus: geht immer, auch im Kampf. Ein Fehler beim Bauen oder Fuellen wird gemeldet,
-- haelt das Umschalten aber nicht auf (das Hauptfenster ist kein geschuetzter Rahmen).
function GK.Toggle()
    if not GK.frame then
        local ok, err = pcall(GK.Build)
        if not ok then geterrorhandler()(err) end
    end
    local f = GK.frame
    if not f then return end
    if f:IsShown() then f:Hide() else f:Show() end
end

-- Farm starten oder stoppen (Tastenbelegung)
function GK.ToggleFarm()
    if GK.farm then GK.FarmStop() else GK.FarmStart() end
    if GK.Refresh then pcall(GK.Refresh) end
end

-- Seit Midnight koennen manche Werte (z. B. Chat-Texte im Kampf) "geheim" sein: Addons duerfen sie nicht auswerten.
-- Solche Nachrichten ueberspringen wir, statt mit einem Fehler abzubrechen.
function GK.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) and true or false
end

-- Minimap-Button ---------------------------------------------------------------------
local minimapBtn
local function Minimap_()
    local b = CreateFrame("Button", "GoldKompassMinimapButton", Minimap)
    minimapBtn = b
    b:SetSize(31, 31); b:SetFrameLevel(8)
    b:SetNormalTexture(GK.LOGO)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local function Place()
        local a = math.rad(DB.angle or 235)
        b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
    end
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local sc = Minimap:GetEffectiveScale()
            DB.angle = math.deg(math.atan2(py / sc - my, px / sc - mx)); Place()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(_, btn)
        if btn == "RightButton" then GK.ToggleOptions() else GK.Toggle() end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("GoldKompass"); GameTooltip:AddLine("Linksklick: Fenster", 1, 1, 1)
        GameTooltip:AddLine("Rechtsklick: Optionen", 1, 1, 1); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    Place()
end

function GK.ApplyOptions()
    if minimapBtn then minimapBtn:SetShown(DB.opt.minimap) end
    if not DB.opt.farm and GK.farm then GK.FarmStop() end
    if GK.frame then GK.Refresh() end
end

-- Befehle: zentrales Register fuer /gk ------------------------------------------------------------
-- Jede Datei meldet ihre Befehle hier an: GK.RegisterCommand({ "name", "zweitname" }, function(arg, msg) end, "Hilfetext")
-- Doppelt vergebene Namen werden als Fehler gemeldet, statt sich still gegenseitig zu ueberdecken.
local commands, commandList = {}, {}
GK.CommandAlias = {}   -- englische Namen -> deutscher Befehl (Sprache.lua)

function GK.RegisterCommand(names, fn, help)
    if type(names) == "string" then names = { names } end
    for _, n in ipairs(names) do
        n = strlower(n)
        if commands[n] then
            geterrorhandler()("GoldKompass: Befehl /gk " .. n .. " ist doppelt vergeben")
        else
            commands[n] = fn
        end
    end
    if help then commandList[#commandList + 1] = { name = names[1], help = help } end
end

function GK.CommandHelp()
    table.sort(commandList, function(a, b) return a.name < b.name end)
    return commandList
end

local function Dispatch(msg)
    msg = strtrim(msg or "")
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = strlower(cmd or "")
    local alias = GK.CommandAlias[cmd]
    if alias ~= nil and not commands[cmd] then cmd = alias end
    -- englische Unterbefehle (z. B. /gk guild on -> gilde an), Tabelle in Sprache.lua
    local sub = GK.SubAlias and GK.SubAlias[cmd]
    if sub and arg then
        local w, rest = arg:match("^(%S*)(.*)$")
        local t = w and sub[strlower(w)]
        if t then arg = t .. rest; msg = cmd .. " " .. arg end
    end
    if cmd == "" then
        GK.Toggle()
    elseif commands[cmd] then
        commands[cmd](arg or "", msg)
    else
        Print("Unbekannter Befehl: " .. cmd .. ". Alle Befehle: /gk befehle")
    end
    if GK.Refresh then
        local ok, err = pcall(GK.Refresh)
        if not ok then geterrorhandler()(err) end
    end
end

SLASH_GOLDKOMPASS1, SLASH_GOLDKOMPASS2 = "/goldkompass", "/gk"
SlashCmdList.GOLDKOMPASS = Dispatch

GK.RegisterCommand("start", function(arg) GK.FarmStart(arg) end, "Farm-Session starten (optional mit Name)")
GK.RegisterCommand({ "stop", "stopp" }, function() GK.FarmStop() end, "Farm-Session beenden")
GK.RegisterCommand({ "befehle", "commands" }, function()
    Print("Alle Befehle (/gk ...):")
    for _, c in ipairs(GK.CommandHelp()) do
        local name = GK.CommandName and GK.CommandName(c.name) or c.name
        print("   |cffffd100" .. name .. "|r  " .. (GK.T and GK.T(c.help) or c.help))
    end
end)

-- Datenversion: alte gespeicherte Staende schrittweise umwandeln ------------------------------------
-- Bei jeder Aenderung am Aufbau von GoldKompassDB: DB_VERSION erhoehen und unten einen Schritt ergaenzen.
-- Jeder Schritt laeuft genau einmal; ein Fehler darin wird gemeldet, haelt das Laden aber nicht auf.
local DB_VERSION = 2
local MIGRATE = {
    -- 1: Tabellen des zentralen Goldzaehlers (0.23)
    [1] = function(db)
        db.gained, db.charGained = db.gained or {}, db.charGained or {}
    end,
    -- 2: Zaehler des Preisverlaufs neu bestimmen (konnte nach dem Aufraeumen falsch sein), leere Eintraege entfernen
    [2] = function(db)
        local n = 0
        for id, h in pairs(db.hist or {}) do
            if type(h) ~= "table" or next(h) == nil then db.hist[id] = nil else n = n + 1 end
        end
        db.histN = n
    end,
}
GK.DB_VERSION = DB_VERSION
function GK.Migrate(db)
    local from = tonumber(db.dbVersion) or 0
    for v = from + 1, DB_VERSION do
        local fn = MIGRATE[v]
        if fn then
            local ok, err = pcall(fn, db)
            if not ok then geterrorhandler()("GoldKompass: Datenumwandlung " .. v .. ": " .. tostring(err)) end
        end
        db.dbVersion = v
    end
end

-- Events ----------------------------------------------------------------------------------
local function IsBanker(t)
    local P = Enum and Enum.PlayerInteractionType
    return P and t and (t == P.Banker or (P.AccountBanker and t == P.AccountBanker))
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_MONEY", "CHAT_MSG_LOOT", "MERCHANT_SHOW", "MERCHANT_CLOSED",
    "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "MAIL_SHOW", "MAIL_CLOSED", "TRADE_SHOW", "TRADE_CLOSED", "QUEST_TURNED_IN",
    "ZONE_CHANGED_NEW_AREA", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", "ACCOUNT_MONEY" }) do
    pcall(ev.RegisterEvent, ev, e) -- pcall: nicht jedes Ereignis gibt es in jeder Spielversion
end
ev:SetScript("OnEvent", function(_, event, a1)
    if event == "ADDON_LOADED" then
        if a1 ~= addonName then return end
        GoldKompassDB = GoldKompassDB or {}
        DB = GoldKompassDB
        DB.days, DB.chars, DB.farms = DB.days or {}, DB.chars or {}, DB.farms or {}
        DB.gained, DB.charGained = DB.gained or {}, DB.charGained or {}
        DB.opt = DB.opt or {}
        for k, v in pairs(DEFAULTS) do if DB.opt[k] == nil then DB.opt[k] = v end end
        GK.Migrate(DB)
    elseif event == "PLAYER_LOGIN" then
        last = GetMoney()
        DB.chars[Me()] = { money = last, ts = time() }
        ReadWarbank()
        SnapTotal()
        Minimap_()
        GK.ApplyOptions()
        if DB.opt.welcome then
            Print("geladen. /gk Fenster, /gk optionen, /gk start, /gk stop, /gk befehle.")
        end
    elseif not DB then return
    elseif event == "PLAYER_MONEY" then OnMoney()
    elseif event == "ACCOUNT_MONEY" then ReadWarbank(); SnapTotal()
    elseif event == "BANKFRAME_OPENED" then ctx.bank = true; ReadWarbank()
    elseif event == "BANKFRAME_CLOSED" then ctx.bank = nil; ReadWarbank(); SnapTotal()
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then if IsBanker(a1) then ctx.bank = true; ReadWarbank() end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then if IsBanker(a1) then ctx.bank = nil; ReadWarbank(); SnapTotal() end
    elseif event == "CHAT_MSG_LOOT" then if DB.opt.farm then OnLoot(a1) end
    elseif event == "QUEST_TURNED_IN" then lastQuest = GetTime()
    elseif event == "MERCHANT_SHOW" then ctx.merchant = true
    elseif event == "MERCHANT_CLOSED" then ctx.merchant = nil
    elseif event == "AUCTION_HOUSE_SHOW" then ctx.ah = true
    elseif event == "AUCTION_HOUSE_CLOSED" then ctx.ah = nil
    elseif event == "MAIL_SHOW" then ctx.mail = true
    elseif event == "MAIL_CLOSED" then ctx.mail = nil
    elseif event == "TRADE_SHOW" then ctx.trade = true
    elseif event == "TRADE_CLOSED" then ctx.trade = nil end
    if GK.frame and GK.frame:IsShown() then GK.Refresh() end
end)
