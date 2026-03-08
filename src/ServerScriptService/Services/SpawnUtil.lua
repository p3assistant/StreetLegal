local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local SpawnData = require(Workspace.Spawns.SpawnData)

local SpawnUtil = {}

local DEFAULT_LOOK = Vector3.new(0, 0, -1)
local EMERGENCY_FOLDER_NAME = "SafeSpawnArea"
local EMERGENCY_PLATFORM_NAME = "SafeSpawnFloor"
local EMERGENCY_LOCATION_NAME = "SafeSpawnLocation"
local EMERGENCY_FOOT_MARKER_NAME = "SafeSpawnFootAnchor"
local EMERGENCY_BIKE_MARKER_NAME = "SafeSpawnBikeAnchor"
local EMERGENCY_ZONE_NAME = "SafeSpawnGarageZone"
local EMERGENCY_GARAGE_CFRAME = CFrame.new(252, 0.3, 820) * CFrame.Angles(0, math.rad(90), 0)
local EMERGENCY_GARAGE_FLOOR_SIZE = Vector3.new(32, 0.6, 34)
local EMERGENCY_EXIT_LANE_SIZE = Vector3.new(18, 0.6, 40)
local EMERGENCY_GARAGE_ZONE_SIZE = Vector3.new(26, 10, 30)

local function flattenLookVector(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.001 then
		return DEFAULT_LOOK
	end
	return flat.Unit
end

local function cloneArray(array)
	local clone = {}
	for _, item in ipairs(array or {}) do
		table.insert(clone, item)
	end
	return clone
end

local function appendUnique(array, item)
	if not item then
		return
	end

	for _, existing in ipairs(array) do
		if existing == item then
			return
		end
	end

	table.insert(array, item)
end

local function createOrUpdatePart(parent, className, name, size, cframe, color, material, transparency, canCollide)
	local instance = parent:FindFirstChild(name)
	if not instance or not instance:IsA(className) then
		if instance then
			instance:Destroy()
		end
		instance = Instance.new(className)
		instance.Name = name
		instance.Parent = parent
	end

	instance.Anchored = true
	instance.Size = size
	instance.CFrame = cframe
	instance.Color = color
	instance.Material = material
	instance.Transparency = transparency or 0
	instance.CanCollide = canCollide ~= false
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	instance.CastShadow = true
	instance:SetAttribute("EmergencySpawn", true)

	return instance
end

local function setSurfaceAttributes(part, district, surfaceType)
	part:SetAttribute("District", district)
	part:SetAttribute("SurfaceType", surfaceType)
	return part
end

local function attachSurfaceLabel(part, text, color)
	if not part then
		return
	end

	local gui = part:FindFirstChild("Label")
	if not gui or not gui:IsA("SurfaceGui") then
		if gui then
			gui:Destroy()
		end
		gui = Instance.new("SurfaceGui")
		gui.Name = "Label"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.AlwaysOnTop = false
		gui.Parent = part
	end

	local label = gui:FindFirstChild("Text")
	if not label or not label:IsA("TextLabel") then
		if label then
			label:Destroy()
		end
		label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = gui
	end

	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(245, 245, 245)
end

local function pointInsidePart(part, point)
	if not part or not part:IsA("BasePart") then
		return false
	end

	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size * 0.5
	return math.abs(localPoint.X) <= half.X
		and math.abs(localPoint.Y) <= half.Y
		and math.abs(localPoint.Z) <= half.Z
end

function SpawnUtil:WaitForWorldReady(timeoutSeconds)
	local startedAt = os.clock()
	while Workspace:GetAttribute("StreetLegalWorldReady") ~= true do
		if timeoutSeconds and (os.clock() - startedAt) >= timeoutSeconds then
			return false
		end
		task.wait(0.1)
	end
	return true
end

function SpawnUtil:GetCharacterSurfaceOffset(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return ((humanoid and humanoid.HipHeight) or 2) + ((rootPart and rootPart.Size.Y) or 2) * 0.5 + 0.25
end

function SpawnUtil:EnsureEmergencySpawnArea()
	local spawnsFolder = Workspace:FindFirstChild("Spawns") or Workspace:WaitForChild("Spawns")
	local safeFolder = spawnsFolder:FindFirstChild(EMERGENCY_FOLDER_NAME)
	if not safeFolder then
		safeFolder = Instance.new("Folder")
		safeFolder.Name = EMERGENCY_FOLDER_NAME
		safeFolder.Parent = spawnsFolder
	end

	local floor = setSurfaceAttributes(createOrUpdatePart(
		safeFolder,
		"Part",
		EMERGENCY_PLATFORM_NAME,
		EMERGENCY_GARAGE_FLOOR_SIZE,
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, EMERGENCY_GARAGE_FLOOR_SIZE.Y * 0.5, 5),
		Color3.fromRGB(72, 75, 81),
		Enum.Material.Concrete,
		0,
		true
	), "SafeSpawn", "Street")

	local exitLane = setSurfaceAttributes(createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnExitLane",
		EMERGENCY_EXIT_LANE_SIZE,
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, EMERGENCY_EXIT_LANE_SIZE.Y * 0.5, -31),
		Color3.fromRGB(50, 53, 58),
		Enum.Material.Asphalt,
		0,
		true
	), "SafeSpawn", "Street")
	setSurfaceAttributes(createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnLaneStripe",
		Vector3.new(0.6, 0.05, 24),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 0.64, -31),
		Color3.fromRGB(255, 208, 94),
		Enum.Material.Neon,
		0,
		false
	), "SafeSpawn", "Street")
	setSurfaceAttributes(createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnLaneEdgeLeft",
		Vector3.new(0.25, 0.04, 34),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(-8.85, 0.63, -28),
		Color3.fromRGB(214, 214, 214),
		Enum.Material.SmoothPlastic,
		0,
		false
	), "SafeSpawn", "Street")
	setSurfaceAttributes(createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnLaneEdgeRight",
		Vector3.new(0.25, 0.04, 34),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(8.85, 0.63, -28),
		Color3.fromRGB(214, 214, 214),
		Enum.Material.SmoothPlastic,
		0,
		false
	), "SafeSpawn", "Street")

	setSurfaceAttributes(createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnThreshold",
		Vector3.new(18, 0.2, 3),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 0.72, -11),
		Color3.fromRGB(255, 196, 88),
		Enum.Material.Neon,
		0.2,
		false
	), "SafeSpawn", "Street")

	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnBackWall",
		Vector3.new(32, 10, 2),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 5.6, 20),
		Color3.fromRGB(59, 63, 72),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnWallLeft",
		Vector3.new(2, 10, 30),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(-15, 5.6, 4),
		Color3.fromRGB(66, 70, 79),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnWallRight",
		Vector3.new(2, 10, 30),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(15, 5.6, 4),
		Color3.fromRGB(66, 70, 79),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnFrontHeader",
		Vector3.new(24, 3, 2),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 8.1, -11),
		Color3.fromRGB(88, 96, 108),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnColumnLeft",
		Vector3.new(2, 7.2, 2),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(-11, 4.2, -11),
		Color3.fromRGB(88, 96, 108),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnColumnRight",
		Vector3.new(2, 7.2, 2),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(11, 4.2, -11),
		Color3.fromRGB(88, 96, 108),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnRoof",
		Vector3.new(34, 1.2, 36),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 10.6, 3),
		Color3.fromRGB(42, 45, 51),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnRoofTrim",
		Vector3.new(24, 0.4, 1),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 9.75, -12.1),
		Color3.fromRGB(255, 170, 60),
		Enum.Material.Neon,
		0,
		false
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnCeilingLight",
		Vector3.new(12, 0.25, 2.2),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 9.85, 4),
		Color3.fromRGB(255, 236, 189),
		Enum.Material.Neon,
		0,
		false
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnSignBacker",
		Vector3.new(16, 3.6, 0.6),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 8.2, 18.7),
		Color3.fromRGB(28, 31, 36),
		Enum.Material.Metal,
		0,
		true
	)
	local sign = createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnSign",
		Vector3.new(14, 2.6, 0.2),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 8.2, 18),
		Color3.fromRGB(110, 214, 240),
		Enum.Material.Neon,
		0,
		false
	)
	attachSurfaceLabel(sign, "SAFE BAY", Color3.fromRGB(19, 27, 34))
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SafeSpawnWheelStop",
		Vector3.new(18, 0.8, 1.4),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 1, 15.5),
		Color3.fromRGB(96, 103, 114),
		Enum.Material.Concrete,
		0,
		true
	)

	local footAnchor = createOrUpdatePart(
		safeFolder,
		"Part",
		EMERGENCY_FOOT_MARKER_NAME,
		Vector3.new(1, 1, 1),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 0.6, 8),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		1,
		false
	)
	footAnchor.CastShadow = false

	local bikeAnchor = createOrUpdatePart(
		safeFolder,
		"Part",
		EMERGENCY_BIKE_MARKER_NAME,
		Vector3.new(1, 1, 1),
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 0.6, -6),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		1,
		false
	)
	bikeAnchor.CastShadow = false

	local zone = createOrUpdatePart(
		safeFolder,
		"Part",
		EMERGENCY_ZONE_NAME,
		EMERGENCY_GARAGE_ZONE_SIZE,
		EMERGENCY_GARAGE_CFRAME * CFrame.new(0, 5, 5),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		1,
		false
	)
	zone.CastShadow = false

	local spawnLocation = safeFolder:FindFirstChild(EMERGENCY_LOCATION_NAME)
	if not spawnLocation or not spawnLocation:IsA("SpawnLocation") then
		if spawnLocation then
			spawnLocation:Destroy()
		end
		spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = EMERGENCY_LOCATION_NAME
		spawnLocation.Parent = safeFolder
	end

	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(14, 0.2, 14)
	spawnLocation.CFrame = footAnchor.CFrame * CFrame.new(0, 0.11, 0)
	spawnLocation.Transparency = 0.92
	spawnLocation.Color = Color3.fromRGB(110, 214, 240)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Neutral = true
	spawnLocation.CanCollide = false
	spawnLocation.Enabled = true
	spawnLocation:SetAttribute("EmergencySpawn", true)
	spawnLocation:SetAttribute("District", "SafeSpawn")
	spawnLocation:SetAttribute("SurfaceType", "Street")

	return safeFolder, floor, spawnLocation
end

function SpawnUtil:GetEmergencySpawnLocation()
	local _, _, spawnLocation = self:EnsureEmergencySpawnArea()
	return spawnLocation
end

function SpawnUtil:GetEmergencySpawnCFrame(character, lookVector)
	local safeFolder, floor = self:EnsureEmergencySpawnArea()
	local footAnchor = safeFolder:FindFirstChild(EMERGENCY_FOOT_MARKER_NAME)
	local surfaceOffset = self:GetCharacterSurfaceOffset(character)
	local basePosition = (footAnchor and footAnchor.Position) or (floor.Position + Vector3.new(0, floor.Size.Y * 0.5, 0))
	local flatLook = flattenLookVector(lookVector or (footAnchor and footAnchor.CFrame.LookVector) or floor.CFrame.LookVector)
	local spawnPosition = basePosition + Vector3.new(0, surfaceOffset, 0)
	return CFrame.lookAt(spawnPosition, spawnPosition + flatLook, Vector3.yAxis), floor
end

function SpawnUtil:GetEmergencyBikeSpawnCFrame(groundOffset)
	local safeFolder, floor = self:EnsureEmergencySpawnArea()
	local bikeAnchor = safeFolder:FindFirstChild(EMERGENCY_BIKE_MARKER_NAME)
	local zone = safeFolder:FindFirstChild(EMERGENCY_ZONE_NAME)
	local footAnchor = safeFolder:FindFirstChild(EMERGENCY_FOOT_MARKER_NAME)
	local spawnLocation = safeFolder:FindFirstChild(EMERGENCY_LOCATION_NAME)
	local anchorPosition = (bikeAnchor and bikeAnchor.Position) or (floor.Position + Vector3.new(0, floor.Size.Y * 0.5, 0))
	local lookVector = flattenLookVector((bikeAnchor and bikeAnchor.CFrame.LookVector) or floor.CFrame.LookVector)
	local resolved = self:ResolveGroundCFrame(anchorPosition, lookVector, {
		bikeAnchor,
		zone,
		footAnchor,
		spawnLocation,
	}, 8, 28, groundOffset)
	if resolved then
		return resolved, floor
	end

	local spawnPosition = anchorPosition + Vector3.new(0, groundOffset or 0, 0)
	return CFrame.lookAt(spawnPosition, spawnPosition + lookVector, Vector3.yAxis), floor
end

function SpawnUtil:IsCharacterInEmergencyGarage(character)
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local safeFolder = self:EnsureEmergencySpawnArea()
	local zone = safeFolder and safeFolder:FindFirstChild(EMERGENCY_ZONE_NAME)
	return pointInsidePart(zone, rootPart.Position)
end

function SpawnUtil:GetSpawnPads()
	local spawnsFolder = Workspace:FindFirstChild("Spawns")
	if not spawnsFolder then
		return {}
	end

	local pads = {}
	for _, descendant in ipairs(spawnsFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("SpawnPad") then
			table.insert(pads, descendant)
		end
	end

	table.sort(pads, function(a, b)
		return a.Name < b.Name
	end)

	return pads
end

function SpawnUtil:ChooseSpawnPad(player)
	local pads = self:GetSpawnPads()
	if #pads == 0 then
		return nil
	end

	local index = ((player and player.UserId or 0) % #pads) + 1
	return pads[index]
end

function SpawnUtil:RaycastToGround(position, ignoreInstances, searchHeight, searchDepth)
	local filter = cloneArray(ignoreInstances)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local height = searchHeight or 72
	local depth = searchDepth or 180
	local origin = position + Vector3.new(0, height, 0)
	local direction = Vector3.new(0, -(height + depth), 0)

	for _ = 1, 12 do
		params.FilterDescendantsInstances = filter
		local result = Workspace:Raycast(origin, direction, params)
		if not result then
			return nil
		end

		if result.Instance and result.Instance.CanCollide then
			return result
		end

		appendUnique(filter, result.Instance)
	end

	return nil
end

function SpawnUtil:ResolveGroundCFrame(position, lookVector, ignoreInstances, searchHeight, searchDepth, surfaceOffset)
	local result = self:RaycastToGround(position, ignoreInstances, searchHeight, searchDepth)
	if not result then
		return nil, nil
	end

	local groundedPosition = Vector3.new(position.X, result.Position.Y + (surfaceOffset or 0), position.Z)
	local flatLook = flattenLookVector(lookVector or DEFAULT_LOOK)
	return CFrame.lookAt(groundedPosition, groundedPosition + flatLook, Vector3.yAxis), result
end

function SpawnUtil:IsCharacterGrounded(character, maxDrop)
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false, nil
	end

	local result = self:RaycastToGround(rootPart.Position, { character }, 3, maxDrop or 10)
	if not result then
		return false, nil
	end

	return (rootPart.Position.Y - result.Position.Y) <= ((maxDrop or 10) + 0.25), result
end

function SpawnUtil:GetFallbackSpawnDefinition(player)
	if #SpawnData == 0 then
		return nil
	end

	local index = ((player and player.UserId or 0) % #SpawnData) + 1
	return SpawnData[index]
end

function SpawnUtil:GetPoliceStationSpawnCFrame(character)
	local stationMarker = Workspace:FindFirstChild("Police") and Workspace.Police:FindFirstChild("StationMarker")
	local position = (stationMarker and stationMarker.Position) or Config.World.PoliceStationPosition
	local surfaceOffset = self:GetCharacterSurfaceOffset(character)
	local grounded = self:ResolveGroundCFrame(position, DEFAULT_LOOK, { character, stationMarker }, 36, 140, surfaceOffset)
	if grounded then
		return grounded, stationMarker
	end

	return self:GetEmergencySpawnCFrame(character, DEFAULT_LOOK)
end

function SpawnUtil:GetPlacementCandidates(player, character)
	local surfaceOffset = self:GetCharacterSurfaceOffset(character)
	local candidates = {}
	local function pushCandidate(cframe, source)
		if cframe then
			table.insert(candidates, {
				CFrame = cframe,
				Source = source,
			})
		end
	end

	local pad = self:ChooseSpawnPad(player)
	if pad then
		local resolved = self:ResolveGroundCFrame(pad.Position, pad.CFrame.LookVector, { character, pad }, 32, 120, surfaceOffset)
		pushCandidate(resolved, string.format("spawn pad %s", pad.Name))
	end

	local fallback = self:GetFallbackSpawnDefinition(player)
	if fallback then
		local fallbackPosition = Vector3.new(fallback.Position.X, Config.World.StreetY, fallback.Position.Z)
		local resolved = self:ResolveGroundCFrame(fallbackPosition, DEFAULT_LOOK, { character }, 32, 120, surfaceOffset)
		pushCandidate(resolved, string.format("fallback lot %s", fallback.Name))
	end

	local policeStationCFrame = self:GetPoliceStationSpawnCFrame(character)
	pushCandidate(policeStationCFrame, "police station ground fallback")

	local emergencyCFrame = self:GetEmergencySpawnCFrame(character, DEFAULT_LOOK)
	pushCandidate(emergencyCFrame, "emergency safe spawn")

	return candidates
end

function SpawnUtil:GetCharacterSpawnCFrame(player, character)
	local candidates = self:GetPlacementCandidates(player, character)
	if candidates[1] then
		return candidates[1].CFrame, candidates[1].Source
	end

	return self:GetEmergencySpawnCFrame(character, DEFAULT_LOOK)
end

return SpawnUtil
