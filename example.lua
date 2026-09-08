-- FUG UI Library — polished example
-- Run this script in your executor, not main.lua directly.

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ricogrrr/FUG-UI-Library/main/main.lua"
))()

Library:SetTheme({
    Accent = Color3.fromRGB(124, 92, 255),
    AccentHover = Color3.fromRGB(145, 118, 255),
    Background = Color3.fromRGB(12, 12, 16),
    Panel = Color3.fromRGB(18, 18, 23),
    PanelLight = Color3.fromRGB(24, 24, 30),
    PanelHover = Color3.fromRGB(31, 31, 39),
    Text = Color3.fromRGB(245, 245, 248),
    TextDark = Color3.fromRGB(145, 145, 158),
    Border = Color3.fromRGB(45, 45, 54),
})

local Window = Library:CreateWindow({
    Title = "Example Hub",
    Subtitle = "FUG UI • Clean Edition",
    Size = UDim2.fromOffset(700, 460),
    ToggleKey = Enum.KeyCode.RightControl,
})

local Main = Window:CreateTab("Overview", "rbxassetid://6035024691")

Main:CreateSection("Quick actions")

Main:CreateButton({
    Name = "Print Hello",
    Icon = "rbxassetid://6035024691",
    Callback = function()
        print("Hello!")
        Library:Notify({
            Title = "Action complete",
            Content = "The button was activated successfully.",
            Duration = 3,
        })
    end,
})

Main:CreateToggle({
    Name = "Example Toggle",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

Main:CreateSection("Movement")

Main:CreateSlider({
    Name = "WalkSpeed",
    Min = 0,
    Max = 100,
    Default = 16,
    Callback = function(value)
        print("WalkSpeed:", value)
    end,
})

Main:CreateDropdown({
    Name = "Mode",
    Options = { "Option 1", "Option 2", "Option 3" },
    Default = "Option 1",
    Callback = function(value)
        print("Selected:", value)
    end,
})

Main:CreateSection("Input")

Main:CreateTextbox({
    Name = "Username",
    Placeholder = "Enter username...",
    Callback = function(value)
        print("Username:", value)
    end,
})

Main:CreateLabel("Everything is spaced into compact cards so the page stays readable without feeling crowded.")

local Settings = Window:CreateTab("Settings", "rbxassetid://6034455061")

Settings:CreateSection("Interface")

Settings:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Library:Notify({
            Title = "Closing",
            Content = "Goodbye.",
            Duration = 2,
        })
    end,
})

Library:Notify({
    Title = "Welcome",
    Content = "Example Hub is ready.",
    Duration = 3,
})
