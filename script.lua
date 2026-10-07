-- Delta / Mobil Uyumlu Güvenli Görsel Script (Fizik/Hız Müdahalesi Yoktur)
if getgenv().SafeSoccerLoaded then return end
getgenv().SafeSoccerLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SETTINGS = {
	BallESP = true,
	TrajectoryPreview = true
}

-- 1. HAFİF ARAYÜZ (GUI)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SafeSoccerGui"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = PlayerGui end)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 140)
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
title.Text = "GÜVENLİ GÖRSEL MOD"
title.TextColor3 = Color3.fromRGB(0, 255, 127)
title.TextSize = 11
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = mainFrame
listLayout.Padding = UDim.new(0, 5)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 38)
padding.Parent = mainFrame

local function createToggle(name, key)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 35)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 11
	btn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	local function update()
		if SETTINGS[key] then
			btn.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
			btn.Text = name .. ": AÇIK"
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
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

createToggle("Top ESP", "BallESP")
createToggle("Şut Yörüngesi", "TrajectoryPreview")

-- 2. ÖNBELLEKLİ TOP TESPİTİ
local cachedBall = nil
local lastCheck = 0

local function getBall()
	if cachedBall and cachedBall.Parent and cachedBall:IsA("BasePart") then
		return cachedBall
	end
	if tick() - lastCheck < 1 then return nil end
	lastCheck = tick()

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

-- 3. GÖRSEL EŞYALAR
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
		return goal.CFrame.Position + Vector3.new(0, goal.Size.Y * 0.3, 0)
	end
	return Vector3.new(0, 8, -100)
end

-- ESP Güncelleme Döngüsü
task.spawn(function()
	while task.wait(0.2) do
		local ball = getBall()
		if ball then
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
	end
end)

-- Yörünge Çizim Döngüsü
RunService.RenderStepped:Connect(function()
	if not SETTINGS.TrajectoryPreview then
		beam.Enabled = false
		return
	end

	local ball = cachedBall
	local char = LocalPlayer.Character
	
	if ball and char and char:FindFirstChild("HumanoidRootPart") then
		local dist = (char.HumanoidRootPart.Position - ball.Position).Magnitude
		if dist < 8 then
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
