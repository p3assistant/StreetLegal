local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)

local DataService = {
	Profiles = {},
	Remotes = nil,
	Store = nil,
	Initialized = false,
	UseMockStore = false,
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local clone = {}
	for key, inner in pairs(value) do
		clone[key] = deepCopy(inner)
	end
	return clone
end

local function reconcile(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = deepCopy(value)
		elseif type(value) == "table" and type(target[key]) == "table" then
			reconcile(target[key], value)
		end
	end
	return target
end

local function ensureFreeBikeOwnership(profile)
	if type(profile.OwnedBikes) ~= "table" then
		profile.OwnedBikes = {}
	end

	for bikeId, bike in pairs(BikeDefinitions) do
		if bike.UnlockType == "Free" then
			profile.OwnedBikes[bikeId] = true
		end
	end

	if not profile.OwnedBikes[profile.EquippedBikeId] then
		profile.EquippedBikeId = nil
		for bikeId, owned in pairs(profile.OwnedBikes) do
			if owned then
				profile.EquippedBikeId = bikeId
				break
			end
		end
	end

	if not profile.EquippedBikeId then
		profile.EquippedBikeId = Config.Economy.StarterBikeId
	end

	return profile
end

local function buildDefaultProfile()
	local profile = {
		Cash = Config.Economy.StarterCash,
		OwnedBikes = {},
		EquippedBikeId = Config.Economy.StarterBikeId,
		Stats = {
			Arrests = 0,
			BestCombo = 0,
			TotalStunts = 0,
			TotalCashEarned = 0,
		},
	}

	return ensureFreeBikeOwnership(profile)
end

function DataService:Init(remotes)
	if self.Initialized then
		return
	end

	self.Initialized = true
	self.Remotes = remotes
	self.UseMockStore = RunService:IsStudio() and game.GameId == 0
	if self.UseMockStore then
		warn("[StreetLegal] Using mock profile storage in Studio because this place is not published.")
	else
		self.Store = DataStoreService:GetDataStore(Config.Gameplay.DataStoreName)
	end

	Players.PlayerAdded:Connect(function(player)
		self:LoadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:SaveProfile(player)
		self.Profiles[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:LoadProfile(player)
		end)
	end

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:SaveProfile(player)
		end
	end)
end

function DataService:GetProfile(player)
	return self.Profiles[player]
end

function DataService:GetClientSnapshot(player)
	local profile = self:GetProfile(player)
	if not profile then
		return nil
	end

	return {
		Cash = profile.Cash,
		OwnedBikes = deepCopy(profile.OwnedBikes),
		EquippedBikeId = profile.EquippedBikeId,
		Stats = deepCopy(profile.Stats),
	}
end

function DataService:PushProfile(player)
	if not self.Remotes or not self.Remotes.DataSync then
		return
	end

	local snapshot = self:GetClientSnapshot(player)
	if snapshot then
		self.Remotes.DataSync:FireClient(player, snapshot)
	end
end

function DataService:LoadProfile(player)
	if self.Profiles[player] then
		return self.Profiles[player]
	end

	local profile = buildDefaultProfile()
	local ok, savedData = true, nil
	if not self.UseMockStore and self.Store then
		ok, savedData = pcall(function()
			return self.Store:GetAsync(tostring(player.UserId))
		end)
		if not ok then
			warn("[StreetLegal] Falling back to default profile for", player.Name, savedData)
		end
	end

	if ok and type(savedData) == "table" then
		profile = reconcile(savedData, buildDefaultProfile())
	end

	profile = ensureFreeBikeOwnership(profile)

	self.Profiles[player] = profile
	player:SetAttribute("StreetLegalProfileReady", true)
	self:PushProfile(player)
	return profile
end

function DataService:SaveProfile(player)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	if self.UseMockStore or not self.Store then
		return true
	end

	local payload = deepCopy(profile)
	local ok, err = pcall(function()
		self.Store:UpdateAsync(tostring(player.UserId), function()
			return payload
		end)
	end)

	if not ok then
		warn("[StreetLegal] Failed to save profile for", player.Name, err)
	end

	return ok
end

function DataService:OwnsBike(player, bikeId)
	local profile = self:GetProfile(player)
	return profile and profile.OwnedBikes[bikeId] == true or false
end

function DataService:GrantBike(player, bikeId)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.OwnedBikes[bikeId] = true
	self:PushProfile(player)
	return true
end

function DataService:SetEquippedBike(player, bikeId)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	if not profile.OwnedBikes[bikeId] then
		return false
	end

	profile.EquippedBikeId = bikeId
	self:PushProfile(player)
	return true
end

function DataService:AdjustCash(player, delta)
	local profile = self:GetProfile(player)
	if not profile then
		return false, 0
	end

	profile.Cash = math.clamp(profile.Cash + delta, 0, Config.Economy.CashCap)
	if delta > 0 then
		profile.Stats.TotalCashEarned = (profile.Stats.TotalCashEarned or 0) + delta
	end
	self:PushProfile(player)
	return true, profile.Cash
end

function DataService:SpendCash(player, amount)
	local profile = self:GetProfile(player)
	if not profile then
		return false, "Profile not loaded"
	end

	if amount < 0 then
		return false, "Invalid cost"
	end

	if profile.Cash < amount then
		return false, "Not enough cash"
	end

	profile.Cash -= amount
	self:PushProfile(player)
	return true, profile.Cash
end

function DataService:RecordStunt(player, score)
	local profile = self:GetProfile(player)
	if not profile then
		return
	end

	profile.Stats.TotalStunts = (profile.Stats.TotalStunts or 0) + 1
	profile.Stats.BestCombo = math.max(profile.Stats.BestCombo or 0, score)
	self:PushProfile(player)
end

function DataService:RecordArrest(player)
	local profile = self:GetProfile(player)
	if not profile then
		return
	end

	profile.Stats.Arrests = (profile.Stats.Arrests or 0) + 1
	self:PushProfile(player)
end

return DataService
