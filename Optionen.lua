-- GoldKompass Optionen: haengt rechts am Hauptfenster, alles einzeln an/aus, Preisquelle und Alarm-Sound waehlbar
local GK = GoldKompass

local GROUPS = {
    { "Aufzeichnung", {
        { "record", "Gold aufzeichnen (Heute / Verlauf)" },
        { "farm", "Farm-Rechner (Loot und Sessions)" },
    } },
    { "Anzeige", {
        { "minimap", "Minimap-Button anzeigen" },
        { "welcome", "Begruessung beim Einloggen" },
    } },
    { "Beute", {
        { "lootSound", "Ton bei gruenem oder besserem Item" },
    } },
    { "Preisalarm", {
        { "alarm", "Preisalarm aktiv" },
        { "alarmSound", "Ton abspielen" },
        { "alarmPopup", "Einblendung am Bildschirm" },
        { "alarmChat", "Meldung im Chat" },
    } },
}
local SOURCES = {
    { "auctionator", "Auctionator" },
    { "tsmMarket", "TSM Marktwert" },
    { "tsmMin", "TSM Mindestgebot" },
}

-- Sounds: eingebaute Spielsounds, dazu alles aus LibSharedMedia (dort melden sich auch TSM und andere Addons an) ---
local BUILTIN = {
    { "Kassen-Klingeln", "LOOT_WINDOW_COIN_SOUND" },
    { "Auktionshaus auf", "AUCTION_WINDOW_OPEN" },
    { "Auktionshaus zu", "AUCTION_WINDOW_CLOSE" },
    { "Quest fertig", "IG_QUEST_LIST_COMPLETE" },
    { "Bereitschaftscheck", "READY_CHECK" },
    { "Schlachtzugswarnung", "RAID_WARNING" },
    { "Toast", "UI_BNET_TOAST" },
    { "Ruhmeshalle", "UI_IG_STORE_BUY_ITEM_SUCCESS" },
}
function GK.SoundList()
    local list = {}
    for _, s in ipairs(BUILTIN) do
        if SOUNDKIT and SOUNDKIT[s[2]] then list[#list + 1] = { name = s[1], id = "kit:" .. s[2] } end
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local names = LSM:List("sound")
        for _, n in ipairs(names or {}) do list[#list + 1] = { name = n, id = "lsm:" .. n } end
    end
    return list
end
function GK.PlayAlarmSound(id)
    id = id or (GK.DB() and GK.DB().opt.sound) or "kit:LOOT_WINDOW_COIN_SOUND"
    local kind, key = id:match("^(%a+):(.+)$")
    if kind == "lsm" then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        local path = LSM and LSM:Fetch("sound", key, true)
        if path then PlaySoundFile(path, "Master"); return end
    elseif kind == "kit" and SOUNDKIT[key] then
        PlaySound(SOUNDKIT[key], "Master"); return
    end
    PlaySound(SOUNDKIT.LOOT_WINDOW_COIN_SOUND, "Master")
end

local function Header(f, text, y)
    local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 16, y); h:SetText(text)
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.35); line:SetHeight(1)
    line:SetPoint("TOPLEFT", 16, y - 16); line:SetPoint("TOPRIGHT", -16, y - 16)
    return y - 24
end

function GK.BuildOptions()
    if GK.optFrame then return end
    GK.Build()
    local f = CreateFrame("Frame", "GoldKompassOptionsFrame", GK.frame, "BackdropTemplate")
    f:SetWidth(300); f:SetPoint("TOPLEFT", GK.frame, "TOPRIGHT", -2, 0); f:SetPoint("BOTTOMLEFT", GK.frame, "BOTTOMRIGHT", -2, 0)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    f:Hide()
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -14); title:SetText("Optionen")

    f.checks, f.radios = {}, {}
    local y = -44
    for _, g in ipairs(GROUPS) do
        y = Header(f, g[1], y)
        for _, c in ipairs(g[2]) do
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", 14, y); y = y - 24
            cb.text:SetText(c[2]); cb.text:SetFontObject("GameFontHighlightSmall")
            cb:SetScript("OnClick", function(self)
                GK.DB().opt[c[1]] = self:GetChecked() and true or false
                GK.ApplyOptions()
            end)
            f.checks[c[1]] = cb
        end
        y = y - 6
    end

    -- Alarm-Sound als Dropdown (scrollbar, weil LibSharedMedia viele Eintraege haben kann)
    y = Header(f, "Alarm-Sound", y)
    local dd = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", 16, y); dd:SetWidth(200)
    dd:SetupMenu(function(_, root)
        root:SetScrollMode(320)
        for _, s in ipairs(GK.SoundList()) do
            root:CreateRadio(s.name,
                function() return GK.DB().opt.sound == s.id end,
                function() GK.DB().opt.sound = s.id; GK.PlayAlarmSound(s.id) end)
        end
    end)
    f.soundDD = dd
    local test = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    test:SetSize(64, 22); test:SetText("Test"); test:SetPoint("LEFT", dd, "RIGHT", 6, 0)
    test:SetScript("OnClick", function() GK.PlayAlarmSound() end)
    y = y - 34

    y = Header(f, "Preisquelle", y)
    for _, s in ipairs(SOURCES) do
        local rb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        rb:SetSize(24, 24); rb:SetPoint("TOPLEFT", 14, y); y = y - 24
        rb.text:SetText(s[2]); rb.text:SetFontObject("GameFontHighlightSmall")
        rb:SetScript("OnClick", function() GK.DB().opt.source = s[1]; GK.RefreshOptions() end)
        f.radios[s[1]] = rb
    end
    f.note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.note:SetPoint("BOTTOMLEFT", 16, 14); f.note:SetWidth(268); f.note:SetJustifyH("LEFT")
    f:SetScript("OnShow", function() GK.RefreshOptions() end)
    GK.optFrame = f
end

function GK.RefreshOptions()
    local f = GK.optFrame
    if not f then return end
    local o = GK.DB().opt
    for k, cb in pairs(f.checks) do cb:SetChecked(o[k]) end
    for k, rb in pairs(f.radios) do rb:SetChecked(o.source == k) end
    f.soundDD:GenerateMenu()
    local msg = ""
    if o.source == "auctionator" and not (Auctionator and Auctionator.API) then
        msg = "|cffff5555Auctionator nicht gefunden.|r Ersatz: Haendlerpreis."
    elseif o.source ~= "auctionator" and not TSM_API then
        msg = "|cffff5555TSM nicht gefunden.|r Ersatz: Auctionator oder Haendlerpreis."
    end
    f.note:SetText(msg)
end

function GK.ToggleOptions()
    GK.BuildOptions()
    if not GK.frame:IsShown() then GK.frame:Show() end
    if GK.optFrame:IsShown() then GK.optFrame:Hide() else GK.optFrame:Show() end
end

GK.RegisterCommand({ "optionen", "opt" }, function() GK.ToggleOptions() end, "Optionen öffnen")
