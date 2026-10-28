-- GoldKompass Eigene Routen: Routen selbst aufzeichnen, speichern, wählen, löschen. Ohne das Addon Routes nutzbar.
-- Daten: GoldKompassDB.myRoutes[kartenId][name] = { pts = { {x, y}, ... } } (Kartenkoordinaten 0 bis 1)
local GK = GoldKompass
local GOLD = "|cffffd100"
local function DB() return GK.DB() end
local print = function(...) return (GoldKompass.Out or _G.print)(...) end
local function Print(m) print(GOLD .. "GoldKompass|r: " .. m) end
local MAXPTS, STEP, LISTN = 300, 0.006, 6

local function CurMap() return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") end
local function MapName(id)
    local i = id and C_Map.GetMapInfo(id)
    return i and i.name or tostring(id)
end
local function Pos(map)
    if not map or not C_Map.GetPlayerMapPosition then return end
    local p = C_Map.GetPlayerMapPosition(map, "player")
    if not p then return end
    local x, y = p:GetXY()
    if x and y and (x > 0 or y > 0) then return x, y end
end
local function OwnRoute(sel)
    local m = sel and DB().myRoutes and DB().myRoutes[sel.map]
    return m and m[sel.name]
end

local rec = { map = nil, pts = {}, on = false }
local frame

local function Length()
    local len = 0
    for i = 2, #rec.pts do
        local a, b = rec.pts[i - 1], rec.pts[i]
        len = len + math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2)
    end
    return len
end

local function Update()
    if not frame then return end
    local sel = GK.routeSel
    frame.info:SetText(string.format("Karte: %s\nPunkte: %d (max. %d)   Länge: %.0f%% der Karte\nAufnahme: %s",
        rec.map and MapName(rec.map) or "-", #rec.pts, MAXPTS, Length() * 100,
        rec.on and "|cff66ff66läuft, einfach laufen|r" or "aus"))
    frame.toggle:SetText(rec.on and "Aufnahme stoppen" or "Aufnahme starten")
    local own = OwnRoute(sel)
    frame.del:SetEnabled(own ~= nil)

    local map = CurMap()
    local names = {}
    for n in pairs(map and DB().myRoutes and DB().myRoutes[map] or {}) do names[#names + 1] = n end
    table.sort(names)
    frame.listHead:SetText("Deine Routen in " .. MapName(map) .. (#names == 0 and ": noch keine" or ":"))
    for i, r in ipairs(frame.rows) do
        local n = names[i]
        if n then
            local on = sel and sel.map == map and sel.name == n
            r.text:SetText((on and (GOLD .. "> |r") or "   ") .. n .. "  (" .. #DB().myRoutes[map][n].pts .. " Punkte)")
            r.click = function() GK.routeSel = { map = map, name = n }; Update(); if GK.RefreshPlus then GK.RefreshPlus() end end
            r:Show()
        else
            r:Hide(); r.click = nil
        end
    end
end

local function AddPoint(force)
    local map = CurMap()
    if not map then Print("Hier gibt es keine Karte (Instanz?). Dort geht keine Route."); rec.on = false; return false end
    if rec.map and rec.map ~= map and #rec.pts > 0 then
        Print("Du hast die Karte gewechselt. Route erst speichern oder verwerfen.")
        rec.on = false
        return false
    end
    local x, y = Pos(map)
    if not x then if force then Print("Position ist hier nicht abrufbar.") end return false end
    local last = rec.pts[#rec.pts]
    if last and not force and math.sqrt((last[1] - x) ^ 2 + (last[2] - y) ^ 2) < STEP then return false end
    if #rec.pts >= MAXPTS then rec.on = false; Print("Maximal " .. MAXPTS .. " Punkte erreicht."); return false end
    rec.map = map
    rec.pts[#rec.pts + 1] = { math.floor(x * 10000 + 0.5) / 10000, math.floor(y * 10000 + 0.5) / 10000 }
    return true
end

local function Build()
    if frame then return end
    local f = CreateFrame("Frame", "GoldKompassRouteEditor", UIParent, "BackdropTemplate")
    f:SetSize(330, 350); f:SetPoint("CENTER")
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.96); f:SetBackdropBorderColor(0.55, 0.45, 0, 1)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "GoldKompassRouteEditor")
    f:Hide()

    local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 10, -9); t:SetText("GoldKompass · Eigene Route")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24); close:SetPoint("TOPRIGHT", 0, 0)

    f.info = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.info:SetPoint("TOPLEFT", 12, -32); f.info:SetJustifyH("LEFT")

    local function Btn(text, w)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(w, 22); b:SetText(text)
        return b
    end
    f.toggle = Btn("Aufnahme starten", 140); f.toggle:SetPoint("TOPLEFT", 10, -76)
    f.toggle:SetScript("OnClick", function()
        if rec.on then rec.on = false
        elseif AddPoint(false) or #rec.pts > 0 then rec.on = true end
        Update()
    end)
    local pt = Btn("Punkt setzen", 100); pt:SetPoint("LEFT", f.toggle, "RIGHT", 4, 0)
    pt:SetScript("OnClick", function() AddPoint(true); Update() end)
    local undo = Btn("Letzten weg", 100); undo:SetPoint("TOPLEFT", 10, -102)
    undo:SetScript("OnClick", function() table.remove(rec.pts); if #rec.pts == 0 then rec.map = nil end Update() end)
    local clear = Btn("Verwerfen", 100); clear:SetPoint("LEFT", undo, "RIGHT", 4, 0)
    clear:SetScript("OnClick", function() rec.pts, rec.map, rec.on = {}, nil, false; Update() end)

    local nl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nl:SetPoint("TOPLEFT", 12, -142); nl:SetText("Name")
    local name = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    name:SetSize(170, 18); name:SetAutoFocus(false); name:SetMaxLetters(40)
    name:SetPoint("LEFT", nl, "RIGHT", 10, 0); name:SetScript("OnEscapePressed", name.ClearFocus)
    local save = Btn("Speichern", 80); save:SetPoint("LEFT", name, "RIGHT", 6, 0)
    save:SetScript("OnClick", function()
        local n = strtrim(name:GetText())
        if n == "" then Print("Bitte einen Namen für die Route eintragen."); return end
        if #rec.pts < 2 or not rec.map then Print("Eine Route braucht mindestens zwei Punkte."); return end
        local d = DB()
        d.myRoutes = d.myRoutes or {}
        d.myRoutes[rec.map] = d.myRoutes[rec.map] or {}
        d.myRoutes[rec.map][n] = { pts = rec.pts, made = date("%Y-%m-%d") }
        GK.routeSel = { map = rec.map, name = n }
        Print("Route gespeichert: " .. GOLD .. n .. "|r (" .. #rec.pts .. " Punkte in " .. MapName(rec.map) .. "). Sie ist für den nächsten Farm-Start gewählt.")
        rec.pts, rec.map, rec.on = {}, nil, false
        name:SetText(""); name:ClearFocus()
        Update()
        if GK.RefreshPlus then GK.RefreshPlus() end
    end)

    f.listHead = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.listHead:SetPoint("TOPLEFT", 12, -176)
    f.rows = {}
    for i = 1, LISTN do
        local r = CreateFrame("Button", nil, f)
        r:SetPoint("TOPLEFT", 10, -192 - (i - 1) * 18); r:SetPoint("TOPRIGHT", -10, -192 - (i - 1) * 18); r:SetHeight(17)
        local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.08)
        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.text:SetPoint("LEFT", 4, 0); r.text:SetJustifyH("LEFT")
        r:SetScript("OnClick", function(self) if self.click then self.click() end end)
        f.rows[i] = r
    end

    f.del = Btn("Gewählte Route löschen", 170); f.del:SetPoint("BOTTOMLEFT", 10, 10)
    f.del:SetScript("OnClick", function()
        local sel = GK.routeSel
        if OwnRoute(sel) then
            DB().myRoutes[sel.map][sel.name] = nil
            Print("Route gelöscht: " .. sel.name)
            GK.routeSel = nil
            Update()
            if GK.RefreshPlus then GK.RefreshPlus() end
        end
    end)
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("LEFT", f.del, "RIGHT", 8, 0); hint:SetText("Route anklicken = Auswahl"); hint:SetTextColor(0.6, 0.6, 0.6)

    local acc = 0
    f:SetScript("OnUpdate", function(_, dt)
        if not rec.on then return end
        acc = acc + dt
        if acc < 0.5 then return end
        acc = 0
        if AddPoint(false) then Update() end
    end)
    f:SetScript("OnShow", Update)
    frame = f
end

function GK.OpenRouteEditor()
    Build(); frame:Show(); Update()
end

-- Eigene Route beim Farm-Start übernehmen (Statistik läuft über die Routen-Anbindung in Plus.lua) -----------
local origStart = GK.FarmStart
function GK.FarmStart(name)
    local had = GK.farm
    origStart(name)
    if had or not GK.farm or GK.farm.route then return end
    local sel, map = GK.routeSel, CurMap()
    if sel and map and sel.map == map and OwnRoute(sel) then
        GK.farm.route = { map = map, name = sel.name }
        DB().routeLast = DB().routeLast or {}
        DB().routeLast[map] = sel.name
        Print("Eigene Route für diese Session: " .. GOLD .. sel.name .. "|r")
        local h = GK.hud
        if h and h.title then h.title:SetText(GK.farm.name .. " · " .. sel.name) end
    end
end

-- Knopf im Plus-Fenster -------------------------------------------------------------------------
local origBuildPlus = GK.BuildPlus
function GK.BuildPlus()
    origBuildPlus()
    local f = GK.plus
    if f and not f.newRoute then
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(100, 20); b:SetText("Eigene Route")
        b:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -5)
        b:SetScript("OnClick", function() GK.OpenRouteEditor() end)
        f.newRoute = b
    end
end

GK.RegisterCommand({ "routenbau", "neueroute" }, function() GK.OpenRouteEditor() end, "Eigene Route aufzeichnen")

-- Hauptfenster schließen schließt auch Plus, Optionen und Routen-Fenster. Das kleine Farm-Fenster (HUD) bleibt. ----
local function HookMain()
    local m = GK.frame
    if not m or m.gkCloseHooked then return end
    m.gkCloseHooked = true
    m:HookScript("OnHide", function()
        if GK.navSwitching then return end -- Seitenwechsel im Ein-Fenster-Modus (Fenster.lua)
        for _, w in ipairs({ GK.plus, GK.optFrame, _G.GoldKompassRouteEditor }) do
            if w and w ~= GK.hud and w.IsShown and w:IsShown() then w:Hide() end
        end
    end)
end
local origBuildMain = GK.Build
function GK.Build()
    origBuildMain()
    HookMain()
end
HookMain()

-- Routenpunkte auf der Weltkarte ---------------------------------------------------------------------------------
local function Draw(o, pts, r, g, b, w, h, startAt)
    for i, p in ipairs(pts) do
        local d = o.dots[startAt + i]
        if not d then
            d = o:CreateTexture(nil, "OVERLAY"); d.isDot = true
            o.dots[startAt + i] = d
        end
        d:SetTexture("Interface\\Buttons\\WHITE8x8")
        d:SetColorTexture(r, g, b, 1); d:SetSize(i == 1 and 9 or 5, i == 1 and 9 or 5)
        d:ClearAllPoints(); d:SetPoint("CENTER", o, "TOPLEFT", p[1] * w, -p[2] * h); d:Show()
        if i > 1 then
            local l = o.lines[startAt + i]
            if not l then l = o:CreateLine(nil, "ARTWORK"); o.lines[startAt + i] = l end
            local q = pts[i - 1]
            l:SetThickness(2); l:SetColorTexture(r, g, b, 0.8)
            l:SetStartPoint("TOPLEFT", o, q[1] * w, -q[2] * h)
            l:SetEndPoint("TOPLEFT", o, p[1] * w, -p[2] * h); l:Show()
        end
    end
    return startAt + #pts
end

-- Neu zeichnen beim Oeffnen der Karte und beim Kartenwechsel (laufend aktualisiert der Takt weiter unten)
local mapEv = CreateFrame("Frame")
mapEv:RegisterEvent("PLAYER_LOGIN")
mapEv:SetScript("OnEvent", function()
    if not WorldMapFrame then return end
    WorldMapFrame:HookScript("OnShow", function() GK.DrawRouteOnMap() end)
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function() GK.DrawRouteOnMap() end)
end)

-- Verbesserung: Punkte auch auf anderen Kartenebenen (Unterzone/Zone) und auf der Minimap ---------------------------
local cache = {}
local function Conv(pts, from, to)
    if from == to then return pts end
    local key = from .. ">" .. to
    local c = cache[pts]
    if c and c.key == key and c.n == #pts then return c.out end
    local out = {}
    for i, p in ipairs(pts) do
        local cont, wp = C_Map.GetWorldPosFromMapPos(from, CreateVector2D(p[1], p[2]))
        if not cont then return end
        local v = C_Map.GetMapPosFromWorldPos(cont, wp, to)
        if not v then return end
        local x, y = v:GetXY()
        out[i] = { x, y }
    end
    cache[pts] = { key = key, n = #pts, out = out }
    return out
end

-- aktuell anzuzeigende Linien: { {pts, mapId, r, g, b}, ... }
local function Sources()
    local s = {}
    local sel = GK.routeSel
    local rt = OwnRoute(sel)
    if rt then s[#s + 1] = { rt.pts, sel.map, 1, 0.82, 0 } end
    if rec.map and #rec.pts > 0 then s[#s + 1] = { rec.pts, rec.map, 0.4, 1, 0.4 } end
    return s
end

local RAD_OUT = { [0] = 233.3, 200, 166.7, 133.3, 100, 66.7 }
local RAD_IN = { [0] = 150, 120, 90, 60, 40, 25 }
local mini = { dots = {} }
local function MiniUpdate()
    local sources = Sources()
    local map = CurMap()
    for _, d in ipairs(mini.dots) do d:Hide() end
    if #sources == 0 or not map or not Minimap:IsVisible() then return end
    local px, py = Pos(map)
    if not px then return end
    local W, H = C_Map.GetMapWorldSize(map)
    if not W or W <= 0 then return end
    local z = Minimap:GetZoom() or 0
    local rad = (IsIndoors() and RAD_IN or RAD_OUT)[z] or 150
    local half = Minimap:GetWidth() / 2
    local rot = GetCVar("rotateMinimap") == "1"
    local face = rot and GetPlayerFacing() or 0
    local sinF, cosF = math.sin(face), math.cos(face)
    local k = 0
    for _, src in ipairs(sources) do
        local pts = Conv(src[1], src[2], map)
        if pts then
            for _, p in ipairs(pts) do
                local dx, dy = (p[1] - px) * W, (p[2] - py) * H
                if rot then dx, dy = dx * cosF - dy * sinF, dx * sinF + dy * cosF end
                if dx * dx + dy * dy < rad * rad * 0.9 then
                    k = k + 1
                    local d = mini.dots[k]
                    if not d then
                        d = mini.frame:CreateTexture(nil, "OVERLAY")
                        d:SetTexture("Interface\\Buttons\\WHITE8x8"); d:SetSize(4, 4)
                        mini.dots[k] = d
                    end
                    d:SetColorTexture(src[3], src[4], src[5], 1)
                    d:ClearAllPoints()
                    d:SetPoint("CENTER", Minimap, "CENTER", dx / rad * half, -dy / rad * half)
                    d:Show()
                end
            end
        end
    end
end

local miniEv = CreateFrame("Frame")
miniEv:RegisterEvent("PLAYER_LOGIN")
miniEv:SetScript("OnEvent", function()
    mini.frame = CreateFrame("Frame", nil, Minimap)
    mini.frame:SetAllPoints(Minimap); mini.frame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    local acc = 0
    miniEv:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.15 then return end
        acc = 0
        local ok, err = pcall(MiniUpdate)
        if not ok and not GK.miniErr then GK.miniErr = true; Print("Minimap-Anzeige der Route: Fehler " .. tostring(err)) end
    end)
end)

-- Kartenebene und Linien auf der Minimap ------------------------------------------------------------------------------
local layer
local function MapLayer()
    if layer then return layer end
    if not WorldMapFrame then return end
    local parent = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
    if not parent and WorldMapFrame.GetCanvas then parent = WorldMapFrame:GetCanvas() end
    if not parent then return end
    local o = CreateFrame("Frame", "GoldKompassMapLayer", parent)
    o:SetAllPoints(parent)
    o:SetFrameStrata("HIGH"); o:SetFrameLevel(500)
    o.dots, o.lines = {}, {}
    layer = o
    return o
end

function GK.DrawRouteOnMap(debug)
    local ok, err = pcall(function()
        local o = MapLayer()
        if not o then if debug then Print("Debug: keine Kartenfläche gefunden") end return end
        for _, d in pairs(o.dots) do d:Hide() end
        for _, l in pairs(o.lines) do l:Hide() end
        if not DB() or not WorldMapFrame:IsShown() then return end
        local map = WorldMapFrame:GetMapID()
        local w, h = o:GetWidth(), o:GetHeight()
        local src = Sources()
        if debug then Print(string.format("Debug: Karte %s, Fläche %.0fx%.0f, Quellen %d, Fenster %s", tostring(map), w or 0, h or 0, #src, tostring(o:IsVisible()))) end
        if not map or not w or w <= 0 then return end
        local n = 0
        for _, s in ipairs(src) do
            local pts = Conv(s[1], s[2], map)
            if debug then Print("Debug: Route " .. #s[1] .. " Punkte, umgerechnet: " .. tostring(pts and #pts or "fehlgeschlagen") .. " (Routenkarte " .. tostring(s[2]) .. ")") end
            if pts then n = Draw(o, pts, s[3], s[4], s[5], w, h, n + 1) end
        end
    end)
    if not ok then
        if debug or not GK.routeDrawErr2 then GK.routeDrawErr2 = true; Print("Kartenanzeige der Route: Fehler " .. tostring(err)) end
    end
end

local mapTick = CreateFrame("Frame")
local macc = 0
mapTick:SetScript("OnUpdate", function(_, dt)
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    macc = macc + dt
    if macc < 0.5 then return end
    macc = 0
    GK.DrawRouteOnMap()
end)

-- Linien zwischen den Punkten auf der Minimap
local mlines = {}
local function MiniLines()
    for _, l in ipairs(mlines) do l:Hide() end
    local sources, map = Sources(), CurMap()
    if #sources == 0 or not map or not mini.frame or not Minimap:IsVisible() then return end
    local px, py = Pos(map)
    local W, H = C_Map.GetMapWorldSize(map)
    if not px or not W or W <= 0 then return end
    local rad = (IsIndoors() and RAD_IN or RAD_OUT)[Minimap:GetZoom() or 0] or 150
    local half = Minimap:GetWidth() / 2
    local rot = GetCVar("rotateMinimap") == "1"
    local face = rot and GetPlayerFacing() or 0
    local sinF, cosF = math.sin(face), math.cos(face)
    local k = 0
    for _, src in ipairs(sources) do
        local pts = Conv(src[1], src[2], map)
        local prev
        if pts then
            for _, p in ipairs(pts) do
                local dx, dy = (p[1] - px) * W, (p[2] - py) * H
                if rot then dx, dy = dx * cosF - dy * sinF, dx * sinF + dy * cosF end
                local inside = dx * dx + dy * dy < rad * rad * 0.9
                local cur = { dx / rad * half, -dy / rad * half }
                if prev and inside and prev.inside then
                    k = k + 1
                    local l = mlines[k]
                    if not l then l = mini.frame:CreateLine(nil, "ARTWORK"); mlines[k] = l end
                    l:SetThickness(1.5); l:SetColorTexture(src[3], src[4], src[5], 0.85)
                    l:SetStartPoint("CENTER", Minimap, prev[1], prev[2])
                    l:SetEndPoint("CENTER", Minimap, cur[1], cur[2]); l:Show()
                end
                cur.inside = inside
                prev = cur
            end
        end
    end
end
local lineTick = CreateFrame("Frame")
local lacc = 0
lineTick:SetScript("OnUpdate", function(_, dt)
    lacc = lacc + dt
    if lacc < 0.15 then return end
    lacc = 0
    local ok, err = pcall(MiniLines)
    if not ok and not GK.miniErr2 then GK.miniErr2 = true; Print("Minimap-Linien: Fehler " .. tostring(err)) end
end)

GK.RegisterCommand("routendebug", function()
    if WorldMapFrame and not WorldMapFrame:IsShown() then Print("Debug: Weltkarte erst öffnen, dann den Befehl nochmal eingeben.") end
    GK.DrawRouteOnMap(true)
end)
