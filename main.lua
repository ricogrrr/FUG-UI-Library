--[[
    FUG UI Library
    A lightweight, single-file Roblox UI framework.
    Usage:
        local Library = loadstring(game:HttpGet("URL"))()
        local Window = Library:CreateWindow({ Title = "My Hub", Size = UDim2.fromOffset(550, 400) })
]]

--| Services |--
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--| Theme |--
local Theme = {
    -- Deep navy surfaces keep the UI calm while the violet accent adds hierarchy.
    Accent = Color3.fromRGB(139, 92, 246),
    AccentHover = Color3.fromRGB(167, 139, 250),
    AccentSoft = Color3.fromRGB(61, 42, 112),
    Background = Color3.fromRGB(11, 15, 28),
    Panel = Color3.fromRGB(18, 24, 41),
    PanelLight = Color3.fromRGB(27, 35, 57),
    PanelHover = Color3.fromRGB(36, 46, 73),
    Text = Color3.fromRGB(244, 247, 255),
    TextDark = Color3.fromRGB(150, 161, 185),
    Border = Color3.fromRGB(52, 65, 94),
    Success = Color3.fromRGB(52, 211, 153),
    Warning = Color3.fromRGB(251, 191, 36),
    Error = Color3.fromRGB(248, 113, 113),
    CornerRadius = UDim.new(0, 9),
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
}

--| Utility |--
local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function tween(inst, time, props)
    local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function round(inst, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = inst })
end

local function stroke(inst, color, thickness)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = 0.5,
        Parent = inst,
    })
end

local function padding(inst, pad)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, pad),
        PaddingRight = UDim.new(0, pad),
        PaddingTop = UDim.new(0, pad),
        PaddingBottom = UDim.new(0, pad),
        Parent = inst,
    })
end

--| Cleanup tracking |--
local Connections = {}
local function track(conn)
    table.insert(Connections, conn)
    return conn
end

--| Library table |--
local Library = {}

function Library:SetTheme(t)
    for k, v in pairs(t) do
        Theme[k] = v
    end
end

--| Notifications |--
local NotifyFolder
local function ensureNotifyFolder()
    if NotifyFolder and NotifyFolder.Parent then return NotifyFolder end
    local sg = create("ScreenGui", { Name = "FUGNotifications", ResetOnSpawn = false })
    sg.Parent = CoreGui
    NotifyFolder = create("Frame", {
        Name = "Container",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 300, 0, 0),
        BackgroundTransparency = 1,
        Parent = sg,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = NotifyFolder,
    })
    return NotifyFolder
end

function Library:Notify(cfg)
    cfg = cfg or {}
    local container = ensureNotifyFolder()
    local notif = create("Frame", {
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        Parent = container,
    })
    round(notif, 9)
    stroke(notif, Theme.Border, 1)
    padding(notif, 12)
    create("Frame", { Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 0, 0, 8), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = notif })
    round(notif, 9)

    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = notif,
    })

    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = cfg.Title or "Notification",
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local content = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = cfg.Content or "",
        TextColor3 = Theme.TextDark,
        Font = Theme.Font,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.Position = UDim2.new(1, 20, 0, 0)
    notif.AnchorPoint = Vector2.new(0, 0)
    tween(notif, 0.25, { Position = UDim2.new(0, 0, 0, 0) })

    task.delay(cfg.Duration or 3, function()
        tween(notif, 0.25, { Position = UDim2.new(1, 20, 0, 0) })
        task.wait(0.3)
        notif:Destroy()
    end)
end

--| Window |--
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "FUG Library"
    local size = cfg.Size or UDim2.fromOffset(550, 400)

    local sg = create("ScreenGui", {
        Name = "FUG_" .. title,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    })
    sg.Parent = CoreGui

    -- Main window frame
    local Window = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = false,
        Active = true,
        Draggable = false,
        Parent = sg,
    })
    round(Window, 12)
    stroke(Window, Theme.Border, 1)

    -- Shadow
    local shadow = create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 30, 1, 30),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.62,
        ZIndex = -1,
        Parent = Window,
    })

    -- Title bar
    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.Panel,
        Parent = Window,
    })
    round(titleBar, 12)

    -- Cover bottom corners of title bar
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    local titleLabel = create("TextLabel", {
        Size = UDim2.new(1, -118, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    -- Close button
    local closeBtn = create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -38, 0, 8),
        BackgroundColor3 = Theme.PanelLight,
        Text = "",
        AutoButtonColor = false,
        Parent = titleBar,
    })
    round(closeBtn, 6)
    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 14,
        Parent = closeBtn,
    })

    -- Minimize button
    local minBtn = create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -74, 0, 8),
        BackgroundColor3 = Theme.PanelLight,
        Text = "",
        AutoButtonColor = false,
        Parent = titleBar,
    })
    round(minBtn, 6)
    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 16,
        Parent = minBtn,
    })

    create("Frame", {
        Name = "AccentRule",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    -- Tab bar (left sidebar)
    local sideBar = create("Frame", {
        Name = "SideBar",
        Size = UDim2.new(0, 146, 1, -46),
        Position = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = Window,
    })

    local tabList = create("Frame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        BackgroundTransparency = 1,
        Parent = sideBar,
    })
    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList,
    })
    padding(tabList, 6)

    -- Content area
    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -146, 1, -46),
        Position = UDim2.new(0, 146, 0, 46),
        BackgroundTransparency = 1,
        Parent = Window,
    })

    -- Minimized state
    local minimized = false
    local contentHolder = create("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -18, 1, -18),
        Position = UDim2.new(0, 9, 0, 9),
        BackgroundTransparency = 1,
        Parent = contentArea,
    })

    --| Draggable |--
    local dragging, dragStart, startPos
    track(titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    --| Close |--
    track(closeBtn.MouseButton1Click:Connect(function()
        tween(Window, 0.2, { Size = UDim2.new(0, 0, 0, 0) })
        task.wait(0.2)
        sg:Destroy()
        for i, c in ipairs(Connections) do c:Disconnect() end
    end))

    --| Minimize |--
    track(minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(contentArea, 0.2, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 146, 0, 46) })
            tween(sideBar, 0.2, { Size = UDim2.new(0, 146, 0, 0) })
            tween(Window, 0.2, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 46) })
        else
            tween(contentArea, 0.2, { Size = UDim2.new(1, -146, 1, -46), Position = UDim2.new(0, 146, 0, 46) })
            tween(sideBar, 0.2, { Size = UDim2.new(0, 146, 1, -46) })
            tween(Window, 0.2, { Size = size })
        end
    end))

    --| Toggle keybind |--
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl
    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            Window.Visible = not Window.Visible
        end
    end))

    --| Hover effects |--
    for _, btn in ipairs({ closeBtn, minBtn }) do
        track(btn.MouseEnter:Connect(function()
            tween(btn, 0.15, { BackgroundColor3 = Theme.PanelHover })
        end))
        track(btn.MouseLeave:Connect(function()
            tween(btn, 0.15, { BackgroundColor3 = Theme.PanelLight })
        end))
    end

    --| Tab system |--
    local tabs = {}
    local tabLabels = {} -- maps tabBtn -> label TextLabel (for icon tabs)
    local tabCount = 0

    local WindowObj = {}

    function WindowObj:CreateTab(name, icon)
        tabCount = tabCount + 1
        local tabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.PanelLight,
            BackgroundTransparency = 1,
            Text = icon and ("  " .. name) or name,
            TextColor3 = Theme.TextDark,
            Font = Theme.Font,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = tabList,
        })
        round(tabBtn, 8)

        local tabIcon
        local tabLabel
        if icon then
            tabIcon = create("ImageLabel", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 8, 0.5, -8),
                BackgroundTransparency = 1,
                Image = icon,
                Parent = tabBtn,
            })
            tabBtn.TextXAlignment = Enum.TextXAlignment.Left
            -- Adjust text position to leave room for icon
            tabLabel = create("TextLabel", {
                Size = UDim2.new(1, -34, 1, 0),
                Position = UDim2.new(0, 30, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = Theme.TextDark,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tabBtn,
            })
            tabBtn.Text = ""
            tabLabels[tabBtn] = tabLabel
        end

        local page = create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = contentHolder,
        })
        local pageLayout = create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })
        padding(page, 2)

        -- Manual canvas size tracking (replaces AutomaticCanvasSize for compatibility)
        track(pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize + 8)
        end))

        local function selectTab()
            for _, t in ipairs(tabs) do
                t.button.BackgroundTransparency = 1
                local tl = tabLabels[t.button]
                if tl then
                    tl.TextColor3 = Theme.TextDark
                else
                    t.button.TextColor3 = Theme.TextDark
                end
                t.page.Visible = false
            end
            tween(tabBtn, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Accent })
            if tabLabel then
                tabLabel.TextColor3 = Theme.Text
            else
                tabBtn.TextColor3 = Theme.Text
            end
            page.Visible = true
        end

        track(tabBtn.MouseButton1Click:Connect(selectTab))

        local tabObj = { button = tabBtn, page = page }
        table.insert(tabs, tabObj)

        if #tabs == 1 then
            selectTab()
        end

        --| Component builders |--
        local Tab = {}

        function Tab:CreateLabel(text)
            local label = create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.TextDark,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
            return {
                Set = function(_, v) label.Text = v end,
                Get = function() return label.Text end,
            }
        end

        function Tab:CreateSection(titleText)
            create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Parent = page,
            })
            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = titleText,
                TextColor3 = Theme.Accent,
                Font = Theme.FontBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
        end

        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local hasIcon = cfg.Icon ~= nil
            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.PanelLight,
                Text = hasIcon and "" or (cfg.Name or "Button"),
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                AutoButtonColor = false,
                Parent = page,
            })
            round(btn, 8)

            local btnLabel
            if hasIcon then
                create("ImageLabel", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 8, 0.5, -8),
                    BackgroundTransparency = 1,
                    Image = cfg.Icon,
                    Parent = btn,
                })
                btnLabel = create("TextLabel", {
                    Size = UDim2.new(1, -34, 1, 0),
                    Position = UDim2.new(0, 30, 0, 0),
                    BackgroundTransparency = 1,
                    Text = cfg.Name or "Button",
                    TextColor3 = Theme.Text,
                    Font = Theme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = btn,
                })
            end
            local callback = cfg.Callback or function() end
            track(btn.MouseButton1Click:Connect(function()
                callback()
            end))
            track(btn.MouseEnter:Connect(function()
                tween(btn, 0.15, { BackgroundColor3 = Theme.PanelHover })
            end))
            track(btn.MouseLeave:Connect(function()
                tween(btn, 0.15, { BackgroundColor3 = Theme.PanelLight })
            end))
            return {
                SetCallback = function(_, cb) callback = cb end,
                SetName = function(_, n)
                    if btnLabel then
                        btnLabel.Text = n
                    else
                        btn.Text = n
                    end
                end,
            }
        end

        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local value = cfg.Default or false
            local callback = cfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.PanelLight,
                Parent = page,
            })
            round(frame, 8)

            local label = create("TextLabel", {
                Size = UDim2.new(1, -50, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = cfg.Name or "Toggle",
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local knob = create("Frame", {
                Size = UDim2.new(0, 44, 0, 22),
                Position = UDim2.new(1, -54, 0.5, -11),
                BackgroundColor3 = value and Theme.Accent or Theme.Border,
                Parent = frame,
            })
            round(knob, 10)

            local circle = create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(value and 1 or 0, value and -20 or 2, 0.5, -9),
                BackgroundColor3 = Theme.Text,
                Parent = knob,
            })
            round(circle, 9)

            local function update(animate)
                if animate then
                    tween(knob, 0.15, { BackgroundColor3 = value and Theme.Accent or Theme.Border })
                    tween(circle, 0.15, { Position = UDim2.new(value and 1 or 0, value and -20 or 2, 0.5, -9) })
                else
                    knob.BackgroundColor3 = value and Theme.Accent or Theme.Border
                    circle.Position = UDim2.new(value and 1 or 0, value and -20 or 2, 0.5, -9)
                end
            end

            track(frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    value = not value
                    update(true)
                    callback(value)
                end
            end))

            return {
                Set = function(_, v) value = v; update(true); callback(value) end,
                Get = function() return value end,
                SetCallback = function(_, cb) callback = cb end,
            }
        end

        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local value = math.clamp(cfg.Default or min, min, max)
            local callback = cfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = Theme.PanelLight,
                Parent = page,
            })
            round(frame, 8)

            local label = create("TextLabel", {
                Size = UDim2.new(1, -60, 0, 20),
                Position = UDim2.new(0, 10, 0, 4),
                BackgroundTransparency = 1,
                Text = cfg.Name or "Slider",
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local valLabel = create("TextLabel", {
                Size = UDim2.new(0, 50, 0, 20),
                Position = UDim2.new(1, -68, 0, 7),
                BackgroundTransparency = 1,
                Text = tostring(value),
                TextColor3 = Theme.Accent,
                Font = Theme.FontBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = frame,
            })

            local track_ = create("Frame", {
                Size = UDim2.new(1, -20, 0, 7),
                Position = UDim2.new(0, 10, 0, 39),
                BackgroundColor3 = Theme.Border,
                Parent = frame,
            })
            round(track_, 3)

            local fill = create("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                Parent = track_,
            })
            round(fill, 3)

            local knob = create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new((value - min) / (max - min), -7, 0.5, -8),
                BackgroundColor3 = Theme.Text,
                Parent = track_,
            })
            round(knob, 7)

            local dragging2 = false
            local function update()
                local pct = (max == min) and 0 or (value - min) / (max - min)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, -7, 0.5, -8)
                valLabel.Text = tostring(value)
            end

            local function onInput(input)
                local pct = math.clamp((input.Position.X - track_.AbsolutePosition.X) / track_.AbsoluteSize.X, 0, 1)
                value = (max == min) and min or math.floor(min + pct * (max - min))
                update()
                callback(value)
            end

            track(track_.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging2 = true
                    onInput(input)
                end
            end))
            track(UserInputService.InputChanged:Connect(function(input)
                if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    onInput(input)
                end
            end))
            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging2 = false
                end
            end))

            return {
                Set = function(_, v) value = math.clamp(v, min, max); update(); callback(value) end,
                Get = function() return value end,
                SetCallback = function(_, cb) callback = cb end,
            }
        end

        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local options = cfg.Options or {}
            local value = cfg.Default or options[1]
            local callback = cfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.PanelLight,
                Parent = page,
            })
            round(frame, 8)

            local label = create("TextLabel", {
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = (cfg.Name or "Dropdown") .. ": " .. (value or ""),
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local arrow = create("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -25, 0, 0),
                BackgroundTransparency = 1,
                Text = "⌄",
                TextColor3 = Theme.TextDark,
                Font = Theme.FontBold,
                TextSize = 12,
                Parent = frame,
            })

            local expanded = false
            local list = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = Theme.Panel,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 10,
                Parent = frame,
            })
            round(list, 6)
            stroke(list)
            local listLayout = create("UIListLayout", {
                Padding = UDim.new(0, 2),
                Parent = list,
            })
            padding(list, 4)

            local optionBtns = {}
            local function buildOptions()
                for _, b in ipairs(optionBtns) do b:Destroy() end
                optionBtns = {}
                for _, opt in ipairs(options) do
                    local ob = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundColor3 = (opt == value) and Theme.Accent or Theme.PanelLight,
                        BackgroundTransparency = (opt == value) and 0 or 0.3,
                        Text = opt,
                        TextColor3 = Theme.Text,
                        Font = Theme.Font,
                        TextSize = 13,
                        AutoButtonColor = false,
                        ZIndex = 10,
                        Parent = list,
                    })
                    round(ob, 4)
                    track(ob.MouseButton1Click:Connect(function()
                        value = opt
                        label.Text = (cfg.Name or "Dropdown") .. ": " .. opt
                        callback(opt)
                        expanded = false
                        list.Visible = false
                        arrow.Text = "⌄"
                        buildOptions()
                    end))
                    table.insert(optionBtns, ob)
                end
            end
            buildOptions()

            track(frame.MouseButton1Click:Connect(function()
                expanded = not expanded
                list.Visible = expanded
                arrow.Text = expanded and "⌃" or "⌄"
            end))

            return {
                Set = function(_, v)
                    for _, o in ipairs(options) do
                        if o == v then
                            value = v
                            label.Text = (cfg.Name or "Dropdown") .. ": " .. v
                            callback(v)
                            buildOptions()
                            break
                        end
                    end
                end,
                Get = function() return value end,
                SetCallback = function(_, cb) callback = cb end,
                SetOptions = function(_, newOpts)
                    options = newOpts
                    value = options[1]
                    label.Text = (cfg.Name or "Dropdown") .. ": " .. value
                    callback(value)
                    buildOptions()
                end,
            }
        end

        function Tab:CreateTextbox(cfg)
            cfg = cfg or {}
            local callback = cfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.PanelLight,
                Parent = page,
            })
            round(frame, 8)

            local label = create("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = cfg.Name or "Input",
                TextColor3 = Theme.TextDark,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local box = create("TextBox", {
                Size = UDim2.new(1, -108, 0, 28),
                Position = UDim2.new(0, 98, 0.5, -14),
                BackgroundColor3 = Theme.Background,
                Text = "",
                PlaceholderText = cfg.Placeholder or "",
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.TextDark,
                Font = Theme.Font,
                TextSize = 13,
                ClearTextOnFocus = false,
                Parent = frame,
            })
            round(box, 6)
            stroke(box, Theme.Border, 1)

            track(box.FocusLost:Connect(function(enter)
                callback(box.Text)
            end))

            return {
                Set = function(_, v) box.Text = v end,
                Get = function() return box.Text end,
                SetCallback = function(_, cb) callback = cb end,
            }
        end

        return Tab
    end

    return WindowObj
end

return Library
