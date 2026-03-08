local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local SpawnData = require(Workspace.Spawns.SpawnData)

local SpawnUtil = {}

local DEFAULT_LOOK = Vector3.new(0, 0, -1)

local function flattenLookVector(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.001 then
		return DEFAULT_LOOK
	end
	return flat.Unit
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
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreInstances or {}
	params.IgnoreWater = false

	local height = searchHeight or 72
	local depth = searchDepth or 180
	return Workspace:Raycast(
		position + Vector3.new(0, height, 0),
		Vector3.new(0, -(height + depth), 0),
		params
	)
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

function SpawnUtil:GetFallbackSpawnDefinition(player)
	if #SpawnData == 0 then
		return nil
	end

	local index = ((player and player.UserId or 0) % #SpawnData) + 1
	return SpawnData[index]
end

function SpawnUtil:GetCharacterSpawnCFrame(player, character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local surfaceOffset = ((humanoid and humanoid.HipHeight) or 2) + ((rootPart and rootPart.Size.Y) or 2) * 0.5 + 0.25
	local ignoreInstances = { character }

	local pad = self:ChooseSpawnPad(player)
	if pad then
		local resolved = self:ResolveGroundCFrame(pad.Position, pad.CFrame.LookVector, { character, pad }, 24, 80, surfaceOffset)
		if resolved then
			return resolved, pad
		end
	end

	local fallback = self:GetFallbackSpawnDefinition(player)
	if fallback then
		local fallbackPosition = Vector3.new(fallback.Position.X, Config.World.StreetY, fallback.Position.Z)
		local resolved = self:ResolveGroundCFrame(fallbackPosition, DEFAULT_LOOK, ignoreInstances, 24, 80, surfaceOffset)
		if resolved then
			return resolved, fallback
		end
	end

	local stationPosition = Config.World.PoliceStationPosition
	return CFrame.lookAt(
		Vector3.new(stationPosition.X, stationPosition.Y + surfaceOffset, stationPosition.Z),
		Vector3.new(stationPosition.X, stationPosition.Y + surfaceOffset, stationPosition.Z) + DEFAULT_LOOK,
		Vector3.yAxis
	), nil
end

return SpawnUtil
