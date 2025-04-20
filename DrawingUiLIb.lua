--[[ 
    Phantom UI Library
    A lightweight, modern UI library using the Drawing API for Roblox exploits

    Features:
    - Sleek, minimal design
    - Smooth animations
    - Easy to use API
    - Fully customizable theme
]]--

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Library
local Library = {
    Drawings = {},
    Windows = {},
    Connections = {},
    Theme = {
        Primary = Color3.fromRGB(40, 40, 60),
        Secondary = Color3.fromRGB(30, 30, 45),
        Accent = Color3.fromRGB(100, 100, 255),
        Text = Color3.fromRGB(255, 255, 255),
        DarkText = Color3.fromRGB(175, 175, 175),
        Outline = Color3.fromRGB(60, 60, 85),
        ElementBackground = Color3.fromRGB(45, 45, 65),
        ElementBorder = Color3.fromRGB(60, 60, 85),
        SliderFill = Color3.fromRGB(100, 100, 255),
        ToggleEnabled = Color3.fromRGB(100, 100, 255),
        ToggleDisabled = Color3.fromRGB(60, 60, 85),
        ButtonBackground = Color3.fromRGB(50, 50, 70),
        ButtonHover = Color3.fromRGB(60, 60, 80),
        Highlight = Color3.fromRGB(100, 100, 255),
        Shadow = Color3.fromRGB(15, 15, 25)
    },
    Font = 2, -- SourceSans
    ToggleKey = Enum.KeyCode.RightShift,
    Visible = true,
    Dragging = false,
    DraggingSlider = nil,
    ActiveDropdown = nil,
    HoveredButton = nil
}

-- Utility Functions
local function IsInBounds(point, position, size)
    return point.X >= position.X and point.X <= position.X + size.X and 
           point.Y >= position.Y and point.Y <= position.Y + size.Y
end

local function Round(number, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor(number * power + 0.5) / power
end

-- Add drawings to cleanup list
local function AddDrawing(drawing)
    table.insert(Library.Drawings, drawing)
    return drawing
end

-- Create text with shadow
local function CreateText(text, position, size, color, center)
    local textObject = AddDrawing(Drawing.new("Text"))
    textObject.Text = text
    textObject.Position = position
    textObject.Size = size
    textObject.Color = color or Library.Theme.Text
    textObject.Center = center or false
    textObject.Outline = false
    textObject.Visible = Library.Visible
    textObject.Font = Library.Font
    textObject.ZIndex = 10

    local shadow = AddDrawing(Drawing.new("Text"))
    shadow.Text = text
    shadow.Position = position + Vector2.new(1, 1)
    shadow.Size = size
    shadow.Color = Library.Theme.Shadow
    shadow.Transparency = 0.8
    shadow.Center = center or false
    shadow.Outline = false
    shadow.Visible = Library.Visible
    shadow.Font = Library.Font
    shadow.ZIndex = 9

    return {
        Object = textObject,
        Shadow = shadow,
        SetText = function(newText)
            textObject.Text = newText
            shadow.Text = newText
        end,
        SetPosition = function(newPosition)
            textObject.Position = newPosition
            shadow.Position = newPosition + Vector2.new(1, 1)
        end,
        SetVisible = function(visible)
            textObject.Visible = visible
            shadow.Visible = visible
        end,
        Remove = function()
            textObject:Remove()
            shadow:Remove()
        end
    }
end

-- Create window class
local Window = {}
Window.__index = Window

function Window:AddSection(name)
    local sectionY = self.ContentY

    -- Section container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = Vector2.new(self.Width - 20, 30)
    container.Position = Vector2.new(self.X + 10, self.Y + sectionY)
    container.Color = Library.Theme.Secondary
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = Library.Visible
    container.ZIndex = 2

    -- Section line accent
    local accent = AddDrawing(Drawing.new("Square"))
    accent.Size = Vector2.new(3, 30)
    accent.Position = Vector2.new(self.X + 10, self.Y + sectionY)
    accent.Color = Library.Theme.Accent
    accent.Filled = true
    accent.Transparency = 1
    accent.Visible = Library.Visible
    accent.ZIndex = 3

    -- Section text
    local text = CreateText(
        name,
        Vector2.new(self.X + 20, self.Y + sectionY + 7),
        18,
        Library.Theme.Accent
    )

    -- Use a separate Y counter for this section:
    local sectionObj = { Container = container, Accent = accent, Text = text, Y = self.ContentY + 40 }
    self.ContentY = sectionObj.Y

    return sectionObj
end

function Window:AddToggle(options)
    local name = options.Name or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function() end
    local section = options.Section

    local y
    if section then
        y = section.Y
        section.Y = y + 30
    else
        y = self.ContentY
        self.ContentY = y + 30
    end

    -- Toggle container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = Vector2.new(self.Width - 20, 25)
    container.Position = Vector2.new(self.X + 10, self.Y + y)
    container.Color = Library.Theme.ElementBackground
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = Library.Visible
    container.ZIndex = 2

    -- Toggle text
    local text = CreateText(
        name,
        Vector2.new(self.X + 15, self.Y + y + 4),
        16,
        Library.Theme.Text
    )

    -- Toggle indicator border
    local indicatorBorder = AddDrawing(Drawing.new("Square"))
    indicatorBorder.Size = Vector2.new(16, 16)
    indicatorBorder.Position = Vector2.new(self.X + self.Width - 30, self.Y + y + 4)
    indicatorBorder.Color = Library.Theme.ElementBorder
    indicatorBorder.Filled = false
    indicatorBorder.Thickness = 1
    indicatorBorder.Transparency = 1
    indicatorBorder.Visible = Library.Visible
    indicatorBorder.ZIndex = 4

    -- Toggle indicator fill
    local indicatorFill = AddDrawing(Drawing.new("Square"))
    indicatorFill.Size = Vector2.new(10, 10)
    indicatorFill.Position = Vector2.new(self.X + self.Width - 27, self.Y + y + 7)
    indicatorFill.Color = default and Library.Theme.ToggleEnabled or Library.Theme.ToggleDisabled
    indicatorFill.Filled = true
    indicatorFill.Transparency = default and 1 or 0.4
    indicatorFill.Visible = Library.Visible
    indicatorFill.ZIndex = 3

    -- Toggle logic
    local toggle = {
        Value = default,
        Container = container,
        IndicatorBorder = indicatorBorder,
        IndicatorFill = indicatorFill,
        Text = text,
        Callback = callback,
        SetValue = function(self, value)
            self.Value = value
            indicatorFill.Color = value and Library.Theme.ToggleEnabled or Library.Theme.ToggleDisabled
            indicatorFill.Transparency = value and 1 or 0.4
            callback(value)
        end
    }

    -- Handle mouse click
    table.insert(self.Elements, {
        Type = "Toggle",
        Instance = toggle,
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

function Window:AddSlider(options)
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = math.clamp(options.Default or min, min, max)
    local callback = options.Callback or function() end
    local decimals = options.Decimals or 1
    local section = options.Section

    local y
    if section then
        y = section.Y
        section.Y = y + 45
    else
        y = self.ContentY
        self.ContentY = y + 45
    end

    -- Slider container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = Vector2.new(self.Width - 20, 40)
    container.Position = Vector2.new(self.X + 10, self.Y + y)
    container.Color = Library.Theme.ElementBackground
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = Library.Visible
    container.ZIndex = 2

    -- Slider text
    local text = CreateText(
        name,
        Vector2.new(self.X + 15, self.Y + y + 4),
        16,
        Library.Theme.Text
    )

    -- Slider value text
    local valueText = CreateText(
        tostring(default),
        Vector2.new(self.X + self.Width - 30, self.Y + y + 4),
        16,
        Library.Theme.Accent
    )

    -- Slider track background
    local trackBg = AddDrawing(Drawing.new("Square"))
    trackBg.Size = Vector2.new(self.Width - 30, 6)
    trackBg.Position = Vector2.new(self.X + 15, self.Y + y + 26)
    trackBg.Color = Library.Theme.Secondary
    trackBg.Filled = true
    trackBg.Transparency = 0.95
    trackBg.Visible = Library.Visible
    trackBg.ZIndex = 3

    -- Calculate fill width based on default value
    local percent = (default - min) / (max - min)
    local fillWidth = (self.Width - 30) * percent

    -- Slider track fill
    local trackFill = AddDrawing(Drawing.new("Square"))
    trackFill.Size = Vector2.new(fillWidth, 6)
    trackFill.Position = Vector2.new(self.X + 15, self.Y + y + 26)
    trackFill.Color = Library.Theme.SliderFill
    trackFill.Filled = true
    trackFill.Transparency = 1
    trackFill.Visible = Library.Visible
    trackFill.ZIndex = 4

    -- Slider knob
    local knob = AddDrawing(Drawing.new("Square"))
    knob.Size = Vector2.new(10, 14)
    knob.Position = Vector2.new(self.X + 15 + fillWidth - 5, self.Y + y + 22)
    knob.Color = Library.Theme.Text
    knob.Filled = true
    knob.Transparency = 1
    knob.Visible = Library.Visible
    knob.ZIndex = 5

    -- Slider logic
    local slider = {
        Value = default,
        Min = min,
        Max = max,
        Container = container,
        Track = trackBg,
        Fill = trackFill,
        Knob = knob,
        Text = text,
        ValueText = valueText,
        Callback = callback,
        Decimals = decimals,
        SetValue = function(self, value)
            value = math.clamp(value, self.Min, self.Max)
            self.Value = value

            local percent = (value - self.Min) / (self.Max - self.Min)
            local fillWidth = (Window.Width - 30) * percent

            self.Fill.Size = Vector2.new(fillWidth, 6)
            self.Knob.Position = Vector2.new(self.Container.Position.X + fillWidth + 10, self.Knob.Position.Y)
            self.ValueText.SetText(tostring(Round(value, self.Decimals)))

            callback(value)
        end,
        UpdateVisuals = function(self, mouseX)
            local relX = mouseX - self.Track.Position.X
            local percent = math.clamp(relX / self.Track.Size.X, 0, 1)
            local value = self.Min + ((self.Max - self.Min) * percent)
            self:SetValue(value)
        end
    }

    table.insert(self.Elements, {
        Type = "Slider",
        Instance = slider,
        Bounds = {
            Min = trackBg.Position,
            Max = trackBg.Position + trackBg.Size + Vector2.new(0, 8)
        },
        OnClick = function()
            Library.DraggingSlider = slider
        end,
        OnDrag = function(input)
            if Library.DraggingSlider == slider then
                slider:UpdateVisuals(input.Position.X)
            end
        end
    })

    return slider
end

function Window:AddButton(options)
    local name = options.Name or "Button"
    local callback = options.Callback or function() end
    local section = options.Section

    local y
    if section then
        y = section.Y
        section.Y = y + 30
    else
        y = self.ContentY
        self.ContentY = y + 30
    end

    -- Button container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = Vector2.new(self.Width - 20, 25)
    container.Position = Vector2.new(self.X + 10, self.Y + y)
    container.Color = Library.Theme.ButtonBackground
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = Library.Visible
    container.ZIndex = 2

    -- Button text (centered)
    local text = CreateText(
        name,
        Vector2.new(self.X + (self.Width / 2), self.Y + y + 4),
        16,
        Library.Theme.Text,
        true
    )

    local button = {
        Container = container,
        Text = text,
        Callback = callback,
        Hover = function(self, hovering)
            self.Container.Color = hovering and Library.Theme.ButtonHover or Library.Theme.ButtonBackground
        end
    }

    table.insert(self.Elements, {
        Type = "Button",
        Instance = button,
        Bounds = {
            Min = container.Position,
            Max = container.Position + container.Size
        },
        OnClick = function()
            button.Container.Color = Library.Theme.Accent
            callback()
            task.delay(0.15, function()
                button.Container.Color = Library.HoveredButton == button and Library.Theme.ButtonHover or Library.Theme.ButtonBackground
            end)
        end,
        OnHover = function(hovering)
            button:Hover(hovering)
            Library.HoveredButton = hovering and button or nil
        end
    })

    return button
end

function Window:AddDropdown(options)
    local name = options.Name or "Dropdown"
    local items = options.Items or {"Item 1", "Item 2", "Item 3"}
    local default = options.Default or items[1]
    local callback = options.Callback or function() end
    local section = options.Section

    local y
    if section then
        y = section.Y
        section.Y = y + 30
    else
        y = self.ContentY
        self.ContentY = y + 30
    end

    -- Dropdown container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = Vector2.new(self.Width - 20, 25)
    container.Position = Vector2.new(self.X + 10, self.Y + y)
    container.Color = Library.Theme.ElementBackground
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = Library.Visible
    container.ZIndex = 2

    -- Dropdown text
    local text = CreateText(
        name .. ": " .. default,
        Vector2.new(self.X + 15, self.Y + y + 4),
        16,
        Library.Theme.Text
    )

    -- Dropdown arrow
    local arrow = CreateText(
        "▼",
        Vector2.new(self.X + self.Width - 25, self.Y + y + 4),
        16,
        Library.Theme.Text
    )

    -- Dropdown menu (initially hidden)
    local menuContainer = AddDrawing(Drawing.new("Square"))
    menuContainer.Size = Vector2.new(self.Width - 20, #items * 25)
    menuContainer.Position = Vector2.new(self.X + 10, self.Y + y + 30)
    menuContainer.Color = Library.Theme.Secondary
    menuContainer.Filled = true
    menuContainer.Transparency = 0.95
    menuContainer.Visible = false
    menuContainer.ZIndex = 10

    -- Dropdown menu border
    local menuBorder = AddDrawing(Drawing.new("Square"))
    menuBorder.Size = Vector2.new(self.Width - 20, #items * 25)
    menuBorder.Position = Vector2.new(self.X + 10, self.Y + y + 30)
    menuBorder.Color = Library.Theme.Outline
    menuBorder.Filled = false
    menuBorder.Thickness = 1
    menuBorder.Transparency = 0.95
    menuBorder.Visible = false
    menuBorder.ZIndex = 11

    -- Create menu items
    local menuItems = {}
    for i, itemName in ipairs(items) do
        local itemY = self.Y + y + 30 + ((i - 1) * 25)

        local itemContainer = AddDrawing(Drawing.new("Square"))
        itemContainer.Size = Vector2.new(self.Width - 20, 25)
        itemContainer.Position = Vector2.new(self.X + 10, itemY)
        itemContainer.Color = itemName == default and Library.Theme.Accent or Library.Theme.ElementBackground
        itemContainer.Filled = true
        itemContainer.Transparency = 0.95
        itemContainer.Visible = false
        itemContainer.ZIndex = 12

        local itemText = CreateText(
            itemName,
            Vector2.new(self.X + 15, itemY + 4),
            16,
            itemName == default and Library.Theme.Text or Library.Theme.DarkText
        )
        itemText.SetVisible(false)

        table.insert(menuItems, {
            Name = itemName,
            Container = itemContainer,
            Text = itemText
        })
    end

    local dropdown = {
        Container = container,
        Text = text,
        Arrow = arrow,
        Menu = menuContainer,
        MenuBorder = menuBorder,
        Items = menuItems,
        ItemsList = items,
        Selected = default,
        Open = false,
        Callback = callback,
        SetValue = function(self, value)
            if not table.find(self.ItemsList, value) then return end

            self.Selected = value
            self.Text.SetText(name .. ": " .. value)

            for _, item in ipairs(self.Items) do
                item.Container.Color = item.Name == value and Library.Theme.Accent or Library.Theme.ElementBackground
                item.Text.Object.Color = item.Name == value and Library.Theme.Text or Library.Theme.DarkText
            end

            callback(value)
        end,
        Toggle = function(self)
            self.Open = not self.Open

            if self.Open then
                if Library.ActiveDropdown and Library.ActiveDropdown ~= self then
                    Library.ActiveDropdown:Toggle()
                end
                Library.ActiveDropdown = self

                self.Menu.Visible = true
                self.MenuBorder.Visible = true

                for _, item in ipairs(self.Items) do
                    item.Container.Visible = true
                    item.Text.SetVisible(true)
                end

                self.Arrow.SetText("▲")
            else
                if Library.ActiveDropdown == self then
                    Library.ActiveDropdown = nil
                end

                self.Menu.Visible = false
                self.MenuBorder.Visible = false

                for _, item in ipairs(self.Items) do
                    item.Container.Visible = false
                    item.Text.SetVisible(false)
                end

                self.Arrow.SetText("▼")
            end
        end
    }

    table.insert(self.Elements, {
        Type = "Dropdown",
        Instance = dropdown,
        Bounds = {
            Min = container.Position,
            Max = container.Position + container.Size
        },
        OnClick = function()
            dropdown:Toggle()
        end
    })

    for i, item in ipairs(menuItems) do
        table.insert(self.Elements, {
            Type = "DropdownItem",
            Instance = {
                Dropdown = dropdown,
                Item = item
            },
            Bounds = {
                Min = item.Container.Position,
                Max = item.Container.Position + item.Container.Size
            },
            OnClick = function()
                dropdown:SetValue(item.Name)
                dropdown:Toggle()
            end,
            Visible = function() return dropdown.Open end
        })
    end

    return dropdown
end

function Window:AddLabel(options)
    local textStr = options.Text or "Label"
    local color = options.Color or Library.Theme.Text
    local section = options.Section

    local y
    if section then
        y = section.Y
        section.Y = y + 20
    else
        y = self.ContentY
        self.ContentY = y + 20
    end

    local label = CreateText(
        textStr,
        Vector2.new(self.X + 15, self.Y + y),
        16,
        color
    )

    return {
        Text = label,
        SetText = function(self, newText)
            self.Text.SetText(newText)
        end
    }
end

function Window:AddKeybind(options)
    local name = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.F
    local callback = options.Callback or function() end
    local section = options.Section

    local y
    if section then
        y = section.Y
        section.Y = y + 30
    else
        y = self.ContentY
        self.ContentY = y + 30
    end

    -- Keybind container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = Vector2.new(self.Width - 20, 25)
    container.Position = Vector2.new(self.X + 10, self.Y + y)
    container.Color = Library.Theme.ElementBackground
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = Library.Visible
    container.ZIndex = 2

    -- Keybind text
    local text = CreateText(
        name,
        Vector2.new(self.X + 15, self.Y + y + 4),
        16,
        Library.Theme.Text
    )

    local keyName = tostring(default):gsub("Enum.KeyCode.", "")
    local keyDisplay = CreateText(
        "[" .. keyName .. "]",
        Vector2.new(self.X + self.Width - 55, self.Y + y + 4),
        16,
        Library.Theme.Accent
    )

    local keybind = {
        Container = container,
        Text = text,
        Display = keyDisplay,
        Key = default,
        Listening = false,
        Callback = callback,
        SetKey = function(self, key)
            self.Key = key
            local keyName = tostring(key):gsub("Enum.KeyCode.", "")
            self.Display.SetText("[" .. keyName .. "]")
            self.Listening = false
            self.Container.Color = Library.Theme.ElementBackground
            callback(key)
        end,
        StartListening = function(self)
            self.Listening = true
            self.Display.SetText("[...]")
            self.Container.Color = Library.Theme.Accent
        end
    }

    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and keybind.Listening then
            keybind:SetKey(input.KeyCode)
        end
    end))

    table.insert(self.Elements, {
        Type = "Keybind",
        Instance = keybind,
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

    return keybind
end

-- Create interface window
function Library:CreateWindow(options)
    options = options or {}
    local title = options.Title or "Phantom UI"
    local width = options.Width or 300
    local height = options.Height or 350
    local x = options.X or 50
    local y = options.Y or 50

    -- Create window container
    local container = AddDrawing(Drawing.new("Square"))
    container.Size = Vector2.new(width, height)
    container.Position = Vector2.new(x, y)
    container.Color = Library.Theme.Primary
    container.Filled = true
    container.Transparency = 0.95
    container.Visible = Library.Visible
    container.ZIndex = 1

    -- Create window border
    local border = AddDrawing(Drawing.new("Square"))
    border.Size = Vector2.new(width, height)
    border.Position = Vector2.new(x, y)
    border.Color = Library.Theme.Outline
    border.Filled = false
    border.Thickness = 1
    border.Transparency = 1
    border.Visible = Library.Visible
    border.ZIndex = 5

    -- Create window shadow
    local shadow = AddDrawing(Drawing.new("Square"))
    shadow.Size = Vector2.new(width, height)
    shadow.Position = Vector2.new(x + 3, y + 3)
    shadow.Color = Library.Theme.Shadow
    shadow.Filled = true
    shadow.Transparency = 0.5
    shadow.Visible = Library.Visible
    shadow.ZIndex = 0

    -- Create title bar
    local titleBar = AddDrawing(Drawing.new("Square"))
    titleBar.Size = Vector2.new(width, 30)
    titleBar.Position = Vector2.new(x, y)
    titleBar.Color = Library.Theme.Secondary
    titleBar.Filled = true
    titleBar.Transparency = 0.95
    titleBar.Visible = Library.Visible
    titleBar.ZIndex = 2

    -- Create title text
    local titleText = CreateText(
        title,
        Vector2.new(x + 10, y + 7),
        18,
        Library.Theme.Text
    )

    -- Close button
    local closeBtn = AddDrawing(Drawing.new("Square"))
    closeBtn.Size = Vector2.new(18, 18)
    closeBtn.Position = Vector2.new(x + width - 25, y + 6)
    closeBtn.Color = Color3.fromRGB(220, 70, 70)
    closeBtn.Filled = true
    closeBtn.Transparency = 0.9
    closeBtn.Visible = Library.Visible
    closeBtn.ZIndex = 3

    local closeText = CreateText(
        "×",
        Vector2.new(x + width - 20, y + 4),
        20,
        Library.Theme.Text,
        true
    )

    local window = setmetatable({
        Container = container,
        Border = border,
        Shadow = shadow,
        TitleBar = titleBar,
        TitleText = titleText,
        CloseButton = closeBtn,
        CloseText = closeText,
        X = x,
        Y = y,
        Width = width,
        Height = height,
        ContentY = 40, -- Start content below title bar
        Elements = {},
        Dragging = false,
        DragOffset = Vector2.new(0, 0)
    }, Window)

    table.insert(Library.Windows, window)

    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            if IsInBounds(mousePos, titleBar.Position, Vector2.new(width - 30, 30)) then
                window.Dragging = true
                window.DragOffset = mousePos - Vector2.new(x, y)
            end
            if IsInBounds(mousePos, closeBtn.Position, closeBtn.Size) then
                Library:CloseWindow(window)
            end
        end
    end))

    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.Dragging = false
        end
    end))

    return window
end

function Library:CloseWindow(window)
    window.Container:Remove()
    window.Border:Remove()
    window.Shadow:Remove()
    window.TitleBar:Remove()
    window.TitleText.Remove()
    window.CloseButton:Remove()
    window.CloseText.Remove()

    for i, w in pairs(Library.Windows) do
        if w == window then
            table.remove(Library.Windows, i)
            break
        end
    end
end

function Library:ToggleUI()
    Library.Visible = not Library.Visible

    for _, drawing in pairs(Library.Drawings) do
        if drawing.Visible ~= nil then
            drawing.Visible = Library.Visible
        end
    end
end

function Library:Update()
    local mousePos = UserInputService:GetMouseLocation()

    for _, window in pairs(Library.Windows) do
        if window.Dragging then
            local newPos = mousePos - window.DragOffset
            local screenSize = workspace.CurrentCamera.ViewportSize
            newPos = Vector2.new(
                math.clamp(newPos.X, 0, screenSize.X - window.Width),
                math.clamp(newPos.Y, 0, screenSize.Y - window.Height)
            )
            local delta = newPos - Vector2.new(window.X, window.Y)
            window.X = newPos.X
            window.Y = newPos.Y

            window.Container.Position = newPos
            window.Border.Position = newPos
            window.Shadow.Position = newPos + Vector2.new(3, 3)
            window.TitleBar.Position = newPos
            window.TitleText.SetPosition(newPos + Vector2.new(10, 7))
            window.CloseButton.Position = Vector2.new(newPos.X + window.Width - 25, newPos.Y + 6)
            window.CloseText.SetPosition(Vector2.new(newPos.X + window.Width - 20, newPos.Y + 4))

            for _, element in pairs(window.Elements) do
                if element.Type == "Toggle" then
                    element.Instance.Container.Position = element.Instance.Container.Position + delta
                    element.Instance.IndicatorBorder.Position = element.Instance.IndicatorBorder.Position + delta
                    element.Instance.IndicatorFill.Position = element.Instance.IndicatorFill.Position + delta
                    element.Instance.Text.SetPosition(element.Instance.Text.Object.Position + delta)
                    element.Bounds.Min = element.Bounds.Min + delta
                    element.Bounds.Max = element.Bounds.Max + delta

                elseif element.Type == "Slider" then
                    element.Instance.Container.Position = element.Instance.Container.Position + delta
                    element.Instance.Track.Position = element.Instance.Track.Position + delta
                    element.Instance.Fill.Position = element.Instance.Fill.Position + delta
                    element.Instance.Knob.Position = element.Instance.Knob.Position + delta
                    element.Instance.Text.SetPosition(element.Instance.Text.Object.Position + delta)
                    element.Instance.ValueText.SetPosition(element.Instance.ValueText.Object.Position + delta)
                    element.Bounds.Min = element.Bounds.Min + delta
                    element.Bounds.Max = element.Bounds.Max + delta

                elseif element.Type == "Button" then
                    element.Instance.Container.Position = element.Instance.Container.Position + delta
                    element.Instance.Text.SetPosition(element.Instance.Text.Object.Position + delta)
                    element.Bounds.Min = element.Bounds.Min + delta
                    element.Bounds.Max = element.Bounds.Max + delta

                elseif element.Type == "Dropdown" then
                    element.Instance.Container.Position = element.Instance.Container.Position + delta
                    element.Instance.Text.SetPosition(element.Instance.Text.Object.Position + delta)
                    element.Instance.Arrow.SetPosition(element.Instance.Arrow.Object.Position + delta)
                    if element.Instance.Open then
                        element.Instance.Menu.Position = element.Instance.Menu.Position + delta
                        element.Instance.MenuBorder.Position = element.Instance.MenuBorder.Position + delta
                        for _, item in pairs(element.Instance.Items) do
                            item.Container.Position = item.Container.Position + delta
                            item.Text.SetPosition(item.Text.Object.Position + delta)
                        end
                    end
                    element.Bounds.Min = element.Bounds.Min + delta
                    element.Bounds.Max = element.Bounds.Max + delta

                elseif element.Type == "DropdownItem" then
                    if element.Instance.Dropdown.Open then
                        element.Bounds.Min = element.Bounds.Min + delta
                        element.Bounds.Max = element.Bounds.Max + delta
                    end

                elseif element.Type == "Keybind" then
                    element.Instance.Container.Position = element.Instance.Container.Position + delta
                    element.Instance.Text.SetPosition(element.Instance.Text.Object.Position + delta)
                    element.Instance.Display.SetPosition(element.Instance.Display.Object.Position + delta)
                    element.Bounds.Min = element.Bounds.Min + delta
                    element.Bounds.Max = element.Bounds.Max + delta
                end
            end
        end
    end

    if Library.DraggingSlider then
        Library.DraggingSlider:UpdateVisuals(mousePos.X)
    end

    for _, window in pairs(Library.Windows) do
        for _, element in pairs(window.Elements) do
            local visible = true
            if element.Visible then
                visible = element.Visible()
            end

            if visible then
                local hovering = IsInBounds(mousePos, element.Bounds.Min, element.Bounds.Max - element.Bounds.Min)
                if element.OnHover then
                    element.OnHover(hovering)
                end
            end
        end
    end
end

function Library:InitializeMouseHandling()
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            for _, window in pairs(Library.Windows) do
                for _, element in pairs(window.Elements) do
                    local visible = true
                    if element.Visible then
                        visible = element.Visible()
                    end
                    if visible and IsInBounds(mousePos, element.Bounds.Min, element.Bounds.Max - element.Bounds.Min) then
                        if element.OnClick then
                            element.OnClick()
                        end
                    end
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Library.DraggingSlider = nil
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Library.ToggleKey then
                Library:ToggleUI()
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        Library:Update()
    end)
end

function Library:Cleanup()
    for _, connection in pairs(Library.Connections) do
        connection:Disconnect()
    end

    for _, drawing in pairs(Library.Drawings) do
        pcall(function() drawing:Remove() end)
    end

    Library.Drawings = {}
    Library.Windows = {}
    Library.Connections = {}
end

function Library:Init()
    Library:InitializeMouseHandling()
    return Library
end

return Library:Init()
