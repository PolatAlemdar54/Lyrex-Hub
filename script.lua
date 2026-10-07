-- =======================================================
--      LYREX HUB v5 STANDALONE (DELTA MOBILE FIX)
-- =======================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ÖNCEKİ ARAYÜZLERİ TEMİZLE
if CoreGui:FindFirstChild("LyrexHubUI") then CoreGui.LyrexHubUI:Destroy() end
if CoreGui:FindFirstChild("LyrexMobileControl") then CoreGui.LyrexMobileControl:Destroy() end

-- DEĞİŞKENLER
local ESP_Players, ESP_GunDrop, AutoFarmCoins, Noclip, BunnyHop, SpinBot = false, false, false, false, false, false
local WalkSpeedToggle, JumpPowerToggle = false, false
local CustomSpeed, CustomJump, SpinSpeed = 16, 50, 30
local SilentAimSheriff, SilentAimMurderer = false, false
local SelectedFlingTarget = ""
local SelectedSkin = "Corrupt"

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
    if plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife") then return "Murderer" end
    if plr.Backpack:FindFirstChild("Gun") or plr.Character:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
end

-- =======================================================
-- ARAYÜZ OLUŞTURMA (PURE GUI - %100 UYUMLU)
-- =======================================================
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "LyrexHubUI"
MainGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = MainGui
MainFrame.Size = UDim2.new(0, 420, 0, 260)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- BAŞLIK
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.Text = "  Lyrex Hub 🔮 | MM2 Ultimate"
Title.TextColor3 = Color3.fromRGB(170, 85, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- TAB BUTONLARI KONTEYNERİ
local TabContainer = Instance.new("Frame")
TabContainer.Parent = MainFrame
TabContainer.Position = UDim2.new(0, 5, 0, 40)
TabContainer.Size = UDim2.new(0, 100, 1, -45)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 32)

local TabList = Instance.new("UIListLayout")
TabList.Parent = TabContainer
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0, 3)

-- İÇERİK ALANI
local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.Position = UDim2.new(0, 110, 0, 40)
ContentContainer.Size = UDim2.new(1, -115, 1, -45)
ContentContainer.BackgroundTransparency = 1

local Tabs = {}

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = TabContainer
    TabBtn.Size = UDim2.new(1, 0, 0, 28)
    TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabBtn.TextSize = 12
    TabBtn.Font = Enum.Font.SourceSans

    local Page = Instance.new("ScrollingFrame")
    Page.Parent = ContentContainer
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 4

    local PageList = Instance.new("UIListLayout")
    PageList.Parent = Page
    PageList.Padding = UDim.new(0, 5)

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
    end)

    local tabObj = {Btn = TabBtn, Page = Page}
    table.insert(Tabs, tabObj)
    return Page
end

-- MOBİL YÜZEN 🔮 BUTONU
local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "LyrexMobileControl"
MobileGui.Parent = CoreGui

local OpenBtn = Instance.new("TextButton")
OpenBtn.Parent = MobileGui
OpenBtn.Size = UDim2.new(0, 45, 0, 45)
OpenBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
OpenBtn.Text = "🔮"
OpenBtn.TextSize = 22
OpenBtn.Active = true
OpenBtn.Draggable = true

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(1, 0)
BtnCorner.Parent = OpenBtn

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- UI ELEMANI EKLEME YARDIMCILARI
local function AddToggle(page, text, default, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = page
    btn.Size = UDim2.new(1, -10, 0, 30)
    local state = default
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(50, 50, 60)
    btn.Text = text .. ": " .. (state and "AÇIK" or "KAPALI")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(50, 50, 60)
        btn.Text = text .. ": " .. (state and "AÇIK" or "KAPALI")
        callback(state)
    end)
end

local function AddButton(page, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = page
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold

    btn.MouseButton1Click:Connect(callback)
end

-- TABLARI OLUŞTUR
local PageESP = CreateTab("Visuals & ESP")
local PageCombat = CreateTab("Combat & Aim")
local PageSkins = CreateTab("Skin Changer")
local PageFling = CreateTab("Fling Player")
PageESP.Visible = true
Tabs[1].Btn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)

-- 1. VISUALS & ESP
AddToggle(PageESP, "Player Role ESP", false, function(v) ESP_Players = v end)
AddToggle(PageESP, "Gun Drop ESP", false, function(v) ESP_GunDrop = v end)

RunService.RenderStepped:Connect(function()
    if ESP_Players then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hl = plr.Character:FindFirstChild("LyrexESP") or Instance.new("Highlight", plr.Character)
                hl.Name = "LyrexESP"
                local role = GetRole(plr)
                hl.FillColor = role == "Murderer" and Color3.fromRGB(255,0,0) or (role == "Sheriff" and Color3.fromRGB(0,120,255) or Color3.fromRGB(0,255,0))
            end
        end
    end
end)

-- 2. COMBAT & AIM
AddButton(PageCombat, "🎯 Katile Ateş Et (Sheriff)", function()
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

-- 3. SKIN CHANGER
AddButton(PageSkins, "✨ Corrupt Skini Uygula", function()
    local char = LocalPlayer.Character
    local knife = char and (char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
    if knife and knife:FindFirstChild("Handle") then
        local mesh = knife.Handle:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            mesh.MeshId = KnifeSkinsData["Corrupt"].Mesh
            mesh.TextureId = KnifeSkinsData["Corrupt"].Texture
        end
    end
end)

AddButton(PageSkins, "✨ Harvester Skini Uygula", function()
    local char = LocalPlayer.Character
    local knife = char and (char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
    if knife and knife:FindFirstChild("Handle") then
        local mesh = knife.Handle:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            mesh.MeshId = KnifeSkinsData["Harvester"].Mesh
            mesh.TextureId = KnifeSkinsData["Harvester"].Texture
        end
    end
end)

-- MOVEMENT / NOCLIP LOOP
AddToggle(PageESP, "Noclip (Duvar Geçme)", false, function(v) Noclip = v end)

RunService.Stepped:Connect(function()
    if Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)
