--[[
      ╷ ╷╷ ╷╭─╮╷ ╷╭─╴╷            
      ╰┬╯│ │╰─╮│ │├╴ │            
       ╵ ╰─╯╰─╯╰─╯╵  ╵            
╭─╴╷╶┬╴╭─╮╭─╮   ╭─╴╭─╮╭╮╷╭─╴      
│  │ │ │ │╰─╮   │╶╮├─┤│╰┤│╶╮      
╰─╴╵ ╵ ╰─╯╰─╯   ╰─╯╵ ╵╵ ╵╰─╯      
--]]    

-- Place this LocalScript inside StarterPlayer.StarterPlayerScripts
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local charactersFolder = Workspace:WaitForChild("Characters")

-- State variables
local visualsEnabled = true
local environmentCollisionEnabled = true
local autoLockToggled = true -- Master switch controlled by "[" key
local rmbHeld = false        -- Tracks Right Mouse Button state
local tpWalkEnabled = false  -- Toggle for tpwalk (controlled by "," key)
local TPWALK_MULTIPLIER = 2  -- Speed multiplier (2x faster)
local FOV_RADIUS = 150       -- Pixel radius around the cursor for auto-lock detection

-- Table to remember original collision states
local originalCollisions = {}

------------------------------------------------------------------
-- UI Setup: Create FOV Circle on Mouse Cursor
------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoLockGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- Ensures accurate mouse alignment
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Size = UDim2.new(0, FOV_RADIUS * 2, 0, FOV_RADIUS * 2)
fovCircle.BackgroundTransparency = 0.9 -- Slight tint so you can see the circle area
fovCircle.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
fovCircle.Visible = autoLockToggled

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 255, 128)
uiStroke.Thickness = 2
uiStroke.Parent = fovCircle

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = fovCircle

fovCircle.Parent = screenGui

------------------------------------------------------------------
-- Character Setup (Highlights & Name Tags)
------------------------------------------------------------------
local function setupCharacter(model: Model)
	if model:FindFirstChild("CharacterHighlightBox") then
		return
	end
	
	-- 1. Create Highlight Box
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

	-- 2. Create Text Above Character
	local targetPart = model:FindFirstChild("Head") 
		or model.PrimaryPart 
		or model:FindFirstChildWhichIsA("BasePart")

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
				local currentHealth = math.floor(humanoid.Health + 0.5)
				nameLabel.Text = string.format("%s | %d", model.Name, currentHealth)
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
-- Toggles (P, Z, [, and , keys)
------------------------------------------------------------------
local function toggleVisuals()
	visualsEnabled = not visualsEnabled
	
	for _, child in ipairs(charactersFolder:GetChildren()) do
		if child:IsA("Model") then
			local highlight = child:FindFirstChild("CharacterHighlightBox")
			if highlight then highlight.Enabled = visualsEnabled end
			
			local billboard = child:FindFirstChild("CharacterNameTag")
			if billboard then billboard.Enabled = visualsEnabled end
		end
	end
end

local function isFloor(part: BasePart)
	local nameLower = part.Name:lower()
	if nameLower:find("floor") or nameLower:find("ground") or nameLower:find("terrain") or nameLower:find("baseplate") then
		return true
	end
	local upVector = part.CFrame.UpVector
	if math.abs(upVector.Y) > 0.95 and part.Size.Y <= 6 then
		return true
	end
	return false
end

local function toggleEnvironmentCollision()
	environmentCollisionEnabled = not environmentCollisionEnabled
	
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("BasePart") then
			if not desc:IsDescendantOf(charactersFolder) and desc.Name ~= "HumanoidRootPart" then
				if isFloor(desc) then continue end
				
				if not environmentCollisionEnabled then
					if originalCollisions[desc] == nil then
						originalCollisions[desc] = desc.CanCollide
					end
					desc.CanCollide = false
				else
					if originalCollisions[desc] ~= nil then
						desc.CanCollide = originalCollisions[desc]
					else
						desc.CanCollide = true
					end
				end
			end
		end
	end
end

local function toggleAutoLockSystem()
	autoLockToggled = not autoLockToggled
	fovCircle.Visible = autoLockToggled
	if not autoLockToggled then
		rmbHeld = false
		uiStroke.Color = Color3.fromRGB(0, 255, 128)
	end
end

local function toggleTpWalk()
	tpWalkEnabled = not tpWalkEnabled
end

------------------------------------------------------------------
-- Input Management (P, Z, [, ,, and RMB)
------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	
	if input.KeyCode == Enum.KeyCode.P then
		toggleVisuals()
	elseif input.KeyCode == Enum.KeyCode.Z then
		toggleEnvironmentCollision()
	elseif input.KeyCode == Enum.KeyCode.LeftBracket then -- "[" Key toggle
		toggleAutoLockSystem()
	elseif input.KeyCode == Enum.KeyCode.Comma then -- "," Key toggle for tpwalk
		toggleTpWalk()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 and autoLockToggled then
		rmbHeld = true
		uiStroke.Color = Color3.fromRGB(255, 0, 0) -- Turns red when locked on via RMB
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rmbHeld = false
		if autoLockToggled then
			uiStroke.Color = Color3.fromRGB(0, 255, 128) -- Back to green when RMB is released
		end
	end
end)

------------------------------------------------------------------
-- Frame Update Loop (Auto-Lock & TpWalk)
------------------------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
	local mousePos = UserInputService:GetMouseLocation()
	fovCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	
	-- 1. Handle TpWalk Movement
	if tpWalkEnabled then
		local char = localPlayer.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			
			if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then
				-- Micro-teleport position forward based on movement direction and normal walkspeed
				local moveDir = humanoid.MoveDirection.Unit
				local speed = humanoid.WalkSpeed
				rootPart.CFrame = rootPart.CFrame + (moveDir * speed * (TPWALK_MULTIPLIER - 1) * deltaTime)
			end
		end
	end
	
	-- 2. Handle Auto-Lock System
	if not autoLockToggled or not rmbHeld then return end
	
	local closestTargetHead = nil
	local shortestDistance = FOV_RADIUS
	
	for _, child in ipairs(charactersFolder:GetChildren()) do
		if child:IsA("Model") and child ~= localPlayer.Character then
			local head = child:FindFirstChild("Head") or child.PrimaryPart
			if head then
				local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
					local distance = (screenPos - mousePos).Magnitude
					
					if distance < shortestDistance then
						shortestDistance = distance
						closestTargetHead = head
					end
				end
			end
		end
	end
	
	if closestTargetHead then
		local currentCamCFrame = camera.CFrame
		local targetCFrame = CFrame.new(currentCamCFrame.Position, closestTargetHead.Position)
		camera.CFrame = currentCamCFrame:Lerp(targetCFrame, 0.3)
	end
end)

-- Apply initial scripts to current and future characters
for _, child in ipairs(charactersFolder:GetChildren()) do
	if child:IsA("Model") then
		setupCharacter(child)
	end
end

charactersFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		setupCharacter(child)
	end
end)
