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
    color = Color3.fromRGB(0,255,255),
    toggleKey = Enum.KeyCode.RightControl,
    fireBind = Enum.KeyCode.RightAlt,
    cursorBind = Enum.KeyCode.F10,
    detectHits = false,
    forceSound = false,
    appearOnPlayer = false,
    damageTracer = false
}

local holding = false
local holdingFireBind = false
local lastShotTime = 0
local delayBetweenTracers = 1/cfg.cps
local cursorUnlocked = false

-- GUI
local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "tracers"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = playerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,360,0,600)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,36)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "🔮 Tracer Customizer"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

local content = Instance.new("Frame", frame)
content.Position = UDim2.new(0,10,0,46)
content.Size = UDim2.new(1,-20,1,-56)
content.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0,6)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Helpers
local function getPlayerFromPart(part)
    if not part then return nil end
    local parent = part
    while parent and not parent:FindFirstChildOfClass("Humanoid") do
        parent = parent.Parent
    end
    if parent then return Players:GetPlayerFromCharacter(parent) end
    return nil
end

local function createTracer(startPos,endPos)
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
    beam.LightEmission = math.clamp(cfg.lightEmission,0,10)
    beam.Parent = Workspace.Terrain
    delay(cfg.lineDuration,function()
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

function AppearOnPlayerToClosest()
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
            local headPos = plr.Character.Head.Position
            local distance = (mouse.Hit.Position - headPos).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = plr
            end
        end
    end
    if closestPlayer and closestPlayer.Character then
        local character = player.Character
        if not character or not character:FindFirstChild("Head") then return end
        local startPos = character.Head.Position + (character.Head.CFrame.LookVector*cfg.spawnOffset)
        local endPos = closestPlayer.Character.Head.Position
        createTracer(startPos,endPos)
        playHitSoundOnSelf(closestPlayer.Character.Head)
    end
end

function SetAppearOffset(studs)
    cfg.spawnOffset = studs
end

function CheckIfDamagedClosestToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("Head") then
            local headPos = plr.Character.Head.Position
            local distance = (mouse.Hit.Position - headPos).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = plr
            end
        end
    end
    if closestPlayer and closestPlayer.Character then
        local humanoid = closestPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local lastHealth = humanoid.Health
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < lastHealth then
                local character = player.Character
                if not character or not character:FindFirstChild("Head") then return end
                local startPos = character.Head.Position + (character.Head.CFrame.LookVector*cfg.spawnOffset)
                local endPos = closestPlayer.Character.Head.Position
                createTracer(startPos,endPos)
                playHitSoundOnSelf(closestPlayer.Character.Head)
            end
            lastHealth = humanoid.Health
        end)
    end
end

-- GUI helpers
local function makeToggle(name, default, callback)
    local row = Instance.new("Frame", content)
    row.Size = UDim2.new(1,0,0,30)
    row.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", row)
    label.Text = name
    label.Size = UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0.3,0,1,0)
    btn.Position = UDim2.new(0.7,0,0,0)
    btn.Text = default and "ON" or "OFF"
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = default and "ON" or "OFF"
        callback(default)
    end)
end

local function makeTextBox(labelText, default, callback)
    local row = Instance.new("Frame", content)
    row.Size = UDim2.new(1,0,0,30)
    row.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", row)
    label.Text = labelText
    label.Size = UDim2.new(0.45,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.55,0,1,0)
    box.Position = UDim2.new(0.45,6,0,0)
    box.Text = tostring(default)
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.BackgroundColor3 = Color3.fromRGB(45,45,45)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.ClearTextOnFocus = false
    box.FocusLost:Connect(function()
        callback(box.Text)
    end)
end

local function makeKeyBind(labelText, currentKey, callback)
    local row = Instance.new("Frame", content)
    row.Size = UDim2.new(1,0,0,30)
    row.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", row)
    label.Text = labelText
    label.Size = UDim2.new(0.45,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14

    local box = Instance.new("TextButton", row)
    box.Size = UDim2.new(0.55,0,1,0)
    box.Position = UDim2.new(0.45,6,0,0)
    box.Text = currentKey.Name
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.BackgroundColor3 = Color3.fromRGB(45,45,45)
    box.TextColor3 = Color3.fromRGB(255,255,255)

    local waitingForInput = false
    box.MouseButton1Click:Connect(function()
        box.Text = "Press any key..."
        waitingForInput = true
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if waitingForInput and input.UserInputType == Enum.UserInputType.Keyboard then
            waitingForInput = false
            callback(input.KeyCode)
            box.Text = input.KeyCode.Name
        end
    end)
end

-- GUI elements
makeToggle("Detect Hits", cfg.detectHits, function(v) cfg.detectHits=v end)
makeToggle("Force Sound", cfg.forceSound, function(v) cfg.forceSound=v end)
makeToggle("Appear On Player", cfg.appearOnPlayer, function(v) cfg.appearOnPlayer=v end)
makeToggle("Damage Tracer", cfg.damageTracer, function(v)
    cfg.damageTracer=v
    if v then CheckIfDamagedClosestToMouse() end
end)

makeTextBox("Texture ID", cfg.textureId, function(v) cfg.textureId=v end)
makeTextBox("Sound ID", cfg.soundId, function(v) cfg.soundId=v end)
makeTextBox("Beam Width", cfg.beamWidth, function(v) cfg.beamWidth=tonumber(v) or cfg.beamWidth end)
makeTextBox("Light Emission", cfg.lightEmission, function(v) cfg.lightEmission=tonumber(v) or cfg.lightEmission end)
makeTextBox("Line Duration", cfg.lineDuration, function(v) cfg.lineDuration=tonumber(v) or cfg.lineDuration end)
makeTextBox("CPS", cfg.cps, function(v) cfg.cps=tonumber(v) or cfg.cps delayBetweenTracers=1/cfg.cps end)
makeTextBox("Spawn Offset", cfg.spawnOffset, function(v) cfg.spawnOffset=tonumber(v) or cfg.spawnOffset end)
makeKeyBind("Menu Keybind", cfg.toggleKey, function(k) cfg.toggleKey=k end)
makeKeyBind("Fire Keybind", cfg.fireBind, function(k) cfg.fireBind=k end)
makeKeyBind("Cursor Unlock", cfg.cursorBind, function(k) cfg.cursorBind=k end)

-- Shooting
local function shoot()
    local now = tick()
    if now - lastShotTime < delayBetweenTracers then return end
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return end
    local head = character.Head
    if cfg.appearOnPlayer then
        AppearOnPlayerToClosest()
    else
        local targetPos = mouse.Hit.Position
        if cfg.detectHits then
            if mouse.Target then
                local hitPlayer = getPlayerFromPart(mouse.Target)
                if not hitPlayer then print("Didnt Detect Hit") lastShotTime=now return end
            else
                print("Didnt Detect Hit") lastShotTime=now return
            end
        end
        createTracer(head.Position + (head.CFrame.LookVector*cfg.spawnOffset), targetPos)
        playHitSoundOnSelf(mouse.Target)
    end
    lastShotTime = now
end

mouse.Button1Down:Connect(function() holding=true end)
mouse.Button1Up:Connect(function() holding=false end)
RunService.RenderStepped:Connect(function()
    if holding or holdingFireBind then shoot() end
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.UserInputType==Enum.UserInputType.Keyboard then
        if input.KeyCode==cfg.toggleKey then
            gui.Enabled = not gui.Enabled
        elseif input.KeyCode==cfg.fireBind then
            holdingFireBind = not holdingFireBind
        elseif input.KeyCode==cfg.cursorBind then
            cursorUnlocked = not cursorUnlocked
            if cursorUnlocked then
                UserInputService.MouseBehavior=Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled=true
            else
                UserInputService.MouseBehavior=Enum.MouseBehavior.LockCenter
                UserInputService.MouseIconEnabled=false
            end
        end
    end
end)

if cfg.damageTracer then
    CheckIfDamagedClosestToMouse()
end
