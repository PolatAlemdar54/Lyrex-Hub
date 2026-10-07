-- =======================================================
--            LYREX HUB v4 ULTIMATE | MM2 SCRIPT
-- =======================================================

-- 3D ARKA PLAN BİLİŞİMİ & BLUR EFEKTİ
local Lighting = game:GetService("Lighting")
local Blur = Lighting:FindFirstChild("LyrexBlur") or Instance.new("BlurEffect")
Blur.Name = "LyrexBlur"
Blur.Size = 10
Blur.Parent = Lighting

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusRef/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
   Name = "Lyrex Hub 🔮 | MM2 Ultimate Edition",
   LoadingTitle = "Lyrex Hub v4 Yükleniyor...",
   LoadingSubtitle = "by PolatAlemdar54",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

-- MOBİL DOKUNMATİK BUTONU (Delta Touch Fix)
local CoreGui = game:GetService("CoreGui")
local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "LyrexMobileControl"
MobileGui.Parent = CoreGui

local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "ToggleBtn"
OpenBtn.Parent = MobileGui
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.TextSize = 25
OpenBtn.Text = "🔮"
OpenBtn.Active = true
OpenBtn.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = OpenBtn

OpenBtn.MouseButton1Click:Connect(function()
    local RayfieldUI = CoreGui:FindFirstChild("Rayfield")
    if RayfieldUI then
        RayfieldUI.Enabled = not RayfieldUI.Enabled
        Blur.Enabled = RayfieldUI.Enabled
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

-- SETTINGS
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

-- SKIN CHANGER DATA
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

-- HELPER FUNCTIONS
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

-- TABS
local TabMain = Window:CreateTab("Visuals & ESP", 4483345998)
local TabCombat = Window:CreateTab("Combat & Aim", 4483345998)
local TabSkins = Window:CreateTab("Skin Changer", 4483345998)
local TabFling = Window:CreateTab("Fling Player", 4483345998)
local TabFarm = Window:CreateTab("Auto Farm", 4483345998)
local TabMovement = Window:CreateTab("Movement", 4483345998)
local TabTeleport = Window:CreateTab("Teleports", 4483345998)

-- =======================================================
-- 1. VISUALS & ESP
-- =======================================================
TabMain:CreateSection("Player ESP")

TabMain:CreateToggle({
   Name = "Player Role ESP",
   CurrentValue = false,
   Flag = "PlayerESPFlag",
   Callback = function(Value)
      ESP_Players = Value
      if not Value then
         for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("LyrexESP") then
               plr.Character.LyrexESP:Destroy()
            end
         end
      end
   end,
})

TabMain:CreateToggle({
   Name = "Gun Drop ESP",
   CurrentValue = false,
   Flag = "GunESPFlag",
   Callback = function(Value)
      ESP_GunDrop = Value
      if not Value then
         local existing = Workspace:FindFirstChild("GunDropHighlight", true)
         if existing then existing:Destroy() end
      end
   end,
})

RunService.RenderStepped:Connect(function()
   if ESP_Players then
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
         local hl = gunDrop:FindFirstChild("GunDropHighlight")
         if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "GunDropHighlight"
            hl.FillColor = Color3.fromRGB(255, 215, 0)
            hl.Parent = gunDrop
         end
      end
   end
end)

-- =======================================================
-- 2. COMBAT & AIM
-- =======================================================
TabCombat:CreateSection("Sheriff Silent Aim")

TabCombat:CreateToggle({
   Name = "Sheriff Silent Aim Modu",
   CurrentValue = false,
   Flag = "SheriffSilentFlag",
   Callback = function(Value)
      SilentAimSheriff = Value
   end,
})

TabCombat:CreateButton({
   Name = "🎯 Katile Otomatik Ateş Et",
   Callback = function()
      if not SilentAimSheriff then
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Önce Sheriff Silent Aim modunu açın!", Duration = 2})
         return
      end
      
      local char = LocalPlayer.Character
      local gun = char and (char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun"))
      if not gun then
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Üzerinizde silah yok!", Duration = 2})
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
            Rayfield:Notify({Title = "Lyrex Hub", Content = "Katile ateş edildi!", Duration = 2})
         else
            Rayfield:Notify({Title = "Lyrex Hub", Content = "Katil duvar arkasında!", Duration = 2})
         end
      else
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Oyunda aktif katil bulunamadı!", Duration = 2})
      end
   end,
})

TabCombat:CreateSection("Murderer Silent Aim")

TabCombat:CreateToggle({
   Name = "Knife Silent Aim Modu",
   CurrentValue = false,
   Flag = "KnifeSilentFlag",
   Callback = function(Value)
      SilentAimMurderer = Value
   end,
})

TabCombat:CreateButton({
   Name = "🔪 En Yakındaki Oyuncuya Bıçak At",
   Callback = function()
      if not SilentAimMurderer then
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Önce Knife Silent Aim modunu açın!", Duration = 2})
         return
      end
      
      local char = LocalPlayer.Character
      local knife = char and (char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
      if not knife then
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Üzerinizde bıçak yok!", Duration = 2})
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
         Rayfield:Notify({Title = "Lyrex Hub", Content = closestPlr.Name .. " hedefine bıçak atıldı!", Duration = 2})
      else
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Görüş alanında hedef bulunamadı!", Duration = 2})
      end
   end,
})

-- =======================================================
-- 3. SKIN CHANGER (GÖRSEL KAPLAMA DEĞİŞTİRİCİ)
-- =======================================================
TabSkins:CreateSection("Bıçak Skin Değiştirici")

local SelectedSkin = "Corrupt"
TabSkins:CreateDropdown({
   Name = "Bıçak Skin Seç",
   Options = {"Nik's Scythe", "Corrupt", "Harvester", "Candy", "Icebreaker"},
   CurrentOption = {"Corrupt"},
   MultipleOptions = false,
   Flag = "SkinDropdownFlag",
   Callback = function(Option)
      SelectedSkin = type(Option) == "table" and Option[1] or Option
   end,
})

TabSkins:CreateButton({
   Name = "✨ Seçili Skini Elindeki Bıçağa Uygula",
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
               Rayfield:Notify({Title = "Lyrex Hub", Content = SelectedSkin .. " skini başarıyla uygulandı!", Duration = 3})
            end
         end
      else
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Elinde veya envanterinde bıçak bulunamadı!", Duration = 2})
      end
   end,
})

-- =======================================================
-- 4. FLING PLAYER
-- =======================================================
TabFling:CreateSection("Oyuncu Fling (Uçurma)")

local playerNames = {}
local function RefreshPlayerList()
   playerNames = {}
   for _, p in pairs(Players:GetPlayers()) do
      if p ~= LocalPlayer then
         table.insert(playerNames, p.Name)
      end
   end
end
RefreshPlayerList()

local FlingDropdown = TabFling:CreateDropdown({
   Name = "Fling Yapılacak Oyuncuyu Seç",
   Options = #playerNames > 0 and playerNames or {"Oyuncu Yok"},
   CurrentOption = {"Seçiniz"},
   MultipleOptions = false,
   Flag = "FlingDropdownFlag",
   Callback = function(Option)
      SelectedFlingTarget = type(Option) == "table" and Option[1] or Option
   end,
})

TabFling:CreateButton({
   Name = "🔄 Oyuncu Listesini Yenile",
   Callback = function()
      RefreshPlayerList()
      FlingDropdown:Refresh(#playerNames > 0 and playerNames or {"Oyuncu Yok"})
      Rayfield:Notify({Title = "Lyrex Hub", Content = "Oyuncu listesi yenilendi!", Duration = 2})
   end,
})

TabFling:CreateButton({
   Name = "🚀 Oyuncuyu Fling Et",
   Callback = function()
      if SelectedFlingTarget == "" or SelectedFlingTarget == "Seçiniz" or SelectedFlingTarget == "Oyuncu Yok" then
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Lütfen bir oyuncu seçin!", Duration = 2})
         return
      end
      
      local targetPlayer = Players:FindFirstChild(SelectedFlingTarget)
      if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Hedef oyuncu bulunamadı!", Duration = 2})
         return
      end
      
      local myChar = LocalPlayer.Character
      if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
      
      Rayfield:Notify({Title = "Lyrex Hub", Content = SelectedFlingTarget .. " Fling ediliyor...", Duration = 3})
      
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
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Fling tamamlandı!", Duration = 2})
      end)
   end,
})

-- =======================================================
-- 5. AUTO FARM
-- =======================================================
TabFarm:CreateSection("Sikke Toplayıcı")

TabFarm:CreateToggle({
   Name = "Auto Collect Coins",
   CurrentValue = false,
   Flag = "AutoCoinFlag",
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
   end,
})

-- =======================================================
-- 6. MOVEMENT
-- =======================================================
TabMovement:CreateSection("Hız & Zıplama")

TabMovement:CreateToggle({
   Name = "Özel Yürüme Hızı Aktif",
   CurrentValue = false,
   Flag = "SpeedToggleFlag",
   Callback = function(Value)
      WalkSpeedToggle = Value
   end,
})

TabMovement:CreateSlider({
   Name = "Yürüme Hızı (WalkSpeed)",
   Range = {16, 120},
   Increment = 1,
   Suffix = " Speed",
   CurrentValue = 16,
   Flag = "SpeedSliderFlag",
   Callback = function(Value)
      CustomSpeed = Value
   end,
})

TabMovement:CreateToggle({
   Name = "Özel Zıplama Gücü Aktif",
   CurrentValue = false,
   Flag = "JumpToggleFlag",
   Callback = function(Value)
      JumpPowerToggle = Value
   end,
})

TabMovement:CreateSlider({
   Name = "Zıplama Gücü (JumpPower)",
   Range = {50, 200},
   Increment = 1,
   Suffix = " Power",
   CurrentValue = 50,
   Flag = "JumpSliderFlag",
   Callback = function(Value)
      CustomJump = Value
   end,
})

TabMovement:CreateSection("Gelişmiş Hareketler")

TabMovement:CreateToggle({
   Name = "Bunny Hop (Otomatik Zıplama)",
   CurrentValue = false,
   Flag = "BhopFlag",
   Callback = function(Value)
      BunnyHop = Value
   end,
})

TabMovement:CreateToggle({
   Name = "Spin Bot (Kendi Etrafında Dönme)",
   CurrentValue = false,
   Flag = "SpinFlag",
   Callback = function(Value)
      SpinBot = Value
   end,
})

TabMovement:CreateSlider({
   Name = "Spin Hızı",
   Range = {10, 100},
   Increment = 5,
   Suffix = " RPM",
   CurrentValue = 30,
   Flag = "SpinSpeedFlag",
   Callback = function(Value)
      SpinSpeed = Value
   end,
})

TabMovement:CreateToggle({
   Name = "Noclip (Duvarlardan Geçme)",
   CurrentValue = false,
   Flag = "NoclipFlag",
   Callback = function(Value)
      Noclip = Value
   end,
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
TabTeleport:CreateSection("Işınlanma")

TabTeleport:CreateButton({
   Name = "🔫 Düşen Silaha Işınlan (Gun Drop TP)",
   Callback = function()
      local gunDrop = Workspace:FindFirstChild("GunDrop", true)
      if gunDrop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         LocalPlayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Silaha ışınlanıldı!", Duration = 2})
      else
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Yerde silah bulunamadı!", Duration = 2})
      end
   end,
})

TabTeleport:CreateButton({
   Name = "🏠 Lobiye Işınlan",
   Callback = function()
      local lobby = Workspace:FindFirstChild("Lobby")
      if lobby and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         LocalPlayer.Character.HumanoidRootPart.CFrame = lobby:GetModelCFrame()
         Rayfield:Notify({Title = "Lyrex Hub", Content = "Lobiye ışınlanıldı!", Duration = 2})
      end
   end,
})

TabTeleport:CreateButton({
   Name = "🔪 Katile Işınlan (Murderer TP)",
   Callback = function()
      for _, plr in pairs(Players:GetPlayers()) do
         if GetRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "Lyrex Hub", Content = "Katile ışınlanıldı!", Duration = 2})
            break
         end
      end
   end,
})

TabTeleport:CreateButton({
   Name = "👮 Şerife Işınlan (Sheriff TP)",
   Callback = function()
      for _, plr in pairs(Players:GetPlayers()) do
         if GetRole(plr) == "Sheriff" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "Lyrex Hub", Content = "Şerife ışınlanıldı!", Duration = 2})
            break
         end
      end
   end,
})

Rayfield:Notify({Title = "Lyrex Hub 🔮", Content = "Lyrex Hub v4 Ultimate yüklendi! Mobil buton açıldı.", Duration = 4})
