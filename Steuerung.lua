-- GoldKompass Steuerung: schmale Start/Stopp-Leiste, haengt unten am Hauptfenster und geht mit ihm auf und zu.
-- Aus- und einblenden mit /gk leiste.
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}

local bar
local function Build()
    if bar then return end
    GK.Build()
    local p = GK.frame
    local b = CreateFrame("Frame", "GoldKompassFarmControl", p, "BackdropTemplate")
    b:SetHeight(32)
    b:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 0, 2)
    b:SetPoint("TOPRIGHT", p, "BOTTOMRIGHT", 0, 2)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    b:SetBackdropColor(0.05, 0.05, 0.08, 0.94)

    b.start = CreateFrame("Button", nil, b, "UIPanelButtonTemplate")
    b.start:SetSize(64, 20); b.start:SetText("Start"); b.start:SetPoint("LEFT", 10, 0)
    b.start:SetScript("OnClick", function() GK.FarmStart(); GK.UpdateControl() end)
    b.stop = CreateFrame("Button", nil, b, "UIPanelButtonTemplate")
    b.stop:SetSize(64, 20); b.stop:SetText("Stopp"); b.stop:SetPoint("LEFT", b.start, "RIGHT", 4, 0)
    b.stop:SetScript("OnClick", function() GK.FarmStop(); GK.UpdateControl() end)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b.stop, "RIGHT", 12, 0); b.text:SetPoint("RIGHT", -10, 0)
    b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false)
    b:SetScript("OnUpdate", function(self, e)
        self.t = (self.t or 0) + e
        if self.t >= 1 then self.t = 0; GK.UpdateControl() end
    end)
    bar = b
end

function GK.UpdateControl()
    local db = GK.DB and GK.DB()
    if not db then return end
    if db.opt.ctlBar == false then if bar then bar:Hide() end; return end
    Build()
    bar:Show()
    local c = COLORS[db.opt.theme or "gold"] or COLORS.gold
    bar:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    local fm = GK.farm
    bar.start:SetEnabled(not fm); bar.stop:SetEnabled(fm and true or false)
    if fm then
        local secs = GetTime() - fm.start
        local total = fm.money + fm.value - (fm.costs or 0)
        bar.text:SetText(string.format("%s  %d:%02d  %s/h", fm.name, floor(secs / 60), floor(secs % 60),
            GK.FmtGold(secs > 30 and total / secs * 3600 or 0)))
    else
        bar.text:SetText("Keine Farm-Session aktiv")
    end
end

GK.RegisterCommand("leiste", function()
    local o = GK.DB().opt
    o.ctlBar = (o.ctlBar == false)
    GK.UpdateControl()
    print("|cffffd100GoldKompass|r: Start/Stopp-Leiste " .. (o.ctlBar and "an" or "aus") .. ".")
end, "Start/Stopp-Leiste unter dem Fenster an/aus")

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    C_Timer.After(1, GK.UpdateControl)
end)
