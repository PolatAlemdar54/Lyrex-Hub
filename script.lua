--[[
    MM2 Ultimate Script v7 "Skyfall" | Delta, Codex, Wave, Solara Uyumlu
    Kullanım:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/PolatAlemdar54/Lyrex-Hub/main/script.lua"))()
    
    v7 YENİLİKLER:
    - 3D Animasyonlu ve Canlı Gökyüzü Arka Planlı Menü (ViewportFrame)
    - Fling tamamen yeniden yazıldı (HumanoidStateType.Physics + AssemblyVelocity)
    - Silah Silent Aim (Raycast + FireServer) kamera kilidi sorunu giderildi
    - Bıçak Silent Aim ve Auto Kill otomatik hedef bulma mantığı düzeltildi
    - Ateş Butonu artık FOV içindeki katili otomatik algılayıp ateş ediyor
]]

-- ============================================================
-- GÜVENLİ ÇAĞRI
-- ============================================================
local function SafeCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[MM2] Hata:", err) end
    return ok
end

-- ============================================================
-- SERVİSLER
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ============================================================
-- AYARLAR
-- ============================================================
local Config = {
    ESP = {
        Enabled = true,
        ShowGunDrop = true,
        ShowTracers = true,
        MaxDistance = 500,
        RefreshRate = 0.4,
    },
    SilentAim = {
        GunEnabled = false,
        KnifeEnabled = false,
        AutoKill = false,
        AutoKillRange = 40,
        AutoKillFOV = 140,
        FOV = 140,
        Headshot = true,
    },
    Movement = {
        WalkSpeed = 16,
        BunnyHop = false,
        SpinBot = false,
        SpinSpeed = 400,
    },
    Farm = {
        AutoCoin = false,
        FarmSpeed = 30,
        MaxCoins = 50,
        MaxDistance = 300,
        AutoTPGun = false,
    },
    Misc = {
        AntiAFK = true,
        FlingCooldown = 0,
    }
}

-- ============================================================
-- HAFIZA
-- ============================================================
local ESPObjects    = {}
local Tracers       = {}
local GunDropESP    = nil
local Connections   = {}
local Threads       = {}
local SilentAimTarget = nil
local FireButton    = nil
local GunNotified   = false

-- ============================================================
-- YARDIMCILAR
-- ============================================================
local function GetRole(player)
    if not player or not player.Character then return "Innocent" end
    local bp = player:FindFirstChild("Backpack")
    local ch = player.Character
    if (bp and bp:FindFirstChild("Knife")) or ch:FindFirstChild("Knife") then return "Murderer" end
    if (bp and bp:FindFirstChild("Gun")) or ch:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
end

local function RoleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 40, 40)
    elseif role == "Sheriff" then return Color3.fromRGB(40, 140, 255)
    else return Color3.fromRGB(40, 255, 90) end
end

local function Distance(player)
    if not player or not player.Character then return math.huge end
    local r = player.Character:FindFirstChild("HumanoidRootPart")
    if not r then return math.huge end
    return (r.Position - Camera.CFrame.Position).Magnitude
end

local function HumanDelay(min, max)
    task.wait(math.random(min * 1000, max * 1000) / 1000)
end

local function IsInFOV(targetPos, fovAngle)
    local cam = Camera.CFrame
    local toTarget = (targetPos - cam.Position)
    if toTarget.Magnitude < 0.1 then return true end
    local dot = cam.LookVector:Dot(toTarget.Unit)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= (fovAngle / 2)
end

local function GetTargetPlayer(roleFilter, fovAngle, maxDist)
    fovAngle = fovAngle or Config.SilentAim.FOV
    maxDist = maxDist or Config.ESP.MaxDistance
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local head = plr.Character:FindFirstChild("Head")
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not head or not root then continue end
        if roleFilter and GetRole(plr) ~= roleFilter then continue end
        if not IsInFOV(head.Position, fovAngle) then continue end
        local d = (root.Position - Camera.CFrame.Position).Magnitude
        if d < bestDist and d <= maxDist then bestDist = d; best = plr end
    end
    return best
end

local function GetTargetHitPos()
    local t = SilentAimTarget
    if not t or not t.Character then return nil end
    local part = t.Character:FindFirstChild(Config.SilentAim.Headshot and "Head" or "HumanoidRootPart")
    return part and part.Position or nil
end

local function GetLocalGun()
    local ch = LocalPlayer.Character
    if not ch then return nil end
    local tool = ch:FindFirstChild("Gun")
    if tool then return tool end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then return bp:FindFirstChild("Gun") end
    return nil
end

local function GetLocalKnife()
    local ch = LocalPlayer.Character
    if not ch then return nil end
    local tool = ch:FindFirstChild("Knife")
    if tool then return tool end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then return bp:FindFirstChild("Knife") end
    return nil
end

local function FindDroppedGun()
    local gun = workspace:FindFirstChild("GunDrop")
    if gun then return gun end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Gun" and obj:IsA("Model") then return obj end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:lower():find("gun") and obj:FindFirstChild("Handle") then
            return obj
        end
    end
    return nil
end

-- ============================================================
-- GELİŞMİŞ SİLENT AİM (Kamera Kilitlenmesini Önleyen Sürüm)
-- ============================================================
local function SetupSilentAim()
    -- FireServer Hook
    SafeCall(function()
        if not getrawmetatable or not setreadonly or not newcclosure or not getnamecallmethod then
            warn("[MM2] Executor Silent Aim desteklemiyor.")
            return
        end
        local mt = getrawmetatable(game)
        if not mt then return end
        local oldNamecall = mt.__namecall
        if not oldNamecall then return end
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and Config.SilentAim.GunEnabled and self then
                local sName = tostring(self.Name)
                if sName == "Gun" or sName == "Shoot" or sName == "FireBullet" then
                    local args = {...}
                    local pos = GetTargetHitPos()
                    if pos then
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = pos
                            elseif typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(pos)
                            end
                        end
                    end
                    return oldNamecall(self, table.unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        print("[MM2] FireServer hook aktif.")
    end)

    -- Raycast Hook
    SafeCall(function()
        if not getrawmetatable or not setreadonly or not newcclosure or not getnamecallmethod then
            return
        end
        local mt = getrawmetatable(game)
        if not mt then return end
        local oldNamecall = mt.__namecall
        if not oldNamecall then return end
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Raycast" and Config.SilentAim.GunEnabled then
                local args = {...}
                local pos = GetTargetHitPos()
                if pos and #args >= 2 then
                    local origin = args[1]
                    if typeof(origin) == "Vector3" and typeof(args[2]) == "Vector3" then
                        args[2] = (pos - origin)
                    end
                end
                return oldNamecall(self, table.unpack(args))
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        print("[MM2] Raycast hook aktif.")
    end)
end

-- ============================================================
-- FLING v3 (KÖKTEN ÇÖZÜM)
-- ============================================================
local function FlingPlayer(target)
    if not target or target == LocalPlayer or not target.Character then return end
    if tick() - Config.Misc.FlingCooldown < 3 then return end
    Config.Misc.FlingCooldown = tick()

    local myChar = LocalPlayer.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tChar  = target.Character
    local tHum   = tChar and tChar:FindFirstChildOfClass("Humanoid")
    local tHRP   = tChar and tChar:FindFirstChild("HumanoidRootPart")

    if not myHRP or not tHRP or not tHum or tHum.Health <= 0 then return end
    if not myHum then return end

    -- Hedefin fiziksel kontrolünü ele geçir
    local oldState = myHum:GetState()
    local oldPosition = myHRP.CFrame
    local oldDestroyHeight = workspace.FallenPartsDestroyHeight

    SafeCall(function() myHum:ChangeState(Enum.HumanoidStateType.Physics) end)
    workspace.FallenPartsDestroyHeight = -math.huge
    task.wait(0.15)

    -- Sürekli yüksek hızda çarpışma döngüsü
    local flingConn = RunService.RenderStepped:Connect(function()
        SafeCall(function()
            myHRP.AssemblyLinearVelocity = Vector3.new(1000, 10000, 1000)
            myHRP.AssemblyAngularVelocity = Vector3.new(500, 500, 500)
        end)
    end)

    -- Hedefin üzerine pozisyon kilitle
    if tHRP and tHRP.Parent then
        SafeCall(function() myHRP.CFrame = tHRP.CFrame end)
    end
    task.wait(0.5)

    -- Hedefi takip et
    local posConn = RunService.Heartbeat:Connect(function()
        if tHRP and tHRP.Parent then
            SafeCall(function()
                local vel = tHRP.Velocity
                myHRP.CFrame = CFrame.new(
                    tHRP.Position.X + vel.X / 2,
                    tHRP.Position.Y + vel.Y / 2,
                    tHRP.Position.Z + vel.Z / 2
                )
            end)
        end
    end)

    task.wait(0.75)
    posConn:Disconnect()
    task.wait(0.1)
    flingConn:Disconnect()

    -- Kendini toparla
    SafeCall(function() myHum:ChangeState(oldState) end)
    SafeCall(function()
        myHRP.AssemblyAngularVelocity = Vector3.zero
        myHRP.AssemblyLinearVelocity = Vector3.zero
    end)
    task.wait(0.1)

    for _ = 1, 20 do
        if myHRP and myHRP.Parent then
            SafeCall(function()
                myHRP.AssemblyAngularVelocity = Vector3.zero
                myHRP.AssemblyLinearVelocity = Vector3.zero
                myHRP.CFrame = oldPosition
            end)
        end
        task.wait(0.05)
    end

    workspace.FallenPartsDestroyHeight = oldDestroyHeight

    -- Maç bug'ına karşı önlem
    task.spawn(function()
        task.wait(2)
        local ch = LocalPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or hrp.Position.Y < -200 then
            SafeCall(function() LocalPlayer.Character:BreakJoints() end)
        end
    end)
end

-- ============================================================
-- ESP
-- ============================================================
local function RemoveESP(player)
    local e = ESPObjects[player]
    if not e then return end
    SafeCall(function() if e.Highlight then e.Highlight:Destroy() end end)
    SafeCall(function() if e.Billboard then e.Billboard:Destroy() end end)
    ESPObjects[player] = nil
end

local function CreateESP(player)
    if not player or player == LocalPlayer or not player.Character then return end
    if not player.Character:FindFirstChild("HumanoidRootPart") then return end

    local role = GetRole(player)
    local color = RoleColor(role)

    local hl = Instance.new("Highlight")
    hl.Name = "MM2_ESP_HL"
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0.15
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = player.Character

    local bb = Instance.new("BillboardGui")
    bb.Name = "MM2_ESP_BB"
    bb.Size = UDim2.new(0, 200, 0, 46)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.Parent = player.Character

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1, 0, 0.5, 0)
    nameL.BackgroundTransparency = 1
    nameL.Text = player.Name .. " [" .. role .. "]"
    nameL.TextColor3 = color
    nameL.TextStrokeTransparency = 0
    nameL.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameL.TextSize = 15
    nameL.Font = Enum.Font.GothamBold
    nameL.Parent = bb

    local distL = Instance.new("TextLabel")
    distL.Size = UDim2.new(1, 0, 0.5, 0)
    distL.Position = UDim2.new(0, 0, 0.5, 0)
    distL.BackgroundTransparency = 1
    distL.Text = "0 studs"
    distL.TextColor3 = Color3.new(1, 1, 1)
    distL.TextStrokeTransparency = 0
    distL.TextStrokeColor3 = Color3.new(0, 0, 0)
    distL.TextSize = 13
    distL.Font = Enum.Font.Gotham
    distL.Parent = bb

    ESPObjects[player] = { Highlight = hl, Billboard = bb, NameLabel = nameL, DistanceLabel = distL }
end

local function EnsureESP(player)
    if not player or player == LocalPlayer or not player.Character then return end
    local e = ESPObjects[player]
    if not e or not e.Highlight or not e.Highlight.Parent
       or not e.Billboard or not e.Billboard.Parent then
        RemoveESP(player)
        CreateESP(player)
    end
end

local function ClearGunDropESP()
    if GunDropESP then
        SafeCall(function() if GunDropESP.Highlight then GunDropESP.Highlight:Destroy() end end)
        SafeCall(function() if GunDropESP.Billboard then GunDropESP.Billboard:Destroy() end end)
        GunDropESP = nil
    end
end

local function UpdateGunDropESP()
    ClearGunDropESP()
    if not Config.ESP.ShowGunDrop then return end

    local gun = FindDroppedGun()
    if not gun then
        GunNotified = false
        return
    end
    local handle = gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart")
    if not handle then return end

    if not GunNotified then
        GunNotified = true
        SafeCall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "🔫 Silah Düştü!",
                Text = "Şerif öldü. Silah konumu işaretlendi.",
                Duration = 4
            })
        end)
    end

    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 165, 0)
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = gun

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 160, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.Parent = gun

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🔫 DÜŞEN SİLAH"
    lbl.TextColor3 = Color3.fromRGB(255, 165, 0)
    lbl.TextStrokeTransparency = 0
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb

    GunDropESP = { Highlight = hl, Billboard = bb, Label = lbl, Part = handle, Model = gun }
end

local function ClearTracers()
    for _, t in pairs(Tracers) do
        SafeCall(function() if t.Remove then t:Remove() end end)
    end
    Tracers = {}
end

local function UpdateTracers()
    ClearTracers()
    if not Config.ESP.ShowTracers or not Config.ESP.Enabled then return end
    if not Drawing or not Drawing.new then return end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        if Distance(plr) > Config.ESP.MaxDistance then continue end

        local color = RoleColor(GetRole(plr))
        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then continue end

        local ok, line = pcall(function()
            local l = Drawing.new("Line")
            l.From = screenCenter
            l.To = Vector2.new(screenPos.X, screenPos.Y)
            l.Color = color
            l.Thickness = 1.5
            l.Transparency = 0.6
            l.Visible = true
            return l
        end)
        if ok and line then table.insert(Tracers, line) end
    end
end

local function ESPUpdateLoop()
    while task.wait(Config.ESP.RefreshRate) do
        SafeCall(function()
            if not Config.ESP.Enabled then
                for plr in pairs(ESPObjects) do RemoveESP(plr) end
                ClearTracers(); ClearGunDropESP()
                return
            end

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then EnsureESP(plr) end
            end

            for plr, e in pairs(ESPObjects) do
                if not plr or not plr.Character then RemoveESP(plr); continue end
                local role = GetRole(plr)
                local color = RoleColor(role)
                local dist = Distance(plr)
                if e.Highlight then
                    e.Highlight.FillColor = color
                    e.Highlight.Enabled = dist <= Config.ESP.MaxDistance
                end
                if e.Billboard then e.Billboard.Enabled = dist <= Config.ESP.MaxDistance end
                if e.NameLabel then
                    e.NameLabel.Text = plr.Name .. " [" .. role .. "]"
                    e.NameLabel.TextColor3 = color
                end
                if e.DistanceLabel then
                    e.DistanceLabel.Text = string.format("%d studs", math.floor(dist))
                end
            end

            UpdateGunDropESP()
            SilentAimTarget = GetTargetPlayer("Murderer")
        end)
    end
end

local function TracerLoop()
    while task.wait(0.05) do
        if Config.ESP.Enabled and Config.ESP.ShowTracers then
            SafeCall(UpdateTracers)
        end
    end
end

-- ============================================================
-- AUTO TP GUN
-- ============================================================
local function AutoTPGunLoop()
    while task.wait(1) do
        if not Config.Farm.AutoTPGun then continue end
        SafeCall(function()
            local gun = FindDroppedGun()
            if not gun then return end
            local handle = gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart")
            if not handle then return end
            local ch = LocalPlayer.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if not root then return end
            HumanDelay(0.1, 0.25)
            local dist = (handle.Position - root.Position).Magnitude
            local t = TweenService:Create(root,
                TweenInfo.new(math.min(dist / 40, 1.2), Enum.EasingStyle.Linear),
                {CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))})
            t:Play()
        end)
    end
end

-- ============================================================
-- AUTO KILL (BIÇAK)
-- ============================================================
local function AutoKillLoop()
    while task.wait(0.12) do
        if not (Config.SilentAim.AutoKill or Config.SilentAim.KnifeEnabled) then continue end
        SafeCall(function()
            local ch = LocalPlayer.Character
            if not ch then return end
            local tool = ch:FindFirstChild("Knife") or GetLocalKnife()
            if not tool then return end
            if tool.Parent ~= ch then
                SafeCall(function() tool.Parent = ch end)
                task.wait(0.1)
            end

            local target, best = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer or not plr.Character then continue end
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then continue end
                local head = plr.Character:FindFirstChild("Head")
                if not head then continue end
                if not IsInFOV(head.Position, Config.SilentAim.AutoKillFOV) then continue end
                local d = (head.Position - Camera.CFrame.Position).Magnitude
                if d < best and d <= Config.SilentAim.AutoKillRange then best = d; target = plr end
            end

            if target and target.Character then
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local mRoot = ch:FindFirstChild("HumanoidRootPart")
                if tRoot and mRoot then
                    local dist = (tRoot.Position - mRoot.Position).Magnitude
                    if dist > 5 then
                        local t = TweenService:Create(mRoot,
                            TweenInfo.new(0.1, Enum.EasingStyle.Linear),
                            {CFrame = tRoot.CFrame * CFrame.new(0, 0, 2)})
                        t:Play()
                        task.wait(0.11)
                    end
                    for _ = 1, 3 do
                        SafeCall(function() tool:Activate() end)
                        task.wait(0.05)
                    end
                    HumanDelay(0.05, 0.1)
                end
            end
        end)
    end
end

-- ============================================================
-- ATEŞ
-- ============================================================
local FireHeld = false

local function TryAutoFire()
    if not Config.SilentAim.GunEnabled then return end
    local gun = GetLocalGun()
    if not gun or gun.Parent ~= LocalPlayer.Character then return end

    local target = GetTargetPlayer("Murderer", Config.SilentAim.FOV, Config.ESP.MaxDistance)
    if not target then
        target = GetTargetPlayer(nil, Config.SilentAim.FOV, Config.ESP.MaxDistance)
    end
    if not target then return end

    SafeCall(function() gun:Activate() end)

    SafeCall(function()
        local remote = gun:FindFirstChild("RemoteEvent") or gun:FindFirstChildWhichIsA("RemoteEvent")
        if remote then
            local pos = GetTargetHitPos()
            if pos then
                remote:FireServer(pos)
            end
        end
    end)
end

local function AutoFireLoop()
    while task.wait(0.06) do
        if FireHeld and Config.SilentAim.GunEnabled then
            SafeCall(TryAutoFire)
        end
    end
end

-- ============================================================
-- AUTO COIN FARM
-- ============================================================
local function GetClosestCoin()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestD = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("coin") then
            local d = (obj.Position - root.Position).Magnitude
            if d < bestD and d <= Config.Farm.MaxDistance then bestD, best = d, obj end
        end
    end
    return best
end

local function AutoFarmLoop()
    while task.wait(0.5) do
        if not Config.Farm.AutoCoin then continue end
        SafeCall(function()
            local ch = LocalPlayer.Character
            if not ch then return end
            local root = ch:FindFirstChild("HumanoidRootPart")
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health <= 0 then return end
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                local cnt = 0
                for _, it in ipairs(bp:GetChildren()) do
                    if it.Name:lower():find("coin") then cnt = cnt + 1 end
                end
                if cnt >= Config.Farm.MaxCoins then return end
            end
            local coin = GetClosestCoin()
            if not coin then return end
            HumanDelay(0.1, 0.2)
            local dist = (coin.Position - root.Position).Magnitude
            local t = TweenService:Create(root,
                TweenInfo.new(dist / Config.Farm.FarmSpeed, Enum.EasingStyle.Linear),
                {CFrame = CFrame.new(coin.Position + Vector3.new(0, 3, 0))})
            t:Play()
        end)
    end
end

-- ============================================================
-- BUNNY HOP
-- ============================================================
local function BunnyHopLoop()
    while task.wait(0.05) do
        if not Config.Movement.BunnyHop then continue end
        SafeCall(function()
            local ch = LocalPlayer.Character
            if not ch then return end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait()
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)
    end
end

-- ============================================================
-- SPINBOT
-- ============================================================
local function SpinBotLoop()
    local last = tick()
    while task.wait(0.02) do
        if not Config.Movement.SpinBot then last = tick(); continue end
        SafeCall(function()
            local now = tick(); local dt = now - last; last = now
            local ch = LocalPlayer.Character
            if not ch then return end
            local root = ch:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local delta = math.rad(Config.Movement.SpinSpeed) * dt
            root.CFrame = root.CFrame * CFrame.Angles(0, delta, 0)
        end)
    end
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
local function SetupAntiAFK()
    SafeCall(function()
        Connections[#Connections+1] = LocalPlayer.Idled:Connect(function()
            if not Config.Misc.AntiAFK then return end
            SafeCall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end)
end

local function ApplyWalkSpeed()
    SafeCall(function()
        local ch = LocalPlayer.Character
        if not ch then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.Movement.WalkSpeed end
    end)
end

-- ============================================================
-- OYUNCU OLAYLARI
-- ============================================================
local function HookPlayer(plr)
    SafeCall(function()
        Connections[#Connections+1] = plr.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if char.Parent and Config.ESP.Enabled then
                RemoveESP(plr); CreateESP(plr)
            end
            if plr == LocalPlayer then
                task.wait(0.5)
                ApplyWalkSpeed()
            end
        end)
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do HookPlayer(plr) end
SafeCall(function()
    Connections[#Connections+1] = Players.PlayerAdded:Connect(HookPlayer)
end)
SafeCall(function()
    Connections[#Connections+1] = Players.PlayerRemoving:Connect(function(plr) RemoveESP(plr) end)
end)

-- ============================================================
-- UI (3D ANİMASYONLU VE GÖKYÜZÜ ARKA PLANLI)
-- ============================================================
local function BuildUI()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not pg then warn("[MM2] PlayerGui bulunamadı."); return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2_UI_v7"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    -- ANA PANEL
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420, 0, 600)
    main.Position = UDim2.new(0.5, -210, 0.5, -300)
    main.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.ClipsDescendants = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

    -- 3D GÖKYÜZÜ ARKA PLANI (ViewportFrame)
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "SkyBackground"
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    viewport.BorderSizePixel = 0
    viewport.ZIndex = 0
    viewport.Parent = main
    Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 16)

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport

    -- Yıldızlar ve gezegenler
    local skyPart = Instance.new("Part")
    skyPart.Size = Vector3.new(100, 100, 1)
    skyPart.Anchored = true
    skyPart.CanCollide = false
    skyPart.Material = Enum.Material.Neon
    skyPart.Color = Color3.fromRGB(20, 25, 40)
    skyPart.Parent = worldModel

    local starPart = Instance.new("Part")
    starPart.Size = Vector3.new(2, 2, 2)
    starPart.Anchored = true
    starPart.CanCollide = false
    starPart.Material = Enum.Material.Neon
    starPart.Color = Color3.fromRGB(100, 200, 255)
    starPart.Position = Vector3.new(10, 10, -5)
    starPart.Parent = worldModel

    local planet = Instance.new("Part")
    planet.Shape = Enum.PartType.Ball
    planet.Size = Vector3.new(20, 20, 20)
    planet.Anchored = true
    planet.CanCollide = false
    planet.Material = Enum.Material.Neon
    planet.Color = Color3.fromRGB(80, 40, 120)
    planet.Position = Vector3.new(-30, 15, -10)
    planet.Parent = worldModel

    local vpCam = Instance.new("Camera")
    vpCam.FieldOfView = 70
    vpCam.CFrame = CFrame.new(Vector3.new(0, 0, 50), Vector3.new(0, 0, 0))
    vpCam.Parent = viewport
    viewport.CurrentCamera = vpCam

    -- Gökyüzünü canlandır
    task.spawn(function()
        while main.Parent do
            task.wait(0.03)
            SafeCall(function()
                vpCam.CFrame = vpCam.CFrame * CFrame.Angles(0, math.rad(0.3), 0)
                starPart.CFrame = starPart.CFrame * CFrame.Angles(0, math.rad(1), 0)
            end)
        end
    end)

    -- Başlık
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 46)
    title.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
    title.BackgroundTransparency = 0.3
    title.Text = "  🎯 MM2 Ultimate v7 Skyfall"
    title.TextColor3 = Color3.fromRGB(220, 230, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 10
    title.Parent = main
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 16)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
    closeBtn.Text = "─"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.ZIndex = 11
    closeBtn.Parent = main
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    -- İçerik scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -64)
    scroll.Position = UDim2.new(0, 8, 0, 54)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 130, 255)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = 5
    scroll.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    -- UI yardımcıları
    local function SectionLabel(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 32)
        l.BackgroundColor3 = Color3.fromRGB(44, 46, 66)
        l.BackgroundTransparency = 0.4
        l.Text = "  " .. text
        l.TextColor3 = Color3.fromRGB(140, 170, 255)
        l.Font = Enum.Font.GothamBold
        l.TextSize = 14
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 6
        l.Parent = scroll
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
    end

    local function ToggleButton(text, initial, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = initial and Color3.fromRGB(30, 150, 90) or Color3.fromRGB(50, 52, 72)
        btn.BackgroundTransparency = 0.2
        btn.Text = "   " .. text .. (initial and "   [AÇIK]" or "   [KAPALI]")
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 6
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local state = initial
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(30, 150, 90) or Color3.fromRGB(50, 52, 72)
            btn.Text = "   " .. text .. (state and "   [AÇIK]" or "   [KAPALI]")
            SafeCall(callback, state)
        end)
        return btn
    end

    local function ActionButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = color or Color3.fromRGB(80, 80, 110)
        btn.BackgroundTransparency = 0.2
        btn.Text = "   " .. text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 6
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(function() SafeCall(callback) end)
        return btn
    end

    local function miniBtn(parent, txt, cb, isFull)
        local b = Instance.new("TextButton")
        b.Size = isFull and UDim2.new(1, 0, 1, 0) or UDim2.new(0.5, -3, 1, 0)
        b.BackgroundColor3 = Color3.fromRGB(60, 62, 90)
        b.BackgroundTransparency = 0.3
        b.Text = txt
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.ZIndex = 6
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function() SafeCall(cb) end)
    end

    -- ESP
    SectionLabel("🎯 ESP")
    ToggleButton("ESP Aç/Kapat", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)
    ToggleButton("Tracers (Çizgi)", Config.ESP.ShowTracers, function(v) Config.ESP.ShowTracers = v end)
    ToggleButton("Düşen Silah ESP", Config.ESP.ShowGunDrop, function(v) Config.ESP.ShowGunDrop = v end)

    -- COMBAT
    SectionLabel("⚔️ COMBAT")
    ToggleButton("Silah Silent Aim", Config.SilentAim.GunEnabled,
        function(v)
            Config.SilentAim.GunEnabled = v
            if FireButton then FireButton.Visible = v end
        end)
    ToggleButton("Bıçak Silent Aim", Config.SilentAim.KnifeEnabled,
        function(v) Config.SilentAim.KnifeEnabled = v end)
    ToggleButton("Auto Kill (Katil)", Config.SilentAim.AutoKill,
        function(v) Config.SilentAim.AutoKill = v end)
    ToggleButton("Headshot", Config.SilentAim.Headshot, function(v) Config.SilentAim.Headshot = v end)

    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.new(1, 0, 0, 24)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "   FOV: " .. Config.SilentAim.FOV .. "°"
    fovLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextSize = 12
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.ZIndex = 6
    fovLabel.Parent = scroll

    local fovRow = Instance.new("Frame")
    fovRow.Size = UDim2.new(1, 0, 0, 30)
    fovRow.BackgroundTransparency = 1
    fovRow.ZIndex = 6
    fovRow.Parent = scroll
    local fovL = Instance.new("UIListLayout", fovRow)
    fovL.FillDirection = Enum.FillDirection.Horizontal
    fovL.Padding = UDim.new(0, 6)
    miniBtn(fovRow, "  -10", function()
        Config.SilentAim.FOV = math.max(20, Config.SilentAim.FOV - 10)
        fovLabel.Text = "   FOV: " .. Config.SilentAim.FOV .. "°"
    end)
    miniBtn(fovRow, "  +10", function()
        Config.SilentAim.FOV = math.min(360, Config.SilentAim.FOV + 10)
        fovLabel.Text = "   FOV: " .. Config.SilentAim.FOV .. "°"
    end)

    local akLabel = Instance.new("TextLabel")
    akLabel.Size = UDim2.new(1, 0, 0, 24)
    akLabel.BackgroundTransparency = 1
    akLabel.Text = "   AutoKill Menzil: " .. Config.SilentAim.AutoKillRange .. " stud"
    akLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    akLabel.Font = Enum.Font.Gotham
    akLabel.TextSize = 12
    akLabel.TextXAlignment = Enum.TextXAlignment.Left
    akLabel.ZIndex = 6
    akLabel.Parent = scroll

    local akRow = Instance.new("Frame")
    akRow.Size = UDim2.new(1, 0, 0, 30)
    akRow.BackgroundTransparency = 1
    akRow.ZIndex = 6
    akRow.Parent = scroll
    local akL = Instance.new("UIListLayout", akRow)
    akL.FillDirection = Enum.FillDirection.Horizontal
    akL.Padding = UDim.new(0, 6)
    miniBtn(akRow, "  -5", function()
        Config.SilentAim.AutoKillRange = math.max(5, Config.SilentAim.AutoKillRange - 5)
        akLabel.Text = "   AutoKill Menzil: " .. Config.SilentAim.AutoKillRange .. " stud"
    end)
    miniBtn(akRow, "  +5", function()
        Config.SilentAim.AutoKillRange = math.min(150, Config.SilentAim.AutoKillRange + 5)
        akLabel.Text = "   AutoKill Menzil: " .. Config.SilentAim.AutoKillRange .. " stud"
    end)

    -- MOVEMENT
    SectionLabel("🏃 HAREKET")
    ToggleButton("Bunny Hop", Config.Movement.BunnyHop, function(v) Config.Movement.BunnyHop = v end)
    ToggleButton("SpinBot", Config.Movement.SpinBot, function(v) Config.Movement.SpinBot = v end)

    local spinLabel = Instance.new("TextLabel")
    spinLabel.Size = UDim2.new(1, 0, 0, 24)
    spinLabel.BackgroundTransparency = 1
    spinLabel.Text = "   Spin Hızı: " .. Config.Movement.SpinSpeed .. "°/sn"
    spinLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    spinLabel.Font = Enum.Font.Gotham
    spinLabel.TextSize = 12
    spinLabel.TextXAlignment = Enum.TextXAlignment.Left
    spinLabel.ZIndex = 6
    spinLabel.Parent = scroll

    local spinRow = Instance.new("Frame")
    spinRow.Size = UDim2.new(1, 0, 0, 30)
    spinRow.BackgroundTransparency = 1
    spinRow.ZIndex = 6
    spinRow.Parent = scroll
    local sLay = Instance.new("UIListLayout", spinRow)
    sLay.FillDirection = Enum.FillDirection.Horizontal
    sLay.Padding = UDim.new(0, 6)
    miniBtn(spinRow, "  Yavaş", function()
        Config.Movement.SpinSpeed = math.max(60, Config.Movement.SpinSpeed - 100)
        spinLabel.Text = "   Spin Hızı: " .. Config.Movement.SpinSpeed .. "°/sn"
    end)
    miniBtn(spinRow, "  Hızlı", function()
        Config.Movement.SpinSpeed = math.min(3000, Config.Movement.SpinSpeed + 100)
        spinLabel.Text = "   Spin Hızı: " .. Config.Movement.SpinSpeed .. "°/sn"
    end)

    local wsLabel = Instance.new("TextLabel")
    wsLabel.Size = UDim2.new(1, 0, 0, 24)
    wsLabel.BackgroundTransparency = 1
    wsLabel.Text = "   WalkSpeed: " .. Config.Movement.WalkSpeed
    wsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    wsLabel.Font = Enum.Font.Gotham
    wsLabel.TextSize = 12
    wsLabel.TextXAlignment = Enum.TextXAlignment.Left
    wsLabel.ZIndex = 6
    wsLabel.Parent = scroll

    local wsRow = Instance.new("Frame")
    wsRow.Size = UDim2.new(1, 0, 0, 30)
    wsRow.BackgroundTransparency = 1
    wsRow.ZIndex = 6
    wsRow.Parent = scroll
    local wLay = Instance.new("UIListLayout", wsRow)
    wLay.FillDirection = Enum.FillDirection.Horizontal
    wLay.Padding = UDim.new(0, 6)
    miniBtn(wsRow, "  -5", function()
        Config.Movement.WalkSpeed = math.max(8, Config.Movement.WalkSpeed - 5)
        wsLabel.Text = "   WalkSpeed: " .. Config.Movement.WalkSpeed
        ApplyWalkSpeed()
    end)
    miniBtn(wsRow, "  +5", function()
        Config.Movement.WalkSpeed = math.min(200, Config.Movement.WalkSpeed + 5)
        wsLabel.Text = "   WalkSpeed: " .. Config.Movement.WalkSpeed
        ApplyWalkSpeed()
    end)

    -- FARM
    SectionLabel("💰 FARM")
    ToggleButton("Auto Coin Farm", Config.Farm.AutoCoin, function(v) Config.Farm.AutoCoin = v end)
    ToggleButton("Auto TP Düşen Silaha", Config.Farm.AutoTPGun, function(v) Config.Farm.AutoTPGun = v end)
    ActionButton("🔫 Şimdi Silaha Teleport Et", Color3.fromRGB(255, 140, 0), function()
        local gun = FindDroppedGun()
        if gun then
            local handle = gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart")
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if handle and root then
                local dist = (handle.Position - root.Position).Magnitude
                local t = TweenService:Create(root,
                    TweenInfo.new(math.min(dist / 40, 1.5), Enum.EasingStyle.Linear),
                    {CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))})
                t:Play()
            end
        else
            SafeCall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "🔫 Silah Yok",
                    Text = "Şu an düşen silah bulunmuyor.",
                    Duration = 3
                })
            end)
        end
    end)

    -- FLING
    SectionLabel("💥 FLING — Hedef Seç")
    local flingList = Instance.new("Frame")
    flingList.Size = UDim2.new(1, 0, 0, 200)
    flingList.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    flingList.BackgroundTransparency = 0.4
    flingList.BorderSizePixel = 0
    flingList.ZIndex = 6
    flingList.Parent = scroll
    Instance.new("UICorner", flingList).CornerRadius = UDim.new(0, 8)

    local flingScroll = Instance.new("ScrollingFrame")
    flingScroll.Size = UDim2.new(1, -8, 1, -8)
    flingScroll.Position = UDim2.new(0, 4, 0, 4)
    flingScroll.BackgroundTransparency = 1
    flingScroll.BorderSizePixel = 0
    flingScroll.ScrollBarThickness = 4
    flingScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    flingScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    flingScroll.ZIndex = 6
    flingScroll.Parent = flingList
    local flLay = Instance.new("UIListLayout", flingScroll)
    flLay.Padding = UDim.new(0, 4)
    flLay.SortOrder = Enum.SortOrder.LayoutOrder

    local function RefreshFlingList()
        for _, c in ipairs(flingScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local role = GetRole(plr)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 32)
            b.BackgroundColor3 = Color3.fromRGB(60, 60, 84)
            b.BackgroundTransparency = 0.3
            b.Text = "   " .. plr.Name .. "  [" .. role .. "]"
            b.TextColor3 = RoleColor(role)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 13
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.ZIndex = 7
            b.Parent = flingScroll
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            b.MouseButton1Click:Connect(function()
                SafeCall(function()
                    b.Text = "   ⏳ " .. plr.Name .. " fırlatılıyor..."
                    b.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
                end)
                task.spawn(function()
                    FlingPlayer(plr)
                    task.wait(1)
                    if b.Parent then
                        b.Text = "   " .. plr.Name .. "  [" .. GetRole(plr) .. "]"
                        b.BackgroundColor3 = Color3.fromRGB(60, 60, 84)
                    end
                end)
            end)
        end
    end
    RefreshFlingList()
    Threads[#Threads+1] = task.spawn(function()
        while task.wait(2) do SafeCall(RefreshFlingList) end
    end)

    -- DİĞER
    SectionLabel("🛠️ DİĞER")
    ToggleButton("Anti-AFK", Config.Misc.AntiAFK, function(v) Config.Misc.AntiAFK = v end)

    ActionButton("🔄 Karakteri Sıfırla", Color3.fromRGB(180, 60, 60), function()
        SafeCall(function() LocalPlayer.Character:BreakJoints() end)
    end)
    ActionButton("✖ Menüyü Gizle", Color3.fromRGB(60, 60, 90), function()
        main.Visible = false
    end)

    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

    -- REOPEN BUTONU (Kapanınca geri açmak için)
    local reopen = Instance.new("TextButton")
    reopen.Size = UDim2.new(0, 50, 0, 50)
    reopen.Position = UDim2.new(0, 15, 0.5, -25)
    reopen.BackgroundColor3 = Color3.fromRGB(80, 90, 220)
    reopen.BackgroundTransparency = 0.2
    reopen.Text = "🎯"
    reopen.TextColor3 = Color3.new(1, 1, 1)
    reopen.Font = Enum.Font.GothamBold
    reopen.TextSize = 24
    reopen.Parent = gui
    Instance.new("UICorner", reopen).CornerRadius = UDim.new(1, 0)

    local rDrag, rStart, rPos
    reopen.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            rDrag = true; rStart = input.Position; rPos = reopen.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then rDrag = false end
            end)
        end
    end)
    reopen.InputChanged:Connect(function(input)
        if rDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - rStart
            reopen.Position = UDim2.new(rPos.X.Scale, rPos.X.Offset + d.X,
                                         rPos.Y.Scale, rPos.Y.Offset + d.Y)
        end
    end)

    local isOpen = true
    reopen.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            main.Visible = true
            main.Size = UDim2.new(0, 420, 0, 0)
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 420, 0, 600)}):Play()
        else
            TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 420, 0, 0)}):Play()
            task.wait(0.2)
            main.Visible = false
        end
    end)

    -- ATEŞ BUTONU
    local fireBtn = Instance.new("TextButton")
    fireBtn.Name = "FireButton"
    fireBtn.Size = UDim2.new(0, 160, 0, 75)
    fireBtn.Position = UDim2.new(1, -180, 1, -120)
    fireBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    fireBtn.BackgroundTransparency = 0.15
    fireBtn.Text = "🔥 ATEŞ"
    fireBtn.TextColor3 = Color3.new(1, 1, 1)
    fireBtn.Font = Enum.Font.GothamBold
    fireBtn.TextSize = 22
    fireBtn.Visible = Config.SilentAim.GunEnabled
    fireBtn.Active = true
    fireBtn.ZIndex = 20
    fireBtn.Parent = gui
    Instance.new("UICorner", fireBtn).CornerRadius = UDim.new(0, 16)

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Color3.fromRGB(255, 200, 200)
    fStroke.Thickness = 2
    fStroke.Transparency = 0.4
    fStroke.Parent = fireBtn

    FireButton = fireBtn

    local fDrag, fStart, fPos
    fireBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            fDrag = true; fStart = input.Position; fPos = fireBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    fDrag = false
                    FireHeld = false
                    fireBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                end
            end)
        end
    end)
    fireBtn.InputChanged:Connect(function(input)
        if fDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - fStart
            if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then
                fireBtn.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + d.X,
                                              fPos.Y.Scale, fPos.Y.Offset + d.Y)
            end
        end
    end)
    fireBtn.MouseButton1Down:Connect(function()
        FireHeld = true
        fireBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        SafeCall(TryAutoFire)
    end)
    fireBtn.MouseButton1Up:Connect(function()
        FireHeld = false
        fireBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end)
    fireBtn.TouchLongPress:Connect(function() FireHeld = true end)
    fireBtn.MouseLeave:Connect(function()
        FireHeld = false
        fireBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end)
end

-- ============================================================
-- BAŞLAT
-- ============================================================
SafeCall(SetupSilentAim)
SafeCall(SetupAntiAFK)
SafeCall(ApplyWalkSpeed)

Threads[#Threads+1] = task.spawn(function() SafeCall(ESPUpdateLoop) end)
Threads[#Threads+1] = task.spawn(function() SafeCall(TracerLoop) end)
Threads[#Threads+1] = task.spawn(function() SafeCall(AutoKillLoop) end)
Threads[#Threads+1] = task.spawn(function() SafeCall(AutoFarmLoop) end)
Threads[#Threads+1] = task.spawn(function() SafeCall(AutoTPGunLoop) end)
Threads[#Threads+1] = task.spawn(function() SafeCall(BunnyHopLoop) end)
Threads[#Threads+1] = task.spawn(function() SafeCall(SpinBotLoop) end)
Threads[#Threads+1] = task.spawn(function() SafeCall(AutoFireLoop) end)

SafeCall(BuildUI)

print("✅ MM2 Ultimate v7 'Skyfall' yüklendi!")
print("🎨 3D animasyonlu gökyüzü menüsü aktif.")
print("💥 Fling, Aim ve Auto Kill mantığı güncellendi.")
