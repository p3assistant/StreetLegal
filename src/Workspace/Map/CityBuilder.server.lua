local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local SpawnData = require(Workspace.Spawns.SpawnData)
local ObstacleCatalog = require(Workspace.Ramps.ObstacleCatalog)

local mapFolder = script.Parent
local spawnsFolder = Workspace:WaitForChild("Spawns")
local policeFolder = Workspace:WaitForChild("Police")
local rampsFolder = Workspace:WaitForChild("Ramps")

local generated = mapFolder:FindFirstChild("Generated")
if generated then
	generated:Destroy()
end

generated = Instance.new("Folder")
generated.Name = "Generated"
generated.Parent = mapFolder

local sections = {}
for _, name in ipairs({ "Ground", "Roads", "Buildings", "Props", "DistrictSigns" }) do
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = generated
	sections[name] = folder
end

local function makePart(parent, name, size, cframe, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Concrete
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function tagSurface(part, district, surfaceType)
	part:SetAttribute("District", district)
	part:SetAttribute("SurfaceType", surfaceType)
	return part
end

local function makeRoad(name, size, cframe, district)
	return tagSurface(makePart(sections.Roads, name, size, cframe, Color3.fromRGB(38, 41, 45), Enum.Material.Asphalt), district, "Street")
end

local function makeSidewalk(name, size, cframe, district)
	return tagSurface(makePart(sections.Roads, name, size, cframe, Color3.fromRGB(150, 150, 150), Enum.Material.Concrete), district, "Sidewalk")
end

local function makeDistrictPlate(name, position, size, color, surfaceType)
	local plate = makePart(sections.Ground, name, size, CFrame.new(position), color, Enum.Material.Concrete)
	plate:SetAttribute("District", name)
	plate:SetAttribute("SurfaceType", surfaceType)
	return plate
end

local function makeBuilding(name, size, cframe, color, district)
	local building = makePart(sections.Buildings, name, size, cframe, color, Enum.Material.Concrete)
	building:SetAttribute("District", district)
	building:SetAttribute("NearMissTarget", true)
	return building
end

local function makeProp(name, size, cframe, color, district, material)
	local prop = makePart(sections.Props, name, size, cframe, color, material or Enum.Material.Metal)
	prop:SetAttribute("District", district)
	prop:SetAttribute("NearMissTarget", true)
	return prop
end

local districtDefs = {
	{ Name = "RedlineRow", Position = Vector3.new(-540, -1, -40), Size = Vector3.new(520, 2, 760), Surface = "Urban" },
	{ Name = "PennMarket", Position = Vector3.new(-20, -1, 40), Size = Vector3.new(520, 2, 640), Surface = "Urban" },
	{ Name = "DruidHeights", Position = Vector3.new(-180, -1, -640), Size = Vector3.new(860, 2, 300), Surface = "Park" },
	{ Name = "IronHarbor", Position = Vector3.new(520, -1, 280), Size = Vector3.new(700, 2, 620), Surface = "Industrial" },
	{ Name = "CanalSide", Position = Vector3.new(640, -1, -220), Size = Vector3.new(500, 2, 560), Surface = "Street" },
	{ Name = "QuarryRun", Position = Vector3.new(-720, -1, 580), Size = Vector3.new(460, 2, 560), Surface = "OffRoad" },
}

makePart(sections.Ground, "VoidPlate", Vector3.new(2200, 6, 2200), CFrame.new(0, -6, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Concrete)
makePart(sections.Ground, "HarborWater", Vector3.new(420, 14, 1800), CFrame.new(900, Config.World.WaterLevel, 0), Color3.fromRGB(44, 95, 140), Enum.Material.Water)

for _, district in ipairs(districtDefs) do
	makeDistrictPlate(district.Name, district.Position, district.Size, Config.World.DistrictColors[district.Name], district.Surface)
end

for _, x in ipairs({ -780, -540, -300, -60, 180, 420, 660 }) do
	local district = "CanalSide"
	if x < -220 then
		district = "RedlineRow"
	elseif x < 240 then
		district = "PennMarket"
	elseif x < 600 then
		district = "IronHarbor"
	end
	makeRoad("Avenue_" .. tostring(x), Vector3.new(42, 1, 1840), CFrame.new(x, 0.1, 0), district)
	makeSidewalk("AvenueSidewalkL_" .. tostring(x), Vector3.new(10, 1, 1840), CFrame.new(x - 26, 0.3, 0), "City")
	makeSidewalk("AvenueSidewalkR_" .. tostring(x), Vector3.new(10, 1, 1840), CFrame.new(x + 26, 0.3, 0), "City")
end

for _, z in ipairs({ -780, -540, -300, -60, 180, 420, 660 }) do
	local district = "QuarryRun"
	if z < -420 then
		district = "DruidHeights"
	elseif z < 240 then
		district = "PennMarket"
	elseif z < 520 then
		district = "IronHarbor"
	end
	makeRoad("Street_" .. tostring(z), Vector3.new(1840, 1, 42), CFrame.new(0, 0.1, z), district)
	makeSidewalk("StreetSidewalkTop_" .. tostring(z), Vector3.new(1840, 1, 10), CFrame.new(0, 0.3, z - 26), "City")
	makeSidewalk("StreetSidewalkBottom_" .. tostring(z), Vector3.new(1840, 1, 10), CFrame.new(0, 0.3, z + 26), "City")
end

makeRoad("HarborExpress", Vector3.new(900, 1, 28), CFrame.new(40, 34, 480), "PennMarket")
for _, offset in ipairs({ -190, -70, 70, 190 }) do
	makePart(sections.Props, "ExpressSupport" .. tostring(offset), Vector3.new(14, 34, 14), CFrame.new(offset, 17, 480), Color3.fromRGB(108, 108, 108), Enum.Material.Concrete)
end

makePart(sections.Ground, "CanalFloor", Vector3.new(480, 2, 50), CFrame.new(390, -8, -310), Color3.fromRGB(129, 129, 129), Enum.Material.Concrete)
local canalLeft = makePart(sections.Ground, "CanalLeftWall", Vector3.new(480, 16, 8), CFrame.new(390, -1, -286), Color3.fromRGB(155, 155, 155), Enum.Material.Concrete)
local canalRight = makePart(sections.Ground, "CanalRightWall", Vector3.new(480, 16, 8), CFrame.new(390, -1, -334), Color3.fromRGB(155, 155, 155), Enum.Material.Concrete)
canalLeft:SetAttribute("NearMissTarget", true)
canalRight:SetAttribute("NearMissTarget", true)

for x = -720, -360, 90 do
	for z = -240, 360, 150 do
		makeBuilding(
			"Rowhouse_" .. tostring(x) .. "_" .. tostring(z),
			Vector3.new(90, 24, 90),
			CFrame.new(x, 12, z),
			Color3.fromRGB(154, 102, 82),
			"RedlineRow"
		)
	end
end

for x = -160, 200, 120 do
	for z = -160, 200, 120 do
		local towerKey = math.abs((x / 40) + (z / 40))
		local height = 38 + ((towerKey % 4) * 14)
		makeBuilding(
			"MarketBlock_" .. tostring(x) .. "_" .. tostring(z),
			Vector3.new(70, height, 70),
			CFrame.new(x, height * 0.5, z),
			Color3.fromRGB(120, 120, 130),
			"PennMarket"
		)
	end
end

for x = 320, 760, 140 do
	for z = 80, 500, 140 do
		makeBuilding(
			"Warehouse_" .. tostring(x) .. "_" .. tostring(z),
			Vector3.new(100, 28, 80),
			CFrame.new(x, 14, z),
			Color3.fromRGB(92, 98, 102),
			"IronHarbor"
		)
	end
end

makePart(sections.Ground, "DruidGrass", Vector3.new(860, 2, 300), CFrame.new(-180, 0, -640), Color3.fromRGB(75, 132, 87), Enum.Material.Grass)
makePart(sections.Ground, "QuarryDirt", Vector3.new(460, 2, 560), CFrame.new(-720, 0, 580), Color3.fromRGB(126, 98, 64), Enum.Material.Ground)

for i = 1, 18 do
	local x = -520 + (i * 34)
	local z = -690 + ((i % 4) * 55)
	local trunk = makeProp("TreeTrunk" .. tostring(i), Vector3.new(2, 16, 2), CFrame.new(x, 8, z), Color3.fromRGB(92, 66, 44), "DruidHeights", Enum.Material.Wood)
	local crown = makePart(sections.Props, "TreeCrown" .. tostring(i), Vector3.new(10, 10, 10), CFrame.new(x, 19, z), Color3.fromRGB(71, 132, 78), Enum.Material.Grass)
	crown.Shape = Enum.PartType.Ball
	crown:SetAttribute("District", "DruidHeights")
	crown:SetAttribute("NearMissTarget", true)
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Orientation = Vector3.new(0, 0, 90)
end

for i = 1, 22 do
	local x = -820 + (i * 70)
	local z = -720 + ((i % 6) * 230)
	local post = makeProp("StreetProp" .. tostring(i), Vector3.new(1, 14, 1), CFrame.new(x, 7, z), Color3.fromRGB(44, 44, 48), "City", Enum.Material.Metal)
	post.Shape = Enum.PartType.Cylinder
end

local signDefs = {
	{ Name = "Redline Row", Position = Vector3.new(-650, 8, -350) },
	{ Name = "Penn Market", Position = Vector3.new(-40, 8, -350) },
	{ Name = "Druid Heights", Position = Vector3.new(-180, 8, -760) },
	{ Name = "Iron Harbor", Position = Vector3.new(560, 8, 580) },
	{ Name = "Canal Side", Position = Vector3.new(760, 8, -470) },
	{ Name = "Quarry Run", Position = Vector3.new(-790, 8, 790) },
}

for _, sign in ipairs(signDefs) do
	local post = makePart(sections.DistrictSigns, sign.Name .. "_Post", Vector3.new(4, 16, 1), CFrame.new(sign.Position), Color3.fromRGB(44, 44, 44), Enum.Material.Metal)
	post:SetAttribute("NearMissTarget", true)
	local board = makePart(sections.DistrictSigns, sign.Name .. "_Board", Vector3.new(18, 8, 1), CFrame.new(sign.Position + Vector3.new(0, 6, 0)), Color3.fromRGB(255, 170, 60), Enum.Material.Neon)
	board:SetAttribute("District", sign.Name)
end

local policeGenerated = policeFolder:FindFirstChild("Generated")
if policeGenerated then
	policeGenerated:Destroy()
end
policeGenerated = Instance.new("Folder")
policeGenerated.Name = "Generated"
policeGenerated.Parent = policeFolder

local patrolNodes = policeFolder:FindFirstChild("PatrolNodes") or Instance.new("Folder")
patrolNodes.Name = "PatrolNodes"
patrolNodes.Parent = policeFolder
for _, child in ipairs(patrolNodes:GetChildren()) do
	if child:IsA("BasePart") then
		child:Destroy()
	end
end

local stationMarker = policeFolder:FindFirstChild("StationMarker") or Instance.new("Part")
stationMarker.Name = "StationMarker"
stationMarker.Anchored = true
stationMarker.CanCollide = false
stationMarker.Transparency = 1
stationMarker.Size = Vector3.new(4, 4, 4)
stationMarker.CFrame = CFrame.new(Config.World.PoliceStationPosition)
stationMarker.Parent = policeFolder

makePart(policeGenerated, "StationBase", Vector3.new(80, 2, 60), CFrame.new(315, 1, -45), Color3.fromRGB(132, 132, 142), Enum.Material.Concrete)
makeBuilding("StationBlock", Vector3.new(70, 24, 36), CFrame.new(315, 12, -45), Color3.fromRGB(88, 96, 108), "PennMarket")
makePart(policeGenerated, "StationYard", Vector3.new(40, 1, 30), CFrame.new(315, 0.2, 8), Color3.fromRGB(44, 44, 46), Enum.Material.Asphalt)

for index, position in ipairs({
	Vector3.new(300, 3, -60), Vector3.new(420, 3, -60), Vector3.new(540, 3, -60),
	Vector3.new(540, 3, 120), Vector3.new(540, 3, 300), Vector3.new(420, 3, 420),
	Vector3.new(180, 3, 420), Vector3.new(-60, 3, 420), Vector3.new(-60, 3, 120),
	Vector3.new(-60, 3, -120), Vector3.new(180, 3, -120),
}) do
	local node = Instance.new("Part")
	node.Name = string.format("PatrolNode_%02d", index)
	node.Size = Vector3.new(2, 2, 2)
	node.CFrame = CFrame.new(position)
	node.Anchored = true
	node.CanCollide = false
	node.Transparency = 1
	node.Parent = patrolNodes
end

for _, child in ipairs(spawnsFolder:GetChildren()) do
	if child:IsA("BasePart") then
		child:Destroy()
	end
end

for _, spawnDef in ipairs(SpawnData) do
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = spawnDef.Name
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(spawnDef.Position)
	spawn.Transparency = 0.15
	spawn.Color = spawnDef.Color
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CanCollide = true
	spawn.Enabled = true
	spawn:SetAttribute("SpawnPad", true)
	spawn:SetAttribute("District", spawnDef.District)
	spawn.Parent = spawnsFolder
end

local rampsGenerated = rampsFolder:FindFirstChild("Generated")
if rampsGenerated then
	rampsGenerated:Destroy()
end
rampsGenerated = Instance.new("Folder")
rampsGenerated.Name = "Generated"
rampsGenerated.Parent = rampsFolder

local function addRamp(obstacle)
	local ramp = Instance.new("WedgePart")
	ramp.Name = obstacle.Name
	ramp.Size = obstacle.Size
	ramp.CFrame = CFrame.new(obstacle.Position) * CFrame.Angles(math.rad(obstacle.Rotation.X), math.rad(obstacle.Rotation.Y), math.rad(obstacle.Rotation.Z))
	ramp.Color = Color3.fromRGB(245, 170, 60)
	ramp.Material = Enum.Material.Metal
	ramp.Anchored = true
	ramp.Parent = rampsGenerated
	ramp:SetAttribute("District", obstacle.District)
	ramp:SetAttribute("NearMissTarget", true)
end

local function addStairSet(obstacle)
	for step = 1, 6 do
		local stepPart = makePart(rampsGenerated, obstacle.Name .. "_Step" .. tostring(step), Vector3.new(obstacle.Size.X, 1 + step, 4), CFrame.new(obstacle.Position + Vector3.new(0, (step * 0.5), (step * 4))), Color3.fromRGB(142, 142, 142), Enum.Material.Concrete)
		stepPart:SetAttribute("District", obstacle.District)
		stepPart:SetAttribute("NearMissTarget", true)
	end
end

local function addGap(obstacle)
	makePart(rampsGenerated, obstacle.Name .. "_DeckA", Vector3.new(obstacle.Size.X * 0.4, 2, obstacle.Size.Z), CFrame.new(obstacle.Position + Vector3.new(-(obstacle.Size.X * 0.3), obstacle.Size.Y, 0)), Color3.fromRGB(88, 88, 92), Enum.Material.Metal)
	makePart(rampsGenerated, obstacle.Name .. "_DeckB", Vector3.new(obstacle.Size.X * 0.4, 2, obstacle.Size.Z), CFrame.new(obstacle.Position + Vector3.new((obstacle.Size.X * 0.3), obstacle.Size.Y, 0)), Color3.fromRGB(88, 88, 92), Enum.Material.Metal)
	addRamp({ Name = obstacle.Name .. "_Launch", Position = obstacle.Position + Vector3.new(-(obstacle.Size.X * 0.48), obstacle.Size.Y - 4, 0), Size = Vector3.new(18, 8, obstacle.Size.Z + 8), Rotation = Vector3.new(0, 90, 0), District = obstacle.District })
	addRamp({ Name = obstacle.Name .. "_Landing", Position = obstacle.Position + Vector3.new((obstacle.Size.X * 0.48), obstacle.Size.Y - 4, 0), Size = Vector3.new(18, 8, obstacle.Size.Z + 8), Rotation = Vector3.new(0, -90, 0), District = obstacle.District })
end

local function addCanalJump(obstacle)
	addRamp({ Name = obstacle.Name .. "_WestRamp", Position = obstacle.Position + Vector3.new(-90, 4, 0), Size = Vector3.new(24, 12, 30), Rotation = Vector3.new(0, 90, 0), District = obstacle.District })
	addRamp({ Name = obstacle.Name .. "_EastRamp", Position = obstacle.Position + Vector3.new(90, 4, 0), Size = Vector3.new(24, 12, 30), Rotation = Vector3.new(0, -90, 0), District = obstacle.District })
end

local function addQuarterPipe(obstacle)
	addRamp(obstacle)
	makePart(rampsGenerated, obstacle.Name .. "_Deck", Vector3.new(obstacle.Size.X, 2, 20), CFrame.new(obstacle.Position + Vector3.new(0, obstacle.Size.Y * 0.8, obstacle.Size.Z * 0.35)), Color3.fromRGB(82, 82, 82), Enum.Material.Metal)
end

local function addDirtJump(obstacle)
	local dirt = Instance.new("WedgePart")
	dirt.Name = obstacle.Name
	dirt.Size = obstacle.Size
	dirt.CFrame = CFrame.new(obstacle.Position) * CFrame.Angles(0, math.rad(obstacle.Rotation.Y), 0)
	dirt.Color = Color3.fromRGB(134, 101, 64)
	dirt.Material = Enum.Material.Ground
	dirt.Anchored = true
	dirt.Parent = rampsGenerated
	dirt:SetAttribute("District", obstacle.District)
	dirt:SetAttribute("NearMissTarget", true)
end

local function addContainerStack(obstacle)
	for layer = 0, 2 do
		for column = -1, 1 do
			local container = makePart(rampsGenerated, obstacle.Name .. "_Container_" .. tostring(layer) .. "_" .. tostring(column), Vector3.new(22, 10, 10), CFrame.new(obstacle.Position + Vector3.new(column * 22, (layer * 10), layer % 2 == 0 and 0 or 11)), Color3.fromRGB(59 + layer * 30, 105, 170), Enum.Material.Metal)
			container:SetAttribute("District", obstacle.District)
			container:SetAttribute("NearMissTarget", true)
		end
	end
	addRamp({ Name = obstacle.Name .. "_Launch", Position = obstacle.Position + Vector3.new(-48, 6, 0), Size = Vector3.new(20, 12, 24), Rotation = Vector3.new(0, 90, 0), District = obstacle.District })
end

for _, obstacle in ipairs(ObstacleCatalog) do
	if obstacle.Type == "Ramp" then
		addRamp(obstacle)
	elseif obstacle.Type == "StairSet" then
		addStairSet(obstacle)
	elseif obstacle.Type == "Gap" then
		addGap(obstacle)
	elseif obstacle.Type == "CanalJump" then
		addCanalJump(obstacle)
	elseif obstacle.Type == "QuarterPipe" then
		addQuarterPipe(obstacle)
	elseif obstacle.Type == "DirtJump" then
		addDirtJump(obstacle)
	elseif obstacle.Type == "ContainerStack" then
		addContainerStack(obstacle)
	end
end

Workspace:SetAttribute("StreetLegalWorldReady", true)
