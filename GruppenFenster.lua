-- GoldKompass Gruppenfenster: Host- und Beitreten-Knopf im Gruppe-Reiter des Hauptfensters
-- Die Gruppen-Beute zeichnet Gruppe.lua auf; /gkgruppe und /gk beute zeigen dasselbe Fenster.
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local TITLE = "|cffffd100GoldKompass|r"
local ACTIVE = 15 -- Sekunden, nach denen eine Farm als beendet gilt

SLASH_GKGRUPPE1 = "/gkgruppe"
SlashCmdList.GKGRUPPE = function() GK.BeuteOpen() end

-- Beute oeffnen. Eigener Befehl, unabhaengig von der Befehlskette des /gk-Befehls
function GK.BeuteOpen()
    if not GK.BeuteShow then print(TITLE .. ": Gruppen-Beute ist nicht geladen.") return end
    GK.BeuteShow()
    if GK.beute then
        GK.beute:Show(); GK.beute:Raise()
        print(TITLE .. ": Gruppen-Beute geöffnet.")
    end
end

-- /gk beute und /gk beute leeren
GK.RegisterCommand({ "beute", "loot" }, function(arg)
    if strlower(strtrim(arg or "")) == "leeren" then
        GK.DB().groupLoot = {}
        if GK.BeuteRefresh then GK.BeuteRefresh() end
        print(TITLE .. ": Gruppen-Beute geleert.")
    else
        GK.BeuteOpen()
    end
end, "Gruppen-Beute (beute leeren setzt sie zurück)")

-- Wer farmt gerade in der Gruppe? (Meldungen kommen aus Gruppe.lua)
local function ActivePeer()
    for name, p in pairs(GK.peers or {}) do
        if p.farming and p.t and GetTime() - p.t < ACTIVE then return name, p end
    end
end

local function Host()
    if GK.farm then
        GK.FarmStop()
    else
        if not GK.Channel() then print(TITLE .. ": Du bist in keiner Gruppe.") return end
        local o = GK.DB().opt
        if not o.groupShare then
            o.groupShare = true
            print(TITLE .. ": Gruppen-Farm teilen war aus und ist jetzt an, damit die anderen dich sehen.")
        end
        GK.FarmStart("Gruppenfarm von " .. UnitName("player"))
        if GK.SendFarmState then GK.SendFarmState(true) end
    end
    GK.Refresh()
end

local function Join()
    local name = ActivePeer()
    if not name then print(TITLE .. ": Gerade farmt niemand in der Gruppe.") return end
    if GK.farm then print(TITLE .. ": Es läuft schon eine eigene Farm.") return end
    GK.FarmStart("Gruppenfarm von " .. name)
    GK.Refresh()
end

local btns
local function Build()
    btns = {}
    local host = CreateFrame("Button", nil, GK.frame, "UIPanelButtonTemplate")
    host:SetSize(120, 22); host:SetPoint("TOPLEFT", 12, -58)
    host:SetScript("OnClick", Host)
    local join = CreateFrame("Button", nil, GK.frame, "UIPanelButtonTemplate")
    join:SetSize(120, 22); join:SetPoint("LEFT", host, "RIGHT", 4, 0)
    join:SetText("Beitreten")
    join:SetScript("OnClick", Join)
    btns.host, btns.join = host, join
end

-- Knöpfe nur im Gruppe-Reiter zeigen, Beschriftung nach Zustand
local function Update()
    if not GK.frame then return end
    if not btns then Build() end
    local show = GK.frame:IsShown() and GK.tab == "gruppe"
    btns.host:SetShown(show); btns.join:SetShown(show)
    if not show then return end
    btns.host:SetText(GK.farm and "Host stoppen" or "Host starten")
    btns.host:SetEnabled(GK.farm ~= nil or GK.Channel() ~= nil)
    btns.join:SetShown(show and GK.farm == nil and ActivePeer() ~= nil)
end

hooksecurefunc(GK, "Refresh", Update)

-- Gruppen-Beute kompakt: nur die Top 8, mit der Ecke unten rechts frei veraenderbar
local BEUTE_TOP = 8

local origBeuteRefreshCompact = GK.BeuteRefresh
function GK.BeuteRefresh()
    origBeuteRefreshCompact()
    local f, DB = GK.beute, GK.DB()
    if not f or not f:IsShown() or not DB then return end
    local t = DB.groupLoot or {}
    f.info:SetText(string.format("Top %d von %d erfassten Drops, nach Wert", math.min(BEUTE_TOP, #t), #t))
end

-- Gruppen-Beute im Stil des Farm-Fensters: gleicher dunkler Hintergrund, feine Goldkante, gleiche Schriften und Zeilen
local function BuildBeuteHud()
    local f = CreateFrame("Frame", "GoldKompassBeuteHud", UIParent, "BackdropTemplate")
    f:SetSize(430, 70 + BEUTE_TOP * 16 + 10)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(0, 0, 0, 0.45); f:SetBackdropBorderColor(1, 0.82, 0, 0.5)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetResizable(true)
    if f.SetResizeBounds then f:SetResizeBounds(330, 150, 900, 700) end

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 8, -6); f.title:SetText("Gruppen-Beute")
    local x = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    x:SetSize(20, 20); x:SetPoint("TOPRIGHT", 0, 0)
    x:SetScript("OnClick", function() f:Hide() end)

    f.info = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.info:SetPoint("TOPLEFT", 8, -24); f.info:SetJustifyH("LEFT")
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.35); line:SetHeight(1)
    line:SetPoint("TOPLEFT", 8, -47); line:SetPoint("TOPRIGHT", -8, -47)

    f.rows = {}
    for i = 1, BEUTE_TOP do
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 8, -54 - (i - 1) * 16); fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
        f.rows[i] = fs
    end
    f:SetScript("OnSizeChanged", function(self, w)
        for _, fs in ipairs(self.rows) do fs:SetWidth(w - 16) end
    end)

    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", -3, 3)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    f:Hide()
    return f
end

-- Gruppen-Beute anzeigen: GK.beute ist das Fenster im Stil des Farm-Fensters
function GK.BeuteShow()
    if not GK.beuteHud then GK.beuteHud = BuildBeuteHud() end
    GK.beute = GK.beuteHud
    GK.DockBeute(GK.beute)
    if GK.beute:GetNumPoints() == 0 then GK.beute:SetPoint("CENTER") end
    GK.beute:Show(); GK.beute:Raise()
    GK.BeuteRefresh()
end

-- Gruppen-Beute folgt der Designfarbe aus den Optionen, genau wie das Farm-Fenster (Rahmen.lua)
local BEUTE_COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}
local function BeuteTheme()
    local f = GK.beuteHud
    local db = GK.DB and GK.DB()
    if not f or not db or not db.opt then return end
    local c = BEUTE_COLORS[db.opt.theme or "gold"] or BEUTE_COLORS.gold
    if f.gkEdge ~= 2 then
        local bd = f:GetBackdrop()
        if not bd then return end
        local r, g, b, a = f:GetBackdropColor()
        bd.edgeSize = 2
        f:SetBackdrop(bd)
        f:SetBackdropColor(r, g, b, a)
        f.gkEdge = 2
    end
    f:SetBackdropBorderColor(c[1], c[2], c[3], 1)
end

local origBeuteShowTheme = GK.BeuteShow
function GK.BeuteShow()
    origBeuteShowTheme()
    pcall(BeuteTheme)
end
C_Timer.NewTicker(1, function()
    if GK.beute and GK.beute:IsShown() then pcall(BeuteTheme) end
end)

-- Gruppenfarm-Name: aus „Gruppenfarm von Name“ wird „Name (Host)“
local origFarmStartHost = GK.FarmStart
function GK.FarmStart(name, ...)
    local who = name and name:match("^Gruppenfarm von (.+)$")
    if who then name = who .. " (Host)" end
    return origFarmStartHost(name, ...)
end
