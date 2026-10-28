-- GoldKompass Stil: einheitliches Aussehen und stimmige Anordnung aller Fenster.
-- Aendert nur Optik und Position nach dem Bauen. Bei einem Fehler bleibt das alte Aussehen.
local GK = GoldKompass

local function Header(f, big)
    if not f or f.gkHeader then return end
    if f.SetBackdropColor then f:SetBackdropColor(0.04, 0.04, 0.07, 0.97) end
    local h = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    h:SetPoint("TOPLEFT", 1, -1); h:SetPoint("TOPRIGHT", -1, -1)
    h:SetHeight(big and 30 or 24)
    h:SetColorTexture(0.16, 0.13, 0.03, 0.9)
    f.gkHeader = h
    local l = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    l:SetPoint("TOPLEFT", h, "BOTTOMLEFT"); l:SetPoint("TOPRIGHT", h, "BOTTOMRIGHT")
    l:SetHeight(1); l:SetColorTexture(1, 0.82, 0, 0.5)
end

local function BigFonts(f)
    for i = 1, select("#", f:GetRegions()) do
        local r = select(i, f:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
            local t = r:GetText() or ""
            if t:find("^GoldKompass") then r:SetFontObject("GameFontNormalLarge"); r:ClearAllPoints(); r:SetPoint("TOPLEFT", 12, -7)
            else r:SetFontObject("GameFontHighlight") end
        end
    end
end

-- Routen-Fenster: groesser, gleiche Schrift wie Plus, haengt rechts am Plus- oder Hauptfenster
local function Editor()
    local f = _G.GoldKompassRouteEditor
    if not f then return end
    if not f.gkStyled then
        f.gkStyled = true
        f:SetSize(380, 380)
        Header(f, true)
        BigFonts(f)
        for _, r in ipairs(f.rows or {}) do
            if r.text then r.text:SetFontObject("GameFontHighlight") end
            r:SetHeight(19)
        end
        f:HookScript("OnShow", function(self) GK.DockEditor(self) end)
    end
    GK.DockEditor(f)
end

function GK.DockEditor(f)
    local anchor
    if GK.plus and GK.plus:IsShown() then anchor = GK.plus
    elseif GK.frame and GK.frame:IsShown() then anchor = GK.frame end
    if anchor then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0)
    end
end

local origOpen = GK.OpenRouteEditor
if origOpen then
    function GK.OpenRouteEditor(...)
        origOpen(...)
        pcall(Editor)
    end
end

-- Hauptfenster und Plus-Fenster: gleiche Kopfleiste
local origBuild = GK.Build
if origBuild then
    function GK.Build(...)
        origBuild(...)
        pcall(Header, GK.frame, false)
    end
end
local origPlus = GK.BuildPlus
if origPlus then
    function GK.BuildPlus(...)
        origPlus(...)
        pcall(Header, GK.plus, true)
    end
end

-- Optionsfenster: gleiche Kopfleiste, wenn es geoeffnet wird
local origOpts = GK.BuildOptions
if origOpts then
    function GK.BuildOptions(...)
        origOpts(...)
        pcall(Header, GK.optFrame, true)
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    C_Timer.After(1, function()
        pcall(Header, GK.frame, false)
        pcall(Header, GK.plus, true)
        pcall(Header, GK.optFrame, true)
    end)
end)

-- Plus-Fenster: Knopfleiste oben rechts ordnen (Mehr direkt am Schliessen-X, "Eigene Route" links daneben)
local function FixPlusButtons()
    local p = GK.plus
    if not p then return end
    local mehr, route = p.mehrBtn, p.newRoute
    if mehr then
        mehr:SetSize(56, 20); mehr:ClearAllPoints(); mehr:SetPoint("TOPRIGHT", p, "TOPRIGHT", -30, -5)
    end
    if route then
        route:SetSize(104, 20); route:ClearAllPoints()
        if mehr then route:SetPoint("RIGHT", mehr, "LEFT", -4, 0) else route:SetPoint("TOPRIGHT", p, "TOPRIGHT", -30, -5) end
    end
end
local origPlus2 = GK.BuildPlus
function GK.BuildPlus(...)
    origPlus2(...)
    pcall(FixPlusButtons)
end

-- Mehr-Fenster: gleiche Groesse, Schrift, Reiter und Zeilen wie das Plus-Fenster, rechts am Plus-Fenster angedockt
local MW, MH, MROW_H, MROW_TOP = 540, 452, 24, 86

local function RestyleMehr(f)
    if not f or f.gkRestyled then return end
    f.gkRestyled = true
    f:SetSize(MW, MH)
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        f:SetBackdropColor(0.04, 0.04, 0.07, 1)
    end
    -- feste, undurchsichtige Flaeche unter allem, unabhaengig vom Backdrop
    f:SetAlpha(1)
    f:SetFrameStrata("DIALOG")
    local solid = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    solid:SetPoint("TOPLEFT", 1, -1); solid:SetPoint("BOTTOMRIGHT", -1, 1)
    solid:SetColorTexture(0.04, 0.04, 0.07, 1)
    f.gkSolid = solid
    Header(f, true)
    for i = 1, select("#", f:GetRegions()) do
        local r = select(i, f:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" and (r:GetText() or ""):find("^GoldKompass") then
            r:SetFontObject("GameFontNormalLarge"); r:ClearAllPoints(); r:SetPoint("TOPLEFT", 12, -8)
        end
    end
    local order = { "gebiete", "schnaeppchen", "inventar", "export" }
    local tw = (MW - 20) / #order
    for i, k in ipairs(order) do
        local b = f.tabs and f.tabs[k]
        if b then
            b:SetSize(tw, 24); b:ClearAllPoints(); b:SetPoint("TOPLEFT", 10 + (i - 1) * tw, -32)
            b.text:SetFontObject("GameFontNormal")
        end
    end
    for i = 1, select("#", f:GetRegions()) do
        local r = select(i, f:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "Texture" and r:GetHeight() == 1 and r ~= f.gkHeader then
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 10, -58); r:SetPoint("TOPRIGHT", -10, -58)
        end
    end
    for _, list in pairs(f.bits or {}) do
        for _, w in ipairs(list) do
            local p, rel, rp, x, y = w:GetPoint(1)
            if p == "TOPLEFT" and rel == f and y and y > -70 then
                w:ClearAllPoints(); w:SetPoint(p, rel, rp, x, y - 8)
            end
        end
    end
    for i, r in ipairs(f.rows or {}) do
        r:SetHeight(MROW_H - 2)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 10, -MROW_TOP - (i - 1) * MROW_H)
        r:SetPoint("TOPRIGHT", -10, -MROW_TOP - (i - 1) * MROW_H)
        if r.l then r.l:SetFontObject("GameFontHighlight") end
        if r.r then r.r:SetFontObject("GameFontHighlight") end
        if i % 2 == 0 then
            local z = r:CreateTexture(nil, "BACKGROUND", nil, -2)
            z:SetAllPoints(); z:SetColorTexture(1, 1, 1, 0.04)
        end
    end
    if f.exportBox then f.exportBox:SetWidth(MW - 60) end
    f:HookScript("OnShow", function(self) self:SetAlpha(1); GK.DockMehr(self) end)
end

function GK.DockMehr(f)
    local anchor
    if GK.plus and GK.plus:IsShown() then anchor = GK.plus
    elseif GK.frame and GK.frame:IsShown() then anchor = GK.frame end
    if anchor then f:ClearAllPoints(); f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0) end
end

-- Routen-Fenster dockt am Mehr-Fenster, wenn es offen ist, sonst wie bisher
function GK.DockEditor(f)
    local anchor
    if GK.mehr and GK.mehr:IsShown() then anchor = GK.mehr
    elseif GK.plus and GK.plus:IsShown() then anchor = GK.plus
    elseif GK.frame and GK.frame:IsShown() then anchor = GK.frame end
    if anchor then f:ClearAllPoints(); f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 6, 0) end
end

local origMehr = GK.BuildMehr
if origMehr then
    function GK.BuildMehr(...)
        origMehr(...)
        pcall(RestyleMehr, GK.mehr)
    end
end

-- Hauptfenster schliessen schliesst auch das Mehr-Fenster
local mainEv = CreateFrame("Frame")
mainEv:RegisterEvent("PLAYER_LOGIN")
mainEv:SetScript("OnEvent", function()
    C_Timer.After(2, function()
        local m = GK.frame
        if m and not m.gkMehrHook then
            m.gkMehrHook = true
            m:HookScript("OnHide", function()
                if GK.navSwitching then return end -- Seitenwechsel im Ein-Fenster-Modus (Fenster.lua)
                if GK.mehr and GK.mehr:IsShown() then GK.mehr:Hide() end
            end)
        end
    end)
end)

-- Kleines Farm-Fenster: feine Linie zwischen Rohgold/Items-Zeile und der Item-Liste darunter
local function StyleHud(h)
    if not h or h.gkLine then return end
    local LINE_Y, SHIFT = -47, 6
    local line = h:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.35); line:SetHeight(1)
    line:SetPoint("TOPLEFT", 8, LINE_Y); line:SetPoint("TOPRIGHT", -8, LINE_Y)
    h.gkLine = line
    h:SetHeight(h:GetHeight() + SHIFT)
    for i, r in ipairs(h.rows or {}) do
        local y = -44 - SHIFT - (i - 1) * 14
        r.val:ClearAllPoints(); r.val:SetPoint("TOPRIGHT", -8, y)
        r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", 8, y); r.name:SetPoint("RIGHT", r.val, "LEFT", -4, 0)
    end
end

local origHud = GK.BuildHud
if origHud then
    function GK.BuildHud(...)
        origHud(...)
        pcall(StyleHud, GK.hud)
    end
end
