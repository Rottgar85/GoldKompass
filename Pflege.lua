-- GoldKompass Pflege: haelt die gespeicherten Daten klein (aeltere Tage und Sessions werden entfernt)
local GK = GoldKompass
local KEEP_DAYS = 400      -- Tageswerte so lange behalten
local KEEP_FARMS = 300     -- so viele Farm-Sessions behalten

local function Prune()
    local DB = GK.DB and GK.DB()
    if not DB then return end
    local cutoff = date("%Y-%m-%d", time() - KEEP_DAYS * 86400)
    local function Old(t)
        if type(t) ~= "table" then return end
        for day in pairs(t) do
            if type(day) == "string" and day < cutoff then t[day] = nil end
        end
    end
    Old(DB.days)
    Old(DB.gained)
    Old(DB.totalHist)
    if type(DB.charGained) == "table" then
        for _, perChar in pairs(DB.charGained) do Old(perChar) end
    end
    if type(DB.farms) == "table" then
        while #DB.farms > KEEP_FARMS do table.remove(DB.farms, 1) end
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    local ok = pcall(Prune)
    ev:UnregisterAllEvents()
    return ok
end)
