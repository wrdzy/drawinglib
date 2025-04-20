--[[
    Simple Phantom UI Library
    A lightweight UI library using the Drawing API for Roblox exploits
    
    USAGE EXAMPLE:
    
    -- Load the library directly
    local UI = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()
    
    -- Create a window
    local window = UI:Window("My Title", {size = Vector2.new(300, 350)})
    
    -- Add elements
    local toggle = window:Toggle("Speed Hack", false, function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value and 100 or 16
    end)
    
    local slider = window:Slider("Jump Power", 50, 250, 50, function(value)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
    end)
    
    local button = window:Button("Teleport", function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Part.CFrame
    end)
    
    local dropdown = window:Dropdown("Select Player", {"Player1", "Player2"}, function(selected)
        print("Selected: " .. selected)
    end)
]]--

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Main Library Table
local SimplePUI = {}
SimplePUI.__index = SimplePUI

-- Settings & Defaults
SimplePUI.Drawings = {}
SimplePUI.Windows = {}
SimplePUI.Connections = {}
SimplePUI.Theme = {
    Background = Color3.fromRGB(40, 40, 60),
    Section = Color3.fromRGB(30, 30, 45),
    Text = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(100, 100, 255),
    DarkText = Color3.fromRGB(175, 175, 175),
    Element = Color3.fromRGB(45, 45, 65),
    Enabled = Color3.fromRGB(100, 100, 255),
    Disabled = Color3.fromRGB(60, 60, 85),
    Button = Color3.fromRGB(50, 50, 70),
    ButtonHover = Color3.fromRGB(60, 60, 80),
    Border = Color3.fromRGB(60, 60, 85),
    Shadow = Color3.fromRGB(15, 15, 25)
}

SimplePUI.DefaultFont = Drawing.Fonts.Monospace
SimplePUI.DefaultSize = 13
SimplePUI.ToggleKey = Enum.KeyCode.RightShift
SimplePUI.Visible = true

-- Utility Functions
local function AddDrawing(drawing)
    table.insert(SimplePUI.Drawings, drawing)
    return drawing
end

local function IsMouseOver(obj)
    local mouse = UserInputService:GetMouseLocation()
    return (mouse.X >= obj.Position.X and mouse.X <= obj.Position.X + obj.Size.X and
            mouse.Y >= obj.Position.Y and mouse.Y <= obj.Position.Y + obj.Size.Y)
end

local function Round(num, places)
    places = places or 1
    local mult = 10^places
    return math.floor(num * mult + 0.5) / mult
end

local function CreateText(text, position, size, color, isCenter)
    local txt = AddDrawing(Drawing.new("Text"))
    txt.Text = text
    txt.Position = position
    txt.Size = size or SimplePUI.DefaultSize
    txt.Color = color or SimplePUI.Theme.Text
    txt.Center = isCenter or false
    txt.Outline = true
    txt.Visible = SimplePUI.Visible
    txt.Font = SimplePUI.DefaultFont
    return txt
end

-- Window Class
local Window = {}
Window.__index = Window

function Window:_update()
    -- Override in implementation
end

function Window:_updatePosition(newPos)
    -- Override in implementation
end

function Window:_createElementContainer(height)
    local container = {
        ElementHeight = height,
        Container = AddDrawing(Drawing.new("Square")),
        Objects = {}
    }
    
    container.Container.Size = Vector2.new(self.Width - 20, height)
    container.Container.Position = Vector2.new(self.X + 10, self.Y + self.ContentY)
    container.Container.Color = SimplePUI.Theme.Element
    container.Container.Filled = true
    container.Container.Transparency = 0.95
    container.Container.Visible = SimplePUI.Visible
    container.Container.ZIndex = 3
    
    -- Add outline
    local outline = AddDrawing(Drawing.new("Square"))
    outline.Size = Vector2.new(self.Width - 20, height)
    outline.Position = Vector2.new(self.X + 10, self.Y + self.ContentY)
    outline.Color = SimplePUI.Theme.Border
    outline.Filled = false
    outline.Thickness = 1
    outline.Transparency = 0.7
    outline.Visible = SimplePUI.Visible
    outline.ZIndex = 4
    
    container.Objects.Outline = outline
    
    self.ContentY = self.ContentY + height + 5
    return container
end

function Window:Toggle(name, default, callback)
    callback = callback or function() end
    default = default or false
    
    -- Create container
    local container = self:_createElementContainer(25)
    
    -- Label text
    local label = CreateText(name, Vector2.new(self.X + 15, self.Y + self.ContentY - 30 + 5))
    container.Objects.Label = label
    
    -- Toggle indicator
    local indicatorBorder = AddDrawing(Drawing.new("Square"))
    indicatorBorder.Size = Vector2.new(16, 16)
    indicatorBorder.Position = Vector2.new(self.X + self.Width - 30, self.Y + self.ContentY - 30 + 5)
    indicatorBorder.Color = SimplePUI.Theme.Border
    indicatorBorder.Filled = false
    indicatorBorder.Thickness = 1
    indicatorBorder.Transparency = 1
    indicatorBorder.Visible = SimplePUI.Visible
    indicatorBorder.ZIndex = 5
    container.Objects.IndicatorBorder = indicatorBorder
    
    local indicatorFill = AddDrawing(Drawing.new("Square"))
    indicatorFill.Size = Vector2.new(10, 10)
    indicatorFill.Position = Vector2.new(self.X + self.Width - 27, self.Y + self.ContentY - 30 + 8)
    indicatorFill.Color = default and SimplePUI.Theme.Enabled or SimplePUI.Theme.Disabled
    indicatorFill.Filled = true
    indicatorFill.Transparency = default and 1 or 0.4
    indicatorFill.Visible = SimplePUI.Visible
    indicatorFill.ZIndex = 6
    container.Objects.IndicatorFill = indicatorFill
    
    -- Logic
    local toggle = {
        Value = default,
        Update = function(self, value)
            self.Value = value
            indicatorFill.Color = value and SimplePUI.Theme.Enabled or SimplePUI.Theme.Disabled
            indicatorFill.Transparency = value and 1 or 0.4
            callback(value)
        end,
        Container = container
    }
    
    -- Handle clicks
    table.insert(self.Elements, {
        Type = "Toggle",
        Instance = toggle,
        Container = container.Container,
        OnClick = function()
            toggle:Update(not toggle.Value)
        end
    })
    
    return toggle
end

function Window:Slider(name, min, max, default, callback)
    callback = callback or function() end
    min = min or 0
    max = max or 100
    default = math.clamp(default or min, min, max)
    
    -- Create container
    local container = self:_createElementContainer(40)
    
    -- Label text
    local label = CreateText(name, Vector2.new(self.X + 15, self.Y + self.ContentY - 45 + 5))
    container.Objects.Label = label
    
    -- Value text
    local value = CreateText(tostring(default), Vector2.new(self.X + self.Width - 30, self.Y + self.ContentY - 45 + 5))
    container.Objects.Value = value
    
    -- Slider track
    local trackBg = AddDrawing(Drawing.new("Square"))
    trackBg.Size = Vector2.new(self.Width - 30, 6)
    trackBg.Position = Vector2.new(self.X + 15, self.Y + self.ContentY - 45 + 25)
    trackBg.Color = SimplePUI.Theme.Section
    trackBg.Filled = true
    trackBg.Transparency = 0.95
    trackBg.Visible = SimplePUI.Visible
    trackBg.ZIndex = 5
    container.Objects.TrackBg = trackBg
    
    -- Calculate initial fill position
    local percent = (default - min) / (max - min)
    local fillWidth = (self.Width - 30) * percent
    
    -- Slider fill
    local fill = AddDrawing(Drawing.new("Square"))
    fill.Size = Vector2.new(fillWidth, 6)
    fill.Position = Vector2.new(self.X + 15, self.Y + self.ContentY - 45 + 25)
    fill.Color = SimplePUI.Theme.Accent
    fill.Filled = true
    fill.Transparency = 1
    fill.Visible = SimplePUI.Visible
    fill.ZIndex = 6
    container.Objects.Fill = fill
    
    -- Slider knob
    local knob = AddDrawing(Drawing.new("Square"))
    knob.Size = Vector2.new(8, 14)
    knob.Position = Vector2.new(self.X + 15 + fillWidth - 4, self.Y + self.ContentY - 45 + 21)
    knob.Color = SimplePUI.Theme.Text
    knob.Filled = true
    knob.Transparency = 1
    knob.Visible = SimplePUI.Visible
    knob.ZIndex = 7
    container.Objects.Knob = knob
    
    -- Logic
    local sliding = false
    
    local slider = {
        Value = default,
        Min = min,
        Max = max,
        Update = function(self, mouseX)
            local trackStart = trackBg.Position.X
            local trackEnd = trackBg.Position.X + trackBg.Size.X
            local trackWidth = trackBg.Size.X
            
            local relativeX = math.clamp(mouseX - trackStart, 0, trackWidth)
            local percent = relativeX / trackWidth
            local newValue = min + ((max - min) * percent)
            newValue = Round(newValue, 1)
            
            self.Value = newValue
            fill.Size = Vector2.new(relativeX, 6)
            knob.Position = Vector2.new(trackStart + relativeX - 4, knob.Position.Y)
            value.Text = tostring(newValue)
            
            callback(newValue)
        end,
        Container = container
    }
    
    -- Handle interaction
    table.insert(self.Elements, {
        Type = "Slider",
        Instance = slider,
        Container = trackBg,
        OnMouseDown = function()
            sliding = true
        end,
        OnMouseUp = function()
            sliding = false
        end,
        OnDrag = function(input)
            if sliding then
                slider:Update(input.Position.X)
            end
        end
    })
    
    table.insert(SimplePUI.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and IsMouseOver(trackBg) then
            sliding = true
            slider:Update(UserInputService:GetMouseLocation().X)
        end
    end))
    
    table.insert(SimplePUI.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end))
    
    table.insert(SimplePUI.Connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and sliding then
            slider:Update(input.Position.X)
        end
    end))
    
    return slider
end

function Window:Button(name, callback)
    callback = callback or function() end
    
    -- Create container
    local container = self:_createElementContainer(25)
    
    -- Button text (centered)
    local text = CreateText(name, Vector2.new(self.X + (self.Width / 2), self.Y + self.ContentY - 30 + 5), nil, nil, true)
    container.Objects.Text = text
    
    -- Button hover effect
    local hovered = false
    local pressed = false
    
    local function updateColor()
        if pressed then
            container.Container.Color = SimplePUI.Theme.Accent
        elseif hovered then
            container.Container.Color = SimplePUI.Theme.ButtonHover
        else
            container.Container.Color = SimplePUI.Theme.Button
        end
    end
    
    -- Logic
    local button = {
        Hover = function(self, isHovered)
            hovered = isHovered
            updateColor()
        end,
        Press = function(self)
            pressed = true
            updateColor()
            callback()
            task.delay(0.15, function()
                pressed = false
                updateColor()
            end)
        end,
        Container = container
    }
    
    -- Handle clicks
    table.insert(self.Elements, {
        Type = "Button",
        Instance = button,
        Container = container.Container,
        OnClick = function()
            button:Press()
        end,
        OnHover = function(hovering)
            button:Hover(hovering)
        end
    })
    
    return button
end

function Window:Dropdown(name, items, callback)
    callback = callback or function() end
    items = items or {"Item 1", "Item 2", "Item 3"}
    local default = items[1]
    
    -- Create container
    local container = self:_createElementContainer(25)
    container.Objects.Items = {}
    
    -- Label text
    local text = CreateText(name .. ": " .. default, Vector2.new(self.X + 15, self.Y + self.ContentY - 30 + 5))
    container.Objects.Text = text
    
    -- Arrow indicator
    local arrow = CreateText("▼", Vector2.new(self.X + self.Width - 25, self.Y + self.ContentY - 30 + 5))
    container.Objects.Arrow = arrow
    
    -- Create dropdown menu container (hidden initially)
    local menuContainer = AddDrawing(Drawing.new("Square"))
    menuContainer.Size = Vector2.new(self.Width - 20, #items * 25)
    menuContainer.Position = Vector2.new(self.X + 10, self.Y + self.ContentY - 30 + 30)
    menuContainer.Color = SimplePUI.Theme.Section
    menuContainer.Filled = true
    menuContainer.Transparency = 0.95
    menuContainer.Visible = false
    menuContainer.ZIndex = 10
    container.Objects.Menu = menuContainer
    
    -- Create menu items
    local menuItems = {}
    for i, itemName in ipairs(items) do
        local itemY = self.Y + self.ContentY - 30 + 30 + ((i - 1) * 25)
        
        local itemContainer = AddDrawing(Drawing.new("Square"))
        itemContainer.Size = Vector2.new(self.Width - 20, 25)
        itemContainer.Position = Vector2.new(self.X + 10, itemY)
        itemContainer.Color = itemName == default and SimplePUI.Theme.Accent or SimplePUI.Theme.Element
        itemContainer.Filled = true
        itemContainer.Transparency = 0.95
        itemContainer.Visible = false
        itemContainer.ZIndex = 11
        
        local itemText = CreateText(itemName, Vector2.new(self.X + 15, itemY + 5), nil, itemName == default and SimplePUI.Theme.Text or SimplePUI.Theme.DarkText)
        itemText.Visible = false
        
        table.insert(menuItems, {
            Name = itemName,
            Container = itemContainer,
            Text = itemText,
            Y = itemY
        })
        
        container.Objects.Items[i] = {Container = itemContainer, Text = itemText}
    end
    
    -- Logic
    local dropdown = {
        Selected = default,
        Items = menuItems,
        ItemsList = items,
        Open = false,
        Container = container,
        Update = function(self, value)
            if not table.find(self.ItemsList, value) then return end
            
            self.Selected = value
            text.Text = name .. ": " .. value
            
            for _, item in ipairs(self.Items) do
                item.Container.Color = item.Name == value and SimplePUI.Theme.Accent or SimplePUI.Theme.Element
                item.Text.Color = item.Name == value and SimplePUI.Theme.Text or SimplePUI.Theme.DarkText
            end
            
            callback(value)
        end,
        Toggle = function(self)
            self.Open = not self.Open
            
            menuContainer.Visible = self.Open
            for _, item in ipairs(self.Items) do
                item.Container.Visible = self.Open
                item.Text.Visible = self.Open
            end
            
            arrow.Text = self.Open and "▲" or "▼"
        end
    }
    
    -- Handle main dropdown click
    table.insert(self.Elements, {
        Type = "Dropdown",
        Instance = dropdown,
        Container = container.Container,
        OnClick = function()
            dropdown:Toggle()
        end
    })
    
    -- Handle item clicks
    for i, item in ipairs(menuItems) do
        table.insert(self.Elements, {
            Type = "DropdownItem",
            Instance = {
                Dropdown = dropdown,
                Item = item
            },
            Container = item.Container,
            OnClick = function()
                dropdown:Update(item.Name)
                dropdown:Toggle()
            end,
            Visible = function() return dropdown.Open end
        })
    end
    
    return dropdown
end

function Window:Label(text, color)
    -- Create container (no background)
    local container = {
        ElementHeight = 20,
        Objects = {}
    }
    
    -- Label text
    local label = CreateText(text, Vector2.new(self.X + 15, self.Y + self.ContentY + 5), nil, color or SimplePUI.Theme.Text)
    container.Objects.Label = label
    
    self.ContentY = self.ContentY + 25
    
    -- Return interface
    return {
        Text = label,
        SetText = function(self, newText)
            self.Text.Text = newText
        end
    }
end

function Window:Section(name)
    -- Create section header
    local container = self:_createElementContainer(25)
    
    -- Section text
    local label = CreateText(name, Vector2.new(self.X + 15, self.Y + self.ContentY - 30 + 5), nil, SimplePUI.Theme.Accent)
    container.Objects.Label = label
    
    -- Section accent line
    local line = AddDrawing(Drawing.new("Square"))
    line.Size = Vector2.new(3, 25)
    line.Position = Vector2.new(self.X + 10, self.Y + self.ContentY - 30)
    line.Color = SimplePUI.Theme.Accent
    line.Filled = true
    line.Transparency = 1
    line.Visible = SimplePUI.Visible
    line.ZIndex = 4
    container.Objects.Line = line
    
    -- Add spacing after section
    self.ContentY = self.ContentY + 5
    
    return container
end

-- Create a window
function SimplePUI:Window(title, options)
    options = options or {}
    local size = options.size or Vector2.new(300, 350)
    local position = options.position or Vector2.new(50, 50)
    
    -- Create window container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = size
    container.Position = position
    container.Color = self.Theme.Background
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = self.Visible
    container.ZIndex = 1
    
    -- Create window border
    local border = AddDrawing(Drawing.new("Square"))
    border.Size = size
    border.Position = position
    border.Color = self.Theme.Border
    border.Filled = false
    border.Thickness = 1
    border.Transparency = 1
    border.Visible = self.Visible
    border.ZIndex = 2
    
    -- Create title bar
    local titleBar = AddDrawing(Drawing.new("Square"))
    titleBar.Size = Vector2.new(size.X, 25)
    titleBar.Position = position
    titleBar.Color = self.Theme.Section
    titleBar.Filled = true
    titleBar.Transparency = 0.95
    titleBar.Visible = self.Visible
    titleBar.ZIndex = 2
    
    -- Create title text
    local titleText = CreateText(title, Vector2.new(position.X + 10, position.Y + 5))
    
    -- Create window object
    local window = setmetatable({
        Container = container,
        Border = border,
        TitleBar = titleBar,
        TitleText = titleText,
        X = position.X,
        Y = position.Y,
        Width = size.X,
        Height = size.Y,
        ContentY = 35, -- Start content below title bar
        Elements = {},
        Dragging = false,
        DragOffset = Vector2.new(0, 0)
    }, Window)
    
    -- Add dragging functionality
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and IsMouseOver(titleBar) then
            window.Dragging = true
            window.DragOffset = UserInputService:GetMouseLocation() - position
        end
    end))
    
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.Dragging = false
        end
    end))
    
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and window.Dragging then
            local newPos = UserInputService:GetMouseLocation() - window.DragOffset
            window:_updatePosition(newPos)
        end
    end))
    
    -- Add window to list
    table.insert(self.Windows, window)
    
    -- Override update position method
    function window:_updatePosition(newPos)
        local screenSize = workspace.CurrentCamera.ViewportSize
        newPos = Vector2.new(
            math.clamp(newPos.X, 0, screenSize.X - self.Width),
            math.clamp(newPos.Y, 0, screenSize.Y - self.Height)
        )
        
        local delta = newPos - Vector2.new(self.X, self.Y)
        self.X = newPos.X
        self.Y = newPos.Y
        
        -- Update window elements
        self.Container.Position = newPos
        self.Border.Position = newPos
        self.TitleBar.Position = newPos
        self.TitleText.Position = newPos + Vector2.new(10, 5)
        
        -- Update all elements inside
        for _, element in pairs(self.Elements) do
            if element.Container then
                element.Container.Position = element.Container.Position + delta
                
                -- Update child objects depending on element type
                if element.Type == "Toggle" then
                    local container = element.Instance.Container
                    for _, obj in pairs(container.Objects) do
                        if obj.Position then
                            obj.Position = obj.Position + delta
                        end
                    end
                elseif element.Type == "Slider" then
                    local container = element.Instance.Container
                    for _, obj in pairs(container.Objects) do
                        if obj.Position then
                            obj.Position = obj.Position + delta
                        end
                    end
                elseif element.Type == "Button" then
                    local container = element.Instance.Container
                    for _, obj in pairs(container.Objects) do
                        if obj.Position then
                            obj.Position = obj.Position + delta
                        end
                    end
                elseif element.Type == "Dropdown" then
                    local container = element.Instance.Container
                    for k, obj in pairs(container.Objects) do
                        if k == "Items" then
                            for _, item in pairs(obj) do
                                if item.Container and item.Container.Position then
                                    item.Container.Position = item.Container.Position + delta
                                end
                                if item.Text and item.Text.Position then
                                    item.Text.Position = item.Text.Position + delta
                                end
                            end
                        elseif obj.Position then
                            obj.Position = obj.Position + delta
                        end
                    end
                    
                    -- Also update dropdown items Y position
                    for _, item in ipairs(element.Instance.Items) do
                        item.Y = item.Y + delta.Y
                        item.Container.Position = item.Container.Position + delta
                        item.Text.Position = item.Text.Position + delta
                    end
                end
            end
        end
    end
    
    return window
end

-- Update hover effects
function SimplePUI:Update()
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, window in pairs(self.Windows) do
        -- Handle hover effects
        for _, element in pairs(window.Elements) do
            local visible = true
            if element.Visible then
                visible = element.Visible()
            end
            
            if visible and element.Container and element.OnHover then
                local hovering = IsMouseOver(element.Container)
                element.OnHover(hovering)
            end
        end
    end
end

-- Initialize mouse handling
function SimplePUI:Init()
    -- Handle clicks
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            for _, window in pairs(self.Windows) do
                for _, element in pairs(window.Elements) do
                    local visible = true
                    if element.Visible then
                        visible = element.Visible()
                    end
                    
                    if visible and element.Container and IsMouseOver(element.Container) then
                        if element.OnClick then
                            element.OnClick()
                        end
                    end
                end
            end
        end
    end))
    
    -- Toggle UI visibility with key
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.ToggleKey then
            self:ToggleVisibility()
        end
    end))
    
    -- Update on render step
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        self:Update()
    end))
    
    return self
end

-- Toggle visibility of the entire UI
function SimplePUI:ToggleVisibility()
    self.Visible = not self.Visible
    
    for _, drawing in pairs(self.Drawings) do
        if drawing and drawing.Visible ~= nil then
            drawing.Visible = self.Visible
        end
    end
end

-- Clean up all resources
function SimplePUI:Destroy()
    -- Disconnect all events
    for _, connection in pairs(self.Connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    -- Remove all drawings
    for _, drawing in pairs(self.Drawings) do
        pcall(function()
            if drawing and typeof(drawing) == "table" and drawing.Remove then
                drawing:Remove()
            elseif drawing and drawing.Destroy then
                drawing:Destroy()
            end
        end)
    end
    
    -- Clear tables
    self.Drawings = {}
    self.Windows = {}
    self.Connections = {}
end

-- Return initialized library
return SimplePUI:Init()
