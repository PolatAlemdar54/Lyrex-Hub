--[[
	Admin Kontrol Paneli (Lyrex Hub MM2 Edition)
	Saf Luau - Dış kütüphane ve takılma yapmaz.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------
-- TEMA
----------------------------------------------------------------------
local THEME = {
	Background = Color3.fromRGB(22, 22, 27),
	Panel = Color3.fromRGB(32, 32, 39),
	Item = Color3.fromRGB(45, 45, 54),
	Accent = Color3.fromRGB(130, 40, 240),
	Text = Color3.fromRGB(236, 236, 241),
	SubText = Color3.fromRGB(150, 150, 163),
	Good = Color3.fromRGB(67, 181, 129),
	Bad = Color3.fromRGB(237, 66, 69),
}

----------------------------------------------------------------------
-- UI YARDIMCILARI
----------------------------------------------------------------------
local function new(className: string, props: {[string]: any}, parent: Instance?)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function addCorner(inst: Instance, radius: number?)
	new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, inst)
end

local orders = setmetatable({}, { __mode = "k" })
local function nextOrder(page: Instance): number
	orders[page] = (orders[page] or 0) + 1
	return orders[page]
end

local function clearContainer(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Sürükleme Mekanizması
local function makeDraggable(handle: GuiObject, target: GuiObject, onTap: (() -> ())?)
	local dragging = false
	local moved = false
	local dragStart: Vector3
	local startPos: UDim2

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved and onTap then
						onTap()
					end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			if delta.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end
	end)
end

----------------------------------------------------------------------
-- ANA ARAYÜZ (CORE GUI)
----------------------------------------------------------------------
local old = CoreGui:FindFirstChild("LyrexAdminHub")
if old then old:Destroy() end

local gui = new("ScreenGui", {
	Name = "LyrexAdminHub",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
}, CoreGui)

local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
local panelWidth = math.clamp(viewport.X - 24, 280, 380)
local panelHeight = math.clamp(viewport.Y - 90, 280, 420)

-- Aç/Kapat Butonu
local toggleButton = new("TextButton", {
	Name = "ToggleButton",
	Size = UDim2.fromOffset(46, 46),
	Position = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = THEME.Accent,
	Text = "🔮",
	TextSize = 20,
	AutoButtonColor = true,
	ZIndex = 10,
}, gui)
addCorner(toggleButton, 23)

-- Ana Panel
local main = new("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(panelWidth, panelHeight),
	Position = UDim2.new(0.5, -panelWidth/2, 0.5, -panelHeight/2),
	BackgroundColor3 = THEME.Background,
	BorderSizePixel = 0,
	Visible = false,
	ClipsDescendants = true,
}, gui)
addCorner(main, 12)
new("UIStroke", { Color = THEME.Item, Thickness = 1 }, main)

local titleBar = new("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
}, main)

new("TextLabel", {
	Size = UDim2.new(1, -44, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text = "Lyrex Hub 🔮",
	TextColor3 = THEME.Text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local closeButton = new("TextButton", {
	Size = UDim2.new(0, 34, 1, 0),
	Position = UDim2.new(1, -34, 0, 0),
	BackgroundTransparency = 1,
	Text = "X",
	TextColor3 = THEME.SubText,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
}, titleBar)

local tabBar = new("Frame", {
	Name = "TabBar",
	Position = UDim2.new(0, 8, 0, 40),
	Size = UDim2.new(1, -16, 0, 30),
	BackgroundTransparency = 1,
}, main)
new("UIGridLayout", {
	CellSize = UDim2.new(0.25, -3, 1, 0),
	CellPadding = UDim2.new(0, 4, 0, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local pagesHolder = new("Frame", {
	Name = "Pages",
	Position = UDim2.new(0, 8, 0, 76),
	Size = UDim2.new(1, -16, 1, -106),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, main)

local statusLabel = new("TextLabel", {
	Name = "Status",
	Position = UDim2.new(0, 8, 1, -26),
	Size = UDim2.new(1, -16, 0, 22),
	BackgroundColor3 = THEME.Panel,
	Text = "Lyrex Hub Aktif.",
	TextColor3 = THEME.SubText,
	Font = Enum.Font.Gotham,
	TextSize = 12,
}, main)
addCorner(statusLabel, 6)

local notifyToken = 0
local function notify(message: string, kind: string?)
	notifyToken += 1
	local token = notifyToken
	statusLabel.Text = message
	statusLabel.TextColor3 = kind == "bad" and THEME.Bad or kind == "good" and THEME.Good or THEME.Text
	task.delay(3, function()
		if token == notifyToken then
			statusLabel.Text = "Hazır."
			statusLabel.TextColor3 = THEME.SubText
		end
	end)
end

----------------------------------------------------------------------
-- SEKME SİSTEMİ
----------------------------------------------------------------------
local tabNames = { "Visuals", "Movement", "Teleport", "Actions" }
local tabButtons = {}
local pages = {}
local selectTab
local onTabSelected = {}

for index, name in ipairs(tabNames) do
	local button = new("TextButton", {
		Name = name .. "Tab",
		LayoutOrder = index,
		BackgroundColor3 = THEME.Panel,
		Text = name,
		TextColor3 = THEME.SubText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
	}, tabBar)
	addCorner(button, 6)
	tabButtons[name] = button

	local page = new("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, pagesHolder)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	pages[name] = page

	button.Activated:Connect(function() selectTab(name) end)
end

selectTab = function(name: string)
	for tabName, page in pairs(pages) do
		local active = tabName == name
		page.Visible = active
		tabButtons[tabName].BackgroundColor3 = active and THEME.Accent or THEME.Panel
		tabButtons[tabName].TextColor3 = active and Color3.new(1, 1, 1) or THEME.SubText
	end
	if onTabSelected[name] then onTabSelected[name]() end
end

----------------------------------------------------------------------
-- WIDGET ÜRETİCİLERİ
----------------------------------------------------------------------
local function makeButton(parent: Instance, text: string, color: Color3?)
	local button = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = color or THEME.Item,
		Text = text,
		TextColor3 = THEME.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
	}, parent)
	addCorner(button, 8)
	return button
end

local function addToggle(page: Instance, text: string, default: boolean, callback: (boolean) -> ())
	local state = default
	local button = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = nextOrder(page),
		BackgroundColor3 = THEME.Item,
		Text = "",
	}, page)
	addCorner(button, 8)

	new("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = THEME.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, button)

	local pill = new("TextLabel", {
		Size = UDim2.new(0, 60, 0, 22),
		Position = UDim2.new(1, -68, 0.5, -11),
		BackgroundColor3 = THEME.Bad,
		Text = "KAPALI",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
	}, button)
	addCorner(pill, 11)

	local function render()
		pill.Text = state and "AÇIK" or "KAPALI"
		pill.BackgroundColor3 = state and THEME.Good or THEME.Bad
	end
	render()

	button.Activated:Connect(function()
		state = not state
		render()
		callback(state)
	end)
end

----------------------------------------------------------------------
-- MM2 ROL SİSTEMİ VE ESP
----------------------------------------------------------------------
local function GetMM2Role(plr)
	if not plr or not plr.Character then return "Innocent" end
	if plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife") then return "Murderer" end
	if plr.Backpack:FindFirstChild("Gun") or plr.Character:FindFirstChild("Gun") then return "Sheriff" end
	return "Innocent"
end

local espEnabled = false
RunService.RenderStepped:Connect(function()
	if espEnabled then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local hl = plr.Character:FindFirstChild("LyrexESP") or Instance.new("Highlight", plr.Character)
				hl.Name = "LyrexESP"
				local role = GetMM2Role(plr)
				hl.FillColor = role == "Murderer" and Color3.fromRGB(255,40,40) or (role == "Sheriff" and Color3.fromRGB(40,120,255) or Color3.fromRGB(40,255,40))
			end
		end
	end
end)

addToggle(pages.Visuals, "MM2 Rol ESP (Katil/Şerif)", false, function(v)
	espEnabled = v
	if not v then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChild("LyrexESP") then
				plr.Character.LyrexESP:Destroy()
			end
		end
	end
end)

----------------------------------------------------------------------
-- MOVEMENT (Noclip & Speed)
----------------------------------------------------------------------
local noclip = false
addToggle(pages.Movement, "Noclip (Duvar Geçme)", false, function(v) noclip = v end)
addToggle(pages.Movement, "Hızlı Koşma (Speed 50)", false, function(v)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = v and 50 or 16
	end
end)

RunService.Stepped:Connect(function()
	if noclip and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end
end)

----------------------------------------------------------------------
-- TELEPORT
----------------------------------------------------------------------
makeButton(pages.Teleport, "🔫 Düşen Silaha Işınlan", Color3.fromRGB(80, 50, 150)).Activated:Connect(function()
	local gunDrop = Workspace:FindFirstChild("GunDrop", true)
	if gunDrop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
		notify("Silaha ışınlanıldı!", "good")
	else
		notify("Düşen silah bulunamadı.", "bad")
	end
end)

makeButton(pages.Teleport, "🔪 Katile Işınlan", Color3.fromRGB(150, 40, 40)).Activated:Connect(function()
	for _, plr in pairs(Players:GetPlayers()) do
		if GetMM2Role(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
			notify("Katile ışınlanıldı!", "good")
			break
		end
	end
end)

----------------------------------------------------------------------
-- DÜĞMELER VE SÜRÜKLEME
----------------------------------------------------------------------
makeDraggable(toggleButton, toggleButton, function()
	main.Visible = not main.Visible
end)
makeDraggable(titleBar, main, nil)
closeButton.Activated:Connect(function() main.Visible = false end)

selectTab("Visuals")
