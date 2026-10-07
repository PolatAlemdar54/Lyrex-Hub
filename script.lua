-- =======================================================
--      LYREX HUB v11 🔮 | MM2 FULL-PACK (BYPASS EDITION)
-- =======================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- BLUR VE ESKİ MENÜ TEMİZLİĞİ
for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("BlurEffect") then v:Destroy() end
end
if CoreGui:FindFirstChild("LyrexFullHub") then CoreGui.LyrexFullHub:Destroy() end

-- AYARLAR VE DEĞİŞKENLER
local Config = {
    ESP_Players = false,
    ESP_Gun = false,
    ESP_Coins = false,
    AutoFarmCoins = false,
    Noclip = false,
    WalkSpeed = 25, -- Kick yememek için güvenli 25 hızı
    SpeedToggle = false,
    JumpPower = 70, -- Safe Jump
    JumpToggle = false,
    InfiniteJump = false,
    SpinBot = false,
    SpinSpeed = 30
}

local KnifeSkins = {
    ["Corrupt"] = {Mesh = "rbxassetid://247000808", Texture = "rbxassetid://247000825"},
    ["Harvester"] = {Mesh = "rbxassetid://11382408013", Texture = "rbxassetid://11382407886"},
    ["Nik's Scythe"] = {Mesh = "rbxassetid://193026211", Texture = "rbxassetid://193026227"},
    ["Candy"] = {Mesh = "rbxassetid://321285226", Texture = "rbxassetid://321285244"},
    ["Icebreaker"] = {Mesh = "rbxassetid://6112999719", Texture = "rbxassetid://6112999581"}
}

-- ANTI-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)

-- ROL TESPİTİ
local function GetRole(plr)
    if not plr or not plr.Character then return "Innocent" end
    if plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife") then return "Murderer" end
    if plr.Backpack:FindFirstChild("Gun") or plr.Character:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
end

-- GUI OLUŞTURMA
local Gui = Instance.new("ScreenGui")
Gui.Name = "LyrexFullHub"
Gui.Parent = CoreGui
Gui.ResetOnSpawn = false

-- MOBİL AÇMA BUTONU (🔮)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = Gui
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.25, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 240)
ToggleBtn.Text = "🔮"
ToggleBtn.TextSize = 24
ToggleBtn.Active = true
ToggleBtn.Draggable = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- ANA PENCERE
local MainFrame = Instance.new("Frame")
MainFrame.Parent = Gui
MainFrame.Size = UDim2.new(0, 440, 0, 280)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- BAŞLIK
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
Title.Text = "  Lyrex Hub 🔮 | MM2 Ultimate (Bypass)"
Title.TextColor3 = Color3.fromRGB(180, 100, 255)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- TAB ALANI
local TabHolder = Instance.new("Frame")
TabHolder.Parent = MainFrame
TabHolder.Position = UDim2.new(0, 6, 0, 42)
TabHolder.Size = UDim2.new(0, 110, 1, -48)
TabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 34)

local TabList = Instance.new("UIListLayout", TabHolder)
TabList.Padding = UDim.new(0, 4)

local ContentHolder = Instance.new("Frame")
ContentHolder.Parent = MainFrame
ContentHolder.Position = UDim2.new(0, 122, 0, 42)
ContentHolder.Size = UDim2.new(1, -128, 1, -48)
ContentHolder.BackgroundTransparency = 1

local Pages = {}

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = TabHolder
    TabBtn.Size = UDim2.new(1, 0, 0, 28)
    TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    TabBtn.TextSize = 11
    TabBtn.Font = Enum.Font.SourceSansBold

    local Page = Instance.new("ScrollingFrame")
    Page.Parent = ContentHolder
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 3, 0)
    Page.ScrollBarThickness = 3

    local PageList = Instance.new("UIListLayout", Page)
    PageList.Padding = UDim.new(0, 5)

    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do
            p.Page.Visible = false
            p.Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 240)
    end)

    table.insert(Pages, {Btn = TabBtn, Page = Page})
    return Page
end

-- UI DÜĞME/TOGGLE YARDIMCILARI
local function AddToggle(page, label, default, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = page
    btn.Size = UDim2.new(1, -8, 0, 30)
    local state = default
    btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(45, 45, 58)
    btn.Text = label .. ": " .. (state and "AÇIK" or "KAPALI")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(45, 45, 58)
        btn.Text = label .. ": " .. (state and "AÇIK" or "KAPALI")
        callback(state)
    end)
end

local function AddButton(page, label, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = page
    btn.Size = UDim2.new(1, -8, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(140, 40, 240)
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click(callback)
end

ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- SEKMELER
local PageESP = CreateTab("Visuals & ESP")
local PageCombat = CreateTab("Combat & Aim")
local PageFarm = CreateTab("Auto Farm")
local PageSkins = CreateTab("Skin Changer")
local PageMove = CreateTab("Movement")
local PageTele = CreateTab("Teleports")

Pages[1].Page.Visible = true
Pages[1].Btn.BackgroundColor3 = Color3.fromRGB(140, 40, 240)

-- =======================================================
-- 1. VISUALS & ESP
-- =======================================================
AddToggle(PageESP, "Player Role ESP", false, function(v) Config.ESP_Players = v end)
AddToggle(PageESP, "Gun Drop ESP", false, function(v) Config.ESP_Gun = v end)
AddToggle(PageESP, "Coin ESP", false, function(v) Config.ESP_Coins = v end)

RunService.RenderStepped:Connect(function()
    if Config.ESP_Players then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hl = plr.Character:FindFirstChild("LyrexESP") or Instance.new("Highlight", plr.Character)
                hl.Name = "LyrexESP"
                local role = GetRole(plr)
                hl.FillColor = role == "Murderer" and Color3.fromRGB(255,40,40) or (role == "Sheriff" and Color3.fromRGB(40,120,255) or Color3.fromRGB(40,255,40))
            end
        end
    end

    if Config.ESP_Gun then
        local gunDrop = Workspace:FindFirstChild("GunDrop", true)
        if gunDrop then
            local hl = gunDrop:FindFirstChild("GunESP") or Instance.new("Highlight", gunDrop)
            hl.Name = "GunESP"
            hl.FillColor = Color3.fromRGB(255, 215, 0)
        end
    end

    if Config.ESP_Coins then
        local coinContainer = Workspace:FindFirstChild("Normal", true) or Workspace:FindFirstChild("CoinContainer", true)
        if coinContainer then
            for _, coin in pairs(coinContainer:GetChildren()) do
                if coin:IsA("BasePart") and not coin:FindFirstChild("CoinESP") then
                    local hl = Instance.new("Highlight", coin)
                    hl.Name = "CoinESP"
                    hl.FillColor = Color3.fromRGB(255, 255, 0)
                end
            end
        end
    end
end)

-- =======================================================
-- 2. COMBAT & AIM
-- =======================================================
AddButton(PageCombat, "🎯 Katile Otomatik Ateş Et (Sheriff)", function()
    local char = LocalPlayer.Character
    local gun = char and (char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun"))
    if not gun then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if GetRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if gun.Parent == LocalPlayer.Backpack then gun.Parent = char end
            local remote = gun:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("ShootGun", true)
            if remote then remote:FireServer(plr.Character.HumanoidRootPart.Position) end
            break
        end
    end
end)

AddButton(PageCombat, "🔪 En Yakındakine Bıçak At", function()
    local char = LocalPlayer.Character
    local knife = char and (char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
    if not knife then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if knife.Parent == LocalPlayer.Backpack then knife.Parent = char end
            local remote = knife:FindFirstChild("Throw") or ReplicatedStorage:FindFirstChild("Throw", true)
            if remote then remote:FireServer(plr.Character.HumanoidRootPart.Position, CFrame.new()) end
            break
        end
    end
end)

AddButton(PageCombat, "⚡ SpinBot (Faydadan Kaçma)", function()
    Config.SpinBot = not Config.SpinBot
end)

RunService.RenderStepped:Connect(function()
    if Config.SpinBot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0)
    end
end)

-- =======================================================
-- 3. AUTO FARM
-- =======================================================
AddToggle(PageFarm, "Auto Farm Coins (Sonsuz Para)", false, function(v) Config.AutoFarmCoins = v end)

task.spawn(function()
    while task.wait(0.3) do
        if Config.AutoFarmCoins and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local coinContainer = Workspace:FindFirstChild("Normal", true) or Workspace:FindFirstChild("CoinContainer", true)
            if coinContainer then
                for _, coin in pairs(coinContainer:GetChildren()) do
                    if Config.AutoFarmCoins and coin:IsA("BasePart") and coin.Transparency < 1 then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = coin.CFrame
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end)

-- =======================================================
-- 4. SKIN CHANGER
-- =======================================================
for skinName, skinData in pairs(KnifeSkins) do
    AddButton(PageSkins, "✨ " .. skinName .. " Skini Giydir", function()
        local char = LocalPlayer.Character
        local knife = char and (char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
        if knife and knife:FindFirstChild("Handle") then
            local mesh = knife.Handle:FindFirstChildOfClass("SpecialMesh") or knife.Handle
            if mesh:IsA("SpecialMesh") then
                mesh.MeshId = skinData.Mesh
                mesh.TextureId = skinData.Texture
            end
        end
    end)
end

-- =======================================================
-- 5. MOVEMENT (BYPASS SİSTEMİ)
-- =======================================================
AddToggle(PageMove, "Noclip (Duvar Geçme)", false, function(v) Config.Noclip = v end)

-- CFRAME BYPASS: WalkSpeed değerini 16 tutarak anti-cheat yakalamasını önler
AddToggle(PageMove, "Bypass Hızlı Koşma (Speed 25)", false, function(v) 
    Config.SpeedToggle = v 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

RunService.Heartbeat:Connect(function(delta)
    if Config.SpeedToggle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hum = LocalPlayer.Character.Humanoid
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (Config.WalkSpeed - 16) * delta)
        end
    end
end)

AddToggle(PageMove, "Güvenli Zıplama (Jump 70)", false, function(v) 
    Config.JumpToggle = v 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v and 70 or 50
    end
end)

AddToggle(PageMove, "Sonsuz Zıplama (Infinite Jump)", false, function(v) Config.InfiniteJump = v end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- =======================================================
-- 6. TELEPORTS
-- =======================================================
AddButton(PageTele, "🔫 Düşen Silaha Işınlan", function()
    local gunDrop = Workspace:FindFirstChild("GunDrop", true)
    if gunDrop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
    end
end)

AddButton(PageTele, "🔪 Katile Işınlan", function()
    for _, plr in pairs(Players:GetPlayers()) do
        if GetRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
            break
        end
    end
end)

AddButton(PageTele, "🏠 Lobiye Işınlan", function()
    local lobby = Workspace:FindFirstChild("Lobby")
    if lobby and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = lobby:GetModelCFrame()
    end
end)
