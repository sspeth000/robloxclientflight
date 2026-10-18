local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Settings
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local PLATFORM_OFFSET = 3.5
local FLIGHT_SPEED_MULTIPLIER = 10
local R15_CLEARANCE = 0.1

-- Session settings (preserved across character respawns)
local moveSpeed = 20
local playerSpeed = 16
local direction = 0
local flying = true
local noclipEnabled = false
local speedPersistEnabled = false
local minimized = false

local character
local rootPart
local humanoid
local platform

local isR15 = false
local platformY
local r15BottomOffset

local activeTouches = {}
local activeMouseButtons = {}

local jumpSnapshots = setmetatable({}, { __mode = "k" })
local collisionSnapshots = setmetatable({}, { __mode = "k" })

local jumpConnection
local stateConnection
local descendantConnection

-- Remove older GUI
local oldGui = playerGui:FindFirstChild("FreshFlightControls")
if oldGui then
	oldGui:Destroy()
end

-- Main GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FreshFlightControls"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromOffset(190, 418)
frame.Position = UDim2.new(0.5, -95, 0.5, -209)
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(67, 105, 170)
frameStroke.Thickness = 1
frameStroke.Transparency = 0.35
frameStroke.Parent = frame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = Color3.fromRGB(38, 42, 54)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.ZIndex = 2
titleBar.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.fromOffset(10, 0)
titleLabel.Size = UDim2.new(1, -48, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Flight Controller"
titleLabel.TextColor3 = Color3.fromRGB(160, 195, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.fromOffset(28, 24)
minimizeButton.Position = UDim2.new(1, -30, 0, 2)
minimizeButton.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.Text = "-"
minimizeButton.TextSize = 22
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.BorderSizePixel = 0
minimizeButton.ZIndex = 3
minimizeButton.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = minimizeButton

-- Content
local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(0, 28)
content.Size = UDim2.new(1, 0, 1, -28)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Parent = frame

local function makeDivider(text, y)
	local divider = Instance.new("Frame")
	divider.Name = text .. "Divider"
	divider.Position = UDim2.fromOffset(12, y)
	divider.Size = UDim2.fromOffset(166, 22)
	divider.BackgroundTransparency = 1
	divider.BorderSizePixel = 0
	divider.Parent = content

	local label = Instance.new("TextLabel")
	label.Name = "SectionTitle"
	label.Size = UDim2.new(1, 0, 0, 15)
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

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = line

	return divider
end

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
	button.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button

	return button
end

local function makeTextBox(name, placeholder, text, position)
	local box = Instance.new("TextBox")
	box.Name = name
	box.Size = UDim2.fromOffset(166, 25)
	box.Position = position
	box.BackgroundColor3 = Color3.fromRGB(48, 51, 62)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.PlaceholderText = placeholder
	box.Text = text
	box.TextSize = 14
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = box

	return box
end

-- Controls
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

-- Flight increment
local incrementDivider = makeDivider("Increment", 94)

local incrementBox = makeTextBox(
	"IncrementBox",
	"Flight increment",
	"2",
	UDim2.fromOffset(12, 119)
)

local applyButton = makeButton(
	"ApplyButton",
	"Apply",
	UDim2.fromOffset(12, 148),
	UDim2.fromOffset(166, 23)
)

-- Speed
local speedDivider = makeDivider("Speed", 183)

local playerSpeedBox = makeTextBox(
	"PlayerSpeedBox",
	"Player speed",
	tostring(playerSpeed),
	UDim2.fromOffset(12, 208)
)

local playerSpeedApplyButton = makeButton(
	"PlayerSpeedApplyButton",
	"Apply Speed",
	UDim2.fromOffset(12, 237),
	UDim2.fromOffset(166, 23)
)

local speedPersistButton = makeButton(
	"SpeedPersistButton",
	"Persist Speed: OFF",
	UDim2.fromOffset(12, 265),
	UDim2.fromOffset(166, 26)
)

-- Noclip
local noclipDivider = makeDivider("Noclip", 296)

local noclipButton = makeButton(
	"NoclipButton",
	"Noclip: OFF",
	UDim2.fromOffset(12, 321),
	UDim2.fromOffset(166, 26)
)

-- Fly / Unfly
local flyButton = makeButton(
	"FlyButton",
	"Unfly",
	UDim2.fromOffset(12, 355),
	UDim2.fromOffset(166, 26)
)

-- GUI layout
local function updatePanelLayout()
	local hasPlatform = platform ~= nil and platform.Parent ~= nil

	content.Visible = not minimized

	if minimized then
		frame.Size = UDim2.fromOffset(190, 30)
		minimizeButton.Text = "+"
		return
	end

	minimizeButton.Text = "-"

	if hasPlatform then
		frame.Size = UDim2.fromOffset(190, 418)

		controlsDivider.Visible = true
		upButton.Visible = true
		downButton.Visible = true

		incrementDivider.Visible = true
		incrementBox.Visible = true
		applyButton.Visible = true

		speedPersistButton.Visible = true

		controlsDivider.Position = UDim2.fromOffset(12, 8)
		upButton.Position = UDim2.fromOffset(12, 32)
		downButton.Position = UDim2.fromOffset(12, 62)

		incrementDivider.Position = UDim2.fromOffset(12, 94)
		incrementBox.Position = UDim2.fromOffset(12, 119)
		applyButton.Position = UDim2.fromOffset(12, 148)

		speedDivider.Position = UDim2.fromOffset(12, 183)
		playerSpeedBox.Position = UDim2.fromOffset(12, 208)
		playerSpeedApplyButton.Position = UDim2.fromOffset(12, 237)
		speedPersistButton.Position = UDim2.fromOffset(12, 265)

		noclipDivider.Position = UDim2.fromOffset(12, 296)
		noclipButton.Position = UDim2.fromOffset(12, 321)
		flyButton.Position = UDim2.fromOffset(12, 355)
	else
		frame.Size = UDim2.fromOffset(190, 238)

		controlsDivider.Visible = false
		upButton.Visible = false
		downButton.Visible = false

		incrementDivider.Visible = false
		incrementBox.Visible = false
		applyButton.Visible = false

		speedDivider.Position = UDim2.fromOffset(12, 8)
		playerSpeedBox.Position = UDim2.fromOffset(12, 33)
		playerSpeedApplyButton.Position = UDim2.fromOffset(12, 62)
		speedPersistButton.Position = UDim2.fromOffset(12, 91)

		noclipDivider.Position = UDim2.fromOffset(12, 122)
		noclipButton.Position = UDim2.fromOffset(12, 147)
		flyButton.Position = UDim2.fromOffset(12, 181)

		speedPersistButton.Visible = true
	end
end

-- Minimize / restore
minimizeButton.Activated:Connect(function()
	minimized = not minimized
	updatePanelLayout()
end)

-- Dragging
local dragging = false
local dragTouch
local dragStart
local frameStart

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragTouch = nil
		dragStart = input.Position
		frameStart = frame.Position
	elseif input.UserInputType == Enum.UserInputType.Touch then
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

	if input.UserInputType == Enum.UserInputType.MouseMovement
		and not dragTouch then

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
	if input.UserInputType == Enum.UserInputType.MouseButton1
		and not dragTouch then
		dragging = false
	elseif input == dragTouch then
		dragging = false
		dragTouch = nil
	end
end)

-- Jump settings
local function disableJumping()
	if not humanoid or not humanoid.Parent then
		return
	end

	if not jumpSnapshots[humanoid] then
		jumpSnapshots[humanoid] = {
			JumpPower = humanoid.JumpPower,
			JumpHeight = humanoid.JumpHeight,
			JumpingEnabled = humanoid:GetStateEnabled(
				Enum.HumanoidStateType.Jumping
			),
		}
	end

	humanoid.Jump = false
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Jumping,
		false
	)
end

local function restoreJumping(targetHumanoid)
	if not targetHumanoid then
		return
	end

	local saved = jumpSnapshots[targetHumanoid]
	if not saved then
		return
	end

	if targetHumanoid.Parent then
		targetHumanoid.Jump = false
		targetHumanoid.JumpPower = saved.JumpPower
		targetHumanoid.JumpHeight = saved.JumpHeight

		targetHumanoid:SetStateEnabled(
			Enum.HumanoidStateType.Jumping,
			saved.JumpingEnabled
		)
	end

	jumpSnapshots[targetHumanoid] = nil
end

-- Noclip
local function applyNoclipToPart(part)
	if not noclipEnabled or not character then
		return
	end

	if not part:IsA("BasePart") then
		return
	end

	if not part:IsDescendantOf(character) then
		return
	end

	if collisionSnapshots[part] == nil then
		collisionSnapshots[part] = part.CanCollide
	end

	part.CanCollide = false
end

local function restoreCharacterCollisions(targetCharacter)
	if not targetCharacter then
		return
	end

	for _, descendant in ipairs(targetCharacter:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local saved = collisionSnapshots[descendant]

			if saved ~= nil then
				descendant.CanCollide = saved
				collisionSnapshots[descendant] = nil
			end
		end
	end
end

local function setNoclip(enabled)
	noclipEnabled = enabled

	if noclipEnabled then
		if character then
			for _, descendant in ipairs(character:GetDescendants()) do
				applyNoclipToPart(descendant)
			end
		end

		noclipButton.Text = "Noclip: ON"
		noclipButton.BackgroundColor3 = Color3.fromRGB(55, 145, 95)
	else
		if character then
			restoreCharacterCollisions(character)
		end

		noclipButton.Text = "Noclip: OFF"
		noclipButton.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
	end
end

noclipButton.Activated:Connect(function()
	setNoclip(not noclipEnabled)
end)

-- Speed persistence toggle
local function updateSpeedPersistButton()
	if speedPersistEnabled then
		speedPersistButton.Text = "Persist Speed: ON"
		speedPersistButton.BackgroundColor3 =
			Color3.fromRGB(55, 145, 95)
	else
		speedPersistButton.Text = "Persist Speed: OFF"
		speedPersistButton.BackgroundColor3 =
			Color3.fromRGB(67, 105, 170)
	end
end

speedPersistButton.Activated:Connect(function()
	speedPersistEnabled = not speedPersistEnabled

	if speedPersistEnabled and humanoid and humanoid.Parent then
		humanoid.WalkSpeed = playerSpeed
	end

	updateSpeedPersistButton()
end)

updateSpeedPersistButton()

-- Platform
local function removePlatform()
	local oldPlatform = platform
	platform = nil

	if oldPlatform then
		oldPlatform:Destroy()
	end

	platformY = nil
	r15BottomOffset = nil

	restoreJumping(humanoid)
	updatePanelLayout()
end

local function createPlatform()
	if not flying or not rootPart or not rootPart.Parent then
		return
	end

	removePlatform()

	if not humanoid or not humanoid.Parent then
		return
	end

	isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

	local startPosition

	if isR15 and character then
		local boxCFrame, boxSize = character:GetBoundingBox()

		r15BottomOffset =
			boxCFrame.Position.Y
			- boxSize.Y / 2
			- rootPart.Position.Y

		platformY =
			rootPart.Position.Y
			+ r15BottomOffset
			- PLATFORM_SIZE.Y / 2
			- R15_CLEARANCE

		startPosition = Vector3.new(
			rootPart.Position.X,
			platformY,
			rootPart.Position.Z
		)
	else
		startPosition = (
			rootPart.CFrame * CFrame.new(0, -PLATFORM_OFFSET, 0)
		).Position
	end

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
	platform.Position = startPosition
	platform.Parent = workspace

	disableJumping()
	updatePanelLayout()
end

-- Character setup
local function setupCharacter(newCharacter)
	direction = 0
	table.clear(activeTouches)
	table.clear(activeMouseButtons)

	if character then
		restoreCharacterCollisions(character)
	end

	removePlatform()

	if jumpConnection then
		jumpConnection:Disconnect()
		jumpConnection = nil
	end

	if stateConnection then
		stateConnection:Disconnect()
		stateConnection = nil
	end

	if descendantConnection then
		descendantConnection:Disconnect()
		descendantConnection = nil
	end

	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

	-- Reapply selected speed on respawn
	humanoid.WalkSpeed = playerSpeed
	playerSpeedBox.Text = tostring(playerSpeed)

	-- Update the current noclip state and visuals
	setNoclip(noclipEnabled)

	descendantConnection = character.DescendantAdded:Connect(function(descendant)
		if noclipEnabled then
			task.defer(function()
				if descendant.Parent and character
					and descendant:IsDescendantOf(character) then
					applyNoclipToPart(descendant)
				end
			end)
		end
	end)

	if flying then
		createPlatform()
	else
		updatePanelLayout()
	end

	jumpConnection = humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
		if platform and platform.Parent then
			humanoid.Jump = false
		end
	end)

	stateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if platform and platform.Parent
			and newState == Enum.HumanoidStateType.Jumping then
			disableJumping()
		end
	end)
end

player.CharacterAdded:Connect(setupCharacter)

player.CharacterRemoving:Connect(function(oldCharacter)
	direction = 0
	table.clear(activeTouches)
	table.clear(activeMouseButtons)

	restoreCharacterCollisions(oldCharacter)

	if oldCharacter == character then
		removePlatform()

		if jumpConnection then
			jumpConnection:Disconnect()
			jumpConnection = nil
		end

		if stateConnection then
			stateConnection:Disconnect()
			stateConnection = nil
		end

		if descendantConnection then
			descendantConnection:Disconnect()
			descendantConnection = nil
		end

		rootPart = nil
		humanoid = nil
		character = nil
	end

	updatePanelLayout()
end)

-- Initial layout
updatePanelLayout()

if player.Character then
	task.spawn(setupCharacter, player.Character)
end

-- Player speed
local function applyPlayerSpeed()
	local value = tonumber(playerSpeedBox.Text)

	-- Require finite numeric input at least 0.1; no upper bound.
	if value == nil or value ~= value or value == math.huge or value == -math.huge or value < 0.1 then
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

-- Flight increment
local function applyFlightSpeed()
	local value = tonumber(incrementBox.Text)

	-- Require finite numeric input at least 0.1; no upper bound.
	if value == nil or value ~= value or value == math.huge or value == -math.huge or value < 0.1 then
		incrementBox.Text = tostring(
			moveSpeed / FLIGHT_SPEED_MULTIPLIER
		)
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

-- Multitouch direction controls
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

	flyButton.Text = flying and "Unfly" or "Fly"
	updatePanelLayout()
end)

-- Movement and enforcement
RunService.Heartbeat:Connect(function(deltaTime)
	-- Keep the selected speed applied while persistence is enabled.
	-- This is client-side enforcement; server-authoritative movement
	-- settings may still override the local Humanoid.
	if speedPersistEnabled and humanoid and humanoid.Parent then
		if humanoid.WalkSpeed ~= playerSpeed then
			humanoid.WalkSpeed = playerSpeed
		end
	end

	if noclipEnabled and character and character.Parent then
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.CanCollide then
				applyNoclipToPart(descendant)
			end
		end
	end

	if not rootPart or not rootPart.Parent then
		return
	end

	if platform and platform.Parent and humanoid and humanoid.Parent then
		if humanoid.JumpPower ~= 0
			or humanoid.JumpHeight ~= 0
			or humanoid:GetStateEnabled(
				Enum.HumanoidStateType.Jumping
			) then
			disableJumping()
		end

		humanoid.Jump = false
	end

	if not (flying and platform and platform.Parent) then
		return
	end

	if isR15 and platformY ~= nil and r15BottomOffset ~= nil then
		if direction ~= 0 then
			platformY += direction * moveSpeed * deltaTime
		end

		platform.Position = Vector3.new(
			rootPart.Position.X,
			platformY,
			rootPart.Position.Z
		)

		local targetRootY =
			platformY
			+ PLATFORM_SIZE.Y / 2
			+ R15_CLEARANCE
			- r15BottomOffset

		local currentPosition = rootPart.Position

		rootPart.CFrame = CFrame.new(
			currentPosition.X,
			targetRootY,
			currentPosition.Z
		) * rootPart.CFrame.Rotation
	else
		if direction ~= 0 then
			local deltaY = direction * moveSpeed * deltaTime

			rootPart.CFrame =
				rootPart.CFrame + Vector3.new(0, deltaY, 0)
		end

		platform.CFrame =
			rootPart.CFrame * CFrame.new(0, -PLATFORM_OFFSET, 0)
	end
end)
