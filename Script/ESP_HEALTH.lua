-- Place this LocalScript inside StarterPlayer.StarterPlayerScripts
local Workspace = game:GetService("Workspace")

-- Access the existing Characters folder in the Workspace
local charactersFolder = Workspace:WaitForChild("Characters")

local function createBoundingBoxAndNameTag(model: Model)
	-- Avoid creating duplicates if the script runs more than once
	if model:FindFirstChild("CharacterHighlightBox") then
		return
	end
	
	------------------------------------------------------------------
	-- 1. Create Highlight Box (Visible through walls)
	------------------------------------------------------------------
	local highlight = Instance.new("Highlight")
	highlight.Name = "CharacterHighlightBox"
	highlight.Adornee = model
	
	highlight.FillColor = Color3.fromRGB(0, 255, 128)
	highlight.FillTransparency = 1 -- Transparent interior
	highlight.OutlineColor = Color3.fromRGB(0, 255, 128)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visible through geometry
	
	highlight.Parent = model

	------------------------------------------------------------------
	-- 2. Create Text Above Character (Name | Health Number)
	------------------------------------------------------------------
	local targetPart = model:FindFirstChild("Head") 
		or model.PrimaryPart 
		or model:FindFirstChildWhichIsA("BasePart")

	if targetPart then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "CharacterNameTag"
		billboard.Adornee = targetPart
		billboard.Size = UDim2.new(0, 250, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0) -- Height above the part
		billboard.AlwaysOnTop = true -- Renders through walls
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.TextStrokeTransparency = 0 -- Black outline for readability
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextSize = 20
		nameLabel.Parent = billboard

		billboard.Parent = model

		-- Locate the Humanoid instance
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		
		local function updateText()
			if humanoid then
				local currentHealth = math.floor(humanoid.Health + 0.5)
				nameLabel.Text = string.format("%s | %d", model.Name, currentHealth)
			else
				nameLabel.Text = model.Name
			end
		end

		-- Initial text setup
		updateText()

		-- Listen for live health changes using GetPropertyChangedSignal
		if humanoid then
			humanoid:GetPropertyChangedSignal("Health"):Connect(updateText)
		end
	end
end

-- Apply to characters already in the folder
for _, child in ipairs(charactersFolder:GetChildren()) do
	if child:IsA("Model") then
		createBoundingBoxAndNameTag(child)
	end
end

-- Apply to any characters added to the folder dynamically later
charactersFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		createBoundingBoxAndNameTag(child)
	end
end)
