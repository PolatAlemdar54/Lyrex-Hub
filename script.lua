-- =======================================================
--                LYREX HUB | MM2 SCRIPT
-- =======================================================

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "Lyrex Hub 🔮 | Murder Mystery 2", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "LyrexHubConfig",
    IntroText = "Lyrex Hub Yükleniyor..."
})

-- DEĞİŞKENLER
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoCoin = false
local Noclip = false
local ESPEnabled = false

-- TABLAR
local MainTab = Window:MakeTab({Name = "Ana Sayfa & ESP", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local FarmTab = Window:MakeTab({Name = "Auto Farm", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local MovementTab = Window:MakeTab({Name = "Hareket & Oyuncu", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TPTab = Window:MakeTab({Name = "Teleport", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- =======================================================
-- 1. ANA SAYFA & ESP (Rol Görme)
-- =======================================================
MainTab:AddSection({Name = "Visuals (ESP)"})

local function GetRole(player)
    if not player or not player.Character then return "Innocent" end
    if player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife") then
        return "Murderer"
    elseif player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun") then
        return "Sheriff"
    end
    return "Innocent"
end

MainTab:AddToggle({
    Name = "Rol ESP (Görüş Hilesi)",
    Default = false,
    Callback = function(Value)
        ESPEnabled = Value
        while ESPEnabled do
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local highlight = plr.Character:FindFirstChild("LyrexESP") or Instance.new("Highlight")
                    highlight.Name = "LyrexESP"
                    highlight.Parent = plr.Character
                    
                    local role = GetRole(plr)
                    if role == "Murderer" then
                        highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Kırmızı
                    elseif role == "Sheriff" then
                        highlight.FillColor = Color3.fromRGB(0, 0, 255) -- Mavi
                    else
                        highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Yeşil
                    end
                end
            end
            task.wait(1)
        end
        
        -- ESP Kapatıldığında Temizle
        if not ESPEnabled then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character and plr.Character:FindFirstChild("LyrexESP") then
                    plr.Character.LyrexESP:Destroy()
                end
            end
        end
    end    
})

-- =======================================================
-- 2. AUTO FARM (Sikke Toplama)
-- =======================================================
FarmTab:AddSection({Name = "Otomatik Sikke Toplayıcı"})

FarmTab:AddToggle({
    Name = "Auto Collect Coins (Otomatik Sikke)",
    Default = false,
    Callback = function(Value)
        AutoCoin = Value
        task.spawn(function()
            while AutoCoin do
                task.wait(0.1)
                pcall(function()
                    local coinContainer = Workspace:FindFirstChild("Normal") or Workspace:FindFirstChild("CoinContainer")
                    if coinContainer then
                        for _, coin in pairs(coinContainer:GetChildren()) do
                            if coin:IsA("BasePart") and AutoCoin and LocalPlayer.Character then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = coin.CFrame
                                task.wait(0.2)
                            end
                        end
                    end
                end)
            end
        end)
    end
})

-- =======================================================
-- 3. HAREKET & OYUNCI MODLARI
-- =======================================================
MovementTab:AddSection({Name = "Karakter Özellikleri"})

MovementTab:AddSlider({
    Name = "WalkSpeed (Yürüme Hızı)",
    Min = 16,
    Max = 120,
    Default = 16,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Hız",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end    
})

MovementTab:AddSlider({
    Name = "JumpPower (Zıplama Gücü)",
    Min = 50,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Güç",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end    
})

MovementTab:AddToggle({
    Name = "Noclip (Duvarlardan Geçme)",
    Default = false,
    Callback = function(Value)
        Noclip = Value
    end
})

RunService.Stepped:Connect(function()
    if Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- =======================================================
-- 4. TELEPORT (Işınlanma)
-- =======================================================
TPTab:AddSection({Name = "Işınlanma Noktaları"})

TPTab:AddButton({
    Name = "Düşen Silahı Al (Gun Drop TP)",
    Callback = function()
        local gunDrop = Workspace:FindFirstChild("GunDrop", true)
        if gunDrop and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Silaha ışınlanıldı!", Time = 3})
        else
            OrionLib:MakeNotification({Name = "Lyrex Hub", Content = "Yerde silah bulunamadı!", Time = 3})
        end
    end
})

TPTab:AddButton({
    Name = "Lobiye Işınlan",
    Callback = function()
        local lobby = Workspace:FindFirstChild("Lobby")
        if lobby and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = lobby:GetModelCFrame()
        end
    end
})

TPTab:AddButton({
    Name = "Katil'e Işınlan (Murderer)",
    Callback = function()
        for _, plr in pairs(Players:GetPlayers()) do
            if GetRole(plr) == "Murderer" and plr.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                break
            end
        end
    end
})

OrionLib:Init()
