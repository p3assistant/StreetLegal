local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local bikeAction = remotesFolder:WaitForChild("BikeAction")
local dataSync = remotesFolder:WaitForChild("DataSync")
local notificationRemote = remotesFolder:WaitForChild("Notification")

if playerGui:GetAttribute("StreetLegalGarageOpen") == nil then
	playerGui:SetAttribute("StreetLegalGarageOpen", false)
end
if playerGui:GetAttribute("StreetLegalGarageFocusFree") == nil then
	playerGui:SetAttribute("StreetLegalGarageFocusFree", false)
end

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
	ServerReachable = false,
	AutoOpenedCharacter = nil,
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

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.28
backdrop.BorderSizePixel = 0
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.84, 0.8)
panel.BackgroundColor3 = Config.UI.Panel
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -180, 0, 42)
title.Position = UDim2.fromOffset(18, 12)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 28
title.TextColor3 = Config.UI.Accent
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Garage"
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -260, 0, 20)
subtitle.Position = UDim2.fromOffset(18, 50)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(190, 195, 201)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Pick a free starter, click Equip & Spawn, and ride. Garage is always on the HUD now."
subtitle.Parent = panel

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0, 180, 0, 28)
cashLabel.Position = UDim2.new(1, -232, 0, 18)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextSize = 18
cashLabel.TextColor3 = Config.UI.Success
cashLabel.TextXAlignment = Enum.TextXAlignment.Right
cashLabel.Text = "$0"
cashLabel.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(42, 42)
closeButton.Position = UDim2.new(1, -54, 0, 14)
closeButton.BackgroundColor3 = Color3.fromRGB(38, 43, 51)
closeButton.Font = Enum.Font.GothamBlack
closeButton.TextSize = 22
closeButton.TextColor3 = Color3.fromRGB(245, 245, 245)
closeButton.Text = "×"
closeButton.Parent = panel
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.fromOffset(18, 86)
listFrame.Size = UDim2.new(0.38, -18, 1, -154)
listFrame.BackgroundColor3 = Config.UI.Background
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.fromOffset(0, 0)
listFrame.Parent = panel
local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 12)
listCorner.Parent = listFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 10)
listPadding.PaddingBottom = UDim.new(0, 10)
listPadding.PaddingLeft = UDim.new(0, 10)
listPadding.PaddingRight = UDim.new(0, 10)
listPadding.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = listFrame

local detailFrame = Instance.new("Frame")
detailFrame.Position = UDim2.new(0.4, 6, 0, 86)
detailFrame.Size = UDim2.new(0.6, -24, 1, -154)
detailFrame.BackgroundColor3 = Config.UI.Background
detailFrame.BorderSizePixel = 0
detailFrame.Parent = panel
local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 12)
detailCorner.Parent = detailFrame

local welcomeCard = Instance.new("Frame")
welcomeCard.Size = UDim2.new(1, -24, 0, 110)
welcomeCard.Position = UDim2.fromOffset(12, 12)
welcomeCard.BackgroundColor3 = Color3.fromRGB(34, 40, 48)
welcomeCard.Parent = detailFrame
local welcomeCorner = Instance.new("UICorner")
welcomeCorner.CornerRadius = UDim.new(0, 12)
welcomeCorner.Parent = welcomeCard

local welcomeTitle = Instance.new("TextLabel")
welcomeTitle.Size = UDim2.new(1, -20, 0, 30)
welcomeTitle.Position = UDim2.fromOffset(12, 10)
welcomeTitle.BackgroundTransparency = 1
welcomeTitle.Font = Enum.Font.GothamBlack
welcomeTitle.TextSize = 22
welcomeTitle.TextColor3 = Config.UI.Accent
welcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
welcomeTitle.Text = "Start here"
welcomeTitle.Parent = welcomeCard

local welcomeBody = Instance.new("TextLabel")
welcomeBody.Size = UDim2.new(1, -20, 1, -46)
welcomeBody.Position = UDim2.fromOffset(12, 38)
welcomeBody.BackgroundTransparency = 1
welcomeBody.Font = Enum.Font.Gotham
welcomeBody.TextSize = 15
welcomeBody.TextWrapped = true
welcomeBody.TextYAlignment = Enum.TextYAlignment.Top
welcomeBody.TextXAlignment = Enum.TextXAlignment.Left
welcomeBody.TextColor3 = Color3.fromRGB(220, 224, 229)
welcomeBody.Text = "1. Pick any free starter bike from the list.\n2. Click Equip & Spawn.\n3. If you end up on foot with no bike out, hit the HUD Spawn Bike button."
welcomeBody.Parent = welcomeCard

local bikeName = Instance.new("TextLabel")
bikeName.Size = UDim2.new(1, -24, 0, 34)
bikeName.Position = UDim2.fromOffset(12, 136)
bikeName.BackgroundTransparency = 1
bikeName.Font = Enum.Font.GothamBlack
bikeName.TextSize = 28
bikeName.TextColor3 = Color3.fromRGB(245, 245, 245)
bikeName.TextXAlignment = Enum.TextXAlignment.Left
bikeName.Text = "Select a bike"
bikeName.Parent = detailFrame

local badgeLabel = Instance.new("TextLabel")
badgeLabel.Size = UDim2.new(1, -24, 0, 22)
badgeLabel.Position = UDim2.fromOffset(12, 172)
badgeLabel.BackgroundTransparency = 1
badgeLabel.Font = Enum.Font.GothamBold
badgeLabel.TextSize = 14
badgeLabel.TextColor3 = Config.UI.Accent
badgeLabel.TextXAlignment = Enum.TextXAlignment.Left
badgeLabel.Text = ""
badgeLabel.Parent = detailFrame

local bikeDesc = Instance.new("TextLabel")
bikeDesc.Size = UDim2.new(1, -24, 0, 70)
bikeDesc.Position = UDim2.fromOffset(12, 198)
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
statsLabel.Size = UDim2.new(1, -24, 0, 176)
statsLabel.Position = UDim2.fromOffset(12, 274)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 17
statsLabel.TextWrapped = true
statsLabel.TextColor3 = Color3.fromRGB(227, 228, 231)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Text = ""
statsLabel.Parent = detailFrame

local buttonRow = Instance.new("Frame")
buttonRow.Size = UDim2.new(1, -24, 0, 52)
buttonRow.Position = UDim2.new(0, 12, 1, -102)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = detailFrame

local function makeButton(name, text, color, positionScale, widthScale)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(widthScale, -8, 1, 0)
	button.Position = UDim2.new(positionScale, 0, 0, 0)
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(18, 18, 18)
	button.Text = text
	button.Parent = buttonRow
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

local primaryButton = makeButton("PrimaryButton", "Equip & Spawn", Config.UI.Success, 0, 0.48)
local secondaryButton = makeButton("SecondaryButton", "Equip Only", Config.UI.Accent, 0.5, 0.24)
local storeButton = makeButton("StoreButton", "Store Bike", Color3.fromRGB(134, 157, 181), 0.76, 0.24)

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, -24, 0, 24)
messageLabel.Position = UDim2.new(0, 12, 1, -40)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextSize = 15
messageLabel.TextColor3 = Config.UI.Accent
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Text = "Garage button is pinned on the HUD. M still toggles this menu."
messageLabel.Parent = detailFrame

local footerLabel = Instance.new("TextLabel")
footerLabel.Size = UDim2.new(1, -24, 0, 22)
footerLabel.Position = UDim2.new(0, 18, 1, -28)
footerLabel.BackgroundTransparency = 1
footerLabel.Font = Enum.Font.Gotham
footerLabel.TextSize = 13
footerLabel.TextColor3 = Color3.fromRGB(176, 182, 189)
footerLabel.TextXAlignment = Enum.TextXAlignment.Left
footerLabel.Text = ""
footerLabel.Parent = panel

local function setFooterText()
	footerLabel.Text = "HUD buttons: Garage / Spawn Bike • M toggles garage • R respawns active bike • Q hops"
end
setFooterText()

local function setGarageOpen(isOpen, focusFree)
	if focusFree ~= nil then
		playerGui:SetAttribute("StreetLegalGarageFocusFree", focusFree)
	end
	playerGui:SetAttribute("StreetLegalGarageOpen", isOpen)
	gui.Enabled = isOpen
end

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

local function getActiveBikeId()
	return player:GetAttribute("StreetLegalActiveBikeId")
end

local function ownsBike(bikeId)
	return state.Snapshot.OwnedBikes and state.Snapshot.OwnedBikes[bikeId] == true or false
end

local function findBike(id)
	for _, bike in ipairs(state.Catalog) do
		if bike.Id == id then
			return bike
		end
	end
	return nil
end

local function choosePreferredBike(focusFree)
	if focusFree then
		for _, bike in ipairs(state.Catalog) do
			if bike.UnlockType == "Free" then
				return bike.Id
			end
		end
	end

	local equipped = state.Snapshot.EquippedBikeId
	if equipped and findBike(equipped) then
		return equipped
	end

	return state.Catalog[1] and state.Catalog[1].Id or nil
end

local function isBootstrapReady()
	return ReplicatedStorage:GetAttribute("StreetLegalBootstrapReady") == true or state.ServerReachable == true
end

local function isSpawnReady()
	return player:GetAttribute("StreetLegalSpawnReady") == true
end

local function buildFallbackCatalog()
	local catalog = {}
	for bikeId, bike in pairs(BikeDefinitions) do
		table.insert(catalog, {
			Id = bikeId,
			DisplayName = bike.DisplayName,
			StyleTag = bike.StyleTag,
			UnlockType = bike.UnlockType,
			Price = bike.Price,
			GamePassId = bike.GamePassId,
			Tier = bike.Tier,
			TopSpeedMph = bike.TopSpeedMph,
			Acceleration = bike.Acceleration,
			Handling = bike.Handling,
			Jump = bike.Jump,
			Durability = bike.Durability,
			IllegalOnStreet = bike.IllegalOnStreet,
			Description = bike.Description,
		})
	end

	table.sort(catalog, function(a, b)
		if a.UnlockType ~= b.UnlockType then
			if a.UnlockType == "Free" or b.UnlockType == "Free" then
				return a.UnlockType == "Free"
			end
		end
		if a.Tier == b.Tier then
			if a.Price == b.Price then
				return a.DisplayName < b.DisplayName
			end
			return a.Price < b.Price
		end
		return a.Tier < b.Tier
	end)

	return catalog
end

local function meter(value)
	local normalized = math.clamp(math.floor((value * 2.1) + 0.5), 1, 5)
	return string.rep("■", normalized) .. string.rep("□", 5 - normalized)
end

local function updateButton(button, enabled, text, color)
	button.Text = text
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = enabled and color or Color3.fromRGB(62, 68, 76)
	button.TextTransparency = enabled and 0 or 0.25
end

local function updateDetails()
	local bike = findBike(state.SelectedBikeId)
	local activeBikeId = getActiveBikeId()
	local noActiveBike = activeBikeId == nil
	if noActiveBike then
		welcomeTitle.Text = "Pick your first ride"
		welcomeBody.Text = "Choose any free starter bike, then hit Equip & Spawn. If you wipe out or end up on foot with no bike active, the HUD keeps a giant Spawn Bike button on screen."
	else
		welcomeTitle.Text = "Garage is pinned"
		welcomeBody.Text = "Your garage is always one click away from the HUD. Use it to swap bikes, respawn one in front of you, or store the current ride."
	end

	if not bike then
		bikeName.Text = "Select a bike"
		badgeLabel.Text = ""
		bikeDesc.Text = "Choose a bike from the list on the left."
		statsLabel.Text = ""
		updateButton(primaryButton, false, "Select a bike", Config.UI.Success)
		updateButton(secondaryButton, false, "Equip Only", Config.UI.Accent)
		updateButton(storeButton, activeBikeId ~= nil, activeBikeId and "Store Current Bike" or "No Bike Out", Color3.fromRGB(134, 157, 181))
		return
	end

	local owned = ownsBike(bike.Id)
	local equipped = state.Snapshot.EquippedBikeId == bike.Id
	local active = activeBikeId == bike.Id
	local unlockText = bike.UnlockType == "Cash" and ("$" .. tostring(bike.Price)) or (bike.UnlockType == "Gamepass" and "Game Pass" or "Free Starter")
	local ownershipLabel = owned and (active and "ACTIVE" or (equipped and "EQUIPPED" or "OWNED")) or "LOCKED"

	bikeName.Text = bike.DisplayName
	badgeLabel.Text = string.format("%s • Tier %d • %s", bike.StyleTag or "Electric dirt bike", bike.Tier or 1, ownershipLabel)
	bikeDesc.Text = bike.Description or ""
	statsLabel.Text = table.concat({
		string.format("Ownership    %s", ownershipLabel),
		string.format("Unlock       %s", unlockText),
		string.format("Top Speed    %d MPH", bike.TopSpeedMph or 0),
		string.format("Acceleration %s", meter(bike.Acceleration or 1)),
		string.format("Handling     %s", meter(bike.Handling or 1)),
		string.format("Jump         %s", meter(bike.Jump or 1)),
		string.format("Durability   %s", meter(bike.Durability or 1)),
		string.format("Street Heat  %s", bike.IllegalOnStreet and "High" or "Low"),
	}, "\n")

	if owned then
		if active then
			updateButton(primaryButton, true, "Respawn Selected", Config.UI.Success)
		elseif equipped then
			updateButton(primaryButton, true, "Spawn Selected", Config.UI.Success)
		else
			updateButton(primaryButton, true, "Equip & Spawn", Config.UI.Success)
		end
		updateButton(secondaryButton, not equipped, equipped and "Equipped" or "Equip Only", Config.UI.Accent)
	else
		if bike.UnlockType == "Free" then
			updateButton(primaryButton, true, "Claim & Spawn", Config.UI.Success)
		else
			updateButton(primaryButton, true, bike.UnlockType == "Cash" and ("Buy $" .. tostring(bike.Price)) or "Unlock", Config.UI.Primary)
		end
		updateButton(secondaryButton, false, bike.UnlockType == "Free" and "Free Starter" or "Owned Required", Config.UI.Accent)
	end

	updateButton(storeButton, activeBikeId ~= nil, active and "Store Active Bike" or (activeBikeId and "Store Current Bike" or "No Bike Out"), Color3.fromRGB(134, 157, 181))
end

local function renderCatalog()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") or child.Name == "CatalogHeader" then
			child:Destroy()
		end
	end

	local header = Instance.new("TextLabel")
	header.Name = "CatalogHeader"
	header.Size = UDim2.new(1, -4, 0, 40)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 15
	header.TextColor3 = Config.UI.Accent
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "Free starters are at the top. Pick one and hit Equip & Spawn."
	header.LayoutOrder = -1
	header.Parent = listFrame

	for index, bike in ipairs(state.Catalog) do
		local owned = ownsBike(bike.Id)
		local active = getActiveBikeId() == bike.Id
		local unlockText = bike.UnlockType == "Cash" and ("$" .. tostring(bike.Price)) or (bike.UnlockType == "Gamepass" and "GAME PASS" or "FREE STARTER")
		local row = Instance.new("TextButton")
		row.Name = bike.Id
		row.Size = UDim2.new(1, -4, 0, 76)
		row.BackgroundColor3 = state.SelectedBikeId == bike.Id and Color3.fromRGB(56, 66, 82) or Color3.fromRGB(34, 39, 46)
		row.AutoButtonColor = true
		row.Text = ""
		row.LayoutOrder = index
		row.Parent = listFrame
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -18, 0, 24)
		nameLabel.Position = UDim2.fromOffset(10, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 18
		nameLabel.TextColor3 = owned and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(220, 220, 220)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = bike.DisplayName
		nameLabel.Parent = row

		local subLabel = Instance.new("TextLabel")
		subLabel.Size = UDim2.new(1, -18, 0, 18)
		subLabel.Position = UDim2.fromOffset(10, 34)
		subLabel.BackgroundTransparency = 1
		subLabel.Font = Enum.Font.Gotham
		subLabel.TextSize = 13
		subLabel.TextColor3 = Color3.fromRGB(182, 188, 195)
		subLabel.TextXAlignment = Enum.TextXAlignment.Left
		subLabel.Text = string.format("%s • %d MPH", bike.StyleTag or "Electric dirt bike", bike.TopSpeedMph or 0)
		subLabel.Parent = row

		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.new(1, -18, 0, 16)
		tagLabel.Position = UDim2.fromOffset(10, 54)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Font = Enum.Font.GothamBold
		tagLabel.TextSize = 12
		tagLabel.TextXAlignment = Enum.TextXAlignment.Left
		tagLabel.TextColor3 = active and Config.UI.Success or (owned and Config.UI.Accent or Color3.fromRGB(162, 166, 172))
		tagLabel.Text = active and "BIKE ACTIVE" or (owned and (bike.UnlockType == "Free" and "FREE • OWNED" or "OWNED") or unlockText)
		tagLabel.Parent = row

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

local function refreshGarage(forceSelection)
	if state.Busy then
		return
	end

	if not isBootstrapReady() then
		state.Catalog = buildFallbackCatalog()
		if forceSelection or not state.SelectedBikeId or not findBike(state.SelectedBikeId) then
			state.SelectedBikeId = choosePreferredBike(true)
		end
		renderCatalog()
		updateDetails()
		setMessage("Garage is still loading. Bikes are listed, but spawn actions unlock in a second.", Config.UI.Accent)
		return
	end

	state.Busy = true
	local ok, response = pcall(function()
		return bikeAction:InvokeServer("GetGarage")
	end)
	state.Busy = false

	if not ok or not response then
		state.Catalog = buildFallbackCatalog()
		renderCatalog()
		updateDetails()
		setMessage("Garage sync failed. Retrying when the server finishes booting.", Config.UI.Danger)
		return
	end

	state.ServerReachable = true
	state.Catalog = (#(response.Catalog or {}) > 0) and response.Catalog or buildFallbackCatalog()
	setSnapshot(response.Snapshot or state.Snapshot)
	player:SetAttribute("StreetLegalActiveBikeId", response.ActiveBikeId)

	local shouldFocusFree = playerGui:GetAttribute("StreetLegalGarageFocusFree") == true
	if forceSelection or not state.SelectedBikeId or shouldFocusFree or not findBike(state.SelectedBikeId) then
		state.SelectedBikeId = choosePreferredBike(shouldFocusFree)
		if shouldFocusFree then
			playerGui:SetAttribute("StreetLegalGarageFocusFree", false)
		end
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
	refreshGarage(false)

	if response.Success and (action == "SpawnBike" or action == "RespawnBike" or action == "EquipAndSpawnBike") then
		setGarageOpen(false)
	end
end

local function handlePrimaryAction()
	local bike = findBike(state.SelectedBikeId)
	if not bike then
		return
	end

	local owned = ownsBike(bike.Id)
	local equipped = state.Snapshot.EquippedBikeId == bike.Id
	local active = getActiveBikeId() == bike.Id

	if owned then
		if active then
			invokeAction("RespawnBike")
		elseif equipped then
			invokeAction("SpawnBike")
		else
			invokeAction("EquipAndSpawnBike")
		end
		return
	end

	if bike.UnlockType == "Free" then
		invokeAction("EquipAndSpawnBike")
	else
		invokeAction("BuyBike")
	end
end

local function handleSecondaryAction()
	local bike = findBike(state.SelectedBikeId)
	if not bike or not ownsBike(bike.Id) then
		return
	end
	if state.Snapshot.EquippedBikeId == bike.Id then
		setMessage(string.format("%s is already equipped.", bike.DisplayName), Config.UI.Accent)
		return
	end
	invokeAction("EquipBike")
end

local function openGarage(focusFree, message)
	setGarageOpen(true, focusFree)
	refreshGarage(true)
	setMessage(message or "Pick a bike and hit Equip & Spawn.", Config.UI.Accent)
end

backdrop.MouseButton1Click:Connect(function()
	setGarageOpen(false)
end)

closeButton.MouseButton1Click:Connect(function()
	setGarageOpen(false)
end)

primaryButton.MouseButton1Click:Connect(handlePrimaryAction)
secondaryButton.MouseButton1Click:Connect(handleSecondaryAction)
storeButton.MouseButton1Click:Connect(function()
	if getActiveBikeId() then
		invokeAction("StoreBike")
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.M then
		if gui.Enabled then
			setGarageOpen(false)
		else
			openGarage(false, "Garage opened. Pick a bike, then click Spawn.")
		end
	end
end)

playerGui:GetAttributeChangedSignal("StreetLegalGarageOpen"):Connect(function()
	local shouldOpen = playerGui:GetAttribute("StreetLegalGarageOpen") == true
	gui.Enabled = shouldOpen
	if shouldOpen then
		refreshGarage(false)
	end
end)

ReplicatedStorage:GetAttributeChangedSignal("StreetLegalBootstrapReady"):Connect(function()
	if isBootstrapReady() then
		refreshGarage(true)
	end
end)

player:GetAttributeChangedSignal("StreetLegalActiveBikeId"):Connect(function()
	if gui.Enabled then
		renderCatalog()
		updateDetails()
	end
end)

dataSync.OnClientEvent:Connect(function(snapshot)
	setSnapshot(snapshot)
	if gui.Enabled then
		updateDetails()
		renderCatalog()
	end
end)

notificationRemote.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.Text then
		setMessage(payload.Text, payload.Type == "danger" and Config.UI.Danger or Config.UI.Accent)
	end
end)

local function scheduleFirstSpawnOpen(character)
	if not character or state.AutoOpenedCharacter == character then
		return
	end
	state.AutoOpenedCharacter = character
	playerGui:SetAttribute("StreetLegalGarageFocusFree", true)
	task.spawn(function()
		local startedAt = os.clock()
		while player.Character == character and (not isSpawnReady() or not isBootstrapReady()) do
			if os.clock() - startedAt > 12 then
				break
			end
			task.wait(0.1)
		end

		if player.Character ~= character then
			return
		end
		if player:GetAttribute("StreetLegalActiveBikeId") then
			return
		end
		openGarage(true, "Choose a free starter bike and hit Equip & Spawn.")
	end)
end

player.CharacterAdded:Connect(scheduleFirstSpawnOpen)
if player.Character then
	scheduleFirstSpawnOpen(player.Character)
end

refreshGarage(true)
setMessage("Garage button is pinned on the HUD. Pick a bike and ride.", Config.UI.Accent)
