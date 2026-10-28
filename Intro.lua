-- GoldKompass Intro: Willkommensseite beim ersten Oeffnen des Fensters.
-- Erklaert, was das Addon macht. Mit "Verstanden" kommt sie nicht wieder; /gk hilfe zeigt sie erneut.
-- Eigenes Fenster, haengt an keiner anderen Datei. Bei Fehlern bleibt das Addon unberuehrt.
local GK = GoldKompass
local GOLD = "|cffffd100"

local TEXT = {
    GOLD .. "Was GoldKompass macht|r",
    "Es zeichnet auf, woher dein Gold kommt und wohin es geht, und rechnet aus, wie viel du pro Stunde verdienst.",
    " ",
    GOLD .. "Die Reiter im Fenster|r",
    "|cffffffffHeute|r  Einnahmen, Ausgaben, Saldo und die wichtigsten Quellen",
    "|cffffffffWoche|r  Wochenziel setzen und den Verlauf der letzten 7 Tage sehen",
    "|cffffffffFarm|r  Sessions starten und stoppen, Gold pro Stunde, beste Gebiete",
    "|cffffffffBeute|r  Wert deiner Taschen, wertvollste Stapel, teuerste Funde",
    "|cffffffffChars|r  Gold und Wochenertrag aller deiner Charaktere",
    "|cffffffffGruppe|r  Farm mit Mitspielern vergleichen (alle brauchen GoldKompass)",
    " ",
    GOLD .. "Dazu gibt es|r",
    "Gold-Verlauf, Items pro Stunde, Preisalarm, Schnaeppchen-Alarm, Verkaufshelfer,",
    "Gilden-Wochenziel, Wochenbericht und Routes-Anbindung. Die Kriegsmeute-Bank zaehlt mit.",
    "Preise kommen von Auctionator oder TSM, ohne beide gilt der Haendlerpreis.",
    " ",
    GOLD .. "Wichtige Befehle|r",
    "/gk  Fenster auf und zu      /gk optionen  Einstellungen",
    "/gk start  und  /gk stop  Farm-Session      /gk verlauf  Gold-Verlauf",
    "/gk befehle  alle Befehle      /gk hilfe  diese Seite noch einmal",
    "Auch im Addon-Menue an der Minimap und unter Esc > Optionen > AddOns.",
}

local frame

local function Build()
    if frame then return frame end
    local f = CreateFrame("Frame", "GoldKompassIntroFrame", UIParent, "BackdropTemplate")
    f:SetSize(540, 470); f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.97); f:SetBackdropBorderColor(1, 0.82, 0, 1)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local logo = f:CreateTexture(nil, "OVERLAY")
    logo:SetSize(28, 28); logo:SetPoint("TOPLEFT", 14, -12)
    logo:SetTexture(GK.LOGO or "Interface\\Icons\\INV_Misc_Coin_02")
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 10, 0); title:SetText("Willkommen bei GoldKompass")

    local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 18, -56); body:SetWidth(504); body:SetJustifyH("LEFT"); body:SetSpacing(3)
    body:SetText(table.concat(TEXT, "\n"))

    local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ok:SetSize(120, 24); ok:SetPoint("BOTTOM", 0, 14); ok:SetText("Verstanden")
    ok:SetScript("OnClick", function()
        local DB = GK.DB and GK.DB()
        if DB then DB.introSeen = true end
        f:Hide()
    end)
    f:Hide()
    frame = f
    return f
end

function GK.ShowIntro()
    local ok, f = pcall(Build)
    if ok and f then f:Show() end
end

-- Beim ersten Oeffnen des Hauptfensters die Seite zeigen (Haken am Fenster statt Dauer-Takt)
local function OnMainShow()
    local DB = GK.DB and GK.DB()
    if DB and not DB.introSeen and not (frame and frame:IsShown()) then GK.ShowIntro() end
end
local origBuild = GK.Build
function GK.Build(...)
    origBuild(...)
    local m = GK.frame
    if m and not m.gkIntroHook then
        m.gkIntroHook = true
        m:HookScript("OnShow", OnMainShow)
        if m:IsShown() then OnMainShow() end
    end
end

-- /gk hilfe
GK.RegisterCommand({ "hilfe", "help", "intro" }, function() GK.ShowIntro() end, "Willkommensseite mit Erklärung")
