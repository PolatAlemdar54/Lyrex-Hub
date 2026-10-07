-- =======================================================
--                LYREX HUB v2 | MM2 SCRIPT
-- =======================================================

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "Lyrex Hub 🔮 | Murder Mystery 2", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "LyrexHubConfig",
    IntroText = "Lyrex Hub v2 Yükleniyor..."
})

-- DEĞİŞKENLER
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local AutoCoin = false
local Noclip = false
local ESPEnabled = false
local CustomSpeed = 16
local CustomJump = 50
local SpeedEnabled = false
local JumpEnabled = false

local SilentAimSheriff = false
local SilentAimMurderer = false

-- TABLAR
local MainTab = Window:MakeTab({Name = "Ana Sayfa & ESP", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local CombatTab = Window:MakeTab({Name = "Combat (Silent Aim)", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local FarmTab = Window:MakeTab({Name = "Auto Farm", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local MovementTab = Window:MakeTab({Name = "Hareket", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TPTab = Window:MakeTab({Name = "Teleport", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- YARDIMCI FONKSİYONLAR
local function GetRole(player)
    if not player or not player.Character then return "Innocent" end
    if player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife") then
        return "Murderer"
    elseif player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun") then
        return "Sheriff"
    end
    return "Innocent"
end

-- Duvar Arkası / Görünürlük Kontrolü (Raycast)
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
    return false
end

-- =======================================================
-- 1. VISUALS (ESP) - OPTİMİZE
-- =======================================================
MainTab:AddSection({Name = "Visuals (ESP)"})

MainTab:AddToggle({
    Name = "Rol ESP (Görüş Hilesi)",
    Default = false,
    Callback = function(Value)
        ESPEnabled = Value
        if not ESPEnabled then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character and plr.Character:FindFirstChild("LyrexESP") then
                    plr.Character.LyrexESP:Destroy()
                end
            end
        end
    end    
})

RunService.RenderStepped:Connect(function()
    if ESPEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local highlight = plr.Character:FindFirstChild("LyrexESP")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "LyrexESP"
                    highlight.Parent = plr.Character
                end
                
                local role = GetRole(plr)
                if role == "Murderer" then
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                elseif role == "Sheriff" then
                    highlight.FillColor = Color3.fromRGB(0, 150, 255)
                else
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                end
            end
        end
    end
end)

-- =======================================================
-- 2. COMBAT (SILENT AIM & OTO ATEŞ/BIÇAK)
-- =======================================================
CombatTab:AddSection({Name = "Şerif Silent Aim"})

CombatTab:AddToggle({
    Name = "Şerif Otomatik Nişan Modu",
    Default = false,
    Callback = function(Value)
        SilentAimSheriff = Value
    end
})

CombatTab:AddButton({
    Name = "🎯 Katile Otomatik Ateş Et",
    Callback = function()
        if not SilentAimSheriff then 
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Önce Şerif Otomatik Nişan Modunu açın!", Time = 2})
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
                
                local shootRemote = gun:FindFirstChild("KnifeServer") or gun:FindFirstChild("Shoot") or game:GetService("ReplicatedStorage"):FindFirstChild("ShootGun", true)
                if shootRemote and shootRemote:IsA("RemoteEvent") then
                    shootRemote:FireServer(targetPart.Position)
                else
                    char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, targetPart.Position)
                    gun:Activate()
                end
                OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Katile mermi gönderildi!", Time = 2})
            else
                OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Katil duvar arkasında (Görünmüyor)!", Time = 2})
            end
        else
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Oyunda aktif katil bulunamadı!", Time = 2})
        end
    end
})

CombatTab:AddSection({Name = "Katil Silent Aim"})

CombatTab:AddToggle({
    Name = "Katil Bıçak Kilitlenme Modu",
    Default = false,
    Callback = function(Value)
        SilentAimMurderer = Value
    end
})

CombatTab:AddButton({
    Name = "🔪 En Yakındaki Oyuncuya Bıçak At",
    Callback = function()
        if not SilentAimMurderer then
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Önce Katil Bıçak Kilitlenme Modunu açın!", Time = 2})
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
            local throwRemote = knife:FindFirstChild("Throw") or game:GetService("ReplicatedStorage"):FindFirstChild("Throw", true)
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
-- 3. AUTO FARM
-- =======================================================
FarmTab:AddSection({Name = "Otomatik Sikke Toplayıcı"})

FarmTab:AddToggle({
    Name = "Auto Collect Coins",
    Default = false,
    Callback = function(Value)
        AutoCoin = Value
        task.spawn(function()
            while AutoCoin do
                task.wait(0.1)
                pcall(function()
                    local coinContainer = Workspace:FindFirstChild("Normal") or Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("CoinServer")
                    if coinContainer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        for _, coin in pairs(coinContainer:GetChildren()) do
                            if coin:IsA("BasePart") and AutoCoin then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = coin.CFrame
                                task.wait(0.25)
                            end
                        end
                    end
                end)
            end
        end)
    end
})

-- =======================================================
-- 4. HAREKET (KİLİTLENMİŞ HIZ VE ZIPLAMA)
-- =======================================================
MovementTab:AddSection({Name = "Karakter Özellikleri"})

MovementTab:AddToggle({
    Name = "Özel Yürüme Hızı Aktif",
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
    end
})

MovementTab:AddSlider({
    Name = "WalkSpeed (Yürüme Hızı)",
    Min = 16,
    Max = 120,
    Default = 16,
    Increment = 1,
    ValueName = "Hız",
    Callback = function(Value)
        CustomSpeed = Value
    end    
})

MovementTab:AddToggle({
    Name = "Özel Zıplama Gücü Aktif",
    Default = false,
    Callback = function(Value)
        JumpEnabled = Value
    end
})

MovementTab:AddSlider({
    Name = "JumpPower (Zıplama Gücü)",
    Min = 50,
    Max = 200,
    Default = 50,
    Increment = 1,
    ValueName = "Güç",
    Callback = function(Value)
        CustomJump = Value
    end    
})

MovementTab:AddToggle({
    Name = "Noclip (Duvarlardan Geçme)",
    Default = false,
    Callback = function(Value)
        Noclip = Value
    end
})

-- MM2 Oyununun Hız Sıfırlamasını Engelleyen Kilit Döngüsü
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if SpeedEnabled then
            char.Humanoid.WalkSpeed = CustomSpeed
        end
        if JumpEnabled then
            char.Humanoid.JumpPower = CustomJump
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

-- =======================================================
-- 5. TELEPORT (IŞINLANMA)
-- =======================================================
TPTab:AddSection({Name = "Işınlanma Noktaları"})

TPTab:AddButton({
    Name = "Düşen Silahı Al (Gun Drop TP)",
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

TPTab:AddButton({
    Name = "Lobiye Işınlan",
    Callback = function()
        local lobby = Workspace:FindFirstChild("Lobby")
        if lobby and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = lobby:GetModelCFrame()
        end
    end
})

TPTab:AddButton({
    Name = "Katil'e Işınlan (Murderer)",
    Callback = function()
        for _, plr in pairs(Players:GetPlayers()) do
            if GetRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                break
            end
        end
    end
})

OrionLib:Init()
