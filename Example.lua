-- Load the UI Library (replace with your own loadstring if using)
local PhantomUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/wrdzy/drawinglib/refs/heads/main/DrawingUiLIb.lua"))()

-- Create a main window
local mainWindow = PhantomUI:CreateWindow({
    Title = "Phantom UI Demo",
    Width = 320,
    Height = 450,
    X = 50,
    Y = 50
})

-- Create sections to organize controls
local combatSection = mainWindow:AddSection("Combat")
local visualsSection = mainWindow:AddSection("Visuals")
local movementSection = mainWindow:AddSection("Movement")
local miscSection = mainWindow:AddSection("Misc")

-- Combat section elements
mainWindow:AddToggle({
    Name = "Aimbot",
    Default = false,
    Section = combatSection,
    Callback = function(value)
        print("Aimbot:", value)
        -- Your aimbot implementation here
    end
})

mainWindow:AddSlider({
    Name = "Aimbot FOV",
    Min = 30,
    Max = 300,
    Default = 80,
    Decimals = 0,
    Section = combatSection,
    Callback = function(value)
        print("FOV set to:", value)
        -- Update FOV circle here
    end
})

mainWindow:AddDropdown({
    Name = "Target Part",
    Items = {"Head", "Torso", "HumanoidRootPart", "Random"},
    Default = "Head",
    Section = combatSection,
    Callback = function(part)
        print("Target part set to:", part)
        -- Update target part here
    end
})

mainWindow:AddKeybind({
    Name = "Aim Key",
    Default = Enum.KeyCode.E,
    Section = combatSection,
    Callback = function(key)
        print("Aim key set to:", key)
    end
})

-- Visuals section elements
mainWindow:AddToggle({
    Name = "ESP",
    Default = true,
    Section = visualsSection,
    Callback = function(value)
        print("ESP:", value)
        -- Toggle ESP functionality
    end
})

mainWindow:AddToggle({
    Name = "Box ESP",
    Default = true,
    Section = visualsSection,
    Callback = function(value)
        print("Box ESP:", value)
    end
})

mainWindow:AddToggle({
    Name = "Name ESP",
    Default = true,
    Section = visualsSection,
    Callback = function(value)
        print("Name ESP:", value)
    end
})

mainWindow:AddToggle({
    Name = "Distance ESP",
    Default = false,
    Section = visualsSection,
    Callback = function(value)
        print("Distance ESP:", value)
    end
})

mainWindow:AddToggle({
    Name = "Chams",
    Default = false,
    Section = visualsSection,
    Callback = function(value)
        print("Chams:", value)
    end
})

-- Movement section elements
mainWindow:AddToggle({
    Name = "Speed Hack",
    Default = false,
    Section = movementSection,
    Callback = function(value)
        print("Speed Hack:", value)
        -- Toggle speed hack
    end
})

mainWindow:AddSlider({
    Name = "Speed Value",
    Min = 16,
    Max = 150,
    Default = 40,
    Decimals = 0,
    Section = movementSection,
    Callback = function(value)
        print("Speed set to:", value)
        -- Set player's walk speed
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = value
        end
    end
})

mainWindow:AddToggle({
    Name = "Fly",
    Default = false,
    Section = movementSection,
    Callback = function(value)
        print("Fly:", value)
        -- Toggle flight
    end
})

mainWindow:AddToggle({
    Name = "No Clip",
    Default = false,
    Section = movementSection,
    Callback = function(value)
        print("No Clip:", value)
        -- Toggle no clip
    end
})

-- Misc section elements
mainWindow:AddButton({
    Name = "Reset Character",
    Section = miscSection,
    Callback = function()
        print("Resetting character...")
        local player = game.Players.LocalPlayer
        if player.Character then
            player.Character:BreakJoints()
        end
    end
})

mainWindow:AddToggle({
    Name = "Anti AFK",
    Default = true,
    Section = miscSection,
    Callback = function(value)
        print("Anti AFK:", value)
        -- Toggle anti AFK
    end
})

mainWindow:AddToggle({
    Name = "Auto Respawn",
    Default = false,
    Section = miscSection,
    Callback = function(value)
        print("Auto Respawn:", value)
        -- Toggle auto respawn
    end
})

-- Add a status label
local statusLabel = mainWindow:AddLabel({
    Text = "Status: Ready",
    Color = PhantomUI.Theme.Accent,
    Section = miscSection
})

-- Update status label periodically as an example
spawn(function()
    while wait(5) do
        local player = game.Players.LocalPlayer
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        statusLabel:SetText("FPS: " .. fps .. " | Ping: " .. player:GetNetworkPing() * 1000 .. "ms")
    end
end)

-- Reminder about toggle key
mainWindow:AddLabel({
    Text = "Press RightShift to toggle UI",
    Color = PhantomUI.Theme.DarkText,
    Section = miscSection
})

-- Print initialization message to console
print("Phantom UI initialized. Press RightShift to toggle.")
