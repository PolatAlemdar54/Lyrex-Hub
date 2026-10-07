local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- OYUN AYARLARI (Menü üzerinden anlık kontrol edilir)
local SETTINGS = {
	BallESP = true,              -- Top ESP
	TrajectoryPreview = true,    -- Şut Yörünge Göstergesi
	AutoTackle = true,           -- Otomatik Kayma / Top Kapma
	CurveShot = true,            -- Kavisli/Falsolu Şut
	CurvePower = 1.2,
	AutoTackleDistance = 10
}

----------------------------------------------------------------------
-- 1. ARAYÜZ (GUI) OLUŞTURMA SİSTEMİ
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SoccerProMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Menü Ana Çerçeve
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = mainFrame

-- Başlık Barı
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
titleLabel.Text = "SOKAK FUTBOLU PRO v1.0"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleLabel

-- Buton Listesi Düzeni
local listLayout = Instance.new("UIListLayout")
listLayout.Parent = mainFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 50)
padding.Parent = mainFrame

-- Menü Açma/Kapama Butonu (Sol Üst Köşe)
local toggleMenuBtn = Instance.new("TextButton")
toggleMenuBtn.Name = "ToggleMenuBtn"
toggleMenuBtn.Size = UDim2.new(0, 100, 0, 35)
toggleMenuBtn.Position = UDim2.new(0, 15, 0, 15)
toggleMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
toggleMenuBtn.Text = "MENÜ (K)"
toggleMenuBtn.TextColor3 = Color3.fromRGB(0, 255, 127)
toggleMenuBtn.Font = Enum.Font.GothamBold
toggleMenuBtn.TextSize = 13
toggleMenuBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleMenuBtn

-- Dinamik Buton Oluşturma Fonksiyonu
local function createToggleButton(name, settingKey)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.9, 0, 0, 45)
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 13
	button.AutoButtonColor = true
	button.Parent = mainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local function updateStyle()
		if SETTINGS[settingKey] then
			button.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
			button.Text = name .. ": AÇIK"
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(178, 34, 34)
			button.Text = name .. ": KAPALI"
			button.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	button.MouseButton1Click:Connect(function()
		SETTINGS[settingKey] = not SETTINGS[settingKey]
		updateStyle()
	end)

	updateStyle()
end

-- Menü Butonlarını Ekle
createToggleButton("Top ESP", "BallESP")
createToggleButton("Şut Yörüngesi", "TrajectoryPreview")
createToggleButton("Otomatik Kayma", "AutoTackle")
createToggleButton("Falsolu Şut", "CurveShot")

-- Menü Gizle / Göster Mantığı
local function toggleMenu()
	mainFrame.Visible = not mainFrame.Visible
end

toggleMenuBtn.MouseButton1Click:Connect(toggleMenu)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
		toggleMenu()
	end
end)

----------------------------------------------------------------------
-- 2. OYUN MOTORU VE FİZİK SİSTEMİ
----------------------------------------------------------------------

-- Top Bulucu
local function getBall()
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name:lower():find("ball") or child.Name:lower():find("top") or child.Name:lower():find("football") then
			if child:IsA("BasePart") then
				return child
			end
		end
	end
	return nil
end

-- ESP Nesnesi
local function applyBallESP(ball)
	if not ball then return end
	local highlight = ball:FindFirstChild("BallHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "BallHighlight"
		highlight.FillColor = Color3.fromRGB(0, 255, 127)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.2
		highlight.Parent = ball
	end
	highlight.Enabled = SETTINGS.BallESP
end

-- Şut Yörüngesi (Beam)
local att0 = Instance.new("Attachment")
local att1 = Instance.new("Attachment")
local trajectoryBeam = Instance.new("Beam")

trajectoryBeam.Name = "ShotTrajectory"
trajectoryBeam.Width0 = 0.4
trajectoryBeam.Width1 = 0.8
trajectoryBeam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 50, 50))
trajectoryBeam.FaceCamera = true
trajectoryBeam.Enabled = false
trajectoryBeam.Parent = Workspace

local function getBestGoalCorner()
	local goal = Workspace:FindFirstChild("Goal") 
		or Workspace:FindFirstChild("AwayGoal") 
		or Workspace:FindFirstChild("HomeGoal")
		
	if goal and goal:IsA("BasePart") then
		return goal.CFrame.Position + Vector3.new(goal.Size.X * 0.35, goal.Size.Y * 0.35, 0)
	end
	return Vector3.new(0, 10, -100) -- Varsayılan kale hedefi
end

local function updateTrajectory(ball)
	if not SETTINGS.TrajectoryPreview or not ball then
		trajectoryBeam.Enabled = false
		return
	end

	local targetPos = getBestGoalCorner()
	att0.Parent = ball
	att1.WorldPosition = targetPos
	att1.Parent = Workspace

	trajectoryBeam.Attachment0 = att0
	trajectoryBeam.Attachment1 = att1
	trajectoryBeam.Enabled = true
end

-- Otomatik Kayma (Auto-Tackle)
local function checkAutoSlide(ball)
	if not SETTINGS.AutoTackle or not ball then return end
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

	local myHrp = myChar.HumanoidRootPart

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local enemyHrp = player.Character.HumanoidRootPart
			local distToEnemy = (myHrp.Position - enemyHrp.Position).Magnitude
			local enemyDistToBall = (enemyHrp.Position - ball.Position).Magnitude

			-- Rakip topa yakınsa ve biz de müdahale mesafesindeysek
			if enemyDistToBall < 5 and distToEnemy <= SETTINGS.AutoTackleDistance then
				myHrp.AssemblyLinearVelocity = (enemyHrp.Position - myHrp.Position).Unit * 55
				break
			end
		end
	end
end

-- Falsolu Şut
local function executeCurveShot(ball)
	if not SETTINGS.CurveShot or not ball then return end
	local targetCorner = getBestGoalCorner()
	local direction = (targetCorner - ball.Position).Unit
	
	ball.AssemblyAngularVelocity = Vector3.new(0, 120 * SETTINGS.CurvePower, 0)
	ball.AssemblyLinearVelocity = (direction * 95) + Vector3.new(0, 18, 0)
end

----------------------------------------------------------------------
-- 3. DÖNGÜ VE TETİKLEYİCİLER
----------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	local ball = getBall()

	if ball then
		applyBallESP(ball)

		local char = LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local distToBall = (char.HumanoidRootPart.Position - ball.Position).Magnitude

			-- Top ayağımıza yakınsa yörünge çizgisini göster
			if distToBall < 6 then
				updateTrajectory(ball)
			else
				trajectoryBeam.Enabled = false
			end
		end

		checkAutoSlide(ball)
	else
		trajectoryBeam.Enabled = false
	end
end)

-- Sol Tık veya Konsol Tetiklemesi
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local ball = getBall()
		local char = LocalPlayer.Character
		if ball and char and char:FindFirstChild("HumanoidRootPart") then
			if (char.HumanoidRootPart.Position - ball.Position).Magnitude < 7 then
				executeCurveShot(ball)
			end
		end
	end
end)
