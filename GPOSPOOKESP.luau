pcall(function() _G.SpookHub_Running = false end)
pcall(function() _G.SpookESP_Running = false end)
pcall(function() _G.CandyESP_Running = false end)
pcall(function() _G.CandyHub_Running = false end)
if _G.SpookHub_ESPConn then pcall(function() _G.SpookHub_ESPConn:Disconnect() end) _G.SpookHub_ESPConn = nil end
if _G.CandyHub_Conn then pcall(function() _G.CandyHub_Conn:Disconnect() end) _G.CandyHub_Conn = nil end
if _G.SpookESP_Conn then pcall(function() _G.SpookESP_Conn:Disconnect() end) _G.SpookESP_Conn = nil end
if _G.CandyHub_Input then pcall(function() _G.CandyHub_Input:Disconnect() end) _G.CandyHub_Input = nil end
if _G.SpookHub_Owned then for _,d in ipairs(_G.SpookHub_Owned) do pcall(function() d:Remove() end) end _G.SpookHub_Owned = nil end
if _G.CandyHub_Owned then for _,d in ipairs(_G.CandyHub_Owned) do pcall(function() d:Remove() end) end end
local myId = tick() + (os.time() % 1000) * 0.001
_G.CandyHub_Id = myId
_G.CandyHub_Owned = {}
_G.CandyHub_Running = true
_G.CandyHub_WaveLen = 300
_G.CandyHub_Phase = 0
local function own(d) _G.CandyHub_Owned[#_G.CandyHub_Owned+1] = d return d end
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local VW, VH = 1920, 1009
do local c = WS.CurrentCamera if c then VW, VH = c.ViewportSize.X, c.ViewportSize.Y end end
local KEY_RSHIFT = 303
local showCandy, showGhost, showTimer, hubVisible = true, true, true, true
local HX, HY = 30, 120
local W, H = 248, 212
local PW, PH = 96, 26
local COL_BG = Color3.fromRGB(14, 14, 22)
local COL_SH = Color3.fromRGB(0, 0, 0)
local COL_ROW = Color3.fromRGB(24, 24, 36)
local COL_ROWH = Color3.fromRGB(38, 32, 52)
local COL_ACC = Color3.fromRGB(255, 170, 40)
local COL_ACC2 = Color3.fromRGB(255, 90, 90)
local COL_TXT = Color3.fromRGB(238, 238, 245)
local COL_DIM = Color3.fromRGB(155, 155, 170)
local COL_ON = Color3.fromRGB(120, 255, 150)
local COL_OFF = Color3.fromRGB(255, 120, 125)
local COL_CANDY = Color3.fromRGB(255, 165, 0)
local COL_GHOST = Color3.fromRGB(150, 220, 255)
local COL_WAVE = Color3.fromRGB(140, 255, 170)
local sh = own(Drawing.new("Square")); sh.Filled = true; sh.Color = COL_SH; sh.Transparency = 1
local bg = own(Drawing.new("Square")); bg.Filled = true; bg.Color = COL_BG; bg.Transparency = 1
pcall(function() bg.Rounding = 9 end)
local accent = own(Drawing.new("Square")); accent.Filled = true; accent.Color = COL_ACC; accent.Transparency = 1
local accent2 = own(Drawing.new("Square")); accent2.Filled = true; accent2.Color = COL_ACC2; accent2.Transparency = 1
local title = own(Drawing.new("Text")); title.Size = 16; title.Color = COL_ACC; title.Outline = true
title.Text = "Mimsy was here"
local sub = own(Drawing.new("Text")); sub.Size = 12; sub.Color = COL_DIM; sub.Outline = true
sub.Text = "ESP for them mfs"
local closeT = own(Drawing.new("Text")); closeT.Size = 15; closeT.Color = COL_TXT; closeT.Outline = true
closeT.Text = "X"
local pillBg = own(Drawing.new("Square")); pillBg.Filled = true; pillBg.Color = COL_BG; pillBg.Transparency = 1
pcall(function() pillBg.Rounding = 8 end)
local pillTx = own(Drawing.new("Text")); pillTx.Size = 13; pillTx.Color = COL_ACC; pillTx.Outline = true
pillTx.Text = "+ CANDY"
local rowBg, rowTx, rowSt = {}, {}, {}
for i = 1, 3 do
  local b = own(Drawing.new("Square")); b.Filled = true; b.Color = COL_ROW; b.Transparency = 1
  pcall(function() b.Rounding = 6 end)
  local t = own(Drawing.new("Text")); t.Size = 13; t.Color = COL_TXT; t.Outline = true
  local s = own(Drawing.new("Text")); s.Size = 13; s.Outline = true
  rowBg[i] = b; rowTx[i] = t; rowSt[i] = s
end
local dots, tmTx = {}, {}
local dotCols = { COL_CANDY, COL_GHOST, COL_WAVE }
for i = 1, 3 do
  local d = own(Drawing.new("Square")); d.Filled = true; d.Color = dotCols[i]; d.Transparency = 1
  local t = own(Drawing.new("Text")); t.Size = 13; t.Color = COL_TXT; t.Outline = true
  dots[i] = d; tmTx[i] = t
end
local hint = own(Drawing.new("Text")); hint.Size = 12; hint.Color = COL_DIM; hint.Outline = true
hint.Text = "vibecoded btw"
local POOL = 16
local pool = {}
for i = 1, POOL do
  local b = own(Drawing.new("Square")); b.Thickness = 1; b.Filled = false; b.Visible = false
  local t = own(Drawing.new("Text")); t.Size = 13; t.Center = true; t.Outline = true; t.Visible = false
  pool[i] = { box = b, tag = t }
end
local function rowY(i) return HY + 54 + (i - 1) * 27 end
local function tmY(i) return HY + 142 + (i - 1) * 17 end
local function layout()
  local pv = (not hubVisible) and _G.CandyHub_Running
  pillBg.Position = Vector2.new(HX, HY); pillBg.Size = Vector2.new(PW, PH); pillBg.Visible = pv
  pillTx.Position = Vector2.new(HX + 12, HY + 5); pillTx.Visible = pv
  sh.Position = Vector2.new(HX + 4, HY + 5); sh.Size = Vector2.new(W, H); sh.Visible = hubVisible
  bg.Position = Vector2.new(HX, HY); bg.Size = Vector2.new(W, H); bg.Visible = hubVisible
  accent.Position = Vector2.new(HX, HY); accent.Size = Vector2.new(W, 3); accent.Visible = hubVisible
  accent2.Position = Vector2.new(HX, HY + 3); accent2.Size = Vector2.new(W, 2); accent2.Visible = hubVisible
  title.Position = Vector2.new(HX + 12, HY + 10); title.Visible = hubVisible
  sub.Position = Vector2.new(HX + 12, HY + 30); sub.Visible = hubVisible
  closeT.Position = Vector2.new(HX + W - 24, HY + 10); closeT.Visible = hubVisible
  for i = 1, 3 do
    rowBg[i].Position = Vector2.new(HX + 10, rowY(i)); rowBg[i].Size = Vector2.new(W - 20, 22)
    rowBg[i].Visible = hubVisible
    rowTx[i].Position = Vector2.new(HX + 18, rowY(i) + 3); rowTx[i].Visible = hubVisible
    rowSt[i].Position = Vector2.new(HX + W - 52, rowY(i) + 3); rowSt[i].Visible = hubVisible
  end
  for i = 1, 3 do
    dots[i].Position = Vector2.new(HX + 14, tmY(i) + 4); dots[i].Size = Vector2.new(8, 8)
    dots[i].Visible = hubVisible and showTimer
    tmTx[i].Position = Vector2.new(HX + 28, tmY(i))
    tmTx[i].Visible = hubVisible and showTimer
  end
  hint.Position = Vector2.new(HX + 12, HY + 196); hint.Visible = hubVisible
end
local function refreshRows()
  rowTx[1].Text = "Candy ESP"
  rowTx[2].Text = "Ghost ESP"
  rowTx[3].Text = "Timers"
  rowSt[1].Text = showCandy and "ON" or "OFF"
  rowSt[2].Text = showGhost and "ON" or "OFF"
  rowSt[3].Text = showTimer and "ON" or "OFF"
  rowSt[1].Color = showCandy and COL_ON or COL_OFF
  rowSt[2].Color = showGhost and COL_ON or COL_OFF
  rowSt[3].Color = showTimer and COL_ON or COL_OFF
end
layout(); refreshRows()
local targets = {}
local myPos = Vector3.new(0, 0, 0)
local waveRem = 0
local function fmt(s)
  s = math.max(0, math.floor(s))
  local m = math.floor(s / 60)
  local r = s - m * 60
  if r < 10 then return tostring(m) .. ":0" .. tostring(r) end
  return tostring(m) .. ":" .. tostring(r)
end
task.spawn(function()
  while _G.CandyHub_Running and _G.CandyHub_Id == myId do
    local out = {}
    local ch = lp.Character
    local myR = ch and ch:FindFirstChild("HumanoidRootPart")
    if myR then myPos = myR.Position end
    local okAge, age = pcall(function() return WS:GetAttribute("serverAge") end)
    if okAge and type(age) == "number" then
      local wl = _G.CandyHub_WaveLen or 300
      local ph = _G.CandyHub_Phase or 0
      waveRem = wl - ((age - ph) % wl)
    end
    local npcs = WS:FindFirstChild("NPCs")
    local nc, ng = 0, 0
    if npcs then
      local kids = npcs:GetChildren()
      for i = 1, #kids do
        local m = kids[i]
        local nm = m.Name
        if nm == "Candy Skeleton" or nm == "Wandering Soul" then
          local head = m:FindFirstChild("Head")
          local root = m:FindFirstChild("HumanoidRootPart")
          local hum = m:FindFirstChild("Humanoid")
          if head and root and hum and hum.Health > 0 then
            local isC = nm == "Candy Skeleton"
            if isC then nc = nc + 1 else ng = ng + 1 end
            out[#out + 1] = { short = isC and "Candy" or "Ghost", head = head, root = root, col = isC and COL_CANDY or COL_GHOST, isC = isC }
            if #out >= POOL then break end
          end
        end
      end
    end
    if hubVisible and showTimer then
      tmTx[1].Text = "Candy  " .. tostring(nc) .. " alive"
      tmTx[2].Text = "Ghost  " .. tostring(ng) .. " alive"
      tmTx[3].Text = "Wave  " .. fmt(waveRem)
    end
    targets = out
    task.wait(0.5)
  end
end)
local function inside(mx, my, x, y, w, h) return mx >= x and mx <= x + w and my >= y and my <= y + h end
local lastFlip = 0
local function flipPanel()
  local now = tick()
  if now - lastFlip < 0.4 then return end
  lastFlip = now
  hubVisible = not hubVisible
  layout()
end
local function teardown()
  _G.CandyHub_Running = false
  if _G.CandyHub_Input then pcall(function() _G.CandyHub_Input:Disconnect() end) _G.CandyHub_Input = nil end
  if _G.CandyHub_Conn then pcall(function() _G.CandyHub_Conn:Disconnect() end) _G.CandyHub_Conn = nil end
  if _G.CandyHub_Owned then for _,d in ipairs(_G.CandyHub_Owned) do pcall(function() d:Remove() end) end end
  _G.CandyHub_Owned = {}
  print("Candy Hub unloaded")
end
task.spawn(function()
  while _G.CandyHub_Running and _G.CandyHub_Id == myId do task.wait(0.5) end
  if _G.CandyHub_Id == myId and _G.CandyHub_Owned then
    if _G.CandyHub_Input then pcall(function() _G.CandyHub_Input:Disconnect() end) _G.CandyHub_Input = nil end
    if _G.CandyHub_Conn then pcall(function() _G.CandyHub_Conn:Disconnect() end) _G.CandyHub_Conn = nil end
    for _,d in ipairs(_G.CandyHub_Owned) do pcall(function() d:Remove() end) end
    _G.CandyHub_Owned = {}
    print("Candy Hub unloaded")
  end
end)
_G.CandyHub_Input = UIS.InputBegan:Connect(function(inp)
  if type(inp) == "table" and inp.KeyCode == KEY_RSHIFT then flipPanel() end
end)
local wasDown, wasShift = false, false
local dragging, ddx, ddy, armRow, armClose = false, 0, 0, 0, false
local armPill, pillMoved, pressX, pressY = false, 0, 0, 0
_G.CandyHub_Conn = RS.RenderStepped:Connect(function()
  if not _G.CandyHub_Running or _G.CandyHub_Id ~= myId then return end
  local mx, my = 0, 0
  do local ok, ms = pcall(function() return lp:GetMouse() end) if ok and ms then mx, my = ms.X, ms.Y end end
  local down = false
  do local ok, v = pcall(function() return ismouse1pressed() end) if ok then down = v end end
  local shift = false
  do local ok, v = pcall(function() return UIS:IsKeyDown(KEY_RSHIFT) end) if ok then shift = v end end
  if shift and not wasShift then flipPanel() end
  wasShift = shift
  if hubVisible then
    if down and not wasDown then
      armRow, armClose = 0, false
      if inside(mx, my, HX + W - 32, HY, 28, 26) then armClose = true
      elseif inside(mx, my, HX, HY, W, 48) then dragging = true ddx, ddy = mx - HX, my - HY
      else
        for i = 1, 3 do if inside(mx, my, HX + 10, rowY(i), W - 20, 22) then armRow = i break end end
      end
    elseif (not down) and wasDown then
      if armClose and inside(mx, my, HX + W - 32, HY, 28, 26) then hubVisible = false layout() end
      if armRow >= 1 and inside(mx, my, HX + 10, rowY(armRow), W - 20, 22) then
        if armRow == 1 then showCandy = not showCandy
        elseif armRow == 2 then showGhost = not showGhost
        else showTimer = not showTimer end
        refreshRows() layout()
      end
      dragging = false armRow, armClose = 0, false
    end
    if dragging and down then
      HX = math.max(0, math.min(mx - ddx, VW - W))
      HY = math.max(0, math.min(my - ddy, VH - H))
      layout()
    end
    if not down then dragging = false end
    if inside(mx, my, HX + W - 32, HY, 28, 26) then closeT.Color = COL_ACC2 else closeT.Color = COL_TXT end
    for i = 1, 3 do
      if inside(mx, my, HX + 10, rowY(i), W - 20, 22) then rowBg[i].Color = COL_ROWH
      else rowBg[i].Color = COL_ROW end
    end
  else
    if down and not wasDown then
      armPill, pillMoved = false, 0
      pressX, pressY = mx, my
      if inside(mx, my, HX, HY, PW, PH) then armPill = true ddx, ddy = mx - HX, my - HY end
    elseif (not down) and wasDown then
      if armPill and pillMoved < 6 and inside(mx, my, HX, HY, PW, PH) then hubVisible = true layout() end
      armPill = false dragging = false
    end
    if armPill and down then
      local dx, dy = mx - pressX, my - pressY
      local mm = math.abs(dx) + math.abs(dy)
      if mm > pillMoved then pillMoved = mm end
      HX = math.max(0, math.min(mx - ddx, VW - PW))
      HY = math.max(0, math.min(my - ddy, VH - PH))
      layout()
    end
    if not down then armPill = false end
  end
  wasDown = down
  local list = targets
  local mp = myPos
  local n = 0
  for i = 1, #list do
    if n >= POOL then break end
    local t = list[i]
    if (t.isC and showCandy) or ((not t.isC) and showGhost) then
      local rp = t.root.Position
      local dx, dy, dz = rp.X - mp.X, rp.Y - mp.Y, rp.Z - mp.Z
      local dist = math.floor((dx * dx + dy * dy + dz * dz) ^ 0.5)
      if dist <= 3000 then
        local top, v1 = WorldToScreen(t.head.Position + Vector3.new(0, 0.7, 0))
        local bot, v2 = WorldToScreen(rp - Vector3.new(0, 3.2, 0))
        if v1 and v2 then
          local h = bot.Y - top.Y
          if h > 4 then
            n = n + 1
            local e = pool[n]
            local w = h * 0.5
            e.box.Position = Vector2.new(top.X - w * 0.5, top.Y)
            e.box.Size = Vector2.new(w, h)
            e.box.Color = t.col
            e.box.Visible = true
            e.tag.Text = t.short .. " [" .. tostring(dist) .. "m]"
            e.tag.Position = Vector2.new(top.X, top.Y - 16)
            e.tag.Visible = true
          end
        end
      end
    end
  end
  for i = n + 1, POOL do pool[i].box.Visible = false pool[i].tag.Visible = false end
end)
notify("mimsers", "RShift fixed + solid bg + pill", 3)
print("mimsers")
