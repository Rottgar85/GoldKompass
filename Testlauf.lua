-- GoldKompass Testlauf: Farm-Zeitlimit (Minuten, 0 = unendlich), Eingabe unter dem Hauptfenster und Restzeit im Farm-Fenster.
-- Befehl: /gk dauer <Minuten>
-- Das Limit gilt fuer laufende und kuenftige Sessions und wird gespeichert (opt.farmMinutes).
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end
local function DB() return GK.DB and GK.DB() end

-- Farm-Zeitlimit ------------------------------------------------------------------------------------------
local function Limit()
    local db = DB()
    local m = db and db.opt and tonumber(db.opt.farmMinutes) or 0
    return m > 0 and m or 0
end

local function SetLimit(m)
    local db = DB()
    if not db then return end
    m = tonumber(m) or 0
    if m < 0 then m = 0 end
    db.opt.farmMinutes = m
    Print(m > 0 and ("Farm stoppt automatisch nach " .. m .. " Minuten.") or "Farm-Dauer unbegrenzt.")
    if GK.UpdateControl then GK.UpdateControl() end
end

C_Timer.NewTicker(1, function()
    local fm, lim = GK.farm, Limit()
    if not fm or lim <= 0 then return end
    if GetTime() - fm.start >= lim * 60 then
        pcall(GK.FarmStop)
        Print("|cff66ff66Farm-Zeit von " .. lim .. " Minuten erreicht.|r Die Session wurde beendet.")
        if GK.PlayAlarmSound then pcall(GK.PlayAlarmSound) end
        if GK.Refresh then pcall(GK.Refresh) end
        if GK.UpdateControl then pcall(GK.UpdateControl) end
    end
end)

local function LeftText()
    local lim, fm = Limit(), GK.farm
    if lim <= 0 then return "unbegrenzt" end
    if fm then
        local left = math.max(0, lim * 60 - (GetTime() - fm.start))
        return string.format("noch %d:%02d", floor(left / 60), floor(left % 60))
    end
    return "stoppt nach " .. lim .. " Min"
end

-- Eigener Streifen fuer die Dauer: haengt unter der Start/Stopp-Leiste (oder unter dem Hauptfenster) ---------
local function ParseMinutes(s)
    s = tostring(s or "")
    s = s:gsub(",", "."):gsub("%s", "")
    if s == "" then return 0 end
    local v = tonumber(s)
    if v and v >= 0 then return v end
end

local dur
local function BuildDur()
    if dur then return dur end
    if not GK.frame then pcall(GK.Build) end
    local p = GK.frame
    if not p then return end
    local f = CreateFrame("Frame", "GoldKompassDauer", p, "BackdropTemplate")
    f:SetHeight(28)
    f:SetFrameStrata(p:GetFrameStrata())
    f:SetFrameLevel(p:GetFrameLevel() + 5)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    f:SetBackdropBorderColor(1, 0.82, 0, 1)

    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("LEFT", 10, 0); lbl:SetText("Farmzeit (Min, 0 = unendlich):")
    local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    box:SetSize(44, 18); box:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
    box:SetAutoFocus(false); box:SetMaxLetters(5); box:SetJustifyH("CENTER")
    local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ok:SetSize(44, 20); ok:SetText("OK"); ok:SetPoint("LEFT", box, "RIGHT", 6, 0)
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("LEFT", ok, "RIGHT", 10, 0)

    local function Apply()
        local v = ParseMinutes(box:GetText())
        if not v then
            Print("Bitte eine Zahl in Minuten eingeben, zum Beispiel 30. 0 heisst unendlich.")
            box:SetText(tostring(Limit()))
            return
        end
        box:ClearFocus()
        SetLimit(v)
    end
    ok:SetScript("OnClick", Apply)
    box:SetScript("OnEnterPressed", Apply)
    box:SetScript("OnEscapePressed", function(self) self:SetText(tostring(Limit())); self:ClearFocus() end)
    f.box, f.status = box, status
    dur = f
    return f
end

local function UpdateLimitUI()
    local f = BuildDur()
    if not f then return end
    local p = GK.frame
    local bar = _G.GoldKompassFarmControl
    f:ClearAllPoints()
    local anchor = (bar and bar:IsShown()) and bar or p
    f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 2)
    f:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, 2)
    f:SetShown(p:IsShown())
    if not f.box:HasFocus() then f.box:SetText(tostring(Limit())) end
    f.status:SetText(LeftText())
end

-- Restzeit im kleinen Farm-Fenster, rechts neben dem Namen -------------------------------------------------
local function UpdateHudTime()
    local h = GK.hud
    if not h then return end
    if not h.gkTime then
        h.gkTime = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h.gkTime:SetPoint("TOPRIGHT", -22, -6); h.gkTime:SetJustifyH("RIGHT")
        h.gkTime:SetTextColor(0.4, 0.9, 0.5)
        h.title:SetWidth(105)
    end
    h.gkTime:SetText(GK.farm and LeftText() or "")
end

local function SafeUpdate()
    local ok, err = pcall(UpdateLimitUI)
    if not ok and not GK.durErr then
        GK.durErr = true
        Print("|cffff6666Fehler bei der Farmzeit-Leiste:|r " .. tostring(err))
    end
    pcall(UpdateHudTime)
end
if type(GK.UpdateControl) == "function" then hooksecurefunc(GK, "UpdateControl", SafeUpdate) end
if type(GK.RefreshHud) == "function" then hooksecurefunc(GK, "RefreshHud", function() pcall(UpdateHudTime) end) end
C_Timer.NewTicker(1, SafeUpdate)

-- Befehle -----------------------------------------------------------------------------------------------------------
GK.RegisterCommand("dauer", function(arg)
    local v = ParseMinutes(arg)
    if v then SetLimit(v) else Print("Benutzung: /gk dauer 30  (Minuten, 0 = unendlich)") end
end, "Farm stoppt automatisch nach X Minuten (0 = nie)")

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    C_Timer.After(2, SafeUpdate)
end)
