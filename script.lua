--!strict
--[[
    ═══════════════════════════════════════════════════════════════
    ⚽  FUTBOL ARENA VISION  |  v1.2 (Mobile Edition)
    ═══════════════════════════════════════════════════════════════
    Yerleştirme : StarterPlayer > StarterPlayerScripts
    Tür         : LocalScript
    Özellikler  : Top ESP • Yörünge Önizleme • Dokunmatik Menü
    Uyumluluk   : Mobil (Android/iOS) & PC
    ═══════════════════════════════════════════════════════════════
--]]

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Workspace          = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════
--  AYARLAR
-- ═══════════════════════════════════════════════════════════════
local VISION_CONFIG = {
    ESP_ENABLED          = true,
    TRAJECTORY_ENABLED   = true,
    UPDATE_RATE          = 0.1,
    TRAJECTORY_STEPS     = 22,
    TRAJECTORY_TIME_STEP = 0.14,
    BALL_NAME            = "Ball",
    GRAVITY              = Vector3.new(0, -196.2, 0),

    -- Mobil UI Ayarları
    UI_SCALE             = 0.85,          -- 0.7 - 1.0 arası önerilir
    BUTTON_HEIGHT        = 52,            -- Dokunmatik için min 48px
    DRAG_THRESHOLD       = 8,             -- Piksel - titremeyi önler
    OPEN_BUTTON_SIZE     = 56,            -- Sağ alttaki küçük buton
}

-- ═══════════════════════════════════════════════════════════════
--  DURUM DEĞİŞKENLERİ
-- ═══════════════════════════════════════════════════════════════
local VisionState = {
    ball              = nil,
    ballHighlight     = nil,
    ballBillboard     = nil,
    trajectoryDots    = {},
    isDragging        = false,
    dragStartOffset   = Vector2.new(0, 0),
    isMobile          = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
}

-- ═══════════════════════════════════════════════════════════════
--  YARDIMCI FONKSİYONLAR
-- ═══════════════════════════════════════════════════════════════

local function playToggleSound(isOn: boolean)
    -- İsteğe bağlı: toggle geri bildirimi (titreme)
    if VisionState.isMobile and UserInputService.VibrationEnabled then
        pcall(function()
            game:GetService("HapticService"):SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, isOn and 0.4 or 0.15)
            task.delay(0.1, function()
                pcall(function()
                    game:GetService("HapticService"):SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
                end)
            end)
        end)
    end
end

local function applyCorner(instance: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function applyStroke(instance: Instance, color: Color3, thickness: number)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

-- ═══════════════════════════════════════════════════════════════
--  ESP BİLEŞENLERİ
-- ═══════════════════════════════════════════════════════════════

local function createBallHighlight(parent: Instance): Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name                = "ArenaVision_Highlight"
    highlight.FillColor           = Color3.fromRGB(0, 255, 120)
    highlight.FillTransparency    = 0.55
    highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent              = parent
    return highlight
end

local function createBallLabel(parent: Instance): BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name         = "ArenaVision_Label"
    billboard.Size         = UDim2.new(5, 0, 1.6, 0)
    billboard.StudsOffset  = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop  = true
    billboard.MaxDistance  = 600
    billboard.Parent       = parent

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3             = Color3.fromRGB(0, 255, 120)
    label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.3
    label.TextScaled             = true
    label.Font                   = Enum.Font.GothamBlack
    label.Text                   = "⚽ TOP"
    label.Parent                 = billboard

    return billboard
end

local function enableBallESP(target: BasePart)
    if VisionState.ballHighlight then VisionState.ballHighlight:Destroy() end
    if VisionState.ballBillboard then VisionState.ballBillboard:Destroy() end

    VisionState.ballHighlight = createBallHighlight(target)
    VisionState.ballBillboard = createBallLabel(target)

    target:GetPropertyChangedSignal("Size"):Connect(function()
        if VisionState.ballBillboard then
            VisionState.ballBillboard.StudsOffset = Vector3.new(0, target.Size.Y / 2 + 1.8, 0)
        end
    end)
end

local function disableBallESP()
    if VisionState.ballHighlight then VisionState.ballHighlight:Destroy() VisionState.ballHighlight = nil end
    if VisionState.ballBillboard then VisionState.ballBillboard:Destroy() VisionState.ballBillboard = nil end
end

-- ═══════════════════════════════════════════════════════════════
--  YÖRÜNGE SİSTEMİ
-- ═══════════════════════════════════════════════════════════════

local function clearTrajectory()
    for _, dot in ipairs(VisionState.trajectoryDots) do
        if dot and dot.Parent then dot:Destroy() end
    end
    table.clear(VisionState.trajectoryDots)
end

local function spawnTrajectoryDot(position: Vector3, index: int)
    local dot = Instance.new("Part")
    dot.Name         = "ArenaVision_TrajDot"
    dot.Anchored     = true
    dot.CanCollide   = false
    dot.CanQuery     = false
    dot.CanTouch     = false
    dot.Massless     = true
    dot.Shape        = Enum.PartType.Ball
    dot.Size         = Vector3.new(0.25, 0.25, 0.25)
    dot.Position     = position
    dot.Color        = Color3.fromRGB(255, 90 + index * 3, 0)
    dot.Material     = Enum.Material.Neon
    dot.Transparency = 0.15 + (index / VISION_CONFIG.TRAJECTORY_STEPS) * 0.6
    dot.Parent       = Workspace

    table.insert(VisionState.trajectoryDots, dot)
end

local function updateTrajectory()
    clearTrajectory()

    local ball = VisionState.ball
    if not VISION_CONFIG.TRAJECTORY_ENABLED or not ball or not ball:IsA("BasePart") then return end

    local velocity = ball.AssemblyLinearVelocity
    if velocity.Magnitude < 5 then return end

    local startPos = ball.Position
    local gravity  = VISION_CONFIG.GRAVITY
    local dt       = VISION_CONFIG.TRAJECTORY_TIME_STEP

    for i = 1, VISION_CONFIG.TRAJECTORY_STEPS do
        local t = i * dt
        local pos = startPos + velocity * t + 0.5 * gravity * t * t
        if pos.Y < -50 then break end
        spawnTrajectoryDot(pos, i)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  MOBİL SÜRÜKLEME (DOKUNMATİK)
-- ═══════════════════════════════════════════════════════════════

local function makeDraggable(frame: GuiObject)
    local dragging    = false
    local dragInput   = nil
    local dragStart   = nil
    local startPos    = nil

    local function updateDrag(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            updateDrag(input)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  ARAYÜZ OLUŞTURMA
-- ═══════════════════════════════════════════════════════════════

local function createVisionUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name            = "ArenaVision_UI"
    screenGui.ResetOnSpawn    = false
    screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset  = true
    screenGui.Parent          = PlayerGui

    local scale = VISION_CONFIG.UI_SCALE
    local panelWidth  = math.floor(240 * scale)
    local panelHeight = math.floor(210 * scale)

    -- ───── Ana Panel ─────
    local panel = Instance.new("Frame")
    panel.Name                   = "VisionPanel"
    panel.Size                   = UDim2.new(0, panelWidth, 0, panelHeight)
    panel.Position               = UDim2.new(0, 16, 0.5, -panelHeight / 2)
    panel.BackgroundColor3       = Color3.fromRGB(18, 18, 28)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel        = 0
    panel.Active                 = true
    panel.Parent                 = screenGui
    applyCorner(panel, 16)
    applyStroke(panel, Color3.fromRGB(0, 255, 120), 1.2)

    -- ───── Başlık ─────
    local header = Instance.new("Frame")
    header.Name             = "Header"
    header.Size             = UDim2.new(1, 0, 0, math.floor(42 * scale))
    header.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    header.BorderSizePixel  = 0
    header.Parent           = panel
    applyCorner(header, 16)

    local headerFix = Instance.new("Frame")
    headerFix.Size             = UDim2.new(1, 0, 0.5, 0)
    headerFix.Position         = UDim2.new(0, 0, 0.5, 0)
    headerFix.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    headerFix.BorderSizePixel  = 0
    headerFix.Parent           = header

    local title = Instance.new("TextLabel")
    title.Size                   = UDim2.new(1, -60, 1, 0)
    title.Position               = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text                   = "⚽ ARENA VISION"
    title.TextColor3             = Color3.fromRGB(0, 255, 120)
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.TextScaled             = true
    title.Font                   = Enum.Font.GothamBold
    title.Parent                 = header

    -- Kapat (X) butonu
    local closeButton = Instance.new("TextButton")
    closeButton.Size                   = UDim2.new(0, 34, 0, 34)
    closeButton.Position               = UDim2.new(1, -40, 0.5, -17)
    closeButton.BackgroundColor3       = Color3.fromRGB(200, 55, 55)
    closeButton.Text                   = "✕"
    closeButton.TextColor3             = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled             = true
    closeButton.Font                   = Enum.Font.GothamBold
    closeButton.BorderSizePixel        = 0
    closeButton.AutoButtonColor        = true
    closeButton.Parent                 = header
    applyCorner(closeButton, 10)

    -- ───── ESP Butonu ─────
    local espButton = Instance.new("TextButton")
    espButton.Name             = "ESPButton"
    espButton.Size             = UDim2.new(1, -24, 0, VISION_CONFIG.BUTTON_HEIGHT * scale)
    espButton.Position         = UDim2.new(0, 12, 0, math.floor(56 * scale))
    espButton.BackgroundColor3 = Color3.fromRGB(0, 190, 90)
    espButton.Text             = "TOP ESP  •  AÇIK"
    espButton.TextColor3       = Color3.fromRGB(255, 255, 255)
    espButton.TextScaled       = true
    espButton.Font             = Enum.Font.GothamBold
    espButton.BorderSizePixel  = 0
    espButton.AutoButtonColor  = false
    espButton.Parent           = panel
    applyCorner(espButton, 12)

    -- ───── Yörünge Butonu ─────
    local trajButton = Instance.new("TextButton")
    trajButton.Name             = "TrajButton"
    trajButton.Size             = UDim2.new(1, -24, 0, VISION_CONFIG.BUTTON_HEIGHT * scale)
    trajButton.Position         = UDim2.new(0, 12, 0, math.floor(120 * scale))
    trajButton.BackgroundColor3 = Color3.fromRGB(0, 190, 90)
    trajButton.Text             = "YÖRÜNGE  •  AÇIK"
    trajButton.TextColor3       = Color3.fromRGB(255, 255, 255)
    trajButton.TextScaled       = true
    trajButton.Font             = Enum.Font.GothamBold
    trajButton.BorderSizePixel  = 0
    trajButton.AutoButtonColor  = false
    trajButton.Parent           = panel
    applyCorner(trajButton, 12)

    -- ───── Sürükleme İpucu ─────
    local hint = Instance.new("TextLabel")
    hint.Size                   = UDim2.new(1, 0, 0, 20)
    hint.Position               = UDim2.new(0, 0, 1, -24)
    hint.BackgroundTransparency = 1
    hint.Text                   = "☰  Sürüklemek için başlığı tut"
    hint.TextColor3             = Color3.fromRGB(150, 150, 170)
    hint.TextScaled             = true
    hint.Font                   = Enum.Font.Gotham
    hint.Parent                 = panel

    -- ═══════════════════════════════════════════════════════════════
    --  AÇ / KAPA BUTONU (Ekranın sağ altı, mobil için ideal)
    -- ═══════════════════════════════════════════════════════════════
    local openButton = Instance.new("TextButton")
    openButton.Name             = "OpenButton"
    openButton.Size             = UDim2.new(0, VISION_CONFIG.OPEN_BUTTON_SIZE, 0, VISION_CONFIG.OPEN_BUTTON_SIZE)
    openButton.Position         = UDim2.new(1, -VISION_CONFIG.OPEN_BUTTON_SIZE - 20, 1, -VISION_CONFIG.OPEN_BUTTON_SIZE - 120)
    openButton.BackgroundColor3 = Color3.fromRGB(0, 190, 90)
    openButton.Text             = "⚽"
    openButton.TextColor3       = Color3.fromRGB(255, 255, 255)
    openButton.TextScaled       = true
    openButton.Font             = Enum.Font.GothamBold
    openButton.BorderSizePixel  = 0
    openButton.Visible          = false
    openButton.Parent           = screenGui
    applyCorner(openButton, VISION_CONFIG.OPEN_BUTTON_SIZE / 2)
    applyStroke(openButton, Color3.fromRGB(255, 255, 255), 1.5)

    -- ═══════════════════════════════════════════════════════════════
    --  OLAY BAĞLANTILARI
    -- ═══════════════════════════════════════════════════════════════

    -- ESP Toggle
    espButton.MouseButton1Click:Connect(function()
        VISION_CONFIG.ESP_ENABLED = not VISION_CONFIG.ESP_ENABLED
        playToggleSound(VISION_CONFIG.ESP_ENABLED)

        if VISION_CONFIG.ESP_ENABLED then
            espButton.BackgroundColor3 = Color3.fromRGB(0, 190, 90)
            espButton.Text = "TOP ESP  •  AÇIK"
            if VisionState.ball then enableBallESP(VisionState.ball) end
        else
            espButton.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
            espButton.Text = "TOP ESP  •  KAPALI"
            disableBallESP()
        end
    end)

    -- Yörünge Toggle
    trajButton.MouseButton1Click:Connect(function()
        VISION_CONFIG.TRAJECTORY_ENABLED = not VISION_CONFIG.TRAJECTORY_ENABLED
        playToggleSound(VISION_CONFIG.TRAJECTORY_ENABLED)

        if VISION_CONFIG.TRAJECTORY_ENABLED then
            trajButton.BackgroundColor3 = Color3.fromRGB(0, 190, 90)
            trajButton.Text = "YÖRÜNGE  •  AÇIK"
        else
            trajButton.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
            trajButton.Text = "YÖRÜNGE  •  KAPALI"
            clearTrajectory()
        end
    end)

    -- Kapat
    closeButton.MouseButton1Click:Connect(function()
        panel.Visible      = false
        openButton.Visible = true
        if VISION_CONFIG.TRAJECTORY_ENABLED then clearTrajectory() end
    end)

    -- Aç
    openButton.MouseButton1Click:Connect(function()
        panel.Visible      = true
        openButton.Visible = false
    end)

    -- Sürükleme (tüm panel değil, sadece başlık)
    makeDraggable(header)

    return screenGui, panel, openButton
end

-- ═══════════════════════════════════════════════════════════════
--  TOP TAKİBİ
-- ═══════════════════════════════════════════════════════════════

local function locateBall(): BasePart?
    local found = Workspace:FindFirstChild(VISION_CONFIG.BALL_NAME, true)
    if found and found:IsA("BasePart") then return found end
    return nil
end

local function onDescendantAdded(child: Instance)
    if child:IsA("BasePart") and child.Name == VISION_CONFIG.BALL_NAME then
        VisionState.ball = child
        if VISION_CONFIG.ESP_ENABLED then enableBallESP(child) end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  ANA DÖNGÜ (Throttled)
-- ═══════════════════════════════════════════════════════════════

local function startVisionLoop()
    while task.wait(VISION_CONFIG.UPDATE_RATE) do
        if not VisionState.ball or not VisionState.ball.Parent then
            VisionState.ball = locateBall()
            if VisionState.ball and VISION_CONFIG.ESP_ENABLED and not VisionState.ballHighlight then
                enableBallESP(VisionState.ball)
            end
        end

        if VISION_CONFIG.TRAJECTORY_ENABLED then
            updateTrajectory()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  BAŞLATMA
-- ═══════════════════════════════════════════════════════════════

local screenGui, mainPanel, openButton = createVisionUI()

VisionState.ball = locateBall()
if VisionState.ball and VISION_CONFIG.ESP_ENABLED then
    enableBallESP(VisionState.ball)
end

Workspace.DescendantAdded:Connect(onDescendantAdded)
task.spawn(startVisionLoop)

-- Mobil için: Panel açıkken yörünge temizliği güvencesi
LocalPlayer.CharacterAdded:Connect(function()
    clearTrajectory()
end)

print("[ArenaVision] ⚽ Mobil sürüm aktif. Panel sürüklemek için başlığı tut.")
