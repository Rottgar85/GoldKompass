-- GoldKompass Sperre: jedes Fenster einzeln sperren.
-- Jedes Fenster bekommt unten links ein kleines Schloss; Klick sperrt oder entsperrt nur dieses Fenster.
-- Gespeichert in opt.locks[schluessel]. Ohne eigenen Eintrag gelten die alten Schalter
-- "Fenster sperren" (opt.lockWindow) und "Farm-Fenster sperren" (opt.lockHud) aus den Einstellungen.
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local LOCK_TEX = "Interface\\PetBattles\\PetBattle-LockIcon"

local function Opt() local db = GK.DB and GK.DB(); return db and db.opt or {} end
local function On() return Opt().oneWindow ~= false end

-- Schluessel -> alter Sammelschalter
local GROUP = {
    nav = "lockWindow", main = "lockWindow", plus = "lockWindow", mehr = "lockWindow", analyse = "lockWindow",
    verkauf = "lockWindow", routen = "lockWindow", intro = "lockWindow", sicherung = "lockWindow", export = "lockWindow",
    hud = "lockHud", beute = "lockHud",
}
local NAMES = {
    nav = "Fenster mit Seitenleiste", main = "Übersicht", plus = "Routen und Ziele", mehr = "Gebiete und Inventar",
    analyse = "Analyse", verkauf = "Verkaufshelfer", routen = "Eigene Route", intro = "Willkommensseite",
    sicherung = "Sicherung", export = "Export", hud = "Farm-Fenster", beute = "Gruppen-Beute",
}
local PAGEKEYS = { main = true, plus = true, mehr = true, analyse = true, verkauf = true, routen = true }

function GK.IsLocked(key)
    local o = Opt()
    if o.locks and o.locks[key] ~= nil then return o.locks[key] end
    local g = GROUP[key]
    return g and o[g] and true or false
end

local buttons = {}
local function Paint(b)
    local locked = GK.IsLocked(b.gkKey)
    b.tex:SetDesaturated(not locked)
    b:SetAlpha(locked and 1 or (b:IsMouseOver() and 0.9 or 0.3))
end
local function RefreshAll()
    for _, b in ipairs(buttons) do
        -- Seiten im Ein-Fenster-Modus bewegen sich mit der Seitenleiste: dort zeigt nur die Leiste ein Schloss
        b:SetShown(not (b.gkPage and On()))
        Paint(b)
    end
end
GK.RefreshLocks = RefreshAll

function GK.SetLocked(key, on)
    local o = Opt()
    o.locks = o.locks or {}
    o.locks[key] = on and true or false
    RefreshAll()
end

-- Sammelschalter aus den Einstellungen: eigene Einstellungen dieser Gruppe verwerfen
function GK.ResetLockGroup(group)
    local o = Opt()
    if not o.locks then return end
    for key, g in pairs(GROUP) do if g == group then o.locks[key] = nil end end
    RefreshAll()
end

local function T(s) return GK.T and GK.T(s) or s end

local function AddButton(f, key, isPage)
    local b = CreateFrame("Button", nil, f)
    b:SetFrameLevel(f:GetFrameLevel() + 20)
    -- Seitenleiste: oben rechts im Kopfband (unten sitzen die Knoepfe), sonst unten links
    if key == "nav" then b:SetSize(12, 12); b:SetPoint("TOPRIGHT", -4, -4) else b:SetSize(14, 14); b:SetPoint("BOTTOMLEFT", 4, 4) end
    b.tex = b:CreateTexture(nil, "ARTWORK"); b.tex:SetAllPoints(); b.tex:SetTexture(LOCK_TEX)
    b.gkKey, b.gkPage = key, isPage
    b:SetScript("OnClick", function(self)
        local on = not GK.IsLocked(self.gkKey)
        GK.SetLocked(self.gkKey, on)
        print("|cffffd100GoldKompass|r: " .. T(NAMES[self.gkKey] or self.gkKey) .. " " .. T(on and "gesperrt." or "verschiebbar."))
    end)
    b:SetScript("OnEnter", function(self)
        Paint(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(T(NAMES[self.gkKey] or self.gkKey))
        GameTooltip:AddLine(T(GK.IsLocked(self.gkKey) and "Gesperrt. Klick: verschiebbar machen" or "Verschiebbar. Klick: an dieser Stelle sperren"), 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self) Paint(self); GameTooltip:Hide() end)
    buttons[#buttons + 1] = b
    return b
end

-- Ziehen nur, wenn das Fenster nicht gesperrt ist. Der vorhandene Zieh-Code bleibt, er wird nur vorgeschaltet.
-- Seiten im Ein-Fenster-Modus folgen der Sperre der Seitenleiste.
local function Guard(f, key, isPage)
    local cur = f:GetScript("OnDragStart")
    if cur and cur ~= f.gkLockWrap then
        local orig = cur
        f.gkLockWrap = function(self, ...)
            local k = (isPage and On()) and "nav" or key
            if GK.IsLocked(k) then return end
            return orig(self, ...)
        end
        f:SetScript("OnDragStart", f.gkLockWrap)
    end
end

function GK.Lockable(f, key)
    if not f then return end
    local isPage = PAGEKEYS[key] or false
    Guard(f, key, isPage)
    if not f.gkLockBtn then
        f.gkLockBtn = AddButton(f, key, isPage)
        -- falls ein anderer Teil das Ziehen spaeter neu setzt: beim Zeigen wieder vorschalten
        f:HookScript("OnShow", function(self) Guard(self, key, isPage); RefreshAll() end)
    end
    RefreshAll()
end

-- Anmelden -------------------------------------------------------------------------------------------------------
local PAGEFRAMES = {
    main = function() return GK.frame end, plus = function() return GK.plus end, mehr = function() return GK.mehr end,
    analyse = function() return _G.GoldKompassAnalyseFrame end, verkauf = function() return _G.GoldKompassSellFrame end,
    routen = function() return _G.GoldKompassRouteEditor end,
}
local OTHER = {
    hud = function() return GK.hud end, beute = function() return GK.beuteHud end,
    intro = function() return _G.GoldKompassIntroFrame end, sicherung = function() return _G.GoldKompassTransfer end,
    export = function() return _G.GoldKompassExport end,
}
local function AttachAll()
    if GK.nav then GK.Lockable(GK.nav, "nav") end
    for key, get in pairs(PAGEFRAMES) do local f = get(); if f then GK.Lockable(f, key) end end
    for key, get in pairs(OTHER) do local f = get(); if f then GK.Lockable(f, key) end end
end

for _, fn in ipairs({ "Build", "BuildPlus", "BuildMehr", "OpenAnalyse", "SellHelper", "OpenRouteEditor",
    "BuildHud", "BeuteShow", "ShowIntro", "OpenTransfer", "ShowExport", "OpenPage" }) do
    if type(GK[fn]) == "function" then hooksecurefunc(GK, fn, function() pcall(AttachAll) end) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function() pcall(AttachAll) end)

-- Ein-Fenster-Modus umgeschaltet: Schloesser der Seiten ein- oder ausblenden
if type(GK.SetOneWindow) == "function" then hooksecurefunc(GK, "SetOneWindow", function() RefreshAll() end) end
