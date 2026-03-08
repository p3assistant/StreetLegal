local Players = game:GetService("Players")

local SpawnUtil = require(script.Parent.SpawnUtil)

local SpawnService = {
	Initialized = false,
}

local function zeroAssembly(rootPart)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

function SpawnService:AssignRespawnLocation(player)
	if not SpawnUtil:WaitForWorldReady(20) then
		return
	end

	local spawnPad = SpawnUtil:ChooseSpawnPad(player)
	if spawnPad and spawnPad:IsA("SpawnLocation") then
		player.RespawnLocation = spawnPad
	end
end

function SpawnService:PlaceCharacter(player, character)
	player:SetAttribute("StreetLegalSpawnReady", false)

	if not SpawnUtil:WaitForWorldReady(20) then
		warn("[StreetLegal] World was not ready in time for", player.Name)
		player:SetAttribute("StreetLegalSpawnReady", true)
		return
	end

	self:AssignRespawnLocation(player)

	local humanoid = character:WaitForChild("Humanoid", 10)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not rootPart or player.Character ~= character then
		return
	end

	local targetCFrame = SpawnUtil:GetCharacterSpawnCFrame(player, character)
	character:PivotTo(targetCFrame)
	zeroAssembly(rootPart)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	task.delay(0.2, function()
		if player.Character ~= character or not rootPart.Parent then
			return
		end

		local grounded = SpawnUtil:RaycastToGround(rootPart.Position, { character }, 6, 20)
		if not grounded then
			local retryCFrame = SpawnUtil:GetCharacterSpawnCFrame(player, character)
			character:PivotTo(retryCFrame)
			zeroAssembly(rootPart)
		end

		player:SetAttribute("StreetLegalSpawnReady", true)
	end)
end

function SpawnService:BindPlayer(player)
	player:SetAttribute("StreetLegalSpawnReady", false)
	task.spawn(function()
		self:AssignRespawnLocation(player)
	end)

	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			self:PlaceCharacter(player, character)
		end)
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

	Players.PlayerAdded:Connect(function(player)
		self:BindPlayer(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:BindPlayer(player)
	end
end

return SpawnService
