--[[
    MM2 Ultimate Script | Delta & Diğer Executor Uyumlu
    GitHub'a yükledikten sonra loadstring ile çalıştırın:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KULLANICI_ADINIZ/REPO_ADINIZ/main/MM2_Script.lua"))()
    
    Özellikler: ESP, Silent Aim (Gun & Knife), Fling, Auto Coin Farm,
    WalkSpeed, Bunny Hop, SpinBot, Teleport, Anti-AFK
]]

-- ============================================================
-- HİZMETLER VE DEĞİŞKENLER
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Yapılandırma
local Config = {
    ESP = {
        Enabled = true,
        ShowMurderer = true,
        ShowSheriff = true,
        ShowInnocent = true,
        ShowGunDrop = true,
        ShowTracers = true,
        MaxDistance = 500
    },
    SilentAim = {
        GunEnabled = false,
        KnifeEnabled = false,
        FOV = 120,
        Smoothness = 0.15
    },
    Movement = {
        WalkSpeed = 16,
        BunnyHop = false,
        SpinBot = false,
        SpinSpeed = 5
    },
    Farm = {
        AutoCoin = false,
        FarmSpeed = 25,
        StopWhenFull = true
    },
    Misc = {
        AntiAFK = true,
        FlingTarget = nil
    }
}

-- ============================================================
-- HAFIZA YÖNETİMİ (Memory Leak Önleme)
-- ============================================================
local ESPObjects = {}      -- Oyuncu ESP nesneleri
local TracerObjects = {}   -- Tracer çizgileri
local GunDropESP = nil     -- Düşen silah ESP nesnesi
local Connections = {}     -- Bağlantılar
local Threads = {}         -- Aktif thread'ler

-- Temizleme fonksiyonu (Memory Leak önleme)
local function CleanupAll()
    for _, obj in pairs(ESPObjects) do
        if obj.Highlight then obj.Highlight:Destroy() end
        if obj.Billboard then obj.Billboard:Destroy() end
    end
    ESPObjects = {}
    
    for _, tracer in pairs(TracerObjects) do
        if tracer then tracer:Destroy() end
    end
    TracerObjects = {}
    
    if GunDropESP then
        if GunDropESP.Highlight then GunDropESP.Highlight:Destroy() end
        if GunDropESP.Billboard then GunDropESP.Billboard:Destroy() end
        GunDropESP = nil
    end
    
    for _, conn in pairs(Connections) do
        if conn and conn.Disconnect then conn:Disconnect() end
    end
    Connections = {}
    
    for _, thread in pairs(Threads) do
        if thread and thread.Cancel then thread:Cancel() end
    end
    Threads = {}
end

-- ============================================================
-- YARDIMCI FONKSİYONLAR
-- ============================================================

-- Oyuncu rolünü belirleme (MM2'ye özel)
local function GetPlayerRole(player)
    if not player or not player.Character then return "Innocent" end
    
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    -- Katil kontrolü
    if backpack and backpack:FindFirstChild("Knife") then
        return "Murderer"
    end
    if character and character:FindFirstChild("Knife") then
        return "Murderer"
    end
    
    -- Şerif kontrolü
    if backpack and backpack:FindFirstChild("Gun") then
        return "Sheriff"
    end
    if character and character:FindFirstChild("Gun") then
        return "Sheriff"
    end
    
    return "Innocent"
end

-- Rol rengini alma
local function GetRoleColor(role)
    if role == "Murderer" then
        return Color3.fromRGB(255, 0, 0)      -- Kırmızı
    elseif role == "Sheriff" then
        return Color3.fromRGB(0, 100, 255)    -- Mavi
    else
        return Color3.fromRGB(0, 255, 0)      -- Yeşil
    end
end

-- Mesafe hesaplama
local function GetDistance(player)
    if not player or not player.Character then return math.huge end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return math.huge end
    return (root.Position - Camera.CFrame.Position).Magnitude
end

-- İnsansı gecikme (Anti-Cheat Bypass)
local function HumanDelay(min, max)
    task.wait(math.random(min * 100, max * 100) / 100)
end

-- ============================================================
-- ESP SİSTEMİ
-- ============================================================
local function CreateESP(player)
    if not player or not player.Character then return end
    if player == LocalPlayer then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Zaten varsa güncelle
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        if esp.Highlight and esp.Highlight.Parent then
            return
        end
    end
    
    local role = GetPlayerRole(player)
    local color = GetRoleColor(role)
    
    -- Highlight oluştur
    local highlight = Instance.new("Highlight")
    highlight.Name = "MM2_ESP_Highlight"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    -- BillboardGui (İsim ve mesafe)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MM2_ESP_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name .. " [" .. role .. "]"
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0 studs"
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextSize = 14
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = billboard
    
    ESPObjects[player] = {
        Highlight = highlight,
        Billboard = billboard,
        NameLabel = nameLabel,
        DistanceLabel = distanceLabel,
        Character = character
    }
end

-- ESP temizleme (tek oyuncu)
local function RemoveESP(player)
    local esp = ESPObjects[player]
    if not esp then return end
    
    if esp.Highlight and esp.Highlight.Parent then
        esp.Highlight:Destroy()
    end
    if esp.Billboard and esp.Billboard.Parent then
        esp.Billboard:Destroy()
    end
    
    ESPObjects[player] = nil
end

-- Tüm oyuncular için ESP güncelle
local function UpdateAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESP(player)
        end
    end
end

-- ESP döngüsü (Throttling ile optimize edilmiş)
local espAccumulator = 0
local espInterval = 1/30 -- 30 FPS'de güncelle

local function ESPLoop(deltaTime)
    espAccumulator = espAccumulator + deltaTime
    if espAccumulator < espInterval then return end
    espAccumulator = 0
    
    if not Config.ESP.Enabled then
        -- Tüm ESP'leri temizle
        for player, _ in pairs(ESPObjects) do
            RemoveESP(player)
        end
        return
    end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Character or not esp.Billboard then
            RemoveESP(player)
            continue
        end
        
        local distance = GetDistance(player)
        if distance > Config.ESP.MaxDistance then
            esp.Billboard.Enabled = false
            if esp.Highlight then esp.Highlight.Enabled = false end
        else
            esp.Billboard.Enabled = true
            if esp.Highlight then esp.Highlight.Enabled = true end
            
            -- Rol güncellemesi
            local role = GetPlayerRole(player)
            local color = GetRoleColor(role)
            
            if esp.NameLabel then
                esp.NameLabel.Text = player.Name .. " [" .. role .. "]"
                esp.NameLabel.TextColor3 = color
            end
            if esp.Highlight then
                esp.Highlight.FillColor = color
            end
            if esp.DistanceLabel then
                esp.DistanceLabel.Text = math.floor(distance) .. " studs"
            end
        end
    end
end

-- ============================================================
-- DÜŞEN SİLAH ESP
-- ============================================================
local function UpdateGunDropESP()
    -- Önceki ESP'yi temizle
    if GunDropESP then
        if GunDropESP.Highlight then GunDropESP.Highlight:Destroy() end
        if GunDropESP.Billboard then GunDropESP.Billboard:Destroy() end
        GunDropESP = nil
    end
    
    if not Config.ESP.ShowGunDrop then return end
    
    -- Düşen silahı bul
    local gun = workspace:FindFirstChild("GunDrop")
    if not gun then
        -- Alternatif isimler
        gun = workspace:FindFirstChild("Gun")
    end
    if not gun then return end
    
    local handle = gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart")
    if not handle then return end
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "MM2_GunDrop_ESP"
    highlight.FillColor = Color3.fromRGB(255, 165, 0) -- Turuncu
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = gun
    
    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MM2_GunDrop_Billboard"
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = gun
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🔫 DÜŞEN SİLAH"
    label.TextColor3 = Color3.fromRGB(255, 165, 0)
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    GunDropESP = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
        Part = handle
    }
end

-- ============================================================
-- TRACERS (Oyunculara Çizgi)
-- ============================================================
local function UpdateTracers()
    -- Tüm tracer'ları temizle
    for _, tracer in pairs(TracerObjects) do
        if tracer then tracer:Destroy() end
    end
    TracerObjects = {}
    
    if not Config.ESP.ShowTracers or not Config.ESP.Enabled then return end
    
    local cameraPos = Camera.CFrame.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        local distance = (root.Position - cameraPos).Magnitude
        if distance > Config.ESP.MaxDistance then continue end
        
        local role = GetPlayerRole(player)
        local color = GetRoleColor(role)
        
        -- Tracer çizgisi (Drawing kütüphanesi yoksa Beam kullanılabilir)
        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = Camera
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = root
        
        local beam = Instance.new("Beam")
        beam.Attachment0 = attachment0
        beam.Attachment1 = attachment1
        beam.Color = ColorSequence.new(color)
        beam.Transparency = NumberSequence.new(0.5)
        beam.Width0 = 0.05
        beam.Width1 = 0.05
        beam.FaceCamera = true
        beam.Parent = Camera
        
        table.insert(TracerObjects, beam)
        table.insert(TracerObjects, attachment0)
        table.insert(TracerObjects, attachment1)
    end
end

-- ============================================================
-- SİLAH SİLENT AİM (Şerif iken Katili vurma)
-- ============================================================
local function GetClosestTarget(roleFilter)
    local closest = nil
    local shortestDist = math.huge
    local cameraPos = Camera.CFrame.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        
        local role = GetPlayerRole(player)
        if roleFilter and role ~= roleFilter then continue end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        local dist = (root.Position - cameraPos).Magnitude
        if dist < shortestDist and dist <= Config.SilentAim.FOV then
            shortestDist = dist
            closest = player
        end
    end
    
    return closest
end

-- Silent Aim döngüsü
local function SilentAimLoop()
    while task.wait(0.1) do
        if not Config.SilentAim.GunEnabled then continue end
        
        local target = GetClosestTarget("Murderer")
        if not target then continue end
        
        local character = target.Character
        if not character then continue end
        
        local head = character:FindFirstChild("Head")
        if not head then continue end
        
        -- Kamera hedefe yönlendir (Silent Aim)
        local cameraPos = Camera.CFrame.Position
        local direction = (head.Position - cameraPos).Unit
        
        -- İnsansı gecikme ile yumuşak geçiş
        local tween = TweenService:Create(
            Camera,
            TweenInfo.new(Config.SilentAim.Smoothness, Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(cameraPos, cameraPos + direction)}
        )
        tween:Play()
        
        HumanDelay(0.05, 0.15)
    end
end

-- ============================================================
-- BIÇAK SİLENT AİM (Katil iken yakındaki oyuncuları avlama)
-- ============================================================
local function KnifeSilentAimLoop()
    while task.wait(0.2) do
        if not Config.SilentAim.KnifeEnabled then continue end
        
        local character = LocalPlayer.Character
        if not character then continue end
        
        -- Katil mi kontrol et
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local isMurderer = (backpack and backpack:FindFirstChild("Knife")) or 
                           (character and character:FindFirstChild("Knife"))
        if not isMurderer then continue end
        
        -- En yakın oyuncuyu bul
        local closest = nil
        local shortestDist = math.huge
        local myRoot = character:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer or not player.Character then continue end
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist < shortestDist and dist < 15 then -- 15 stud mesafe
                shortestDist = dist
                closest = player
            end
        end
        
        if closest and closest.Character then
            local targetRoot = closest.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                -- Hedefe doğru ışınlanma (insansı gecikme ile)
                local tween = TweenService:Create(
                    myRoot,
                    TweenInfo.new(0.1, Enum.EasingStyle.Linear),
                    {CFrame = targetRoot.CFrame}
                )
                tween:Play()
                
                -- Bıçak saldırısı
                task.wait(0.1)
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
            end
        end
    end
end

-- ============================================================
-- FLING (Hedef Oyuncuyu Fırlatma)
-- ============================================================
local function FlingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Fling vektörü (harita dışına doğru)
    local flingDirection = Vector3.new(0, 500, 0) -- Yukarı doğru fırlat
    local randomOffset = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
    
    -- İnsansı gecikme
    HumanDelay(0.1, 0.3)
    
    -- Hedefi fırlat
    targetRoot.Velocity = flingDirection + randomOffset
    targetRoot.RotVelocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
end

-- Fling döngüsü
local function FlingLoop()
    while task.wait(0.5) do
        if not Config.Misc.FlingTarget then continue end
        
        local target = Config.Misc.FlingTarget
        if target and target.Character then
            FlingPlayer(target)
        else
            Config.Misc.FlingTarget = nil
        end
    end
end

-- ============================================================
-- AUTO COIN FARM
-- ============================================================
local function GetClosestCoin()
    local closest = nil
    local shortestDist = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    -- Coin container'ı bul
    local coinFolder = workspace:FindFirstChild("CoinFolder") or 
                       workspace:FindFirstChild("Coins") or
                       workspace:FindFirstChild("CoinContainer")
    
    if not coinFolder then
        -- Tüm workspace'te coin ara
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("coin") and obj:IsA("BasePart") then
                local dist = (obj.Position - myRoot.Position).Magnitude
                if dist < shortestDist and dist < 500 then
                    shortestDist = dist
                    closest = obj
                end
            end
        end
    else
        for _, coin in pairs(coinFolder:GetChildren()) do
            if coin:IsA("BasePart") then
                local dist = (coin.Position - myRoot.Position).Magnitude
                if dist < shortestDist and dist < 500 then
                    shortestDist = dist
                    closest = coin
                end
            end
        end
    end
    
    return closest
end

-- Auto Farm döngüsü (Throttling ile)
local farmAccumulator = 0
local farmInterval = 0.5 -- 2 saniyede bir kontrol

local function AutoFarmLoop(deltaTime)
    farmAccumulator = farmAccumulator + deltaTime
    if farmAccumulator < farmInterval then return end
    farmAccumulator = 0
    
    if not Config.Farm.AutoCoin then return end
    
    -- Çanta doluluk kontrolü (MM2'de çanta limiti)
    if Config.Farm.StopWhenFull then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local coinCount = 0
            for _, item in pairs(backpack:GetChildren()) do
                if item.Name:lower():find("coin") then
                    coinCount = coinCount + 1
                end
            end
            if coinCount >= 50 then -- Varsayılan limit
                return
            end
        end
    end
    
    local coin = GetClosestCoin()
    if not coin then return end
    
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    -- İnsansı gecikme
    HumanDelay(0.1, 0.2)
    
    -- Coin'e doğru Tween ile hareket (anti-cheat bypass)
    local distance = (coin.Position - myRoot.Position).Magnitude
    local travelTime = distance / Config.Farm.FarmSpeed
    
    local tween = TweenService:Create(
        myRoot,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(coin.Position + Vector3.new(0, 3, 0))}
    )
    tween:Play()
end

-- ============================================================
-- HAREKET SİSTEMİ
-- ============================================================

-- WalkSpeed güncelleme
local function UpdateWalkSpeed()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    humanoid.WalkSpeed = Config.Movement.WalkSpeed
end

-- Bunny Hop döngüsü
local function BunnyHopLoop()
    while task.wait(0.1) do
        if not Config.Movement.BunnyHop then continue end
        
        local character = LocalPlayer.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then continue end
        
        -- Yerde mi kontrol et
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
        end
    end
end

-- SpinBot döngüsü
local function SpinBotLoop()
    while task.wait(0.03) do
        if not Config.Movement.SpinBot then continue end
        
        local character = LocalPlayer.Character
        if not character then continue end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        -- 360 derece dönüş
        local currentCFrame = root.CFrame
        local rotatedCFrame = currentCFrame * CFrame.Angles(0, math.rad(Config.Movement.SpinSpeed), 0)
        root.CFrame = rotatedCFrame
    end
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
local function AntiAFK()
    local vu = game:GetService("VirtualUser")
    
    Connections[#Connections + 1] = LocalPlayer.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end

-- ============================================================
-- ANA DÖNGÜLER (RenderStepped Optimizasyonu)
-- ============================================================
local lastUpdate = tick()

Connections[#Connections + 1] = RunService.RenderStepped:Connect(function(deltaTime)
    local now = tick()
    if now - lastUpdate < 1/60 then return end -- 60 FPS sınırı
    lastUpdate = now
    
    -- Throttling uygulanmış döngüler
    if Config.ESP.Enabled then
        ESPLoop(deltaTime)
        UpdateTracers()
    end
    
    if Config.Farm.AutoCoin then
        AutoFarmLoop(deltaTime)
    end
end)

-- Düşen silah ESP'sini periyodik güncelle
Threads[#Threads + 1] = task.spawn(function()
    while task.wait(1) do
        if Config.ESP.ShowGunDrop and Config.ESP.Enabled then
            UpdateGunDropESP()
        end
    end
end)

-- ============================================================
-- OYUNCU OLAYLARI
-- ============================================================
Connections[#Connections + 1] = Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.ESP.Enabled then
            CreateESP(player)
        end
    end)
end)

Connections[#Connections + 1] = Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Mevcut oyuncular için ESP başlat
UpdateAllESP()

-- ============================================================
-- SCRIPT BAŞLATMA
-- ============================================================
-- Hareket döngülerini başlat
Threads[#Threads + 1] = task.spawn(BunnyHopLoop)
Threads[#Threads + 1] = task.spawn(SpinBotLoop)
Threads[#Threads + 1] = task.spawn(SilentAimLoop)
Threads[#Threads + 1] = task.spawn(KnifeSilentAimLoop)
Threads[#Threads + 1] = task.spawn(FlingLoop)

-- Anti-AFK başlat
if Config.Misc.AntiAFK then
    AntiAFK()
end

-- WalkSpeed başlangıç değeri
UpdateWalkSpeed()

-- ============================================================
-- KULLANICI ARAYÜZÜ (Basit, Modern UI)
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Ultimate_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Ana Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 500)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Yuvarlak köşeler
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Başlık
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
Title.Text = "🔪 MM2 Ultimate Script"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = Title

-- Kapatma butonu
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- İçerik Alanı (Scroll)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -60)
ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
ScrollFrame.Parent = MainFrame

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.Padding = UDim.new(0, 8)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollLayout.Parent = ScrollFrame

-- Buton oluşturma yardımcısı
local function CreateToggleButton(text, initialState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = initialState and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 80)
    btn.Text = text .. (initialState and " [AÇIK]" or " [KAPALI]")
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = ScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local state = initialState
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 80)
        btn.Text = text .. (state and " [AÇIK]" or " [KAPALI]")
        callback(state)
    end)
    
    return btn
end

-- Ana kategoriler
local categories = {
    { name = "ESP", items = {
        { "Tüm ESP", "ESP.Enabled", function(v) Config.ESP.Enabled = v end },
        { "Tracers", "ESP.ShowTracers", function(v) Config.ESP.ShowTracers = v end },
        { "Düşen Silah ESP", "ESP.ShowGunDrop", function(v) Config.ESP.ShowGunDrop = v end },
    }},
    { name = "Combat", items = {
        { "Silah Silent Aim", "SilentAim.GunEnabled", function(v) Config.SilentAim.GunEnabled = v end },
        { "Bıçak Silent Aim", "SilentAim.KnifeEnabled", function(v) Config.SilentAim.KnifeEnabled = v end },
    }},
    { name = "Movement", items = {
        { "Bunny Hop", "Movement.BunnyHop", function(v) Config.Movement.BunnyHop = v end },
        { "SpinBot", "Movement.SpinBot", function(v) Config.Movement.SpinBot = v end },
    }},
    { name = "Farm", items = {
        { "Auto Coin Farm", "Farm.AutoCoin", function(v) Config.Farm.AutoCoin = v end },
    }},
    { name = "Misc", items = {
        { "Anti-AFK", "Misc.AntiAFK", function(v) Config.Misc.AntiAFK = v end },
    }}
}

-- Kategorileri ve butonları oluştur
for _, category in pairs(categories) do
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    header.Text = "  " .. category.name
    header.TextColor3 = Color3.fromRGB(150, 200, 255)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 15
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = ScrollFrame
    
    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 6)
    hCorner.Parent = header
    
    for _, item in pairs(category.items) do
        local currentState = false
        -- Mevcut durumu al
        if item[2] == "ESP.Enabled" then currentState = Config.ESP.Enabled end
        if item[2] == "ESP.ShowTracers" then currentState = Config.ESP.ShowTracers end
        if item[2] == "ESP.ShowGunDrop" then currentState = Config.ESP.ShowGunDrop end
        if item[2] == "SilentAim.GunEnabled" then currentState = Config.SilentAim.GunEnabled end
        if item[2] == "SilentAim.KnifeEnabled" then currentState = Config.SilentAim.KnifeEnabled end
        if item[2] == "Movement.BunnyHop" then currentState = Config.Movement.BunnyHop end
        if item[2] == "Movement.SpinBot" then currentState = Config.Movement.SpinBot end
        if item[2] == "Farm.AutoCoin" then currentState = Config.Farm.AutoCoin end
        if item[2] == "Misc.AntiAFK" then currentState = Config.Misc.AntiAFK end
        
        CreateToggleButton("  " .. item[1], currentState, item[3])
    end
end

-- WalkSpeed Slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 25)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "  WalkSpeed: " .. Config.Movement.WalkSpeed
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = ScrollFrame

local speedSlider = Instance.new("TextButton")
speedSlider.Size = UDim2.new(1, 0, 0, 25)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
speedSlider.Text = "  Hızı Artır"
speedSlider.TextColor3 = Color3.new(1, 1, 1)
speedSlider.Font = Enum.Font.Gotham
speedSlider.TextSize = 13
speedSlider.Parent = ScrollFrame

local speedSliderCorner = Instance.new("UICorner")
speedSliderCorner.CornerRadius = UDim.new(0, 6)
speedSliderCorner.Parent = speedSlider

speedSlider.MouseButton1Click:Connect(function()
    Config.Movement.WalkSpeed = math.min(Config.Movement.WalkSpeed + 10, 100)
    speedLabel.Text = "  WalkSpeed: " .. Config.Movement.WalkSpeed
    UpdateWalkSpeed()
end)

-- Fling butonu
local flingBtn = Instance.new("TextButton")
flingBtn.Size = UDim2.new(1, 0, 0, 35)
flingBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
flingBtn.Text = "  Hedefi Fırlat (Fling)"
flingBtn.TextColor3 = Color3.new(1, 1, 1)
flingBtn.Font = Enum.Font.GothamBold
flingBtn.TextSize = 14
flingBtn.Parent = ScrollFrame

local flingCorner = Instance.new("UICorner")
flingCorner.CornerRadius = UDim.new(0, 8)
flingCorner.Parent = flingBtn

flingBtn.MouseButton1Click:Connect(function()
    -- En yakın oyuncuyu hedef al
    local closest = nil
    local shortestDist = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    if closest then
        Config.Misc.FlingTarget = closest
    end
end)

-- ============================================================
-- SCRIPT SONU
-- ============================================================
print("✅ MM2 Ultimate Script başarıyla yüklendi!")
print("📌 GitHub'dan loadstring ile çalıştırıldı.")
