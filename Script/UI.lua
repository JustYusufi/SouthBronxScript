-- Place this LocalScript inside StarterPlayer.StarterPlayerScripts
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local charactersFolder = Workspace:WaitForChild("Characters")

-- State variables
local scriptActive = true
local visualsEnabled = true
local environmentCollisionEnabled = true
local autoLockToggled = true
local rmbHeld = false
local tpWalkEnabled = false
local tpWalkMultiplier = 2
local fovRadius = 150

local originalCollisions = {}

------------------------------------------------------------------
-- UI Construction (Draggable Window, Animation, Tabs, Console)
------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomMenuGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Main Window Frame
local mainFrame = Instance.new("TextButton")
mainFrame.Name = "MainWindow"
mainFrame.Size = UDim2.new(0, 450, 0, 320)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.AutoButtonColor = false
mainFrame.Text = ""
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- Opening Animation (Scale up and fade in)
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundTransparency = 1
local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 450, 0, 320),
	BackgroundTransparency = 0
})
openTween:Play()

-- Logo Image Label (Displays your image when minimized)
local logoIcon = Instance.new("ImageLabel")
logoIcon.Name = "LogoIcon"
logoIcon.Size = UDim2.new(1, 0, 1, 0)
logoIcon.BackgroundTransparency = 1
logoIcon.ScaleType = Enum.ScaleType.Fit
logoIcon.Image = "rbxassetid://81525636953612" 
logoIcon.Visible = false
logoIcon.Parent = mainFrame

-- Top Bar (Draggable & Minimize Button)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Custom Menu | Controls & Commands"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.Parent = topBar

-- Minimize / Expand Icon Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -32, 0, 2)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

-- Tab System Setup containers
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0, 30)
tabContainer.Position = UDim2.new(0, 0, 0, 35)
tabContainer.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -65)
contentContainer.Position = UDim2.new(0, 0, 0, 65)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

------------------------------------------------------------------
-- Universal Draggable & Minimize Logic
------------------------------------------------------------------
local isMinimized = false
local dragging, dragInput, dragStart, startPos
local dragDistance = 0

local function startDragging(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		dragDistance = 0
		
		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				connection:Disconnect()
			end
		end)
	end
end

topBar.InputBegan:Connect(startDragging)
mainFrame.InputBegan:Connect(function(input)
	if isMinimized then
		startDragging(input)
	end
end)

topBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		dragDistance = delta.Magnitude
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local function toggleMinimize()
	isMinimized = not isMinimized
	if isMinimized then
		topBar.Visible = false
		tabContainer.Visible = false
		contentContainer.Visible = false
		logoIcon.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 50, 0, 50)
		}):Play()
	else
		logoIcon.Visible = false
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 450, 0, 320)
		}):Play()
		task.wait(0.15)
		topBar.Visible = true
		tabContainer.Visible = true
		contentContainer.Visible = true
	end
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

mainFrame.MouseButton1Click:Connect(function()
	if isMinimized and dragDistance < 5 then
		toggleMinimize()
	end
end)

-- Create Tabs (Settings, Keybinds, Commands)
local tabs = {"Settings", "Keybinds", "Commands"}
local tabFrames = {}

for i, tabName in ipairs(tabs) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1 / #tabs, 0, 1, 0)
	btn.Position = UDim2.new((i - 1) / #tabs, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.Text = tabName
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.Parent = tabContainer

	local frame = Instance.new("ScrollingFrame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = (i == 1)
	frame.CanvasSize = UDim2.new(0, 0, 0, 0)
	frame.Parent = contentContainer
	tabFrames[tabName] = frame

	btn.MouseButton1Click:Connect(function()
		for _, f in pairs(tabFrames) do f.Visible = false end
		frame.Visible = true
	end)
end

------------------------------------------------------------------
-- TAB 1: Settings
------------------------------------------------------------------
local settingsFrame = tabFrames["Settings"]

local function createSettingLabel(text, yPos)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 200, 0, 30)
	lbl.Position = UDim2.new(0, 15, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 15
	lbl.Parent = settingsFrame
	return lbl
end

createSettingLabel("TpWalk Speed Multiplier:", 15)
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 100, 0, 30)
speedBox.Position = UDim2.new(0, 230, 0, 15)
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Text = tostring(tpWalkMultiplier)
speedBox.Font = Enum.Font.SourceSansBold
speedBox.TextSize = 14
speedBox.Parent = settingsFrame

speedBox.FocusLost:Connect(function()
	local val = tonumber(speedBox.Text)
	if val then tpWalkMultiplier = math.clamp(val, 1, 10) else speedBox.Text = tostring(tpWalkMultiplier) end
end)

createSettingLabel("Auto-Lock FOV Radius:", 60)
local fovBox = Instance.new("TextBox")
fovBox.Size = UDim2.new(0, 100, 0, 30)
fovBox.Position = UDim2.new(0, 230, 0, 60)
fovBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
fovBox.TextColor3 = Color3.fromRGB(255, 255, 255)
fovBox.Text = tostring(fovRadius)
fovBox.Font = Enum.Font.SourceSansBold
fovBox.TextSize = 14
fovBox.Parent = settingsFrame

fovBox.FocusLost:Connect(function()
	local val = tonumber(fovBox.Text)
	if val then fovRadius = math.clamp(val, 50, 400) else fovBox.Text = tostring(fovRadius) end
end)

------------------------------------------------------------------
-- TAB 2: Keybinds Info
------------------------------------------------------------------
local keybindsFrame = tabFrames["Keybinds"]
local keybindInfo = Instance.new("TextLabel")
keybindInfo.Size = UDim2.new(1, -30, 1, -20)
keybindInfo.Position = UDim2.new(0, 15, 0, 10)
keybindInfo.BackgroundTransparency = 1
keybindInfo.Text = "• [P] : Toggle ESP & Name/Health Tags\n• [Z] : Toggle Environment Noclip (Walls/Props)\n• [  ]  ] : Toggle Auto-Lock System & FOV Circle\n• [RMB] : Hold to Auto-Lock nearest head in FOV\n• [ , ] : Toggle TpWalk Speed Boost"
keybindInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
keybindInfo.TextXAlignment = Enum.TextXAlignment.Left
keybindInfo.TextYAlignment = Enum.TextYAlignment.Top
keybindInfo.Font = Enum.Font.SourceSans
keybindInfo.TextSize = 15
keybindInfo.Parent = keybindsFrame

------------------------------------------------------------------
-- TAB 3: Commands Console
------------------------------------------------------------------
local commandsFrame = tabFrames["Commands"]

local cmdOutput = Instance.new("TextLabel")
cmdOutput.Size = UDim2.new(1, -30, 0, 150)
cmdOutput.Position = UDim2.new(0, 15, 0, 10)
cmdOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
cmdOutput.TextColor3 = Color3.fromRGB(0, 255, 128)
cmdOutput.Text = "System Console Ready.\nCommands: 'spawn', 'spawnpoint', 'reset', 'leave', 'exit'"
cmdOutput.TextXAlignment = Enum.TextXAlignment.Left
cmdOutput.TextYAlignment = Enum.TextYAlignment.Top
cmdOutput.TextWrapped = true
cmdOutput.Font = Enum.Font.Code
cmdOutput.TextSize = 13
cmdOutput.Parent = commandsFrame

local cmdInput = Instance.new("TextBox")
cmdInput.Size = UDim2.new(1, -30, 0, 35)
cmdInput.Position = UDim2.new(0, 15, 0, 175)
cmdInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
cmdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
cmdInput.PlaceholderText = "Type command here..."
cmdInput.Text = ""
cmdInput.Font = Enum.Font.Code
cmdInput.TextSize = 14
cmdInput.Parent = commandsFrame

cmdInput.FocusLost:Connect(function(enterPressed)
	if not enterPressed or not scriptActive then return end
	local text = cmdInput.Text:lower():gsub("%s+", "")
	cmdInput.Text = ""
	
	if text == "spawn" or text == "spawnpoint" then
		local char = localPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local root = char.HumanoidRootPart
			local spawn = Workspace:FindFirstChild("CustomSpawnPoint")
			if not spawn then
				spawn = Instance.new("SpawnLocation")
				spawn.Name = "CustomSpawnPoint"
				spawn.Size = Vector3.new(6, 1, 6)
				spawn.Anchored = true
				spawn.Transparency = 1
				spawn.CanCollide = false
				spawn.Parent = Workspace
			end
			spawn.CFrame = root.CFrame - Vector3.new(0, 3, 0)
			localPlayer.RespawnLocation = spawn
			cmdOutput.Text = cmdOutput.Text .. "\n> " .. text .. " executed: Spawnpoint set."
		else
			cmdOutput.Text = cmdOutput.Text .. "\n> Error: Character not found."
		end
	elseif text == "reset" then
		local char = localPlayer.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
				cmdOutput.Text = cmdOutput.Text .. "\n> reset executed: Character reset."
			end
		end
	elseif text == "leave" then
		cmdOutput.Text = cmdOutput.Text .. "\n> leave executed: Exiting experience..."
		localPlayer:Kick("Left the experience via console command.")
	elseif text == "exit" then
		scriptActive = false
		screenGui:Destroy()
		-- Restore environment collisions back to original state
		for part, state in pairs(originalCollisions) do
			if part and part.Parent then
				part.CanCollide = state
			end
		end
		-- Remove highlights and tags from characters
		for _, child in ipairs(charactersFolder:GetChildren()) do
			if child:IsA("Model") then
				local hl = child:FindFirstChild("CharacterHighlightBox")
				if hl then hl:Destroy() end
				local tag = child:FindFirstChild("CharacterNameTag")
				if tag then tag:Destroy() end
			end
		end
		print("[Script Terminated via Exit Command]")
	else
		cmdOutput.Text = cmdOutput.Text .. "\n> Unknown command: " .. text
	end
end)

------------------------------------------------------------------
-- FOV Circle UI Element
------------------------------------------------------------------
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
fovCircle.BackgroundTransparency = 0.9
fovCircle.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
fovCircle.Visible = autoLockToggled
fovCircle.Parent = screenGui

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 255, 128)
uiStroke.Thickness = 2
uiStroke.Parent = fovCircle

local uiCornerCircle = Instance.new("UICorner")
uiCornerCircle.CornerRadius = UDim.new(1, 0)
uiCornerCircle.Parent = fovCircle

------------------------------------------------------------------
-- Character Setup (ESP & Name/Health Tags)
------------------------------------------------------------------
local function setupCharacter(model: Model)
	if not scriptActive or model:FindFirstChild("CharacterHighlightBox") then return end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "CharacterHighlightBox"
	highlight.Adornee = model
	highlight.Enabled = visualsEnabled
	highlight.FillColor = Color3.fromRGB(0, 255, 128)
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(0, 255, 128)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = model

	local targetPart = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if targetPart then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "CharacterNameTag"
		billboard.Adornee = targetPart
		billboard.Size = UDim2.new(0, 250, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Enabled = visualsEnabled
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.TextStrokeTransparency = 0
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextSize = 20
		nameLabel.Parent = billboard

		billboard.Parent = model

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local function updateText()
			if humanoid then
				nameLabel.Text = string.format("%s | %d", model.Name, math.floor(humanoid.Health + 0.5))
			else
				nameLabel.Text = model.Name
			end
		end
		updateText()
		if humanoid then
			humanoid:GetPropertyChangedSignal("Health"):Connect(updateText)
		end
	end
end

------------------------------------------------------------------
-- Keybinds & Frame Update Logic
------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not scriptActive or gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.P then
		visualsEnabled = not visualsEnabled
		for _, child in ipairs(charactersFolder:GetChildren()) do
			if child:IsA("Model") then
				if child:FindFirstChild("CharacterHighlightBox") then child.CharacterHighlightBox.Enabled = visualsEnabled end
				if child:FindFirstChild("CharacterNameTag") then child.CharacterNameTag.Enabled = visualsEnabled end
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Z then
		environmentCollisionEnabled = not environmentCollisionEnabled
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("BasePart") and not desc:IsDescendantOf(charactersFolder) and desc.Name ~= "HumanoidRootPart" then
				local nameLower = desc.Name:lower()
				local isFl = nameLower:find("floor") or nameLower:find("ground") or nameLower:find("terrain") or nameLower:find("baseplate") or (math.abs(desc.CFrame.UpVector.Y) > 0.95 and desc.Size.Y <= 6)
				if not isFl then
					if not environmentCollisionEnabled then
						if originalCollisions[desc] == nil then originalCollisions[desc] = desc.CanCollide end
						desc.CanCollide = false
					else
						desc.CanCollide = originalCollisions[desc] ~= nil and originalCollisions[desc] or true
					end
				end
			end
		end
	elseif input.KeyCode == Enum.KeyCode.LeftBracket then
		autoLockToggled = not autoLockToggled
		fovCircle.Visible = autoLockToggled
		if not autoLockToggled then rmbHeld = false end
	elseif input.KeyCode == Enum.KeyCode.Comma then
		tpWalkEnabled = not tpWalkEnabled
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 and autoLockToggled then
		rmbHeld = true
		uiStroke.Color = Color3.fromRGB(255, 0, 0)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not scriptActive then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rmbHeld = false
		uiStroke.Color = Color3.fromRGB(0, 255, 128)
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if not scriptActive then return end
	
	local mousePos = UserInputService:GetMouseLocation()
	fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
	fovCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	
	-- Safe TpWalk
	if tpWalkEnabled then
		local char = localPlayer.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then
				local stepSize = math.min(humanoid.WalkSpeed * (tpWalkMultiplier - 1) * deltaTime, 1.5)
				rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection.Unit * stepSize)
			end
		end
	end
	
	-- Auto-Lock Targeting
	if not autoLockToggled or not rmbHeld then return end
	local closestTargetHead = nil
	local shortestDistance = fovRadius
	
	for _, child in ipairs(charactersFolder:GetChildren()) do
		if child:IsA("Model") and child ~= localPlayer.Character then
			local head = child:FindFirstChild("Head") or child.PrimaryPart
			if head then
				local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
					if dist < shortestDistance then
						shortestDistance = dist
						closestTargetHead = head
					end
				end
			end
		end
	end
	
	if closestTargetHead then
		camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, closestTargetHead.Position), 0.3)
	end
end)

-- Initialize current and future characters
for _, child in ipairs(charactersFolder:GetChildren()) do
	if child:IsA("Model") then setupCharacter(child) end
end
charactersFolder.ChildAdded:Connect(function(child)
	if scriptActive and child:IsA("Model") then setupCharacter(child) end
end)