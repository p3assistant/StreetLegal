local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Modules.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local bikeAction = remotesFolder:WaitForChild("BikeAction")
local dataSync = remotesFolder:WaitForChild("DataSync")
local notificationRemote = remotesFolder:WaitForChild("Notification")

local state = {
	Catalog = {},
	Snapshot = {
		Cash = 0,
		OwnedBikes = {},
		EquippedBikeId = nil,
	},
	SelectedBikeId = nil,
	Message = "",
	Busy = false,
}

local existingGui = playerGui:FindFirstChild("StreetLegalGarage")
if existingGui then
	existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetLegalGarage"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.3
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.78, 0.74)
panel.BackgroundColor3 = Config.UI.Panel
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 46)
title.Position = UDim2.fromOffset(12, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 28
title.TextColor3 = Config.UI.Accent
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Street Legal Garage"
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -24, 0, 22)
subtitle.Position = UDim2.fromOffset(12, 52)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(190, 195, 201)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Starter bikes are free. Progression bikes unlock with cash. Premium hook is optional."
subtitle.Parent = panel

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0, 220, 0, 30)
cashLabel.Position = UDim2.new(1, -232, 0, 18)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextSize = 18
cashLabel.TextColor3 = Config.UI.Success
cashLabel.TextXAlignment = Enum.TextXAlignment.Right
cashLabel.Text = "$0"
cashLabel.Parent = panel

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.fromOffset(14, 90)
listFrame.Size = UDim2.new(0.42, -20, 1, -148)
listFrame.BackgroundColor3 = Config.UI.Background
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.fromOffset(0, 0)
listFrame.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 12)
listCorner.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = listFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 10)
listPadding.PaddingLeft = UDim.new(0, 10)
listPadding.PaddingRight = UDim.new(0, 10)
listPadding.PaddingBottom = UDim.new(0, 10)
listPadding.Parent = listFrame

local detailFrame = Instance.new("Frame")
detailFrame.Position = UDim2.new(0.45, 0, 0, 90)
detailFrame.Size = UDim2.new(0.55, -16, 1, -148)
detailFrame.BackgroundColor3 = Config.UI.Background
detailFrame.BorderSizePixel = 0
detailFrame.Parent = panel

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 12)
detailCorner.Parent = detailFrame

local bikeName = Instance.new("TextLabel")
bikeName.Size = UDim2.new(1, -20, 0, 40)
bikeName.Position = UDim2.fromOffset(12, 12)
bikeName.BackgroundTransparency = 1
bikeName.Font = Enum.Font.GothamBlack
bikeName.TextSize = 26
bikeName.TextColor3 = Config.UI.Primary
bikeName.TextXAlignment = Enum.TextXAlignment.Left
bikeName.Text = "Select a bike"
bikeName.Parent = detailFrame

local bikeDesc = Instance.new("TextLabel")
bikeDesc.Size = UDim2.new(1, -24, 0, 70)
bikeDesc.Position = UDim2.fromOffset(12, 54)
bikeDesc.BackgroundTransparency = 1
bikeDesc.Font = Enum.Font.Gotham
bikeDesc.TextSize = 16
bikeDesc.TextWrapped = true
bikeDesc.TextColor3 = Color3.fromRGB(208, 212, 217)
bikeDesc.TextXAlignment = Enum.TextXAlignment.Left
bikeDesc.TextYAlignment = Enum.TextYAlignment.Top
bikeDesc.Text = ""
bikeDesc.Parent = detailFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -24, 0, 150)
statsLabel.Position = UDim2.fromOffset(12, 132)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 18
statsLabel.TextWrapped = true
statsLabel.TextColor3 = Color3.fromRGB(227, 228, 231)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Text = ""
statsLabel.Parent = detailFrame

local buttonRow = Instance.new("Frame")
buttonRow.Size = UDim2.new(1, -24, 0, 46)
buttonRow.Position = UDim2.new(0, 12, 1, -92)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = detailFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, -24, 0, 24)
messageLabel.Position = UDim2.new(0, 12, 1, -38)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextSize = 16
messageLabel.TextColor3 = Config.UI.Accent
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Text = "[M] closes garage"
messageLabel.Parent = detailFrame

local function makeButton(text, widthScale, color)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(widthScale, -8, 1, 0)
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(18, 18, 18)
	button.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Parent = buttonRow
	return button
end

local equipButton = makeButton("Equip", 0.32, Config.UI.Accent)
local buyButton = makeButton("Buy", 0.32, Config.UI.Primary)
local spawnButton = makeButton("Spawn", 0.32, Config.UI.Success)
spawnButton.Position = UDim2.new(0.68, 0, 0, 0)
buyButton.Position = UDim2.new(0.34, 0, 0, 0)
equipButton.Position = UDim2.new(0, 0, 0, 0)

local function setMessage(text, color)
	state.Message = text
	messageLabel.Text = text
	messageLabel.TextColor3 = color or Config.UI.Accent
end

local function setSnapshot(snapshot)
	if not snapshot then
		return
	end
	state.Snapshot = snapshot
	cashLabel.Text = string.format("$%d", snapshot.Cash or 0)
end

local function findBike(id)
	for _, bike in ipairs(state.Catalog) do
		if bike.Id == id then
			return bike
		end
	end
	return nil
end

local function updateDetails()
	local bike = findBike(state.SelectedBikeId)
	if not bike then
		bikeName.Text = "Select a bike"
		bikeDesc.Text = "Choose a bike from the left list."
		statsLabel.Text = ""
		return
	end

	bikeName.Text = bike.DisplayName
	bikeDesc.Text = bike.Description
	local owned = state.Snapshot.OwnedBikes and state.Snapshot.OwnedBikes[bike.Id]
	local costText = bike.UnlockType == "Cash" and ("$" .. tostring(bike.Price)) or (bike.UnlockType == "Gamepass" and "Game Pass" or "Free")
	statsLabel.Text = table.concat({
		string.format("Ownership: %s", owned and "Owned" or "Locked"),
		string.format("Unlock: %s", costText),
		string.format("Top Speed: %d MPH", bike.TopSpeedMph),
		string.format("Acceleration: %.2f", bike.Acceleration),
		string.format("Handling: %.2f", bike.Handling),
		string.format("Jump: %.2f", bike.Jump),
		string.format("Durability: %.2f", bike.Durability),
		string.format("Street Heat: %s", bike.IllegalOnStreet and "High" or "Low"),
	}, "\n")

	equipButton.Text = state.Snapshot.EquippedBikeId == bike.Id and "Equipped" or "Equip"
	buyButton.Text = owned and "Owned" or (bike.UnlockType == "Cash" and ("Buy $" .. tostring(bike.Price)) or (bike.UnlockType == "Gamepass" and "Unlock" or "Free"))
	spawnButton.Text = "Spawn"
end

local function renderCatalog()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, bike in ipairs(state.Catalog) do
		local owned = state.Snapshot.OwnedBikes and state.Snapshot.OwnedBikes[bike.Id]
		local row = Instance.new("TextButton")
		row.Name = bike.Id
		row.Size = UDim2.new(1, -4, 0, 62)
		row.BackgroundColor3 = state.SelectedBikeId == bike.Id and Color3.fromRGB(52, 60, 74) or Color3.fromRGB(34, 39, 46)
		row.AutoButtonColor = true
		row.Text = ""
		row.LayoutOrder = index
		row.Parent = listFrame
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -16, 0, 24)
		nameLabel.Position = UDim2.fromOffset(10, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 18
		nameLabel.TextColor3 = owned and Config.UI.Accent or Color3.fromRGB(223, 227, 231)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = bike.DisplayName
		nameLabel.Parent = row

		local metaLabel = Instance.new("TextLabel")
		metaLabel.Size = UDim2.new(1, -16, 0, 20)
		metaLabel.Position = UDim2.fromOffset(10, 34)
		metaLabel.BackgroundTransparency = 1
		metaLabel.Font = Enum.Font.Gotham
		metaLabel.TextSize = 14
		metaLabel.TextColor3 = Color3.fromRGB(175, 181, 188)
		metaLabel.TextXAlignment = Enum.TextXAlignment.Left
		metaLabel.Text = string.format("%d MPH • %s", bike.TopSpeedMph, owned and "Owned" or bike.UnlockType)
		metaLabel.Parent = row

		row.MouseButton1Click:Connect(function()
			state.SelectedBikeId = bike.Id
			renderCatalog()
			updateDetails()
		end)
	end

	task.defer(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end)
end

local function refreshGarage()
	if state.Busy then
		return
	end
	state.Busy = true
	local ok, response = pcall(function()
		return bikeAction:InvokeServer("GetGarage")
	end)
	state.Busy = false

	if not ok or not response then
		setMessage("Garage sync failed.", Config.UI.Danger)
		return
	end

	state.Catalog = response.Catalog or {}
	setSnapshot(response.Snapshot or state.Snapshot)
	if not state.SelectedBikeId then
		state.SelectedBikeId = state.Snapshot.EquippedBikeId or (state.Catalog[1] and state.Catalog[1].Id)
	end
	if not findBike(state.SelectedBikeId) and state.Catalog[1] then
		state.SelectedBikeId = state.Catalog[1].Id
	end
	renderCatalog()
	updateDetails()
end

local function invokeAction(action)
	if state.Busy or not state.SelectedBikeId then
		return
	end
	state.Busy = true
	local ok, response = pcall(function()
		return bikeAction:InvokeServer(action, { BikeId = state.SelectedBikeId })
	end)
	state.Busy = false

	if not ok or not response then
		setMessage("Action failed.", Config.UI.Danger)
		return
	end

	if response.Snapshot then
		setSnapshot(response.Snapshot)
	end

	setMessage(response.Message or "Done.", response.Success and Config.UI.Success or Config.UI.Danger)
	refreshGarage()
end

equipButton.MouseButton1Click:Connect(function()
	invokeAction("EquipBike")
end)

buyButton.MouseButton1Click:Connect(function()
	local bike = findBike(state.SelectedBikeId)
	if bike and bike.UnlockType == "Free" then
		setMessage("This bike is already free.", Config.UI.Accent)
		return
	end
	invokeAction("BuyBike")
end)

spawnButton.MouseButton1Click:Connect(function()
	invokeAction("SpawnBike")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.M then
		gui.Enabled = not gui.Enabled
		if gui.Enabled then
			refreshGarage()
			setMessage("M closes garage", Config.UI.Accent)
		end
	end
end)

dataSync.OnClientEvent:Connect(function(snapshot)
	setSnapshot(snapshot)
	updateDetails()
	renderCatalog()
end)

notificationRemote.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.Text then
		setMessage(payload.Text, payload.Type == "danger" and Config.UI.Danger or Config.UI.Accent)
	end
end)

refreshGarage()
