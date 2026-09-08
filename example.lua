-- FUG UI Library — example
-- Run this script in your executor, not main.lua directly.

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ricogrrr/FUG-UI-Library/main/main.lua"
))()

-- Theme is already set to the v2 defaults in main.lua.
-- Only call SetTheme if you want to override the accent for a specific hub.
-- Library:SetTheme({ Accent = Color3.fromRGB(80, 200, 120) })

local Window = Library:CreateWindow({
    Title = "Example Hub",
    Subtitle = "FUG UI v2",
    Size = UDim2.fromOffset(560, 380),
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

Main:CreateLabel("Numeric readouts use a mono font and a single accent color — everything else stays neutral so state actually stands out.")

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