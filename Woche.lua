-- GoldKompass Extras: Historie (Gebiete/Sessions), Woche (Diagramm + Wochenziel), Kosten, Filter, Export
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end

-- Goldbetraege mit Muenzsymbolen aus dem Spiel und Tausenderpunkten: 12.345[Gold] 20[Silber]
-- Silber nur unter 10.000 Gold und wenn es nicht 0 ist; noSilver laesst es ganz weg (Kacheln, Achsen).
local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:1:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:1:0|t"
local function Thousands(n)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
    local s = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return (s:gsub("^%.", ""))
end
local function G(c, noSilver)
    c = c or 0
    local neg = c < 0
    c = math.abs(c)
    local gold, silver = floor(c / 10000), floor((c % 10000) / 100)
    local col = neg and "|cffff5555" or "|cff66ff66"
    local t = col .. (neg and "-" or "") .. Thousands(gold) .. "|r" .. GOLD_ICON
    if not noSilver and gold < 10000 and silver > 0 then t = t .. " " .. col .. silver .. "|r" .. SILVER_ICON end
    return t
end
GK.Thousands = Thousands
GK.GOLD_ICON, GK.SILVER_ICON = GOLD_ICON, SILVER_ICON
local function Num(s)
    s = tostring(s or ""):gsub(",", ".")
    return tonumber(s)
end
local function Bar(n, color)
    return color .. string.rep("||", math.max(0, math.min(30, n))) .. "|r"
end
local function Net(r) return r.net or r.total or 0 end
local function NetPerHour(r)
    if r.netPerHour then return r.netPerHour end
    return (r.secs or 0) > 0 and Net(r) / r.secs * 3600 or 0
end
local function WeekStart()
    local wd = date("*t").wday            -- 1 = Sonntag
    local back = (wd + 5) % 7             -- Tage seit Montag
    return date("%Y-%m-%d", time() - back * 86400)
end

-- Kosten ------------------------------------------------------------------------
function GK.AddCost(gold)
    local f = GK.farm
    if not f then Print("Keine Session aktiv. Starte zuerst eine Farm-Session."); return end
    if not gold or gold <= 0 then Print("So: /gk kosten 50   (Betrag in Gold)"); return end
    f.costs = (f.costs or 0) + gold * 10000
    Print("Kosten gebucht: " .. G(gold * 10000) .. "  (gesamt " .. G(f.costs) .. ")")
    GK.Refresh()
end

local origStop = GK.FarmStop
function GK.FarmStop()
    local f = GK.farm
    local n = #GK.DB().farms
    origStop()
    local rec = GK.DB().farms[#GK.DB().farms]
    if f and rec and #GK.DB().farms > n then
        rec.costs = f.costs or 0
        rec.net = rec.total - rec.costs
        rec.netPerHour = rec.secs > 0 and rec.net / rec.secs * 3600 or 0
        if rec.costs > 0 then
            Print(string.format("Nach Kosten (%s): %s, das sind %s pro Stunde.", G(rec.costs), G(rec.net), G(rec.netPerHour)))
        end
    end
end

-- Filter fuers kleine Farm-Fenster: Items unter dem Mindestwert ausblenden -----------------
local origHud = GK.RefreshHud
function GK.RefreshHud()
    local fm = GK.farm
    local min = (GK.DB().opt.minValue or 0) * 10000
    if not fm or min <= 0 then return origHud() end
    local real, filt = fm.items, {}
    for id, n in pairs(real) do
        if (fm.price[id] or 0) * n >= min then filt[id] = n end
    end
    fm.items = filt
    local ok, err = pcall(origHud)
    fm.items = real
    if not ok then error(err) end
end

-- Export --------------------------------------------------------------------------
local function CSV()
    local function C(c) return (string.format("%.2f", (c or 0) / 10000):gsub("%.", ",")) end
    local out = { "Datum;Gebiet;Minuten;Gold brutto;Kosten;Gold netto;Netto pro Stunde" }
    for _, r in ipairs(GK.DB().farms) do
        out[#out + 1] = table.concat({ r.date or "", (r.name or ""):gsub(";", ","), floor((r.secs or 0) / 60),
            C(r.total), C(r.costs or 0), C(Net(r)), C(NetPerHour(r)) }, ";")
    end
    return table.concat(out, "\n")
end
local exportFrame
function GK.ShowExport()
    if not exportFrame then
        local e = CreateFrame("Frame", "GoldKompassExport", UIParent, "BasicFrameTemplateWithInset")
        e:SetSize(540, 320); e:SetPoint("CENTER"); e:SetFrameStrata("DIALOG")
        e:SetMovable(true); e:EnableMouse(true); e:RegisterForDrag("LeftButton")
        e:SetScript("OnDragStart", e.StartMoving); e:SetScript("OnDragStop", e.StopMovingOrSizing)
        e.TitleText:SetText("GoldKompass Export")
        tinsert(UISpecialFrames, "GoldKompassExport")
        local hint = e:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 14, -30); hint:SetText("Alles markiert: Strg+C kopiert, dann in Excel oder Editor einfuegen (Trennzeichen ;).")
        local sf = CreateFrame("ScrollFrame", nil, e, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 14, -50); sf:SetPoint("BOTTOMRIGHT", -32, 14)
        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetMultiLine(true); eb:SetFontObject("ChatFontNormal"); eb:SetWidth(480); eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function() e:Hide() end)
        sf:SetScrollChild(eb)
        e.eb = eb
        exportFrame = e
    end
    exportFrame.eb:SetText(CSV())
    exportFrame:Show()
    exportFrame.eb:SetFocus(); exportFrame.eb:HighlightText()
end

-- Wochenziel --------------------------------------------------------------------------
function GK.SetGoal(gold)
    GK.DB().weekGoal = (gold and gold > 0) and gold or nil
    Print(gold and gold > 0 and ("Wochenziel: " .. G(gold * 10000)) or "Wochenziel entfernt.")
    GK.Refresh()
end
local function WeekNet()
    local ws, sum, cnt = WeekStart(), 0, 0
    for _, r in ipairs(GK.DB().farms) do
        if (r.date or "") >= ws then sum = sum + Net(r); cnt = cnt + 1 end
    end
    return sum, cnt
end

-- Fenster: Tabs und Eingabefelder ---------------------------------------------------------
local function EditBox(parent, w)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(w, 20); eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    return eb
end

local origBuild = GK.Build
function GK.Build()
    origBuild()
    local f = GK.frame
    if not f or f.gkExtra then return end
    f.gkExtra = true
    f:SetSize(600, f:GetHeight() + 34)

    local x = 12 + 3 * 94
    for _, t in ipairs({ { "historie", "Historie" }, { "woche", "Woche" } }) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(90, 22); b:SetText(t[2]); b:SetPoint("TOPLEFT", x, -30)
        b:SetScript("OnClick", function() GK.tab = t[1]; GK.Refresh() end)
        x = x + 94
    end

    -- Farm-Reiter, unten: Kosten buchen und Filter
    f.farmBits = {}
    local l1 = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    l1:SetPoint("BOTTOMLEFT", 16, 16); l1:SetText("Kosten (g):")
    local cost = EditBox(f, 60); cost:SetPoint("LEFT", l1, "RIGHT", 10, 0)
    local cb = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cb:SetSize(80, 22); cb:SetText("Abziehen"); cb:SetPoint("LEFT", cost, "RIGHT", 6, 0)
    local function Book() GK.AddCost(Num(cost:GetText())); cost:SetText(""); cost:ClearFocus() end
    cb:SetScript("OnClick", Book); cost:SetScript("OnEnterPressed", Book)
    local l2 = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    l2:SetPoint("LEFT", cb, "RIGHT", 20, 0); l2:SetText("Items ausblenden unter (g):")
    local flt = EditBox(f, 50); flt:SetPoint("LEFT", l2, "RIGHT", 10, 0)
    local function SetFilter()
        local v = Num(flt:GetText()) or 0
        GK.DB().opt.minValue = v > 0 and v or 0
        flt:ClearFocus(); GK.Refresh(); GK.RefreshHud()
    end
    flt:SetScript("OnEnterPressed", SetFilter); flt:SetScript("OnEditFocusLost", SetFilter)
    f.filterBox = flt
    f.farmBits = { l1, cost, cb, l2, flt }

    -- Woche-Reiter: Wochenziel eintragen
    local gl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    gl:SetPoint("TOPLEFT", 16, -62); gl:SetText("Wochenziel (g):")
    local ge = EditBox(f, 80); ge:SetPoint("LEFT", gl, "RIGHT", 10, 0)
    local gb = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    gb:SetSize(80, 22); gb:SetText("Setzen"); gb:SetPoint("LEFT", ge, "RIGHT", 6, 0)
    local function Goal() GK.SetGoal(Num(ge:GetText())); ge:ClearFocus() end
    gb:SetScript("OnClick", Goal); ge:SetScript("OnEnterPressed", Goal)
    f.goalBits = { gl, ge, gb }
    f.goalBox = ge

    -- Historie-Reiter: Export
    local xb = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    xb:SetSize(130, 22); xb:SetText("Export (Tabelle)"); xb:SetPoint("TOPLEFT", 12, -58)
    xb:SetScript("OnClick", function() GK.ShowExport() end)
    f.histBits = { xb }
end

local function Lines(list)
    for i, fs in ipairs(GK.frame.rows) do fs:SetText(list[i] or "") end
end

local origRefresh = GK.Refresh
function GK.Refresh()
    origRefresh()
    local f = GK.frame
    if not f or not f.gkExtra or not f:IsShown() then return end
    local tab = GK.tab
    for _, w in ipairs(f.farmBits) do w:SetShown(tab == "farm") end
    for _, w in ipairs(f.goalBits) do w:SetShown(tab == "woche") end
    for _, w in ipairs(f.histBits) do w:SetShown(tab == "historie") end
    local DB = GK.DB()

    if tab == "farm" then
        if not f.filterBox:HasFocus() then
            f.filterBox:SetText((DB.opt.minValue or 0) > 0 and tostring(DB.opt.minValue) or "")
        end
        local fm = GK.farm
        if fm and (fm.costs or 0) > 0 then
            local secs = GetTime() - fm.start
            local net = fm.money + fm.value - fm.costs
            f.rows[17]:SetText("Kosten: " .. G(fm.costs))
            f.rows[18]:SetText("Gewinn nach Kosten: " .. G(net) .. "   pro Stunde: " .. G(secs > 30 and net / secs * 3600 or 0))
        end

    elseif tab == "historie" then
        local L = {}
        local zones, order = {}, {}
        for _, r in ipairs(DB.farms) do
            local z = zones[r.name]
            if not z then z = { name = r.name, net = 0, secs = 0, n = 0 }; zones[r.name] = z; order[#order + 1] = z end
            z.net = z.net + Net(r); z.secs = z.secs + (r.secs or 0); z.n = z.n + 1
        end
        table.sort(order, function(a, b)
            return (a.secs > 0 and a.net / a.secs or 0) > (b.secs > 0 and b.net / b.secs or 0)
        end)
        L[#L + 1] = "|cffffd100Beste Gebiete (Durchschnitt netto pro Stunde)|r"
        if #order == 0 then L[#L + 1] = "   Noch keine beendete Session. Im Reiter Farm auf Start und Stopp klicken." end
        for i = 1, math.min(7, #order) do
            local z = order[i]
            L[#L + 1] = string.format("%d. %s   %s/h   (%d Sessions)", i, z.name, G(z.secs > 0 and z.net / z.secs * 3600 or 0), z.n)
        end
        L[#L + 1] = " "
        L[#L + 1] = "|cffffd100Letzte Sessions|r"
        local total = #DB.farms
        for i = total, math.max(1, total - 7), -1 do
            local r = DB.farms[i]
            L[#L + 1] = string.format("%s  %s   %d Min   %s   %s/h", r.date or "?", r.name or "?", floor((r.secs or 0) / 60), G(Net(r)), G(NetPerHour(r)))
        end
        Lines(L)

    elseif tab == "woche" then
        local L = {}
        local goal = DB.weekGoal
        if not f.goalBox:HasFocus() then f.goalBox:SetText(goal and tostring(goal) or "") end
        local net, cnt = WeekNet()
        L[#L + 1] = "|cffffd100Wochenziel (Netto aus Farm-Sessions seit Montag)|r"
        if goal then
            local pct = net / (goal * 10000)
            local n = math.floor(math.min(pct, 1) * 30)
            L[#L + 1] = Bar(n, pct >= 1 and "|cff66ff66" or "|cffffd100") .. Bar(30 - n, "|cff555555") .. string.format("  %d%%", floor(pct * 100))
            L[#L + 1] = G(net) .. " von " .. G(goal * 10000) .. "   (" .. cnt .. " Sessions)"
            L[#L + 1] = pct >= 1 and "|cff66ff66Ziel erreicht!|r" or ("Noch offen: " .. G(goal * 10000 - net))
        else
            L[#L + 1] = "Kein Ziel gesetzt. Oben den Betrag in Gold eintragen und auf Setzen klicken."
            L[#L + 1] = "Diese Woche bisher: " .. G(net) .. "   (" .. cnt .. " Sessions)"
        end
        L[#L + 1] = " "
        L[#L + 1] = "|cffffd100Letzte 7 Tage|r   |cff66ff66gruen = eingenommen|r   |cffff5555rot = ausgegeben|r"
        local days, maxv = {}, 1
        for i = 6, 0, -1 do
            local d = DB.days[date("%Y-%m-%d", time() - i * 86400)]
            local inn, out = d and d.inn or 0, d and d.out or 0
            days[#days + 1] = { date("%a %d.%m.", time() - i * 86400), inn, out }
            maxv = math.max(maxv, inn, out)
        end
        local si, so = 0, 0
        for _, d in ipairs(days) do
            si, so = si + d[2], so + d[3]
            L[#L + 1] = d[1] .. "  " .. Bar(floor(d[2] / maxv * 20), "|cff66ff66") .. " " .. G(d[2])
            L[#L + 1] = "              " .. Bar(floor(d[3] / maxv * 20), "|cffff5555") .. " " .. G(d[3])
        end
        L[#L + 1] = "Summe 7 Tage: ein " .. G(si) .. "   aus " .. G(so) .. "   Saldo " .. G(si - so)
        Lines(L)
    end
end

-- Befehle -------------------------------------------------------------------------------
GK.RegisterCommand("kosten", function(arg) GK.AddCost(Num(arg)) end, "Kosten zur laufenden Farm buchen (Gold)")
-- "/gk ziel 5000" setzt das Wochenziel, "/gk ziel aus" entfernt es, "/gk ziel" ohne Betrag oeffnet die Sparziele
GK.RegisterCommand("ziel", function(arg)
    arg = strlower(strtrim(arg or ""))
    if arg == "" then
        if GK.OpenPlus then GK.OpenPlus("ziele") end
    elseif arg == "aus" or arg == "off" or arg == "0" then
        GK.SetGoal(nil)
    else
        local v = Num(arg)
        if v then GK.SetGoal(v) else Print("So: /gk ziel 5000   (Wochenziel in Gold, /gk ziel aus entfernt es)") end
    end
end, "Wochenziel setzen: ziel 5000, ziel aus")
GK.RegisterCommand("filter", function(arg)
    local v = Num(arg) or 0
    GK.DB().opt.minValue = v > 0 and v or 0
    Print(v > 0 and ("Items unter " .. G(v * 10000) .. " werden ausgeblendet.") or "Filter aus.")
    GK.RefreshHud(); GK.Refresh()
end, "Farm-Fenster: Items unter X Gold ausblenden")
GK.RegisterCommand("export", function() GK.ShowExport() end, "Farm-Sessions als Tabelle exportieren")

-- Reparaturkosten automatisch buchen (nur waehrend einer Farm-Session) ----------------------------
local repairCost = 0
local function SnapRepair()
    local c = GetRepairAllCost and GetRepairAllCost()
    repairCost = tonumber(c) or 0
end
hooksecurefunc("RepairAllItems", function(useGuild)
    if useGuild or repairCost <= 0 then return end
    local o = GK.DB() and GK.DB().opt
    if o and o.autoRepair and GK.farm then
        GK.farm.costs = (GK.farm.costs or 0) + repairCost
        Print("Reparatur als Kosten gebucht: " .. G(repairCost))
    end
    repairCost = 0
    C_Timer.After(1, SnapRepair)
end)

-- Wochenleiste: Erfahrungsleiste fuers Wochenziel, verschiebbar -------------------------------------
local bar
local function LiveWeek()
    local net, cnt = WeekNet()
    local fm = GK.farm
    if fm then net = net + fm.money + fm.value - (fm.costs or 0) end
    return net, cnt
end

local function BuildBar()
    if bar then return end
    local b = CreateFrame("Frame", "GoldKompassWeekBar", UIParent, "BackdropTemplate")
    b:SetSize(420, 22); b:SetFrameStrata("MEDIUM")
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    b:SetBackdropColor(0, 0, 0, 0.7); b:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    b:SetMovable(true); b:EnableMouse(true); b:RegisterForDrag("LeftButton"); b:SetClampedToScreen(true)
    b:SetScript("OnDragStart", function(self) if not GK.DB().opt.barLock then self:StartMoving() end end)
    b:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        GK.DB().barPos = { p, rp, x, y }
    end)
    local pos = GK.DB().barPos
    if pos then b:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else b:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 6) end

    local sb = CreateFrame("StatusBar", nil, b)
    sb:SetPoint("TOPLEFT", 1, -1); sb:SetPoint("BOTTOMRIGHT", -1, 1)
    sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    sb:SetMinMaxValues(0, 1); sb:SetValue(0)
    b.sb = sb
    local shine = sb:CreateTexture(nil, "OVERLAY")
    shine:SetAllPoints(); shine:SetColorTexture(1, 1, 1, 0.08)
    b.text = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("CENTER")

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("GoldKompass Wochenziel")
        local net, cnt = LiveWeek()
        local goal = GK.DB().weekGoal
        GameTooltip:AddLine("Diese Woche netto: " .. G(net) .. " (" .. cnt .. " Sessions)", 1, 1, 1)
        if goal then GameTooltip:AddLine("Ziel: " .. G(goal * 10000), 1, 1, 1) end
        GameTooltip:AddLine("Ziehen: verschieben (in den Optionen sperrbar)", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    bar = b
end

function GK.UpdateBar()
    local o = GK.DB() and GK.DB().opt
    if not o then return end
    if not o.weekBar then if bar then bar:Hide() end; return end
    BuildBar()
    bar:Show()
    local net = LiveWeek()
    local goal = GK.DB().weekGoal
    if goal then
        local pct = net / (goal * 10000)
        bar.sb:SetMinMaxValues(0, 1); bar.sb:SetValue(math.max(0, math.min(pct, 1)))
        if pct >= 1 then bar.sb:SetStatusBarColor(0.2, 0.8, 0.2) else bar.sb:SetStatusBarColor(0.58, 0, 0.55) end
        bar.text:SetText(string.format("Woche: %s von %s  (%d%%)", floor(net / 10000) .. "g", floor(goal) .. "g", floor(math.max(pct, 0) * 100)))
    else
        bar.sb:SetValue(0)
        bar.text:SetText("Kein Wochenziel gesetzt  (/gk ziel 5000)")
    end
end

-- Optionen um Leiste und Reparatur erweitern ----------------------------------------------------------
local origBuildOpt = GK.BuildOptions
function GK.BuildOptions()
    if GK.optFrame then return end
    origBuildOpt()
    local f = GK.optFrame
    if not f or f.gkExtra then return end
    f.gkExtra = true
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", GK.frame, "TOPRIGHT", -2, 0)
    f:SetHeight(660)
    local y = -540
    local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 16, y); h:SetText("Leiste und Kosten")
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.35); line:SetHeight(1)
    line:SetPoint("TOPLEFT", 16, y - 16); line:SetPoint("TOPRIGHT", -16, y - 16)
    y = y - 24
    for _, c in ipairs({
        { "weekBar", "Wochenleiste am Bildschirm zeigen" },
        { "barLock", "Wochenleiste sperren (nicht verschiebbar)" },
        { "autoRepair", "Reparatur automatisch als Kosten buchen" },
    }) do
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", 14, y); y = y - 24
        cb.text:SetText(c[2]); cb.text:SetFontObject("GameFontHighlightSmall")
        cb:SetScript("OnClick", function(self)
            GK.DB().opt[c[1]] = self:GetChecked() and true or false
            GK.UpdateBar()
        end)
        f.checks[c[1]] = cb
    end
end

local ev2 = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "MERCHANT_SHOW", "MERCHANT_UPDATE", "UPDATE_INVENTORY_DURABILITY" }) do ev2:RegisterEvent(e) end
ev2:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local o = GK.DB().opt
        if o.weekBar == nil then o.weekBar = true end
        if o.barLock == nil then o.barLock = false end
        if o.autoRepair == nil then o.autoRepair = true end
        GK.UpdateBar()
        C_Timer.NewTicker(2, GK.UpdateBar)
    else
        SnapRepair()
    end
end)

local origRefresh2 = GK.Refresh
function GK.Refresh()
    origRefresh2()
    GK.UpdateBar()
end

-- Wochengold = wirklich erhaltenes Gold (Loot, Quests, Post, Rohgold) ---------------------------------------
-- Nicht gezaehlt: Gold beim Haendler, bei offenem Auktionshaus und im Handel. Optional nur Farm-Sessions.
-- DB.gained fuellt der zentrale Goldzaehler in GoldKompass.lua
local farmWeek, farmLive = WeekNet, LiveWeek
WeekNet = function()
    if GK.DB().opt.weekFarmOnly then return farmWeek() end
    local ws, sum = WeekStart(), 0
    for day, v in pairs(GK.DB().gained or {}) do
        if day >= ws then sum = sum + v end
    end
    local _, cnt = farmWeek()
    return sum, cnt
end
LiveWeek = function()
    if GK.DB().opt.weekFarmOnly then return farmLive() end
    return WeekNet()
end

-- Beschriftung im Woche-Reiter passend zur Zaehlweise
local origRefresh3 = GK.Refresh
function GK.Refresh()
    origRefresh3()
    local f = GK.frame
    if f and f.gkExtra and f:IsShown() and GK.tab == "woche" and not GK.DB().opt.weekFarmOnly then
        f.rows[1]:SetText("|cffffd100Wochenziel (erhaltenes Gold seit Montag: Loot, Quests, Post)|r")
    end
end

-- Schalter in den Optionen
local origBuildOpt2 = GK.BuildOptions
function GK.BuildOptions()
    if GK.optFrame then return end
    origBuildOpt2()
    local f = GK.optFrame
    if not f or f.gkExtra2 then return end
    f.gkExtra2 = true
    f:SetHeight(690)
    local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", 14, -636)
    cb.text:SetText("Wochenziel nur aus Farm-Sessions"); cb.text:SetFontObject("GameFontHighlightSmall")
    cb:SetScript("OnClick", function(self)
        GK.DB().opt.weekFarmOnly = self:GetChecked() and true or false
        GK.UpdateBar(); GK.Refresh()
    end)
    f.checks.weekFarmOnly = cb
end

-- fuer Extras2
function GK.LiveWeek() return LiveWeek() end
function GK.FmtGold(c) return G(c) end
function GK.FmtGoldShort(c) return G(c, true) end -- ohne Silber, fuer Kacheln und knappe Stellen
