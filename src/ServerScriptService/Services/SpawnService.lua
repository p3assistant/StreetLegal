local Players = game:GetService("Players")

local SpawnUtil = require(script.Parent.SpawnUtil)

local SpawnService = {
	Initialized = false,
	SpawnTokens = {},
	Protections = {},
}

local POST_RELEASE_PROTECTION_SECONDS = 1.5
local WORLD_READY_TIMEOUT = 15

local function zeroAssembly(rootPart)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function restoreProtectedState(state)
	if not state or state.Restored then
		return
	end

	state.Restored = true

	local humanoid = state.Humanoid
	local rootPart = state.RootPart
	if rootPart and rootPart.Parent then
		zeroAssembly(rootPart)
		rootPart.Anchored = state.RootAnchored
	end

	if humanoid and humanoid.Parent then
		humanoid.AutoRotate = state.AutoRotate
		humanoid.WalkSpeed = state.WalkSpeed
		humanoid.JumpPower = state.JumpPower
		humanoid.JumpHeight = state.JumpHeight
		humanoid.PlatformStand = state.PlatformStand
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

function SpawnService:IsCurrentPlacement(player, character, token)
	return self.SpawnTokens[player] == token and player.Character == character
end

function SpawnService:ClearProtection(character)
	local state = self.Protections[character]
	if not state then
		return
	end

	restoreProtectedState(state)

	if state.HealthConnection then
		state.HealthConnection:Disconnect()
		state.HealthConnection = nil
	end

	self.Protections[character] = nil
end

function SpawnService:AssignRespawnLocation(player)
	local safeSpawn = SpawnUtil:GetEmergencySpawnLocation()
	if safeSpawn and safeSpawn:IsA("SpawnLocation") then
		player.RespawnLocation = safeSpawn
	end
end

function SpawnService:BeginProtection(player, character, token)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not rootPart or not self:IsCurrentPlacement(player, character, token) then
		return nil
	end

	self:ClearProtection(character)

	local state = {
		Player = player,
		Character = character,
		Humanoid = humanoid,
		RootPart = rootPart,
		RootAnchored = rootPart.Anchored,
		AutoRotate = humanoid.AutoRotate,
		WalkSpeed = humanoid.WalkSpeed,
		JumpPower = humanoid.JumpPower,
		JumpHeight = humanoid.JumpHeight,
		PlatformStand = humanoid.PlatformStand,
		ProtectedHealth = math.max(humanoid.Health, humanoid.MaxHealth),
		Token = token,
		Restored = false,
	}

	self.Protections[character] = state

	player:SetAttribute("StreetLegalSpawnStabilizing", true)
	rootPart.Anchored = true
	zeroAssembly(rootPart)
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.PlatformStand = true
	humanoid.Sit = false
	humanoid.Health = state.ProtectedHealth

	state.HealthConnection = humanoid.HealthChanged:Connect(function(newHealth)
		if self.Protections[character] ~= state or not self:IsCurrentPlacement(player, character, token) then
			return
		end
		if humanoid.Parent and newHealth < state.ProtectedHealth then
			humanoid.Health = state.ProtectedHealth
		end
	end)

	return state
end

function SpawnService:TryPlacement(player, character, rootPart, token, candidate)
	for _ = 1, 2 do
		if not self:IsCurrentPlacement(player, character, token) or not rootPart.Parent then
			return false
		end

		character:PivotTo(candidate.CFrame)
		zeroAssembly(rootPart)
		task.wait(0.05)

		local grounded = SpawnUtil:IsCharacterGrounded(character, 10)
		if grounded then
			player:SetAttribute("StreetLegalSpawnSource", candidate.Source)
			return true
		end
	end

	return false
end

function SpawnService:FinishPlacement(player, character, token)
	local state = self.Protections[character]
	if not state or not self:IsCurrentPlacement(player, character, token) then
		return
	end

	restoreProtectedState(state)
	player:SetAttribute("StreetLegalSpawnStabilizing", false)
	player:SetAttribute("StreetLegalSpawnReady", true)

	task.delay(POST_RELEASE_PROTECTION_SECONDS, function()
		if self.Protections[character] == state then
			self:ClearProtection(character)
		end
	end)
end

function SpawnService:FailToSafeSpawn(player, character, rootPart, token)
	local emergencyCFrame = SpawnUtil:GetEmergencySpawnCFrame(character)
	local emergencyCandidate = {
		CFrame = emergencyCFrame,
		Source = "emergency safe spawn",
	}

	if not self:TryPlacement(player, character, rootPart, token, emergencyCandidate) then
		warn("[StreetLegal] Failed to verify emergency spawn for", player.Name)
	end

	player:SetAttribute("StreetLegalSpawnSource", emergencyCandidate.Source)
	self:FinishPlacement(player, character, token)
end

function SpawnService:PlaceCharacter(player, character)
	local token = (self.SpawnTokens[player] or 0) + 1
	self.SpawnTokens[player] = token

	player:SetAttribute("StreetLegalSpawnReady", false)
	self:AssignRespawnLocation(player)
	SpawnUtil:EnsureEmergencySpawnArea()

	local protection = self:BeginProtection(player, character, token)
	if not protection then
		return
	end

	local worldReady = SpawnUtil:WaitForWorldReady(WORLD_READY_TIMEOUT)
	if not self:IsCurrentPlacement(player, character, token) then
		return
	end

	local candidates
	if worldReady then
		candidates = SpawnUtil:GetPlacementCandidates(player, character)
	else
		warn("[StreetLegal] World was not ready in time for", player.Name, "- releasing on emergency safe spawn")
		local emergencyCFrame = SpawnUtil:GetEmergencySpawnCFrame(character)
		candidates = {
			{
				CFrame = emergencyCFrame,
				Source = "emergency safe spawn (world timeout)",
			},
		}
	end

	local rootPart = protection.RootPart
	local placed = false
	for _, candidate in ipairs(candidates) do
		if self:TryPlacement(player, character, rootPart, token, candidate) then
			placed = true
			break
		end
	end

	if not placed then
		warn("[StreetLegal] All spawn candidates failed for", player.Name, "- forcing emergency safe spawn")
		self:FailToSafeSpawn(player, character, rootPart, token)
		return
	end

	self:FinishPlacement(player, character, token)
end

function SpawnService:BindPlayer(player)
	player:SetAttribute("StreetLegalSpawnReady", false)
	player:SetAttribute("StreetLegalSpawnStabilizing", false)
	self:AssignRespawnLocation(player)

	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			self:PlaceCharacter(player, character)
		end)
	end)

	player.CharacterRemoving:Connect(function(character)
		self.SpawnTokens[player] = (self.SpawnTokens[player] or 0) + 1
		player:SetAttribute("StreetLegalSpawnReady", false)
		player:SetAttribute("StreetLegalSpawnStabilizing", false)
		self:ClearProtection(character)
	end)

	if player.Character then
		task.spawn(function()
			self:PlaceCharacter(player, player.Character)
		end)
	end
end

function SpawnService:Init()
	if self.Initialized then
		return
	end

	self.Initialized = true
	SpawnUtil:EnsureEmergencySpawnArea()

	Players.PlayerAdded:Connect(function(player)
		self:BindPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.SpawnTokens[player] = nil
		for character, state in pairs(self.Protections) do
			if state.Player == player then
				self:ClearProtection(character)
			end
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:BindPlayer(player)
	end
end

return SpawnService
