-- GoldKompass Rahmen: Rahmen aller Fenster in voller Designfarbe, 2 Pixel breit.
-- Läuft nach Plus.lua und überschreibt dessen gedämpften Rand.
local GK = GoldKompass
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}

local function Edge(fr, c)
    if not (fr and fr.SetBackdropBorderColor and fr.GetBackdrop) then return end
    if fr.gkEdge ~= 2 then
        local bd = fr:GetBackdrop()
        if not bd then return end
        local r, g, b, a = fr:GetBackdropColor()
        bd.edgeSize = 2
        fr:SetBackdrop(bd)
        if r then fr:SetBackdropColor(r, g, b, a) end
        fr.gkEdge = 2
    end
    fr:SetBackdropBorderColor(c[1], c[2], c[3], 1)
end

local function Fix()
    local db = GK.DB and GK.DB()
    if not db then return end
    local c = COLORS[db.opt.theme or "gold"] or COLORS.gold
    Edge(GK.frame, c); Edge(GK.optFrame, c); Edge(GK.plus, c); Edge(GK.hud, c)
    Edge(_G.GoldKompassWeekBar, c)
end
GK.FixEdge = Fix

for _, name in ipairs({ "Refresh", "UpdateBar", "RefreshHud", "BuildPlus", "BuildOptions", "RefreshPlus" }) do
    if type(GK[name]) == "function" then pcall(hooksecurefunc, GK, name, Fix) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    -- Kein eigener Takt noetig: Fix haengt an UpdateBar, das die Wochenleiste ohnehin alle 2 Sekunden aufruft
    -- (faengt so auch den Designwechsel im Dropdown ab)
    C_Timer.After(3, Fix)
end)
