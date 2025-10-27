local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local cfg = {
	cps = 7,
	lineDuration = 3,
	spawnOffset = 2,
	textureId = "rbxassetid://1134824633",
	soundId = "rbxassetid://97643101798871",
	beamWidth = 6,
	lightEmission = 0.7,
	color = Color3.fromRGB(0, 255, 255),
	toggleKey = Enum.KeyCode.RightControl,
	fireBind = Enum.KeyCode.RightAlt,
	cursorBind = Enum.KeyCode.F10,
	detectHits = false,
	forceSound = false
}

local holding = false
local holdingFireBind = false
local lastShotTime = 0
local delayBetweenTracers = 1 / cfg.cps
local cursorUnlocked = false

local function getPlayerFromPart(part)
	if not part then return nil end
	local parent = part
	while parent and not parent:FindFirstChildOfClass("Humanoid") do
		parent = parent.Parent
	end
	if parent then return Players:GetPlayerFromCharacter(parent) end
	return nil
end

local function createTracer(startPos, endPos)
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	a0.WorldPosition = startPos
	a1.WorldPosition = endPos
	a0.Parent = Workspace.Terrain
	a1.Parent = Workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.Width0 = cfg.beamWidth
	beam.Width1 = cfg.beamWidth
	beam.Texture = cfg.textureId
	beam.TextureLength = 1
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.Color = ColorSequence.new(cfg.color)
	beam.LightEmission = math.clamp(cfg.lightEmission, 0, 10)
	beam.Parent = Workspace.Terrain
	delay(cfg.lineDuration, function()
		if beam then beam:Destroy() end
		if a0 then a0:Destroy() end
		if a1 then a1:Destroy() end
	end)
end

local function playHitSoundOnSelf(part)
	if cfg.forceSound then
		local char = player.Character
		if not char then return end
		local parentForSound = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or Workspace
		local sound = Instance.new("Sound")
		sound.SoundId = cfg.soundId
		sound.Volume = 1
		sound.PlayOnRemove = true
		sound.Parent = parentForSound
		sound:Destroy()
		return
	end
	local hitPlayer = getPlayerFromPart(part)
	if hitPlayer and hitPlayer ~= player then
		local char = player.Character
		if not char then return end
		local parentForSound = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or Workspace
		local sound = Instance.new("Sound")
		sound.SoundId = cfg.soundId
		sound.Volume = 1
		sound.PlayOnRemove = true
		sound.Parent = parentForSound
		sound:Destroy()
	end
end

local function shoot()
	local now = tick()
	if now - lastShotTime < delayBetweenTracers then return end
	local character = player.Character
	if not character or not character:FindFirstChild("Head") then return end
	local head = character.Head
	local startPos = head.Position + (head.CFrame.LookVector * cfg.spawnOffset)
	local targetPos = mouse.Hit.Position
	if cfg.detectHits then
		if not mouse.Target then
			print("Didnt Detect Hit")
			lastShotTime = now
			return
		end
		local hitPlayer = getPlayerFromPart(mouse.Target)
		if not hitPlayer then
			print("Didnt Detect Hit")
			lastShotTime = now
			return
		end
	end
	createTracer(startPos, targetPos)
	playHitSoundOnSelf(mouse.Target)
	lastShotTime = now
end

mouse.Button1Down:Connect(function() holding = true end)
mouse.Button1Up:Connect(function() holding = false end)

RunService.RenderStepped:Connect(function()
	if holding or holdingFireBind then shoot() end
end)

local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "TracerCustomizerGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = playerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 360, 0, 540)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔮 Tracer Customizer"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

local content = Instance.new("Frame", frame)
content.Position = UDim2.new(0, 10, 0, 46)
content.Size = UDim2.new(1, -20, 1, -56)
content.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeRow(labelText, defaultText, placeholder, onDone)
	local row = Instance.new("Frame", content)
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundTransparency = 1
	local label = Instance.new("TextLabel", row)
	label.Text = labelText
	label.Size = UDim2.new(0.45, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	local box = Instance.new("TextBox", row)
	box.Size = UDim2.new(0.55, 0, 1, 0)
	box.Position = UDim2.new(0.45, 6, 0, 0)
	box.Text = defaultText or ""
	box.PlaceholderText = placeholder or ""
	box.Font = Enum.Font.Code
	box.TextSize = 14
	box.TextColor3 = Color3.fromRGB(240, 240, 240)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	box.ClearTextOnFocus = false
	box.FocusLost:Connect(function()
		if onDone then onDone(box.Text) end
	end)
	return row, box
end

local _, soundBox = makeRow("🎵 Sound ID", tostring(cfg.soundId), "numeric id", function(txt)
	local id = txt:match("%d+")
	if id then cfg.soundId = "rbxassetid://" .. id end
end)

local _, textureBox = makeRow("🌌 Texture ID", tostring(cfg.textureId), "numeric id", function(txt)
	local id = txt:match("%d+")
	if id then cfg.textureId = "rbxassetid://" .. id end
end)

local _, widthBox = makeRow("📏 Beam Width", tostring(cfg.beamWidth), "0.1 - 50", function(txt)
	local num = tonumber(txt)
	if num then cfg.beamWidth = math.clamp(num, 0.1, 50) end
end)

local _, lightBox = makeRow("💡 Light Emission", tostring(cfg.lightEmission), "0 - 10", function(txt)
	local num = tonumber(txt)
	if num then cfg.lightEmission = math.clamp(num, 0, 10) end
end)

local _, cpsBox = makeRow("⚡ CPS", tostring(cfg.cps), "shots per second", function(txt)
	local num = tonumber(txt)
	if num and num > 0 then
		cfg.cps = math.max(0.1, num)
		delayBetweenTracers = 1 / cfg.cps
	end
end)

local _, durBox = makeRow("🕒 Line Duration", tostring(cfg.lineDuration), "seconds", function(txt)
	local num = tonumber(txt)
	if num and num > 0 then cfg.lineDuration = num end
end)

local detectRow = Instance.new("Frame", content)
detectRow.Size = UDim2.new(1, 0, 0, 30)
detectRow.BackgroundTransparency = 1
local detectLabel = Instance.new("TextLabel", detectRow)
detectLabel.Text = "🎯 Detect Hits"
detectLabel.Size = UDim2.new(0.7, 0, 1, 0)
detectLabel.BackgroundTransparency = 1
detectLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
detectLabel.Font = Enum.Font.Gotham
detectLabel.TextSize = 14
local detectBtn = Instance.new("TextButton", detectRow)
detectBtn.Size = UDim2.new(0.3, 0, 1, 0)
detectBtn.Position = UDim2.new(0.7, 0, 0, 0)
detectBtn.Text = cfg.detectHits and "ON" or "OFF"
detectBtn.Font = Enum.Font.Gotham
detectBtn.TextSize = 14
detectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
detectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
detectBtn.MouseButton1Click:Connect(function()
	cfg.detectHits = not cfg.detectHits
	detectBtn.Text = cfg.detectHits and "ON" or "OFF"
end)

local forceRow = Instance.new("Frame", content)
forceRow.Size = UDim2.new(1, 0, 0, 30)
forceRow.BackgroundTransparency = 1
local forceLabel = Instance.new("TextLabel", forceRow)
forceLabel.Text = "🎧 Force Sound"
forceLabel.Size = UDim2.new(0.7, 0, 1, 0)
forceLabel.BackgroundTransparency = 1
forceLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
forceLabel.Font = Enum.Font.Gotham
forceLabel.TextSize = 14
local forceBtn = Instance.new("TextButton", forceRow)
forceBtn.Size = UDim2
