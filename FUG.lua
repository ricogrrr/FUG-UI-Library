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

-- [[ // ESP Page // ]]
local esp = window:CreatePage({Icon = "rbxassetid://8547236654"})

local esp_main = esp:CreateSection({Name = "Corner ESP", Size = 200, Side = "Left"})
local esp_color = esp:CreateSection({Name = "Colors", Size = 158, Side = "Right"})

-- [[ // ESP Config // ]]
local ESPConfig = {
	Enabled = false,
	TeamCheck = false,
	TeamColor = false,
	AutoThickness = true,
	UseRainbow = false,
	BoxThickness = 2,
	BoxColor = Color3.fromRGB(255, 0, 0),
	EnemyColor = Color3.fromRGB(255, 0, 0),
	FriendlyColor = Color3.fromRGB(0, 255, 0),
}

-- [[ // ESP Drawing Helpers // ]]
local function NewLine(color, thickness)
	local line = Drawing.new("Line")
	line.Visible = false
	line.From = Vector2.new(0, 0)
	line.To = Vector2.new(0, 0)
	line.Color = color
	line.Thickness = thickness
	line.Transparency = 1
	return line
end

local function VisLib(lib, state)
	for _, v in pairs(lib) do
		v.Visible = state
	end
end

local function ColorizeLib(lib, color)
	for _, v in pairs(lib) do
		v.Color = color
	end
end

-- [[ // ESP Player Tracking // ]]
local espPlayers = {}

local function getESPColor(plr)
	if ESPConfig.UseRainbow then
		return nil
	elseif ESPConfig.TeamColor and plr.TeamColor then
		return plr.TeamColor.Color
	elseif ESPConfig.TeamCheck then
		if plr.TeamColor and plr.TeamColor == LocalPlayer.TeamColor then
			return ESPConfig.FriendlyColor
		else
			return ESPConfig.EnemyColor
		end
	else
		return ESPConfig.BoxColor
	end
end

local function drawESP(plr)
	if plr == LocalPlayer then return end

	repeat task.wait() until plr.Character and plr.Character:FindFirstChild("Humanoid")

	local lib = {
		TL1 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness),
		TL2 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness),
		TR1 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness),
		TR2 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness),
		BL1 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness),
		BL2 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness),
		BR1 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness),
		BR2 = NewLine(ESPConfig.BoxColor, ESPConfig.BoxThickness)
	}

	local oripart = Instance.new("Part")
	oripart.Parent = workspace
	oripart.Transparency = 1
	oripart.CanCollide = false
	oripart.Size = Vector3.new(1, 1, 1)
	oripart.Position = Vector3.new(0, 0, 0)

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ESPConfig.Enabled then
			VisLib(lib, false)
			return
		end

		if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("Head") then
			local char = plr.Character
			local camera = workspace.CurrentCamera
			if not camera then return end

			local humPos, vis = camera:WorldToViewportPoint(char.HumanoidRootPart.Position)

			if vis then
				oripart.Size = Vector3.new(char.HumanoidRootPart.Size.X, char.HumanoidRootPart.Size.Y * 1.5, char.HumanoidRootPart.Size.Z)
				oripart.CFrame = CFrame.new(char.HumanoidRootPart.CFrame.Position, camera.CFrame.Position)

				local sizeX = oripart.Size.X
				local sizeY = oripart.Size.Y
				local TL = camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(sizeX, sizeY, 0)).p)
				local TR = camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-sizeX, sizeY, 0)).p)
				local BL = camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(sizeX, -sizeY, 0)).p)
				local BR = camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-sizeX, -sizeY, 0)).p)

				local color = getESPColor(plr)
				if color then
					ColorizeLib(lib, color)
				end

				if ESPConfig.AutoThickness then
					local lpChar = LocalPlayer.Character
					if lpChar and lpChar:FindFirstChild("HumanoidRootPart") then
						local distance = (lpChar.HumanoidRootPart.Position - oripart.Position).Magnitude
						local value = math.clamp(1 / distance * 100, 1, 4)
						for _, v in pairs(lib) do
							v.Thickness = value
						end
					end
				else
					for _, v in pairs(lib) do
						v.Thickness = ESPConfig.BoxThickness
					end
				end

				local ratio = (camera.CFrame.Position - char.HumanoidRootPart.Position).Magnitude
				local offset = math.clamp(1 / ratio * 750, 2, 300)

				lib.TL1.From = Vector2.new(TL.X, TL.Y)
				lib.TL1.To = Vector2.new(TL.X + offset, TL.Y)
				lib.TL2.From = Vector2.new(TL.X, TL.Y)
				lib.TL2.To = Vector2.new(TL.X, TL.Y + offset)

				lib.TR1.From = Vector2.new(TR.X, TR.Y)
				lib.TR1.To = Vector2.new(TR.X - offset, TR.Y)
				lib.TR2.From = Vector2.new(TR.X, TR.Y)
				lib.TR2.To = Vector2.new(TR.X, TR.Y + offset)

				lib.BL1.From = Vector2.new(BL.X, BL.Y)
				lib.BL1.To = Vector2.new(BL.X + offset, BL.Y)
				lib.BL2.From = Vector2.new(BL.X, BL.Y)
				lib.BL2.To = Vector2.new(BL.X, BL.Y - offset)

				lib.BR1.From = Vector2.new(BR.X, BR.Y)
				lib.BR1.To = Vector2.new(BR.X - offset, BR.Y)
				lib.BR2.From = Vector2.new(BR.X, BR.Y)
				lib.BR2.To = Vector2.new(BR.X, BR.Y - offset)

				VisLib(lib, true)
			else
				VisLib(lib, false)
			end
		else
			VisLib(lib, false)
			if not Players:FindFirstChild(plr.Name) then
				for _, v in pairs(lib) do
					v:Remove()
				end
				oripart:Destroy()
				conn:Disconnect()
			end
		end
	end)

	espPlayers[plr] = {lib = lib, conn = conn, oripart = oripart}
end

-- Initialize ESP for existing players
for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		task.spawn(drawESP, plr)
	end
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(drawESP, plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	local data = espPlayers[plr]
	if data then
		for _, v in pairs(data.lib) do
			v:Remove()
		end
		if data.oripart then
			data.oripart:Destroy()
		end
		if data.conn then
			data.conn:Disconnect()
		end
		espPlayers[plr] = nil
	end
end)

-- Rainbow ESP loop
task.spawn(function()
	while true do
		if ESPConfig.Enabled and ESPConfig.UseRainbow then
			local hue = (tick() % 5) / 5
			local color = Color3.fromHSV(hue, 0.6, 1)
			for _, data in pairs(espPlayers) do
				ColorizeLib(data.lib, color)
			end
		end
		task.wait(0.05)
	end
end)

-- [[ // ESP UI // ]]
esp_main:CreateToggle({
	Name = "Enabled",
	State = false,
	Callback = function(State)
		ESPConfig.Enabled = State
	end
})

esp_main:CreateToggle({
	Name = "Team Check",
	State = false,
	Callback = function(State)
		ESPConfig.TeamCheck = State
	end
})

esp_main:CreateToggle({
	Name = "Team Color",
	State = false,
	Callback = function(State)
		ESPConfig.TeamColor = State
	end
})

esp_main:CreateToggle({
	Name = "Auto Thickness",
	State = true,
	Callback = function(State)
		ESPConfig.AutoThickness = State
	end
})

esp_main:CreateToggle({
	Name = "Use Rainbow",
	State = false,
	Callback = function(State)
		ESPConfig.UseRainbow = State
	end
})

esp_main:CreateSlider({
	Name = "Box Thickness",
	State = 2,
	Min = 1,
	Max = 10,
	Decimals = 1,
	Suffix = "px",
	Callback = function(State)
		ESPConfig.BoxThickness = State
	end
})

esp_color:CreateColorpicker({
	Name = "Box Color",
	State = Color3.fromRGB(255, 0, 0),
	Callback = function(Color)
		ESPConfig.BoxColor = Color
	end
})

esp_color:CreateColorpicker({
	Name = "Enemy Color",
	State = Color3.fromRGB(255, 0, 0),
	Callback = function(Color)
		ESPConfig.EnemyColor = Color
	end
})

esp_color:CreateColorpicker({
	Name = "Friendly Color",
	State = Color3.fromRGB(0, 255, 0),
	Callback = function(Color)
		ESPConfig.FriendlyColor = Color
	end
})
