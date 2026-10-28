-- GoldKompass Rekorde, Einblendungen und Einfuehrung.
-- Rekorde: beste Farm-Stunde, bester Tag, beste Woche (DB.records); ein neuer Rekord wird kurz eingeblendet.
-- Wochenziel erreicht: einmal pro Woche eine Einblendung. Seiten blenden weich ein.
-- Einfuehrung: beim ersten Oeffnen erklaeren drei Hinweise die Seitenleiste (/gk tour zeigt sie erneut).
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function DB() return GK.DB and GK.DB() end
local function T(s) return GK.T and GK.T(s) or s end
local function G(c) return GK.FmtGold and GK.FmtGold(c) or tostring(floor((c or 0) / 10000)) .. "g" end

-- Einblendung ----------------------------------------------------------------------------------------------------
local toast = CreateFrame("Frame", "GoldKompassRecordToast", UIParent, "BackdropTemplate")
toast:SetSize(300, 64); toast:SetPoint("TOP", UIParent, "TOP", 0, -160)
toast:SetFrameStrata("HIGH"); toast:Hide()
toast:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
toast:SetBackdropColor(0.06, 0.05, 0.02, 0.95); toast:SetBackdropBorderColor(1, 0.82, 0, 1)
local icon = toast:CreateTexture(nil, "ARTWORK"); icon:SetSize(40, 40); icon:SetPoint("LEFT", 12, 0)
local head = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
head:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2); head:SetPoint("RIGHT", -10, 0); head:SetJustifyH("LEFT")
local body = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
body:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 2); body:SetPoint("RIGHT", -10, 0); body:SetJustifyH("LEFT")
local glow = toast:CreateTexture(nil, "BACKGROUND", nil, 1)
glow:SetAllPoints(); glow:SetColorTexture(1, 0.82, 0, 0.25); glow:SetBlendMode("ADD")
local pulse = glow:CreateAnimationGroup(); pulse:SetLooping("BOUNCE")
local a = pulse:CreateAnimation("Alpha"); a:SetFromAlpha(0.1); a:SetToAlpha(1); a:SetDuration(0.6)

local queue = {}
local function ShowNext()
    local item = table.remove(queue, 1)
    if not item then toast:Hide(); return end
    icon:SetTexture(item.icon or "Interface\\Icons\\Achievement_Reputation_01")
    head:SetText(T(item.title)); body:SetText(item.text)
    toast:SetAlpha(0); toast:Show(); UIFrameFadeIn(toast, 0.3, 0, 1); pulse:Play()
    PlaySound(SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST or 31578, "Master")
    C_Timer.After(4.5, function()
        UIFrameFadeOut(toast, 0.6, 1, 0)
        C_Timer.After(0.7, function() pulse:Stop(); ShowNext() end)
    end)
end
function GK.Celebrate(title, text, tex)
    queue[#queue + 1] = { title = title, text = text, icon = tex }
    if not toast:IsShown() then ShowNext() end
end

-- Rekorde --------------------------------------------------------------------------------------------------------
local function Rec() local db = DB(); if not db then return end; db.records = db.records or {}; return db.records end
local function WeekStart() return date("%Y-%m-%d", time() - ((date("*t").wday + 5) % 7) * 86400) end

local function CheckDayWeek(silent)
    local db, r = DB(), Rec()
    if not r or not db.days then return end
    local today = date("%Y-%m-%d")
    local d = db.days[today]
    local net = d and (d.inn - d.out) or 0
    if net > 0 and net > (r.day or 0) then
        local first = r.day == nil
        r.day, r.dayDate = net, date("%d.%m.%Y")
        if not silent and not first and r.dayToast ~= today then
            r.dayToast = today
            GK.Celebrate("Neuer Rekord: bester Tag!", G(net), "Interface\\Icons\\INV_Misc_Coin_02")
        end
    end
    local ws, wnet = WeekStart(), 0
    for day, dd in pairs(db.days) do if day >= ws then wnet = wnet + dd.inn - dd.out end end
    if wnet > 0 and wnet > (r.week or 0) then
        local first = r.week == nil
        r.week, r.weekDate = wnet, date("%d.%m.%Y", time() - ((date("*t").wday + 5) % 7) * 86400)
        if not silent and not first and r.weekToast ~= ws then
            r.weekToast = ws
            GK.Celebrate("Neuer Rekord: beste Woche!", G(wnet), "Interface\\Icons\\INV_Misc_Coin_17")
        end
    end
    -- Wochenziel erreicht (einmal pro Woche)
    local goal = (db.weekGoal or 0) * 10000
    if goal > 0 and wnet >= goal and r.goalToast ~= ws then
        r.goalToast = ws
        if not silent then GK.Celebrate("Wochenziel erreicht!", G(wnet), "Interface\\Icons\\Achievement_Quests_Completed_08") end
    end
end

-- Beste Farm-Stunde: nach jedem Stopp (Sessions unter 10 Minuten zaehlen nicht, sonst reicht ein Glueckstreffer)
if type(GK.FarmStop) == "function" then
    hooksecurefunc(GK, "FarmStop", function()
        local db, r = DB(), Rec()
        local last = db and db.farms and db.farms[#db.farms]
        if not r or not last or (last.secs or 0) < 600 or last.gkRecChecked then return end
        last.gkRecChecked = true
        local ph = last.perHour or 0
        if ph > (r.hour or 0) then
            local first = r.hour == nil
            r.hour, r.hourName = ph, last.name
            if not first then GK.Celebrate("Neuer Rekord: beste Farm-Stunde!", G(ph) .. " / h", "Interface\\Icons\\INV_Misc_PocketWatch_01") end
        end
    end)
end

-- Seiten blenden weich ein ----------------------------------------------------------------------------------------
local function Fade(f)
    if not f or f.gkFade then return end
    f.gkFade = true
    f:HookScript("OnShow", function(self) if not InCombatLockdown() then UIFrameFadeIn(self, 0.15, 0, 1) end end)
end
local function FadeAll()
    for _, f in ipairs({ GK.frame, GK.plus, GK.mehr, GK.nav, _G.GoldKompassAnalyseFrame, _G.GoldKompassSellFrame,
        _G.GoldKompassRouteEditor, GK.optFrame }) do Fade(f) end
end
for _, fn in ipairs({ "Build", "BuildPlus", "BuildMehr", "OpenAnalyse", "SellHelper", "OpenRouteEditor", "BuildOptions" }) do
    if type(GK[fn]) == "function" then hooksecurefunc(GK, fn, function() pcall(FadeAll) end) end
end

-- Einfuehrung ------------------------------------------------------------------------------------------------------
local STEPS = {
    { key = "main", text = "Hier ist deine Übersicht: Gold heute, Gold pro Stunde und Wochenziel." },
    { key = "plus", text = "Weitere Seiten öffnen sich rechts neben der Übersicht. Ein Klick auf Übersicht schließt sie wieder." },
    { key = "lang", text = "Sprache, Optionen und Einstellungen findest du unten. Viel Spaß beim Farmen!" },
}
local tip = CreateFrame("Frame", "GoldKompassTour", UIParent, "BackdropTemplate")
tip:SetSize(240, 96); tip:SetFrameStrata("DIALOG"); tip:Hide()
tip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
tip:SetBackdropColor(0.05, 0.05, 0.08, 0.97); tip:SetBackdropBorderColor(1, 0.82, 0, 1)
local arrow = tip:CreateTexture(nil, "OVERLAY"); arrow:SetSize(24, 24); arrow:SetPoint("RIGHT", tip, "LEFT", 2, 0)
arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
local tipText = tip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
tipText:SetPoint("TOPLEFT", 10, -10); tipText:SetPoint("TOPRIGHT", -10, -10); tipText:SetJustifyH("LEFT")
local nextBtn = CreateFrame("Button", nil, tip, "UIPanelButtonTemplate")
nextBtn:SetSize(80, 20); nextBtn:SetPoint("BOTTOMRIGHT", -8, 8)
local skipBtn = CreateFrame("Button", nil, tip, "UIPanelButtonTemplate")
skipBtn:SetSize(80, 20); skipBtn:SetPoint("RIGHT", nextBtn, "LEFT", -4, 0); skipBtn:SetText(T("Überspringen"))
local step = 0
local function Finish() tip:Hide(); local db = DB(); if db then db.opt.tourDone = true end end
local function ShowStep()
    step = step + 1
    local s, nav = STEPS[step], GK.nav
    if not s or not nav or not nav:IsShown() then Finish(); return end
    local anchor = nav.buttons and nav.buttons[s.key] or nav
    if s.key == "lang" then anchor = nav end
    tip:ClearAllPoints()
    if s.key == "lang" then tip:SetPoint("LEFT", nav, "BOTTOMRIGHT", 16, 70) else tip:SetPoint("LEFT", anchor, "RIGHT", 16, 0) end
    tipText:SetText(T(s.text))
    nextBtn:SetText(T(step < #STEPS and "Weiter" or "Fertig"))
    tip:Show(); UIFrameFadeIn(tip, 0.2, 0, 1)
end
nextBtn:SetScript("OnClick", ShowStep)
skipBtn:SetScript("OnClick", Finish)
function GK.StartTour() step = 0; if GK.OpenPage and not (GK.nav and GK.nav:IsShown()) then GK.OpenPage("main") end; C_Timer.After(0.3, ShowStep) end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    pcall(FadeAll)
    C_Timer.After(5, function() pcall(CheckDayWeek, true) end)
    C_Timer.NewTicker(60, function() pcall(CheckDayWeek, false) end)
    if GK.nav then
        GK.nav:HookScript("OnShow", function()
            local db = DB()
            if db and not db.opt.tourDone and not InCombatLockdown() then C_Timer.After(0.5, function() step = 0; ShowStep() end) end
        end)
        GK.nav:HookScript("OnHide", function() tip:Hide() end)
    end
end)

GK.RegisterCommand({ "tour" }, function() GK.StartTour() end, "Einführung erneut zeigen")
GK.RegisterCommand({ "rekorde", "records" }, function()
    local r = Rec() or {}
    print("|cffffd100GoldKompass|r: " .. T("Deine Rekorde"))
    print("   " .. T("Beste Farm-Stunde") .. ": " .. (r.hour and G(r.hour) or "-"))
    print("   " .. T("Bester Tag") .. ": " .. (r.day and (G(r.day) .. " (" .. r.dayDate .. ")") or "-"))
    print("   " .. T("Beste Woche") .. ": " .. (r.week and (G(r.week) .. " (" .. r.weekDate .. ")") or "-"))
end, "Rekorde: beste Stunde, bester Tag, beste Woche")
