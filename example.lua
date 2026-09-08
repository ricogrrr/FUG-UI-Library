-- Example usage of FUG UI Library
-- Run this script in your executor, not main.lua directly.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ricogrrr/FUG-UI-Library/main/dist/Library.luau"))()

-- Optional: customize theme
Library:SetTheme({
    Accent = Color3.fromRGB(120, 80, 255),
    Background = Color3.fromRGB(20, 20, 25),
    Text = Color3.fromRGB(255, 255, 255),
})

local Window = Library:CreateWindow({
    Title = "Example Hub",
    Size = UDim2.fromOffset(550, 400),
    ToggleKey = Enum.KeyCode.RightControl,
})

local Tab = Window:CreateTab("Main")

Tab:CreateSection("Components")

Tab:CreateButton({
    Name = "Print Hello",
    Callback = function()
        print("Hello!")
        Library:Notify({ Title = "Success", Content = "Button activated!", Duration = 3 })
    end,
})

local Toggle = Tab:CreateToggle({
    Name = "Example Toggle",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

Tab:CreateSlider({
    Name = "WalkSpeed",
    Min = 0,
    Max = 100,
    Default = 16,
    Callback = function(value)
        print("WalkSpeed:", value)
    end,
})

Tab:CreateDropdown({
    Name = "Options",
    Options = { "Option 1", "Option 2", "Option 3" },
    Default = "Option 1",
    Callback = function(value)
        print("Selected:", value)
    end,
})

Tab:CreateTextbox({
    Name = "Username",
    Placeholder = "Enter username...",
    Callback = function(value)
        print("Username:", value)
    end,
})

Tab:CreateLabel("This is a label.")

local Tab2 = Window:CreateTab("Settings")
Tab2:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Library:Notify({ Title = "Goodbye", Content = "Closing UI...", Duration = 2 })
    end,
})

Library:Notify({ Title = "Loaded", Content = "FUG UI Library is ready!", Duration = 3 })
