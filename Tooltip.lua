-- GoldKompass Tooltip: Maus ueber einen Gegenstand im kleinen Farm-Fenster zeigt den Gegenstands-Tooltip.
local GK = GoldKompass

local function ItemList()
    local fm = GK.farm
    local list = {}
    if not fm then return list end
    local min = (GK.DB().opt.minValue or 0) * 10000
    for id, n in pairs(fm.items) do
        local v = (fm.price[id] or 0) * n
        if v >= min then list[#list + 1] = { id = id, v = v } end
    end
    table.sort(list, function(a, b) return a.v > b.v end)
    return list
end

local function Setup()
    local h = GK.hud
    if not h or not h.rows then return end
    local list = ItemList()
    for i, r in ipairs(h.rows) do
        if not r.gkHit then
            local b = CreateFrame("Button", nil, h)
            b:SetPoint("TOPLEFT", r.name, "TOPLEFT", 0, 1)
            b:SetPoint("BOTTOMRIGHT", r.val, "BOTTOMRIGHT", 0, -1)
            b:SetFrameLevel(h:GetFrameLevel() + 5)
            b:RegisterForDrag("LeftButton")
            b:SetScript("OnDragStart", function() h:StartMoving() end)
            b:SetScript("OnDragStop", function() h:GetScript("OnDragStop")(h) end)
            b:SetScript("OnEnter", function(self)
                if not self.itemId then return end
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetItemByID(self.itemId)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            r.gkHit = b
        end
        local it = list[i]
        r.gkHit.itemId = it and it.id or nil
        r.gkHit:SetShown(it ~= nil)
    end
end

if type(GK.RefreshHud) == "function" then
    hooksecurefunc(GK, "RefreshHud", function() pcall(Setup) end)
end
