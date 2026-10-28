-- GoldKompass Gruppe: Gruppen-Farm, Fundliste (Trophaeen), Farm-Empfehlung, Bankwert und Standardwerte der Optionen.
-- Stand zurueck aus dem frueheren Extras3 (dort beim Leeren verloren gegangen). Verkaufshelfer und Taschenwert liegen in Verkauf.lua.
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end
local function G(c) return GK.FmtGold(c) end
local function Me() return UnitName("player") .. "-" .. GetRealmName() end
local PREFIX = "GoldKompass"

local function Sell(id) return select(11, C_Item.GetItemInfo(id)) or 0 end
local function Value(id) return GK.MarketPrice(id) or Sell(id) end

-- Fundliste (teuerste Drops) ----------------------------------------------------------------------------
local PATS = {}
for _, g in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF" }) do
    if _G[g] then
        local s = _G[g]:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
        PATS[#PATS + 1] = { "^" .. s .. "$", g:find("MULTIPLE") ~= nil }
    end
end
local function ParseLoot(msg)
    for _, p in ipairs(PATS) do
        local a, b = msg:match(p[1])
        if a then return a, p[2] and (tonumber(b) or 1) or 1 end
    end
end

local lootEv = CreateFrame("Frame")
lootEv:RegisterEvent("CHAT_MSG_LOOT")
lootEv:SetScript("OnEvent", function(_, _, msg)
    local DB = GK.DB()
    if not DB or GK.IsSecret(msg) then return end
    local link, n = ParseLoot(msg)
    if not link then return end
    local id = C_Item.GetItemInfoInstant(link)
    if not id then return end
    C_Timer.After(0.8, function()
        local v = Value(id) * n
        if v <= 0 then return end
        DB.trophies = DB.trophies or {}
        local t = DB.trophies
        if #t >= 10 and v <= t[#t].v then return end
        local _, nlink = C_Item.GetItemInfo(id)
        t[#t + 1] = { link = nlink or link, n = n, v = v, date = date("%Y-%m-%d"), zone = GetRealZoneText() or "?", char = UnitName("player") }
        table.sort(t, function(a, b) return a.v > b.v end)
        while #t > 10 do t[#t] = nil end
    end)
end)

-- Farm-Empfehlung: Tageszeit der Session merken -----------------------------------------------------------
local origStop = GK.FarmStop
function GK.FarmStop()
    local f = GK.farm
    local n = #GK.DB().farms
    origStop()
    local rec = GK.DB().farms[#GK.DB().farms]
    if f and rec and #GK.DB().farms > n then
        rec.hour = tonumber(date("%H", time() - (rec.secs or 0)))
    end
    if GK.SendFarmState then GK.SendFarmState(true) end
end

local function Part(h)
    if not h then return nil end
    if h < 6 then return "nachts" elseif h < 12 then return "vormittags" elseif h < 18 then return "nachmittags" end
    return "abends"
end

function GK.Recommend()
    local DB = GK.DB()
    local L, by = {}, {}
    for _, r in ipairs(DB.farms) do
        if (r.secs or 0) >= 300 then
            local k = r.name
            by[k] = by[k] or { name = k, sum = 0, secs = 0, n = 0, parts = {} }
            local net = r.net or r.total or 0
            by[k].sum = by[k].sum + net; by[k].secs = by[k].secs + r.secs; by[k].n = by[k].n + 1
            local p = Part(r.hour)
            if p then
                local q = by[k].parts[p] or { sum = 0, secs = 0 }
                q.sum = q.sum + net; q.secs = q.secs + r.secs
                by[k].parts[p] = q
            end
        end
    end
    local arr = {}
    for _, z in pairs(by) do arr[#arr + 1] = z end
    table.sort(arr, function(a, b) return a.sum / a.secs > b.sum / b.secs end)
    L[#L + 1] = "|cffffd100Farm-Empfehlung aus deinen eigenen Sessions|r"
    if #arr == 0 then
        L[#L + 1] = "   Noch zu wenig Daten. Beende ein paar Sessions von mindestens 5 Minuten."
        return L
    end
    for i = 1, math.min(3, #arr) do
        local z = arr[i]
        local bestP, bestV
        for p, q in pairs(z.parts) do
            local v = q.sum / q.secs * 3600
            if not bestV or v > bestV then bestP, bestV = p, v end
        end
        L[#L + 1] = string.format("%d. %s   %s/h  (%d Sessions)%s", i, z.name, G(z.sum / z.secs * 3600), z.n,
            bestP and ("  am besten " .. bestP) or "")
    end
    return L
end

-- Gruppen-Farm ---------------------------------------------------------------------------------------------------
GK.peers = GK.peers or {}
local lastSend = 0

function GK.Channel()
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
end

function GK.SendFarmState(force)
    local DB = GK.DB()
    if not DB or not DB.opt.groupShare then return end
    local ch = GK.Channel()
    if not ch then return end
    if not force and GetTime() - lastSend < 5 then return end
    lastSend = GetTime()
    local f = GK.farm
    local msg
    if f then
        msg = string.format("F|%s|%d|%d|%d|%d", (f.name or ""):gsub("|", "/"), f.money or 0, f.value or 0, floor(GetTime() - f.start), f.costs or 0)
    else
        msg = "H"
    end
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if send then pcall(send, PREFIX, msg, ch) end
end

local function OnAddon(prefix, msg, _, sender)
    if GK.IsSecret(prefix) or GK.IsSecret(msg) or GK.IsSecret(sender) then return end
    if prefix ~= PREFIX or not sender or sender == Me() or Ambiguate(sender, "none") == UnitName("player") then return end
    local DB = GK.DB()
    if not DB then return end
    local who = Ambiguate(sender, "short")
    local kind = msg:sub(1, 1)
    local p = GK.peers[who] or {}
    GK.peers[who] = p
    p.t = GetTime()
    if kind == "F" then
        local name, money, value, secs, costs = msg:match("^F|(.-)|(%-?%d+)|(%-?%d+)|(%d+)|(%d+)$")
        if name then
            local wasFarming = p.farming
            p.farming, p.zone = true, name
            p.money, p.value, p.secs, p.costs = tonumber(money), tonumber(value), tonumber(secs), tonumber(costs)
            if not wasFarming then
                if DB.opt.groupAutoJoin and not GK.farm and DB.opt.farm then
                    Print(who .. " farmt in " .. name .. ". Ich steige automatisch ein.")
                    GK.FarmStart(name)
                else
                    Print(who .. " hat eine Farm-Session gestartet (" .. name .. "). Mitmachen: /gk start")
                end
            end
        end
    elseif kind == "H" then
        p.farming = false
    end
end

C_Timer.NewTicker(5, function() GK.SendFarmState(false) end)
C_Timer.NewTicker(2, function()
    if GK.frame and GK.frame:IsShown() and GK.tab == "gruppe" then GK.Refresh() end
end)

-- Bankwert aus dem Inventar-Scan (Mehr.lua zaehlt die Bank beim Oeffnen) ----------------------------------------------
local function BankValue()
    local DB = GK.DB()
    local rec = DB and DB.inv and DB.inv[Me()]
    if not rec or not rec.bank then return end
    local total = 0
    for id, n in pairs(rec.bank) do total = total + Value(id) * n end
    DB.bank = DB.bank or {}
    DB.bank[Me()] = { v = total, ts = time() }
end

local function IsBanker(t)
    return Enum and Enum.PlayerInteractionType and t == Enum.PlayerInteractionType.Banker
end

-- Befehle: Reiter des Hauptfensters direkt oeffnen
GK.RegisterCommand({ "gruppe", "taschen", "funde" }, function(_, msg)
    local cmd = strlower(msg:match("^(%S*)") or "")
    if GK.CommandAlias[cmd] then cmd = GK.CommandAlias[cmd] end
    GK.Build(); GK.tab = cmd
    if not GK.frame:IsShown() then GK.frame:Show() end
    GK.Refresh()
end, "Hauptfenster im Reiter Gruppe (taschen/funde: Reiter Beute)")

-- Start, Standardwerte ---------------------------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "CHAT_MSG_ADDON", "BANKFRAME_OPENED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "PLAYER_LOGIN" then
        local DB = GK.DB()
        local o = DB.opt
        for k, v in pairs({ sellHelper = true, reminders = true, groupShare = true, groupAutoJoin = false }) do
            if o[k] == nil then o[k] = v end
        end
        DB.bank = DB.bank or {}
        local reg = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
        if reg then pcall(reg, PREFIX) end
    elseif event == "CHAT_MSG_ADDON" then
        OnAddon(a1, a2, a3, a4)
    elseif event == "BANKFRAME_OPENED" or (event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and IsBanker(a1)) then
        C_Timer.After(4, BankValue) -- Mehr.lua scannt die Bank nach 2 Sekunden
    end
end)

-- Gruppen-Beute: wer hat welchen Drop bekommen, Top 20 nach Wert (/gk beute, /gk beute leeren) ---------------------------
local function BeutePat(s)
    s = s:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    s = s:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    return "^" .. s .. "$"
end
local FREMD, EIGEN = {}, {}
for _, g in ipairs({ "LOOT_ITEM_MULTIPLE", "LOOT_ITEM" }) do
    if _G[g] then FREMD[#FREMD + 1] = { BeutePat(_G[g]), g:find("MULTIPLE") ~= nil } end
end
for _, g in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF" }) do
    if _G[g] then EIGEN[#EIGEN + 1] = { BeutePat(_G[g]), g:find("MULTIPLE") ~= nil } end
end

-- liefert Spieler, Link, Anzahl; Fremde zuerst, dann die eigene Beute
local function BeuteParse(msg)
    for _, p in ipairs(FREMD) do
        local who, link, n = msg:match(p[1])
        if who then return Ambiguate(who, "short"), link, p[2] and tonumber(n) or 1 end
    end
    for _, p in ipairs(EIGEN) do
        local link, n = msg:match(p[1])
        if link then return UnitName("player"), link, p[2] and tonumber(n) or 1 end
    end
end

local BEUTE_ROWS = 20
function GK.BeuteRefresh()
    local f, DB = GK.beute, GK.DB()
    if not f or not f:IsShown() or not DB then return end
    local t = DB.groupLoot or {}
    f.info:SetText(string.format("Top %d von %d erfassten Drops, nach Wert sortiert", math.min(BEUTE_ROWS, #t), #t))
    for i, fs in ipairs(f.rows) do
        local r = t[i]
        if r then
            fs:SetText(string.format("%2d. %s%s  |cffffd100%s|r  %s  %s", i, r.link, r.n > 1 and (" x" .. r.n) or "",
                r.who, GK.FmtGold(r.v), r.date))
        else
            fs:SetText("")
        end
    end
end

-- Das Fenster selbst (GK.BeuteShow) baut GruppenFenster.lua.

-- Der Befehl /gk beute liegt in GruppenFenster.lua
local beuteEv = CreateFrame("Frame")
beuteEv:RegisterEvent("CHAT_MSG_LOOT")
beuteEv:SetScript("OnEvent", function(_, event, msg)
    local DB = GK.DB()
    if not DB or GK.IsSecret(msg) then return end
    local who, link, n = BeuteParse(msg)
    if not link then return end
    local id = C_Item.GetItemInfoInstant(link)
    if not id then return end
    -- Item-Daten abwarten, dann den Wert festhalten
    C_Timer.After(0.8, function()
        local v = (GK.MarketPrice(id) or select(11, C_Item.GetItemInfo(id)) or 0) * n
        if v <= 0 then return end
        local t = DB.groupLoot or {}
        DB.groupLoot = t
        t[#t + 1] = { link = link, n = n, v = v, who = who, date = date("%d.%m."), zone = GetRealZoneText() or "?" }
        table.sort(t, function(a, b) return a.v > b.v end)
        while #t > 200 do t[#t] = nil end
        if GK.beute and GK.beute:IsShown() then GK.BeuteRefresh() end
    end)
end)

-- Gruppen-Beute andocken: links neben dem Farm-Fenster
function GK.DockBeute(f)
    local hud = GK.hud
    if not f or not hud or not hud:IsShown() then return end
    f:ClearAllPoints(); f:SetPoint("TOPRIGHT", hud, "TOPLEFT", -6, 0)
end

-- Farm-Session startet oder endet: Gruppen-Beute mit dem Farm-Fenster zeigen oder ausblenden
local origFarmStart = GK.FarmStart
function GK.FarmStart(...)
    origFarmStart(...)
    if GK.farm and GK.DB().opt.farm then GK.BeuteShow() end
end
local origFarmStop = GK.FarmStop
function GK.FarmStop(...)
    origFarmStop(...)
    if GK.beute then GK.beute:Hide() end
end

-- Gruppen-Beute, zweiter Anlauf: eigener Befehl /gkbeute und Anzeige, sobald das Farm-Fenster erscheint.
-- Unabhaengig von /gk, weil andere Teile des Addons den /gk-Befehl beim Start neu setzen koennen.
SLASH_GKBEUTE1 = "/gkbeute"
SlashCmdList.GKBEUTE = function() GK.BeuteShow() end

local beuteHudEv = CreateFrame("Frame")
beuteHudEv:RegisterEvent("PLAYER_LOGIN")
beuteHudEv:SetScript("OnEvent", function()
    C_Timer.NewTicker(1, function()
        local h = GK.hud
        if h and not h.gkBeuteHook then
            h.gkBeuteHook = true
            h:HookScript("OnShow", function() GK.BeuteShow() end)
            h:HookScript("OnHide", function() if GK.beute then GK.beute:Hide() end end)
        end
    end)
end)
