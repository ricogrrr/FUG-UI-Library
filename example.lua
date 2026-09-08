--[[
	PuppyWare UI Library - Example
	Upload main.lua to a GitHub repo (or any raw host) and replace the URL below,
	then execute this file in your executor.
]]

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ricogrrr/FUG-UI-Library/main/main.lua"))()

-- [[ // Window // ]]
local window = library:CreateWindow({Accent = Color3.fromRGB(255, 120, 30), Key = Enum.KeyCode.Z})

-- [[ // Pages // ]]
local rage = window:CreatePage({Icon = "rbxassetid://8547236654"})
local antiaim = window:CreatePage({Icon = "rbxassetid://8548723563"})
local aimbot = window:CreatePage({Icon = "rbxassetid://8547249956"})
local visuals = window:CreatePage({Icon = "rbxassetid://8547254518"})
local setting = window:CreatePage({Icon = "rbxassetid://8547256547"})
local skins = window:CreatePage({Icon = "rbxassetid://8547258459"})
local config = window:CreatePage({Icon = "rbxassetid://8547269749"})

-- [[ // Rage Sections // ]]
local rage_main = rage:CreateSection({Name = "Ragebot", Size = 250, Side = "Left"})
local rage_resolver = rage:CreateSection({Name = "Resolver", Size = 200, Side = "Right"})

-- [[ // Rage Content // ]]
rage_main:CreateKeybind({Name = "Ragebot Key", Mode = "Toggle"})
rage_main:CreateToggle({Name = "Enabled", State = true})
rage_main:CreateToggle({Name = "Auto Fire", State = true})
rage_main:CreateDropdown({Name = "Hitbox", State = 1, Options = {"Head", "Chest", "Pelvis", "Nearest"}})
rage_main:CreateMultibox({Name = "Hitscan", State = {1, 2}, Options = {"Head", "Chest", "Arms", "Legs"}})
rage_main:CreateSlider({Name = "Hitchance", State = 80, Max = 100, Min = 0, Decimals = 1, Suffix = "%"})
rage_main:CreateSlider({Name = "Min Damage", State = 20, Max = 130, Min = 0, Decimals = 1, Suffix = "hp"})
--
rage_resolver:CreateToggle({Name = "Enabled", State = true})
rage_resolver:CreateDropdown({Name = "Mode", State = 1, Options = {"Bruteforce", "Delta", "Layered"}})
rage_resolver:CreateToggle({Name = "Prefer safe point", State = true})
rage_resolver:CreateToggle({Name = "Force body yaw", State = false})
rage_resolver:CreateSlider({Name = "Max misses", State = 3, Max = 10, Min = 1, Decimals = 1, Suffix = ""})

-- [[ // Anti-Aim Sections // ]]
local antiaim_main = antiaim:CreateSection({Name = "Anti-Aim", Size = 260, Side = "Left"})
local antiaim_fakelag = antiaim:CreateSection({Name = "Fake Lag", Size = 180, Side = "Right"})

-- [[ // Anti-Aim Content // ]]
antiaim_main:CreateKeybind({Name = "Anti-Aim Key", Mode = "Toggle"})
antiaim_main:CreateToggle({Name = "Enabled", State = false})
antiaim_main:CreateDropdown({Name = "Pitch", State = 2, Options = {"Off", "Down", "Up", "Zero"}})
antiaim_main:CreateDropdown({Name = "Yaw", State = 1, Options = {"Backward", "Spin", "Jitter", "Random"}})
antiaim_main:CreateDropdown({Name = "Yaw Base", State = 1, Options = {"Local view", "At targets"}})
antiaim_main:CreateSlider({Name = "Yaw Offset", State = 0, Max = 180, Min = -180, Decimals = 1, Suffix = "°"})
antiaim_main:CreateToggle({Name = "Freestanding", State = false})
antiaim_main:CreateToggle({Name = "Disable on grenade", State = true})
--
antiaim_fakelag:CreateToggle({Name = "Enabled", State = false})
antiaim_fakelag:CreateDropdown({Name = "Mode", State = 1, Options = {"Static", "Random", "Switch"}})
antiaim_fakelag:CreateSlider({Name = "Limit", State = 8, Max = 15, Min = 1, Decimals = 1, Suffix = "t"})
antiaim_fakelag:CreateToggle({Name = "While shooting", State = false})
antiaim_fakelag:CreateToggle({Name = "In air", State = false})

-- [[ // Aimbot Sections // ]]
local aimbot_main = aimbot:CreateSection({Name = "Aimbot", Size = 200, Side = "Left"})
local aimbot_filter = aimbot:CreateSection({Name = "Filter", Size = 158, Side = "Left"})
local aimbot_misc = aimbot:CreateSection({Name = "Misc", Size = 200, Side = "Right"})

-- [[ // Aimbot Content // ]]
aimbot_main:CreateKeybind({Name = "Aimbot Key", Mode = "Hold"})
aimbot_main:CreateToggle({Name = "Enabled", State = true})
aimbot_main:CreateToggle({Name = "Visibility Check", State = true})
aimbot_main:CreateToggle({Name = "Through Walls", State = false})
aimbot_main:CreateDropdown({Name = "Target Priority", State = 1, Options = {"Closest", "Lowest Health", "Highest Health", "Random"}})
aimbot_main:CreateDropdown({Name = "Aim Bone", State = 1, Options = {"Head", "Chest", "Pelvis", "Nearest"}})
aimbot_main:CreateSlider({Name = "FOV", State = 180, Max = 360, Min = 0, Decimals = 1, Suffix = "px"})
aimbot_main:CreateSlider({Name = "Smoothing", State = 5, Max = 20, Min = 0, Decimals = 1, Suffix = ""})
--
aimbot_filter:CreateToggle({Name = "Teammates", State = false})
aimbot_filter:CreateToggle({Name = "Dormant", State = false})
aimbot_filter:CreateToggle({Name = "NPCs", State = false})
aimbot_filter:CreateToggle({Name = "Local player", State = false})
aimbot_filter:CreateMultibox({Name = "Filter Flags", State = {1}, Options = {"Visible", "Behind Wall", "Dormant", "Friendly"}})
--
aimbot_misc:CreateToggle({Name = "Prediction", State = true})
aimbot_misc:CreateToggle({Name = "Auto Fire", State = false})
aimbot_misc:CreateToggle({Name = "Silent Aim", State = false})
aimbot_misc:CreateToggle({Name = "Trigger Bot", State = false})
aimbot_misc:CreateSlider({Name = "Hit Chance", State = 100, Max = 100, Min = 0, Decimals = 1, Suffix = "%"})
aimbot_misc:CreateSlider({Name = "Min Damage", State = 20, Max = 130, Min = 0, Decimals = 1, Suffix = "hp"})
aimbot_misc:CreateColorpicker({Name = "Aimbot FOV Circle", State = Color3.fromRGB(255, 255, 255)})

-- [[ // Visuals Sections // ]]
local playeresp = visuals:CreateSection({Name = "Player ESP", Size = 330, Side = "Left"})
local coloredmodels = visuals:CreateSection({Name = "Colored models", Size = 158, Side = "Left"})
local otheresp = visuals:CreateSection({Name = "Other ESP", Size = 200, Side = "Right"})
local effects = visuals:CreateSection({Name = "Effects", Size = 288, Side = "Right"})

-- [[ // Content // ]]
local keybn = playeresp:CreateKeybind({Name = "Activation Type"})
playeresp:CreateToggle({Name = "Teammates", State = false})
playeresp:CreateColorpicker({Name = "Visualize aimbot", State = Color3.fromRGB(255, 0, 0)})
playeresp:CreateColorpicker({Name = "Bounding Box", State = Color3.fromRGB(50, 100, 200)})
playeresp:CreateColorpicker({Name = "Glow", State = Color3.fromRGB(25, 180, 75)})
playeresp:CreateToggle({Name = "Dormant", State = false})
playeresp:CreateToggle({Name = "Bounding Box", State = true})
playeresp:CreateToggle({Name = "Health Bar", State = true})
playeresp:CreateToggle({Name = "Name", State = true})
playeresp:CreateToggle({Name = "Flags", State = true})
playeresp:CreateToggle({Name = "Weapon Text", State = false})
playeresp:CreateToggle({Name = "Weapon Icon", State = false})
playeresp:CreateToggle({Name = "Ammo", State = false})
playeresp:CreateToggle({Name = "Distance", State = false})
playeresp:CreateToggle({Name = "Glow", State = true})
playeresp:CreateToggle({Name = "Hit Marker", State = true})
playeresp:CreateToggle({Name = "Hit Marker Sound", State = true})
playeresp:CreateToggle({Name = "Visualize sounds", State = true})
playeresp:CreateToggle({Name = "Line of sight", State = false})
playeresp:CreateToggle({Name = "Money", State = false})
playeresp:CreateToggle({Name = "Skeleton", State = false})
playeresp:CreateToggle({Name = "Out of FOV arrow", State = true})
playeresp:CreateSlider({State = 12, Max = 30, Min = 1, Decimals = 1, Suffix = "px"})
playeresp:CreateSlider({State = 100, Max = 100, Min = 1, Decimals = 1, Suffix = "%"})
--
coloredmodels:CreateToggle({Name = "Player", State = false})
coloredmodels:CreateToggle({Name = "Player behind wall", State = false})
coloredmodels:CreateToggle({Name = "Teammate", State = false})
coloredmodels:CreateToggle({Name = "Teammate behind wall", State = false})
coloredmodels:CreateToggle({Name = "Local player", State = false})
coloredmodels:CreateToggle({Name = "Local player fake", State = false})
coloredmodels:CreateToggle({Name = "Ragdolls", State = false})
coloredmodels:CreateToggle({Name = "Hands", State = false})
coloredmodels:CreateToggle({Name = "Weapon viewmodel", State = false})
coloredmodels:CreateToggle({Name = "Disable model occlusion", State = false})
coloredmodels:CreateToggle({Name = "Shadow", State = false})
coloredmodels:CreateToggle({Name = "Props", State = false})
--
otheresp:CreateToggle({Name = "Radar", State = false})
otheresp:CreateMultibox({Name = "Dropped weapons", State = {1, 3, 4}, Options = {"Icon", "Text", "Glow", "Ammo", "Distance"}})
otheresp:CreateToggle({Name = "Grenades", State = false})
otheresp:CreateToggle({Name = "Inaccuracy overlay", State = false})
otheresp:CreateToggle({Name = "Recoil overlay", State = false})
otheresp:CreateToggle({Name = "Crosshair", State = false})
otheresp:CreateToggle({Name = "Bomb", State = false})
otheresp:CreateToggle({Name = "Grenade trajectory", State = false})
otheresp:CreateToggle({Name = "Grenade proximity warning", State = false})
otheresp:CreateToggle({Name = "Spectators", State = false})
otheresp:CreateToggle({Name = "Penetration reticle", State = false})
otheresp:CreateToggle({Name = "Hostages", State = false})
otheresp:CreateToggle({Name = "Shared esp", State = false})
otheresp:CreateToggle({Name = "Upgrade tablet", State = false})
otheresp:CreateToggle({Name = "Danger Zone items", State = false})
--
effects:CreateToggle({Name = "Remove flashbang effects", State = false})
effects:CreateToggle({Name = "Remove smoke grenades", State = false})
effects:CreateToggle({Name = "Remove fog", State = false})
effects:CreateToggle({Name = "Remove grass", State = false})
effects:CreateToggle({Name = "Remove skybox", State = false})
effects:CreateDropdown({Name = "Visual Recoil Adjustment", State = 1, Options = {"Off", "Remove Shake", "Remove All"}})
effects:CreateSlider({Name = "Transparent walls", State = 50, Max = 100, Min = 0, Decimals = 1, Suffix = "%"})
effects:CreateSlider({Name = "Transparent props", State = 50, Max = 100, Min = 0, Decimals = 1, Suffix = "%"})
effects:CreateDropdown({Name = "Brightness Adjustment", State = 1, Options = {"Off", "Night Mode", "Full Bright"}})
effects:CreateToggle({Name = "Remove scope overlay", State = false})
effects:CreateToggle({Name = "Instant scope", State = false})
effects:CreateToggle({Name = "Disable post processing", State = false})
effects:CreateToggle({Name = "Force third person (alive)", State = false})
effects:CreateToggle({Name = "Force third person (dead)", State = false})
effects:CreateToggle({Name = "Disable rendering of teamates", State = false})
effects:CreateToggle({Name = "Bullet tracers", State = false})
effects:CreateToggle({Name = "Bullet impacts", State = false})
effects:CreateToggle({Name = "Override Skybox", State = false})

-- [[ // Settings Sections // ]]
local setting_menu = setting:CreateSection({Name = "Menu", Size = 200, Side = "Left"})
local setting_other = setting:CreateSection({Name = "Other", Size = 158, Side = "Right"})

-- [[ // Settings Content // ]]
setting_menu:CreateKeybind({Name = "Menu Key", State = {"KeyCode", "Z"}, Mode = "Toggle"})
setting_menu:CreateColorpicker({Name = "Accent", State = Color3.fromRGB(255, 120, 30), Callback = function(Color) window.Accent = Color end})
setting_menu:CreateToggle({Name = "Watermark", State = true})
setting_menu:CreateToggle({Name = "Keybind list", State = false})
setting_menu:CreateDropdown({Name = "UI Scale", State = 3, Options = {"50%", "75%", "100%", "125%"}})
setting_menu:CreateSlider({Name = "FPS Cap", State = 240, Max = 480, Min = 30, Decimals = 1, Suffix = "fps"})
--
setting_other:CreateToggle({Name = "Clantag", State = false})
setting_other:CreateToggle({Name = "Auto accept", State = true})
setting_other:CreateToggle({Name = "Unlock inventory", State = false})
setting_other:CreateToggle({Name = "Bypass sv_pure", State = false})
setting_other:CreateMultibox({Name = "Log events", State = {1}, Options = {"Purchases", "Damage", "Misses", "Hits"}})

-- [[ // Skins Sections // ]]
local skins_main = skins:CreateSection({Name = "Weapon Skins", Size = 260, Side = "Left"})
local skins_agents = skins:CreateSection({Name = "Agents", Size = 180, Side = "Right"})

-- [[ // Skins Content // ]]
skins_main:CreateDropdown({Name = "Weapon", State = 1, Options = {"AK-47", "M4A4", "AWP", "Desert Eagle", "Knife"}})
skins_main:CreateDropdown({Name = "Skin", State = 1, Options = {"Asiimov", "Redline", "Dragon Lore", "Printstream", "Fade"}})
skins_main:CreateToggle({Name = "StatTrak", State = false})
skins_main:CreateSlider({Name = "Wear", State = 0, Max = 1, Min = 0, Decimals = 0.01, Suffix = ""})
skins_main:CreateSlider({Name = "Seed", State = 1, Max = 1000, Min = 1, Decimals = 1, Suffix = ""})
skins_main:CreateToggle({Name = "Apply on spawn", State = true})
--
skins_agents:CreateDropdown({Name = "T Agent", State = 1, Options = {"Default", "Sir Bloody", "Number K"}})
skins_agents:CreateDropdown({Name = "CT Agent", State = 1, Options = {"Default", "Lt. Commander", "Getaway Sally"}})
skins_agents:CreateToggle({Name = "Glove changer", State = false})
skins_agents:CreateToggle({Name = "Knife changer", State = false})

-- [[ // Config Sections // ]]
local config_main = config:CreateSection({Name = "Configs", Size = 200, Side = "Left"})
local config_cloud = config:CreateSection({Name = "Cloud", Size = 158, Side = "Right"})

-- [[ // Config Content // ]]
config_main:CreateDropdown({Name = "Config", State = 1, Options = {"Config 1", "Config 2", "Config 3", "Config 4"}})
config_main:CreateToggle({Name = "Auto load last", State = true})
config_main:CreateToggle({Name = "Save on unload", State = true})
config_main:CreateKeybind({Name = "Save config", Mode = "Toggle"})
--
config_cloud:CreateToggle({Name = "Cloud configs", State = false})
config_cloud:CreateToggle({Name = "Share current", State = false})
config_cloud:CreateToggle({Name = "Auto update", State = true})
config_cloud:CreateDropdown({Name = "Sort by", State = 1, Options = {"Name", "Date", "Author"}})
