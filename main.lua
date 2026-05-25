-- ==========================================
-- 1. LOAD FLUENT UI LIBRARY
-- ==========================================
-- FIX: Replaced the broken homepage link with the official raw repository library file
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Create the Window
local Window = Fluent:CreateWindow({
    Title = "A&W MM2",
    SubTitle = "By aimxxz",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 500),
    Acrylic = true,
    Theme = "Light",
    Minimizable = true
})

-- Create our Tabs
local Tabs = {
    ESP = Window:AddTab({ Title = ";)", Icon = "eye" })
}

-- ==========================================
-- 2. OUR FIXED & HARDENED ESP ENGINE
-- ==========================================
local gunDropESP_Enabled = false 
local playerESP_Enabled = false 

-- Random strings for instance names to bypass simple anti-cheat string scans
local GUN_ESP_ID = "G_" .. tostring(math.random(10000, 99999))
local PLAYER_ESP_ID = "P_" .. tostring(math.random(10000, 99999))

-- Store event connections so we can safely disconnect them when toggled off
local gunDropConnections = {}
local Workspace = game:GetService("Workspace")

-- Core logic to see if a specific instance matches MM2 gun drop patterns
local function isGunDropInstance(object)
    if not object then return false end
    
    -- Matches the standard part name or mesh asset indicators
    if object.Name == "GunDrop" then return true end
    if object:FindFirstChild("GunDropClips") or object.Name == "GunDropClips" then return true end
    
    -- Check string matches if Nikilis appends text variants
    if string.find(string.lower(object.Name), "gundrop") then return true end
    
    return false
end

local function applyGunESP(child)
    if not child then return end
    if child:FindFirstChild(GUN_ESP_ID) then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = GUN_ESP_ID
    highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Neon Green
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.40
    highlight.OutlineTransparency = 0
    highlight.Adornee = child
    highlight.Parent = child
    print("✅ Gun Drop Highlighted successfully.")
end

local function watchForGunDrop(parent)
    if not parent then return end

    -- Check anything already there (Checking parts, meshes, and models)
    for _, child in ipairs(parent:GetChildren()) do
        if isGunDropInstance(child) then
            applyGunESP(child)
        end
    end

    -- Watch for newly instantiated drops
    local c1 = parent.ChildAdded:Connect(function(child)
        task.wait(0.1) -- Allow network replication properties to catch up
        if isGunDropInstance(child) then
            applyGunESP(child)
        elseif child:IsA("Model") or child:IsA("Folder") then
            -- Fallback structural search inside container additions
            for _, subChild in ipairs(child:GetChildren()) do
                if isGunDropInstance(subChild) then
                    applyGunESP(subChild)
                end
            end
        end
    end)
    table.insert(gunDropConnections, c1)

    -- Watch all descendants too (Captures instantaneous child property renames)
    local c2 = parent.DescendantAdded:Connect(function(desc)
        if desc.Name == "GunDropClips" or desc.Name == "GunDrop" then
            applyGunESP(desc)
        end
    end)
    table.insert(gunDropConnections, c2)
end

local function enableGunDropESP()
    -- Watch Workspace AND every immediate sub-container inside it
    watchForGunDrop(Workspace)
    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            watchForGunDrop(folder)
        end
    end
end

local function disableGunDropESP()
    -- Disconnect all active hook events
    for _, connection in ipairs(gunDropConnections) do
        connection:Disconnect()
    end
    gunDropConnections = {}

    -- Clean up gun highlights completely safely from Workspace
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child:IsA("Highlight") and child.Name == GUN_ESP_ID then
            child:Destroy()
        end
    end
end

-- [PLAYER ESP FUNCTIONS]
local function hasWeapon(player, weaponName)
    if player.Character and player.Character:FindFirstChild(weaponName) then return true end
    if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild(weaponName) then return true end
    return false
end

local function addHighlight(player)
    if not player.Character then return end
    local highlight = player.Character:FindFirstChild(PLAYER_ESP_ID)
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = PLAYER_ESP_ID
        highlight.Parent = player.Character
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.50     
        highlight.FillTransparency = 0.50     
    end
    
    if hasWeapon(player, "Knife") then
        highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red for Murderer
    elseif hasWeapon(player, "Gun") then
        highlight.FillColor = Color3.fromRGB(150, 0, 255) -- Purple for Sheriff
    else
        highlight.FillColor = Color3.fromRGB(255, 255, 255) -- White for Innocents
    end
end

-- ==========================================
-- 3. THE GUI TOGGLE BUTTONS
-- ==========================================
local ToggleGunDrop = Tabs.ESP:AddToggle("GunDropToggle", {Title = "Enable Gun Drop ESP", Default = false})
ToggleGunDrop:OnChanged(function()
    gunDropESP_Enabled = ToggleGunDrop.Value
    if gunDropESP_Enabled then
        enableGunDropESP() 
    else
        disableGunDropESP()
    end
end)

local TogglePlayerESP = Tabs.ESP:AddToggle("PlayerESPToggle", {Title = "Enable Player ESP", Default = false})
TogglePlayerESP:OnChanged(function()
    playerESP_Enabled = TogglePlayerESP.Value
    if not playerESP_Enabled then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild(PLAYER_ESP_ID) then
                player.Character[PLAYER_ESP_ID]:Destroy()
            end
        end
    end
end)

-- ==========================================
-- 4. THE BACKGROUND LOOP
-- ==========================================
task.spawn(function()
    while true do
        task.wait(1) 
        if playerESP_Enabled then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    addHighlight(player)
                end
            end
        end
    end
end)

-- Initialize Fluent UI
Window:SelectTab(1)
Fluent:Notify({
    Title = "A&W MM2",
    Content = "Hub loaded successfully! By aimxxz",
    Duration = 5 
})
