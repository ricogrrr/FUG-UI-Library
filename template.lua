--[[
	FUG UI Library - Blank Template
	Start building your own UI from scratch.
	Replace the URL below with your raw main.lua link.
]]

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ricogrrr/FUG-UI-Library/main/main.lua"))()

-- [[ // Window // ]]
local window = library:CreateWindow({
	Accent = Color3.fromRGB(255, 120, 30),
	Key = Enum.KeyCode.Z
})

-- [[ // Pages // ]]
local page = window:CreatePage({
	Icon = "rbxassetid://8547236654"
})

-- [[ // Sections // ]]
local section = page:CreateSection({
	Name = "My Section",
	Size = 200,
	Side = "Left"
})

-- [[ // Content // ]]
section:CreateToggle({
	Name = "My Toggle",
	State = false,
	Callback = function(State)
		print("Toggle is now:", State)
	end
})

section:CreateSlider({
	Name = "My Slider",
	State = 50,
	Max = 100,
	Min = 0,
	Decimals = 1,
	Suffix = "%",
	Callback = function(State)
		print("Slider value:", State)
	end
})

section:CreateDropdown({
	Name = "My Dropdown",
	State = 1,
	Options = {"Option 1", "Option 2", "Option 3"},
	Callback = function(State, Value)
		print("Selected:", Value)
	end
})

-- Press the Key (default Z) to toggle the UI
