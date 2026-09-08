--[[
    FUG UI Library — v2
    A lightweight, single-file Roblox UI framework.

    Design language: near-black neutrals, ONE accent color used sparingly,
    two deliberate corner radii (soft shell / sharp controls), mono font
    for numeric readouts, two-layer borders instead of blurred shadow images,
    state indicators that are literal rather than skeuomorphic.

    Usage:
        local Library = loadstring(game:HttpGet("URL"))()
        local Window = Library:CreateWindow({ Title = "My Hub", Size = UDim2.fromOffset(560, 380) })
]]

--| Services |--
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--| Theme |--
local Theme = {
    Accent       = Color3.fromRGB(80, 200, 120),
    AccentDim    = Color3.fromRGB(45, 110, 68),
    Background   = Color3.fromRGB(15, 15, 16),
    Panel        = Color3.fromRGB(20, 20, 21),
    PanelLight   = Color3.fromRGB(26, 26, 28),
    PanelHover   = Color3.fromRGB(33, 33, 36),
    Text         = Color3.fromRGB(235, 235, 235),
    TextDim      = Color3.fromRGB(130, 130, 135),
    Border       = Color3.fromRGB(40, 40, 43),
    BorderLight  = Color3.fromRGB(55, 55, 59),
    Success      = Color3.fromRGB(96, 200, 130),
    Warning      = Color3.fromRGB(220, 170, 80),
    Error        = Color3.fromRGB(220, 90, 90),

    RadiusOuter  = UDim.new(0, 6),
    RadiusInner  = UDim.new(0, 3),

    Font         = Enum.Font.Gotham,
    FontBold     = Enum.Font.GothamBold,
    FontMono     = Enum.Font.Code,
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

local function round(inst, udim)
    create("UICorner", { CornerRadius = udim or Theme.RadiusInner, Parent = inst })
end

-- Two-layer border for depth instead of a blurred shadow image asset.
local function depth(inst, color)
    create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = 1,
        Transparency = 0,
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
        Size = UDim2.new(0, 280, 0, 0),
        BackgroundTransparency = 1,
        Parent = sg,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
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
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.Panel,
        Parent = container,
    })
    round(notif, Theme.RadiusInner)
    depth(notif)

    -- left accent bar signals type instead of a colored icon
    create("Frame", {
        Size = UDim2.new(0, 2, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        BackgroundColor3 = (cfg.Type == "Error" and Theme.Error)
            or (cfg.Type == "Warning" and Theme.Warning)
            or Theme.Accent,
        BorderSizePixel = 0,
        Parent = notif,
    })

    create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = notif,
    })
    padding(notif, 12)

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = cfg.Title or "Notification",
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notif,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 14),
        BackgroundTransparency = 1,
        Text = cfg.Content or "",
        TextColor3 = Theme.TextDim,
        Font = Theme.Font,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notif,
    })

    notif.Position = UDim2.new(1, 20, 0, 0)
    tween(notif, 0.2, { Position = UDim2.new(0, 0, 0, 0) })

    task.delay(cfg.Duration or 3, function()
        tween(notif, 0.2, { Position = UDim2.new(1, 20, 0, 0) })
        task.wait(0.25)
        notif:Destroy()
    end)
end

--| Window |--
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "FUG Library"
    local subtitle = cfg.Subtitle
    local size = cfg.Size or UDim2.fromOffset(560, 380)

    local sg = create("ScreenGui", {
        Name = "FUG_" .. title,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    })
    sg.Parent = CoreGui

    local Window = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        BackgroundColor3 = Theme.Background,
        Active = true,
        Parent = sg,
    })
    round(Window, Theme.RadiusOuter)
    depth(Window, Theme.BorderLight)

    --| Title bar |--
    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, subtitle and 48 or 40),
        BackgroundColor3 = Theme.Panel,
        Parent = Window,
    })
    round(titleBar, Theme.RadiusOuter)
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = titleBar,
    })
    -- single 1px accent underline instead of a thick full-width bar
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    local titleLabel = create("TextLabel", {
        Size = UDim2.new(1, -100, 0, subtitle and 18 or titleBar.Size.Y.Offset),
        Position = UDim2.new(0, 16, 0, subtitle and 8 or 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleBar,
    })

    if subtitle then
        create("TextLabel", {
            Size = UDim2.new(1, -100, 0, 14),
            Position = UDim2.new(0, 16, 0, 26),
            BackgroundTransparency = 1,
            Text = subtitle,
            TextColor3 = Theme.TextDim,
            Font = Theme.FontMono,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = titleBar,
        })
    end

    -- Close / minimize as text glyphs on flat hit-targets, not filled squares
    local closeBtn = create("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -34, 0.5, -13),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Theme.TextDim,
        Font = Theme.FontBold,
        TextSize = 18,
        AutoButtonColor = false,
        Parent = titleBar,
    })
    local minBtn = create("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -60, 0.5, -13),
        BackgroundTransparency = 1,
        Text = "–",
        TextColor3 = Theme.TextDim,
        Font = Theme.FontBold,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = titleBar,
    })
    for _, b in ipairs({ closeBtn, minBtn }) do
        track(b.MouseEnter:Connect(function() tween(b, 0.1, { TextColor3 = Theme.Text }) end))
        track(b.MouseLeave:Connect(function() tween(b, 0.1, { TextColor3 = Theme.TextDim }) end))
    end

    --| Sidebar |--
    local sideBar = create("Frame", {
        Name = "SideBar",
        Size = UDim2.new(0, 132, 1, -titleBar.Size.Y.Offset),
        Position = UDim2.new(0, 0, 0, titleBar.Size.Y.Offset),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = Window,
    })
    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = sideBar,
    })

    local tabList = create("Frame", {
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Parent = sideBar,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList,
    })
    padding(tabList, 6)

    --| Content area |--
    local contentArea = create("Frame", {
        Size = UDim2.new(1, -132, 1, -titleBar.Size.Y.Offset),
        Position = UDim2.new(0, 132, 0, titleBar.Size.Y.Offset),
        BackgroundTransparency = 1,
        Parent = Window,
    })
    local contentHolder = create("Frame", {
        Size = UDim2.new(1, -20, 1, -16),
        Position = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1,
        Parent = contentArea,
    })

    --| Drag |--
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

    --| Close / minimize behavior |--
    track(closeBtn.MouseButton1Click:Connect(function()
        tween(Window, 0.15, { Size = UDim2.new(0, 0, 0, 0) })
        task.wait(0.15)
        sg:Destroy()
        for _, c in ipairs(Connections) do c:Disconnect() end
    end))

    local minimized = false
    track(minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(contentArea, 0.18, { Size = UDim2.new(0, 0, 0, 0) })
            tween(sideBar, 0.18, { Size = UDim2.new(0, 132, 0, 0) })
            tween(Window, 0.18, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, titleBar.Size.Y.Offset) })
        else
            tween(contentArea, 0.18, { Size = UDim2.new(1, -132, 1, -titleBar.Size.Y.Offset) })
            tween(sideBar, 0.18, { Size = UDim2.new(0, 132, 1, -titleBar.Size.Y.Offset) })
            tween(Window, 0.18, { Size = size })
        end
    end))

    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl
    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            Window.Visible = not Window.Visible
        end
    end))

    --| Tabs |--
    local tabs = {}
    local WindowObj = {}

    function WindowObj:CreateTab(name, icon)
        local tabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = tabList,
        })
        round(tabBtn, UDim.new(0, 4))

        -- 2px left accent tick instead of full-bg fill when selected
        local tick = create("Frame", {
            Size = UDim2.new(0, 2, 0, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Parent = tabBtn,
        })

        local offsetX = 12
        if icon then
            create("ImageLabel", {
                Size = UDim2.new(0, 15, 0, 15),
                Position = UDim2.new(0, 10, 0.5, -7.5),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = Theme.TextDim,
                Parent = tabBtn,
            })
            offsetX = 32
        end

        local label = create("TextLabel", {
            Size = UDim2.new(1, -offsetX - 8, 1, 0),
            Position = UDim2.new(0, offsetX, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TextDim,
            Font = Theme.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabBtn,
        })

        local page = create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
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
        track(pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize + 8)
        end))

        local function selectTab()
            for _, t in ipairs(tabs) do
                tween(t.tick, 0.12, { Size = UDim2.new(0, 2, 0, 0) })
                tween(t.label, 0.12, { TextColor3 = Theme.TextDim })
                t.page.Visible = false
            end
            tween(tick, 0.12, { Size = UDim2.new(0, 2, 0.6, 0) })
            tween(label, 0.12, { TextColor3 = Theme.Text })
            page.Visible = true
        end
        track(tabBtn.MouseButton1Click:Connect(selectTab))

        local tabObj = { button = tabBtn, page = page, tick = tick, label = label }
        table.insert(tabs, tabObj)
        if #tabs == 1 then selectTab() end

        --| Components |--
        local Tab = {}

        function Tab:CreateLabel(text)
            local label2 = create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.TextDim,
                Font = Theme.Font,
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
            return {
                Set = function(_, v) label2.Text = v end,
                Get = function() return label2.Text end,
            }
        end

        function Tab:CreateSection(titleText)
            local wrap = create("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Parent = page,
            })
            create("TextLabel", {
                Size = UDim2.new(0, 200, 0, 16),
                Position = UDim2.new(0, 0, 0, 4),
                BackgroundTransparency = 1,
                Text = string.upper(titleText),
                TextColor3 = Theme.TextDim,
                Font = Theme.FontMono,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = wrap,
            })
        end

        function Tab:CreateButton(bcfg)
            bcfg = bcfg or {}
            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.PanelLight,
                AutoButtonColor = false,
                Text = "",
                Parent = page,
            })
            round(btn, Theme.RadiusInner)
            depth(btn)

            local accentBar = create("Frame", {
                Size = UDim2.new(0, 2, 1, -8),
                Position = UDim2.new(0, 0, 0, 4),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = btn,
            })

            local offsetX = 12
            if bcfg.Icon then
                create("ImageLabel", {
                    Size = UDim2.new(0, 15, 0, 15),
                    Position = UDim2.new(0, 10, 0.5, -7.5),
                    BackgroundTransparency = 1,
                    Image = bcfg.Icon,
                    ImageColor3 = Theme.Text,
                    Parent = btn,
                })
                offsetX = 32
            end

            local btnLabel = create("TextLabel", {
                Size = UDim2.new(1, -offsetX - 8, 1, 0),
                Position = UDim2.new(0, offsetX, 0, 0),
                BackgroundTransparency = 1,
                Text = bcfg.Name or "Button",
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btn,
            })

            local callback = bcfg.Callback or function() end
            track(btn.MouseButton1Click:Connect(function() callback() end))
            track(btn.MouseEnter:Connect(function()
                tween(btn, 0.12, { BackgroundColor3 = Theme.PanelHover })
                tween(accentBar, 0.12, { BackgroundTransparency = 0 })
            end))
            track(btn.MouseLeave:Connect(function()
                tween(btn, 0.12, { BackgroundColor3 = Theme.PanelLight })
                tween(accentBar, 0.12, { BackgroundTransparency = 1 })
            end))

            return {
                SetCallback = function(_, cb) callback = cb end,
                SetName = function(_, n) btnLabel.Text = n end,
            }
        end

        function Tab:CreateToggle(tcfg)
            tcfg = tcfg or {}
            local value = tcfg.Default or false
            local callback = tcfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.PanelLight,
                Parent = page,
            })
            round(frame, Theme.RadiusInner)
            depth(frame)

            create("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = tcfg.Name or "Toggle",
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local indicator = create("Frame", {
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(1, -28, 0.5, -6),
                BackgroundColor3 = value and Theme.Accent or Theme.Border,
                Parent = frame,
            })
            round(indicator, UDim.new(0, 2))

            local stateLabel = create("TextLabel", {
                Size = UDim2.new(0, 38, 1, 0),
                Position = UDim2.new(1, -68, 0, 0),
                BackgroundTransparency = 1,
                Text = value and "ON" or "OFF",
                TextColor3 = value and Theme.Accent or Theme.TextDim,
                Font = Theme.FontMono,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = frame,
            })

            local function update(animate)
                if animate then
                    tween(indicator, 0.1, { BackgroundColor3 = value and Theme.Accent or Theme.Border })
                else
                    indicator.BackgroundColor3 = value and Theme.Accent or Theme.Border
                end
                stateLabel.Text = value and "ON" or "OFF"
                stateLabel.TextColor3 = value and Theme.Accent or Theme.TextDim
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

        function Tab:CreateSlider(scfg)
            scfg = scfg or {}
            local min = scfg.Min or 0
            local max = scfg.Max or 100
            local value = math.clamp(scfg.Default or min, min, max)
            local callback = scfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundColor3 = Theme.PanelLight,
                Parent = page,
            })
            round(frame, Theme.RadiusInner)
            depth(frame)

            create("TextLabel", {
                Size = UDim2.new(1, -70, 0, 18),
                Position = UDim2.new(0, 12, 0, 5),
                BackgroundTransparency = 1,
                Text = scfg.Name or "Slider",
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local valLabel = create("TextLabel", {
                Size = UDim2.new(0, 50, 0, 18),
                Position = UDim2.new(1, -62, 0, 5),
                BackgroundTransparency = 1,
                Text = tostring(value),
                TextColor3 = Theme.Accent,
                Font = Theme.FontMono,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = frame,
            })

            local trackBar = create("Frame", {
                Size = UDim2.new(1, -24, 0, 3),
                Position = UDim2.new(0, 12, 0, 32),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Parent = frame,
            })

            local fill = create("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Parent = trackBar,
            })

            local knob = create("Frame", {
                Size = UDim2.new(0, 9, 0, 9),
                Position = UDim2.new((value - min) / (max - min), -4.5, 0.5, -4.5),
                BackgroundColor3 = Theme.Text,
                Parent = trackBar,
            })
            round(knob, UDim.new(0, 2))

            local dragging2 = false
            local function refresh()
                local pct = (max == min) and 0 or (value - min) / (max - min)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, -4.5, 0.5, -4.5)
                valLabel.Text = tostring(value)
            end

            local function onInput(input)
                local pct = math.clamp((input.Position.X - trackBar.AbsolutePosition.X) / trackBar.AbsoluteSize.X, 0, 1)
                value = (max == min) and min or math.floor(min + pct * (max - min))
                refresh()
                callback(value)
            end

            track(trackBar.InputBegan:Connect(function(input)
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
                Set = function(_, v) value = math.clamp(v, min, max); refresh(); callback(value) end,
                Get = function() return value end,
                SetCallback = function(_, cb) callback = cb end,
            }
        end

        function Tab:CreateDropdown(dcfg)
            dcfg = dcfg or {}
            local options = dcfg.Options or {}
            local value = dcfg.Default or options[1]
            local callback = dcfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.PanelLight,
                ClipsDescendants = false,
                Parent = page,
            })
            round(frame, Theme.RadiusInner)
            depth(frame)

            local hitArea = create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = frame,
            })

            local nameLabel = create("TextLabel", {
                Size = UDim2.new(0.5, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = dcfg.Name or "Dropdown",
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local valueLabel = create("TextLabel", {
                Size = UDim2.new(0.5, -26, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = value or "",
                TextColor3 = Theme.Accent,
                Font = Theme.FontMono,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = frame,
            })

            local arrow = create("TextLabel", {
                Size = UDim2.new(0, 16, 1, 0),
                Position = UDim2.new(1, -20, 0, 0),
                BackgroundTransparency = 1,
                Text = "⌄",
                TextColor3 = Theme.TextDim,
                Font = Theme.FontBold,
                TextSize = 11,
                Parent = frame,
            })

            local expanded = false
            local list = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.Panel,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 10,
                Parent = frame,
            })
            round(list, Theme.RadiusInner)
            depth(list, Theme.BorderLight)
            create("UIListLayout", { Padding = UDim.new(0, 1), Parent = list })
            padding(list, 4)

            local optionBtns = {}
            local function buildOptions()
                for _, b in ipairs(optionBtns) do b:Destroy() end
                optionBtns = {}
                for _, opt in ipairs(options) do
                    local ob = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundColor3 = (opt == value) and Theme.PanelHover or Theme.Panel,
                        Text = opt,
                        TextColor3 = (opt == value) and Theme.Accent or Theme.Text,
                        Font = Theme.Font,
                        TextSize = 12,
                        AutoButtonColor = false,
                        ZIndex = 10,
                        Parent = list,
                    })
                    round(ob, UDim.new(0, 2))
                    track(ob.MouseButton1Click:Connect(function()
                        value = opt
                        valueLabel.Text = opt
                        callback(opt)
                        expanded = false
                        list.Visible = false
                        arrow.Text = "⌄"
                        buildOptions()
                    end))
                    track(ob.MouseEnter:Connect(function() tween(ob, 0.1, { BackgroundColor3 = Theme.PanelHover }) end))
                    track(ob.MouseLeave:Connect(function()
                        tween(ob, 0.1, { BackgroundColor3 = (opt == value) and Theme.PanelHover or Theme.Panel })
                    end))
                    table.insert(optionBtns, ob)
                end
            end
            buildOptions()

            track(hitArea.MouseButton1Click:Connect(function()
                expanded = not expanded
                list.Visible = expanded
                list.Size = expanded and UDim2.new(1, 0, 0, #options * 25 + 8) or UDim2.new(1, 0, 0, 0)
                arrow.Text = expanded and "⌃" or "⌄"
            end))

            return {
                Set = function(_, v)
                    for _, o in ipairs(options) do
                        if o == v then
                            value = v
                            valueLabel.Text = v
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
                    valueLabel.Text = value or ""
                    callback(value)
                    buildOptions()
                end,
            }
        end

        function Tab:CreateTextbox(xcfg)
            xcfg = xcfg or {}
            local callback = xcfg.Callback or function() end

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.PanelLight,
                Parent = page,
            })
            round(frame, Theme.RadiusInner)
            depth(frame)

            create("TextLabel", {
                Size = UDim2.new(0, 76, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = xcfg.Name or "Input",
                TextColor3 = Theme.TextDim,
                Font = Theme.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })

            local box = create("TextBox", {
                Size = UDim2.new(1, -96, 0, 22),
                Position = UDim2.new(0, 88, 0.5, -11),
                BackgroundColor3 = Theme.Background,
                Text = "",
                PlaceholderText = xcfg.Placeholder or "",
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.TextDim,
                Font = Theme.FontMono,
                TextSize = 12,
                ClearTextOnFocus = false,
                Parent = frame,
            })
            round(box, UDim.new(0, 2))
            depth(box)

            track(box.FocusLost:Connect(function()
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