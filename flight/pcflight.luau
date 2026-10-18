-- FreshFlightControls
-- PC-native Roblox Studio LocalScript
--
-- E          = Ascend
-- Q          = Descend
-- F          = Toggle flight platform
-- X          = Toggle noclip
-- R          = Show/hide GUI
-- Mouse drag = Move GUI
-- Minimize   = Collapse/expand GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- SETTINGS
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local PLATFORM_OFFSET = 3.5
local FLIGHT_SPEED_MULTIPLIER = 10
local R15_CLEARANCE = 0.1

-- STATE
local moveSpeed = 20
local playerSpeed = 16

local flightEnabled = true
local speedPersistEnabled = false
local noclipEnabled = false

local ascendHeld = false
local descendHeld = false
local direction = 0

local character
local rootPart
local humanoid
local platform

local platformY = 0
local rootToPlatformOffset = PLATFORM_OFFSET

local characterConnections = {}
local jumpSnapshots = setmetatable({}, { __mode = "k" })
local collisionSnapshots = setmetatable({}, { __mode = "k" })

-- Remove an old GUI copy.
local oldGui = playerGui:FindFirstChild("FreshFlightControls")
if oldGui then
	oldGui:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FreshFlightControls"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "MainPanel"
frame.Size = UDim2.fromOffset(190, 460)
frame.Position = UDim2.new(0.5, -95, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
frame.BorderSizePixel = 0
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
titleBar.BackgroundColor3 = Color3.fromRGB(39, 43, 54)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleCover = Instance.new("Frame")
titleCover.Size = UDim2.new(1, 0, 0, 8)
titleCover.Position = UDim2.new(0, 0, 1, -8)
titleCover.BackgroundColor3 = titleBar.BackgroundColor3
titleCover.BorderSizePixel = 0
titleCover.Parent = titleBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -58, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "Flight Controls"
title.TextColor3 = Color3.fromRGB(235, 239, 248)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "Minimize"
minimizeButton.Size = UDim2.fromOffset(24, 22)
minimizeButton.Position = UDim2.new(1, -28, 0, 3)
minimizeButton.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 17
minimizeButton.AutoButtonColor = true
minimizeButton.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = minimizeButton

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(0, 28)
content.Size = UDim2.new(1, 0, 1, -28)
content.BackgroundTransparency = 1
content.Parent = frame

-- GUI helpers
local function makeDivider(text, y)
	local holder = Instance.new("Frame")
	holder.Name = text:gsub("%s+", "") .. "Divider"
	holder.Size = UDim2.new(1, -16, 0, 20)
	holder.Position = UDim2.fromOffset(8, y)
	holder.BackgroundTransparency = 1
	holder.Parent = content

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 17)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(130, 175, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = holder

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.fromOffset(0, 19)
	line.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
	line.BorderSizePixel = 0
	line.Parent = holder

	return holder
end

local function makeButton(text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(166, 25)
	button.Position = UDim2.fromOffset(12, y)
	button.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 13
	button.AutoButtonColor = true
	button.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button

	return button
end

local function makeTextBox(text, y)
	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(166, 25)
	box.Position = UDim2.fromOffset(12, y)
	box.BackgroundColor3 = Color3.fromRGB(48, 51, 62)
	box.Text = text
	box.PlaceholderText = ""
	box.TextColor3 = Color3.fromRGB(240, 242, 248)
	box.PlaceholderColor3 = Color3.fromRGB(150, 155, 170)
	box.Font = Enum.Font.Gotham
	box.TextSize = 13
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Center
	box.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = box

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(67, 105, 170)
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	stroke.Parent = box

	return box
end

local function makeHint(text, y)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(166, 20)
	label.Position = UDim2.fromOffset(12, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(210, 215, 228)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = content
	return label
end

local function makeToggleStatus(text, y)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(166, 20)
	label.Position = UDim2.fromOffset(12, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(210, 215, 228)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = content
	return label
end

-- Controls
local controlsDivider = makeDivider("Controls", 8)
local ascendHint = makeHint("Ascend: E", 32)
local descendHint = makeHint("Descend: Q", 56)
local flightHint = makeHint("Flight: F", 80)
local noclipHint = makeHint("Noclip: X", 98)
local guiHint = makeHint("Show/hide GUI: R", 116)

-- Increment
local incrementDivider = makeDivider("Increment", 139)
local incrementBox = makeTextBox("2", 164)
local applyIncrementButton = makeButton("Apply Increment", 193)

-- Speed
local speedDivider = makeDivider("Speed", 228)
local speedBox = makeTextBox(tostring(playerSpeed), 253)
local applySpeedButton = makeButton("Apply Speed", 282)
local persistButton = makeButton("Persist Speed: OFF", 310)

-- Toggles
local togglesDivider = makeDivider("Toggles", 341)
local flightStatus = makeToggleStatus("Flight: ON", 366)
local noclipStatus = makeToggleStatus("Noclip: OFF", 387)
local persistStatus = makeToggleStatus("Persist Speed: OFF", 408)

-- Update live toggle labels.
local function updateToggleStatus()
	flightStatus.Text = "Flight: " .. (platform and "ON" or "OFF")
	flightStatus.TextColor3 = platform
		and Color3.fromRGB(105, 220, 145)
		or Color3.fromRGB(210, 215, 228)

	noclipStatus.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
	noclipStatus.TextColor3 = noclipEnabled
		and Color3.fromRGB(105, 220, 145)
		or Color3.fromRGB(210, 215, 228)

	persistStatus.Text = "Persist Speed: " .. (speedPersistEnabled and "ON" or "OFF")
	persistStatus.TextColor3 = speedPersistEnabled
		and Color3.fromRGB(105, 220, 145)
		or Color3.fromRGB(210, 215, 228)

	if speedPersistEnabled then
		persistButton.Text = "Persist Speed: ON"
		persistButton.BackgroundColor3 = Color3.fromRGB(55, 145, 95)
	else
		persistButton.Text = "Persist Speed: OFF"
		persistButton.BackgroundColor3 = Color3.fromRGB(67, 105, 170)
	end
end

-- Layout
local minimized = false

local function updatePanelLayout()
	if minimized then
		content.Visible = false
		frame.Size = UDim2.fromOffset(190, 28)
		minimizeButton.Text = "+"
		return
	end

	content.Visible = true

	-- Controls remain visible whether or not the platform exists.
	controlsDivider.Visible = true
	ascendHint.Visible = true
	descendHint.Visible = true
	flightHint.Visible = true
	noclipHint.Visible = true
	guiHint.Visible = true

	-- Only the Increment section is hidden when the platform is absent.
	local showIncrement = platform ~= nil

	incrementDivider.Visible = showIncrement
	incrementBox.Visible = showIncrement
	applyIncrementButton.Visible = showIncrement

	if showIncrement then
		-- Full layout with Increment visible.
		frame.Size = UDim2.fromOffset(190, 460)

		speedDivider.Position = UDim2.fromOffset(8, 228)
		speedBox.Position = UDim2.fromOffset(12, 253)
		applySpeedButton.Position = UDim2.fromOffset(12, 282)
		persistButton.Position = UDim2.fromOffset(12, 310)

		togglesDivider.Position = UDim2.fromOffset(8, 341)
		flightStatus.Position = UDim2.fromOffset(12, 366)
		noclipStatus.Position = UDim2.fromOffset(12, 387)
		persistStatus.Position = UDim2.fromOffset(12, 408)
	else
		-- Compact layout: close the gap left by Increment.
		frame.Size = UDim2.fromOffset(190, 371)

		speedDivider.Position = UDim2.fromOffset(8, 139)
		speedBox.Position = UDim2.fromOffset(12, 164)
		applySpeedButton.Position = UDim2.fromOffset(12, 193)
		persistButton.Position = UDim2.fromOffset(12, 221)

		togglesDivider.Position = UDim2.fromOffset(8, 252)
		flightStatus.Position = UDim2.fromOffset(12, 277)
		noclipStatus.Position = UDim2.fromOffset(12, 298)
		persistStatus.Position = UDim2.fromOffset(12, 319)
	end

	updateToggleStatus()
	minimizeButton.Text = "−"
end

minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	updatePanelLayout()
end)

-- Mouse dragging
local dragging = false
local dragStart
local frameStart

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		frameStart = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		)
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	dragging = false
	ascendHeld = false
	descendHeld = false
	direction = 0
end)

-- Number validation: finite and at least 0.1, with no arbitrary upper limit.
local function parseNonnegativeNumber(text)
	local value = tonumber(text)

	if value == nil then
		return nil
	end

	if value ~= value or value == math.huge or value == -math.huge then
		return nil
	end

	if value < 0.1 then
		return nil
	end

	return value
end

local function refreshDirection()
	if ascendHeld and not descendHeld then
		direction = 1
	elseif descendHeld and not ascendHeld then
		direction = -1
	else
		direction = 0
	end
end

-- Jump prevention
local function disableJumping()
	if not humanoid then
		return
	end

	if not jumpSnapshots[humanoid] then
		jumpSnapshots[humanoid] = {
			JumpPower = humanoid.JumpPower,
			JumpHeight = humanoid.JumpHeight,
			UseJumpPower = humanoid.UseJumpPower,
			JumpingEnabled = humanoid:GetStateEnabled(
				Enum.HumanoidStateType.Jumping
			),
		}
	end

	humanoid.Jump = false
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end

local function restoreJumping()
	if not humanoid then
		return
	end

	local snapshot = jumpSnapshots[humanoid]
	if not snapshot then
		return
	end

	humanoid.UseJumpPower = snapshot.UseJumpPower
	humanoid.JumpPower = snapshot.JumpPower
	humanoid.JumpHeight = snapshot.JumpHeight

	humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Jumping,
		snapshot.JumpingEnabled
	)

	humanoid.Jump = false
	jumpSnapshots[humanoid] = nil
end

-- Noclip
local function setNoclipForPart(part)
	if not part:IsA("BasePart") then
		return
	end

	if noclipEnabled then
		if collisionSnapshots[part] == nil then
			collisionSnapshots[part] = part.CanCollide
		end

		part.CanCollide = false
	else
		local oldValue = collisionSnapshots[part]

		if oldValue ~= nil then
			part.CanCollide = oldValue
			collisionSnapshots[part] = nil
		end
	end
end

local function applyNoclipToCharacter()
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		setNoclipForPart(descendant)
	end
end

local function toggleNoclip()
	noclipEnabled = not noclipEnabled
	applyNoclipToCharacter()
	updateToggleStatus()
end

-- Flight platform
local function removePlatform()
	if platform then
		platform:Destroy()
		platform = nil
	end

	direction = 0
	ascendHeld = false
	descendHeld = false

	restoreJumping()
	updateToggleStatus()
	updatePanelLayout()
end

local function createPlatform()
	if not character or not rootPart or not humanoid then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	if platform then
		platform:Destroy()
		platform = nil
	end

	local rootY = rootPart.Position.Y
	local offset = PLATFORM_OFFSET

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		local boundingCFrame, boundingSize = character:GetBoundingBox()
		local bottomY = boundingCFrame.Position.Y - (boundingSize.Y / 2)
		local bottomOffset = bottomY - rootY

		offset = -bottomOffset + (PLATFORM_SIZE.Y / 2) + R15_CLEARANCE
	end

	rootToPlatformOffset = offset
	platformY = rootY - rootToPlatformOffset

	local newPlatform = Instance.new("Part")
	newPlatform.Name = "ClientFlightPlatform"
	newPlatform.Size = PLATFORM_SIZE
	newPlatform.Anchored = true
	newPlatform.CanCollide = true
	newPlatform.CanTouch = false
	newPlatform.CanQuery = false
	newPlatform.Material = Enum.Material.SmoothPlastic
	newPlatform.Color = Color3.fromRGB(255, 255, 255)
	newPlatform.Transparency = 0.5
	newPlatform.TopSurface = Enum.SurfaceType.Smooth
	newPlatform.BottomSurface = Enum.SurfaceType.Smooth
	newPlatform.CFrame = CFrame.new(
		rootPart.Position.X,
		platformY,
		rootPart.Position.Z
	)
	newPlatform.Parent = workspace

	platform = newPlatform

	disableJumping()
	updateToggleStatus()
	updatePanelLayout()
end

local function toggleFlight()
	flightEnabled = not flightEnabled

	if flightEnabled then
		createPlatform()
	else
		removePlatform()
	end

	updateToggleStatus()
end

-- Flight increment
applyIncrementButton.MouseButton1Click:Connect(function()
	local value = parseNonnegativeNumber(incrementBox.Text)

	if value == nil then
		incrementBox.Text = tostring(moveSpeed / FLIGHT_SPEED_MULTIPLIER)
		return
	end

	moveSpeed = value * FLIGHT_SPEED_MULTIPLIER
	incrementBox.Text = tostring(value)
end)

-- Player speed
applySpeedButton.MouseButton1Click:Connect(function()
	local value = parseNonnegativeNumber(speedBox.Text)

	if value == nil then
		if humanoid then
			speedBox.Text = tostring(humanoid.WalkSpeed)
		else
			speedBox.Text = tostring(playerSpeed)
		end
		return
	end

	playerSpeed = value
	speedBox.Text = tostring(value)

	if humanoid then
		humanoid.WalkSpeed = playerSpeed
	end
end)

-- Persist Speed toggle
persistButton.MouseButton1Click:Connect(function()
	speedPersistEnabled = not speedPersistEnabled
	updateToggleStatus()
end)

-- Keyboard controls
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- R toggles the GUI, even while it is hidden.
	if input.KeyCode == Enum.KeyCode.R then
		if not UserInputService:GetFocusedTextBox() then
			gui.Enabled = not gui.Enabled
		end
		return
	end

	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		toggleFlight()
	elseif input.KeyCode == Enum.KeyCode.X then
		toggleNoclip()
	elseif input.KeyCode == Enum.KeyCode.E then
		ascendHeld = true
		refreshDirection()
	elseif input.KeyCode == Enum.KeyCode.Q then
		descendHeld = true
		refreshDirection()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		ascendHeld = false
		refreshDirection()
	elseif input.KeyCode == Enum.KeyCode.Q then
		descendHeld = false
		refreshDirection()
	end
end)

-- Character setup / respawn
local function disconnectCharacterConnections()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end

	table.clear(characterConnections)
end

local function setupCharacter(newCharacter)
	disconnectCharacterConnections()

	removePlatform()

	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	playerSpeed = humanoid.WalkSpeed
	speedBox.Text = tostring(playerSpeed)

	table.insert(characterConnections, character.DescendantAdded:Connect(function(descendant)
		if noclipEnabled then
			task.defer(function()
				if descendant.Parent then
					setNoclipForPart(descendant)
				end
			end)
		end
	end))

	table.insert(characterConnections, humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
		if platform and humanoid.Jump then
			humanoid.Jump = false
		end
	end))

	table.insert(characterConnections, humanoid.StateChanged:Connect(function(_, newState)
		if platform and newState == Enum.HumanoidStateType.Jumping then
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end))

	if noclipEnabled then
		applyNoclipToCharacter()
	end

	if flightEnabled then
		createPlatform()
	else
		updatePanelLayout()
	end

	updateToggleStatus()
end

player.CharacterAdded:Connect(setupCharacter)

player.CharacterRemoving:Connect(function(oldCharacter)
	if oldCharacter == character then
		removePlatform()
		disconnectCharacterConnections()

		character = nil
		rootPart = nil
		humanoid = nil
	end
end)

if player.Character then
	task.spawn(setupCharacter, player.Character)
else
	updatePanelLayout()
end

-- Main update loop
RunService.Heartbeat:Connect(function(deltaTime)
	if character and humanoid and humanoid.Health > 0 then
		-- Enforce Persist Speed.
		if speedPersistEnabled and humanoid.WalkSpeed ~= playerSpeed then
			humanoid.WalkSpeed = playerSpeed
		end

		-- Enforce noclip on character parts.
		if noclipEnabled then
			for _, descendant in ipairs(character:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.CanCollide then
					if collisionSnapshots[descendant] == nil then
						collisionSnapshots[descendant] = true
					end

					descendant.CanCollide = false
				end
			end
		end
	end

	if not platform or not platform.Parent or not rootPart or not humanoid then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	-- Move the platform vertically and keep it under the character.
	platformY += direction * moveSpeed * deltaTime

	local rootPosition = rootPart.Position

	platform.Position = Vector3.new(
		rootPosition.X,
		platformY,
		rootPosition.Z
	)

	local targetRootY = platformY + rootToPlatformOffset
	local currentCFrame = rootPart.CFrame

	rootPart.CFrame =
		CFrame.new(rootPosition.X, targetRootY, rootPosition.Z)
		* currentCFrame.Rotation
end)

-- Initial state
updateToggleStatus()
updatePanelLayout()
