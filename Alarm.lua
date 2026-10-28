-- GoldKompass Preisalarm: meldet sich mit Kassen-Klingeln, wenn ein Item auf oder unter deinen Wunschpreis faellt
local addonName = ...
local GK = GoldKompass
local TITLE = "|cffffd100GoldKompass Alarm|r"
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(TITLE .. ": " .. m) end
local CHECK_EVERY = 60     -- Sekunden zwischen Pruefungen
local REPEAT_AFTER = 600   -- gleicher Alarm fruehestens nach 10 Min

local function Money(c)
    return string.format("%dg %02ds", floor(c / 10000), floor((c % 10000) / 100))
end

local function Price(id) return GK.MarketPrice(id) end

local function List()
    GoldKompassDB.alarms = GoldKompassDB.alarms or {}
    return GoldKompassDB.alarms
end

local function Link(id)
    local _, link = C_Item.GetItemInfo(id)
    return link or ("Item " .. id)
end

-- Einblendung mit Muenze ---------------------------------------------------
local popup
local function Popup(id, price, target)
    if not popup then
        popup = CreateFrame("Frame", "GoldKompassAlarmPopup", UIParent, "BackdropTemplate")
        popup:SetSize(340, 64); popup:SetPoint("TOP", 0, -140); popup:SetFrameStrata("DIALOG")
        popup:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        popup:SetBackdropColor(0, 0, 0, 0.9)
        popup.icon = popup:CreateTexture(nil, "ARTWORK")
        popup.icon:SetSize(40, 40); popup.icon:SetPoint("LEFT", 12, 0)
        popup.text = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        popup.text:SetPoint("LEFT", popup.icon, "RIGHT", 10, 0); popup.text:SetJustifyH("LEFT"); popup.text:SetWidth(260)
        popup:Hide()
    end
    popup.icon:SetTexture(C_Item.GetItemIconByID(id) or "Interface\\Icons\\INV_Misc_Coin_02")
    popup.text:SetText("|cff66ff66KA-CHING!|r " .. Link(id) .. "\nJetzt " .. Money(price) .. "  (Ziel " .. Money(target) .. ")")
    popup:Show()
    popup.hideAt = GetTime() + 8
    popup:SetScript("OnUpdate", function(self) if GetTime() > self.hideAt then self:Hide() end end)
end

local function Fire(a, price)
    local o = GK.DB().opt
    if o.alarmSound then GK.PlayAlarmSound() end
    if o.alarmChat then
        Print(Link(a.id) .. " ist jetzt " .. Money(price) .. " (Ziel " .. Money(a.target) .. ")")
    end
    if o.alarmPopup then Popup(a.id, price, a.target) end
end

local function Check()
    if not GoldKompassDB or not GK.DB().opt.alarm then return end
    for _, a in ipairs(List()) do
        local p = Price(a.id)
        if p then
            a.last = p
            -- time() statt GetTime(): firedAt wird gespeichert, GetTime() beginnt bei jedem Spielstart neu
            local fired = a.firedAt
            if fired and fired > time() then fired = nil end
            if p <= a.target and time() - (fired or 0) >= REPEAT_AFTER then
                a.firedAt = time()
                Fire(a, p)
            end
        end
    end
end

-- Befehle: /gk alarm ... ----------------------------------------------------
local function Parse(arg)
    local id = tonumber(arg:match("item:(%d+)")) or tonumber(arg:match("^(%d+)"))
    local gold = arg:gsub("|c%x+|Hitem:.-|h%[.-%]|h|r", ""):match("(%d+[%.,]?%d*)%s*$")
    gold = gold and tonumber((gold:gsub(",", ".")))
    return id, gold
end

local function Handle(arg)
    local sub, rest = arg:match("^(%S*)%s*(.-)$")
    sub = strlower(sub)
    local list = List()
    if sub == "add" or sub == "neu" then
        local id, gold = Parse(rest)
        if not id or not gold then
            Print("So: /gk alarm add [Item-Link per Shift-Klick] 150   (Wunschpreis in Gold)"); return
        end
        C_Item.RequestLoadItemDataByID(id)
        for _, a in ipairs(list) do if a.id == id then a.target = gold * 10000; Print("Ziel geaendert: " .. Link(id) .. " auf " .. Money(a.target)); return end end
        list[#list + 1] = { id = id, target = gold * 10000 }
        Print("Alarm gesetzt: " .. Link(id) .. " bei " .. Money(gold * 10000) .. " oder weniger.")
        Check()
    elseif sub == "del" or sub == "weg" then
        local n = tonumber(rest)
        local id = Parse(rest)
        for i, a in ipairs(list) do
            if i == n or (id and a.id == id) then table.remove(list, i); Print("Alarm entfernt."); return end
        end
        Print("Nicht gefunden. /gk alarm zeigt die Liste.")
    elseif sub == "test" then
        Fire({ id = 2589, target = 10000 }, 5000)
    else
        if #list == 0 then Print("Keine Alarme. /gk alarm add [Item] 150  setzt einen (Preis in Gold)."); return end
        for i, a in ipairs(list) do
            Print(string.format("%d. %s  Ziel %s  jetzt %s", i, Link(a.id), Money(a.target), a.last and Money(a.last) or "unbekannt"))
        end
        Print("Entfernen: /gk alarm del <Nummer>.  Ton testen: /gk alarm test")
    end
end

GK.RegisterCommand("alarm", Handle, "Preisalarm: alarm add [Item] 150, alarm del 1, alarm test")

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    C_Timer.NewTicker(CHECK_EVERY, Check)
    C_Timer.After(10, Check)
end)
