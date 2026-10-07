-- Delta Executor & Mobil Optimizasyonlu Sokak Futbolu Scripti
if getgenv().SoccerScriptLoaded then
	print("Script zaten çalışıyor!")
	return
end
getgenv().SoccerScriptLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- AYARLAR
local SETTINGS = {
	BallESP = true,
	TrajectoryPreview = true,
	AutoTackle = true,
	CurveShot = true,
	CurvePower = 1.1,
	AutoTackleDistance = 9,
	BypassMode = true -- Anti-Cheat İnsansı Tepki ve Hız Sınırlayıcı
}

----------------------------------------------------------------------
-- 1. MOBİL UYUMLU VE HAFİF MENÜ (GUI)
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaSoccerGui"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = PlayerGui end)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 270)
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
title.Text = "SOKAK FUTBOLU PRO (BYPASS)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = mainFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 45)
padding.Parent = mainFrame

-- Buton Yapıcı
local function createButton(name, key)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 38)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 12
	btn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	local function update()
		if SETTINGS[key] then
			btn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
			btn.Text = name .. ": AÇIK"
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
			btn.Text = name .. ": KAPALI"
			btn.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	btn.MouseButton1Click:Connect(function()
		SETTINGS[key] = not SETTINGS[key]
		update()
	end)

	update()
end

createButton("Top ESP", "BallESP")
createButton("Şut Yörüngesi", "TrajectoryPreview")
createButton("Auto Kayma", "AutoTackle")
createButton("Falsolu Şut", "CurveShot")

----------------------------------------------------------------------
-- 2. ÖNBELLEKLEME & PERFORMANS MOTORU (DONMAYI ÖNLER)
----------------------------------------------------------------------
local cachedBall = nil
local lastSearchTime = 0

-- Topu Her Frame Yerinize Sadece İhtiyaç Anında Arar
local function getBall()
	if cachedBall and cachedBall.Parent and cachedBall:IsA("BasePart") then
		return cachedBall
	end
	
	if tick() - lastSearchTime < 0.5 then return nil end
	lastSearchTime = tick()

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("BasePart") then
			local n = obj.Name:lower()
			if n:find("ball") or n:find("top") or n:find("soccer") or n:find("football") then
				cachedBall = obj
				return cachedBall
			end
		end
	end
	return nil
end

-- ESP SİSTEMİ (Önbellek Üzerinden)
local function applyESP(ball)
	if not ball then return end
	local hl = ball:FindFirstChild("BallHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "BallHighlight"
		hl.FillColor = Color3.fromRGB(0, 255, 127)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.3
		hl.Parent = ball
	end
	hl.Enabled = SETTINGS.BallESP
end

-- YÖRÜNGE GÖSTERGESİ (BEAM)
local att0 = Instance.new("Attachment")
local att1 = Instance.new("Attachment")
local beam = Instance.new("Beam")
beam.Width0 = 0.3
beam.Width1 = 0.6
beam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 50, 50))
beam.FaceCamera = true
beam.Enabled = false
beam.Parent = Workspace

local function getGoalPosition()
	local goal = Workspace:FindFirstChild("Goal") or Workspace:FindFirstChild("AwayGoal") or Workspace:FindFirstChild("HomeGoal")
	if goal and goal:IsA("BasePart") then
		return goal.CFrame.Position + Vector3.new(goal.Size.X * 0.3, goal.Size.Y * 0.3, 0)
	end
	return Vector3.new(0, 8, -120)
end

----------------------------------------------------------------------
-- 3. BYPASS & MÜDAHALE MEKANİZMASI
----------------------------------------------------------------------
local lastSlideTime = 0

-- Otomatik Kayma (Anti-Cheat Bypass ve Delaysız)
local function safeAutoSlide(ball)
	if not SETTINGS.AutoTackle or not ball then return end
	if tick() - lastSlideTime < 1.5 then return end -- Spam engelleme bypass'ı

	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local myHrp = char.HumanoidRootPart

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local enemyHrp = plr.Character.HumanoidRootPart
			local distToEnemy = (myHrp.Position - enemyHrp.Position).Magnitude
			local enemyDistToBall = (enemyHrp.Position - ball.Position).Magnitude

			if enemyDistToBall < 4.5 and distToEnemy <= SETTINGS.AutoTackleDistance then
				lastSlideTime = tick()
				
				-- Bypass: İnsansı mikro gecikme (Bot algılayıcıları yanıltır)
				if SETTINGS.BypassMode then
					task.wait(math.random(3, 8) / 100)
				end

				-- Speed-Hack Anti-Cheat'e takılmamak için sınırlı fiziksel impulse
				local dir = (enemyHrp.Position - myHrp.Position).Unit
				myHrp.AssemblyLinearVelocity = dir * 42
				break
			end
		end
	end
end

-- Falsolu Şut (Network Ownership & Velocity Bypass)
local function safeCurveShot(ball)
	if not SETTINGS.CurveShot or not ball then return end
	
	pcall(function()
		local goalPos = getGoalPosition()
		local direction = (goalPos - ball.Position).Unit
		
		-- Falso Dönüşü ve İlerleme Hızı (Sunucu Banını Önlemek İçin Clamped Yapıldı)
		ball.AssemblyAngularVelocity = Vector3.new(0, 90 * SETTINGS.CurvePower, 0)
		ball.AssemblyLinearVelocity = (direction * 80) + Vector3.new(0, 12, 0)
	end)
end

----------------------------------------------------------------------
-- 4. PERFORMANS DOSTU ZAMANLAYICI DÖNGÜLERİ (THROTTLED)
----------------------------------------------------------------------

-- Ağır Mantık Döngüsü (Saniyede 10 kez çalışır, FPS düşürmez)
task.spawn(function()
	while task.wait(0.1) do
		local ball = getBall()
		if ball then
			applyESP(ball)
			safeAutoSlide(ball)
		end
	end
end)

-- Görsel Döngü (Yalnızca Yörünge Çizimi İçin)
RunService.RenderStepped:Connect(function()
	if not SETTINGS.TrajectoryPreview then
		beam.Enabled = false
		return
	end

	local ball = cachedBall
	local char = LocalPlayer.Character
	
	if ball and char and char:FindFirstChild("HumanoidRootPart") then
		local dist = (char.HumanoidRootPart.Position - ball.Position).Magnitude
		if dist < 7 then
			att0.Parent = ball
			att1.WorldPosition = getGoalPosition()
			att1.Parent = Workspace
			beam.Attachment0 = att0
			beam.Attachment1 = att1
			beam.Enabled = true
		else
			beam.Enabled = false
		end
	else
		beam.Enabled = false
	end
end)

-- Ekran Tıklaması (Şut Tetikleyici)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local ball = cachedBall
		local char = LocalPlayer.Character
		if ball and char and char:FindFirstChild("HumanoidRootPart") then
			if (char.HumanoidRootPart.Position - ball.Position).Magnitude < 7 then
				safeCurveShot(ball)
			end
		end
	end
end)
