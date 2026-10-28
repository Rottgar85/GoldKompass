-- GoldKompass Menue: Eintrag im Addon-Fach an der Minimap und Seite im Blizzard-Optionsmenue
-- (Esc > Optionen > AddOns > GoldKompass). Die eigentlichen Einstellungen bleiben im GoldKompass-Fenster.
local GK = GoldKompass
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function T(s) return GK.T and GK.T(s) or s end
local function G(c) return GK.FmtGold(c) end

-- Addon-Fach (## AddonCompartmentFunc... in der .toc) ---------------------------------------------------------
function GoldKompass_OnAddonCompartmentClick(_, button)
    if button == "RightButton" then GK.ToggleOptions() else GK.Toggle() end
end

function GoldKompass_OnAddonCompartmentEnter(_, menuButton)
    GameTooltip:SetOwner(menuButton or UIParent, "ANCHOR_LEFT")
    GameTooltip:AddLine("GoldKompass")
    local db = GK.DB and GK.DB()
    if db then
        GameTooltip:AddDoubleLine(T("Gold gesamt"), G((GK.TotalGold())), 1, 1, 1)
        local d = db.days and db.days[date("%Y-%m-%d")]
        if d then GameTooltip:AddDoubleLine(T("Saldo heute"), G((d.inn or 0) - (d.out or 0)), 1, 1, 1) end
        local fm = GK.farm
        if fm then
            local secs = GetTime() - fm.start
            local total = fm.money + fm.value - (fm.costs or 0)
            GameTooltip:AddDoubleLine(fm.name, G(secs > 30 and total / secs * 3600 or 0) .. "/h", 1, 0.82, 0)
        end
    end
    GameTooltip:AddLine(T("Linksklick: Fenster"), 0.7, 0.7, 0.7)
    GameTooltip:AddLine(T("Rechtsklick: Optionen"), 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function GoldKompass_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

-- Seite im Blizzard-Optionsmenue ----------------------------------------------------------------------------
local category

local function CloseSettings()
    if SettingsPanel and SettingsPanel:IsShown() then pcall(HideUIPanel, SettingsPanel) end
end

local function Version()
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return get and get("GoldKompass", "Version") or ""
end

local panel = CreateFrame("Frame", "GoldKompassSettingsPanel")
panel.name = "GoldKompass"

local logo = panel:CreateTexture(nil, "ARTWORK")
logo:SetSize(64, 64); logo:SetPoint("TOPLEFT", 16, -16)
logo:SetTexture(GK.LOGO or "Interface\\Icons\\INV_Misc_Coin_02")
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -6); title:SetText("GoldKompass")
local ver = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -12); desc:SetPoint("RIGHT", -16, 0)
desc:SetJustifyH("LEFT")
desc:SetText("Zeichnet auf, woher dein Gold kommt und wohin es geht, rechnet Gold pro Stunde aus und hilft beim Farmen und Verkaufen.\nDie Einstellungen findest du im GoldKompass-Fenster unter Optionen.")

local summary = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
summary:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12); summary:SetJustifyH("LEFT")

-- Knoepfe: oeffnen das jeweilige GoldKompass-Fenster und schliessen dabei das Blizzard-Menue
local function Page(key, fallback)
    return function()
        if GK.OpenPage then GK.OpenPage(key) elseif fallback then fallback() end
    end
end
local BUTTONS = {
    { "Fenster öffnen", Page("main", function() GK.Build(); GK.frame:Show() end) },
    { "Optionen öffnen", function() GK.ToggleOptions() end },
    { "Willkommensseite", function() if GK.ShowIntro then GK.ShowIntro() end end },
    { "Gold-Verlauf", function() if GK.OpenAnalyse then GK.OpenAnalyse("verlauf") end end },
    { "Items pro Stunde", function() if GK.OpenAnalyse then GK.OpenAnalyse("items") end end },
    { "Routen und Ziele", Page("plus", function() if GK.OpenPlus then GK.OpenPlus() end end) },
    { "Sicherung", function() if GK.OpenTransfer then GK.OpenTransfer() end end },
    { "Speicher prüfen", function() if GK.ShowMemory then GK.ShowMemory() end end, true },
    { "Selbsttest", function() if GK.SelfTest then GK.SelfTest() end end, true },
}
local rowStart
for i, b in ipairs(BUTTONS) do
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(150, 24); btn:SetText(b[1])
    local col = (i - 1) % 3
    if i == 1 then btn:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -14)
    elseif col == 0 then btn:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -6) end
    if col == 0 then rowStart = btn else btn:SetPoint("TOPLEFT", rowStart, "TOPLEFT", col * 158, 0) end
    if i == 1 then panel.firstBtn = btn end
    -- b[3]: Ergebnis steht im Chat, das Blizzard-Menue bleibt offen
    btn:SetScript("OnClick", function() if not b[3] then CloseSettings() end; b[2]() end)
end

-- Darstellung: Groesse, Sperren, Ein-Fenster-Modus, Ausblenden im Kampf (wirkt sofort, siehe Fenster.lua)
local look = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
look:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -18); look:SetText("Darstellung")
panel.steppers, panel.checks = {}, {}

local function Stepper(label, key, anchor, x)
    local l = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    l:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, -10); l:SetWidth(140); l:SetJustifyH("LEFT"); l:SetText(label)
    local minus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"); minus:SetSize(24, 20); minus:SetText("-")
    minus:SetPoint("LEFT", l, "RIGHT", 4, 0)
    local val = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); val:SetWidth(46)
    val:SetPoint("LEFT", minus, "RIGHT", 2, 0)
    local plus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"); plus:SetSize(24, 20); plus:SetText("+")
    plus:SetPoint("LEFT", val, "RIGHT", 2, 0)
    local function Show()
        local db = GK.DB and GK.DB()
        local v = db and tonumber(db.opt[key]) or 1
        val:SetText(floor(v * 100 + 0.5) .. "%")
    end
    local function Step(d)
        local db = GK.DB and GK.DB()
        if not db then return end
        local v = (tonumber(db.opt[key]) or 1) + d
        db.opt[key] = math.max(0.6, math.min(1.5, floor(v * 20 + 0.5) / 20))
        if GK.ApplyScale then GK.ApplyScale() end
        Show()
    end
    minus:SetScript("OnClick", function() Step(-0.05) end)
    plus:SetScript("OnClick", function() Step(0.05) end)
    panel.steppers[#panel.steppers + 1] = Show
    return l
end
local s1 = Stepper("Fenstergröße", "scale", look)
Stepper("Farm-Fenster-Größe", "hudScale", look, 300)

local CHECKS = {
    { "oneWindow", "Ein Fenster mit Seitenleiste", function(on) if GK.SetOneWindow then GK.SetOneWindow(on) end end },
    -- Sammelschalter: setzt auch die einzeln (per Schloss) gesperrten Fenster dieser Gruppe zurueck
    { "lockWindow", "Fenster sperren", function() if GK.ResetLockGroup then GK.ResetLockGroup("lockWindow") end end },
    { "lockHud", "Farm-Fenster sperren", function() if GK.ResetLockGroup then GK.ResetLockGroup("lockHud") end end },
    { "combatHide", "Im Kampf ausblenden" },
}
local lastCheck
for i, c in ipairs(CHECKS) do
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local col = (i - 1) % 2
    if col == 0 then
        cb:SetPoint("TOPLEFT", lastCheck or s1, "BOTTOMLEFT", lastCheck and 0 or -4, lastCheck and -2 or -10)
        lastCheck = cb
    else
        cb:SetPoint("LEFT", lastCheck, "LEFT", 304, 0)
    end
    cb.text:SetText(c[2]); cb.text:SetFontObject("GameFontHighlight")
    cb:SetScript("OnClick", function(self)
        local db = GK.DB and GK.DB()
        if not db then return end
        local on = self:GetChecked() and true or false
        db.opt[c[1]] = on
        if c[3] then c[3](on) end
    end)
    panel.checks[c[1]] = cb
end

-- Sprache: Automatisch (folgt dem Spiel), Deutsch oder English
local langLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
langLabel:SetPoint("TOPLEFT", lastCheck, "BOTTOMLEFT", 4, -10); langLabel:SetText("Sprache")
panel.langChecks = {}
local function RefreshLang()
    local cur = GK.GetLanguageSetting and GK.GetLanguageSetting() or "auto"
    for key, cb in pairs(panel.langChecks) do cb:SetChecked(key == cur) end
end
local prevLang
for i, l in ipairs({ { "auto", "Automatisch" }, { "de", "Deutsch" }, { "en", "English" } }) do
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    if i == 1 then cb:SetPoint("LEFT", langLabel, "RIGHT", 10, 0) else cb:SetPoint("LEFT", prevLang.text, "RIGHT", 16, 0) end
    cb.text:SetText(l[2]); cb.text:SetFontObject("GameFontHighlight")
    cb:SetScript("OnClick", function()
        if GK.SetLanguage then GK.SetLanguage(l[1]) end
        RefreshLang()
    end)
    panel.langChecks[l[1]] = cb
    prevLang = cb
end
local prevRefreshLang = GK.RefreshLanguageUI
GK.RefreshLanguageUI = function()
    RefreshLang()
    if prevRefreshLang then prevRefreshLang() end
end

-- Befehlsliste (aus dem zentralen Befehlsregister), scrollbar
local head = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
head:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -18); head:SetText("Befehle (/gk ...)")
local sf = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
sf:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -6); sf:SetPoint("BOTTOMRIGHT", -32, 16)
local child = CreateFrame("Frame", nil, sf)
child:SetSize(560, 10)
sf:SetScrollChild(child)
local list = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
list:SetPoint("TOPLEFT"); list:SetWidth(560); list:SetJustifyH("LEFT"); list:SetSpacing(3)

panel:SetScript("OnShow", function()
    ver:SetText("Version " .. Version())
    local db = GK.DB and GK.DB()
    if db then
        local total, chars, warbank = GK.TotalGold()
        summary:SetText(string.format("%s %s     %s %s     %s %s", T("Gold gesamt:"), G(total), T("Charaktere:"), G(chars),
            T("Kriegsmeute-Bank:"), db.warbank and G(warbank) or "-"))
        for key, cb in pairs(panel.checks) do
            if key == "oneWindow" then cb:SetChecked(db.opt.oneWindow ~= false) else cb:SetChecked(db.opt[key] and true or false) end
        end
        for _, fn in ipairs(panel.steppers) do fn() end
        RefreshLang()
    end
    local lines = {}
    for _, c in ipairs(GK.CommandHelp and GK.CommandHelp() or {}) do
        lines[#lines + 1] = "|cffffd100/gk " .. (GK.CommandName and GK.CommandName(c.name) or c.name) .. "|r  " .. T(c.help)
    end
    list:SetText(table.concat(lines, "\n"))
    child:SetHeight(list:GetStringHeight() + 10)
    child:SetWidth(math.max(200, sf:GetWidth()))
    list:SetWidth(child:GetWidth())
end)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    category = Settings.RegisterCanvasLayoutCategory(panel, "GoldKompass")
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end

-- /gk einstellungen oeffnet die Seite im Blizzard-Menue
function GK.OpenSettings()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end
GK.RegisterCommand({ "einstellungen", "settings" }, function() GK.OpenSettings() end, "GoldKompass im Blizzard-Optionsmenü öffnen")
