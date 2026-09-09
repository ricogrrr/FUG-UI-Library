local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ricogrrr/FUG-UI-Library/main/main.lua"))()

local window = library:CreateWindow({
	Accent = Color3.fromRGB(255, 120, 30),
	Key = Enum.KeyCode.Z
})

local rage = window:CreatePage({Icon = "rbxassetid://8547236654"})

local rage_main = rage:CreateSection({Name = "Silent Aim", Size = 200, Side = "Left"})
local rage_fov = rage:CreateSection({Name = "FOV", Size = 158, Side = "Right"})

-- [[ // Config // ]]
local Config = {
	Enabled = false,
	TeamCheck = true,
	VisibleCheck = true,
	FOVRadius = 100,
	FOVVisible = true,
	FOVColor = Color3.fromRGB(255, 255, 255),
}

-- [[ // Services // ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- [[ // Locate ShootEvent // ]]
local ShootEvent
pcall(function()
	ShootEvent = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("ShootEvent", 5)
end)

if not ShootEvent then
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") and obj.Name:lower():find("shoot") then
			ShootEvent = obj
			break
		end
	end
end

-- [[ // FOV Circle // ]]
local fovCircle = nil
if Drawing then
	fovCircle = Drawing.new("Circle")
	fovCircle.Visible = Config.FOVVisible
	fovCircle.Radius = Config.FOVRadius
	fovCircle.Color = Config.FOVColor
	fovCircle.Thickness = 1
	fovCircle.Filled = false
	fovCircle.NumSides = 60
	fovCircle.Transparency = 0.5
end

-- [[ // Helpers // ]]
local HITBOX_NAMES = {"Head", "HeadHitbox"}
local RANGE = 1000
local STICKINESS = 50
local TARGET_RETENTION = 0.3
local FOV_OFFSET = Vector2.new(190, 110)

local currentTarget = nil
local currentTargetChar = nil
local currentPixelDist = 0
local lastTargetTime = 0

local function findHitbox(char)
	for _, name in ipairs(HITBOX_NAMES) do
		local part = char:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function getEnemies()
	local enemies = {}
	local playerChars = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local skip = Config.TeamCheck and player.Team ~= nil and player.Team == LocalPlayer.Team
			if not skip then
				local char = player.Character
				if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
					table.insert(enemies, char)
					playerChars[char] = true
				end
			end
			if player.Character then
				playerChars[player.Character] = true
			end
		end
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and not playerChars[obj] and obj ~= LocalPlayer.Character then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if findHitbox(obj) then
					table.insert(enemies, obj)
				end
			end
		end
	end

	return enemies
end

local function isVisible(part)
	if not Config.VisibleCheck then return true end
	local camera = workspace.CurrentCamera
	if not camera then return false end
	local origin = camera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = workspace:Raycast(origin, part.Position - origin, params)
	if result and result.Instance then
		if result.Instance:IsDescendantOf(part.Parent) then
			return true
		end
		return false
	end
	return true
end

-- [[ // Target Loop // ]]
RunService.Heartbeat:Connect(function()
	local ok, err = pcall(function()
		if not Config.Enabled then
			currentTarget = nil
			currentTargetChar = nil
			if fovCircle then
				fovCircle.Visible = false
			end
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

		if fovCircle and Config.FOVVisible then
			fovCircle.Visible = true
			fovCircle.Position = Vector2.new(center.X + FOV_OFFSET.X, center.Y + FOV_OFFSET.Y)
			fovCircle.Radius = Config.FOVRadius
			fovCircle.Color = Config.FOVColor
		elseif fovCircle then
			fovCircle.Visible = false
		end

		local bestPart, bestChar, bestPixel = nil, nil, Config.FOVRadius
		local threshold = Config.FOVRadius

		if currentTarget and currentTargetChar then
			local curHitbox = findHitbox(currentTargetChar)
			if curHitbox then
				local curScreenPos, curOnScreen = camera:WorldToViewportPoint(curHitbox.Position)
				if curOnScreen and curScreenPos.Z <= RANGE then
					local curPixel = (Vector2.new(curScreenPos.X, curScreenPos.Y) - center).Magnitude
					if curPixel < Config.FOVRadius and isVisible(curHitbox) then
						threshold = curPixel - STICKINESS
						bestPart = curHitbox
						bestChar = currentTargetChar
						bestPixel = curPixel
					end
				end
			end
		end

		for _, char in ipairs(getEnemies()) do
			local hitbox = findHitbox(char)
			if hitbox then
				local screenPos, onScreen = camera:WorldToViewportPoint(hitbox.Position)
				if onScreen and screenPos.Z <= RANGE then
					local pixelDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if pixelDist < threshold and pixelDist < bestPixel and isVisible(hitbox) then
						bestPixel = pixelDist
						bestPart = hitbox
						bestChar = char
					end
				end
			end
		end

		if bestPart then
			currentTarget = bestPart
			currentTargetChar = bestChar
			currentPixelDist = bestPixel
			lastTargetTime = tick()
		elseif tick() - lastTargetTime > TARGET_RETENTION then
			currentTarget = nil
			currentTargetChar = nil
			currentPixelDist = 0
		end
	end)
	if not ok then
		warn("[FUG] Heartbeat error:", err)
	end
end)

-- [[ // Interceptor // ]]
local function intercept(self, data)
	if type(data) == "table" and data.w and data.o and data.d then
		if Config.Enabled and currentTarget and currentTargetChar then
			local origin = data.o
			local targetPos = currentTarget.Position
			data.e = targetPos
			data.d = (targetPos - origin).Unit
			data.h = {
				partName = currentTarget.Name,
				modelName = currentTargetChar.Name
			}
		end
	end
	return data
end

-- [[ // Hook // ]]
if ShootEvent then
	if hookmetamethod then
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if method == "FireServer" and self == ShootEvent then
				local args = {...}
				if #args == 1 and type(args[1]) == "table" then
					return old(self, intercept(self, args[1]))
				end
				return old(self, ...)
			end
			return old(self, ...)
		end)
	elseif getrawmetatable and getnamecallmethod then
		local mt = getrawmetatable(game)
		local oldNC = mt.__namecall
		if setreadonly then setreadonly(mt, false) end
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if not checkcaller() and method == "FireServer" and self == ShootEvent then
				local args = {...}
				if #args == 1 and type(args[1]) == "table" then
					return oldNC(self, intercept(self, args[1]))
				end
				return oldNC(self, ...)
			end
			return oldNC(self, ...)
		end)
		if setreadonly then setreadonly(mt, true) end
	elseif hookfunction then
		local oldFireServer
		oldFireServer = hookfunction(ShootEvent.FireServer, function(self, data)
			if type(data) == "table" and data.w and data.o and data.d then
				data = intercept(self, data)
			end
			return oldFireServer(self, data)
		end)
	end
end

-- [[ // UI // ]]
rage_main:CreateToggle({
	Name = "Enabled",
	State = false,
	Callback = function(State)
		Config.Enabled = State
	end
})

rage_main:CreateToggle({
	Name = "Team Check",
	State = true,
	Callback = function(State)
		Config.TeamCheck = State
	end
})

rage_main:CreateToggle({
	Name = "Visible Check",
	State = true,
	Callback = function(State)
		Config.VisibleCheck = State
	end
})

rage_fov:CreateSlider({
	Name = "FOV Radius",
	State = 100,
	Max = 500,
	Min = 0,
	Decimals = 1,
	Suffix = "px",
	Callback = function(State)
		Config.FOVRadius = State
		if fovCircle then
			fovCircle.Radius = State
		end
	end
})

rage_fov:CreateToggle({
	Name = "Show FOV Circle",
	State = true,
	Callback = function(State)
		Config.FOVVisible = State
		if fovCircle then
			fovCircle.Visible = State and Config.Enabled
		end
	end
})

rage_fov:CreateColorpicker({
	Name = "FOV Circle Color",
	State = Color3.fromRGB(255, 255, 255),
	Callback = function(Color)
		Config.FOVColor = Color
		if fovCircle then
			fovCircle.Color = Color
		end
	end
})
