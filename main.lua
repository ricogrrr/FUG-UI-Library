--[[
    ==========================================================================
     SimpleUI - A lightweight, single-file Roblox UI library
    ==========================================================================

    USAGE:
        local Library = loadstring(game:HttpGet("URL"))()

        local Window = Library:CreateWindow({ Title = "Example Hub", Size = UDim2.fromOffset(550, 400) })
        local Tab = Window:CreateTab("Main")

        Tab:CreateButton({ Name = "Print Hello", Callback = function() print("Hello!") end })

    SECTIONS IN THIS FILE:
        1. Services & Utilities
        2. Theme
        3. Instance helper / Tween helper / Drag helper
        4. Notifications
        5. Component: Button
        6. Component: Toggle
        7. Component: Slider
        8. Component: Dropdown
        9. Component: Textbox
        10. Component: Label
        11. Component: Section / Divider
        12. Tab
        13. Window
        14. Library entrypoint
    ==========================================================================
]]

--// ==========================================================================
--// 1. SERVICES & UTILITIES
--// ==========================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Root container. pcall in case gethui / CoreGui access is restricted by the executor.
local function getRootParent()
    local ok, hui = pcall(function()
        return gethui and gethui() or CoreGui
    end)
    if ok and hui then
        return hui
    end
    return CoreGui
end

--// ==========================================================================
--// 2. THEME
--// ==========================================================================

local Theme = {
    Accent          = Color3.fromRGB(120, 80, 255),
    Background      = Color3.fromRGB(20, 20, 25),
    Panel           = Color3.fromRGB(28, 28, 34),
    PanelLight      = Color3.fromRGB(36, 36, 44),
    Border          = Color3.fromRGB(48, 48, 56),
    Text            = Color3.fromRGB(235, 235, 240),
    SubText         = Color3.fromRGB(160, 160, 170),
    Font            = Enum.Font.Gotham,
    FontBold        = Enum.Font.GothamBold,
    CornerRadius    = UDim.new(0, 6),
    TweenSpeed      = 0.18,
}

--// ==========================================================================
--// 3. HELPERS: instance creation, tweening, dragging
--// ==========================================================================

-- Creates a new Instance and applies a property table + optional children.
local function New(className, props, children)
    local inst = Instance.new(className)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

-- Shortcut to add rounded corners.
local function AddCorner(parent, radius)
    return New("UICorner", { CornerRadius = radius or Theme.CornerRadius, Parent = parent })
end

-- Shortcut to add a subtle border stroke.
local function AddStroke(parent, color, thickness)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

-- Runs a lightweight tween. Returns the Tween object.
local function Tween(instance, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or Theme.TweenSpeed,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(instance, info, props)
    tw:Play()
    return tw
end

-- Makes `handle` drag `target` around the screen. Returns a disconnect function.
local function MakeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos
    local connections = {}

    table.insert(connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConn then changedConn:Disconnect() end
                end
            end)
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    return function()
        for _, c in ipairs(connections) do
            c:Disconnect()
        end
    end
end

-- Adds a simple hover/press color effect to a button-like GuiObject.
local function AddHoverEffect(button, baseColor, hoverColor, pressColor)
    local connections = {}
    table.insert(connections, button.MouseEnter:Connect(function()
        Tween(button, { BackgroundColor3 = hoverColor })
    end))
    table.insert(connections, button.MouseLeave:Connect(function()
        Tween(button, { BackgroundColor3 = baseColor })
    end))
    if pressColor then
        table.insert(connections, button.MouseButton1Down:Connect(function()
            Tween(button, { BackgroundColor3 = pressColor }, 0.08)
        end))
        table.insert(connections, button.MouseButton1Up:Connect(function()
            Tween(button, { BackgroundColor3 = hoverColor }, 0.08)
        end))
    end
    return function()
        for _, c in ipairs(connections) do c:Disconnect() end
    end
end

--// ==========================================================================
--// LIBRARY TABLE
--// ==========================================================================

local Library = {}
Library.__index = Library

Library.Theme = Theme
Library.Windows = {}
Library.Flags = {} -- optional global flag store for components with a Flag field

--// ==========================================================================
--// 4. NOTIFICATIONS
--// ==========================================================================

local NotificationHolder -- created lazily on first Notify call

local function ensureNotificationHolder()
    if NotificationHolder and NotificationHolder.Parent then
        return NotificationHolder
    end

    local screenGui = New("ScreenGui", {
        Name = "SimpleUI_Notifications",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getRootParent(),
    })

    NotificationHolder = New("Frame", {
        Name = "NotificationHolder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 300, 1, -32),
        Parent = screenGui,
    })

    New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = NotificationHolder,
    })

    return NotificationHolder
end

-- Library:Notify({ Title, Content, Duration })
function Library:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration or 3

    local holder = ensureNotificationHolder()

    local card = New("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        LayoutOrder = -os.clock(),
        Parent = holder,
    })
    AddCorner(card)
    AddStroke(card)

    local accentBar = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        Parent = card,
    })
    AddCorner(accentBar, UDim.new(0, 2))

    local padding = New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 10),
        Parent = card,
    })

    local titleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18),
        Parent = card,
    })

    local contentLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = content,
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    })

    -- Fade / slide in
    card.BackgroundTransparency = 1
    accentBar.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    contentLabel.TextTransparency = 1
    local originalSize = card.Size

    Tween(card, { BackgroundTransparency = 0 }, 0.2)
    Tween(accentBar, { BackgroundTransparency = 0 }, 0.2)
    Tween(titleLabel, { TextTransparency = 0 }, 0.2)
    Tween(contentLabel, { TextTransparency = 0.15 }, 0.2)

    task.delay(duration, function()
        if not card or not card.Parent then return end
        Tween(card, { BackgroundTransparency = 1 }, 0.25)
        Tween(accentBar, { BackgroundTransparency = 1 }, 0.25)
        Tween(titleLabel, { TextTransparency = 1 }, 0.25)
        Tween(contentLabel, { TextTransparency = 1 }, 0.25)
        task.wait(0.25)
        if card then card:Destroy() end
    end)
end

--// SetTheme lets a developer override global theme colors before/after creating a window.
function Library:SetTheme(newTheme)
    newTheme = newTheme or {}
    for key, value in pairs(newTheme) do
        Theme[key] = value
    end
end

--// ==========================================================================
--// WINDOW / TAB / COMPONENT IMPLEMENTATION
--// ==========================================================================

--// ------------------------------------------------------------------------
--// 12. TAB
--// ------------------------------------------------------------------------

local Tab = {}
Tab.__index = Tab

-- Internal: creates a new Tab object bound to a page Frame and a tab button.
local function newTab(window, name)
    local self = setmetatable({}, Tab)
    self._window = window
    self._connections = {}

    -- Tab button in the sidebar
    self.Button = New("TextButton", {
        Name = name .. "TabButton",
        BackgroundColor3 = Theme.PanelLight,
        AutoButtonColor = false,
        Font = Theme.Font,
        Text = "  " .. name,
        TextColor3 = Theme.SubText,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = window.SidebarList,
    })
    AddCorner(self.Button, UDim.new(0, 5))

    -- Page (scrolling frame that holds components)
    self.Page = New("ScrollingFrame", {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        Visible = false,
        Parent = window.PageHolder,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.Page,
    })

    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 8),
        Parent = self.Page,
    })

    local unhover = AddHoverEffect(self.Button, Theme.PanelLight, Theme.Border, Theme.Border)
    table.insert(self._connections, unhover)

    table.insert(self._connections, self.Button.MouseButton1Click:Connect(function()
        window:SelectTab(self)
    end))

    return self
end

-- Internal helper shared by components: wraps a control in a standard "row" frame with a label.
local function baseRow(tab, height)
    local row = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, 0, 0, height or 36),
        Parent = tab.Page,
    })
    AddCorner(row)
    AddStroke(row)
    return row
end

--// ------------------------------------------------------------------------
--// 5. COMPONENT: BUTTON
--// ------------------------------------------------------------------------

function Tab:CreateButton(config)
    config = config or {}
    local name = config.Name or "Button"
    local callback = config.Callback or function() end

    local row = baseRow(self, 36)

    local button = New("TextButton", {
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = row,
    })

    -- NOTE: hover/press effects are driven off `button` (the actual TextButton, which
    -- receives the input events) but recolor `row` (the visible Frame behind it), since
    -- Frame instances don't have MouseButton1Down/Up events of their own.
    local hoverConnections = {}
    table.insert(hoverConnections, button.MouseEnter:Connect(function()
        Tween(row, { BackgroundColor3 = Theme.PanelLight })
    end))
    table.insert(hoverConnections, button.MouseLeave:Connect(function()
        Tween(row, { BackgroundColor3 = Theme.Panel })
    end))
    table.insert(hoverConnections, button.MouseButton1Down:Connect(function()
        Tween(row, { BackgroundColor3 = Theme.Border }, 0.08)
    end))
    table.insert(hoverConnections, button.MouseButton1Up:Connect(function()
        Tween(row, { BackgroundColor3 = Theme.PanelLight }, 0.08)
    end))

    local connection = button.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then
            warn("[SimpleUI] Button callback error: " .. tostring(err))
        end
    end)

    local ButtonObj = {}
    function ButtonObj:SetCallback(newCallback)
        callback = newCallback or function() end
    end
    function ButtonObj:Destroy()
        connection:Disconnect()
        for _, c in ipairs(hoverConnections) do c:Disconnect() end
        row:Destroy()
    end

    return ButtonObj
end

--// ------------------------------------------------------------------------
--// 6. COMPONENT: TOGGLE
--// ------------------------------------------------------------------------

function Tab:CreateToggle(config)
    config = config or {}
    local name = config.Name or "Toggle"
    local default = config.Default == true
    local callback = config.Callback or function() end

    local row = baseRow(self, 36)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Parent = row,
    })

    local switchBG = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 38, 0, 20),
        BackgroundColor3 = default and Theme.Accent or Theme.Border,
        Parent = row,
    })
    AddCorner(switchBG, UDim.new(1, 0))

    local knob = New("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = switchBG,
    })
    AddCorner(knob, UDim.new(1, 0))

    local clickArea = New("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        Parent = row,
    })

    local state = default

    local function applyVisual(animate)
        local goalPos = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local goalColor = state and Theme.Accent or Theme.Border
        if animate then
            Tween(knob, { Position = goalPos })
            Tween(switchBG, { BackgroundColor3 = goalColor })
        else
            knob.Position = goalPos
            switchBG.BackgroundColor3 = goalColor
        end
    end

    local ToggleObj = {}

    function ToggleObj:Set(value, silent)
        state = value == true
        applyVisual(true)
        if not silent then
            local ok, err = pcall(callback, state)
            if not ok then warn("[SimpleUI] Toggle callback error: " .. tostring(err)) end
        end
    end

    function ToggleObj:Get()
        return state
    end

    function ToggleObj:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    local connection = clickArea.MouseButton1Click:Connect(function()
        ToggleObj:Set(not state)
    end)

    function ToggleObj:Destroy()
        connection:Disconnect()
        row:Destroy()
    end

    -- Fire initial callback state quietly (does not call callback, matches "Default" semantics)
    return ToggleObj
end

--// ------------------------------------------------------------------------
--// 7. COMPONENT: SLIDER
--// ------------------------------------------------------------------------

function Tab:CreateSlider(config)
    config = config or {}
    local name = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    if max <= min then max = min + 1 end -- guard against invalid config
    local default = config.Default or min
    default = math.clamp(default, min, max)
    local callback = config.Callback or function() end

    local row = baseRow(self, 46)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0, 4),
        Size = UDim2.new(1, -70, 0, 18),
        Parent = row,
    })

    local valueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = tostring(default),
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -60, 0, 4),
        Size = UDim2.new(0, 50, 0, 18),
        Parent = row,
    })

    local track = New("Frame", {
        BackgroundColor3 = Theme.PanelLight,
        Position = UDim2.new(0, 12, 1, -14),
        Size = UDim2.new(1, -24, 0, 6),
        Parent = row,
    })
    AddCorner(track, UDim.new(1, 0))

    local fill = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        Parent = track,
    })
    AddCorner(fill, UDim.new(1, 0))

    local dragButton = New("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        Parent = track,
    })

    local value = default
    local dragging = false
    local connections = {}

    local function setFromAlpha(alpha)
        alpha = math.clamp(alpha, 0, 1)
        local raw = min + (max - min) * alpha
        -- round to nearest integer for a clean UX; developers can post-process floats if needed
        raw = math.floor(raw + 0.5)
        value = raw
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        valueLabel.Text = tostring(value)
    end

    local function updateFromInput(input)
        local relativeX = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        setFromAlpha(relativeX)
    end

    table.insert(connections, dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                local ok, err = pcall(callback, value)
                if not ok then warn("[SimpleUI] Slider callback error: " .. tostring(err)) end
            end
        end
    end))

    local SliderObj = {}

    function SliderObj:Set(newValue, silent)
        newValue = math.clamp(newValue, min, max)
        local alpha = (newValue - min) / (max - min)
        setFromAlpha(alpha)
        if not silent then
            local ok, err = pcall(callback, value)
            if not ok then warn("[SimpleUI] Slider callback error: " .. tostring(err)) end
        end
    end

    function SliderObj:Get()
        return value
    end

    function SliderObj:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    function SliderObj:Destroy()
        for _, c in ipairs(connections) do c:Disconnect() end
        row:Destroy()
    end

    return SliderObj
end

--// ------------------------------------------------------------------------
--// 8. COMPONENT: DROPDOWN
--// ------------------------------------------------------------------------

function Tab:CreateDropdown(config)
    config = config or {}
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local default = config.Default
    if default == nil or not table.find(options, default) then
        default = options[1]
    end
    local callback = config.Callback or function() end

    local row = baseRow(self, 36)
    row.ClipsDescendants = false -- allow the option list to overflow visually

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Parent = row,
    })

    local selectorButton = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 140, 0, 26),
        BackgroundColor3 = Theme.PanelLight,
        AutoButtonColor = false,
        Font = Theme.Font,
        Text = tostring(default or "None"),
        TextColor3 = Theme.SubText,
        TextSize = 13,
        Parent = row,
    })
    AddCorner(selectorButton, UDim.new(0, 5))
    AddStroke(selectorButton)

    local listFrame = New("Frame", {
        BackgroundColor3 = Theme.PanelLight,
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 5,
        Parent = selectorButton,
    })
    AddCorner(listFrame)
    AddStroke(listFrame)

    local listLayout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listFrame,
    })

    local value = default
    local open = false
    local optionButtons = {}
    local connections = {}

    local function closeList()
        open = false
        listFrame.Visible = false
        listFrame.Size = UDim2.new(1, 0, 0, 0)
    end

    local function openList()
        open = true
        listFrame.Visible = true
        listFrame.Size = UDim2.new(1, 0, 0, math.min(#optionButtons * 24, 120))
    end

    local DropdownObj = {}

    local function rebuildOptions(newOptions)
        for _, btn in ipairs(optionButtons) do
            btn:Destroy()
        end
        optionButtons = {}
        options = newOptions or {}

        for _, option in ipairs(options) do
            local optButton = New("TextButton", {
                BackgroundColor3 = Theme.PanelLight,
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Font = Theme.Font,
                Text = tostring(option),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 6,
                Parent = listFrame,
            })
            table.insert(connections, optButton.MouseButton1Click:Connect(function()
                DropdownObj:Set(option)
                closeList()
            end))
            table.insert(optionButtons, optButton)
        end
    end

    rebuildOptions(options)

    table.insert(connections, selectorButton.MouseButton1Click:Connect(function()
        if open then closeList() else openList() end
    end))

    function DropdownObj:Set(newValue, silent)
        value = newValue
        selectorButton.Text = tostring(value or "None")
        if not silent then
            local ok, err = pcall(callback, value)
            if not ok then warn("[SimpleUI] Dropdown callback error: " .. tostring(err)) end
        end
    end

    function DropdownObj:Get()
        return value
    end

    function DropdownObj:SetOptions(newOptions)
        rebuildOptions(newOptions)
        if not table.find(options, value) then
            DropdownObj:Set(options[1], true)
        end
    end

    function DropdownObj:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    function DropdownObj:Destroy()
        for _, c in ipairs(connections) do c:Disconnect() end
        row:Destroy()
    end

    return DropdownObj
end

--// ------------------------------------------------------------------------
--// 9. COMPONENT: TEXTBOX
--// ------------------------------------------------------------------------

function Tab:CreateTextbox(config)
    config = config or {}
    local name = config.Name or "Textbox"
    local placeholder = config.Placeholder or "Enter text..."
    local default = config.Default or ""
    local callback = config.Callback or function() end

    local row = baseRow(self, 36)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        Parent = row,
    })

    local inputBG = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 150, 0, 26),
        BackgroundColor3 = Theme.PanelLight,
        Parent = row,
    })
    AddCorner(inputBG, UDim.new(0, 5))
    AddStroke(inputBG)

    local textBox = New("TextBox", {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        PlaceholderText = placeholder,
        Text = default,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.SubText,
        TextSize = 13,
        ClearTextOnFocus = false,
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        Parent = inputBG,
    })

    local TextboxObj = {}

    local connection = textBox.FocusLost:Connect(function(enterPressed)
        local ok, err = pcall(callback, textBox.Text, enterPressed)
        if not ok then warn("[SimpleUI] Textbox callback error: " .. tostring(err)) end
    end)

    function TextboxObj:Set(text, silent)
        textBox.Text = text or ""
        if not silent then
            local ok, err = pcall(callback, textBox.Text, false)
            if not ok then warn("[SimpleUI] Textbox callback error: " .. tostring(err)) end
        end
    end

    function TextboxObj:Get()
        return textBox.Text
    end

    function TextboxObj:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    function TextboxObj:Destroy()
        connection:Disconnect()
        row:Destroy()
    end

    return TextboxObj
end

--// ------------------------------------------------------------------------
--// 10. COMPONENT: LABEL
--// ------------------------------------------------------------------------

function Tab:CreateLabel(config)
    config = config or {}
    local text = config.Text or config.Name or "Label"

    local row = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = self.Page,
    })

    local label = New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = row,
    })

    local LabelObj = {}

    function LabelObj:Set(newText)
        label.Text = newText
    end

    function LabelObj:Get()
        return label.Text
    end

    function LabelObj:Destroy()
        row:Destroy()
    end

    return LabelObj
end

--// ------------------------------------------------------------------------
--// 11. COMPONENT: SECTION / DIVIDER
--// ------------------------------------------------------------------------

function Tab:CreateSection(name)
    local row = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = self.Page,
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = name or "Section",
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 16),
        Parent = row,
    })

    New("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = row,
    })

    return { Destroy = function() row:Destroy() end }
end

-- Alias, since "Divider" is a common name for a plain separator with no title.
function Tab:CreateDivider()
    local row = New("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self.Page,
    })
    return { Destroy = function() row:Destroy() end }
end

--// ==========================================================================
--// 13. WINDOW
--// ==========================================================================

local Window = {}
Window.__index = Window

function Window:CreateTab(name)
    name = name or ("Tab" .. (#self.Tabs + 1))
    local tab = newTab(self, name)
    table.insert(self.Tabs, tab)

    -- First tab created becomes the active tab automatically.
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    for _, t in ipairs(self.Tabs) do
        local isActive = t == tab
        t.Page.Visible = isActive
        t.Button.TextColor3 = isActive and Theme.Text or Theme.SubText
        Tween(t.Button, { BackgroundColor3 = isActive and Theme.Border or Theme.PanelLight }, 0.15)
    end
    self.ActiveTab = tab
end

function Window:SetVisible(visible)
    self.Gui.Enabled = visible
    self.Visible = visible
end

function Window:Toggle()
    self:SetVisible(not self.Visible)
end

-- Cleans up all connections and destroys the ScreenGui.
function Window:Destroy()
    for _, c in ipairs(self._connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, tab in ipairs(self.Tabs) do
        for _, c in ipairs(tab._connections) do
            pcall(function() c() end) -- some stored as disconnect functions
        end
    end
    if self.Gui then
        self.Gui:Destroy()
    end
end

--// ==========================================================================
--// Library:CreateWindow
--// ==========================================================================

function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Window"
    local size = config.Size or UDim2.fromOffset(550, 400)
    local toggleKey = config.ToggleKeybind or Enum.KeyCode.RightControl

    local self = setmetatable({}, Window)
    self.Tabs = {}
    self.Visible = true
    self._connections = {}

    -- Root ScreenGui
    self.Gui = New("ScreenGui", {
        Name = "SimpleUI_" .. title:gsub("%s+", ""),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getRootParent(),
    })

    -- Main window frame
    self.Main = New("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Size = size,
        ClipsDescendants = true,
        Parent = self.Gui,
    })
    AddCorner(self.Main, UDim.new(0, 8))
    AddStroke(self.Main)

    -- Responsive: keep the window within screen bounds on viewport changes.
    local function clampToScreen()
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        if not viewport then return end
        local pos = self.Main.AbsolutePosition
        local sz = self.Main.AbsoluteSize
        local newX = math.clamp(pos.X, 0, math.max(0, viewport.X - sz.X))
        local newY = math.clamp(pos.Y, 0, math.max(0, viewport.Y - sz.Y))
        if newX ~= pos.X or newY ~= pos.Y then
            self.Main.Position = UDim2.fromOffset(newX, newY)
        end
    end
    -- Guard against CurrentCamera being momentarily nil (can happen right at script start).
    if workspace.CurrentCamera then
        table.insert(self._connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(clampToScreen))
    end
    table.insert(self._connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if workspace.CurrentCamera then
            table.insert(self._connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(clampToScreen))
        end
    end))

    -- Title bar
    local titleBar = New("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, 0, 0, 36),
        Parent = self.Main,
    })
    AddCorner(titleBar, UDim.new(0, 8))
    -- Mask the bottom corners of the title bar so it looks flush with the body below.
    New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        Parent = titleBar,
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -90, 1, 0),
        Parent = titleBar,
    })

    -- Close button
    local closeButton = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Theme.PanelLight,
        AutoButtonColor = false,
        Font = Theme.FontBold,
        Text = "X",
        TextColor3 = Theme.SubText,
        TextSize = 13,
        Parent = titleBar,
    })
    AddCorner(closeButton, UDim.new(0, 5))
    local unhoverClose = AddHoverEffect(closeButton, Theme.PanelLight, Color3.fromRGB(200, 60, 60), Color3.fromRGB(160, 40, 40))

    -- Minimize button
    local minimizeButton = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -40, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Theme.PanelLight,
        AutoButtonColor = false,
        Font = Theme.FontBold,
        Text = "-",
        TextColor3 = Theme.SubText,
        TextSize = 15,
        Parent = titleBar,
    })
    AddCorner(minimizeButton, UDim.new(0, 5))
    local unhoverMin = AddHoverEffect(minimizeButton, Theme.PanelLight, Theme.Border, Theme.Border)

    -- Body: sidebar (tabs) + page holder
    local body = New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        Parent = self.Main,
    })

    local sidebar = New("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(0, 130, 1, 0),
        Parent = body,
    })

    self.SidebarList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        Parent = sidebar,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.SidebarList,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = self.SidebarList,
    })

    self.PageHolder = New("Frame", {
        Name = "PageHolder",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 130, 0, 0),
        Size = UDim2.new(1, -130, 1, 0),
        Parent = body,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 4),
        Parent = self.PageHolder,
    })

    -- Dragging
    local unbindDrag = MakeDraggable(titleBar, self.Main)

    -- Close / minimize behavior
    table.insert(self._connections, closeButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end))

    local minimized = false
    local expandedSize = size
    table.insert(self._connections, minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(self.Main, { Size = UDim2.new(0, size.X.Offset, 0, 36) }, 0.2)
            body.Visible = false
        else
            body.Visible = true
            Tween(self.Main, { Size = expandedSize }, 0.2)
        end
    end))

    -- Keybind to show/hide the whole UI
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            self:Toggle()
        end
    end))

    table.insert(self._connections, function() unbindDrag() end)
    table.insert(self._connections, function() unhoverClose() end)
    table.insert(self._connections, function() unhoverMin() end)

    -- Fade-in intro animation (subtle, lightweight)
    self.Main.BackgroundTransparency = 1
    self.Main.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, 0)
    Tween(self.Main, { BackgroundTransparency = 0, Size = size }, 0.25)

    table.insert(Library.Windows, self)
    return self
end

--// ==========================================================================
--// 14. LIBRARY ENTRYPOINT
--// ==========================================================================

return Library
