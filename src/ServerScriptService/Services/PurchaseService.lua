local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)
local BikeVisuals = require(ReplicatedStorage.Modules.BikeVisuals)
local SpawnUtil = require(script.Parent.SpawnUtil)

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

local function createPart(parent, className, name, size, cframe, color, material, options)
	local part = Instance.new(className or "Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color or Color3.fromRGB(255, 255, 255)
	part.Material = material or Enum.Material.Metal
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = options and options.CanCollide or false
	part.Anchored = false
	part.Transparency = options and options.Transparency or 0
	part.Massless = if options and options.Massless ~= nil then options.Massless else true
	part.CastShadow = if options and options.CastShadow ~= nil then options.CastShadow else true
	if part:IsA("Part") and options and options.Shape then
		part.Shape = options.Shape
	end
	part.Parent = parent
	return part
end

local function toWorldPosition(origin, localPosition)
	return (origin * CFrame.new(localPosition.X, localPosition.Y, localPosition.Z)).Position
end

local function createBeam(parent, rootPart, origin, name, localA, localB, thickness, color, material)
	local worldA = toWorldPosition(origin, localA)
	local worldB = toWorldPosition(origin, localB)
	local delta = worldB - worldA
	local length = delta.Magnitude
	if length <= 0.01 then
		return nil
	end

	local beam = createPart(
		parent,
		"Part",
		name,
		Vector3.new(thickness, thickness, length),
		CFrame.lookAt((worldA + worldB) * 0.5, worldB),
		color,
		material,
		{ CanCollide = false, Massless = true }
	)
	createWeld(beam, rootPart, beam)
	return beam
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
	}
	return payload
end

local function setPlayerBikeAttributes(player, activeBikeId)
	player:SetAttribute("StreetLegalActiveBikeId", activeBikeId)
	player:SetAttribute("StreetLegalMounted", false)
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

	local function initializePlayer(player)
		setPlayerBikeAttributes(player, nil)
	end

	Players.PlayerAdded:Connect(initializePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		initializePlayer(player)
	end

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

function PurchaseService:GetGarageState(player)
	return {
		Success = true,
		Catalog = self:GetCatalog(player),
		Snapshot = self.DataService:GetClientSnapshot(player),
		ActiveBikeId = player:GetAttribute("StreetLegalActiveBikeId"),
	}
end

function PurchaseService:GetSpawnCFrame(player, bikeId)
	local visual = BikeVisuals[bikeId] or BikeVisuals.default
	local geometry = visual.Geometry
	local groundOffset = math.max(
		(geometry.FrontWheelRadius or 1.1) - (geometry.FrontAxleY or 0.55),
		(geometry.RearWheelRadius or 1.1) - (geometry.RearAxleY or 0.55),
		0.6
	) + 0.05

	local character = player.Character
	if character and SpawnUtil:IsCharacterInEmergencyGarage(character) then
		local emergencyGarageCFrame = SpawnUtil:GetEmergencyBikeSpawnCFrame(groundOffset)
		if emergencyGarageCFrame then
			return emergencyGarageCFrame
		end
	end

	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local forward = rootPart.CFrame.LookVector
		local flatForward = Vector3.new(forward.X, 0, forward.Z)
		if flatForward.Magnitude < 0.001 then
			flatForward = Vector3.new(0, 0, -1)
		else
			flatForward = flatForward.Unit
		end

		local candidatePosition = rootPart.Position + (flatForward * Config.Gameplay.TeleportSpawnOffset)
		local grounded = SpawnUtil:ResolveGroundCFrame(
			candidatePosition,
			flatForward,
			{ character },
			Config.Gameplay.BikeRespawnHeight,
			72,
			groundOffset
		)
		if grounded then
			return grounded
		end
	end

	local spawnPad = SpawnUtil:ChooseSpawnPad(player)
	if spawnPad then
		local grounded = SpawnUtil:ResolveGroundCFrame(
			spawnPad.Position,
			spawnPad.CFrame.LookVector,
			{ spawnPad },
			16,
			72,
			groundOffset
		)
		if grounded then
			return grounded
		end
	end

	return CFrame.new(0, groundOffset + 4, 0)
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
	local visual = BikeVisuals[bikeId] or BikeVisuals.default
	local g = visual.Geometry
	local c = visual.Colors
	local paint = bike.Paint or c.Primary
	local spawnCFrame = self:GetSpawnCFrame(player, bikeId)

	local model = Instance.new("Model")
	model.Name = string.format("%s_%d", bikeId, player.UserId)
	model:SetAttribute("StreetLegalBike", true)
	model:SetAttribute("BikeId", bikeId)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("IllegalOnStreet", bike.IllegalOnStreet)
	model:SetAttribute("TopSpeedStuds", bike.TopSpeedStuds)
	model:SetAttribute("SpawnTime", now())

	local hull = createPart(
		model,
		"Part",
		"Hull",
		Vector3.new(2.0, 1.4, g.Wheelbase + 0.7),
		spawnCFrame * CFrame.new(0, 0.62, 0),
		paint,
		Enum.Material.SmoothPlastic,
		{ Transparency = 1, CanCollide = true, Massless = false, CastShadow = false }
	)
	hull.CustomPhysicalProperties = PhysicalProperties.new(1.15, 0.8, 0.1, 1, 1)
	model.PrimaryPart = hull

	local function decorPart(name, size, localPosition, color, material, options)
		local rotation = options and options.Rotation or Vector3.zero
		local cf = spawnCFrame
			* CFrame.new(localPosition.X, localPosition.Y, localPosition.Z)
			* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		local part = createPart(model, options and options.ClassName or "Part", name, size, cf, color, material, {
			CanCollide = false,
			Massless = true,
			Transparency = options and options.Transparency or 0,
			Shape = options and options.Shape or nil,
			CastShadow = options and options.CastShadow,
		})
		createWeld(part, hull, part)
		return part
	end

	local rearWheelZ = g.Wheelbase * 0.5
	local frontWheelZ = -g.Wheelbase * 0.5
	local rearWheel = decorPart(
		"RearWheel",
		Vector3.new(g.WheelThickness, g.RearWheelRadius * 2, g.RearWheelRadius * 2),
		Vector3.new(0, g.RearAxleY, rearWheelZ),
		Color3.fromRGB(26, 26, 26),
		Enum.Material.Rubber,
		{ Shape = Enum.PartType.Cylinder }
	)
	local frontWheel = decorPart(
		"FrontWheel",
		Vector3.new(g.WheelThickness, g.FrontWheelRadius * 2, g.FrontWheelRadius * 2),
		Vector3.new(0, g.FrontAxleY, frontWheelZ),
		Color3.fromRGB(26, 26, 26),
		Enum.Material.Rubber,
		{ Shape = Enum.PartType.Cylinder }
	)
	decorPart(
		"RearRim",
		Vector3.new(g.WheelThickness * 0.55, g.RearWheelRadius * 1.42, g.RearWheelRadius * 1.42),
		Vector3.new(0, g.RearAxleY, rearWheelZ),
		c.Rim,
		Enum.Material.Metal,
		{ Shape = Enum.PartType.Cylinder }
	)
	decorPart(
		"FrontRim",
		Vector3.new(g.WheelThickness * 0.55, g.FrontWheelRadius * 1.42, g.FrontWheelRadius * 1.42),
		Vector3.new(0, g.FrontAxleY, frontWheelZ),
		c.Rim,
		Enum.Material.Metal,
		{ Shape = Enum.PartType.Cylinder }
	)
	decorPart(
		"RearHub",
		Vector3.new(g.WheelThickness * 0.42, g.RearWheelRadius * 0.42, g.RearWheelRadius * 0.42),
		Vector3.new(0, g.RearAxleY, rearWheelZ),
		c.Trim,
		Enum.Material.Metal,
		{ Shape = Enum.PartType.Cylinder }
	)
	decorPart(
		"FrontHub",
		Vector3.new(g.WheelThickness * 0.42, g.FrontWheelRadius * 0.42, g.FrontWheelRadius * 0.42),
		Vector3.new(0, g.FrontAxleY, frontWheelZ),
		c.Trim,
		Enum.Material.Metal,
		{ Shape = Enum.PartType.Cylinder }
	)

	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(1.2, 0.42, g.SeatLength)
	seat.CFrame = spawnCFrame * CFrame.new(0, g.SeatHeight, g.SeatZ)
	seat.Color = c.Seat
	seat.Material = Enum.Material.SmoothPlastic
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.CanCollide = true
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.Parent = model
	createWeld(seat, hull, seat)

	decorPart("BatteryBox", g.BatterySize, Vector3.new(0, g.BatteryY, g.BatteryZ), c.Battery, Enum.Material.SmoothPlastic)
	decorPart("BatteryCap", Vector3.new(g.BatterySize.X * 0.88, 0.16, g.BatterySize.Z * 0.78), Vector3.new(0, g.BatteryY + (g.BatterySize.Y * 0.5) + 0.06, g.BatteryZ - 0.08), c.Trim, Enum.Material.Metal)
	decorPart("Controller", Vector3.new(0.62, 0.26, 0.62), Vector3.new(0, g.BatteryY + 0.88, g.BatteryZ + 0.36), c.Trim, Enum.Material.Metal)
	decorPart("Motor", Vector3.new(0.96, 0.66, 0.88), Vector3.new(0, g.MotorY, g.MotorZ), c.Trim, Enum.Material.Metal)
	decorPart("FrontPlate", Vector3.new(0.92, 1.02, 0.12), Vector3.new(0, g.HeadTubeY + 0.02, g.HeadTubeZ - 0.56), c.Accent, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(g.HeadTubeTilt, 0, 0),
	})
	decorPart("Headlight", Vector3.new(0.46, 0.24, 0.08), Vector3.new(0, g.HeadTubeY + 0.06, g.HeadTubeZ - 0.64), c.Headlight, Enum.Material.Neon, {
		Rotation = Vector3.new(g.HeadTubeTilt, 0, 0),
	})
	decorPart("TailLight", Vector3.new(0.34, 0.1, 0.14), Vector3.new(0, g.RearFenderY + 0.04, g.RearFenderZ + 0.52), c.Taillight, Enum.Material.Neon)

	decorPart("TopShroud", Vector3.new(1.02, 0.22, 1.08), Vector3.new(0, g.BatteryY + 0.78, g.BatteryZ - 0.46), paint, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(-14, 0, 0),
	})
	decorPart("FrontFender", Vector3.new(0.62, 0.14, 1.62), Vector3.new(0, g.FrontFenderY, g.FrontFenderZ), paint, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(g.FrontFenderPitch, 0, 0),
	})
	decorPart("RearFender", Vector3.new(0.72, 0.16, 1.46), Vector3.new(0, g.RearFenderY, g.RearFenderZ), c.Accent, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(g.RearFenderPitch, 0, 0),
	})
	decorPart("ChainGuard", Vector3.new(0.18, 0.22, 1.36), Vector3.new(0.56, g.RearAxleY + 0.22, rearWheelZ - 0.58), c.Trim, Enum.Material.Metal, {
		Rotation = Vector3.new(4, 0, -6),
	})
	decorPart("SkidPlate", Vector3.new(0.9, 0.14, 1.12), Vector3.new(0, g.MotorY - 0.5, g.MotorZ + 0.08), c.Frame, Enum.Material.Metal, {
		Rotation = Vector3.new(7, 0, 0),
	})
	decorPart("StemBlock", Vector3.new(0.54, 0.44, 0.4), Vector3.new(0, g.HeadTubeY + 0.36, g.HeadTubeZ - 0.08), c.Frame, Enum.Material.Metal, {
		Rotation = Vector3.new(g.HeadTubeTilt, 0, 0),
	})
	decorPart("HandleBar", Vector3.new(g.HandleWidth, 0.16, 0.16), Vector3.new(0, g.HandleY, g.HandleZ), c.Trim, Enum.Material.Metal)
	decorPart("GripLeft", Vector3.new(0.22, 0.18, 0.42), Vector3.new(-(g.HandleWidth * 0.5) - 0.08, g.HandleY, g.HandleZ), Color3.fromRGB(18, 18, 18), Enum.Material.Rubber)
	decorPart("GripRight", Vector3.new(0.22, 0.18, 0.42), Vector3.new((g.HandleWidth * 0.5) + 0.08, g.HandleY, g.HandleZ), Color3.fromRGB(18, 18, 18), Enum.Material.Rubber)
	decorPart("SidePlateLeft", Vector3.new(0.08, 0.76, 1.06), Vector3.new(-(g.BatterySize.X * 0.5) - 0.1, g.BatteryY + 0.1, g.BatteryZ - 0.06), paint, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(0, 8, 0),
	})
	decorPart("SidePlateRight", Vector3.new(0.08, 0.76, 1.06), Vector3.new((g.BatterySize.X * 0.5) + 0.1, g.BatteryY + 0.1, g.BatteryZ - 0.06), paint, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(0, -8, 0),
	})
	decorPart("SeatCowl", Vector3.new(0.9, 0.18, 1.12), Vector3.new(0, g.SeatHeight + 0.1, g.SeatZ + (g.SeatLength * 0.24)), c.Accent, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(-4, 0, 0),
	})
	decorPart("ForkGuardLeft", Vector3.new(0.16, 0.82, 0.28), Vector3.new(-(g.ForkSpread * 0.5), g.FrontAxleY + 0.56, frontWheelZ + 0.14), paint, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(-10, 0, 0),
	})
	decorPart("ForkGuardRight", Vector3.new(0.16, 0.82, 0.28), Vector3.new((g.ForkSpread * 0.5), g.FrontAxleY + 0.56, frontWheelZ + 0.14), paint, Enum.Material.SmoothPlastic, {
		Rotation = Vector3.new(-10, 0, 0),
	})
	decorPart("RearDisc", Vector3.new(0.08, g.RearWheelRadius * 0.74, g.RearWheelRadius * 0.74), Vector3.new(0.21, g.RearAxleY, rearWheelZ), c.Trim, Enum.Material.Metal, {
		Shape = Enum.PartType.Cylinder,
	})
	decorPart("FrontDisc", Vector3.new(0.08, g.FrontWheelRadius * 0.82, g.FrontWheelRadius * 0.82), Vector3.new(0.21, g.FrontAxleY, frontWheelZ), c.Trim, Enum.Material.Metal, {
		Shape = Enum.PartType.Cylinder,
	})
	decorPart("PegLeft", Vector3.new(0.6, 0.1, 0.18), Vector3.new(-0.62, g.MotorY + 0.06, g.MotorZ + 0.38), c.Trim, Enum.Material.Metal)
	decorPart("PegRight", Vector3.new(0.6, 0.1, 0.18), Vector3.new(0.62, g.MotorY + 0.06, g.MotorZ + 0.38), c.Trim, Enum.Material.Metal)
	decorPart("RearBrace", Vector3.new(0.18, 0.68, 0.18), Vector3.new(0, g.SeatHeight - 0.1, g.SeatZ + (g.SeatLength * 0.5) - 0.18), c.Trim, Enum.Material.Metal, {
		Rotation = Vector3.new(-20, 0, 0),
	})
	decorPart("LowerBatteryGuard", Vector3.new(g.BatterySize.X + 0.18, 0.14, 0.92), Vector3.new(0, g.BatteryY - (g.BatterySize.Y * 0.48), g.BatteryZ + 0.18), c.Frame, Enum.Material.Metal)
	decorPart("ChargePortCap", Vector3.new(0.14, 0.18, 0.18), Vector3.new((g.BatterySize.X * 0.5) + 0.12, g.BatteryY + 0.2, g.BatteryZ + 0.24), c.Accent, Enum.Material.Neon)

	local frameWidth = g.FrameWidth
	local forkHalf = g.ForkSpread * 0.5
	createBeam(model, hull, spawnCFrame, "TopRailLeft", Vector3.new(frameWidth, g.SeatHeight - 0.1, g.SeatZ - (g.SeatLength * 0.5) + 0.1), Vector3.new(frameWidth * 0.7, g.HeadTubeY + 0.34, g.HeadTubeZ + 0.12), 0.16, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "TopRailRight", Vector3.new(-frameWidth, g.SeatHeight - 0.1, g.SeatZ - (g.SeatLength * 0.5) + 0.1), Vector3.new(-frameWidth * 0.7, g.HeadTubeY + 0.34, g.HeadTubeZ + 0.12), 0.16, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "DownTubeLeft", Vector3.new(frameWidth * 0.72, g.HeadTubeY - 0.22, g.HeadTubeZ + 0.02), Vector3.new(frameWidth * 0.52, g.MotorY + 0.12, g.MotorZ + 0.16), 0.17, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "DownTubeRight", Vector3.new(-frameWidth * 0.72, g.HeadTubeY - 0.22, g.HeadTubeZ + 0.02), Vector3.new(-frameWidth * 0.52, g.MotorY + 0.12, g.MotorZ + 0.16), 0.17, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "LowerRailLeft", Vector3.new(frameWidth * 0.55, g.MotorY - 0.16, g.MotorZ + 0.52), Vector3.new(frameWidth * 0.72, g.RearAxleY + 0.16, rearWheelZ - 0.52), 0.17, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "LowerRailRight", Vector3.new(-frameWidth * 0.55, g.MotorY - 0.16, g.MotorZ + 0.52), Vector3.new(-frameWidth * 0.72, g.RearAxleY + 0.16, rearWheelZ - 0.52), 0.17, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "SeatStayLeft", Vector3.new(frameWidth, g.SeatHeight - 0.22, g.SeatZ + (g.SeatLength * 0.5) - 0.1), Vector3.new(frameWidth * 0.9, g.RearAxleY + 0.4, rearWheelZ - 0.12), 0.15, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "SeatStayRight", Vector3.new(-frameWidth, g.SeatHeight - 0.22, g.SeatZ + (g.SeatLength * 0.5) - 0.1), Vector3.new(-frameWidth * 0.9, g.RearAxleY + 0.4, rearWheelZ - 0.12), 0.15, c.Frame, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "SwingArmLeft", Vector3.new(frameWidth + 0.2, g.MotorY - 0.22, g.MotorZ + 0.72), Vector3.new(frameWidth + 0.26, g.RearAxleY + 0.06, rearWheelZ), 0.22, c.Trim, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "SwingArmRight", Vector3.new(-(frameWidth + 0.2), g.MotorY - 0.22, g.MotorZ + 0.72), Vector3.new(-(frameWidth + 0.26), g.RearAxleY + 0.06, rearWheelZ), 0.22, c.Trim, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "ForkLeft", Vector3.new(-forkHalf, g.HeadTubeY - 0.08, g.HeadTubeZ - 0.1), Vector3.new(-forkHalf, g.FrontAxleY + 0.04, frontWheelZ + 0.06), 0.16, c.Fork, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "ForkRight", Vector3.new(forkHalf, g.HeadTubeY - 0.08, g.HeadTubeZ - 0.1), Vector3.new(forkHalf, g.FrontAxleY + 0.04, frontWheelZ + 0.06), 0.16, c.Fork, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "ForkBrace", Vector3.new(-forkHalf, g.FrontAxleY + 0.5, frontWheelZ + 0.18), Vector3.new(forkHalf, g.FrontAxleY + 0.5, frontWheelZ + 0.18), 0.18, c.Trim, Enum.Material.Metal)
	createBeam(model, hull, spawnCFrame, "RearShock", Vector3.new(0, g.SeatHeight - 0.25, g.SeatZ + 0.2), Vector3.new(0, g.RearAxleY + 0.44, rearWheelZ - 0.56), 0.14, c.Accent, Enum.Material.Metal)

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
	setPlayerBikeAttributes(player, nil)
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
		Snapshot = self.DataService:GetClientSnapshot(player),
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

	if bike.UnlockType == "Free" then
		self.DataService:GrantBike(player, bikeId)
		self.DataService:SetEquippedBike(player, bikeId)
		return { Success = true, Message = string.format("Unlocked %s.", bike.DisplayName), Snapshot = self.DataService:GetClientSnapshot(player) }
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

function PurchaseService:EquipAndSpawnBike(player, bikeId)
	local bike = BikeDefinitions[bikeId]
	if not bike then
		return { Success = false, Message = "Unknown bike." }
	end

	if not self.DataService:OwnsBike(player, bikeId) then
		if bike.UnlockType == "Free" then
			self.DataService:GrantBike(player, bikeId)
		else
			return { Success = false, Message = "Bike not owned." }
		end
	end

	self.DataService:SetEquippedBike(player, bikeId)
	return self:SpawnBike(player, bikeId)
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
	elseif action == "EquipAndSpawnBike" then
		return self:EquipAndSpawnBike(player, payload.BikeId)
	elseif action == "SpawnBike" then
		local bikeId = payload.BikeId or profile.EquippedBikeId
		return self:SpawnBike(player, bikeId)
	elseif action == "DespawnBike" or action == "StoreBike" then
		self:DespawnBike(player)
		return { Success = true, Message = "Bike stored.", Snapshot = self.DataService:GetClientSnapshot(player) }
	elseif action == "RespawnBike" then
		local bikeId = payload.BikeId or profile.EquippedBikeId
		return self:SpawnBike(player, bikeId)
	end

	return { Success = false, Message = "Unsupported action." }
end

return PurchaseService
