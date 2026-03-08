local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local WantedService = require(ServerScriptService.Services.WantedService)

local PoliceService = {
	Initialized = false,
	PoliceFolder = nil,
	OfficersFolder = nil,
	NodesFolder = nil,
	PatrolNodes = {},
	Officers = {},
}

local function createOfficerPart(parent, name, size, cframe, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.CanCollide = true
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function weld(part0, part1)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = part0
	weldConstraint.Part1 = part1
	weldConstraint.Parent = part0
	return weldConstraint
end

local function now()
	return Workspace:GetServerTimeNow()
end

function PoliceService:CollectNodes()
	self.PatrolNodes = {}
	for _, node in ipairs(self.NodesFolder:GetChildren()) do
		if node:IsA("BasePart") then
			table.insert(self.PatrolNodes, node)
		end
	end
	return self.PatrolNodes
end

function PoliceService:CreateOfficerModel(index, spawnCFrame)
	local model = Instance.new("Model")
	model.Name = string.format("BPD_Rider_%02d", index)
	model:SetAttribute("OfficerIndex", index)

	local root = createOfficerPart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), spawnCFrame, Color3.fromRGB(30, 40, 55), Enum.Material.SmoothPlastic, 0)
	root.Massless = false
	model.PrimaryPart = root

	local torso = createOfficerPart(model, "Torso", Vector3.new(2, 2, 1), spawnCFrame * CFrame.new(0, 1.4, 0), Color3.fromRGB(43, 65, 89), Enum.Material.SmoothPlastic, 0)
	local head = createOfficerPart(model, "Head", Vector3.new(1.5, 1.5, 1.5), spawnCFrame * CFrame.new(0, 3.0, 0), Color3.fromRGB(233, 194, 165), Enum.Material.SmoothPlastic, 0)
	local bikeBody = createOfficerPart(model, "PatrolBike", Vector3.new(1.5, 1, 4.5), spawnCFrame * CFrame.new(0, 0.5, 0), Color3.fromRGB(245, 245, 245), Enum.Material.Metal, 0)
	local frontWheel = createOfficerPart(model, "FrontWheel", Vector3.new(1.8, 1.8, 0.5), spawnCFrame * CFrame.new(0, 0.6, -2.1) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(18, 18, 18), Enum.Material.Rubber, 0)
	local rearWheel = createOfficerPart(model, "RearWheel", Vector3.new(1.8, 1.8, 0.5), spawnCFrame * CFrame.new(0, 0.6, 2.1) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(18, 18, 18), Enum.Material.Rubber, 0)
	frontWheel.Shape = Enum.PartType.Cylinder
	rearWheel.Shape = Enum.PartType.Cylinder

	for _, part in ipairs({ torso, head, bikeBody, frontWheel, rearWheel }) do
		weld(root, part)
	end

	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.WalkSpeed = Config.Police.PatrolSpeed
	hum.AutoRotate = true
	hum.DisplayName = "BPD Rider"
	hum.Parent = model

	model.Parent = self.OfficersFolder

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			pcall(function()
				descendant:SetNetworkOwner(nil)
			end)
		end
	end

	local officer = {
		Model = model,
		Humanoid = hum,
		Root = root,
		PatrolIndex = ((index - 1) % math.max(1, #self.PatrolNodes)) + 1,
		CurrentTarget = nil,
		LastPathAt = 0,
		LastSeenAt = 0,
		Waypoints = {},
		WaypointIndex = 0,
	}

	hum.MoveToFinished:Connect(function(reached)
		if not officer.Model.Parent then
			return
		end
		if officer.WaypointIndex > 0 and reached then
			officer.WaypointIndex += 1
			local nextWaypoint = officer.Waypoints[officer.WaypointIndex]
			if nextWaypoint then
				if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
					officer.Humanoid.Jump = true
				end
				officer.Humanoid:MoveTo(nextWaypoint.Position)
			end
		end
	end)

	return officer
end

function PoliceService:ChooseTarget(officer)
	local bestPlayer = nil
	local bestScore = -math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if not WantedService:IsOnArrestCooldown(player) then
			local heat = WantedService:GetHeat(player)
			if heat > 0 then
				local character = player.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local distance = (rootPart.Position - officer.Root.Position).Magnitude
					local range = math.min(Config.Police.PursuitMaxRange, Config.Police.DetectionRange + (heat * 2.5))
					if distance <= range then
						local score = (heat * 14) - (distance * 0.08)
						if score > bestScore then
							bestScore = score
							bestPlayer = player
						end
					end
				end
			end
		end
	end

	return bestPlayer
end

function PoliceService:PathOfficerTo(officer, destination)
	if not officer.Root or not officer.Root.Parent then
		return
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2.5,
		AgentHeight = 6,
		AgentCanJump = true,
		AgentCanClimb = true,
	})

	local success = pcall(function()
		path:ComputeAsync(officer.Root.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		officer.Waypoints = path:GetWaypoints()
		officer.WaypointIndex = 2
		local firstWaypoint = officer.Waypoints[2]
		if firstWaypoint then
			if firstWaypoint.Action == Enum.PathWaypointAction.Jump then
				officer.Humanoid.Jump = true
			end
			officer.Humanoid:MoveTo(firstWaypoint.Position)
		else
			officer.Humanoid:MoveTo(destination)
		end
	else
		officer.Waypoints = {}
		officer.WaypointIndex = 0
		officer.Humanoid:MoveTo(destination)
	end

	officer.LastPathAt = now()
end

function PoliceService:UpdateOfficer(officer)
	if not officer.Model.Parent then
		return
	end

	if officer.Root.Position.Y < -30 then
		officer.Model:PivotTo(self.PatrolNodes[officer.PatrolIndex].CFrame + Vector3.new(0, 4, 0))
		return
	end

	local target = self:ChooseTarget(officer) or officer.CurrentTarget

	if target and WantedService:GetHeat(target) > 0 then
		officer.CurrentTarget = target
		officer.Humanoid.WalkSpeed = Config.Police.ChaseSpeed

		local targetCharacter = target.Character
		local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			return
		end

		officer.LastSeenAt = now()
		local distance = (targetRoot.Position - officer.Root.Position).Magnitude
		if distance <= Config.Police.ArrestDistance then
			WantedService:ArrestPlayer(target, officer.Model.Name)
			return
		end

		if now() - officer.LastPathAt >= Config.Police.RepathInterval then
			self:PathOfficerTo(officer, targetRoot.Position)
		end
	else
		officer.CurrentTarget = nil
		officer.Humanoid.WalkSpeed = Config.Police.PatrolSpeed
		local patrolNode = self.PatrolNodes[officer.PatrolIndex]
		if patrolNode then
			if (patrolNode.Position - officer.Root.Position).Magnitude <= 12 then
				officer.PatrolIndex += 1
				if officer.PatrolIndex > #self.PatrolNodes then
					officer.PatrolIndex = 1
				end
				patrolNode = self.PatrolNodes[officer.PatrolIndex]
			end
			if patrolNode and now() - officer.LastPathAt >= Config.Police.RepathInterval then
				self:PathOfficerTo(officer, patrolNode.Position)
			end
		end
	end
end

function PoliceService:Init(policeFolder)
	if self.Initialized then
		return
	end

	self.Initialized = true
	self.PoliceFolder = policeFolder
	self.OfficersFolder = policeFolder:FindFirstChild("Officers") or Instance.new("Folder")
	self.OfficersFolder.Name = "Officers"
	self.OfficersFolder.Parent = policeFolder
	self.NodesFolder = policeFolder:WaitForChild("PatrolNodes")
	self:CollectNodes()

	if #self.PatrolNodes == 0 then
		warn("[StreetLegal] No police patrol nodes found.")
		return
	end

	for index = 1, Config.Police.OfficerCount do
		local spawnNode = self.PatrolNodes[((index - 1) % #self.PatrolNodes) + 1]
		local officer = self:CreateOfficerModel(index, spawnNode.CFrame + Vector3.new(0, 4, 0))
		table.insert(self.Officers, officer)
	end

	task.spawn(function()
		while true do
			for _, officer in ipairs(self.Officers) do
				self:UpdateOfficer(officer)
			end
			task.wait(0.35)
		end
	end)
end

return PoliceService
