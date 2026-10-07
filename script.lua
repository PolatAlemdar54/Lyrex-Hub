-- =======================================================
--            LYREX HUB v4 FIX | MM2 SCRIPT
-- =======================================================

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "Lyrex Hub 🔮 | MM2 Ultimate", 
    HidePremium = false, 
    SaveConfig = false, 
    ConfigFolder = "LyrexConfig",
    IntroText = "Lyrex Hub Yükleniyor..."
})

-- MOBİL AÇMA/KAPAMA BUTONU (Yüzen 🔮 Butonu)
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("LyrexMobileControl") then
    CoreGui.LyrexMobileControl:Destroy()
end

local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "LyrexMobileControl"
MobileGui.Parent = CoreGui

local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "ToggleBtn"
OpenBtn.Parent = MobileGui
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.TextSize = 25
OpenBtn.Text = "🔮"
OpenBtn.Active = true
OpenBtn.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = OpenBtn

OpenBtn.MouseButton1Click:Connect(function()
    local OrionUI = CoreGui:FindFirstChild("Orion")
    if OrionUI then
        OrionUI.Enabled = not OrionUI.Enabled
    end
end)

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- DEĞİŞKENLER
local ESP_Players = false
local ESP_GunDrop = false
local AutoFarmCoins = false
local Noclip = false
local BunnyHop = false
local SpinBot = false
local WalkSpeedToggle = false
local JumpPowerToggle = false
local CustomSpeed = 16
local CustomJump = 50
local SpinSpeed = 30
local SilentAimSheriff = false
local SilentAimMurderer = false
local SelectedFlingTarget = ""
local SelectedSkin = "Corrupt"

-- SKIN CHANGER VERİLERİ
local KnifeSkinsData = {
    ["Nik's Scythe"] = {Mesh = "rbxassetid://193026211", Texture = "rbxassetid://193026227"},
    ["Corrupt"] = {Mesh = "rbxassetid://247000808", Texture = "rbxassetid://247000825"},
    ["Harvester"] = {Mesh = "rbxassetid://11382408013", Texture = "rbxassetid://11382407886"},
    ["Candy"] = {Mesh = "rbxassetid://321285226", Texture = "rbxassetid://321285244"},
    ["Icebreaker"] = {Mesh = "rbxassetid://6112999719", Texture = "rbxassetid://6112999581"}
}

-- ANTI-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)

-- YARDIMCI FONKSİYONLAR
local function GetRole(plr)
    if not plr or not plr.Character then return "Innocent" end
    if plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife") then
        return "Murderer"
    elseif plr.Backpack:FindFirstChild("Gun") or plr.Character:FindFirstChild("Gun") then
        return "Sheriff"
    end
    return "Innocent"
end

local function IsVisible(targetPart)
    if not targetPart or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = (destination - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

-- TABLAR
local TabMain = Window:MakeTab({Name = "Visuals & ESP", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TabCombat = Window:MakeTab({Name = "Combat & Aim", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TabSkins = Window:MakeTab({Name = "Skin Changer", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TabFling = Window:MakeTab({Name = "Fling Player", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TabFarm = Window:MakeTab({Name = "Auto Farm", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TabMovement = Window:MakeTab({Name = "Movement", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TabTeleport = Window:MakeTab({Name = "Teleports", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- =======================================================
-- 1. VISUALS & ESP
-- =======================================================
TabMain:AddSection({Name = "Oyuncu ve Eşya Görüşü"})

TabMain:AddToggle({
    Name = "Player Role ESP",
    Default = false,
    Callback = function(Value)
        ESP_Players = Value
        if not Value then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character and plr.Character:FindFirstChild("LyrexESP") then
                    plr.Character.LyrexESP:Destroy()
                end
            end
        end
    end
})

TabMain:AddToggle({
    Name = "Gun Drop ESP (Düşen Silah)",
    Default = false,
    Callback = function(Value)
        ESP_GunDrop = Value
        if not Value then
            local existing = Workspace:FindFirstChild("GunDropHighlight", true)
            if existing then existing:Destroy() end
        end
    end
})

RunService.RenderStepped:Connect(function()
    if ESP_Players then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local highlight = plr.Character:FindFirstChild("LyrexESP") or Instance.new("Highlight")
                highlight.Name = "LyrexESP"
                highlight.Parent = plr.Character
                
                local role = GetRole(plr)
                if role == "Murderer" then
                    highlight.FillColor = Color3.fromRGB(255, 30, 30)
                elseif role == "Sheriff" then
                    highlight.FillColor = Color3.fromRGB(30, 140, 255)
                else
                    highlight.FillColor = Color3.fromRGB(30, 255, 30)
                end
            end
        end
    end

    if ESP_GunDrop then
        local gunDrop = Workspace:FindFirstChild("GunDrop", true)
        if gunDrop then
            local hl = gunDrop:FindFirstChild("GunDropHighlight") or Instance.new("Highlight")
            hl.Name = "GunDropHighlight"
            hl.FillColor = Color3.fromRGB(255, 215, 0)
            hl.Parent = gunDrop
        end
    end
end)

-- =======================================================
-- 2. COMBAT & AIM
-- =======================================================
TabCombat:AddSection({Name = "Şerif Otomatik Nişan"})

TabCombat:AddToggle({
    Name = "Sheriff Silent Aim Modu",
    Default = false,
    Callback = function(Value)
        SilentAimSheriff = Value
    end
})

TabCombat:AddButton({
    Name = "🎯 Katile Otomatik Ateş Et",
    Callback = function()
        if not SilentAimSheriff then
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Önce Sheriff Silent Aim modunu açın!", Time = 2})
            return
        end
        
        local char = LocalPlayer.Character
        local gun = char and (char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun"))
        if not gun then
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Üzerinizde silah yok!", Time = 2})
            return
        end
        
        local murderer = nil
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and GetRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                murderer = plr
                break
            end
        end
        
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPart = murderer.Character.HumanoidRootPart
            if IsVisible(targetPart) then
                if gun.Parent == LocalPlayer.Backpack then gun.Parent = char end
                local shootRemote = gun:FindFirstChild("KnifeServer") or gun:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("ShootGun", true)
                if shootRemote and shootRemote:IsA("RemoteEvent") then
                    shootRemote:FireServer(targetPart.Position)
                else
                    char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, targetPart.Position)
                    gun:Activate()
                end
                OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Katile ateş edildi!", Time = 2})
            else
                OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Katil duvar arkasında!", Time = 2})
            end
        else
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Oyunda aktif katil bulunamadı!", Time = 2})
        end
    end
})

TabCombat:AddSection({Name = "Katil Otomatik Nişan"})

TabCombat:AddToggle({
    Name = "Knife Silent Aim Modu",
    Default = false,
    Callback = function(Value)
        SilentAimMurderer = Value
    end
})

TabCombat:AddButton({
    Name = "🔪 En Yakındaki Oyuncuya Bıçak At",
    Callback = function()
        if not SilentAimMurderer then
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Önce Knife Silent Aim modunu açın!", Time = 2})
            return
        end
        
        local char = LocalPlayer.Character
        local knife = char and (char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
        if not knife then
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Üzerinizde bıçak yok!", Time = 2})
            return
        end
        
        local closestPlr = nil
        local shortestDist = math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if dist < shortestDist and IsVisible(plr.Character.HumanoidRootPart) then
                    shortestDist = dist
                    closestPlr = plr
                end
            end
        end
        
        if closestPlr and closestPlr.Character then
            if knife.Parent == LocalPlayer.Backpack then knife.Parent = char end
            local targetPos = closestPlr.Character.HumanoidRootPart.Position
            local throwRemote = knife:FindFirstChild("Throw") or ReplicatedStorage:FindFirstChild("Throw", true)
            if throwRemote and throwRemote:IsA("RemoteEvent") then
                throwRemote:FireServer(targetPos, CFrame.new(char.HumanoidRootPart.Position, targetPos))
            else
                char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, targetPos)
                knife:Activate()
            end
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = closestPlr.Name .. " hedefine bıçak atıldı!", Time = 2})
        else
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Görüş alanında hedef bulunamadı!", Time = 2})
        end
    end
})

-- =======================================================
-- 3. SKIN CHANGER
-- =======================================================
TabSkins:AddSection({Name = "Bıçak Kaplama Değiştirici"})

TabSkins:AddDropdown({
    Name = "Bıçak Skin Seç",
    Default = "Corrupt",
    Options = {"Nik's Scythe", "Corrupt", "Harvester", "Candy", "Icebreaker"},
    Callback = function(Value)
        SelectedSkin = Value
    end
})

TabSkins:AddButton({
    Name = "✨ Seçili Skini Uygula",
    Callback = function()
        local char = LocalPlayer.Character
        local knife = char and (char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
        if knife then
            local handle = knife:FindFirstChild("Handle")
            if handle then
                local mesh = handle:FindFirstChildOfClass("SpecialMesh") or handle
                local skinData = KnifeSkinsData[SelectedSkin]
                if skinData and mesh then
                    if mesh:IsA("SpecialMesh") then
                        mesh.MeshId = skinData.Mesh
                        mesh.TextureId = skinData.Texture
                    end
                    OrionLib:MakeNotification({Name = "Lyrex Hub", Content = SelectedSkin .. " skini uygulandı!", Time = 3})
                end
            end
        else
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Elinde veya envanterinde bıçak yok!", Time = 2})
        end
    end
})

-- =======================================================
-- 4. FLING PLAYER
-- =======================================================
TabFling:AddSection({Name = "Oyuncu Uçurma"})

local playerNames = {}
local function GetPlayerList()
    playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(playerNames, p.Name)
        end
    end
    return playerNames
end

TabFling:AddDropdown({
    Name = "Fling Yapılacak Oyuncuyu Seç",
    Default = "Seçiniz",
    Options = GetPlayerList(),
    Callback = function(Value)
        SelectedFlingTarget = Value
    end
})

TabFling:AddButton({
    Name = "🚀 Oyuncuyu Fling Et",
    Callback = function()
        if SelectedFlingTarget == "" or SelectedFlingTarget == "Seçiniz" then
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Lütfen bir oyuncu seçin!", Time = 2})
            return
        end
        
        local targetPlayer = Players:FindFirstChild(SelectedFlingTarget)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Hedef oyuncu bulunamadı!", Time = 2})
            return
        end
        
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        
        OrionLib:MakeNotification({Name = "Lyrex Hub", Content = SelectedFlingTarget .. " Fling ediliyor...", Time = 3})
        
        task.spawn(function()
            local myRoot = myChar.HumanoidRootPart
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            local oldCF = myRoot.CFrame
            
            local bAvel = Instance.new("BodyAngularVelocity")
            bAvel.Name = "FlingVelocity"
            bAvel.AngularVelocity = Vector3.new(0, 999999, 0)
            bAvel.MaxTorque = Vector3.new(0, math.huge, 0)
            bAvel.P = math.huge
            bAvel.Parent = myRoot
            
            local startTime = os.clock()
            while os.clock() - startTime < 2.5 and myChar and targetPlayer.Character and targetRoot do
                task.wait()
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
            end
            
            bAvel:Destroy()
            myRoot.CFrame = oldCF
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Fling tamamlandı!", Time = 2})
        end)
    end
})

-- =======================================================
-- 5. AUTO FARM
-- =======================================================
TabFarm:AddSection({Name = "Sikke Toplayıcı"})

TabFarm:AddToggle({
    Name = "Auto Collect Coins",
    Default = false,
    Callback = function(Value)
        AutoFarmCoins = Value
        if Value then
            task.spawn(function()
                while AutoFarmCoins do
                    task.wait(0.2)
                    pcall(function()
                        local coinContainer = Workspace:FindFirstChild("Normal") or Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("CoinServer")
                        if coinContainer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            for _, coin in pairs(coinContainer:GetChildren()) do
                                if coin:IsA("BasePart") and AutoFarmCoins and LocalPlayer.Character then
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = coin.CFrame
                                    task.wait(0.25)
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end
})

-- =======================================================
-- 6. MOVEMENT
-- =======================================================
TabMovement:AddSection({Name = "Hız & Zıplama"})

TabMovement:AddToggle({
    Name = "Özel Yürüme Hızı Aktif",
    Default = false,
    Callback = function(Value)
        WalkSpeedToggle = Value
    end
})

TabMovement:AddSlider({
    Name = "WalkSpeed (Yürüme Hızı)",
    Min = 16,
    Max = 120,
    Default = 16,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Hız",
    Callback = function(Value)
        CustomSpeed = Value
    end
})

TabMovement:AddToggle({
    Name = "Özel Zıplama Gücü Aktif",
    Default = false,
    Callback = function(Value)
        JumpPowerToggle = Value
    end
})

TabMovement:AddSlider({
    Name = "JumpPower (Zıplama Gücü)",
    Min = 50,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Güç",
    Callback = function(Value)
        CustomJump = Value
    end
})

TabMovement:AddSection({Name = "Gelişmiş Hareketler"})

TabMovement:AddToggle({
    Name = "Bunny Hop (Otomatik Zıplama)",
    Default = false,
    Callback = function(Value)
        BunnyHop = Value
    end
})

TabMovement:AddToggle({
    Name = "Spin Bot (Kendi Etrafında Dönme)",
    Default = false,
    Callback = function(Value)
        SpinBot = Value
    end
})

TabMovement:AddSlider({
    Name = "Spin Hızı",
    Min = 10,
    Max = 100,
    Default = 30,
    Color = Color3.fromRGB(255,255,255),
    Increment = 5,
    ValueName = "RPM",
    Callback = function(Value)
        SpinSpeed = Value
    end
})

TabMovement:AddToggle({
    Name = "Noclip (Duvarlardan Geçme)",
    Default = false,
    Callback = function(Value)
        Noclip = Value
    end
})

-- MOVEMENT LOOP
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if WalkSpeedToggle then
            char.Humanoid.WalkSpeed = CustomSpeed
        end
        if JumpPowerToggle then
            char.Humanoid.JumpPower = CustomJump
        end
        if BunnyHop and char.Humanoid.FloorMaterial ~= Enum.Material.Air then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    
    if Noclip and char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if SpinBot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(SpinSpeed), 0)
    end
end)

-- =======================================================
-- 7. TELEPORTS
-- =======================================================
TabTeleport:AddSection({Name = "Işınlanma"})

TabTeleport:AddButton({
    Name = "🔫 Düşen Silaha Işınlan (Gun Drop TP)",
    Callback = function()
        local gunDrop = Workspace:FindFirstChild("GunDrop", true)
        if gunDrop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Silaha ışınlanıldı!", Time = 2})
        else
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Yerde silah bulunamadı!", Time = 2})
        end
    end
})

TabTeleport:AddButton({
    Name = "🏠 Lobiye Işınlan",
    Callback = function()
        local lobby = Workspace:FindFirstChild("Lobby")
        if lobby and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = lobby:GetModelCFrame()
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Lobiye ışınlanıldı!", Time = 2})
        end
    end
})

TabTeleport:AddButton({
    Name = "🔪 Katile Işınlan (Murderer TP)",
    Callback = function()
        for _, plr in pairs(Players:GetPlayers()) do
            if GetRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Katile ışınlanıldı!", Time = 2})
                break
            end
        end
    end
})

TabTeleport:AddButton({
    Name = "👮 Şerife Işınlan (Sheriff TP)",
    Callback = function()
        for _, plr in pairs(Players:GetPlayers()) do
            if GetRole(plr) == "Sheriff" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Şerife ışınlanıldı!", Time = 2})
                break
            end
        end
    end
})

OrionLib:Init()
