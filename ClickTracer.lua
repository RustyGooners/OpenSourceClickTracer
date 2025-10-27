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
	toggleKey = Enum.KeyCode.M,
	fireBind = Enum.KeyCode.LeftControl,
	cursorBind = Enum.KeyCode.RightControl,
	detectHits = false,
	forceSound = false
}

local holding = false
local holdingFireBind = false
local cursorUnlocked = false
local lastShotTime = 0
local delayBetweenTracers = 1 / cfg.cps

local function getPlayerFromPart(part)
	if not part then return nil end
	local parent = part
	while parent and not parent:FindFirstChildOfClass("Humanoid") do
		parent = parent.Parent
	end
	if parent then
		return Players:GetPlayerFromCharacter(parent)
	end
	return nil
end

local function createTracer(startPos, endPos)
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	a0.WorldPosition, a1.WorldPosition = startPos, endPos
	a0.Parent, a1.Parent = Workspace.Terrain, Workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.FaceCamera = true
	beam.Width0, beam.Width1 = cfg.beamWidth, cfg.beamWidth
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
	local hitPlayer = getPlayerFromPart(part)
	if cfg.forceSound or (hitPlayer and hitPlayer ~= player) then
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
			return
		end
		local hitPlayer = getPlayerFromPart(mouse.Target)
		if not hitPlayer then
			print("Didnt Detect Hit")
			return
		end
	end
	createTracer(startPos, targetPos)
	if mouse.Target then playHitSoundOnSelf(mouse.Target) end
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
frame.Size = UDim2.new(0, 360, 0, 520)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active, frame.Draggable = true, true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Tracer Customizer"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 24

local function makeButton(name, y, func)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1, -20, 0, 30)
	b.Position = UDim2.new(0, 10, 0, y)
	b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = name
	b.Font = Enum.Font.SourceSans
	b.TextSize = 20
	b.MouseButton1Click:Connect(func)
end

makeButton("Toggle Detect Hits", 60, function() cfg.detectHits = not cfg.detectHits end)
makeButton("Toggle Force Sound", 100, function() cfg.forceSound = not cfg.forceSound end)
makeButton("Unlock Cursor ("..cfg.cursorBind.Name..")", 140, function()
	cursorUnlocked = not cursorUnlocked
	UserInputService.MouseIconEnabled = cursorUnlocked
end)
makeButton("Close Menu ("..cfg.toggleKey.Name..")", 180, function() gui.Enabled = not gui.Enabled end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == cfg.fireBind then holdingFireBind = true end
	if input.KeyCode == cfg.toggleKey then gui.Enabled = not gui.Enabled end
	if input.KeyCode == cfg.cursorBind then
		cursorUnlocked = not cursorUnlocked
		UserInputService.MouseIconEnabled = cursorUnlocked
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == cfg.fireBind then holdingFireBind = false end
end)
