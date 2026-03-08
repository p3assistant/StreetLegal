local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)

local PurchaseService = {
	ActiveBikes = {},
	RuntimeFolder = nil,
	BikesFolder = nil,
	DataService = nil,
	WantedService = nil,
	Remotes = nil,
	Initialized = false,
}

local function now()
	return Workspace:GetServerTimeNow()
end

local function createWeld(parent, part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = parent
	return weld
end

local function createPart(parent, name, size, cframe, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = true
	part.Anchored = false
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function getRuntimeFolder()
	local runtimeFolder = Workspace:FindFirstChild("StreetLegalRuntime")
	if not runtimeFolder then
		runtimeFolder = Instance.new("Folder")
		runtimeFolder.Name = "StreetLegalRuntime"
		runtimeFolder.Parent = Workspace
	end

	local bikesFolder = runtimeFolder:FindFirstChild("Bikes")
	if not bikesFolder then
		bikesFolder = Instance.new("Folder")
		bikesFolder.Name = "Bikes"
		bikesFolder.Parent = runtimeFolder
	end

	return runtimeFolder, bikesFolder
end

local function copyBikeForClient(_, bikeId)
	local bike = BikeDefinitions[bikeId]
	local payload = {
		Id = bike.Id,
		DisplayName = bike.DisplayName,
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
	}
	return payload
end

function PurchaseService:Init(dataService, wantedService, remotes)
	if self.Initialized then
		return
	end

	self.Initialized = true
	self.DataService = dataService
	self.WantedService = wantedService
	self.Remotes = remotes
	self.RuntimeFolder, self.BikesFolder = getRuntimeFolder()

	self.Remotes.BikeAction.OnServerInvoke = function(player, action, payload)
		return self:HandleBikeAction(player, action, payload)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end

		for bikeId, bike in pairs(BikeDefinitions) do
			if bike.GamePassId == gamePassId and gamePassId ~= 0 then
				self.DataService:GrantBike(player, bikeId)
				self.DataService:SetEquippedBike(player, bikeId)
				if self.Remotes.Notification then
					self.Remotes.Notification:FireClient(player, {
						Type = "success",
						Text = string.format("Unlocked %s.", bike.DisplayName),
					})
				end
				break
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:DespawnBike(player)
	end)
end

function PurchaseService:GetCatalog(player)
	local catalog = {}
	for bikeId, bike in pairs(BikeDefinitions) do
		local entry = copyBikeForClient(player, bikeId)
		entry.Owned = self.DataService:OwnsBike(player, bikeId)
		table.insert(catalog, entry)
	end

	table.sort(catalog, function(a, b)
		if a.Tier == b.Tier then
			return a.Price < b.Price
		end
		return a.Tier < b.Tier
	end)

	return catalog
end

function PurchaseService:GetGarageState(player)
	return {
		Success = true,
		Catalog = self:GetCatalog(player),
		Snapshot = self.DataService:GetClientSnapshot(player),
	}
end

function PurchaseService:GetSpawnCFrame(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local forward = rootPart.CFrame.LookVector
		return CFrame.new(rootPart.Position + (forward * Config.Gameplay.TeleportSpawnOffset) + Vector3.new(0, Config.Gameplay.BikeRespawnHeight, 0), rootPart.Position + (forward * 60))
	end

	local spawns = Workspace:FindFirstChild("Spawns")
	if spawns then
		for _, descendant in ipairs(spawns:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("SpawnPad") then
				return descendant.CFrame + Vector3.new(0, Config.Gameplay.BikeRespawnHeight, 0)
			end
		end
	end

	return CFrame.new(0, 8, 0)
end

function PurchaseService:SetBikeNetworkOwner(model, player)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			pcall(function()
				descendant:SetNetworkOwner(player)
			end)
		end
	end
end

function PurchaseService:CreateBikeModel(player, bikeId)
	local bike = BikeDefinitions[bikeId]
	local model = Instance.new("Model")
	model.Name = string.format("%s_%d", bikeId, player.UserId)
	model:SetAttribute("StreetLegalBike", true)
	model:SetAttribute("BikeId", bikeId)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("IllegalOnStreet", bike.IllegalOnStreet)
	model:SetAttribute("TopSpeedStuds", bike.TopSpeedStuds)
	model:SetAttribute("SpawnTime", now())

	local spawnCFrame = self:GetSpawnCFrame(player)
	local paint = bike.Paint or Color3.fromRGB(255, 255, 255)

	local hull = createPart(model, "Hull", Vector3.new(4.2, 1.2, 7), spawnCFrame, paint, Enum.Material.SmoothPlastic, 1)
	hull.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.8, 0.1, 1, 1)
	model.PrimaryPart = hull

	local frame = createPart(model, "Frame", Vector3.new(1.4, 1, 5), spawnCFrame * CFrame.new(0, 1.2, 0), paint, Enum.Material.Metal, 0)
	local tank = createPart(model, "Tank", Vector3.new(1.6, 1.4, 1.8), spawnCFrame * CFrame.new(0, 1.9, -0.2), paint, Enum.Material.SmoothPlastic, 0)
	local handle = createPart(model, "HandleBar", Vector3.new(3.2, 0.3, 0.3), spawnCFrame * CFrame.new(0, 2.35, -1.65), Color3.fromRGB(35, 35, 35), Enum.Material.Metal, 0)
	local rearWheel = createPart(model, "RearWheel", Vector3.new(2.4, 2.4, 0.8), spawnCFrame * CFrame.new(0, 1.1, 2.35) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(28, 28, 28), Enum.Material.Rubber, 0)
	local frontWheel = createPart(model, "FrontWheel", Vector3.new(2.2, 2.2, 0.7), spawnCFrame * CFrame.new(0, 1.1, -2.3) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(28, 28, 28), Enum.Material.Rubber, 0)
	rearWheel.Shape = Enum.PartType.Cylinder
	frontWheel.Shape = Enum.PartType.Cylinder
	local skidLeft = createPart(model, "SkidLeft", Vector3.new(0.6, 0.6, 3.5), spawnCFrame * CFrame.new(-1.5, 0.6, 0), paint, Enum.Material.SmoothPlastic, 1)
	local skidRight = createPart(model, "SkidRight", Vector3.new(0.6, 0.6, 3.5), spawnCFrame * CFrame.new(1.5, 0.6, 0), paint, Enum.Material.SmoothPlastic, 1)

	for _, part in ipairs({ frame, tank, handle, rearWheel, frontWheel, skidLeft, skidRight }) do
		createWeld(part, hull, part)
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.CFrame = spawnCFrame * CFrame.new(0, 2.2, 0.6)
	seat.Color = Color3.fromRGB(30, 30, 30)
	seat.Material = Enum.Material.SmoothPlastic
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.Parent = model
	createWeld(seat, hull, seat)

	local bodyAttachment = Instance.new("Attachment")
	bodyAttachment.Name = "BodyAttachment"
	bodyAttachment.Parent = hull

	local align = Instance.new("AlignOrientation")
	align.Name = "BodyAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = bodyAttachment
	align.Responsiveness = Config.Bike.Stability.Responsiveness
	align.MaxTorque = Config.Bike.Stability.MaxTorque
	align.RigidityEnabled = false
	align.ReactionTorqueEnabled = false
	align.CFrame = spawnCFrame
	align.Parent = hull

	local enginePitch = Instance.new("NumberValue")
	enginePitch.Name = "EnginePitch"
	enginePitch.Value = 1
	enginePitch.Parent = model

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if not occupant then
			player:SetAttribute("StreetLegalMounted", false)
			return
		end

		if player.Character and occupant.Parent == player.Character then
			player:SetAttribute("StreetLegalMounted", true)
		else
			occupant.Sit = false
		end
	end)

	local lastCollision = 0
	hull.Touched:Connect(function(hit)
		if not model.Parent then
			return
		end
		if player.Character and hit:IsDescendantOf(player.Character) then
			return
		end
		if hit:IsDescendantOf(model) then
			return
		end

		local speed = hull.AssemblyLinearVelocity.Magnitude
		local stamp = now()
		if speed >= 36 and stamp - lastCollision > 1 then
			lastCollision = stamp
			if self.WantedService then
				self.WantedService:AddHeat(player, "Collision")
			end
			hull.AssemblyLinearVelocity *= 0.62
		end
	end)

	model.Parent = self.BikesFolder
	self:SetBikeNetworkOwner(model, player)

	return model
end

function PurchaseService:DespawnBike(player)
	local active = self.ActiveBikes[player]
	if active and active.Parent then
		active:Destroy()
	end
	self.ActiveBikes[player] = nil
	player:SetAttribute("StreetLegalActiveBikeId", nil)
	player:SetAttribute("StreetLegalMounted", false)
	return true
end

function PurchaseService:SpawnBike(player, bikeId)
	if not BikeDefinitions[bikeId] then
		return { Success = false, Message = "Unknown bike." }
	end

	if not self.DataService:OwnsBike(player, bikeId) then
		return { Success = false, Message = "Bike not owned." }
	end

	self:DespawnBike(player)

	local model = self:CreateBikeModel(player, bikeId)
	self.ActiveBikes[player] = model
	player:SetAttribute("StreetLegalActiveBikeId", bikeId)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = model:FindFirstChild("Seat")
	if humanoid and seat then
		task.delay(0.15, function()
			if humanoid.Parent and seat.Parent then
				seat:Sit(humanoid)
			end
		end)
	end

	return {
		Success = true,
		Message = string.format("Spawned %s.", BikeDefinitions[bikeId].DisplayName),
		BikeId = bikeId,
	}
end

function PurchaseService:BuyBike(player, bikeId)
	local bike = BikeDefinitions[bikeId]
	if not bike then
		return { Success = false, Message = "Bike not found." }
	end

	if self.DataService:OwnsBike(player, bikeId) then
		return { Success = true, Message = "Bike already owned.", Snapshot = self.DataService:GetClientSnapshot(player) }
	end

	if bike.UnlockType == "Cash" then
		local ok, reason = self.DataService:SpendCash(player, bike.Price)
		if not ok then
			return { Success = false, Message = reason or "Purchase failed." }
		end
		self.DataService:GrantBike(player, bikeId)
		self.DataService:SetEquippedBike(player, bikeId)
		return { Success = true, Message = string.format("Purchased %s.", bike.DisplayName), Snapshot = self.DataService:GetClientSnapshot(player) }
	end

	if bike.UnlockType == "Gamepass" then
		if bike.GamePassId == 0 then
			return { Success = false, Message = "GamePassId placeholder is not configured yet." }
		end

		local ownsPass = false
		pcall(function()
			ownsPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, bike.GamePassId)
		end)

		if ownsPass then
			self.DataService:GrantBike(player, bikeId)
			self.DataService:SetEquippedBike(player, bikeId)
			return { Success = true, Message = string.format("Unlocked %s.", bike.DisplayName), Snapshot = self.DataService:GetClientSnapshot(player) }
		end

		MarketplaceService:PromptGamePassPurchase(player, bike.GamePassId)
		return { Success = false, Message = "Game pass prompt opened." }
	end

	return { Success = false, Message = "This bike is not purchasable." }
end

function PurchaseService:EquipBike(player, bikeId)
	if not BikeDefinitions[bikeId] then
		return { Success = false, Message = "Unknown bike." }
	end

	if not self.DataService:OwnsBike(player, bikeId) then
		return { Success = false, Message = "Bike not owned." }
	end

	self.DataService:SetEquippedBike(player, bikeId)
	return { Success = true, Message = string.format("Equipped %s.", BikeDefinitions[bikeId].DisplayName), Snapshot = self.DataService:GetClientSnapshot(player) }
end

function PurchaseService:HandleBikeAction(player, action, payload)
	payload = payload or {}
	local profile = self.DataService:GetProfile(player)
	if not profile then
		profile = self.DataService:LoadProfile(player)
	end
	player:SetAttribute("StreetLegalProfileReady", profile ~= nil)

	if action == "GetGarage" then
		return self:GetGarageState(player)
	elseif action == "BuyBike" then
		return self:BuyBike(player, payload.BikeId)
	elseif action == "EquipBike" then
		return self:EquipBike(player, payload.BikeId)
	elseif action == "SpawnBike" then
		local bikeId = payload.BikeId or profile.EquippedBikeId
		return self:SpawnBike(player, bikeId)
	elseif action == "DespawnBike" then
		self:DespawnBike(player)
		return { Success = true, Message = "Bike stored." }
	elseif action == "RespawnBike" then
		local bikeId = payload.BikeId or profile.EquippedBikeId
		return self:SpawnBike(player, bikeId)
	end

	return { Success = false, Message = "Unsupported action." }
end

return PurchaseService
