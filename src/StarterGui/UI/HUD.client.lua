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

if playerGui:GetAttribute("StreetLegalGarageOpen") == nil then
	playerGui:SetAttribute("StreetLegalGarageOpen", false)
end
if playerGui:GetAttribute("StreetLegalGarageFocusFree") == nil then
	playerGui:SetAttribute("StreetLegalGarageFocusFree", false)
end

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
speedFrame.Position = UDim2.new(0, 18, 1, -140)
speedFrame.Size = UDim2.fromOffset(260, 114)
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

local bikeStatusLabel = Instance.new("TextLabel")
bikeStatusLabel.Size = UDim2.new(1, -18, 0, 16)
bikeStatusLabel.Position = UDim2.fromOffset(12, 94)
bikeStatusLabel.BackgroundTransparency = 1
bikeStatusLabel.Font = Enum.Font.GothamBold
bikeStatusLabel.TextSize = 13
bikeStatusLabel.TextColor3 = Config.UI.Success
bikeStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
bikeStatusLabel.Text = ""
bikeStatusLabel.Parent = speedFrame

local heatFrame = Instance.new("Frame")
heatFrame.Position = UDim2.new(0, 18, 0, 18)
heatFrame.Size = UDim2.fromOffset(320, 96)
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
promptLabel.Size = UDim2.new(1, -24, 0, 22)
promptLabel.Position = UDim2.fromOffset(12, 68)
promptLabel.BackgroundTransparency = 1
promptLabel.Font = Enum.Font.Gotham
promptLabel.TextSize = 13
promptLabel.TextColor3 = Color3.fromRGB(190, 195, 202)
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Text = "Garage on HUD • R respawn bike • Q hop • Ctrl + W wheelie • Tap W to balance"
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
toastLabel.Size = UDim2.fromOffset(480, 28)
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
districtLabel.Position = UDim2.new(1, -260, 0, 160)
districtLabel.Size = UDim2.fromOffset(240, 24)
districtLabel.BackgroundTransparency = 1
districtLabel.Font = Enum.Font.GothamBold
districtLabel.TextSize = 16
districtLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
districtLabel.TextXAlignment = Enum.TextXAlignment.Right
districtLabel.Text = "District: Unknown"
districtLabel.Parent = root

local garageButton = Instance.new("TextButton")
garageButton.AnchorPoint = Vector2.new(1, 1)
garageButton.Position = UDim2.new(1, -18, 1, -18)
garageButton.Size = UDim2.fromOffset(196, 52)
garageButton.BackgroundColor3 = Config.UI.Accent
garageButton.Font = Enum.Font.GothamBlack
garageButton.TextSize = 20
garageButton.TextColor3 = Color3.fromRGB(18, 18, 18)
garageButton.Text = "GARAGE"
garageButton.Parent = root
local garageCorner = Instance.new("UICorner")
garageCorner.CornerRadius = UDim.new(0, 12)
garageCorner.Parent = garageButton

local noBikeCallout = Instance.new("Frame")
noBikeCallout.AnchorPoint = Vector2.new(0.5, 0)
noBikeCallout.Position = UDim2.fromScale(0.5, 0.25)
noBikeCallout.Size = UDim2.fromOffset(420, 120)
noBikeCallout.BackgroundColor3 = Color3.fromRGB(30, 35, 42)
noBikeCallout.BackgroundTransparency = 0.04
noBikeCallout.Parent = root
local noBikeCorner = Instance.new("UICorner")
noBikeCorner.CornerRadius = UDim.new(0, 16)
noBikeCorner.Parent = noBikeCallout

local noBikeTitle = Instance.new("TextLabel")
noBikeTitle.Size = UDim2.new(1, -24, 0, 28)
noBikeTitle.Position = UDim2.fromOffset(12, 12)
noBikeTitle.BackgroundTransparency = 1
noBikeTitle.Font = Enum.Font.GothamBlack
noBikeTitle.TextSize = 24
noBikeTitle.TextColor3 = Config.UI.Accent
noBikeTitle.Text = "SELECT A BIKE TO RIDE"
noBikeTitle.Parent = noBikeCallout

local noBikeBody = Instance.new("TextLabel")
noBikeBody.Size = UDim2.new(1, -24, 0, 38)
noBikeBody.Position = UDim2.fromOffset(12, 42)
noBikeBody.BackgroundTransparency = 1
noBikeBody.Font = Enum.Font.Gotham
noBikeBody.TextSize = 16
noBikeBody.TextWrapped = true
noBikeBody.TextColor3 = Color3.fromRGB(230, 233, 236)
noBikeBody.Text = "You are on foot with no active bike. Open the garage, pick a free starter, and click Equip & Spawn."
noBikeBody.Parent = noBikeCallout

local noBikeButton = Instance.new("TextButton")
noBikeButton.Size = UDim2.fromOffset(170, 34)
noBikeButton.Position = UDim2.new(0.5, -85, 1, -46)
noBikeButton.BackgroundColor3 = Config.UI.Success
noBikeButton.Font = Enum.Font.GothamBlack
noBikeButton.TextSize = 18
noBikeButton.TextColor3 = Color3.fromRGB(18, 18, 18)
noBikeButton.Text = "SPAWN BIKE"
noBikeButton.Parent = noBikeCallout
local noBikeButtonCorner = Instance.new("UICorner")
noBikeButtonCorner.CornerRadius = UDim.new(0, 10)
noBikeButtonCorner.Parent = noBikeButton

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

local function noActiveBike()
	return player:GetAttribute("StreetLegalActiveBikeId") == nil
end

local function openGarage(focusFree)
	playerGui:SetAttribute("StreetLegalGarageFocusFree", focusFree)
	playerGui:SetAttribute("StreetLegalGarageOpen", true)
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

local function refreshBikePrompts()
	if noActiveBike() then
		bikeStatusLabel.Text = "NO BIKE ACTIVE"
		bikeStatusLabel.TextColor3 = Config.UI.Danger
		promptLabel.Text = "No bike active • Click Spawn Bike or press M • Free starters are ready in the garage"
		garageButton.Text = "SPAWN BIKE"
		garageButton.BackgroundColor3 = Config.UI.Success
		noBikeCallout.Visible = true
	else
		bikeStatusLabel.Text = "ACTIVE BIKE READY"
		bikeStatusLabel.TextColor3 = Config.UI.Success
		promptLabel.Text = "Garage on HUD • R respawn bike • Q hop • Ctrl + W wheelie • Tap W to balance"
		garageButton.Text = "GARAGE"
		garageButton.BackgroundColor3 = Config.UI.Accent
		noBikeCallout.Visible = false
	end
end

local function requestRespawn()
	if noActiveBike() then
		openGarage(true)
		setToast("No bike out. Pick one in the garage first.", Config.UI.Accent)
		return
	end

	local ok, response = pcall(function()
		return bikeAction:InvokeServer("RespawnBike", { BikeId = localState.EquippedBikeId })
	end)
	if ok and response then
		setToast(response.Message or "Bike respawned.", response.Success and Config.UI.Success or Config.UI.Danger)
	end
end

local function handleGarageButton()
	openGarage(noActiveBike())
	if noActiveBike() then
		setToast("Pick a free starter and hit Equip & Spawn.", Config.UI.Accent)
	else
		setToast("Garage opened.", Config.UI.Accent)
	end
end

garageButton.MouseButton1Click:Connect(handleGarageButton)
noBikeButton.MouseButton1Click:Connect(handleGarageButton)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		requestRespawn()
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
	refreshBikePrompts()
end)

for _, attributeName in ipairs({ "StreetLegalSpeedMph", "StreetLegalGear", "StreetLegalBikeName", "StreetLegalComboText", "StreetLegalDistrict", "StreetLegalActiveBikeId" }) do
	player:GetAttributeChangedSignal(attributeName):Connect(function()
		refreshSpeed()
		refreshBikePrompts()
	end)
end

refreshSpeed()
refreshHeat()
refreshBikePrompts()

RunService.RenderStepped:Connect(function()
	refreshMinimap()
	if toastLabel.Text ~= "" and os.clock() >= localState.ToastExpiresAt then
		toastLabel.Text = ""
	end
	refreshSpeed()
	refreshBikePrompts()
end)
