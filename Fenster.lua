-- GoldKompass Fenster: ein Fenster mit Seitenleiste statt vieler einzelner Fenster.
-- Die bisherigen Fenster (Uebersicht, Plus, Mehr, Analyse, Verkauf, Eigene Route) bleiben erhalten und werden zu
-- Seiten: sie erscheinen rechts an der Seitenleiste, immer nur eine zur Zeit, und das Ganze wird an der Leiste verschoben.
-- Dazu: Groesse von Fenster und Farm-Fenster, Position sperren, im Kampf automatisch ausblenden.
-- Abschaltbar in den Einstellungen (opt.oneWindow); dann verhalten sich die Fenster wie frueher.
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local WHITE = "Interface\\Buttons\\WHITE8x8"
local ICONS = "Interface\\Icons\\"
local NAV_W, BTN_H = 150, 26
local COLORS = {
    gold = { 1, 0.82, 0 }, blau = { 0.35, 0.65, 1 }, gruen = { 0.4, 0.9, 0.5 },
    violett = { 0.75, 0.45, 1 }, rot = { 1, 0.4, 0.4 },
}
local function DB() return GK.DB and GK.DB() end
local function Opt() local db = DB(); return db and db.opt or {} end
local function On() return Opt().oneWindow ~= false end
local function Theme() return COLORS[Opt().theme or "gold"] or COLORS.gold end

-- Seiten: Schluessel, Beschriftung, Symbol, wie man an den Rahmen kommt und wie man die Seite oeffnet
local PAGES = {
    { key = "main", label = "Übersicht", icon = "INV_Misc_Coin_01",
      frame = function() return GK.frame end, open = function() GK.Build(); GK.frame:Show() end },
    { key = "plus", label = "Routen und Ziele", icon = "INV_Misc_Map_01",
      frame = function() return GK.plus end, open = function() GK.OpenPlus() end },
    { key = "mehr", label = "Gebiete und Inventar", icon = "INV_Misc_Spyglass_03",
      frame = function() return GK.mehr end, open = function() GK.OpenMehr() end },
    { key = "analyse", label = "Analyse", icon = "INV_Misc_Note_06",
      frame = function() return _G.GoldKompassAnalyseFrame end, open = function() GK.OpenAnalyse() end },
    { key = "verkauf", label = "Verkaufshelfer", icon = "INV_Misc_Coin_03",
      frame = function() return _G.GoldKompassSellFrame end, open = function() GK.SellHelper("open") end },
    { key = "routen", label = "Eigene Route", icon = "INV_Misc_Map02",
      frame = function() return _G.GoldKompassRouteEditor end, open = function() GK.OpenRouteEditor() end },
}
local BYKEY = {}
for _, p in ipairs(PAGES) do BYKEY[p.key] = p end

local current, lastKey = nil, "main"
local HideSidePages -- weiter unten belegt, wird schon vom Optionen-Knopf gebraucht

-- Fensterpositionen merken (ueberleben /reload und Neustart) ---------------------------------------------------
-- Gespeichert wird die linke obere Ecke in Bildschirm-Einheiten (DB.positions[schluessel]); so stimmt die Position
-- auch, wenn die Fenstergroesse spaeter geaendert wird.
local function SavePos(f, key)
    local db = DB()
    if not db or not f or not f:GetLeft() then return end
    local s = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    db.positions = db.positions or {}
    db.positions[key] = { x = f:GetLeft() * s, y = f:GetTop() * s }
end
local function HasPos(key)
    local db = DB()
    return db and db.positions and db.positions[key] ~= nil
end
local function RestorePos(f, key)
    local db = DB()
    local pos = db and db.positions and db.positions[key]
    if not pos or not f then return false end
    local s = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x / s, pos.y / s)
    return true
end
GK.SavePos, GK.RestorePos, GK.HasPos = SavePos, RestorePos, HasPos

-- Fuer Fenster mit eigenem Ziehen: nach dem Loslassen speichern, beim Zeigen wiederherstellen
function GK.RememberFrame(f, key)
    if not f or f.gkPosKey then return end
    f.gkPosKey = key
    f:HookScript("OnDragStop", function(self) SavePos(self, key) end)
    f:HookScript("OnShow", function(self) RestorePos(self, key) end)
    if f:IsShown() then RestorePos(f, key) end
end

-- Seitenleiste -------------------------------------------------------------------------------------------------
local nav = CreateFrame("Frame", "GoldKompassNav", UIParent, "BackdropTemplate")
nav:SetSize(NAV_W, 380)
nav:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 2 })
nav:SetBackdropColor(0.04, 0.04, 0.07, 0.97)
nav:SetMovable(true); nav:EnableMouse(true); nav:RegisterForDrag("LeftButton"); nav:SetClampedToScreen(true)
if nav.SetDontSavePosition then nav:SetDontSavePosition(true) end -- Position speichert GoldKompass selbst (DB.navPos)
nav:SetFrameStrata("MEDIUM")
nav:Hide()
tinsert(UISpecialFrames, "GoldKompassNav")
GK.nav = nav

local function StartMove()
    if not Opt().lockWindow then nav:StartMoving() end
end
local function StopMove()
    nav:StopMovingOrSizing()
    if GK.SavePos then GK.SavePos(nav, "nav") end
end
nav:SetScript("OnDragStart", StartMove)
nav:SetScript("OnDragStop", StopMove)

local band = nav:CreateTexture(nil, "BACKGROUND", nil, 1)
band:SetPoint("TOPLEFT", 2, -2); band:SetPoint("TOPRIGHT", -2, -2); band:SetHeight(40)
band:SetColorTexture(0.16, 0.13, 0.03, 0.9)
local logo = nav:CreateTexture(nil, "ARTWORK")
logo:SetSize(30, 30); logo:SetPoint("TOPLEFT", 8, -7); logo:SetTexture(GK.LOGO)
local title = nav:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("LEFT", logo, "RIGHT", 6, 0); title:SetText("GoldKompass")

nav.buttons = {}
for i, p in ipairs(PAGES) do
    local b = CreateFrame("Button", nil, nav)
    b:SetSize(NAV_W - 8, BTN_H); b:SetPoint("TOPLEFT", 4, -48 - (i - 1) * (BTN_H + 2))
    b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetColorTexture(0.16, 0.13, 0.03, 0.9); b.bg:Hide()
    b.accent = b:CreateTexture(nil, "ARTWORK"); b.accent:SetWidth(3)
    b.accent:SetPoint("TOPLEFT"); b.accent:SetPoint("BOTTOMLEFT"); b.accent:Hide()
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(18, 18); b.icon:SetPoint("LEFT", 8, 0)
    b.icon:SetTexture(ICONS .. p.icon); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0); b.text:SetPoint("RIGHT", -4, 0)
    b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false); b.text:SetText(p.label)
    b:SetScript("OnClick", function() GK.OpenPage(p.key) end)
    nav.buttons[p.key] = b
end

local function SmallBtn(text, onClick)
    local b = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    b:SetSize(NAV_W - 16, 20); b:SetText(text); b:SetScript("OnClick", onClick)
    return b
end
local closeBtn = SmallBtn("Schließen", function() nav:Hide() end)
closeBtn:SetPoint("BOTTOM", 0, 8)
local setBtn = SmallBtn("Einstellungen", function() if GK.OpenSettings then GK.OpenSettings() end end)
setBtn:SetPoint("BOTTOM", closeBtn, "TOP", 0, 4)
local optBtn = SmallBtn("Optionen", function()
    if not (GK.frame and GK.frame:IsShown()) then GK.OpenPage("main") end
    -- Optionen erscheinen rechts an der Uebersicht, am selben Platz wie die anderen Seiten
    if On() then HideSidePages(); current = "main"; Paint() end
    GK.ToggleOptions()
end)
optBtn:SetPoint("BOTTOM", setBtn, "TOP", 0, 4)

-- Sprache wechseln: Automatisch -> Deutsch -> English -> Automatisch
local LANG_NEXT = { auto = "de", de = "en", en = "auto" }
local LANG_LABEL = { auto = "Sprache: Automatisch", de = "Sprache: Deutsch", en = "Sprache: English" }
local langBtn = SmallBtn("", function()
    local cur = GK.GetLanguageSetting and GK.GetLanguageSetting() or "auto"
    if GK.SetLanguage then GK.SetLanguage(LANG_NEXT[cur] or "auto") end
end)
langBtn:SetPoint("BOTTOM", optBtn, "TOP", 0, 4)
local function RefreshLangBtn()
    local cur = GK.GetLanguageSetting and GK.GetLanguageSetting() or "auto"
    local text = LANG_LABEL[cur] or LANG_LABEL.auto
    langBtn:SetText(GK.T and GK.T(text) or text)
end
local prevRefreshLang = GK.RefreshLanguageUI
GK.RefreshLanguageUI = function()
    RefreshLangBtn()
    if prevRefreshLang then prevRefreshLang() end
end
nav:HookScript("OnShow", RefreshLangBtn)

local function Paint()
    local c = Theme()
    nav:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    for key, b in pairs(nav.buttons) do
        local on = key == current
        b.bg:SetShown(on); b.accent:SetShown(on); b.accent:SetColorTexture(c[1], c[2], c[3], 1)
        if on then b.text:SetTextColor(c[1], c[2], c[3]) else b.text:SetTextColor(0.85, 0.85, 0.85) end
        b.icon:SetDesaturated(not on)
    end
end

-- Seiten an- und abmelden ------------------------------------------------------------------------------------------
-- Die Uebersicht sitzt immer an der Seitenleiste, jede andere Seite rechts neben der Uebersicht
local function Place(f)
    f:ClearAllPoints()
    if f == GK.frame or not GK.frame then
        f:SetPoint("TOPLEFT", nav, "TOPRIGHT", -2, 0)
    else
        f:SetPoint("TOPLEFT", GK.frame, "TOPRIGHT", 4, 0)
    end
    nav:SetHeight(math.max(GK.frame and GK.frame:GetHeight() or f:GetHeight(), 48 + #PAGES * (BTN_H + 2) + 110))
end

-- Andere Seiten als die Uebersicht schliessen (ohne dass die Seitenleiste mitgeht)
HideSidePages = function(except)
    GK.navSwitching = true
    for _, o in ipairs(PAGES) do
        local of = o.frame()
        if o.key ~= "main" and o.key ~= except and of and of:IsShown() then of:Hide() end
    end
    GK.navSwitching = false
end

local function Shown(key)
    if not On() then return end
    local p = BYKEY[key]
    local f = p and p.frame()
    if not f then return end
    if key == "main" then
        if not current then current = "main" end
    else
        -- Uebersicht bleibt immer offen: falls zu, mit oeffnen
        if not (GK.frame and GK.frame:IsShown()) then
            local ok, err = pcall(BYKEY.main.open)
            if not ok then geterrorhandler()(err) end
        end
        HideSidePages(key)
        if GK.optFrame and GK.optFrame:IsShown() then GK.optFrame:Hide() end
        current, lastKey = key, key
    end
    if GK.frame then Place(GK.frame) end
    if f ~= GK.frame then Place(f) end
    if GK.ApplyScale then GK.ApplyScale() end
    nav:Show()
    Paint()
end

local function Hidden(key)
    if GK.navSwitching or not On() then return end
    if key == "main" then
        -- Uebersicht zu: alles zu
        current = nil
        if nav:IsShown() then nav:Hide() end
    elseif key == current then
        current = "main"
        if nav:IsShown() then Paint() end
    end
end

-- Seitenleiste zu: auch die offene Seite schliessen
nav:SetScript("OnHide", function()
    if GK.navSwitching then return end
    GK.navSwitching = true
    for _, p in ipairs(PAGES) do
        local f = p.frame()
        if f and f:IsShown() then f:Hide() end
    end
    GK.navSwitching = false
    current = nil
end)

local function Attach(key)
    local p = BYKEY[key]
    local f = p and p.frame()
    if not f or f.gkNav then return end
    f.gkNav = key
    -- Ein-Fenster-Modus: an die Seitenleiste haengen; sonst die gemerkte eigene Position nehmen
    f:HookScript("OnShow", function(self)
        if On() then Shown(key) else RestorePos(self, "page_" .. key) end
    end)
    f:HookScript("OnHide", function() Hidden(key) end)
    -- Ziehen an der Seite verschiebt im Ein-Fenster-Modus die ganze Einheit
    f:SetScript("OnDragStart", function(self)
        if On() then StartMove() elseif not Opt().lockWindow then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        if On() then StopMove() else self:StopMovingOrSizing(); SavePos(self, "page_" .. key) end
    end)
    if GK.ApplyScale then GK.ApplyScale() end
    if f:IsShown() then
        if On() then Shown(key) else RestorePos(f, "page_" .. key) end
    end
end
GK.NavAttach = Attach

-- Nach dem Bauen der jeweiligen Fenster anmelden
local hooks = { Build = "main", BuildPlus = "plus", BuildMehr = "mehr", OpenAnalyse = "analyse", SellHelper = "verkauf", OpenRouteEditor = "routen" }
for fn, key in pairs(hooks) do
    if type(GK[fn]) == "function" then hooksecurefunc(GK, fn, function() pcall(Attach, key) end) end
end

-- Andocken aus Stil.lua (Mehr und Routen-Fenster) im Ein-Fenster-Modus abschalten
for _, fn in ipairs({ "DockMehr", "DockEditor" }) do
    local orig = GK[fn]
    if orig then
        GK[fn] = function(f, ...)
            if On() and f and f.gkNav then return Place(f) end
            -- ohne Seitenleiste: eine selbst gewaehlte Position hat Vorrang vor dem Andocken
            if f and f.gkNav and HasPos("page_" .. f.gkNav) then return RestorePos(f, "page_" .. f.gkNav) end
            return orig(f, ...)
        end
    end
end

-- Oeffnen und Umschalten -------------------------------------------------------------------------------------------
function GK.OpenPage(key)
    local p = BYKEY[key] or BYKEY.main
    -- Klick auf Uebersicht: nur noch die Uebersicht zeigen
    if p.key == "main" and On() and GK.frame and GK.frame:IsShown() then
        HideSidePages()
        current, lastKey = "main", "main"
        Paint()
        return
    end
    local ok, err = pcall(p.open)
    if not ok then geterrorhandler()(err) end
    pcall(Attach, p.key)
end

local origToggle = GK.Toggle
function GK.Toggle()
    if not On() then return origToggle() end
    if nav:IsShown() then nav:Hide() else GK.OpenPage(lastKey or "main") end
end

function GK.SetOneWindow(on)
    Opt().oneWindow = on and true or false
    if not on then nav:Hide() end
end

-- Groesse und Sperre ---------------------------------------------------------------------------------------------------
function GK.ApplyScale()
    local o = Opt()
    local s = math.max(0.6, math.min(1.5, tonumber(o.scale) or 1))
    for _, f in ipairs({ nav, GK.frame, GK.plus, GK.mehr, _G.GoldKompassAnalyseFrame, _G.GoldKompassSellFrame,
        _G.GoldKompassRouteEditor, _G.GoldKompassIntroFrame }) do
        if f and f:GetScale() ~= s then f:SetScale(s) end
    end
    local hs = math.max(0.6, math.min(1.5, tonumber(o.hudScale) or 1))
    for _, f in ipairs({ GK.hud, GK.beuteHud }) do
        if f and f:GetScale() ~= hs then f:SetScale(hs) end
    end
end

-- Farm-Fenster und Gruppen-Beute: Sperre beachten
local function LockHud(f)
    if not f or f.gkLock then return end
    f.gkLock = true
    f:SetScript("OnDragStart", function(self) if not Opt().lockHud then self:StartMoving() end end)
end
if type(GK.BuildHud) == "function" then
    hooksecurefunc(GK, "BuildHud", function() pcall(LockHud, GK.hud); pcall(GK.ApplyScale) end)
end
if type(GK.BeuteShow) == "function" then
    hooksecurefunc(GK, "BeuteShow", function()
        pcall(LockHud, GK.beuteHud); pcall(GK.ApplyScale)
        pcall(GK.RememberFrame, GK.beuteHud, "beute")
    end)
end

-- Gruppen-Beute: einmal selbst verschoben, bleibt sie dort, statt ans Farm-Fenster anzudocken
local origDockBeute = GK.DockBeute
if origDockBeute then
    GK.DockBeute = function(f, ...)
        if f and HasPos("beute") then return RestorePos(f, "beute") end
        return origDockBeute(f, ...)
    end
end

-- Im Kampf ausblenden (opt.combatHide) und danach wieder zeigen -------------------------------------------------------
local combatPages
local function HideForCombat()
    if not Opt().combatHide then return end
    local list = {}
    for _, p in ipairs(PAGES) do
        local f = p.frame()
        if f and f:IsShown() then list[#list + 1] = p.key end
    end
    if #list == 0 then return end
    combatPages = list
    if On() then nav:Hide() else for _, key in ipairs(list) do BYKEY[key].frame():Hide() end end
end
local function ShowAfterCombat()
    local list = combatPages
    combatPages = nil
    if not list then return end
    for _, key in ipairs(list) do GK.OpenPage(key) end
end
-- Wer im Kampf selbst umschaltet, entscheidet: dann nach dem Kampf nichts wieder oeffnen
hooksecurefunc(GK, "Toggle", function() if InCombatLockdown() then combatPages = nil end end)

-- Befehle und Start --------------------------------------------------------------------------------------------------
GK.RegisterCommand({ "groesse", "größe", "scale" }, function(arg)
    local v = tonumber((((arg or ""):gsub(",", "."))))
    if not v then print("|cffffd100GoldKompass|r: /gk groesse 0.6 bis 1.5  (1 = normal)") return end
    if v > 3 then v = v / 100 end -- auch "/gk groesse 90" fuer 90 %
    Opt().scale = math.max(0.6, math.min(1.5, v))
    GK.ApplyScale()
end, "Fenstergröße: groesse 0.9 oder groesse 110")
GK.RegisterCommand({ "sperren", "lock" }, function()
    local o = Opt()
    o.lockWindow = not o.lockWindow
    print("|cffffd100GoldKompass|r: Fenster " .. (o.lockWindow and "gesperrt." or "verschiebbar."))
end, "Fensterposition sperren/entsperren")

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then pcall(HideForCombat); return end
    if event == "PLAYER_REGEN_ENABLED" then pcall(ShowAfterCombat); return end
    local o = Opt()
    for k, v in pairs({ oneWindow = true, scale = 1, hudScale = 1, lockWindow = false, lockHud = false, combatHide = false }) do
        if o[k] == nil then o[k] = v end
    end
    -- Position der Seitenleiste: neue Speicherart, sonst die aus 0.25.0 (navPos), sonst Bildschirmmitte
    pcall(GK.ApplyScale)
    if not RestorePos(nav, "nav") then
        local pos = DB().navPos
        nav:ClearAllPoints()
        if pos then nav:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else nav:SetPoint("CENTER", UIParent, "CENTER", -300, 40) end
    end
    -- Seiten, die schon gebaut sind, gleich anmelden
    for _, p in ipairs(PAGES) do pcall(Attach, p.key) end
    pcall(GK.ApplyScale)
    -- weitere Fenster: Position merken, sobald sie zum ersten Mal gebaut werden
    for fn, info in pairs({ ShowIntro = { "GoldKompassIntroFrame", "intro" }, OpenTransfer = { "GoldKompassTransfer", "sicherung" },
        ShowExport = { "GoldKompassExport", "export" } }) do
        if type(GK[fn]) == "function" then
            hooksecurefunc(GK, fn, function() pcall(GK.RememberFrame, _G[info[1]], info[2]) end)
        end
    end
end)

-- Designfarbe der Leiste mitziehen (UpdateBar laeuft alle 2 Sekunden)
if type(GK.UpdateBar) == "function" then
    hooksecurefunc(GK, "UpdateBar", function() if nav:IsShown() then Paint() end end)
end
