-- GoldKompass PlusOptik: lesbareres Plus-Fenster (groessere Schrift, mehr Platz, Zebrastreifen).
-- Aendert nur das Aussehen nach dem Bauen des Fensters. Bei einem Fehler bleibt das alte Aussehen.
local GK = GoldKompass

local W, H = 540, 452
local ROW_H, ROW_TOP = 24, 86

local function Restyle(f)
    if not f or f.gkRestyled then return end
    f.gkRestyled = true

    f:SetSize(W, H)

    -- Titel groesser, goldene Linie darunter
    for i = 1, select("#", f:GetRegions()) do
        local r = select(i, f:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" and r:GetText() == "GoldKompass · Plus" then
            r:SetFontObject("GameFontNormalLarge")
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 12, -8)
        end
    end

    -- Reiter: breiter und groessere Schrift
    local names, n = {}, 0
    for k in pairs(f.tabs or {}) do n = n + 1 end
    local order = { "routen", "ziele", "mats", "preise", "rueck" }
    local tw = (W - 20) / math.max(n, 1)
    for i, k in ipairs(order) do
        local b = f.tabs and f.tabs[k]
        if b then
            b:SetSize(tw, 24); b:ClearAllPoints(); b:SetPoint("TOPLEFT", 10 + (i - 1) * tw, -32)
            b.text:SetFontObject("GameFontNormal")
        end
    end

    -- Trennlinie tiefer
    for i = 1, select("#", f:GetRegions()) do
        local r = select(i, f:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "Texture" and r:GetHeight() == 1 then
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", 10, -58); r:SetPoint("TOPRIGHT", -10, -58)
        end
    end

    -- Eingabe- und Knopfzeile unter den Reitern etwas tiefer
    for _, list in pairs(f.bits or {}) do
        for _, w in ipairs(list) do
            local p, rel, rp, x, y = w:GetPoint(1)
            if p == "TOPLEFT" and rel == f and y and y > -70 then
                w:ClearAllPoints(); w:SetPoint(p, rel, rp, x, y - 8)
            end
        end
    end

    -- Zeilen: hoeher, groessere Schrift, Zebrastreifen
    for i, r in ipairs(f.rows or {}) do
        r:SetHeight(ROW_H - 2)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 10, -ROW_TOP - (i - 1) * ROW_H)
        r:SetPoint("TOPRIGHT", -10, -ROW_TOP - (i - 1) * ROW_H)
        if r.l then r.l:SetFontObject("GameFontHighlight") end
        if r.r then r.r:SetFontObject("GameFontHighlight") end
        if i % 2 == 0 and not r.gkZebra then
            r.gkZebra = r:CreateTexture(nil, "BACKGROUND", nil, -2)
            r.gkZebra:SetAllPoints(); r.gkZebra:SetColorTexture(1, 1, 1, 0.04)
        end
    end
end

local origBuild = GK.BuildPlus
if type(origBuild) == "function" then
    function GK.BuildPlus(...)
        origBuild(...)
        pcall(Restyle, GK.plus)
        if GK.ApplyTheme then pcall(GK.ApplyTheme) end
    end
end
