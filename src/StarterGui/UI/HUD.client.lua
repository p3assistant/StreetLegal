local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Modules.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local wantedStateRemote = remotesFolder:WaitForChild("WantedState")
local policeStateRemote = remotesFolder:WaitForChild("PoliceState")
local notificationRemote = remotesFolder:WaitForChild("Notification")
local dataSyncRemote = remotesFolder:WaitForChild("DataSync")
local bikeAction = remotesFolder:WaitForChild("BikeAction")

local existingGui = playerGui:FindFirstChild("StreetLegalHUD")
if existingGui then
	existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetLegalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local speedFrame = Instance.new("Frame")
speedFrame.Position = UDim2.new(0, 18, 1, -130)
speedFrame.Size = UDim2.fromOffset(240, 104)
speedFrame.BackgroundColor3 = Config.UI.Background
speedFrame.BackgroundTransparency = 0.08
speedFrame.Parent = root
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 14)
speedCorner.Parent = speedFrame

local bikeLabel = Instance.new("TextLabel")
bikeLabel.Size = UDim2.new(1, -18, 0, 22)
bikeLabel.Position = UDim2.fromOffset(12, 10)
bikeLabel.BackgroundTransparency = 1
bikeLabel.Font = Enum.Font.GothamBold
bikeLabel.TextSize = 16
bikeLabel.TextColor3 = Config.UI.Accent
bikeLabel.TextXAlignment = Enum.TextXAlignment.Left
bikeLabel.Text = "On Foot"
bikeLabel.Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -18, 0, 44)
speedLabel.Position = UDim2.fromOffset(12, 28)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBlack
speedLabel.TextSize = 36
speedLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Text = "0 MPH"
speedLabel.Parent = speedFrame

local gearLabel = Instance.new("TextLabel")
gearLabel.Size = UDim2.new(1, -18, 0, 20)
gearLabel.Position = UDim2.fromOffset(12, 74)
gearLabel.BackgroundTransparency = 1
gearLabel.Font = Enum.Font.Gotham
gearLabel.TextSize = 16
gearLabel.TextColor3 = Color3.fromRGB(190, 195, 202)
gearLabel.TextXAlignment = Enum.TextXAlignment.Left
gearLabel.Text = "Neutral"
gearLabel.Parent = speedFrame

local heatFrame = Instance.new("Frame")
heatFrame.Position = UDim2.new(0, 18, 0, 18)
heatFrame.Size = UDim2.fromOffset(280, 90)
heatFrame.BackgroundColor3 = Config.UI.Background
heatFrame.BackgroundTransparency = 0.08
heatFrame.Parent = root
local heatCorner = Instance.new("UICorner")
heatCorner.CornerRadius = UDim.new(0, 14)
heatCorner.Parent = heatFrame

local wantedLabel = Instance.new("TextLabel")
wantedLabel.Size = UDim2.new(1, -20, 0, 24)
wantedLabel.Position = UDim2.fromOffset(12, 10)
wantedLabel.BackgroundTransparency = 1
wantedLabel.Font = Enum.Font.GothamBlack
wantedLabel.TextSize = 20
wantedLabel.TextColor3 = Config.UI.Danger
wantedLabel.TextXAlignment = Enum.TextXAlignment.Left
wantedLabel.Text = "HEAT: CLEAN"
wantedLabel.Parent = heatFrame

local heatBarBg = Instance.new("Frame")
heatBarBg.Position = UDim2.fromOffset(12, 44)
heatBarBg.Size = UDim2.new(1, -24, 0, 18)
heatBarBg.BackgroundColor3 = Color3.fromRGB(46, 49, 55)
heatBarBg.Parent = heatFrame
local heatBarBgCorner = Instance.new("UICorner")
heatBarBgCorner.CornerRadius = UDim.new(1, 0)
heatBarBgCorner.Parent = heatBarBg

local heatBar = Instance.new("Frame")
heatBar.Size = UDim2.new(0, 0, 1, 0)
heatBar.BackgroundColor3 = Config.UI.Danger
heatBar.Parent = heatBarBg
local heatCorner2 = Instance.new("UICorner")
heatCorner2.CornerRadius = UDim.new(1, 0)
heatCorner2.Parent = heatBar

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, -24, 0, 18)
promptLabel.Position = UDim2.fromOffset(12, 66)
promptLabel.BackgroundTransparency = 1
promptLabel.Font = Enum.Font.Gotham
promptLabel.TextSize = 13
promptLabel.TextColor3 = Color3.fromRGB(190, 195, 202)
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Text = "M Garage • R Respawn • Q Hop • Break line of sight to cool heat"
promptLabel.Parent = heatFrame

local comboLabel = Instance.new("TextLabel")
comboLabel.AnchorPoint = Vector2.new(0.5, 0)
comboLabel.Position = UDim2.fromScale(0.5, 0.12)
comboLabel.Size = UDim2.fromOffset(360, 34)
comboLabel.BackgroundTransparency = 1
comboLabel.Font = Enum.Font.GothamBlack
comboLabel.TextSize = 26
comboLabel.TextColor3 = Config.UI.Accent
comboLabel.Text = ""
comboLabel.Parent = root

local toastLabel = Instance.new("TextLabel")
toastLabel.AnchorPoint = Vector2.new(0.5, 0)
toastLabel.Position = UDim2.fromScale(0.5, 0.18)
toastLabel.Size = UDim2.fromOffset(420, 28)
toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 18
toastLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
toastLabel.Text = ""
toastLabel.Parent = root

local miniMap = Instance.new("Frame")
miniMap.Position = UDim2.new(1, -150, 0, 18)
miniMap.Size = UDim2.fromOffset(132, 132)
miniMap.BackgroundColor3 = Config.UI.Background
miniMap.BackgroundTransparency = 0.08
miniMap.Parent = root
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 14)
miniCorner.Parent = miniMap

local miniTitle = Instance.new("TextLabel")
miniTitle.Size = UDim2.new(1, 0, 0, 20)
miniTitle.BackgroundTransparency = 1
miniTitle.Font = Enum.Font.GothamBold
miniTitle.TextSize = 14
miniTitle.TextColor3 = Config.UI.Accent
miniTitle.Text = "CITY MAP"
miniTitle.Parent = miniMap

local mapCanvas = Instance.new("Frame")
mapCanvas.Position = UDim2.fromOffset(8, 24)
mapCanvas.Size = UDim2.fromOffset(116, 100)
mapCanvas.BackgroundColor3 = Color3.fromRGB(28, 31, 37)
mapCanvas.Parent = miniMap
local mapCanvasCorner = Instance.new("UICorner")
mapCanvasCorner.CornerRadius = UDim.new(0, 10)
mapCanvasCorner.Parent = mapCanvas

local function addMiniDistrict(name, pos, size, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = pos
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel = 0
	frame.Parent = mapCanvas
	return frame
end

addMiniDistrict("RedlineRow", UDim2.new(0.02, 0, 0.16, 0), UDim2.new(0.28, 0, 0.62, 0), Config.World.DistrictColors.RedlineRow)
addMiniDistrict("PennMarket", UDim2.new(0.32, 0, 0.18, 0), UDim2.new(0.24, 0, 0.56, 0), Config.World.DistrictColors.PennMarket)
addMiniDistrict("DruidHeights", UDim2.new(0.12, 0, 0.02, 0), UDim2.new(0.48, 0, 0.16, 0), Config.World.DistrictColors.DruidHeights)
addMiniDistrict("IronHarbor", UDim2.new(0.58, 0, 0.46, 0), UDim2.new(0.28, 0, 0.38, 0), Config.World.DistrictColors.IronHarbor)
addMiniDistrict("CanalSide", UDim2.new(0.72, 0, 0.12, 0), UDim2.new(0.24, 0, 0.28, 0), Config.World.DistrictColors.CanalSide)
addMiniDistrict("QuarryRun", UDim2.new(0.0, 0, 0.72, 0), UDim2.new(0.22, 0, 0.24, 0), Config.World.DistrictColors.QuarryRun)

local playerDot = Instance.new("Frame")
playerDot.Size = UDim2.fromOffset(8, 8)
playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerDot.BorderSizePixel = 0
playerDot.Parent = mapCanvas
local playerDotCorner = Instance.new("UICorner")
playerDotCorner.CornerRadius = UDim.new(1, 0)
playerDotCorner.Parent = playerDot

local districtLabel = Instance.new("TextLabel")
districtLabel.Position = UDim2.new(1, -240, 0, 160)
districtLabel.Size = UDim2.fromOffset(220, 24)
districtLabel.BackgroundTransparency = 1
districtLabel.Font = Enum.Font.GothamBold
districtLabel.TextSize = 16
districtLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
districtLabel.TextXAlignment = Enum.TextXAlignment.Right
districtLabel.Text = "District: Unknown"
districtLabel.Parent = root

local localState = {
	Heat = 0,
	Level = 0,
	Label = "Clean",
	EquippedBikeId = nil,
	ToastExpiresAt = 0,
}

local function setToast(text, color)
	toastLabel.Text = text or ""
	toastLabel.TextColor3 = color or Color3.fromRGB(245, 245, 245)
	localState.ToastExpiresAt = os.clock() + 3
end

local function getCurrentRootPart()
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function refreshSpeed()
	local speed = player:GetAttribute("StreetLegalSpeedMph") or 0
	local gear = player:GetAttribute("StreetLegalGear") or "Neutral"
	local bikeName = player:GetAttribute("StreetLegalBikeName") or "On Foot"
	local combo = player:GetAttribute("StreetLegalComboText") or ""
	local district = player:GetAttribute("StreetLegalDistrict") or "Unknown"
	bikeLabel.Text = bikeName
	speedLabel.Text = string.format("%d MPH", speed)
	gearLabel.Text = gear
	comboLabel.Text = combo
	districtLabel.Text = "District: " .. district
end

local function refreshHeat()
	wantedLabel.Text = string.format("HEAT: %s", string.upper(localState.Label or "Clean"))
	heatBar.Size = UDim2.new(math.clamp((localState.Heat or 0) / 140, 0, 1), 0, 1, 0)
end

local function refreshMinimap()
	local rootPart = getCurrentRootPart()
	if not rootPart then
		return
	end

	local minBounds = Config.World.Bounds.Min
	local maxBounds = Config.World.Bounds.Max
	local xAlpha = math.clamp((rootPart.Position.X - minBounds.X) / (maxBounds.X - minBounds.X), 0, 1)
	local zAlpha = math.clamp((rootPart.Position.Z - minBounds.Z) / (maxBounds.Z - minBounds.Z), 0, 1)
	playerDot.Position = UDim2.new(xAlpha, -4, zAlpha, -4)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		local ok, response = pcall(function()
			return bikeAction:InvokeServer("RespawnBike", { BikeId = localState.EquippedBikeId })
		end)
		if ok and response then
			setToast(response.Message or "Bike respawned.", response.Success and Config.UI.Success or Config.UI.Danger)
		end
	end
end)

wantedStateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	localState.Heat = payload.Heat or 0
	localState.Level = payload.Level or 0
	localState.Label = payload.Label or "Clean"
	refreshHeat()
end)

policeStateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.Type == "ARRESTED" then
		setToast(string.format("Arrested by %s • Fine $%d", payload.Officer or "BPD", payload.Fine or 0), Config.UI.Danger)
	end
end)

notificationRemote.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.Text then
		setToast(payload.Text, payload.Type == "danger" and Config.UI.Danger or (payload.Type == "success" and Config.UI.Success or Config.UI.Accent))
	end
end)

dataSyncRemote.OnClientEvent:Connect(function(snapshot)
	if type(snapshot) ~= "table" then
		return
	end
	localState.EquippedBikeId = snapshot.EquippedBikeId
end)

for _, attributeName in ipairs({ "StreetLegalSpeedMph", "StreetLegalGear", "StreetLegalBikeName", "StreetLegalComboText", "StreetLegalDistrict" }) do
	player:GetAttributeChangedSignal(attributeName):Connect(refreshSpeed)
end

refreshSpeed()
refreshHeat()

RunService.RenderStepped:Connect(function()
	refreshMinimap()
	if toastLabel.Text ~= "" and os.clock() >= localState.ToastExpiresAt then
		toastLabel.Text = ""
	end
	refreshSpeed()
end)
