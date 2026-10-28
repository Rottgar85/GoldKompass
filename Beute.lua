-- GoldKompass Beute: Ton nur bei Bind-on-Equip-Beute (unabhaengig vom Farm-Rechner) + Absicherung der Farm-Liste
local GK = GoldKompass

-- Bind on Equip: nur dann gibt es einen Beute-Ton
function GK.IsBoE(id)
    local bind = select(14, C_Item.GetItemInfo(id))
    return bind == 2
end

local function Pat(s)
    s = s:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    s = s:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    return "^" .. s .. "$"
end
local PATS = {}
for _, g in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF" }) do
    if _G[g] then PATS[#PATS + 1] = { Pat(_G[g]), g:find("MULTIPLE") ~= nil } end
end

local function Parse(msg)
    for _, p in ipairs(PATS) do
        local a, b = msg:match(p[1])
        if a then
            if p[2] then return a, tonumber(b) or 1 end
            return a, 1
        end
    end
end

local function Handle(msg)
    local link, n = Parse(msg)
    if not link then return end
    local id = C_Item.GetItemInfoInstant(link)
    if not id then return end

    -- Item-Daten abwarten, dann Ton nur bei Bind on Equip
    C_Timer.After(0.6, function()
        local o = GK.DB() and GK.DB().opt
        if o and o.lootSound and GK.IsBoE(id) then GK.PlayAlarmSound() end
    end)

    -- Farm-Liste: fehlt das Item noch, jetzt eintragen. Hat es noch den Preis 0 (Item-Daten waren beim Looten nicht
    -- geladen), den Wert nachtragen, sonst fehlt er in Gold pro Stunde.
    C_Timer.After(1.2, function()
        local f = GK.farm
        if not f or not GK.DB().opt.farm then return end
        local _, _, _, _, _, _, _, _, _, _, sell, _, _, bindType = C_Item.GetItemInfo(id)
        if not f.items[id] then
            f.items[id] = n
            f.price[id] = GK.MarketPrice(id) or sell or 0
            f.value = f.value + f.price[id] * n
        elseif (f.price[id] or 0) == 0 then
            local count = f.items[id]
            if bindType == 1 and (sell or 0) > 0 then
                f.price[id] = sell
                f.money = f.money + sell * count
                f.soul = (f.soul or 0) + sell * count
            else
                local p = GK.MarketPrice(id) or sell or 0
                if p > 0 then
                    f.price[id] = p
                    f.value = f.value + p * count
                end
            end
        end
    end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_LOOT")
ev:SetScript("OnEvent", function(_, event, msg)
    if event == "PLAYER_LOGIN" then
        local o = GK.DB().opt
        if o.lootSound == nil then o.lootSound = true end
    elseif GK.DB() and not GK.IsSecret(msg) then
        Handle(msg)
    end
end)
