-- GoldKompass Optik: Symbole aus dem Spiel statt eigener Bilder.
-- Logo im Fenster, Rand am Minimap-Button und Symbole vor den Quellen im Reiter "Heute".
-- Passt zum schlanken Hauptfenster aus Kompakt.lua (Zeilen sind Frames mit r.l / r.r).
-- Alles in pcall: ein Fehler hier darf das Addon nie stoeren.
local GK = GoldKompass
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}
local ICON = "Interface\\Icons\\"
local LOGO = GK.LOGO or (ICON .. "INV_Misc_Coin_02")

-- Quelle (deutsch und englisch) -> Symbol
local SOURCES = {
    ["Haendler"] = "INV_Misc_Coin_01", ["Merchant"] = "INV_Misc_Coin_01", ["Vendor"] = "INV_Misc_Coin_01",
    ["Auktionshaus"] = "INV_Misc_Coin_03", ["Auction House"] = "INV_Misc_Coin_03",
    ["Auktionshaus-Verkauf"] = "INV_Misc_Coin_17", ["Auction sales"] = "INV_Misc_Coin_17",
    ["Kriegsmeute-Bank"] = "INV_Misc_Bag_10", ["Warband bank"] = "INV_Misc_Bag_10",
    ["Post"] = "INV_Letter_15", ["Mail"] = "INV_Letter_15",
    ["Handel"] = "INV_Misc_Note_01", ["Trade"] = "INV_Misc_Note_01",
    ["Quests"] = "INV_Misc_Book_09",
    ["Looten / Sonstiges"] = "INV_Misc_Bag_08", ["Loot / Other"] = "INV_Misc_Bag_08",
}

local function Theme()
    local db = GK.DB and GK.DB()
    return COLORS[db and db.opt and db.opt.theme or "gold"] or COLORS.gold
end

-- Titel-Schrift des Hauptfensters finden (Kompakt.lua merkt sie sich nicht)
local function TitleOf(f)
    for i = 1, select("#", f:GetRegions()) do
        local r = select(i, f:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" and r:GetText() == "GoldKompass" then return r end
    end
end

-- Symbol vor die Quellen-Zeilen im Reiter "Heute" setzen ("   Quests" -> "   [Symbol] Quests")
local function DecorateRows(f)
    local busy
    for _, row in ipairs(f.rows or {}) do
        local fs = row.l
        if fs and not fs.gkHooked then
            fs.gkHooked = true
            hooksecurefunc(fs, "SetText", function(self, text)
                if busy or GK.tab ~= "heute" or type(text) ~= "string" then return end
                local lead, rest = text:match("^(%s%s%s)(.*)$")
                if not lead then return end
                for name, ico in pairs(SOURCES) do
                    if rest == name then
                        busy = true
                        self:SetText(lead .. "|T" .. ICON .. ico .. ":14|t " .. rest)
                        busy = false
                        return
                    end
                end
            end)
        end
    end
end

local function Decorate()
    local f = GK.frame
    if f and not f.gkLogo then
        local title = TitleOf(f)
        if title then
            f.gkLogo = true
            local t = f:CreateTexture(nil, "OVERLAY")
            t:SetSize(18, 18); t:SetTexture(LOGO)
            t:SetPoint("TOPLEFT", 9, -4)
            title:ClearAllPoints(); title:SetPoint("TOPLEFT", 32, -9)
            -- Farblinie unter der Kopfleiste (folgt dem Design aus den Optionen)
            local line = f:CreateTexture(nil, "ARTWORK")
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", 1, -25); line:SetPoint("TOPRIGHT", -1, -25)
            f.gkLine = line
            DecorateRows(f)
        end
    end
    local mb = _G.GoldKompassMinimapButton
    if mb and not mb.gkBorder then
        mb.gkBorder = true
        local bg = mb:CreateTexture(nil, "BACKGROUND")
        bg:SetSize(22, 22); bg:SetPoint("CENTER", 0, 0)
        bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
        local ring = mb:CreateTexture(nil, "OVERLAY")
        ring:SetSize(54, 54); ring:SetPoint("TOPLEFT", 0, 0)
        ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        local nt = mb:GetNormalTexture()
        if nt then
            nt:ClearAllPoints(); nt:SetSize(20, 20); nt:SetPoint("CENTER", 0, 1)
        end
    end
    if f and f.gkLine then
        local c = Theme()
        f.gkLine:SetColorTexture(c[1], c[2], c[3], 0.9)
    end
end

-- Schmuecken, sobald Hauptfenster und Minimap-Button da sind; danach haelt der Haken an UpdateBar
-- (Wochenleiste, alle 2 Sekunden) nur noch die Linienfarbe passend zum Design.
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    local ticker
    ticker = C_Timer.NewTicker(2, function()
        pcall(Decorate)
        local f, mb = GK.frame, _G.GoldKompassMinimapButton
        if f and f.gkLogo and mb and mb.gkBorder then ticker:Cancel() end
    end)
    if type(GK.UpdateBar) == "function" then hooksecurefunc(GK, "UpdateBar", function() pcall(Decorate) end) end
end)
