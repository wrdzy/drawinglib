-- UI Library using Drawing API for exploit use
-- Made for personal/private game testing

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

-- Window class
function Library:CreateWindow(name, size, position)
    local self = setmetatable({}, Library)
    self.Name = name or "Window"
    self.Size = size or Vector2.new(300, 300)
    self.Position = position or Vector2.new(100, 100)
    self.Objects = {}
    self.Tabs = {}
    self.ActiveTab = nil
    self.Dragging = false
    self.DragOffset = Vector2.new()
    self.ComponentY = 35

    -- Background
    self.Background = create("Square", {
        Size = self.Size,
        Position = self.Position,
        Color = Color3.fromRGB(30, 30, 30),
        Filled = true,
        Transparency = 1,
        Visible = true,
    })

    -- Title bar
    self.TitleBar = create("Square", {
        Size = Vector2.new(self.Size.X, 25),
        Position = self.Position,
        Color = Color3.fromRGB(45, 45, 45),
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
        Position = self.Position + Vector2.new(5, 4),
        Visible = true,
    })

    -- Dragging
    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= self.Position.X and mouse.X <= self.Position.X + self.Size.X and
               mouse.Y >= self.Position.Y and mouse.Y <= self.Position.Y + 25 then
                self.Dragging = true
                self.DragOffset = mouse - self.Position
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
            self.Title.Position = self.Position + Vector2.new(5, 4)

            local offsetY = 35
            for _, obj in ipairs(self.Objects) do
                if obj._type == "component" then
                    obj.ref.Position = self.Position + Vector2.new(10, offsetY)
                    offsetY = offsetY + 25
                end
            end
        end
    end)

    return self
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
        Color = Color3.fromRGB(200, 200, 255),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = btn, _type = "component"})

    btn.MouseDown = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= btn.Position.X and mouse.X <= btn.Position.X + 100 and
               mouse.Y >= btn.Position.Y and mouse.Y <= btn.Position.Y + 20 then
                pcall(callback)
            end
        end
    end)
    self.ComponentY = self.ComponentY + 25
    return btn
end

function Library:CreateToggle(text, callback)
    local state = false
    local toggle = create("Text", {
        Text = "[ ] " .. text,
        Size = 16,
        Color = Color3.fromRGB(255, 255, 180),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = toggle, _type = "component"})

    toggle.MouseDown = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= toggle.Position.X and mouse.X <= toggle.Position.X + 150 and
               mouse.Y >= toggle.Position.Y and mouse.Y <= toggle.Position.Y + 20 then
                state = not state
                toggle.Text = (state and "[x] " or "[ ] ") .. text
                pcall(callback, state)
            end
        end
    end)
    self.ComponentY = self.ComponentY + 25
    return toggle
end

function Library:CreateSlider(text, min, max, default, callback)
    local value = default or min
    local label = create("Text", {
        Text = text .. ": " .. tostring(value),
        Size = 16,
        Color = Color3.fromRGB(180, 255, 180),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = label, _type = "component"})

    local dragging = false
    local width = 100
    local bar = create("Square", {
        Size = Vector2.new(width, 5),
        Position = self.Position + Vector2.new(10, self.ComponentY + 20),
        Color = Color3.fromRGB(100, 100, 255),
        Filled = true,
        Visible = true,
    })

    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            local mouse = UIS:GetMouseLocation()
            local percent = math.clamp((mouse.X - bar.Position.X) / width, 0, 1)
            value = round(min + (max - min) * percent, 1)
            label.Text = text .. ": " .. tostring(value)
            pcall(callback, value)
        end
    end)

    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UIS:GetMouseLocation()
            if mouse.X >= bar.Position.X and mouse.X <= bar.Position.X + width and
               mouse.Y >= bar.Position.Y and mouse.Y <= bar.Position.Y + 10 then
                dragging = true
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    table.insert(self.Objects, {ref = bar, _type = "component"})
    self.ComponentY = self.ComponentY + 40
    return label, bar
end

-- Tabs (very basic implementation for now)
function Library:CreateTab(name)
    local tab = {
        Name = name,
        Elements = {}
    }
    self.Tabs[#self.Tabs + 1] = tab
    return tab
end

-- Input Box (simulation with text update only)
function Library:CreateInputBox(placeholder, callback)
    local value = ""
    local box = create("Text", {
        Text = placeholder .. ": [ click to input ]",
        Size = 16,
        Color = Color3.fromRGB(200, 255, 200),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = box, _type = "component"})

    box.MouseDown = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local userInput = tostring(game:GetService("Players").LocalPlayer.Name)
            value = userInput
            box.Text = placeholder .. ": [ " .. value .. " ]"
            pcall(callback, value)
        end
    end)
    self.ComponentY = self.ComponentY + 25
    return box
end

-- Dropdown (simulated click cycling)
function Library:CreateDropdown(title, options, callback)
    local index = 1
    local dropdown = create("Text", {
        Text = title .. ": [ " .. options[index] .. " ]",
        Size = 16,
        Color = Color3.fromRGB(255, 220, 150),
        Center = false,
        Outline = true,
        Position = self.Position + Vector2.new(10, self.ComponentY),
        Visible = true,
    })
    table.insert(self.Objects, {ref = dropdown, _type = "component"})

    dropdown.MouseDown = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            index = index + 1
            if index > #options then index = 1 end
            dropdown.Text = title .. ": [ " .. options[index] .. " ]"
            pcall(callback, options[index])
        end
    end)
    self.ComponentY = self.ComponentY + 25
    return dropdown
end

function Library:Destroy()
    self.Background:Remove()
    self.TitleBar:Remove()
    self.Title:Remove()
    for _, obj in pairs(self.Objects) do
        obj.ref:Remove()
    end
end

return Library
