-- UI Library using Drawing API for exploit use
-- Horizon GUI styled + Full Tab Support + Correct Separation

local Library = {}
Library.__index = Library

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

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
    for k, v in pairs(Library) do
        if type(v) == "function" and k ~= "CreateWindow" then
            self[k] = v
        end
    end

    self.Name = name or "Window"
    self.Size = size or Vector2.new(350, 400)
    self.Position = position or Vector2.new(100, 100)
    self.Objects = {}
    self.Tabs = {}
    self.CurrentTab = nil
    self.ComponentY = 60

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
        Outline = true,
        Position = self.Position + Vector2.new(6, 3),
        Visible = true,
    })

    self.Version = create("Text", {
        Text = "v1.0",
        Size = 14,
        Color = Color3.fromRGB(160, 160, 160),
        Outline = true,
        Position = self.Position + Vector2.new(self.Size.X - 40, self.Size.Y - 18),
        Visible = true,
    })

    local dragging = false
    local dragOffset = Vector2.new()

    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= self.Position.X and mouse.X <= self.Position.X + self.Size.X and
               mouse.Y >= self.Position.Y and mouse.Y <= self.Position.Y + 25 then
                dragging = true
                dragOffset = mouse - self.Position
            end

            for _, clickable in ipairs(Clickables) do
                local pos, size = clickable.obj.Position, clickable.size or Vector2.new(100, 20)
                if mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y then
                    pcall(clickable.callback)
                end
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    RS.RenderStepped:Connect(function()
        if dragging then
            local mouse = UIS:GetMouseLocation()
            self.Position = mouse - dragOffset
            self.Background.Position = self.Position
            self.TitleBar.Position = self.Position
            self.Title.Position = self.Position + Vector2.new(6, 3)
            self.Version.Position = self.Position + Vector2.new(self.Size.X - 40, self.Size.Y - 18)

            -- Reposition components for current tab
            local y = 60
            if self.CurrentTab then
                for _, comp in ipairs(self.CurrentTab.Components) do
                    comp.obj.Position = self.Position + Vector2.new(10, y)
                    y = y + (comp.height or 25)
                end
            end

            -- Reposition tabs
            for i, tab in ipairs(self.Tabs) do
                tab.Button.Position = self.Position + Vector2.new(10 + ((i - 1) * 70), 30)
            end
        end
    end)

    return self
end

function Library:CreateTab(name)
    local tab = {
        Name = name,
        Components = {},
        Button = create("Text", {
            Text = name,
            Size = 16,
            Color = Color3.fromRGB(200, 200, 255),
            Outline = true,
            Position = Vector2.new(),
            Visible = true,
        })
    }

    table.insert(self.Tabs, tab)
    table.insert(Clickables, {
        obj = tab.Button,
        size = Vector2.new(60, 20),
        callback = function()
            self:SetActiveTab(tab)
        end
    })
    if not self.CurrentTab then self:SetActiveTab(tab) end
    return tab
end

function Library:SetActiveTab(tab)
    self.CurrentTab = tab
    self.ComponentY = 60
    for _, t in ipairs(self.Tabs) do
        t.Button.Color = (t == tab) and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(200, 200, 255)
    end
end

function Library:AddComponent(obj, height)
    if not self.CurrentTab then return end
    table.insert(self.CurrentTab.Components, {obj = obj, height = height})
end

function Library:CreateLabel(text)
    local label = create("Text", {
        Text = text,
        Size = 16,
        Color = Color3.fromRGB(255, 255, 255),
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true
    })
    self:AddComponent(label, 25)
    return label
end

function Library:CreateButton(text, callback)
    local btn = create("Text", {
        Text = "[ " .. text .. " ]",
        Size = 16,
        Color = Color3.fromRGB(0, 200, 255),
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true
    })
    table.insert(Clickables, {
        obj = btn,
        callback = callback,
        size = Vector2.new(150, 20)
    })
    self:AddComponent(btn, 25)
    return btn
end

function Library:CreateSlider(title, min, max, default, callback)
    local value = default or min
    local barWidth = 200

    local label = create("Text", {
        Text = title .. ": " .. tostring(value),
        Size = 16,
        Color = Color3.fromRGB(255, 255, 255),
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true
    })

    local bar = create("Square", {
        Position = self.Position + Vector2.new(10, self.ComponentY + 18),
        Size = Vector2.new(barWidth, 6),
        Color = Color3.fromRGB(60, 60, 60),
        Filled = true,
        Visible = true
    })

    local fill = create("Square", {
        Position = bar.Position,
        Size = Vector2.new(0, 6),
        Color = Color3.fromRGB(0, 120, 255),
        Filled = true,
        Visible = true
    })

    local dragging = false

    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            local mouse = UIS:GetMouseLocation()
            local percent = math.clamp((mouse.X - bar.Position.X) / barWidth, 0, 1)
            value = round(min + (max - min) * percent, 1)
            fill.Size = Vector2.new(barWidth * percent, 6)
            label.Text = title .. ": " .. tostring(value)
            pcall(callback, value)
        end
    end)

    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= bar.Position.X and mouse.X <= bar.Position.X + barWidth and
               mouse.Y >= bar.Position.Y and mouse.Y <= bar.Position.Y + 6 then
                dragging = true
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    self:AddComponent(label, 26)
    self:AddComponent(bar, 8)
    self:AddComponent(fill, 0)

    return label
end


return Library
