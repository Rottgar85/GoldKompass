-- GoldKompass Broker: Anzeige in Titan Panel, ElvUI-Datentexten, Bazooka, ChocolateBar und aehnlichen Leisten.
-- Nutzt LibDataBroker, das diese Leisten selbst mitbringen. Ohne so eine Leiste passiert hier nichts.
-- Text: Saldo heute, bei laufender Farm zusaetzlich Gold pro Stunde. Linksklick Fenster, Rechtsklick Optionen.
local GK = GoldKompass
local function T(s) return GK.T and GK.T(s) or s end
local obj

local function Text()
    local db = GK.DB and GK.DB()
    if not db then return "GoldKompass" end
    local d = db.days and db.days[date("%Y-%m-%d")] or { inn = 0, out = 0 }
    local txt = GK.FmtGoldShort((d.inn or 0) - (d.out or 0))
    local fm = GK.farm
    if fm then
        local secs = GetTime() - fm.start
        local total = fm.money + fm.value - (fm.costs or 0)
        if secs > 30 then txt = txt .. "  |cffffd100" .. GK.FmtGoldShort(total / secs * 3600) .. "/h|r" end
    end
    return txt
end

local function Tooltip(tt)
    local db = GK.DB and GK.DB()
    tt:AddLine("GoldKompass", 1, 0.82, 0)
    if db then
        local total, _, warbank = GK.TotalGold()
        local d = db.days and db.days[date("%Y-%m-%d")] or { inn = 0, out = 0 }
        tt:AddDoubleLine(T("Gold gesamt"), GK.FmtGold(total), 1, 1, 1)
        if db.warbank then tt:AddDoubleLine(T("   davon Kriegsmeute-Bank"), GK.FmtGold(warbank), 0.8, 0.8, 0.8) end
        tt:AddDoubleLine(T("Heute eingenommen"), GK.FmtGold(d.inn or 0), 1, 1, 1)
        tt:AddDoubleLine(T("Heute ausgegeben"), GK.FmtGold(-(d.out or 0)), 1, 1, 1)
        if db.weekGoal and GK.LiveWeek then
            local net = GK.LiveWeek()
            tt:AddDoubleLine(T("Wochenziel"), floor(math.max(net / (db.weekGoal * 10000), 0) * 100) .. "%", 1, 1, 1)
        end
        local fm = GK.farm
        if fm then
            local secs = GetTime() - fm.start
            local total2 = fm.money + fm.value - (fm.costs or 0)
            tt:AddLine(" ")
            tt:AddDoubleLine(fm.name, string.format("%d:%02d", floor(secs / 60), floor(secs % 60)), 1, 0.82, 0)
            tt:AddDoubleLine(T("Gold pro Stunde"), GK.FmtGold(secs > 30 and total2 / secs * 3600 or 0), 1, 1, 1)
        end
    end
    tt:AddLine(" ")
    tt:AddLine(T("Linksklick: Fenster"), 0.7, 0.7, 0.7)
    tt:AddLine(T("Rechtsklick: Optionen"), 0.7, 0.7, 0.7)
end

local function Update()
    if obj then obj.text = Text() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    if not LDB then return end
    obj = LDB:NewDataObject("GoldKompass", {
        type = "data source",
        label = "GoldKompass",
        text = "GoldKompass",
        icon = GK.LOGO,
        OnClick = function(_, button)
            if button == "RightButton" then GK.ToggleOptions() else GK.Toggle() end
        end,
        OnTooltipShow = function(tt) pcall(Tooltip, tt) end,
    })
    if not obj then return end
    pcall(Update)
    -- kein eigener Takt: UpdateBar laeuft ohnehin alle 2 Sekunden und bei jeder Goldaenderung
    if type(GK.UpdateBar) == "function" then hooksecurefunc(GK, "UpdateBar", function() pcall(Update) end) end
end)
