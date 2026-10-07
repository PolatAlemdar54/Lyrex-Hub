-- =======================================================
--      LYREX HUB 🔮 | MM2 ULTIMATE MOBILE EDITION
-- =======================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ÖNCEKİ MENÜLERİ VE BLUR EFEKTLERİNİ TEMİZLE
for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
    if v:IsA("BlurEffect") then v:Destroy() end
end
if CoreGui:FindFirstChild("LyrexMainUI") then CoreGui.LyrexMainUI:Destroy() end

-- SISTEM DEĞİŞKENLERİ
local Config = {
    ESP_Players = false,
    ESP_Gun = false,
    AutoCoin = false,
    Noclip = false,
    WalkSpeed = 16,
    JumpPower = 50,
    SpeedToggle = false,
    JumpToggle = false,
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

-- YARDIMCI FONKSİYONLAR
local function GetRole(plr)
    if not plr or not plr.Character then return "Innocent" end
    if plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife") then return "Murderer" end
    if plr.Backpack:FindFirstChild("Gun") or plr.Character:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
end

-- GUI OLUŞTURMA
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LyrexMainUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- MOBİL AÇMA/KAPAMA BUTONU (🔮)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 220)
ToggleBtn.Text = "🔮"
ToggleBtn.TextSize = 26
ToggleBtn.Active = true
ToggleBtn.Draggable = true

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(1, 0)
BtnCorner.Parent = ToggleBtn

-- ANA PENCERE
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 440, 0, 270)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -135)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- BAŞLIK BAR
local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.Size = UDim2.new(1, -40, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.Text = "Lyrex Hub 🔮 | MM2 Ultimate"
TitleText.TextColor3 = Color3.fromRGB(180, 100, 255)
TitleText.TextSize = 16
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -33, 0, 2)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.BackgroundTransparency = 1

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- TAB MENÜSÜ
local TabHolder = Instance.new("Frame")
TabHolder.Parent = MainFrame
TabHolder.Position = UDim2.new(0, 5, 0, 40)
TabHolder.Size = UDim2.new(0, 110, 1, -45)
TabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 35)

local TabList = Instance.new("UIListLayout")
TabList.Parent = TabHolder
TabList.Padding = UDim.new(0, 4)

local ContentHolder = Instance.new("Frame")
ContentHolder.Parent = MainFrame
ContentHolder.Position = UDim2.new(0, 120, 0, 40)
ContentHolder.Size = UDim2.new(1, -125, 1, -45)
ContentHolder.BackgroundTransparency = 1

local Pages = {}

local function AddTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = TabHolder
    TabBtn.Size = UDim2.new(1, 0, 0, 30)
    TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    TabBtn.TextSize = 12
    TabBtn.Font = Enum.Font.SourceSansBold

    local Page = Instance.new("ScrollingFrame")
    Page.Parent = ContentHolder
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 2, 0)
    Page.ScrollBarThickness = 3

    local PageList = Instance.new("UIListLayout")
    PageList.Parent = Page
    PageList.Padding = UDim.new(0, 6)

    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do
            p.Page.Visible = false
            p.Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 220)
    end)

    table.insert(Pages, {Btn = TabBtn, Page = Page})
    return Page
end

-- UI DÜĞME VE TOGGLE EKLENICILERI
local function AddToggle(page, label, default, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = page
    btn.Size = UDim2.new(1, -10, 0, 32)
    local state = default
    btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(50, 50, 65)
    btn.Text = label .. ": " .. (state and "AÇIK" or "KAPALI")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(50, 50, 65)
        btn.Text = label .. ": " .. (state and "AÇIK" or "KAPALI")
        callback(state)
    end)
end

local function AddButton(page, label, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = page
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(120, 40, 220)
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

-- TABLARI OLUŞTUR
local PageESP = AddTab("Visuals & ESP")
local PageCombat = AddTab("Combat & Aim")
local PageSkins = AddTab("Skin Changer")
local PageMove = AddTab("Movement")
local PageTele = AddTab("Teleports")

Pages[1].Page.Visible = true
Pages[1].Btn.BackgroundColor3 = Color3.fromRGB(120, 40, 220)

-- =======================================================
-- 1. VISUALS & ESP
-- =======================================================
AddToggle(PageESP, "Player Role ESP", false, function(v) Config.ESP_Players = v end)
AddToggle(PageESP, "Gun Drop ESP", false, function(v) Config.ESP_Gun = v end)

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
end)

-- =======================================================
-- 2. COMBAT & AIM
-- =======================================================
AddButton(PageCombat, "🎯 Katile Otomatik Ateş Et", function()
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

-- =======================================================
-- 3. SKIN CHANGER
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
-- 4. MOVEMENT
-- =======================================================
AddToggle(PageMove, "Noclip (Duvar Geçme)", false, function(v) Config.Noclip = v end)
AddToggle(PageMove, "Hızlı Koşma (Speed 50)", false, function(v) 
    Config.SpeedToggle = v 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v and 50 or 16
    end
end)
AddToggle(PageMove, "Yüksek Zıplama (Jump 100)", false, function(v) 
    Config.JumpToggle = v 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v and 100 or 50
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
-- 5. TELEPORTS
-- =======================================================
AddButton(PageTele, "🔫 Düşen Silaha Işınlan", function()
    local gunDrop = Workspace:FindFirstChild("GunDrop", true)
    if gunDrop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
    end
end)

AddButton(PageTele, "🏠 Lobiye Işınlan", function()
    local lobby = Workspace:FindFirstChild("Lobby")
    if lobby and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = lobby:GetModelCFrame()
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
