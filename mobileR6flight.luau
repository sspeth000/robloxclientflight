local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Settings
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local PLATFORM_OFFSET = 3.5
local FLIGHT_SPEED_MULTIPLIER = 10

local moveSpeed = 20
local playerSpeed = 16
local direction = 0
local flying = true

local character
local rootPart
local humanoid
local platform

local activeTouches = {}
local activeMouseButtons = {}

-- Remove an older copy of this GUI
local oldGui = playerGui:FindFirstChild("FreshFlightControls")
if oldGui then
	oldGui:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FreshFlightControls"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromOffset(190, 308)
frame.Position = UDim2.new(0.5, -95, 0.5, -154)
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(67, 105, 170)
frameStroke.Thickness = 1
frameStroke.Transparency = 0.35
frameStroke.Parent = frame

-- Section divider helper
-- Titles sit above rounded blue accent lines
local function makeDivider(text, y)
	local divider = Instance.new("Frame")
	divider.Name = text .. "Divider"
	divider.Position = UDim2.fromOffset(12, y)
	divider.Size = UDim2.fromOffset(166, 22)
	divider.BackgroundTransparency = 1
	divider.BorderSizePixel = 0
	divider.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "SectionTitle"
	label.Size = UDim2.new(1, 0, 0, 15)
	label.Position = UDim2.fromOffset(0, 0)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(130, 175, 255)
	label.TextSize = 13
	label.Font = Enum.Font.SourceSansBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = divider

	local line = Instance.new("Frame")
	line.Name = "AccentLine"
	line.Size = UDim2.new(1, 0, 0, 2)
	line.Position = UDim2.fromOffset(0, 18)
	line.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
	line.BorderSizePixel = 0
	line.Parent = divider

	local lineCorner = Instance.new("UICorner")
	lineCorner.CornerRadius = UDim.new(1, 0)
	lineCorner.Parent = line

	return divider
end

-- Button helper
local function makeButton(name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 14
	button.Font = Enum.Font.SourceSansSemibold
	button.TextWrapped = true
	button.BorderSizePixel = 0
	button.Active = true
	button.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button

	return button
end

-- Controls section
local controlsDivider = makeDivider("Controls", 8)

local upButton = makeButton(
	"UpButton",
	"Up",
	UDim2.fromOffset(12, 32),
	UDim2.fromOffset(166, 25)
)

local downButton = makeButton(
	"DownButton",
	"Down",
	UDim2.fromOffset(12, 62),
	UDim2.fromOffset(166, 25)
)

-- Increment section
makeDivider("Increment", 94)

local incrementBox = Instance.new("TextBox")
incrementBox.Name = "IncrementBox"
incrementBox.Size = UDim2.fromOffset(166, 25)
incrementBox.Position = UDim2.fromOffset(12, 119)
incrementBox.BackgroundColor3 = Color3.fromRGB(48, 51, 62)
incrementBox.TextColor3 = Color3.new(1, 1, 1)
incrementBox.PlaceholderText = "Flight increment"
incrementBox.Text = "2"
incrementBox.TextSize = 14
incrementBox.ClearTextOnFocus = false
incrementBox.BorderSizePixel = 0
incrementBox.Parent = frame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 5)
inputCorner.Parent = incrementBox

local applyButton = makeButton(
	"ApplyButton",
	"Apply",
	UDim2.fromOffset(12, 148),
	UDim2.fromOffset(166, 23)
)

-- Speed section
makeDivider("Speed", 183)

local playerSpeedBox = Instance.new("TextBox")
playerSpeedBox.Name = "PlayerSpeedBox"
playerSpeedBox.Size = UDim2.fromOffset(166, 25)
playerSpeedBox.Position = UDim2.fromOffset(12, 208)
playerSpeedBox.BackgroundColor3 = Color3.fromRGB(48, 51, 62)
playerSpeedBox.TextColor3 = Color3.new(1, 1, 1)
playerSpeedBox.PlaceholderText = "Player speed"
playerSpeedBox.Text = tostring(playerSpeed)
playerSpeedBox.TextSize = 14
playerSpeedBox.ClearTextOnFocus = false
playerSpeedBox.BorderSizePixel = 0
playerSpeedBox.Parent = frame

local playerSpeedCorner = Instance.new("UICorner")
playerSpeedCorner.CornerRadius = UDim.new(0, 5)
playerSpeedCorner.Parent = playerSpeedBox

local playerSpeedApplyButton = makeButton(
	"PlayerSpeedApplyButton",
	"Apply Speed",
	UDim2.fromOffset(12, 237),
	UDim2.fromOffset(166, 23)
)

-- Fly / Unfly at the bottom
local flyButton = makeButton(
	"FlyButton",
	"Unfly",
	UDim2.fromOffset(12, 267),
	UDim2.fromOffset(166, 29)
)

-- Dragging: use the Controls divider as the handle
local dragging = false
local dragTouch
local dragStart
local frameStart

controlsDivider.Active = true

controlsDivider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragTouch = nil
		dragStart = input.Position
		frameStart = frame.Position
	elseif input.UserInputType == Enum.UserInputType.Touch and not dragTouch then
		dragging = true
		dragTouch = input
		dragStart = input.Position
		frameStart = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement and not dragTouch then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		)
	elseif input == dragTouch then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not dragTouch then
		dragging = false
	elseif input == dragTouch then
		dragging = false
		dragTouch = nil
	end
end)

-- Platform
local function updateFlyButton()
	flyButton.Text = flying and "Unfly" or "Fly"
end

local function removePlatform()
	if platform then
		platform:Destroy()
		platform = nil
	end
end

local function createPlatform()
	if not flying or not rootPart or not rootPart.Parent then
		return
	end

	removePlatform()

	platform = Instance.new("Part")
	platform.Name = "FlightPlatform"
	platform.Size = PLATFORM_SIZE
	platform.Anchored = true
	platform.CanCollide = true
	platform.CanTouch = false
	platform.CanQuery = false
	platform.Material = Enum.Material.SmoothPlastic
	platform.Color = Color3.fromRGB(255, 255, 255)
	platform.Transparency = 0.5
	platform.CFrame = rootPart.CFrame * CFrame.new(0, -PLATFORM_OFFSET, 0)
	platform.Parent = workspace
end

-- Apply player walking speed
local function applyPlayerSpeed()
	local value = tonumber(playerSpeedBox.Text)

	if not value or value < 0 or value > 100 then
		playerSpeedBox.Text = tostring(playerSpeed)
		return
	end

	playerSpeed = value

	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = playerSpeed
	end

	playerSpeedBox.Text = tostring(playerSpeed)
end

playerSpeedApplyButton.Activated:Connect(applyPlayerSpeed)

playerSpeedBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		applyPlayerSpeed()
	end
end)

-- Character setup
local function setupCharacter(newCharacter)
	direction = 0
	table.clear(activeTouches)
	table.clear(activeMouseButtons)

	removePlatform()

	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	-- Fetch the character's actual current speed
	playerSpeed = humanoid.WalkSpeed
	playerSpeedBox.Text = tostring(playerSpeed)

	if flying then
		createPlatform()
	end
end

player.CharacterAdded:Connect(setupCharacter)

player.CharacterRemoving:Connect(function()
	direction = 0
	table.clear(activeTouches)
	table.clear(activeMouseButtons)

	removePlatform()

	rootPart = nil
	humanoid = nil
	character = nil
end)

if player.Character then
	task.spawn(setupCharacter, player.Character)
end

-- Apply vertical flight speed
local function applyFlightSpeed()
	local value = tonumber(incrementBox.Text)

	if not value or value <= 0 or value > 100 then
		incrementBox.Text = tostring(moveSpeed / FLIGHT_SPEED_MULTIPLIER)
		return
	end

	moveSpeed = value * FLIGHT_SPEED_MULTIPLIER
	incrementBox.Text = tostring(value)
end

applyButton.Activated:Connect(applyFlightSpeed)

incrementBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		applyFlightSpeed()
	end
end)

-- Direction tracking for multitouch
local function refreshDirection()
	if not flying then
		direction = 0
		return
	end

	local upHeld = false
	local downHeld = false

	for _, heldDirection in pairs(activeTouches) do
		if heldDirection == 1 then
			upHeld = true
		elseif heldDirection == -1 then
			downHeld = true
		end
	end

	for _, heldDirection in pairs(activeMouseButtons) do
		if heldDirection == 1 then
			upHeld = true
		elseif heldDirection == -1 then
			downHeld = true
		end
	end

	if upHeld and not downHeld then
		direction = 1
	elseif downHeld and not upHeld then
		direction = -1
	else
		direction = 0
	end
end

local function bindHold(button, newDirection)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			activeTouches[input] = newDirection
			refreshDirection()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			activeMouseButtons[button] = newDirection
			refreshDirection()
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			activeTouches[input] = nil
			refreshDirection()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			activeMouseButtons[button] = nil
			refreshDirection()
		end
	end)
end

bindHold(upButton, 1)
bindHold(downButton, -1)

UserInputService.TouchEnded:Connect(function(touch)
	if activeTouches[touch] then
		activeTouches[touch] = nil
		refreshDirection()
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	table.clear(activeTouches)
	table.clear(activeMouseButtons)

	dragging = false
	dragTouch = nil

	refreshDirection()
end)

-- Fly / Unfly
flyButton.Activated:Connect(function()
	flying = not flying

	table.clear(activeTouches)
	table.clear(activeMouseButtons)
	direction = 0

	if flying then
		createPlatform()
	else
		removePlatform()
	end

	updateFlyButton()
end)

-- Movement
RunService.Heartbeat:Connect(function(deltaTime)
	if not rootPart or not rootPart.Parent then
		return
	end

	if flying and platform and platform.Parent then
		if direction ~= 0 then
			local deltaY = direction * moveSpeed * deltaTime
			rootPart.CFrame = rootPart.CFrame + Vector3.new(0, deltaY, 0)
		end

		platform.CFrame = rootPart.CFrame * CFrame.new(0, -PLATFORM_OFFSET, 0)
	end
end)

updateFlyButton()
