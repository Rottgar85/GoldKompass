-- GoldKompass Extras2: Charakter-Vergleich, Meilenstein-Ton, Tagesbilanz, Seltenheits-Anzeige, Wertwarner, Preisquellen im Tooltip
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end
local G = function(c) return GK.FmtGold(c) end
local function Me() return UnitName("player") .. "-" .. GetRealmName() end
local function WeekStart()
    local back = (date("*t").wday + 5) % 7
    return date("%Y-%m-%d", time() - back * 86400)
end

-- 1. Gold je Charakter (erhaltenes Gold, ohne Haendler/Auktionshaus/Handel) ---------------------
-- DB.charGained fuellt der zentrale Goldzaehler in GoldKompass.lua; hier nur die Standardwerte.
local mev = CreateFrame("Frame")
mev:RegisterEvent("PLAYER_LOGIN")
mev:SetScript("OnEvent", function()
    local o = GK.DB().opt
    for k, v in pairs({ milestones = true, rareLoot = true, logoutSum = true, tipCompare = true }) do
        if o[k] == nil then o[k] = v end
    end
    if o.valueWarn == nil then o.valueWarn = 0 end
end)

local function CharWeek(name)
    local ws, sum = WeekStart(), 0
    for day, v in pairs((GK.DB().charGained or {})[name] or {}) do
        if day >= ws then sum = sum + v end
    end
    return sum
end

-- Reiter "Charaktere"
local origBuild = GK.Build
function GK.Build()
    origBuild()
    local f = GK.frame
    if not f or f.gkExtra2 then return end
    f.gkExtra2 = true
    f:SetWidth(700)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(90, 22); b:SetText("Charaktere"); b:SetPoint("TOPLEFT", 12 + 5 * 94, -30)
    b:SetScript("OnClick", function() GK.tab = "chars"; GK.Refresh() end)
end

local origRefresh = GK.Refresh
function GK.Refresh()
    origRefresh()
    local f = GK.frame
    if not f or not f.gkExtra2 or not f:IsShown() or GK.tab ~= "chars" then return end
    local DB = GK.DB()
    local list, total, totalMoney = {}, 0, 0
    for name, c in pairs(DB.chars) do
        local w = CharWeek(name)
        list[#list + 1] = { name = name, week = w, money = c.money or 0 }
        total = total + w; totalMoney = totalMoney + (c.money or 0)
    end
    table.sort(list, function(a, b) return a.week > b.week end)
    local maxw = 1
    for _, c in ipairs(list) do maxw = math.max(maxw, c.week) end
    local L = { "|cffffd100Erhaltenes Gold diese Woche je Charakter|r" }
    for i, c in ipairs(list) do
        if #L < 14 then
            local bar = string.rep("||", math.floor(c.week / maxw * 20))
            L[#L + 1] = string.format("%d. %-24.24s |cffffd100%s|r %s", i, c.name, bar, G(c.week))
        end
    end
    L[#L + 1] = " "
    L[#L + 1] = "Alle zusammen diese Woche: " .. G(total)
    L[#L + 1] = "|cffffd100Gold auf den Charakteren (Gesamt: " .. G(totalMoney) .. ")|r"
    table.sort(list, function(a, b) return a.money > b.money end)
    for _, c in ipairs(list) do
        if #L < 18 then L[#L + 1] = string.format("   %-26.26s %s", c.name, G(c.money)) end
    end
    for i, fs in ipairs(f.rows) do fs:SetText(L[i] or "") end
end

-- 2. Meilenstein-Ton an der Wochenleiste -----------------------------------------------------------
local STEPS = { 25, 50, 75, 100 }
C_Timer.NewTicker(3, function()
    local DB = GK.DB()
    if not DB or not DB.opt or not DB.opt.milestones or not DB.weekGoal then return end
    local ws = WeekStart()
    if not DB.ms or DB.ms.week ~= ws or DB.ms.goal ~= DB.weekGoal then
        local pct = GK.LiveWeek() / (DB.weekGoal * 10000) * 100
        DB.ms = { week = ws, goal = DB.weekGoal, done = {} }
        for _, s in ipairs(STEPS) do if pct >= s then DB.ms.done[s] = true end end -- Bestehendes nicht nachmelden
        return
    end
    local pct = GK.LiveWeek() / (DB.weekGoal * 10000) * 100
    for _, s in ipairs(STEPS) do
        if pct >= s and not DB.ms.done[s] then
            DB.ms.done[s] = true
            if s == 100 then
                PlaySound(SOUNDKIT.UI_70_BOSS_DEFEATED or SOUNDKIT.IG_QUEST_LIST_COMPLETE, "Master")
                Print("|cff66ff66Wochenziel erreicht!|r " .. G(DB.weekGoal * 10000))
            else
                PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE, "Master")
                Print(s .. "% vom Wochenziel geschafft.")
            end
        end
    end
end)

-- 3. Tagesbilanz beim Ausloggen --------------------------------------------------------------------
local cev = CreateFrame("Frame")
cev:RegisterEvent("PLAYER_CAMPING")
cev:SetScript("OnEvent", function()
    local DB = GK.DB()
    if not DB or not DB.opt.logoutSum then return end
    local d = DB.days[date("%Y-%m-%d")]
    if not d then return end
    local best
    for _, r in ipairs(DB.farms) do
        if r.date == date("%Y-%m-%d") then
            local ph = r.netPerHour or r.perHour or 0
            if not best or ph > best.ph then best = { name = r.name, ph = ph } end
        end
    end
    Print(string.format("Tagesbilanz: eingenommen %s, ausgegeben %s, Saldo %s.%s", G(d.inn), G(-d.out), G(d.inn - d.out),
        best and ("  Beste Farm: " .. best.name .. " mit " .. G(best.ph) .. " pro Stunde.") or ""))
end)

-- 4./5. Seltene Beute einblenden, Wertwarner ------------------------------------------------------------
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

local pop
local function Toast(link, id, text)
    if not pop then
        pop = CreateFrame("Frame", "GoldKompassRareToast", UIParent, "BackdropTemplate")
        pop:SetSize(330, 56); pop:SetPoint("TOP", 0, -200); pop:SetFrameStrata("DIALOG")
        pop:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        pop:SetBackdropColor(0, 0, 0, 0.85)
        pop.icon = pop:CreateTexture(nil, "ARTWORK"); pop.icon:SetSize(38, 38); pop.icon:SetPoint("LEFT", 10, 0)
        pop.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- Rand um das Symbol in Qualitaetsfarbe
        pop.iconBorder = pop:CreateTexture(nil, "BORDER")
        pop.iconBorder:SetPoint("TOPLEFT", pop.icon, -2, 2); pop.iconBorder:SetPoint("BOTTOMRIGHT", pop.icon, 2, -2)
        pop.text = pop:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        pop.text:SetPoint("LEFT", pop.icon, "RIGHT", 10, 0); pop.text:SetWidth(260); pop.text:SetJustifyH("LEFT")
        pop:Hide()
    end
    -- Rahmen und Symbolrand in der Qualitaetsfarbe des Gegenstands (blau, episch, ...)
    local q = C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(id)
    local r, g, b = 1, 0.82, 0
    if q and C_Item.GetItemQualityColor then r, g, b = C_Item.GetItemQualityColor(q) end
    pop:SetBackdropBorderColor(r, g, b, 1)
    pop:SetBackdropColor(r * 0.12, g * 0.12, b * 0.12, 0.92)
    pop.iconBorder:SetColorTexture(r, g, b, 1)
    pop.icon:SetTexture(C_Item.GetItemIconByID(id) or "Interface\\Icons\\INV_Misc_QuestionMark")
    pop.text:SetText(link .. "\n" .. text)
    pop:Show(); pop:SetAlpha(1)
    pop.hideAt = GetTime() + 6
    pop:SetScript("OnUpdate", function(self)
        local left = self.hideAt - GetTime()
        if left <= 0 then self:Hide() elseif left < 1 then self:SetAlpha(left) end
    end)
end

local function Worth(id)
    local v = GK.MarketPrice(id)
    if v then return v, "AH" end
    local sell = select(11, C_Item.GetItemInfo(id))
    return sell or 0, "Verkaufspreis"
end

-- Toene gibt es nur bei Bind-on-Equip-Beute (GK.IsBoE aus Beute.lua); Einblendung und Chat-Hinweis bleiben.
local function OnLoot(msg)
    local link, n = ParseLoot(msg)
    if not link then return end
    local id = C_Item.GetItemInfoInstant(link)
    if not id then return end
    local DB = GK.DB()
    local o = DB.opt
    C_Timer.After(0.6, function() -- Item-Daten abwarten
        local q = select(3, C_Item.GetItemInfo(id)) or C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(id) or 0
        local v, src = Worth(id)
        local total = v * n
        local warn = (o.valueWarn or 0) * 10000
        local isWarn = warn > 0 and total >= warn
        -- Ist "Ton bei BoE-Beute" an, spielt Beute.lua schon einen Ton; dann hier keinen zweiten
        local boe = GK.IsBoE and GK.IsBoE(id) and not o.lootSound
        if o.rareLoot and q >= 3 then
            if boe then
                if q >= 4 then PlaySound(SOUNDKIT.UI_EPICLOOT_TOAST or SOUNDKIT.RAID_WARNING, "Master")
                else PlaySound(SOUNDKIT.UI_IG_STORE_BUY_ITEM_SUCCESS or SOUNDKIT.IG_QUEST_LIST_COMPLETE, "Master") end
            end
            Toast(link, id, (n > 1 and (n .. "x ") or "") .. "Wert " .. G(total) .. " (" .. src .. ")")
        end
        if isWarn then
            if boe and not (o.rareLoot and q >= 3) then PlaySound(SOUNDKIT.LOOT_WINDOW_COIN_SOUND, "Master") end
            Print("Wertvoller Fund: " .. link .. (n > 1 and (" x" .. n) or "") .. " ist " .. G(total) .. " wert.")
        end
    end)
end
local lev = CreateFrame("Frame")
lev:RegisterEvent("CHAT_MSG_LOOT")
lev:SetScript("OnEvent", function(_, _, msg) if GK.DB() and not GK.IsSecret(msg) then OnLoot(msg) end end)

-- 6. Preisquellen im Tooltip ---------------------------------------------------------------------------
-- Zeigt immer einen GoldKompass-Block: Auctionator, TSM, Verkaufspreis. Fehlt eine Quelle, steht ein Hinweis da.
local function Tip(tt, data)
    local DB = GK.DB()
    if not DB or not DB.opt.tipCompare or not tt or not data or not data.id then return end
    if tt.IsForbidden and tt:IsForbidden() then return end
    local id = data.id
    local au, mk, mn
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if api and api.GetAuctionPriceByItemID then
        local ok, v = pcall(api.GetAuctionPriceByItemID, "GoldKompass", id)
        if ok and type(v) == "number" and v > 0 then au = v end
    end
    if TSM_API and TSM_API.GetCustomPriceValue then
        local ok1, v1 = pcall(TSM_API.GetCustomPriceValue, "DBMarket", "i:" .. id)
        local ok2, v2 = pcall(TSM_API.GetCustomPriceValue, "DBMinBuyout", "i:" .. id)
        if ok1 and type(v1) == "number" and v1 > 0 then mk = v1 end
        if ok2 and type(v2) == "number" and v2 > 0 then mn = v2 end
    end
    local sell = select(11, C_Item.GetItemInfo(id))
    tt:AddLine(" ")
    tt:AddLine("GoldKompass Preise", 1, 0.82, 0)
    if au then tt:AddDoubleLine("Auctionator", G(au), 1, 1, 1) end
    if mk then tt:AddDoubleLine("TSM Marktwert", G(mk), 1, 1, 1) end
    if mn then tt:AddDoubleLine("TSM Mindestgebot", G(mn), 1, 1, 1) end
    if sell and sell > 0 then tt:AddDoubleLine("Verkaufspreis", G(sell), 1, 1, 1) end
    if not (au or mk or mn) then
        tt:AddLine((Auctionator or TSM_API) and "Kein Auktionshauspreis bekannt." or "Weder Auctionator noch TSM gefunden.", 0.7, 0.7, 0.7)
    end
    if tt.Show then tt:Show() end
end
if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, Tip)
end

-- Optionen: zweite Spalte rechts neben dem Optionsfenster ---------------------------------------------
local origBuildOpt = GK.BuildOptions
function GK.BuildOptions()
    if GK.optFrame then return end
    origBuildOpt()
    local of = GK.optFrame
    if not of or of.gkMore then return end
    of.gkMore = true
    local f = CreateFrame("Frame", nil, of, "BackdropTemplate")
    f:SetWidth(280); f:SetHeight(300); f:SetPoint("TOPLEFT", of, "TOPRIGHT", -2, 0)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -14); t:SetText("Mehr Funktionen")
    local y = -44
    for _, c in ipairs({
        { "milestones", "Ton bei 25/50/75/100% vom Wochenziel" },
        { "logoutSum", "Tagesbilanz beim Ausloggen" },
        { "rareLoot", "Einblendung bei blauer/epischer Beute" },
        { "tipCompare", "Auctionator/TSM-Preise im Tooltip" },
    }) do
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", 14, y); y = y - 26
        cb.text:SetText(c[2]); cb.text:SetFontObject("GameFontHighlightSmall")
        cb:SetScript("OnClick", function(self) GK.DB().opt[c[1]] = self:GetChecked() and true or false end)
        of.checks[c[1]] = cb
    end
    y = y - 8
    local l = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    l:SetPoint("TOPLEFT", 16, y); l:SetText("Wertwarner ab (Gold, 0 = aus):")
    local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    eb:SetSize(70, 20); eb:SetAutoFocus(false); eb:SetPoint("TOPLEFT", 20, y - 18)
    local function Set()
        local v = tonumber((eb:GetText():gsub(",", "."))) or 0
        GK.DB().opt.valueWarn = v > 0 and v or 0
        eb:ClearFocus()
    end
    eb:SetScript("OnEnterPressed", Set); eb:SetScript("OnEditFocusLost", Set)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    f:SetScript("OnShow", function()
        local v = GK.DB().opt.valueWarn or 0
        eb:SetText(v > 0 and tostring(v) or "")
    end)
end

-- Befehl /gk wert <Gold> -------------------------------------------------------------------------------
GK.RegisterCommand("wert", function(arg)
    local v = tonumber((arg:gsub(",", "."))) or 0
    GK.DB().opt.valueWarn = v > 0 and v or 0
    Print(v > 0 and ("Wertwarner ab " .. G(v * 10000)) or "Wertwarner aus.")
end, "Wertwarner: meldet Funde ab X Gold (0 = aus)")

-- fuer Kompakt.lua
GK.CharWeek = CharWeek
