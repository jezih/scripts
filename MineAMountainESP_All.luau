local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TARGET_PLACE = 125927821145949
if game.PlaceId ~= TARGET_PLACE then
    print("wrong game")
    notify("Wrong Game", "This script only works in Mine a Mountain", 4)
    return
end

if not _G.__oreEspFilter and not _G.__espPrintFilter then
    _G.__oreEspFilter = true
    _G.__espPrintFilter = true
    local origPrint = print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        local msg = table.concat(parts, " ")
        if msg:find("InputBegan") or msg:find("IB key") then return end
        origPrint(...)
    end
end

local lp = Players.LocalPlayer

if _G.oreEsp then _G.oreEsp.stop(); _G.oreEsp = nil end
if _G.boulderEsp then _G.boulderEsp.stop(); _G.boulderEsp = nil end
if _G.espUI then _G.espUI.stop(); _G.espUI = nil end

-- ============================================================
-- MY UI LIB (Drawing-based): window + toggle + dropdown
-- ============================================================
local DrawUI = {}
DrawUI.controls = {}
DrawUI.allObjs = {}
DrawUI.w = 244
DrawUI.x = 0
DrawUI.y = 0
DrawUI.titleText = "MENU"
DrawUI.visible = true
DrawUI.dirty = true
DrawUI.rows = {}
DrawUI.drag = nil
DrawUI.running = true
local ROW_H = 24
local TITLE_H = 30
local PAD = 10
local R = 10
local C = {
    bg       = Color3.fromRGB(8, 18, 13),
    scan     = Color3.fromRGB(0, 0, 0),
    border   = Color3.fromRGB(120, 255, 150),
    titlebar = Color3.fromRGB(70, 210, 130),
    row      = Color3.fromRGB(14, 30, 22),
    divider  = Color3.fromRGB(50, 110, 80),
    text     = Color3.fromRGB(232, 255, 242),
    muted    = Color3.fromRGB(160, 215, 180),
    accent   = Color3.fromRGB(120, 255, 150),
    on       = Color3.fromRGB(120, 220, 255),
    onGlow   = Color3.fromRGB(120, 220, 255),
    off      = Color3.fromRGB(74, 96, 84),
    knob     = Color3.fromRGB(246, 248, 252),
    optSel   = Color3.fromRGB(22, 54, 74),
    optBg    = Color3.fromRGB(12, 26, 19),
    close    = Color3.fromRGB(255, 120, 120),
    footer   = Color3.fromRGB(155, 210, 175),
}
local FONT_TITLE = 5
local FONT_BODY  = 5
local FONT_MONO  = 5

local function newSquare(color, transparency, filled, rounding)
    local d = Drawing.new("Square")
    d.Color = color or C.bg
    d.Transparency = transparency or 0
    d.Filled = filled ~= false
    d.Thickness = 1
    if rounding then d.Rounding = rounding end
    d.Visible = false
    DrawUI.allObjs[#DrawUI.allObjs + 1] = d
    return d
end

local function newCircle(color, radius)
    local d = Drawing.new("Circle")
    d.Color = color or C.knob
    d.Radius = radius or 5
    d.Filled = true
    d.Thickness = 1
    d.Visible = false
    DrawUI.allObjs[#DrawUI.allObjs + 1] = d
    return d
end

local function newText(txt, size, color, center)
    local d = Drawing.new("Text")
    d.Text = txt or ""
    d.Size = size or 13
    d.Color = color or Color3.fromRGB(235, 235, 235)
    d.Center = center or false
    d.Outline = true
    d.Font = FONT_BODY
    d.Visible = false
    DrawUI.allObjs[#DrawUI.allObjs + 1] = d
    return d
end

function DrawUI.toggle(id, label, default)
    local ctl = {
        type = "toggle",
        id = id,
        label = label,
        value = default and true or false,
        rowBg = newSquare(C.row, 0, true, 6),
        labelTxt = newText(label, 13, C.text, false),
        tagBg = newSquare(C.off, 0, true, 5),
        stateTxt = newText("OFF", 12, C.muted, true),
        divider = newSquare(C.divider, 0, true),
    }
    DrawUI.controls[#DrawUI.controls + 1] = ctl
    DrawUI.dirty = true
    return ctl
end

function DrawUI.dropdown(id, label, options, defaultIdx)
    local idx = 1
    if defaultIdx and defaultIdx >= 1 and defaultIdx <= #options then idx = defaultIdx end
    local ctl = {
        type = "dropdown",
        id = id,
        label = label,
        options = options,
        value = idx,
        open = false,
        rowBg = newSquare(C.row, 0, true, 6),
        labelTxt = newText(label, 13, C.text, false),
        selTxt = newText(options[idx], 13, C.on, false),
        arrow = newText("v", 12, C.accent, true),
        optBgs = {},
        optTexts = {},
        divider = newSquare(C.divider, 0, true),
    }
    for i = 1, #options do
        ctl.optBgs[i] = newSquare(C.optBg, 0, true, 4)
        ctl.optTexts[i] = newText(options[i], 13, C.text, false)
    end
    DrawUI.controls[#DrawUI.controls + 1] = ctl
    DrawUI.dirty = true
    return ctl
end

function DrawUI.val(id, default)
    for _, ctl in ipairs(DrawUI.controls) do
        if ctl.id == id then return ctl.value end
    end
    return default
end

function DrawUI.option(id, defaultText)
    for _, ctl in ipairs(DrawUI.controls) do
        if ctl.id == id and ctl.type == "dropdown" then
            return ctl.options[ctl.value] or defaultText
        end
    end
    return defaultText
end

function DrawUI.set(id, v)
    for _, ctl in ipairs(DrawUI.controls) do
        if ctl.id == id then
            if ctl.type == "toggle" then
                ctl.value = v and true or false
            elseif ctl.type == "dropdown" then
                if type(v) == "number" and v >= 1 and v <= #ctl.options then ctl.value = v end
            end
            DrawUI.draw()
            return
        end
    end
end

function DrawUI.draw()
    for _, o in ipairs(DrawUI.allObjs) do o.Visible = false end
    if not DrawUI.running or not DrawUI.bg then return end
    if not DrawUI.visible then
        local tw, th = 76, 22
        DrawUI.reopenBg.Position = Vector2.new(DrawUI.x, DrawUI.y)
        DrawUI.reopenBg.Size = Vector2.new(tw, th)
        DrawUI.reopenBg.Visible = true
        DrawUI.reopenBorder.Position = Vector2.new(DrawUI.x, DrawUI.y)
        DrawUI.reopenBorder.Size = Vector2.new(tw, th)
        DrawUI.reopenBorder.Visible = true
        DrawUI.reopenDot.Position = Vector2.new(DrawUI.x + 14, DrawUI.y + th * 0.5)
        DrawUI.reopenDot.Visible = true
        DrawUI.reopenTxt.Position = Vector2.new(DrawUI.x + tw * 0.5 + 6, DrawUI.y + th * 0.5)
        DrawUI.reopenTxt.Visible = true
        DrawUI.rows = { { kind = "reopen", x = DrawUI.x, y = DrawUI.y, w = tw, h = th } }
        DrawUI.dirty = false
        return
    end
    local x, w = DrawUI.x, DrawUI.w
    local y = DrawUI.y
    local rows = {}
    DrawUI.titleBar.Position = Vector2.new(x, y)
    DrawUI.titleBar.Size = Vector2.new(w, TITLE_H)
    DrawUI.titleBar.Visible = true
    DrawUI.titleDot.Position = Vector2.new(x + 16, y + TITLE_H * 0.5)
    DrawUI.titleDot.Visible = true
    DrawUI.title.Position = Vector2.new(x + w * 0.5 + 6, y + TITLE_H * 0.5)
    DrawUI.title.Text = DrawUI.titleText
    DrawUI.title.Visible = true
    DrawUI.closeX.Position = Vector2.new(x + w - 16, y + TITLE_H * 0.5)
    DrawUI.closeX.Visible = true
    rows[#rows + 1] = { kind = "close", x = x + w - 30, y = y, w = 30, h = TITLE_H }
    rows[#rows + 1] = { kind = "title", x = x, y = y, w = w - 30, h = TITLE_H }
    y = y + TITLE_H
    local first = true
    for _, ctl in ipairs(DrawUI.controls) do
        if not first then
            local div = ctl.divider
            div.Position = Vector2.new(x + PAD, y - 1)
            div.Size = Vector2.new(w - PAD * 2, 1)
            div.Visible = true
        end
        first = false
        if ctl.type == "toggle" then
            ctl.rowBg.Position = Vector2.new(x, y)
            ctl.rowBg.Size = Vector2.new(w, ROW_H)
            ctl.rowBg.Visible = true
            ctl.labelTxt.Position = Vector2.new(x + PAD, y + ROW_H * 0.5 - 7)
            ctl.labelTxt.Text = ctl.label
            ctl.labelTxt.Visible = true
            local tw = 46
            local th = 18
            local tx = x + w - tw - PAD
            local ty = y + ROW_H * 0.5 - th * 0.5
            ctl.tagBg.Position = Vector2.new(tx, ty)
            ctl.tagBg.Size = Vector2.new(tw, th)
            ctl.tagBg.Color = ctl.value and Color3.fromRGB(28, 44, 70) or C.off
            ctl.tagBg.Visible = true
            ctl.stateTxt.Text = ctl.value and "ON" or "OFF"
            ctl.stateTxt.Color = ctl.value and Color3.fromRGB(130, 190, 255) or C.close
            ctl.stateTxt.Position = Vector2.new(tx + tw * 0.5, ty + th * 0.5)
            ctl.stateTxt.Visible = true
            rows[#rows + 1] = { kind = "toggle", ctl = ctl, x = x, y = y, w = w, h = ROW_H }
            y = y + ROW_H
        else
            ctl.rowBg.Position = Vector2.new(x, y)
            ctl.rowBg.Size = Vector2.new(w, ROW_H)
            ctl.rowBg.Visible = true
            ctl.labelTxt.Position = Vector2.new(x + PAD, y + ROW_H * 0.5 - 7)
            ctl.labelTxt.Text = ctl.label
            ctl.labelTxt.Visible = true
            ctl.selTxt.Text = ctl.options[ctl.value] or ""
            local ok2, tb = pcall(function() return ctl.selTxt.TextBounds end)
            local bw = (ok2 and tb and tb.X) or 0
            if bw <= 0 then bw = #ctl.selTxt.Text * 7 end
            ctl.selTxt.Position = Vector2.new((x + w - 24) - bw, y + ROW_H * 0.5 - 7)
            ctl.selTxt.Visible = true
            ctl.arrow.Text = ctl.open and "^" or "v"
            ctl.arrow.Position = Vector2.new(x + w - 12, y + ROW_H * 0.5 - 7)
            ctl.arrow.Visible = true
            rows[#rows + 1] = { kind = "dropdown", ctl = ctl, x = x, y = y, w = w, h = ROW_H }
            y = y + ROW_H
            if ctl.open then
                for i = 1, #ctl.options do
                    local oy = y + (i - 1) * ROW_H
                    local bg = ctl.optBgs[i]
                    bg.Position = Vector2.new(x + 8, oy)
                    bg.Size = Vector2.new(w - 16, ROW_H)
                    bg.Color = (i == ctl.value) and C.optSel or C.optBg
                    bg.Visible = true
                    local ot = ctl.optTexts[i]
                    ot.Position = Vector2.new(x + 18, oy + ROW_H * 0.5 - 7)
                    ot.Color = (i == ctl.value) and C.on or C.text
                    ot.Visible = true
                    rows[#rows + 1] = { kind = "opt", ctl = ctl, idx = i, x = x + 8, y = oy, w = w - 16, h = ROW_H }
                end
                y = y + #ctl.options * ROW_H
            end
        end
    end
    y = y + 6
    DrawUI.footer.Position = Vector2.new(x + w * 0.5, y + 9)
    DrawUI.footer.Visible = true
    local totalH = (y + 18) - DrawUI.y
    DrawUI.bg.Position = Vector2.new(x, DrawUI.y)
    DrawUI.bg.Size = Vector2.new(w, totalH)
    DrawUI.bg.Visible = true
    DrawUI.border.Position = Vector2.new(x, DrawUI.y)
    DrawUI.border.Size = Vector2.new(w, totalH)
    DrawUI.border.Visible = true
    local sn = 0
    for sy = DrawUI.y + 2, DrawUI.y + totalH - 2, 3 do
        sn = sn + 1
        if sn > #DrawUI.scan then break end
        local ln = DrawUI.scan[sn]
        ln.From = Vector2.new(x + 2, sy)
        ln.To = Vector2.new(x + w - 2, sy)
        ln.Transparency = 0.5
        ln.Visible = true
    end
    for i = sn + 1, #DrawUI.scan do DrawUI.scan[i].Visible = false end
    DrawUI.rows = rows
    DrawUI.dirty = false
end

function DrawUI.init(title)
    DrawUI.titleText = title
    DrawUI.bg = newSquare(C.bg, 0.45, true, R)
    DrawUI.border = newSquare(C.border, 0, false, R)
    DrawUI.border.Thickness = 1.5
    DrawUI.border.ZIndex = 5
    DrawUI.titleBar = newSquare(C.titlebar, 0.32, true, R)
    pcall(function() DrawUI.titleBar.Corner = "Top" end)
    DrawUI.titleDot = newCircle(C.accent, 4)
    DrawUI.title = newText(title, 15, Color3.fromRGB(200, 255, 215), true)
    DrawUI.title.Font = FONT_TITLE
    DrawUI.title.Outline = true
    DrawUI.closeX = newText("X", 14, C.close, true)
    DrawUI.footer = newText("Drag bar  •  [End] hide", 11, C.footer, true)
    DrawUI.footer.Font = FONT_MONO
    DrawUI.scan = {}
    for i = 1, 90 do
        local ln = Drawing.new("Line")
        ln.Color = C.scan
        ln.Transparency = 0.5
        ln.Thickness = 1
        ln.ZIndex = 4
        ln.Visible = false
        DrawUI.allObjs[#DrawUI.allObjs + 1] = ln
        DrawUI.scan[i] = ln
    end
    DrawUI.reopenTxt = newText("MENU", 13, Color3.fromRGB(190, 255, 210), true)
    DrawUI.reopenBg = newSquare(C.bg, 0.4, true, 6)
    DrawUI.reopenBorder = newSquare(C.border, 0, false, 6)
    DrawUI.reopenBorder.Thickness = 1.5
    DrawUI.reopenDot = newCircle(C.accent, 3)
    local cam = workspace:FindFirstChild("Camera")
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    DrawUI.x = (vp.X - DrawUI.w) * 0.5
    DrawUI.y = (vp.Y - 200) * 0.5
    DrawUI.dirty = true
end

function DrawUI.handleClick(mx, my)
    if not DrawUI.running or not DrawUI.rows then return end
    for _, r in ipairs(DrawUI.rows) do
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            if r.kind == "reopen" then
                DrawUI.visible = true
                DrawUI.draw()
            elseif r.kind == "close" then
                DrawUI.visible = false
                DrawUI.draw()
            elseif r.kind == "title" then
                DrawUI.drag = { ox = mx - DrawUI.x, oy = my - DrawUI.y }
            elseif r.kind == "toggle" then
                r.ctl.value = not r.ctl.value
                DrawUI.draw()
            elseif r.kind == "dropdown" then
                r.ctl.open = not r.ctl.open
                DrawUI.draw()
            elseif r.kind == "opt" then
                r.ctl.value = r.idx
                r.ctl.open = false
                DrawUI.draw()
            end
            return
        end
    end
end

local uiConn
local lastDown = false
local mouse = lp:GetMouse()
uiConn = RunService.RenderStepped:Connect(function(dt)
    if not DrawUI.running then return end
    local down = false
    pcall(function() down = ismouse1pressed() end)
    DrawUI._dot = (DrawUI._dot or 0) + (dt or 0) * 3
    local p = 0.5 + 0.5 * math.sin(DrawUI._dot)
    pcall(function()
        local col = Color3.fromRGB(120 + p * 80, 255, 150 + p * 50)
        if DrawUI.visible and DrawUI.titleDot then
            DrawUI.titleDot.Radius = 3 + p * 2
            DrawUI.titleDot.Color = col
        elseif DrawUI.reopenDot then
            DrawUI.reopenDot.Radius = 2.5 + p * 1.5
            DrawUI.reopenDot.Color = col
        end
    end)
    if DrawUI.drag then
        if down then
            if mouse then
                DrawUI.x = mouse.X - DrawUI.drag.ox
                DrawUI.y = mouse.Y - DrawUI.drag.oy
                DrawUI.draw()
            end
        else
            DrawUI.drag = nil
            DrawUI.dirty = true
        end
    end
    if down and not lastDown then
        if mouse then DrawUI.handleClick(mouse.X, mouse.Y) end
    end
    lastDown = down
    local endNow = false
    pcall(function() endNow = iskeypressed(0x23) end)
    if endNow and not DrawUI._endPrev then
        DrawUI.visible = not DrawUI.visible
        DrawUI.dirty = true
    end
    DrawUI._endPrev = endNow
    if DrawUI.dirty then
        DrawUI.draw()
    end
end)

-- ===== BUILD MENU =====
DrawUI.init("Mine a Mountain ESP")
DrawUI.toggle("ore_enabled", "Ore ESP", true)
DrawUI.toggle("boulder_enabled", "Boulder ESP", true)
DrawUI.dropdown("ore_range", "Ore Range", { "200", "350", "500", "750", "1000" }, 2)
DrawUI.dropdown("boulder_range", "Boulder Range", { "200", "350", "500", "750", "1000" }, 2)
DrawUI.dropdown("ore_rarity", "Ore Rarity", { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Empyrean", "Pulsar", "Quasar" }, 1)

local menuKeyConn
local function stopUI()
    DrawUI.running = false
    if uiConn then uiConn:Disconnect() end
    if menuKeyConn then menuKeyConn:Disconnect() end
    for _, o in ipairs(DrawUI.allObjs) do
        pcall(function() o:Remove() end)
    end
end
_G.espUI = { stop = stopUI }

-- ===== CRYSTAL ESP =====
do
    local POOL = 64
    local nodes = {}
    local pool = {}
    local conn
    local running = true
    local tierColor = {}
    local tierColorReady = false

    for i = 1, POOL do
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Visible = false
        local tag = Drawing.new("Text")
        tag.Size = 12
        tag.Center = true
        tag.Outline = true
        tag.Visible = false
        pool[i] = { box = box, tag = tag }
    end

    task.spawn(function()
        while running do
            local out = {}
            local Things = game.Workspace:FindFirstChild("Things")
            local Crystals = Things and Things:FindFirstChild("Crystals")
            if Crystals and DrawUI.val("ore_enabled", true) then
                local range = tonumber(DrawUI.option("ore_range", "350")) or 350
                local filter = DrawUI.option("ore_rarity", "All")
                if not tierColorReady then
                    for _, c in ipairs(Crystals:GetChildren()) do
                        local t = c:GetAttribute("Tier")
                        if t and not tierColor[t] then
                            tierColor[t] = Color3.fromRGB(
                                c:GetAttribute("TierColorR") or 255,
                                c:GetAttribute("TierColorG") or 255,
                                c:GetAttribute("TierColorB") or 255)
                        end
                        local seen = 0
                        for _ in pairs(tierColor) do seen = seen + 1 end
                        if seen >= 9 then break end
                    end
                    tierColorReady = true
                end
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local myPos = root and root.Position
                local myPosX, myPosY, myPosZ = myPos and myPos.X, myPos and myPos.Y, myPos and myPos.Z
                local myPosNum = myPos and true or false
                for _, c in ipairs(Crystals:GetChildren()) do
                    local pos = c.Position
                    local d = 0
                    if myPosNum then
                        d = (pos.X - myPosX) * (pos.X - myPosX)
                            + (pos.Y - myPosY) * (pos.Y - myPosY)
                            + (pos.Z - myPosZ) * (pos.Z - myPosZ)
                        if d > (range + 60) * (range + 60) then continue end
                    end
                    if filter ~= "All" then
                        local tn = c:GetAttribute("TierName")
                        if tostring(tn or "") ~= filter then continue end
                    end
                    local cname = c:GetAttribute("CrystalName")
                    local tier = c:GetAttribute("Tier")
                    local r = c:GetAttribute("TierColorR")
                    local g = c:GetAttribute("TierColorG")
                    local b = c:GetAttribute("TierColorB")
                    local name = (cname and cname ~= "" and tostring(cname)) or c.Name
                    local value = tostring(c:GetAttribute("Value") or "")
                    out[#out + 1] = {
                        pos = pos,
                        d = d,
                        h = (c.Size.Y or 3) + 2,
                        tag = name .. " " .. value,
                        color = tierColor[tier] or Color3.fromRGB(r or 255, g or 255, b or 255),
                    }
                end
                if #out > POOL then
                    table.sort(out, function(a, b) return a.d < b.d end)
                    for i = POOL + 1, #out do out[i] = nil end
                end
            end
            nodes = out
            task.wait(0.8)
        end
    end)

    conn = RunService.RenderStepped:Connect(function()
        if not DrawUI.val("ore_enabled", true) then
            for i = 1, POOL do
                pool[i].box.Visible = false
                pool[i].tag.Visible = false
            end
            return
        end
        local list = nodes
        local n = 0
        for i = 1, #list do
            if n >= POOL then break end
            local e = list[i]
            local half = e.h * 0.5
            local top, v1 = WorldToScreen(e.pos + Vector3.new(0, half, 0))
            local bot, v2 = WorldToScreen(e.pos - Vector3.new(0, half, 0))
            if v1 and v2 then
                n = n + 1
                local d = pool[n]
                local h = bot.Y - top.Y
                local w = h * 0.8
                d.box.Position = Vector2.new(top.X - w * 0.5, top.Y)
                d.box.Size = Vector2.new(w, h)
                d.box.Color = e.color
                d.box.Visible = true
                d.tag.Text = e.tag
                d.tag.Position = Vector2.new(top.X, top.Y - 14)
                d.tag.Color = e.color
                d.tag.Visible = true
            end
        end
        for i = n + 1, POOL do
            pool[i].box.Visible = false
            pool[i].tag.Visible = false
        end
    end)

    local function stop()
        if not running then return end
        running = false
        if conn then conn:Disconnect() end
        for i = 1, POOL do
            pool[i].box:Remove()
            pool[i].tag:Remove()
        end
    end

    _G.oreEsp = { stop = stop }
end

-- ===== BOULDER ESP =====
do
    local POOL = 32
    local nodes = {}
    local pool = {}
    local conn
    local running = true

    local rarityColor = {
        Common = Color3.fromRGB(180, 210, 150),
        Uncommon = Color3.fromRGB(120, 220, 255),
        Rare = Color3.fromRGB(255, 220, 120),
        Epic = Color3.fromRGB(210, 150, 255),
        Legendary = Color3.fromRGB(255, 150, 90),
        Mythic = Color3.fromRGB(255, 90, 90),
        Empyrean = Color3.fromRGB(255, 225, 150),
        Pulsar = Color3.fromRGB(90, 210, 255),
        Quasar = Color3.fromRGB(255, 90, 220),
    }

    for i = 1, POOL do
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Visible = false
        local tag = Drawing.new("Text")
        tag.Size = 12
        tag.Center = true
        tag.Outline = true
        tag.Visible = false
        pool[i] = { box = box, tag = tag }
    end

    task.spawn(function()
        local bboxCache = {}
        while running do
            local out = {}
            local MD = game.Workspace:FindFirstChild("MountainDecorations")
            local B = MD and MD:FindFirstChild("Boulders")
            if not B then
                B = game.Workspace:FindFirstChild("BoulderTest")
            end
            if B and DrawUI.val("boulder_enabled", true) then
                local range = tonumber(DrawUI.option("boulder_range", "350")) or 350
                local rangeSq = (range + 60) * (range + 60)
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local myPos = root and root.Position
                local myPosX, myPosY, myPosZ = myPos and myPos.X, myPos and myPos.Y, myPos and myPos.Z
                local myPosNum = myPos and true or false
                local live = {}
                for _, b in ipairs(B:GetChildren()) do
                    local name = b:GetAttribute("BoulderName")
                    if not name then continue end
                    local key = b.Address
                    local cc = #b:GetChildren()
                    local bb = bboxCache[key]
                    if not bb or bb.cc ~= cc then
                        local minX, minY, minZ = math.huge, math.huge, math.huge
                        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
                        local n = 0
                        for _, p in ipairs(b:GetChildren()) do
                            local cn = p.ClassName
                            if cn == "MeshPart" or cn == "Part" then
                                local pos = p.Position
                                if pos.X < minX then minX = pos.X end
                                if pos.Y < minY then minY = pos.Y end
                                if pos.Z < minZ then minZ = pos.Z end
                                if pos.X > maxX then maxX = pos.X end
                                if pos.Y > maxY then maxY = pos.Y end
                                if pos.Z > maxZ then maxZ = pos.Z end
                                n = n + 1
                            end
                        end
                        if n == 0 then
                            local primary = b.PrimaryPart
                            if not primary then continue end
                            local pos = primary.Position
                            local s = primary.Size
                            minX, maxX = pos.X - s.X * 0.5, pos.X + s.X * 0.5
                            minY, maxY = pos.Y - s.Y * 0.5, pos.Y + s.Y * 0.5
                            minZ, maxZ = pos.Z - s.Z * 0.5, pos.Z + s.Z * 0.5
                        end
                        bb = {
                            cc = cc,
                            cx = (minX + maxX) * 0.5,
                            cy = (minY + maxY) * 0.5,
                            cz = (minZ + maxZ) * 0.5,
                            h = maxY - minY,
                        }
                        bboxCache[key] = bb
                    end
                    live[#live + 1] = key
                    local d = 0
                    if myPosNum then
                        local dx = bb.cx - myPosX
                        local dy = bb.cy - myPosY
                        local dz = bb.cz - myPosZ
                        d = dx * dx + dy * dy + dz * dz
                        if d > rangeSq then continue end
                    end
                    local rarity = b:GetAttribute("Rarity")
                    local rarityTxt = rarity and tostring(rarity) or ""
                    local tag = rarityTxt ~= "" and (tostring(name) .. " (" .. rarityTxt .. ")") or tostring(name)
                    out[#out + 1] = {
                        pos = Vector3.new(bb.cx, bb.cy, bb.cz),
                        d = d,
                        h = bb.h,
                        tag = tag,
                        color = rarityColor[rarityTxt] or Color3.fromRGB(255, 225, 160),
                    }
                end
                local liveSet = {}
                for _, k in ipairs(live) do liveSet[k] = true end
                for k in pairs(bboxCache) do
                    if not liveSet[k] then bboxCache[k] = nil end
                end
                if #out > POOL then
                    table.sort(out, function(a, b) return a.d < b.d end)
                    for i = POOL + 1, #out do out[i] = nil end
                end
            end
            nodes = out
            task.wait(1.5)
        end
    end)

    conn = RunService.RenderStepped:Connect(function()
        if not DrawUI.val("boulder_enabled", true) then
            for i = 1, POOL do
                pool[i].box.Visible = false
                pool[i].tag.Visible = false
            end
            return
        end
        local list = nodes
        local n = 0
        for i = 1, #list do
            if n >= POOL then break end
            local e = list[i]
            local half = e.h * 0.5 + 1
            local top, v1 = WorldToScreen(e.pos + Vector3.new(0, half, 0))
            local bot, v2 = WorldToScreen(e.pos - Vector3.new(0, half, 0))
            if v1 and v2 then
                n = n + 1
                local d = pool[n]
                local h = bot.Y - top.Y
                local w = h * 0.8
                d.box.Position = Vector2.new(top.X - w * 0.5, top.Y)
                d.box.Size = Vector2.new(w, h)
                d.box.Color = e.color
                d.box.Visible = true
                d.tag.Text = e.tag
                d.tag.Position = Vector2.new(top.X, top.Y - 14)
                d.tag.Color = e.color
                d.tag.Visible = true
            end
        end
        for i = n + 1, POOL do
            pool[i].box.Visible = false
            pool[i].tag.Visible = false
        end
    end)

    local function stop()
        if not running then return end
        running = false
        if conn then conn:Disconnect() end
        for i = 1, POOL do
            pool[i].box:Remove()
            pool[i].tag:Remove()
        end
    end

    _G.boulderEsp = { stop = stop }
end

notify("Enjoy <3", "", 4)