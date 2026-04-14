local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)
local WantedConfig = require(ReplicatedStorage.Modules.WantedConfig)
local SpawnUtil = require(script.Parent.SpawnUtil)

local WantedService = {
	States = {},
	DataService = nil,
	Remotes = nil,
	Initialized = false,
}

local function now()
	return Workspace:GetServerTimeNow()
end

local function getRuntimeBikesFolder()
	local runtime = Workspace:FindFirstChild("StreetLegalRuntime")
	return runtime and runtime:FindFirstChild("Bikes") or nil
end

local TELEMETRY_MOUNT_DISTANCE = 18
local MAX_STUNT_AIRTIME = 6
local MIN_STUNT_SPEED_MPH = 18

function WantedService:EnsureState(player)
	local state = self.States[player]
	if state then
		return state
	end

	state = {
		Heat = 0,
		Level = 0,
		Label = WantedConfig.Levels[1].Label,
		Cooldowns = {},
		LastInfractionAt = 0,
		NextDecayAt = 0,
		ArrestCooldownEnds = 0,
		LastPushedHeat = -1,
		LastPushedLevel = -1,
		NextStuntAwardAt = 0,
		NextNearMissAt = 0,
		LastValidatedBikeSpeedStuds = 0,
	}
	self.States[player] = state
	player:SetAttribute("StreetLegalHeat", 0)
	player:SetAttribute("StreetLegalWantedLevel", 0)
	return state
end

function WantedService:GetLevelForHeat(heat)
	local chosenLevel = 0
	local chosenLabel = WantedConfig.Levels[1].Label
	for index, entry in ipairs(WantedConfig.Levels) do
		if heat >= entry.Threshold then
			chosenLevel = index - 1
			chosenLabel = entry.Label
		end
	end
	return chosenLevel, chosenLabel
end

function WantedService:PushState(player, force)
	local state = self:EnsureState(player)
	if not force and state.LastPushedHeat == state.Heat and state.LastPushedLevel == state.Level then
		return
	end

	state.LastPushedHeat = state.Heat
	state.LastPushedLevel = state.Level
	player:SetAttribute("StreetLegalHeat", state.Heat)
	player:SetAttribute("StreetLegalWantedLevel", state.Level)

	if self.Remotes and self.Remotes.WantedState then
		self.Remotes.WantedState:FireClient(player, {
			Heat = state.Heat,
			Level = state.Level,
			Label = state.Label,
			Cooldown = math.max(0, state.ArrestCooldownEnds - now()),
		})
	end
end

function WantedService:GetHeat(player)
	local state = self:EnsureState(player)
	return state.Heat
end

function WantedService:IsOnArrestCooldown(player)
	local state = self:EnsureState(player)
	return state.ArrestCooldownEnds > now()
end

function WantedService:GetSurfaceInfo(position, ignoreInstances)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreInstances or {}
	params.IgnoreWater = false

	local result = Workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -18, 0), params)
	if not result then
		return "Unknown", "Unknown", nil
	end

	local instance = result.Instance
	return instance:GetAttribute("SurfaceType") or "Unknown", instance:GetAttribute("District") or "Unknown", instance
end

function WantedService:GetActiveBikeModel(player)
	local bikesFolder = getRuntimeBikesFolder()
	if not bikesFolder then
		return nil
	end

	for _, child in ipairs(bikesFolder:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == player.UserId then
			return child
		end
	end

	return nil
end

function WantedService:GetMountedBikeContext(player, character)
	local activeBike = self:GetActiveBikeModel(player)
	if not activeBike or not activeBike.PrimaryPart then
		return nil, nil
	end

	local seat = activeBike:FindFirstChild("Seat")
	if not seat or not seat:IsA("VehicleSeat") then
		return nil, nil
	end

	local occupant = seat.Occupant
	if not occupant or occupant.Parent ~= character then
		return nil, nil
	end

	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return nil, nil
	end

	if (activeBike.PrimaryPart.Position - rootPart.Position).Magnitude > TELEMETRY_MOUNT_DISTANCE then
		return nil, nil
	end

	return activeBike, activeBike.PrimaryPart
end

function WantedService:DestroyActiveBike(player)
	local activeBike = self:GetActiveBikeModel(player)
	if activeBike then
		activeBike:Destroy()
	end
	player:SetAttribute("StreetLegalActiveBikeId", nil)
	player:SetAttribute("StreetLegalMounted", false)
end

function WantedService:AddHeat(player, infractionName, multiplier)
	if not player or not player.Parent then
		return false
	end

	local infraction = WantedConfig.Infractions[infractionName]
	if not infraction then
		return false
	end

	local state = self:EnsureState(player)
	local stamp = now()
	if state.ArrestCooldownEnds > stamp then
		return false
	end

	local cooldownEnds = state.Cooldowns[infractionName]
	if cooldownEnds and cooldownEnds > stamp then
		return false
	end

	local gain = math.max(1, math.floor((infraction.Heat or 0) * (multiplier or 1)))
	state.Cooldowns[infractionName] = stamp + (infraction.Cooldown or 1)
	state.Heat = math.clamp(state.Heat + gain, 0, WantedConfig.MaxHeat)
	state.Level, state.Label = self:GetLevelForHeat(state.Heat)
	state.LastInfractionAt = stamp
	state.NextDecayAt = stamp + WantedConfig.Decay.Delay
	self:PushState(player, true)
	return true
end

function WantedService:AwardStunt(player, score)
	local payout = math.clamp(math.floor(score * Config.Economy.StuntPayoutMultiplier), Config.Economy.StuntPayoutMin, Config.Economy.StuntPayoutMax)
	self.DataService:AdjustCash(player, payout)
	self.DataService:RecordStunt(player, score)
	if self.Remotes and self.Remotes.Notification then
		self.Remotes.Notification:FireClient(player, {
			Type = "success",
			Text = string.format("Clean landing. +$%d", payout),
		})
	end
end

function WantedService:HandleTelemetry(player, action, payload)
	payload = payload or {}
	local state = self:EnsureState(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if action == "StuntLanded" then
		local activeBike, bikeRoot = self:GetMountedBikeContext(player, character)
		if not activeBike or not bikeRoot then
			return
		end

		local stamp = now()
		if state.NextStuntAwardAt > stamp then
			return
		end

		local score = tonumber(payload.Score) or 0
		local airtime = tonumber(payload.Airtime) or 0
		if score <= 0 or score > 4000 or airtime < 0.35 or airtime > MAX_STUNT_AIRTIME then
			return
		end

		local speedStuds = math.max(state.LastValidatedBikeSpeedStuds or 0, bikeRoot.AssemblyLinearVelocity.Magnitude)
		local speedMph = speedStuds / Config.Bike.MphToStuds
		if speedMph < MIN_STUNT_SPEED_MPH then
			return
		end

		local maxScore = math.clamp(math.floor((airtime * 170) + (speedMph * 5) + 180), 25, 2500)
		local awardedScore = math.min(math.floor(score + 0.5), maxScore)
		if awardedScore < 25 then
			return
		end

		state.NextStuntAwardAt = stamp + math.clamp(1 + (airtime * 0.5), 1, 4)
		self:AwardStunt(player, awardedScore)
		local surface = self:GetSurfaceInfo(bikeRoot.Position, { activeBike, character })
		if surface == "Street" then
			self:AddHeat(player, "StuntNoise")
		end
	elseif action == "NearMiss" then
		local _, bikeRoot = self:GetMountedBikeContext(player, character)
		if not bikeRoot then
			return
		end

		local stamp = now()
		if state.NextNearMissAt > stamp then
			return
		end

		local speed = bikeRoot.AssemblyLinearVelocity.Magnitude / Config.Bike.MphToStuds
		if speed < 25 then
			return
		end

		state.NextNearMissAt = stamp + math.max(0.5, WantedConfig.Infractions.NearMiss.Cooldown or 1)
		self:AddHeat(player, "NearMiss")
	end
end

function WantedService:DecayState(player, state)
	local stamp = now()
	if state.Heat <= 0 then
		return
	end
	if stamp < state.NextDecayAt then
		return
	end
	state.Heat = math.max(0, state.Heat - WantedConfig.Decay.Amount)
	state.Level, state.Label = self:GetLevelForHeat(state.Heat)
	state.NextDecayAt = stamp + WantedConfig.Decay.Interval
	self:PushState(player, true)
end

function WantedService:EvaluatePlayer(player)
	local state = self:EnsureState(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local activeBikeId = player:GetAttribute("StreetLegalActiveBikeId")
	local bike = activeBikeId and BikeDefinitions[activeBikeId] or nil
	local activeBike = self:GetActiveBikeModel(player)

	if bike and activeBike and activeBike.PrimaryPart then
		local speedStuds = activeBike.PrimaryPart.AssemblyLinearVelocity.Magnitude
		local speedMph = speedStuds / Config.Bike.MphToStuds
		state.LastValidatedBikeSpeedStuds = speedStuds
		local surface, district = self:GetSurfaceInfo(activeBike.PrimaryPart.Position, { activeBike, character })
		player:SetAttribute("StreetLegalDistrict", district)

		local maxAllowed = bike.TopSpeedStuds * Config.Bike.MaxServerSpeedBuffer
		if speedStuds > maxAllowed then
			local velocity = activeBike.PrimaryPart.AssemblyLinearVelocity
			local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
			if horizontal.Magnitude > 0 then
				local clamped = horizontal.Unit * maxAllowed
				activeBike.PrimaryPart.AssemblyLinearVelocity = Vector3.new(clamped.X, velocity.Y, clamped.Z)
			end
		end

		if surface == "Street" then
			if bike.IllegalOnStreet then
				self:AddHeat(player, "IllegalStreetBike", bike.PoliceHeatMultiplier)
			end
			if speedMph >= 50 then
				self:AddHeat(player, "ExcessiveSpeed")
			elseif speedMph >= 38 then
				self:AddHeat(player, "Speeding")
			end
		end
	elseif rootPart then
		state.LastValidatedBikeSpeedStuds = 0
		local surface, district = self:GetSurfaceInfo(rootPart.Position, { character })
		player:SetAttribute("StreetLegalDistrict", district)
	else
		state.LastValidatedBikeSpeedStuds = 0
	end

	self:DecayState(player, state)
end

function WantedService:ArrestPlayer(player, arrestingOfficer)
	local state = self:EnsureState(player)
	local stamp = now()
	if state.ArrestCooldownEnds > stamp then
		return false
	end

	local fine = Config.Economy.ArrestFineBase + (Config.Economy.ArrestFinePerLevel * state.Level)
	state.Heat = 0
	state.Level = 0
	state.Label = WantedConfig.Levels[1].Label
	state.Cooldowns = {}
	state.LastInfractionAt = 0
	state.NextDecayAt = 0
	state.ArrestCooldownEnds = stamp + Config.Gameplay.ArrestCooldown
	state.NextStuntAwardAt = 0
	state.NextNearMissAt = 0
	state.LastValidatedBikeSpeedStuds = 0
	self:PushState(player, true)

	self:DestroyActiveBike(player)
	self.DataService:AdjustCash(player, -fine)
	self.DataService:RecordArrest(player)

	local character = player.Character
	if character then
		local stationSpawnCFrame = SpawnUtil:GetPoliceStationSpawnCFrame(character)
		character:PivotTo(stationSpawnCFrame)
	end

	if self.Remotes and self.Remotes.PoliceState then
		self.Remotes.PoliceState:FireClient(player, {
			Type = "ARRESTED",
			Fine = fine,
			Officer = arrestingOfficer or "BPD",
			Cooldown = Config.Gameplay.ArrestCooldown,
		})
	end

	if self.Remotes and self.Remotes.Notification then
		self.Remotes.Notification:FireClient(player, {
			Type = "danger",
			Text = string.format("Busted. Fine paid: $%d", fine),
		})
	end

	return true
end

function WantedService:Init(dataService, remotes)
	if self.Initialized then
		return
	end

	self.Initialized = true
	self.DataService = dataService
	self.Remotes = remotes

	Players.PlayerAdded:Connect(function(player)
		self:EnsureState(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.States[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:EnsureState(player)
	end

	self.Remotes.ClientTelemetry.OnServerEvent:Connect(function(player, action, payload)
		self:HandleTelemetry(player, action, payload)
	end)

	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				self:EvaluatePlayer(player)
			end
			task.wait(Config.Gameplay.PoliceScanInterval)
		end
	end)
end

return WantedService
