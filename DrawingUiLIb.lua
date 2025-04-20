--[[
    Phantom UI Library (Tabbed Version)
    A lightweight UI library with proper tab system using Drawing API
]]

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Library
local Library = {
    Drawings = {},
    Connections = {},
    Theme = {
        Window = {
            Background = Color3.fromRGB(25, 25, 35),
            TopBar = Color3.fromRGB(30, 30, 40),
            Border = Color3.fromRGB(50, 50, 70),
        },
        Tab = {
            Active = Color3.fromRGB(60, 60, 120),
            Inactive = Color3.fromRGB(40, 40, 60),
            Accent = Color3.fromRGB(100, 100, 255),
            Text = Color3.fromRGB(255, 255, 255),
            DimText = Color3.fromRGB(170, 170, 185)
        },
        Element = {
            Background = Color3.fromRGB(35, 35, 50),
            ButtonBackground = Color3.fromRGB(45, 45, 65),
            SliderBackground = Color3.fromRGB(30, 30, 45),
            SliderFill = Color3.fromRGB(100, 100, 255),
            SliderValue = Color3.fromRGB(120, 120, 255),
            ToggleBackground = Color3.fromRGB(35, 35, 50),
            ToggleEnabled = Color3.fromRGB(100, 100, 255),
            ToggleDisabled = Color3.fromRGB(65, 65, 85),
            Text = Color3.fromRGB(255, 255, 255),
            SubText = Color3.fromRGB(180, 180, 195),
            Border = Color3.fromRGB(60, 60, 80),
            Hover = Color3.fromRGB(55, 55, 75)
        }
    },
    Windows = {},
    ToggleKey = Enum.KeyCode.RightShift,
    Visible = true,
    ActiveWindow = nil,
    DraggingWindow = nil,
    DraggingSlider = nil,
    ActiveDropdown = nil,
    Font = 2, -- SourceSans
    FontBold = 3 -- SourceSansBold
}

-- Utility Functions
local function AddDrawing(drawing)
    table.insert(Library.Drawings, drawing)
    return drawing
end

local function Round(number, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor(number * power + 0.5) / power
end

local function IsInBounds(point, position, size)
    return point.X >= position.X and point.X <= position.X + size.X and 
           point.Y >= position.Y and point.Y <= position.Y + size.Y
end

-- Drawing utility functions
local function CreateSquare(options)
    local square = AddDrawing(Drawing.new("Square"))
    square.Visible = Library.Visible
    square.Transparency = options.Transparency or 1
    square.Color = options.Color or Library.Theme.Window.Background
    square.Size = options.Size or Vector2.new(100, 100)
    square.Position = options.Position or Vector2.new(0, 0)
    square.Filled = options.Filled ~= nil and options.Filled or true
    square.Thickness = options.Thickness or 1
    square.ZIndex = options.ZIndex or 1
    return square
end

local function CreateText(options)
    local text = AddDrawing(Drawing.new("Text"))
    text.Visible = Library.Visible
    text.Transparency = options.Transparency or 1
    text.Color = options.Color or Library.Theme.Element.Text
    text.Text = options.Text or ""
    text.Size = options.Size or 13
    text.Center = options.Center or false
    text.Outline = options.Outline or false
    text.Position = options.Position or Vector2.new(0, 0)
    text.Font = options.Font or Library.Font
    text.ZIndex = options.ZIndex or 2
    return text
end

local function CreateShadowedText(options)
    local shadow = CreateText({
        Text = options.Text or "",
        Position = (options.Position or Vector2.new(0, 0)) + Vector2.new(1, 1),
        Size = options.Size or 13,
        Color = Color3.fromRGB(0, 0, 0),
        Center = options.Center or false,
        Transparency = (options.Transparency or 1) * 0.75,
        Font = options.Font or Library.Font,
        ZIndex = (options.ZIndex or 2) - 1
    })
    
    local text = CreateText(options)
    
    return {
        Text = text,
        Shadow = shadow,
        SetText = function(self, newText)
            text.Text = newText
            shadow.Text = newText
        end,
        SetPosition = function(self, newPos)
            text.Position = newPos
            shadow.Position = newPos + Vector2.new(1, 1)
        end,
        SetVisible = function(self, visible)
            text.Visible = visible
            shadow.Visible = visible
        end,
        Remove = function(self)
            text:Remove()
            shadow:Remove()
        end
    }
end

-- Tab Class
local Tab = {}
Tab.__index = Tab

function Tab:AddElement(elementType, options)
    -- Ensure yOffset exists and is valid
    options = options or {}
    options.Parent = self
    options.Y = self.ContentY
    
    local element
    
    if elementType == "Toggle" then
        element = self.Window:CreateToggle(options)
        self.ContentY = self.ContentY + 30
    elseif elementType == "Slider" then
        element = self.Window:CreateSlider(options)
        self.ContentY = self.ContentY + 45
    elseif elementType == "Button" then
        element = self.Window:CreateButton(options)
        self.ContentY = self.ContentY + 30
    elseif elementType == "Dropdown" then
        element = self.Window:CreateDropdown(options)
        self.ContentY = self.ContentY + 30
    elseif elementType == "Label" then
        element = self.Window:CreateLabel(options)
        self.ContentY = self.ContentY + 20
    elseif elementType == "Keybind" then
        element = self.Window:CreateKeybind(options)
        self.ContentY = self.ContentY + 30
    end
    
    table.insert(self.Elements, element)
    return element
end

function Tab:UpdateVisibility(visible)
    for _, element in ipairs(self.Elements) do
        element:SetVisible(visible)
    end
end

-- Window Class
local Window = {}
Window.__index = Window

function Window:CreateTab(name)
    local tabIndex = #self.Tabs + 1
    local tabWidth = self.Width / (#self.Tabs + 1)
    
    -- Update all tab buttons width
    for i, tab in ipairs(self.Tabs) do
        tab.Button.Size = Vector2.new(tabWidth, 25)
        tab.Button.Position = Vector2.new(self.X + (i-1) * tabWidth, self.Y + 30)
        
        if tab.Text then
            tab.Text:SetPosition(Vector2.new(
                self.X + (i-1) * tabWidth + (tabWidth/2),
                self.Y + 35
            ))
        end
        
        if tab.Indicator then
            tab.Indicator.Size = Vector2.new(tabWidth, 2)
            tab.Indicator.Position = Vector2.new(self.X + (i-1) * tabWidth, self.Y + 55)
        end
    end
    
    -- Create tab button
    local tabButton = CreateSquare({
        Size = Vector2.new(tabWidth, 25),
        Position = Vector2.new(self.X + (tabIndex-1) * tabWidth, self.Y + 30),
        Color = self.ActiveTab == name and Library.Theme.Tab.Active or Library.Theme.Tab.Inactive,
        ZIndex = 3
    })
    
    -- Tab label
    local tabText = CreateShadowedText({
        Text = name,
        Position = Vector2.new(self.X + (tabIndex-1) * tabWidth + (tabWidth/2), self.Y + 35),
        Size = 14,
        Center = true,
        Color = self.ActiveTab == name and Library.Theme.Tab.Text or Library.Theme.Tab.DimText,
        ZIndex = 4
    })
    
    -- Tab accent indicator
    local tabIndicator = CreateSquare({
        Size = Vector2.new(tabWidth, 2),
        Position = Vector2.new(self.X + (tabIndex-1) * tabWidth, self.Y + 55),
        Color = Library.Theme.Tab.Accent,
        Transparency = self.ActiveTab == name and 1 or 0,
        ZIndex = 4
    })
    
    -- Create tab object
    local tab = setmetatable({
        Name = name,
        Window = self,
        Button = tabButton,
        Text = tabText,
        Indicator = tabIndicator,
        Elements = {},
        ContentY = 65, -- Start position for elements (below tab bar)
        Visible = self.ActiveTab == name
    }, Tab)
    
    -- Add tab to window
    table.insert(self.Tabs, tab)
    self.TabObjects[name] = tab
    
    -- Handle tab button click
    table.insert(self.Interactables, {
        Type = "TabButton",
        Object = tab,
        Bounds = {
            Min = tabButton.Position,
            Max = tabButton.Position + tabButton.Size
        },
        OnClick = function()
            self:SelectTab(name)
        end
    })
    
    -- Select first tab if none active
    if not self.ActiveTab then
        self:SelectTab(name)
    end
    
    return tab
end

function Window:SelectTab(name)
    -- Skip if already selected
    if self.ActiveTab == name then return end
    
    self.ActiveTab = name
    
    -- Update tab visuals
    for _, tab in ipairs(self.Tabs) do
        local isActive = tab.Name == name
        
        tab.Button.Color = isActive and Library.Theme.Tab.Active or Library.Theme.Tab.Inactive
        tab.Text.Text.Color = isActive and Library.Theme.Tab.Text or Library.Theme.Tab.DimText
        tab.Indicator.Transparency = isActive and 1 or 0
        
        -- Update tab elements visibility
        tab:UpdateVisibility(isActive)
    end
end

function Window:CreateToggle(options)
    local parent = options.Parent
    local name = options.Name or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function() end
    
    -- Container
    local container = CreateSquare({
        Size = Vector2.new(self.Width - 20, 25),
        Position = Vector2.new(self.X + 10, self.Y + options.Y),
        Color = Library.Theme.Element.ToggleBackground,
        ZIndex = 3,
        Visible = parent.Visible
    })
    
    -- Toggle text
    local text = CreateShadowedText({
        Text = name,
        Position = Vector2.new(self.X + 20, self.Y + options.Y + 5),
        Size = 14,
        Color = Library.Theme.Element.Text,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Toggle indicator background
    local indicatorBg = CreateSquare({
        Size = Vector2.new(16, 16),
        Position = Vector2.new(self.X + self.Width - 35, self.Y + options.Y + 4.5),
        Color = Library.Theme.Element.Border,
        ZIndex = 4,
        Filled = false,
        Thickness = 1,
        Visible = parent.Visible
    })
    
    -- Toggle indicator
    local indicator = CreateSquare({
        Size = Vector2.new(10, 10),
        Position = Vector2.new(self.X + self.Width - 32, self.Y + options.Y + 7.5),
        Color = default and Library.Theme.Element.ToggleEnabled or Library.Theme.Element.ToggleDisabled,
        Transparency = default and 1 or 0.6,
        ZIndex = 5,
        Visible = parent.Visible
    })
    
    -- Create toggle object
    local toggle = {
        Type = "Toggle",
        Container = container,
        Text = text,
        IndicatorBg = indicatorBg,
        Indicator = indicator,
        Value = default,
        Callback = callback,
        SetValue = function(self, value)
            self.Value = value
            self.Indicator.Color = value and Library.Theme.Element.ToggleEnabled or Library.Theme.Element.ToggleDisabled
            self.Indicator.Transparency = value and 1 or 0.6
            callback(value)
        end,
        SetVisible = function(self, visible)
            self.Container.Visible = visible
            self.Text:SetVisible(visible)
            self.IndicatorBg.Visible = visible
            self.Indicator.Visible = visible
        end
    }
    
    -- Add to interactables
    table.insert(self.Interactables, {
        Type = "Toggle",
        Object = toggle,
        Bounds = {
            Min = container.Position,
            Max = container.Position + container.Size
        },
        OnClick = function()
            toggle:SetValue(not toggle.Value)
        end
    })
    
    return toggle
end

function Window:CreateSlider(options)
    local parent = options.Parent
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = math.clamp(options.Default or min, min, max)
    local callback = options.Callback or function() end
    local decimals = options.Decimals or 0
    
    -- Container
    local container = CreateSquare({
        Size = Vector2.new(self.Width - 20, 40),
        Position = Vector2.new(self.X + 10, self.Y + options.Y),
        Color = Library.Theme.Element.Background,
        ZIndex = 3,
        Visible = parent.Visible
    })
    
    -- Slider text
    local text = CreateShadowedText({
        Text = name,
        Position = Vector2.new(self.X + 20, self.Y + options.Y + 5),
        Size = 14,
        Color = Library.Theme.Element.Text,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Slider value
    local valueText = CreateShadowedText({
        Text = tostring(Round(default, decimals)),
        Position = Vector2.new(self.X + self.Width - 45, self.Y + options.Y + 5),
        Size = 14,
        Color = Library.Theme.Element.SliderValue,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Slider track background
    local track = CreateSquare({
        Size = Vector2.new(self.Width - 30, 6),
        Position = Vector2.new(self.X + 15, self.Y + options.Y + 25),
        Color = Library.Theme.Element.SliderBackground,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Calculate initial fill width
    local percent = (default - min) / (max - min)
    local fillWidth = (self.Width - 30) * percent
    
    -- Slider track fill
    local fill = CreateSquare({
        Size = Vector2.new(fillWidth, 6),
        Position = Vector2.new(self.X + 15, self.Y + options.Y + 25),
        Color = Library.Theme.Element.SliderFill,
        ZIndex = 5,
        Visible = parent.Visible
    })
    
    -- Slider knob
    local knob = CreateSquare({
        Size = Vector2.new(10, 14),
        Position = Vector2.new(self.X + 15 + fillWidth - 5, self.Y + options.Y + 21),
        Color = Library.Theme.Element.Text,
        ZIndex = 6,
        Visible = parent.Visible
    })
    
    -- Create slider object
    local slider = {
        Type = "Slider",
        Container = container,
        Text = text,
        ValueText = valueText,
        Track = track,
        Fill = fill,
        Knob = knob,
        Min = min,
        Max = max,
        Value = default,
        Decimals = decimals,
        Callback = callback,
        SetValue = function(self, value, updateVisuals)
            value = math.clamp(value, self.Min, self.Max)
            self.Value = value
            
            if updateVisuals ~= false then
                local percent = (value - self.Min) / (self.Max - self.Min)
                local fillWidth = (Window.Width - 30) * percent
                
                self.Fill.Size = Vector2.new(fillWidth, 6)
                self.Knob.Position = Vector2.new(self.Container.Position.X + 5 + fillWidth, self.Knob.Position.Y)
            end
            
            self.ValueText:SetText(tostring(Round(value, self.Decimals)))
            
            callback(value)
        end,
        SetVisible = function(self, visible)
            self.Container.Visible = visible
            self.Text:SetVisible(visible)
            self.ValueText:SetVisible(visible)
            self.Track.Visible = visible
            self.Fill.Visible = visible
            self.Knob.Visible = visible
        end
    }
    
    -- Add to interactables
    table.insert(self.Interactables, {
        Type = "Slider",
        Object = slider,
        Bounds = {
            Min = track.Position,
            Max = track.Position + track.Size + Vector2.new(0, 10)
        },
        OnClick = function()
            Library.DraggingSlider = slider
        end,
        OnDrag = function(input)
            if Library.DraggingSlider == slider then
                local relX = math.clamp(input.Position.X - slider.Track.Position.X, 0, slider.Track.Size.X)
                local percent = relX / slider.Track.Size.X
                local value = slider.Min + ((slider.Max - slider.Min) * percent)
                slider:SetValue(value)
            end
        end
    })
    
    return slider
end

function Window:CreateButton(options)
    local parent = options.Parent
    local name = options.Name or "Button"
    local callback = options.Callback or function() end
    
    -- Container
    local container = CreateSquare({
        Size = Vector2.new(self.Width - 20, 25),
        Position = Vector2.new(self.X + 10, self.Y + options.Y),
        Color = Library.Theme.Element.ButtonBackground,
        ZIndex = 3,
        Visible = parent.Visible
    })
    
    -- Button text
    local text = CreateShadowedText({
        Text = name,
        Position = Vector2.new(self.X + (self.Width / 2), self.Y + options.Y + 5),
        Size = 14,
        Center = true,
        Color = Library.Theme.Element.Text,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Create button object
    local button = {
        Type = "Button",
        Container = container,
        Text = text,
        OriginalColor = Library.Theme.Element.ButtonBackground,
        Callback = callback,
        SetVisible = function(self, visible)
            self.Container.Visible = visible
            self.Text:SetVisible(visible)
        end
    }
    
    -- Add to interactables
    table.insert(self.Interactables, {
        Type = "Button",
        Object = button,
        Bounds = {
            Min = container.Position,
            Max = container.Position + container.Size
        },
        OnClick = function()
            -- Flash effect
            button.Container.Color = Library.Theme.Tab.Accent
            callback()
            task.delay(0.2, function()
                button.Container.Color = button.OriginalColor
            end)
        end,
        OnHover = function(isHovering)
            button.Container.Color = isHovering and Library.Theme.Element.Hover or button.OriginalColor
        end
    })
    
    return button
end

function Window:CreateDropdown(options)
    local parent = options.Parent
    local name = options.Name or "Dropdown"
    local items = options.Items or {"Item 1", "Item 2", "Item 3"}
    local default = options.Default or items[1]
    local callback = options.Callback or function() end
    
    -- Container
    local container = CreateSquare({
        Size = Vector2.new(self.Width - 20, 25),
        Position = Vector2.new(self.X + 10, self.Y + options.Y),
        Color = Library.Theme.Element.ButtonBackground,
        ZIndex = 3,
        Visible = parent.Visible
    })
    
    -- Dropdown text
    local text = CreateShadowedText({
        Text = name .. ": " .. default,
        Position = Vector2.new(self.X + 20, self.Y + options.Y + 5),
        Size = 14,
        Color = Library.Theme.Element.Text,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Dropdown arrow
    local arrow = CreateShadowedText({
        Text = "▼",
        Position = Vector2.new(self.X + self.Width - 25, self.Y + options.Y + 5),
        Size = 14,
        Color = Library.Theme.Element.Text,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Create dropdown object
    local dropdown = {
        Type = "Dropdown",
        Container = container,
        Text = text,
        Arrow = arrow,
        Items = {},
        AllItems = items,
        Selected = default,
        Open = false,
        Callback = callback,
        SetValue = function(self, value)
            if not table.find(self.AllItems, value) then return end
            
            self.Selected = value
            self.Text:SetText(name .. ": " .. value)
            self:CloseMenu()
            
            callback(value)
        end,
        CreateMenu = function(self)
            if self.Menu then self:CloseMenu() end
            
            local menuHeight = #items * 25
            
            -- Create menu container
            self.Menu = CreateSquare({
                Size = Vector2.new(self.Container.Size.X, menuHeight),
                Position = Vector2.new(self.Container.Position.X, self.Container.Position.Y + self.Container.Size.Y),
                Color = Library.Theme.Element.Background,
                ZIndex = 20,
                Visible = true
            })
            
            -- Create menu border
            self.MenuBorder = CreateSquare({
                Size = Vector2.new(self.Container.Size.X, menuHeight),
                Position = Vector2.new(self.Container.Position.X, self.Container.Position.Y + self.Container.Size.Y),
                Color = Library.Theme.Element.Border,
                ZIndex = 19,
                Filled = false,
                Thickness = 1,
                Visible = true
            })
            
            -- Create menu items
            self.Items = {}
            
            for i, itemName in ipairs(items) do
                local itemY = self.Container.Position.Y + self.Container.Size.Y + ((i-1) * 25)
                
                local itemContainer = CreateSquare({
                    Size = Vector2.new(self.Container.Size.X, 25),
                    Position = Vector2.new(self.Container.Position.X, itemY),
                    Color = itemName == self.Selected and Library.Theme.Tab.Accent or Library.Theme.Element.ButtonBackground,
                    ZIndex = 21,
                    Visible = true
                })
                
                local itemText = CreateShadowedText({
                    Text = itemName,
                    Position = Vector2.new(self.Container.Position.X + 10, itemY + 5),
                    Size = 14,
                    Color = Library.Theme.Element.Text,
                    ZIndex = 22,
                    Visible = true
                })
                
                local item = {
                    Container = itemContainer,
                    Text = itemText,
                    Value = itemName
                }
                
                table.insert(self.Items, item)
                
                -- Add to interactables
                table.insert(Window.Interactables, {
                    Type = "DropdownItem",
                    Object = {
                        Dropdown = self,
                        Item = item
                    },
                    Bounds = {
                        Min = itemContainer.Position,
                        Max = itemContainer.Position + itemContainer.Size
                    },
                    OnClick = function()
                        self:SetValue(itemName)
                    end,
                    Visible = function() return self.Open end
                })
            end
            
            self.Open = true
            self.Arrow:SetText("▲")
            Library.ActiveDropdown = self
        end,
        CloseMenu = function(self)
            if not self.Menu then return end
            
            -- Remove menu items from interactables
            for i = #Window.Interactables, 1, -1 do
                local interactable = Window.Interactables[i]
                if interactable.Type == "DropdownItem" and interactable.Object.Dropdown == self then
                    table.remove(Window.Interactables, i)
                end
            end
            
            -- Remove menu visuals
            self.Menu:Remove()
            self.MenuBorder:Remove()
            
            for _, item in ipairs(self.Items) do
                item.Container:Remove()
                item.Text:Remove()
            end
            
            self.Menu = nil
            self.MenuBorder = nil
            self.Items = {}
            
            self.Open = false
            self.Arrow:SetText("▼")
            
            if Library.ActiveDropdown == self then
                Library.ActiveDropdown = nil
            end
        end,
        ToggleMenu = function(self)
            if self.Open then
                self:CloseMenu()
            else
                -- Close any other open dropdown
                if Library.ActiveDropdown and Library.ActiveDropdown ~= self then
                    Library.ActiveDropdown:CloseMenu()
                end
                
                self:CreateMenu()
            end
        end,
        SetVisible = function(self, visible)
            self.Container.Visible = visible
            self.Text:SetVisible(visible)
            self.Arrow:SetVisible(visible)
            
            if not visible and self.Open then
                self:CloseMenu()
            end
        end
    }
    
    -- Add to interactables
    table.insert(self.Interactables, {
        Type = "Dropdown",
        Object = dropdown,
        Bounds = {
            Min = container.Position,
            Max = container.Position + container.Size
        },
        OnClick = function()
            dropdown:ToggleMenu()
        end
    })
    
    return dropdown
end

function Window:CreateLabel(options)
    local parent = options.Parent
    local text = options.Text or "Label"
    local color = options.Color or Library.Theme.Element.Text
    
    -- Label text
    local label = CreateShadowedText({
        Text = text,
        Position = Vector2.new(self.X + 15, self.Y + options.Y),
        Size = 14,
        Color = color,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Create label object
    local labelObj = {
        Type = "Label",
        Text = label,
        SetText = function(self, newText)
            self.Text:SetText(newText)
        end,
        SetVisible = function(self, visible)
            self.Text:SetVisible(visible)
        end
    }
    
    return labelObj
end

function Window:CreateKeybind(options)
    local parent = options.Parent
    local name = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.F
    local callback = options.Callback or function() end
    
    -- Format key name
    local keyName = tostring(default):gsub("Enum.KeyCode.", "")
    
    -- Container
    local container = CreateSquare({
        Size = Vector2.new(self.Width - 20, 25),
        Position = Vector2.new(self.X + 10, self.Y + options.Y),
        Color = Library.Theme.Element.Background,
        ZIndex = 3,
        Visible = parent.Visible
    })
    
    -- Keybind text
    local text = CreateShadowedText({
        Text = name,
        Position = Vector2.new(self.X + 20, self.Y + options.Y + 5),
        Size = 14,
        Color = Library.Theme.Element.Text,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Key display
    local keyDisplay = CreateShadowedText({
        Text = "[" .. keyName .. "]",
        Position = Vector2.new(self.X + self.Width - 50, self.Y + options.Y + 5),
        Size = 14,
        Color = Library.Theme.Element.SliderValue,
        ZIndex = 4,
        Visible = parent.Visible
    })
    
    -- Create keybind object
    local keybind = {
        Type = "Keybind",
        Container = container,
        Text = text,
        KeyDisplay = keyDisplay,
        Key = default,
        Listening = false,
        Callback = callback,
        SetKey = function(self, key)
            self.Key = key
            local keyName = tostring(key):gsub("Enum.KeyCode.", "")
            self.KeyDisplay:SetText("[" .. keyName .. "]")
            self.Listening = false
            self.Container.Color = Library.Theme.Element.Background
            
            callback(key)
        end,
        StartListening = function(self)
            self.Listening = true
            self.KeyDisplay:SetText("[...]")
            self.Container.Color = Library.Theme.Tab.Accent
            
            Library.ActiveKeybind = self
        end,
        SetVisible = function(self, visible)
            self.Container.Visible = visible
            self.Text:SetVisible(visible)
            self.KeyDisplay:SetVisible(visible)
        end
    }
    
    -- Add to interactables
    table.insert(self.Interactables, {
        Type = "Keybind",
        Object = keybind,
        Bounds = {
            Min = container.Position,
            Max = container.Position + container.Size
        },
        OnClick = function()
            if not keybind.Listening then
                keybind:StartListening()
            end
        end
    })
    
    -- Listen for keypresses if binding
    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and Library.ActiveKeybind and Library.ActiveKeybind == keybind and keybind.Listening then
            keybind:SetKey(input.KeyCode)
            Library.ActiveKeybind = nil
        end
    end))
    
    return keybind
end

-- Create a window with tabs
function Library:CreateWindow(options)
    options = options or {}
    local title = options.Title or "Phantom UI"
    local width = options.Width or 300
    local height = options.Height or 350
    local x = options.X or 50
    local y = options.Y or 50
    
    -- Create window container
    local container = CreateSquare({
        Size = Vector2.new(width, height),
        Position = Vector2.new(x, y),
        Color = Library.Theme.Window.Background,
        ZIndex = 1
    })
    
    -- Create window shadow
    local shadow = CreateSquare({
        Size = Vector2.new(width, height),
        Position = Vector2.new(x + 4, y + 4),
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.4,
        ZIndex = 0
    })
    
    -- Create window border
    local border = CreateSquare({
        Size = Vector2.new(width, height),
        Position = Vector2.new(x, y),
        Color = Library.Theme.Window.Border,
        Filled = false,
        Thickness = 1,
        ZIndex = 10
    })
    
    -- Create title bar
    local titleBar = CreateSquare({
        Size = Vector2.new(width, 30),
        Position = Vector2.new(x, y),
        Color = Library.Theme.Window.TopBar,
        ZIndex = 2
    })
    
    -- Create title text
    local titleText = CreateShadowedText({
        Text = title,
        Position = Vector2.new(x + 10, y + 7),
        Size = 16,
        Color = Library.Theme.Element.Text,
        Font = Library.FontBold,
        ZIndex = 3
    })
    
    -- Create close button
    local closeBtn = CreateSquare({
        Size = Vector2.new(20, 20),
        Position = Vector2.new(x + width - 25, y + 5),
        Color = Color3.fromRGB(220, 60, 60),
        ZIndex = 3
    })
    
    -- Create X text for close button
    local closeX = CreateShadowedText({
        Text = "×",
        Position = Vector2.new(x + width - 19, y + 6),
        Size = 18,
        Color = Color3.fromRGB(255, 255, 255),
        Center = true,
        ZIndex = 4
    })
    
    -- Create tab container
    local tabContainer = CreateSquare({
        Size = Vector2.new(width, 25),
        Position = Vector2.new(x, y + 30),
        Color = Library.Theme.Tab.Inactive,
        ZIndex = 2
    })
    
    -- Create content container
    local contentContainer = CreateSquare({
        Size = Vector2.new(width, height - 55),
        Position = Vector2.new(x, y + 55),
        Color = Library.Theme.Window.Background,
        ZIndex = 1
    })
    
    -- Create window object
    local window = setmetatable({
        X = x,
        Y = y,
        Width = width,
        Height = height,
        Dragging = false,
        DragOffset = Vector2.new(0, 0),
        Container = container,
        Shadow = shadow,
        Border = border,
        TitleBar = titleBar,
        TitleText = titleText,
        CloseBtn = closeBtn,
        CloseX = closeX,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        TabObjects = {},
        ActiveTab = nil,
        Interactables = {}
    }, Window)
    
    -- Handle window dragging
    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            
            -- Check if clicking on title bar
            if IsInBounds(mousePos, titleBar.Position, Vector2.new(width - 30, 30)) then
                window.Dragging = true
                window.DragOffset = mousePos - Vector2.new(x, y)
                Library.DraggingWindow = window
            end
            
            -- Check if clicking close button
            if IsInBounds(mousePos, closeBtn.Position, closeBtn.Size) then
                Library:DestroyWindow(window)
                return
            end
            
            -- Check other interactables
            for _, interactable in ipairs(window.Interactables) do
                -- Check if element should be visible/processed
                local visible = true
                if interactable.Visible then
                    visible = interactable.Visible()
                end
                
                if visible and IsInBounds(mousePos, interactable.Bounds.Min, interactable.Bounds.Max - interactable.Bounds.Min) then
                    if interactable.OnClick then
                        interactable.OnClick()
                    end
                    break
                end
            end
        end
    end))
    
    -- Handle mouse movement for hover effects and dragging
    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            
            -- Handle window dragging
            if window.Dragging and Library.DraggingWindow == window then
                local newPos = mousePos - window.DragOffset
                local screenSize = workspace.CurrentCamera.ViewportSize
                
                -- Keep window on screen
                newPos = Vector2.new(
                    math.clamp(newPos.X, 0, screenSize.X - width),
                    math.clamp(newPos.Y, 0, screenSize.Y - height)
                )
                
                -- Calculate movement delta
                local deltaPos = newPos - Vector2.new(window.X, window.Y)
                
                -- Update window position
                window:UpdatePosition(newPos)
            end
            
            -- Handle hover effects
            for _, interactable in ipairs(window.Interactables) do
                -- Check if element should be visible/processed
                local visible = true
                if interactable.Visible then
                    visible = interactable.Visible()
                end
                
                if visible and interactable.OnHover then
                    local hovering = IsInBounds(mousePos, interactable.Bounds.Min, interactable.Bounds.Max - interactable.Bounds.Min)
                    interactable.OnHover(hovering)
                end
            end
            
            -- Handle slider dragging
            if Library.DraggingSlider then
                local sliderInteractable = nil
                
                -- Find the slider interactable
                for _, interactable in ipairs(window.Interactables) do
                    if interactable.Type == "Slider" and interactable.Object == Library.DraggingSlider then
                        sliderInteractable = interactable
                        break
                    end
                end
                
                if sliderInteractable and sliderInteractable.OnDrag then
                    sliderInteractable.OnDrag(input)
                end
            end
        end
    end))
    
    -- Handle input ended
    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if window.Dragging and Library.DraggingWindow == window then
                window.Dragging = false
                Library.DraggingWindow = nil
            end
            
            -- Reset dragging slider
            Library.DraggingSlider = nil
        end
    end))
    
    -- Handle toggle key
    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Library.ToggleKey then
            Library:ToggleUI()
        end
    end))
    
    -- Add window to library
    table.insert(Library.Windows, window)
    
    return window
end

function Window:UpdatePosition(newPos)
    local deltaX = newPos.X - self.X
    local deltaY = newPos.Y - self.Y
    local deltaPos = Vector2.new(deltaX, deltaY)
    
    self.X = newPos.X
    self.Y = newPos.Y
    
    -- Update all window components
    self.Container.Position = newPos
    self.Shadow.Position = newPos + Vector2.new(4, 4)
    self.Border.Position = newPos
    self.TitleBar.Position = newPos
    self.TitleText:SetPosition(Vector2.new(newPos.X + 10, newPos.Y + 7))
    self.CloseBtn.Position = Vector2.new(newPos.X + self.Width - 25, newPos.Y + 5)
    self.CloseX:SetPosition(Vector2.new(newPos.X + self.Width - 19, newPos.Y + 6))
    self.TabContainer.Position = Vector2.new(newPos.X, newPos.Y + 30)
    self.ContentContainer.Position = Vector2.new(newPos.X, newPos.Y + 55)
    
    -- Update tab positions
    for i, tab in ipairs(self.Tabs) do
        local tabWidth = self.Width / #self.Tabs
        
        tab.Button.Position = Vector2.new(newPos.X + (i-1) * tabWidth, newPos.Y + 30)
        tab.Text:SetPosition(Vector2.new(
            newPos.X + (i-1) * tabWidth + (tabWidth/2),
            newPos.Y + 35
        ))
        tab.Indicator.Position = Vector2.new(newPos.X + (i-1) * tabWidth, newPos.Y + 55)
        
        -- Update all elements in the tab
        for _, element in ipairs(tab.Elements) do
            if element.Type == "Toggle" then
                element.Container.Position = element.Container.Position + deltaPos
                element.Text:SetPosition(Vector2.new(element.Text.Text.Position.X + deltaX, element.Text.Text.Position.Y + deltaY))
                element.IndicatorBg.Position = element.IndicatorBg.Position + deltaPos
                element.Indicator.Position = element.Indicator.Position + deltaPos
            elseif element.Type == "Slider" then
                element.Container.Position = element.Container.Position + deltaPos
                element.Text:SetPosition(Vector2.new(element.Text.Text.Position.X + deltaX, element.Text.Text.Position.Y + deltaY))
                element.ValueText:SetPosition(Vector2.new(element.ValueText.Text.Position.X + deltaX, element.ValueText.Text.Position.Y + deltaY))
                element.Track.Position = element.Track.Position + deltaPos
                element.Fill.Position = element.Fill.Position + deltaPos
                element.Knob.Position = element.Knob.Position + deltaPos
            elseif element.Type == "Button" then
                element.Container.Position = element.Container.Position + deltaPos
                element.Text:SetPosition(Vector2.new(element.Text.Text.Position.X + deltaX, element.Text.Text.Position.Y + deltaY))
            elseif element.Type == "Dropdown" then
                element.Container.Position = element.Container.Position + deltaPos
                element.Text:SetPosition(Vector2.new(element.Text.Text.Position.X + deltaX, element.Text.Text.Position.Y + deltaY))
                element.Arrow:SetPosition(Vector2.new(element.Arrow.Text.Position.X + deltaX, element.Arrow.Text.Position.Y + deltaY))
                
                if element.Open and element.Menu then
                    element.Menu.Position = element.Menu.Position + deltaPos
                    element.MenuBorder.Position = element.MenuBorder.Position + deltaPos
                    
                    for _, item in ipairs(element.Items) do
                        item.Container.Position = item.Container.Position + deltaPos
                        item.Text:SetPosition(Vector2.new(item.Text.Text.Position.X + deltaX, item.Text.Text.Position.Y + deltaY))
                    end
                end
            elseif element.Type == "Label" then
                element.Text:SetPosition(Vector2.new(element.Text.Text.Position.X + deltaX, element.Text.Text.Position.Y + deltaY))
            elseif element.Type == "Keybind" then
                element.Container.Position = element.Container.Position + deltaPos
                element.Text:SetPosition(Vector2.new(element.Text.Text.Position.X + deltaX, element.Text.Text.Position.Y + deltaY))
                element.KeyDisplay:SetPosition(Vector2.new(element.KeyDisplay.Text.Position.X + deltaX, element.KeyDisplay.Text.Position.Y + deltaY))
            end
        end
    end
    
    -- Update interactable bounds
    for _, interactable in ipairs(self.Interactables) do
        interactable.Bounds.Min = interactable.Bounds.Min + deltaPos
        interactable.Bounds.Max = interactable.Bounds.Max + deltaPos
    end
end

-- Toggle UI visibility
function Library:ToggleUI()
    Library.Visible = not Library.Visible
    
    for _, drawing in ipairs(Library.Drawings) do
        pcall(function()
            drawing.Visible = Library.Visible
        end)
    end
end

-- Destroy a window
function Library:DestroyWindow(window)
    -- Remove all window components
    pcall(function() window.Container:Remove() end)
    pcall(function() window.Shadow:Remove() end)
    pcall(function() window.Border:Remove() end)
    pcall(function() window.TitleBar:Remove() end)
    pcall(function() window.TitleText:Remove() end)
    pcall(function() window.CloseBtn:Remove() end)
    pcall(function() window.CloseX:Remove() end)
    pcall(function() window.TabContainer:Remove() end)
    pcall(function() window.ContentContainer:Remove() end)
    
    -- Remove all tabs
    for _, tab in ipairs(window.Tabs) do
        pcall(function() tab.Button:Remove() end)
        pcall(function() tab.Text:Remove() end)
        pcall(function() tab.Indicator:Remove() end)
        
        -- Remove all elements
        for _, element in ipairs(tab.Elements) do
            if element.Type == "Toggle" then
                pcall(function() element.Container:Remove() end)
                pcall(function() element.Text:Remove() end)
                pcall(function() element.IndicatorBg:Remove() end)
                pcall(function() element.Indicator:Remove() end)
            elseif element.Type == "Slider" then
                pcall(function() element.Container:Remove() end)
                pcall(function() element.Text:Remove() end)
                pcall(function() element.ValueText:Remove() end)
                pcall(function() element.Track:Remove() end)
                pcall(function() element.Fill:Remove() end)
                pcall(function() element.Knob:Remove() end)
            elseif element.Type == "Button" then
                pcall(function() element.Container:Remove() end)
                pcall(function() element.Text:Remove() end)
            elseif element.Type == "Dropdown" then
                pcall(function() element.Container:Remove() end)
                pcall(function() element.Text:Remove() end)
                pcall(function() element.Arrow:Remove() end)
                
                if element.Menu then
                    pcall(function() element.Menu:Remove() end)
                    pcall(function() element.MenuBorder:Remove() end)
                    
                    for _, item in ipairs(element.Items) do
                        pcall(function() item.Container:Remove() end)
                        pcall(function() item.Text:Remove() end)
                    end
                end
            elseif element.Type == "Label" then
                pcall(function() element.Text:Remove() end)
            elseif element.Type == "Keybind" then
                pcall(function() element.Container:Remove() end)
                pcall(function() element.Text:Remove() end)
                pcall(function() element.KeyDisplay:Remove() end)
            end
        end
    end
    
    -- Remove window from windows list
    for i, w in ipairs(Library.Windows) do
        if w == window then
            table.remove(Library.Windows, i)
            break
        end
    end
end

-- Clean up everything
function Library:Destroy()
    -- Disconnect all connections
    for _, connection in ipairs(Library.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    
    -- Destroy all windows
    for _, window in ipairs(Library.Windows) do
        Library:DestroyWindow(window)
    end
    
    -- Remove any remaining drawings
    for _, drawing in ipairs(Library.Drawings) do
        pcall(function() drawing:Remove() end)
    end
    
    Library.Connections = {}
    Library.Windows = {}
    Library.Drawings = {}
end

-- Initialize library
function Library:Init()
    return Library
end

return Library:Init()
