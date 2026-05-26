-- ==========================================
-- SINGLETON GUARD
-- ==========================================
if _G.AWMM2_Cleanup then
    pcall(_G.AWMM2_Cleanup)
    task.wait(0.15)
end
-- ==========================================
-- SERVICES
-- ==========================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")
local camera      = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local mouse       = localPlayer:GetMouse()
-- ==========================================
-- TRACK EXISTING GUIS TO FIND FLUENT
-- ==========================================
local preExistingGuis = {}
local function scanForGuis(container)
    if not container then return end
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("ScreenGui") then
            preExistingGuis[child] = true
        end
    end
end
scanForGuis(CoreGui)
if localPlayer:FindFirstChildOfClass("PlayerGui") then
    scanForGuis(localPlayer:FindFirstChildOfClass("PlayerGui"))
end
if gethui then
    pcall(function() scanForGuis(gethui()) end)
end
-- ==========================================
-- FLUENT UI
-- ==========================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title       = "A&W's MM2 HUB",
    SubTitle    = "Credit: aimxxz",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 500),
    Acrylic     = false,
    Theme       = "Sage",
    Minimizable = true
})
local fluentGui = nil
local function getNewGui(container)
    if not container then return nil end
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("ScreenGui") and not preExistingGuis[child] then
            return child
        end
    end
    return nil
end
fluentGui = getNewGui(CoreGui)
if not fluentGui and localPlayer:FindFirstChildOfClass("PlayerGui") then
    fluentGui = getNewGui(localPlayer:FindFirstChildOfClass("PlayerGui"))
end
if not fluentGui and gethui then
    local s, res = pcall(gethui)
    if s and res then fluentGui = getNewGui(res) end
end
-- Minimize placeholder setup
local minimizePlaceholder = Instance.new("ScreenGui")
minimizePlaceholder.Name = "MM2_MinimizePlaceholder"
minimizePlaceholder.ResetOnSpawn = false
minimizePlaceholder.Parent = CoreGui
local minimizeBox = Instance.new("Frame")
minimizeBox.Name = "Box"
minimizeBox.Size = UDim2.new(0, 30, 0, 100)
minimizeBox.Position = UDim2.new(1, -35, 0.5, -50)
minimizeBox.BackgroundColor3 = Color3.fromRGB(224, 90, 60) -- Calm orange-red
minimizeBox.BorderSizePixel = 0
minimizeBox.Visible = false
minimizeBox.Parent = minimizePlaceholder
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenBtn"
openBtn.Size = UDim2.new(1,0,1,0)
openBtn.BackgroundTransparency = 0.2
openBtn.Text = "▸"
openBtn.TextScaled = true
openBtn.Parent = minimizeBox
local function hideGui()
    if fluentGui then
        fluentGui.Enabled = false
        minimizeBox.Visible = true
    end
end
openBtn.MouseButton1Click:Connect(function()
    -- toggleUI is defined later; directly restore here and sync the flag
    if fluentGui then
        fluentGui.Enabled = true
        minimizeBox.Visible = false
    end
    -- The isMinimized flag is set later in the script; we access it via _G for the click handler
    _G._AWMM2_Minimized = false
end)
-- Listen for Fluent minimize (if supported)
if Window.MinimizedChanged then
    Window.MinimizedChanged:Connect(function(isMinimized)
        if isMinimized then
            hideGui()
        else
            if not fluentGui.Enabled then
                fluentGui.Enabled = true
                minimizeBox.Visible = false
            end
        end
    end)
end
local Tabs = {
    ESP      = Window:AddTab({ Title = "ESP",             Icon = "eye"        }),
    LOCK     = Window:AddTab({ Title = "Combat",          Icon = "crosshair"  }),
    FLING    = Window:AddTab({ Title = "Fling",           Icon = "zap"        }),
    ROLLBACK = Window:AddTab({ Title = "Rollback(Undone)", Icon = "refresh-cw" }),
    MISC     = Window:AddTab({ Title = "Misc",            Icon = "settings"   })
}
-- ==========================================
-- RANDOM IDs
-- ==========================================
local GUN_ESP_ID      = "G_" .. tostring(math.random(10000, 99999))
local PLAYER_ESP_ID   = "P_" .. tostring(math.random(10000, 99999))
local COIN_ESP_ID     = "C_" .. tostring(math.random(10000, 99999))
local USERNAME_ESP_ID = "U_" .. tostring(math.random(10000, 99999))
-- ==========================================
-- STATE FLAGS
-- ==========================================
local gunDropESP_Enabled  = false
local playerESP_Enabled   = false
local coinESP_Enabled     = false
local usernameESP_Enabled = false
local silentAim_Enabled   = false
local aimbot_Enabled      = false
local noclipEnabled       = false
local antiAfkEnabled      = false
local antiAfkConn         = nil
-- ==========================================
-- CONNECTION REGISTRY
-- ==========================================
local _connections = {}
local function track(conn)
    table.insert(_connections, conn)
    return conn
end
-- ==========================================
-- GUN DROP ESP
-- ==========================================
local gunDropConnections = {}
local function isGunDropInstance(object)
    if not object then return false end
    if object.Name == "GunDrop" then return true end
    if object:FindFirstChild("GunDropClips") or object.Name == "GunDropClips" then return true end
    if string.find(string.lower(object.Name), "gundrop") then return true end
    return false
end
local function applyGunESP(child)
    if not child or not child.Parent then return end
    if child:FindFirstChild(GUN_ESP_ID) then return end
    local highlight               = Instance.new("Highlight")
    highlight.Name                = GUN_ESP_ID
    highlight.FillColor           = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency    = 0.40
    highlight.OutlineTransparency = 0
    highlight.Adornee             = child
    highlight.Parent              = child
end
local function watchForGunDrop(parent)
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do
        if isGunDropInstance(child) then applyGunESP(child) end
    end
    local c1 = parent.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if not child or not child.Parent then return end
        if isGunDropInstance(child) then
            applyGunESP(child)
        elseif child:IsA("Model") or child:IsA("Folder") then
            for _, sub in ipairs(child:GetChildren()) do
                if isGunDropInstance(sub) then applyGunESP(sub) end
            end
        end
    end)
    table.insert(gunDropConnections, c1)
    local c2 = parent.DescendantAdded:Connect(function(desc)
        if not desc or not desc.Parent then return end
        if desc.Name == "GunDropClips" then
            applyGunESP(desc.Parent)
        elseif desc.Name == "GunDrop" then
            applyGunESP(desc)
        end
    end)
    table.insert(gunDropConnections, c2)
end
local function enableGunDropESP()
    watchForGunDrop(Workspace)
    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            watchForGunDrop(folder)
        end
    end
end
local function disableGunDropESP()
    for _, conn in ipairs(gunDropConnections) do conn:Disconnect() end
    gunDropConnections = {}
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child:IsA("Highlight") and child.Name == GUN_ESP_ID then
            child:Destroy()
        end
    end
end
-- ==========================================
-- COIN ESP
-- ==========================================
local coinConnections = {}
local function isCoinInstance(object)
    if not object then return false end
    local name = string.lower(object.Name)
    if name == "coin_server" or name == "coin" then return true end
    if string.find(name, "coin") and (object:IsA("BasePart") or object:IsA("Model")) then return true end
    return false
end
local function applyCoinESP(child)
    if not child or not child.Parent then return end
    if child:FindFirstChild(COIN_ESP_ID) then return end
    local highlight               = Instance.new("Highlight")
    highlight.Name                = COIN_ESP_ID
    highlight.FillColor           = Color3.fromRGB(255, 215, 0)
    highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency    = 0.20
    highlight.OutlineTransparency = 0
    highlight.Adornee             = child
    highlight.Parent              = child
    local bb = Instance.new("BillboardGui")
    bb.Name        = COIN_ESP_ID .. "_BB"
    bb.Size        = UDim2.new(0, 50, 0, 20)
    bb.AlwaysOnTop = true
    bb.Parent      = child
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size                   = UDim2.new(1, 0, 1, 0)
    text.Text                   = "[Coin]"
    text.TextColor3             = Color3.fromRGB(255, 215, 0)
    text.TextStrokeTransparency = 0
    text.Font                   = Enum.Font.SourceSansBold
    text.TextSize               = 14
    text.Parent                 = bb
end
local function watchForCoins(parent)
    if not parent then return end
    for _, child in ipairs(parent:GetDescendants()) do
        if isCoinInstance(child) then applyCoinESP(child) end
    end
    local c = parent.DescendantAdded:Connect(function(desc)
        task.wait(0.1)
        if isCoinInstance(desc) then applyCoinESP(desc) end
    end)
    table.insert(coinConnections, c)
end
local function enableCoinESP()
    local container = Workspace:FindFirstChild("Normal")
    if container then watchForCoins(container) else watchForCoins(Workspace) end
    if container then
        watchForCoins(container)
    else
        watchForCoins(Workspace)
    end
end
local function disableCoinESP()
    for _, conn in ipairs(coinConnections) do conn:Disconnect() end
    coinConnections = {}
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child.Name == COIN_ESP_ID or child.Name == COIN_ESP_ID .. "_BB" then
            child:Destroy()
        end
    end
end
-- ==========================================
-- PLAYER ESP + USERNAME ESP
-- ==========================================
local function hasWeapon(player, weaponName)
    if player.Character and player.Character:FindFirstChild(weaponName) then return true end
    if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild(weaponName) then return true end
    return false
end
local function addHighlight(player)
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local highlight = player.Character:FindFirstChild(PLAYER_ESP_ID)
    if not highlight then
        highlight                     = Instance.new("Highlight")
        highlight.Name                = PLAYER_ESP_ID
        highlight.Parent              = player.Character
        highlight.OutlineTransparency = 0.50
        highlight.FillTransparency    = 0.50
        highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
    end
    if hasWeapon(player, "Knife") then
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
    elseif hasWeapon(player, "Gun") then
        highlight.FillColor = Color3.fromRGB(150, 0, 255)
    else
        highlight.FillColor = Color3.fromRGB(255, 255, 255)
    end
end
local function removeAllPlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild(PLAYER_ESP_ID) then
            player.Character[PLAYER_ESP_ID]:Destroy()
        end
    end
end
-- Username ESP: BillboardGui above the head showing name + health
local function addUsernameESP(player)
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    -- Remove stale one if it exists
    if head:FindFirstChild(USERNAME_ESP_ID) then
        head:FindFirstChild(USERNAME_ESP_ID):Destroy()
    end
    local bb = Instance.new("BillboardGui")
    bb.Name            = USERNAME_ESP_ID
    bb.Size            = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset     = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop     = true
    bb.MaxDistance     = 200
    bb.ResetOnSpawn    = false
    bb.Parent          = head
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name                   = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size                   = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position               = UDim2.new(0, 0, 0, 0)
    nameLabel.Text                   = player.DisplayName .. " (@" .. player.Name .. ")"
    nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextScaled             = true
    nameLabel.Parent                 = bb
    -- Health label
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Name                   = "HpLabel"
    hpLabel.BackgroundTransparency = 1
    hpLabel.Size                   = UDim2.new(1, 0, 0.4, 0)
    hpLabel.Position               = UDim2.new(0, 0, 0.6, 0)
    hpLabel.Text                   = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
    hpLabel.TextColor3             = Color3.fromRGB(80, 255, 80)
    hpLabel.TextStrokeTransparency = 0
    hpLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    hpLabel.Font                   = Enum.Font.Gotham
    hpLabel.TextScaled             = true
    hpLabel.Parent                 = bb
    -- Live update health
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if hpLabel and hpLabel.Parent then
            local hp = math.floor(humanoid.Health)
            hpLabel.Text = "HP: " .. hp .. "/" .. math.floor(humanoid.MaxHealth)
            -- Colour shifts red as HP drops
            local ratio = math.clamp(hp / humanoid.MaxHealth, 0, 1)
            hpLabel.TextColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
        end
    end)
end
local function removeAllUsernameESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head and head:FindFirstChild(USERNAME_ESP_ID) then
                head:FindFirstChild(USERNAME_ESP_ID):Destroy()
            end
        end
    end
end
-- ==========================================
-- AIMING LOGIC
-- ==========================================
local FOV_RADIUS        = 180
local MAX_DISTANCE      = 250
local PREDICTION_FACTOR = 0.95
local fovCircle        = Drawing.new("Circle")
fovCircle.Visible      = false
fovCircle.Color        = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness    = 1
fovCircle.NumSides     = 64
fovCircle.Radius       = FOV_RADIUS
fovCircle.Filled       = false
fovCircle.Transparency = 0.5
local lastTargetPos  = nil
local lastTargetTime = nil
local function getMousePosition()
    return UserInputService:GetMouseLocation()
end
local function getNearestHeadInFOV()
    local character = localPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    local mousePos     = getMousePosition()
    local nearest      = nil
    local shortestDist = FOV_RADIUS
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local head     = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local worldDist = (rootPart.Position - head.Position).Magnitude
                if worldDist <= MAX_DISTANCE then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local targetCoord = Vector2.new(screenPos.X, screenPos.Y)
                        local mouseDist   = (mousePos - targetCoord).Magnitude
                        if mouseDist < shortestDist then
                            shortestDist = mouseDist
                            nearest      = head
                        end
                    end
                end
            end
        end
    end
    return nearest
end
local function getSilentAimPosition()
    local target = getNearestHeadInFOV()
    if not target then
        lastTargetPos  = nil
        lastTargetTime = nil
        return nil
    end
    local now         = tick()
    local aimPosition = target.Position
    if lastTargetPos and lastTargetTime then
        local dt = now - lastTargetTime
        if dt > 0 and dt < 0.5 then
            local velocity = (target.Position - lastTargetPos) / dt
            aimPosition    = target.Position + velocity * PREDICTION_FACTOR
        end
    end
    lastTargetPos  = target.Position
    lastTargetTime = now
    return aimPosition
end
local mouseMetaHooked = false
local originalIndex   = nil
local function hookMouse()
    if mouseMetaHooked then return end
    mouseMetaHooked = true
    local mt = getrawmetatable(mouse)
    originalIndex = mt.__index
    if setreadonly then setreadonly(mt, false) end
    if make_writeable then make_writeable(mt) end
    mt.__index = newcclosure(function(self, key)
        if silentAim_Enabled and (key == "Hit" or key == "Target") then
            local aimPos = getSilentAimPosition()
            if aimPos then
                if key == "Hit" then
                    return CFrame.new(aimPos)
                elseif key == "Target" then
                    local head = getNearestHeadInFOV()
                    if head then return head end
                end
            end
        end
        return originalIndex(self, key)
    end)
end
local function unhookMouse()
    if not mouseMetaHooked then return end
    mouseMetaHooked = false
    local mt = getrawmetatable(mouse)
    if setreadonly then setreadonly(mt, false) end
    if make_writeable then make_writeable(mt) end
    if originalIndex then
        mt.__index = originalIndex
        originalIndex = nil
    end
end
-- ==========================================
-- NOCLIP
-- ==========================================
local noclipConn = nil
local function enableNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = localPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end
local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = localPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end
-- ==========================================
-- FLING PLAYER  (STRONGER)
-- ==========================================
local isFlingActive   = false
local flingTargetName = ""
local function findPlayerByName(name)
    name = string.lower(name)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            if string.lower(player.Name) == name or string.lower(player.DisplayName) == name then return player end
            if string.find(string.lower(player.Name), name, 1, true) then return player end
            if string.find(string.lower(player.DisplayName), name, 1, true) then return player end
        end
    end
    return nil
end
local function flingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        Fluent:Notify({ Title = "Fling", Content = "Target not found or has no character", Duration = 3 })
        return
    end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        Fluent:Notify({ Title = "Fling", Content = "Target has no HumanoidRootPart", Duration = 3 })
        return
    end
    local myChar = localPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum then return end
    local msg = "Flinging " .. targetPlayer.Name .. "..."
    Fluent:Notify({ Title = "Fling", Content = msg, Duration = 3 })
    isFlingActive = true
    local oldWalkSpeed   = myHum.WalkSpeed
    local oldJumpPower   = myHum.JumpPower
    myHum.WalkSpeed  = 0
    myHum.JumpPower  = 0
    local startTime  = tick()
    -- Phase 2: Active Fling — Massive RotVelocity + teleporting inside them
    while isFlingActive and (tick() - startTime) < 2.5 do
        if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then break end
        local tRoot = targetPlayer.Character.HumanoidRootPart
        
        -- High rotational velocity is what actually causes the physics engine to fling them upon collision
        myRoot.RotVelocity = Vector3.new(50000, 50000, 50000)
        -- Add erratic velocity to bounce around inside them
        myRoot.Velocity = Vector3.new(math.random(-1000, 1000), 5000, math.random(-1000, 1000))
        
        -- Stick directly to their core
        myRoot.CFrame = tRoot.CFrame
        RunService.Heartbeat:Wait()
    end
    -- Phase 3: Release
    isFlingActive = false
    -- Cleanup
    if myRoot and myRoot.Parent then
        task.wait(0.05)
        myRoot.RotVelocity = Vector3.new(0, 0, 0)
    end
    if myHum and myHum.Parent then
        myHum.WalkSpeed = oldWalkSpeed
        myHum.JumpPower = oldJumpPower
    end
    Fluent:Notify({ Title = "Fling", Content = "Fling complete!", Duration = 2 })
end
-- ==========================================
-- UI MINIMIZE / RESTORE TOGGLE  (V Key)
-- ==========================================
local isMinimized   = false
local UI_TOGGLE_KEY = Enum.KeyCode.V
local function toggleUI()
    isMinimized = not isMinimized
    if isMinimized then
        -- Hide main GUI, show the small box on the right
        if fluentGui and fluentGui.Parent then
            fluentGui.Enabled = false
        end
        minimizeBox.Visible = true
    else
        -- Show main GUI, hide the box
        if fluentGui and fluentGui.Parent then
            fluentGui.Enabled = true
        end
        minimizeBox.Visible = false
    end
end
-- ==========================================
-- INPUT HANDLER
-- ==========================================
local CAM_LOCK_KEY    = Enum.KeyCode.F
local aimbotToggleObj = nil
track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == UI_TOGGLE_KEY then toggleUI() end
    if input.KeyCode == CAM_LOCK_KEY then
        if aimbotToggleObj then aimbotToggleObj:SetValue(not aimbot_Enabled) end
    end
end))
-- ==========================================
-- RENDER LOOP  (FOV circle + Camera Aimbot)
-- ==========================================
track(RunService.RenderStepped:Connect(function()
    if not silentAim_Enabled and not aimbot_Enabled then
        fovCircle.Visible = false
        return
    end
    fovCircle.Visible  = true
    fovCircle.Position = getMousePosition()
    local target = getNearestHeadInFOV()
    if target then
        fovCircle.Color = Color3.fromRGB(0, 255, 100)
        if aimbot_Enabled then
            local camPos = camera.CFrame.Position
            camera.CFrame = CFrame.new(camPos, target.Position)
        end
    else
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
    end
end))
-- ==========================================
-- BACKGROUND ESP LOOP
-- ==========================================
local _espRunning = true
task.spawn(function()
    while _espRunning do
        task.wait(0.5)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                if playerESP_Enabled   then addHighlight(player)     end
                if usernameESP_Enabled then addUsernameESP(player)   end
            end
        end
    end
end)
-- ==========================================
-- GUI TOGGLES — ESP Tab
-- ==========================================
Tabs.ESP:AddToggle("GunDropToggle", {Title = "Gun Drop ESP", Default = false}):OnChanged(function(value)
    gunDropESP_Enabled = value
    if value then enableGunDropESP() else disableGunDropESP() end
    if value then
        enableGunDropESP()
    else
        disableGunDropESP()
    end
end)
Tabs.ESP:AddToggle("CoinESPToggle", {Title = "Coin ESP", Default = false}):OnChanged(function(value)
    coinESP_Enabled = value
    if value then enableCoinESP() else disableCoinESP() end
    if value then
        enableCoinESP()
    else
        disableCoinESP()
    end
end)
Tabs.ESP:AddToggle("PlayerESPToggle", {Title = "Player ESP (Highlight)", Default = false}):OnChanged(function(value)
    playerESP_Enabled = value
    if not value then removeAllPlayerESP() end
end)
-- NEW: Username ESP toggle
Tabs.ESP:AddToggle("UsernameESPToggle", {Title = "Username ESP (Name + HP)", Default = false}):OnChanged(function(value)
    usernameESP_Enabled = value
    if not value then
        removeAllUsernameESP()
    else
        -- Apply immediately to all current players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then addUsernameESP(player) end
        end
    end
end)
-- ==========================================
-- GUI TOGGLES — Combat Tab
-- ==========================================
aimbotToggleObj = Tabs.LOCK:AddToggle("AimbotToggle", {Title = "Camera Lock (Head) [F]", Default = false})
aimbotToggleObj:OnChanged(function(value)
    aimbot_Enabled = value
    if not silentAim_Enabled and not aimbot_Enabled then
        fovCircle.Visible = false
        lastTargetPos     = nil
        lastTargetTime    = nil
    end
    local msg = value and "Enabled" or "Disabled"
    Fluent:Notify({ Title = "Camera Lock", Content = msg, Duration = 1 })
end)
Tabs.LOCK:AddToggle("SilentAimToggle", {Title = "Silent Aim (Head)", Default = false}):OnChanged(function(value)
    silentAim_Enabled = value
    if value then
        hookMouse()
    else
        if not silentAim_Enabled and not aimbot_Enabled then
            fovCircle.Visible = false
            lastTargetPos     = nil
            lastTargetTime    = nil
        end
    end
end)
Tabs.LOCK:AddToggle("NoclipToggle", {Title = "Noclip", Default = false}):OnChanged(function(value)
    noclipEnabled = value
    if value then enableNoclip() else disableNoclip() end
    if value then
        enableNoclip()
    else
        disableNoclip()
    end
end)
-- ==========================================
-- GUI TOGGLES — Fling Tab
-- ==========================================
local flingInput = Tabs.FLING:AddInput("FlingPlayerName", {
    Title       = "Player Name",
    Default     = "",
    Placeholder = "Type player name...",
    Numeric     = false
})
flingInput:OnChanged(function(value) flingTargetName = value end)
Tabs.FLING:AddButton({
    Title = "Fling Player",
    Callback = function()
        if flingTargetName == "" then
            Fluent:Notify({ Title = "Fling", Content = "Enter a player name first!", Duration = 3 })
            return
        end
        local target = findPlayerByName(flingTargetName)
        if target then
            task.spawn(function() flingPlayer(target) end)
        if target ~= nil then
            local t = target
            task.spawn(function()
                flingPlayer(t)
            end)
        else
            local msg = "Player not found: " .. flingTargetName
            Fluent:Notify({ Title = "Fling", Content = msg, Duration = 3 })
        end
    end
})
Tabs.FLING:AddButton({
    Title = "Stop Fling",
    Callback = function()
        isFlingActive = false
        Fluent:Notify({ Title = "Fling", Content = "Fling stopped", Duration = 2 })
    end
})
-- ==========================================
-- ROLLBACK / DUPE TAB
-- ==========================================
local isDupeFlooding    = false
local dupeFloodConnection = nil
Tabs.ROLLBACK:AddParagraph({
    Title   = "How to Dupe / Freeze Save",
    Content = "1. Enable 'Freeze Save'\n2. Wait 2-3 seconds for DataStore queues to fill\n3. Drop/Trade your weapon to an alt account\n4. Leave the game immediately.\nWhen you rejoin, the server will load your previous save since the remote flooded."
})
local SAVE_REMOTE_NAME   = "SaveData"
local UPDATE_REMOTE_NAME = "UpdateInventory"
Tabs.ROLLBACK:AddInput("SaveRemoteName", {
    Title       = "Save RemoteEvent Name",
    Default     = SAVE_REMOTE_NAME,
    Placeholder = "e.g. ChangeProfileData",
    Numeric     = false
}):OnChanged(function(value) SAVE_REMOTE_NAME = value end)
local ToggleDupe = Tabs.ROLLBACK:AddToggle("DupeFloodToggle", {Title = "Enable Freeze Save (Spam Remotes)", Default = false})
ToggleDupe:OnChanged(function(value)
    isDupeFlooding = value
    if isDupeFlooding then
        local RS = game:GetService("ReplicatedStorage")
        dupeFloodConnection = RunService.Heartbeat:Connect(function()
            local saveRemote   = RS:FindFirstChild(SAVE_REMOTE_NAME, true)
            local updateRemote = RS:FindFirstChild(UPDATE_REMOTE_NAME, true)
            if saveRemote and saveRemote:IsA("RemoteEvent") then
                saveRemote:FireServer("FreezeSpam")
            end
            if updateRemote and updateRemote:IsA("RemoteEvent") then
                local brokenData = {}
                brokenData["NaN_Exploit"] = math.huge * 0
                brokenData["HugeString"]  = string.rep("A", 50000)
                updateRemote:FireServer(brokenData)
            end
        end)
        local msg = "Flooding " .. SAVE_REMOTE_NAME .. ". Drop your items now!"
        Fluent:Notify({ Title = "Save Frozen", Content = msg, Duration = 3 })
    else
        if dupeFloodConnection then
            dupeFloodConnection:Disconnect()
            dupeFloodConnection = nil
        end
        Fluent:Notify({ Title = "Save Frozen", Content = "Spamming stopped.", Duration = 2 })
    end
end)
-- ==========================================
-- MISC TAB
-- ==========================================
Tabs.MISC:AddToggle("AntiAfkToggle", { Title = "Anti-AFK", Default = false }):OnChanged(function(value)
    antiAfkEnabled = value
    if value then
        local VirtualUser = game:GetService("VirtualUser")
        antiAfkConn = localPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Fluent:Notify({ Title = "Anti-AFK", Content = "Enabled - You will not be kicked", Duration = 3 })
    else
        if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
        Fluent:Notify({ Title = "Anti-AFK", Content = "Disabled", Duration = 2 })
    end
end)
Tabs.MISC:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer)
    end
})
Tabs.MISC:AddButton({
    Title = "Server Hop (Random Server)",
    Callback = function()
        Fluent:Notify({ Title = "Server Hop", Content = "Finding a new server...", Duration = 3 })
        local TPS         = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TPS:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
                    return
                end
            end
            Fluent:Notify({ Title = "Server Hop", Content = "No available servers found", Duration = 3 })
        else
            Fluent:Notify({ Title = "Server Hop", Content = "Failed to fetch servers", Duration = 3 })
        end
    end
})
-- ==========================================
-- CLEANUP  (registered for next run)
-- ==========================================
_G.AWMM2_Cleanup = function()
    _espRunning   = false
    isFlingActive = false
    for _, conn in ipairs(_connections) do pcall(function() conn:Disconnect() end) end
    _connections = {}
    for _, conn in ipairs(gunDropConnections) do pcall(function() conn:Disconnect() end) end
    gunDropConnections = {}
    if dupeFloodConnection then pcall(function() dupeFloodConnection:Disconnect() end) end
    pcall(disableNoclip)
    pcall(unhookMouse)
    if antiAfkConn then pcall(function() antiAfkConn:Disconnect() end) end
    pcall(disableGunDropESP)
    pcall(disableCoinESP)
    pcall(removeAllPlayerESP)
    pcall(removeAllUsernameESP)
    pcall(function() fovCircle:Remove() end)
    if fluentGui then
        pcall(function() fluentGui:Destroy() end)
        fluentGui = nil
    end
end
-- ==========================================
-- INIT
-- ==========================================
Window:SelectTab(1)
Fluent:Notify({
    Title    = "A&W's MM2 HUB",
    Content  = "Credits: aimxxz",
    Duration = 5
})
