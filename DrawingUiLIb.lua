-- UI Library using Drawing API for exploit use
-- Horizon GUI styled

local Library = {}
Library.__index = Library

local UIS = game:GetService("UserInputService")

local function round(num, bracket)
    bracket = bracket or 1
    return math.floor(num/bracket + 0.5) * bracket
end

local function create(class, props)
    local obj = Drawing.new(class)
    for i, v in pairs(props) do
        obj[i] = v
    end
    return obj
end

local Clickables = {}

function Library:CreateWindow(name, size, position)
    local self = setmetatable({}, Library)
    self.Name = name or "Window"
    self.Size = size or Vector2.new(300, 320)
    self.Position = position or Vector2.new(100, 100)
    self.Objects = {}
    self.Tabs = {}
    self.ActiveTab = nil
    self.Dragging = false
    self.DragOffset = Vector2.new()
    self.ComponentY = 35

    self.Background = create("Square", {
        Size = self.Size,
        Position = self.Position,
        Color = Color3.fromRGB(20, 20, 20),
        Filled = true,
        Transparency = 1,
        Visible = true,
    })

    self.TitleBar = create("Square", {
        Size = Vector2.new(self.Size.X, 25),
        Position = self.Position,
        Color = Color3.fromRGB(0, 120, 255),
        Filled = true,
        Transparency = 1,
        Visible = true,
    })

    self.Title = create("Text", {
        Text = self.Name,
        Size = 18,
        Color = Color3.fromRGB(255, 255, 255),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(6, 3),
        Visible = true,
    })

    self.Version = create("Text", {
        Text = "v1.0",
        Size = 14,
        Color = Color3.fromRGB(160, 160, 160),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(self.Size.X - 40, self.Size.Y - 18),
        Visible = true,
    })

    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= self.Position.X and mouse.X <= self.Position.X + self.Size.X and
               mouse.Y >= self.Position.Y and mouse.Y <= self.Position.Y + 25 then
                self.Dragging = true
                self.DragOffset = mouse - self.Position
            end

            for _, clickable in pairs(Clickables) do
                local pos = clickable.obj.Position
                local size = clickable.size or Vector2.new(100, 20)
                if mouse.X >= pos.X and mouse.X <= pos.X + size.X and
                   mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y then
                    pcall(clickable.callback)
                end
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)

    game:GetService("RunService").RenderStepped:Connect(function()
        if self.Dragging then
            local mouse = UIS:GetMouseLocation()
            self.Position = mouse - self.DragOffset
            self.Background.Position = self.Position
            self.TitleBar.Position = self.Position
            self.Title.Position = self.Position + Vector2.new(6, 3)
            self.Version.Position = self.Position + Vector2.new(self.Size.X - 40, self.Size.Y - 18)

            local offsetY = 35
            for _, obj in ipairs(self.Objects) do
                if obj._type == "component" then
                    obj.ref.Position = self.Position + Vector2.new(10, offsetY)
                    offsetY = offsetY + obj.height or 25
                end
            end
        end
    end)

    return self
end

function Library:CreateSection(title)
    local header = create("Text", {
        Text = title,
        Size = 18,
        Color = Color3.fromRGB(0, 170, 255),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = header, _type = "component", height = 28})
    self.ComponentY = self.ComponentY + 28
    return header
end

function Library:CreateLabel(text)
    local label = create("Text", {
        Text = text or "Label",
        Size = 16,
        Color = Color3.fromRGB(255, 255, 255),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = label, _type = "component"})
    self.ComponentY = self.ComponentY + 25
    return label
end

function Library:CreateButton(text, callback)
    local btn = create("Text", {
        Text = "[ " .. text .. " ]",
        Size = 16,
        Color = Color3.fromRGB(0, 200, 255),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = btn, _type = "component"})
    table.insert(Clickables, {obj = btn, callback = callback, size = Vector2.new(150, 20)})
    self.ComponentY = self.ComponentY + 25
    return btn
end

function Library:CreateSlider(title, min, max, default, callback)
    local value = default or min
    local barWidth = 200

    local label = create("Text", {
        Text = title .. ": " .. tostring(value),
        Size = 16,
        Color = Color3.fromRGB(255, 255, 255),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })

    local sliderBar = create("Square", {
        Position = self.Position + Vector2.new(10, self.ComponentY + 18),
        Size = Vector2.new(barWidth, 6),
        Color = Color3.fromRGB(60, 60, 60),
        Filled = true,
        Visible = true,
    })

    local fill = create("Square", {
        Position = sliderBar.Position,
        Size = Vector2.new(0, 6),
        Color = Color3.fromRGB(0, 120, 255),
        Filled = true,
        Visible = true,
    })

    local dragging = false

    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            local mouse = UIS:GetMouseLocation()
            local percent = math.clamp((mouse.X - sliderBar.Position.X) / barWidth, 0, 1)
            value = round(min + (max - min) * percent, 1)
            fill.Size = Vector2.new(barWidth * percent, 6)
            label.Text = title .. ": " .. tostring(value)
            pcall(callback, value)
        end
    end)

    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= sliderBar.Position.X and mouse.X <= sliderBar.Position.X + barWidth and
               mouse.Y >= sliderBar.Position.Y and mouse.Y <= sliderBar.Position.Y + 6 then
                dragging = true
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    table.insert(self.Objects, {ref = label, _type = "component", height = 26})
    table.insert(self.Objects, {ref = sliderBar, _type = "component", height = 8})
    table.insert(self.Objects, {ref = fill, _type = "component", height = 0})
    self.ComponentY = self.ComponentY + 30
    return label
end

return Library
