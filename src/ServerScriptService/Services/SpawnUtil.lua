local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local SpawnData = require(Workspace.Spawns.SpawnData)

local SpawnUtil = {}

local DEFAULT_LOOK = Vector3.new(0, 0, -1)
local EMERGENCY_FOLDER_NAME = "SafeSpawnArea"
local EMERGENCY_PLATFORM_NAME = "SafeSpawnPlatform"
local EMERGENCY_LOCATION_NAME = "SafeSpawnLocation"
local EMERGENCY_PLATFORM_CFRAME = CFrame.new(0, 14, 860) * CFrame.Angles(0, math.rad(180), 0)
local EMERGENCY_PLATFORM_SIZE = Vector3.new(96, 8, 96)

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

	local platform = createOrUpdatePart(
		safeFolder,
		"Part",
		EMERGENCY_PLATFORM_NAME,
		EMERGENCY_PLATFORM_SIZE,
		EMERGENCY_PLATFORM_CFRAME,
		Color3.fromRGB(92, 96, 108),
		Enum.Material.Concrete,
		0,
		true
	)
	platform:SetAttribute("SurfaceType", "Street")
	platform:SetAttribute("District", "SafeSpawn")

	local wallHeight = 12
	local wallThickness = 4
	local halfX = (EMERGENCY_PLATFORM_SIZE.X * 0.5) - (wallThickness * 0.5)
	local halfZ = (EMERGENCY_PLATFORM_SIZE.Z * 0.5) - (wallThickness * 0.5)
	local wallY = (EMERGENCY_PLATFORM_SIZE.Y * 0.5) + (wallHeight * 0.5)

	createOrUpdatePart(
		safeFolder,
		"Part",
		"NorthBarrier",
		Vector3.new(EMERGENCY_PLATFORM_SIZE.X, wallHeight, wallThickness),
		EMERGENCY_PLATFORM_CFRAME * CFrame.new(0, wallY, -halfZ),
		Color3.fromRGB(63, 67, 76),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"SouthBarrier",
		Vector3.new(EMERGENCY_PLATFORM_SIZE.X, wallHeight, wallThickness),
		EMERGENCY_PLATFORM_CFRAME * CFrame.new(0, wallY, halfZ),
		Color3.fromRGB(63, 67, 76),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"WestBarrier",
		Vector3.new(wallThickness, wallHeight, EMERGENCY_PLATFORM_SIZE.Z),
		EMERGENCY_PLATFORM_CFRAME * CFrame.new(-halfX, wallY, 0),
		Color3.fromRGB(63, 67, 76),
		Enum.Material.Metal,
		0,
		true
	)
	createOrUpdatePart(
		safeFolder,
		"Part",
		"EastBarrier",
		Vector3.new(wallThickness, wallHeight, EMERGENCY_PLATFORM_SIZE.Z),
		EMERGENCY_PLATFORM_CFRAME * CFrame.new(halfX, wallY, 0),
		Color3.fromRGB(63, 67, 76),
		Enum.Material.Metal,
		0,
		true
	)

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
	spawnLocation.Size = Vector3.new(18, 0.2, 18)
	spawnLocation.CFrame = EMERGENCY_PLATFORM_CFRAME * CFrame.new(0, (EMERGENCY_PLATFORM_SIZE.Y * 0.5) + 0.11, 0)
	spawnLocation.Transparency = 0.9
	spawnLocation.Color = Color3.fromRGB(110, 214, 240)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Neutral = true
	spawnLocation.CanCollide = false
	spawnLocation.Enabled = true
	spawnLocation:SetAttribute("EmergencySpawn", true)

	return safeFolder, platform, spawnLocation
end

function SpawnUtil:GetEmergencySpawnLocation()
	local _, _, spawnLocation = self:EnsureEmergencySpawnArea()
	return spawnLocation
end

function SpawnUtil:GetEmergencySpawnCFrame(character, lookVector)
	local _, platform = self:EnsureEmergencySpawnArea()
	local surfaceOffset = self:GetCharacterSurfaceOffset(character)
	local spawnPosition = platform.Position + Vector3.new(0, (platform.Size.Y * 0.5) + surfaceOffset, 0)
	local flatLook = flattenLookVector(lookVector or platform.CFrame.LookVector)
	return CFrame.lookAt(spawnPosition, spawnPosition + flatLook, Vector3.yAxis), platform
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
