local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Modules.Config)
local SpawnData = require(Workspace.Spawns.SpawnData)
local ObstacleCatalog = require(Workspace.Ramps.ObstacleCatalog)

local mapFolder = script.Parent
local spawnsFolder = Workspace:WaitForChild("Spawns")
local policeFolder = Workspace:WaitForChild("Police")
local rampsFolder = Workspace:WaitForChild("Ramps")

Workspace:SetAttribute("StreetLegalWorldReady", false)

local generated = mapFolder:FindFirstChild("Generated")
if generated then
	generated:Destroy()
end

generated = Instance.new("Folder")
generated.Name = "Generated"
generated.Parent = mapFolder

local sections = {}
for _, name in ipairs({ "Ground", "Roads", "Buildings", "Props", "DistrictSigns", "Waterfront", "Background" }) do
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = generated
	sections[name] = folder
end

local palettes = {
	RedlineRow = {
		Ground = Color3.fromRGB(118, 83, 72),
		Trim = Color3.fromRGB(178, 140, 118),
		Accent = Color3.fromRGB(201, 88, 78),
		Roof = Color3.fromRGB(53, 41, 40),
		Window = Color3.fromRGB(199, 222, 255),
	},
	PennMarket = {
		Ground = Color3.fromRGB(74, 76, 82),
		Trim = Color3.fromRGB(164, 168, 176),
		Accent = Color3.fromRGB(255, 178, 82),
		Roof = Color3.fromRGB(44, 47, 55),
		Window = Color3.fromRGB(188, 225, 255),
	},
	DruidHeights = {
		Ground = Color3.fromRGB(72, 118, 82),
		Trim = Color3.fromRGB(154, 179, 137),
		Accent = Color3.fromRGB(116, 202, 144),
		Roof = Color3.fromRGB(61, 72, 53),
		Window = Color3.fromRGB(206, 236, 201),
	},
	IronHarbor = {
		Ground = Color3.fromRGB(88, 92, 95),
		Trim = Color3.fromRGB(149, 156, 164),
		Accent = Color3.fromRGB(92, 157, 220),
		Roof = Color3.fromRGB(57, 61, 66),
		Window = Color3.fromRGB(186, 216, 239),
	},
	CanalSide = {
		Ground = Color3.fromRGB(70, 90, 104),
		Trim = Color3.fromRGB(145, 168, 186),
		Accent = Color3.fromRGB(110, 214, 240),
		Roof = Color3.fromRGB(47, 58, 68),
		Window = Color3.fromRGB(193, 232, 245),
	},
	QuarryRun = {
		Ground = Color3.fromRGB(118, 92, 61),
		Trim = Color3.fromRGB(175, 152, 106),
		Accent = Color3.fromRGB(237, 204, 123),
		Roof = Color3.fromRGB(86, 71, 55),
		Window = Color3.fromRGB(233, 227, 203),
	},
	City = {
		Ground = Color3.fromRGB(84, 86, 92),
		Trim = Color3.fromRGB(166, 170, 176),
		Accent = Color3.fromRGB(255, 205, 118),
		Roof = Color3.fromRGB(50, 52, 58),
		Window = Color3.fromRGB(198, 224, 245),
	},
}

local districtDefs = {
	{ Name = "RedlineRow", Position = Vector3.new(-540, -1, -40), Size = Vector3.new(520, 2, 760), Surface = "Urban", Material = Enum.Material.Ground },
	{ Name = "PennMarket", Position = Vector3.new(-20, -1, 40), Size = Vector3.new(520, 2, 640), Surface = "Urban", Material = Enum.Material.Concrete },
	{ Name = "DruidHeights", Position = Vector3.new(-180, -1, -640), Size = Vector3.new(860, 2, 300), Surface = "Park", Material = Enum.Material.Grass },
	{ Name = "IronHarbor", Position = Vector3.new(520, -1, 280), Size = Vector3.new(700, 2, 620), Surface = "Industrial", Material = Enum.Material.Concrete },
	{ Name = "CanalSide", Position = Vector3.new(640, -1, -220), Size = Vector3.new(500, 2, 560), Surface = "Street", Material = Enum.Material.Slate },
	{ Name = "QuarryRun", Position = Vector3.new(-720, -1, 580), Size = Vector3.new(460, 2, 560), Surface = "OffRoad", Material = Enum.Material.Ground },
}

local function applyLighting()
	Lighting.Technology = Enum.Technology.Future
	Lighting.ClockTime = 16.1
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(28, 30, 38)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 118, 132)
	Lighting.EnvironmentDiffuseScale = 0.38
	Lighting.EnvironmentSpecularScale = 0.48
	Lighting.GlobalShadows = true
	Lighting.FogColor = Color3.fromRGB(170, 183, 201)
	Lighting.FogEnd = 3600
	Lighting.ShadowSoftness = 0.3

	local atmosphere = Lighting:FindFirstChild("StreetLegalAtmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "StreetLegalAtmosphere"
	atmosphere.Color = Color3.fromRGB(194, 210, 230)
	atmosphere.Decay = Color3.fromRGB(123, 148, 168)
	atmosphere.Density = 0.29
	atmosphere.Glare = 0.12
	atmosphere.Haze = 1.45
	atmosphere.Parent = Lighting

	local bloom = Lighting:FindFirstChild("StreetLegalBloom") or Instance.new("BloomEffect")
	bloom.Name = "StreetLegalBloom"
	bloom.Intensity = 0.18
	bloom.Size = 18
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local sunRays = Lighting:FindFirstChild("StreetLegalSunRays") or Instance.new("SunRaysEffect")
	sunRays.Name = "StreetLegalSunRays"
	sunRays.Intensity = 0.045
	sunRays.Spread = 0.62
	sunRays.Parent = Lighting

	local colorCorrection = Lighting:FindFirstChild("StreetLegalColorCorrection") or Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "StreetLegalColorCorrection"
	colorCorrection.Brightness = 0.01
	colorCorrection.Contrast = 0.06
	colorCorrection.Saturation = -0.02
	colorCorrection.TintColor = Color3.fromRGB(255, 246, 234)
	colorCorrection.Parent = Lighting
end

local function makePart(parent, name, size, cframe, color, material, options)
	local part = Instance.new((options and options.ClassName) or "Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color or Color3.fromRGB(255, 255, 255)
	part.Material = material or Enum.Material.Concrete
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = if options and options.CanCollide ~= nil then options.CanCollide else true
	part.Transparency = options and options.Transparency or 0
	part.CastShadow = if options and options.CastShadow ~= nil then options.CastShadow else true
	if part:IsA("Part") and options and options.Shape then
		part.Shape = options.Shape
	end
	part.Parent = parent
	return part
end

local function tagSurface(part, district, surfaceType)
	part:SetAttribute("District", district)
	part:SetAttribute("SurfaceType", surfaceType)
	return part
end

local function tagNearMiss(part, district)
	part:SetAttribute("District", district)
	part:SetAttribute("NearMissTarget", true)
	return part
end

local function makeRoad(name, size, cframe, district)
	return tagSurface(makePart(sections.Roads, name, size, cframe, Color3.fromRGB(37, 41, 46), Enum.Material.Asphalt), district, "Street")
end

local function makeSidewalk(name, size, cframe, district)
	return tagSurface(makePart(sections.Roads, name, size, cframe, Color3.fromRGB(148, 148, 152), Enum.Material.Concrete), district, "Sidewalk")
end

local function makeTrim(parent, name, size, cframe, color, material, district)
	return tagNearMiss(makePart(parent, name, size, cframe, color, material or Enum.Material.Metal), district)
end

local function addSurfaceGui(part, text, accent)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.AlwaysOnTop = false
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = accent or Color3.fromRGB(245, 245, 245)
	label.Parent = gui
end

local function makeLaneStripe(name, size, cframe)
	local stripe = makePart(sections.Roads, name, size, cframe, Color3.fromRGB(245, 214, 114), Enum.Material.Neon, {
		CanCollide = false,
		CastShadow = false,
	})
	stripe:SetAttribute("SurfaceType", "Street")
	return stripe
end

local function addRoadMarkingsVertical(x, zMin, zMax)
	for z = zMin, zMax, 54 do
		makeLaneStripe(string.format("StripeV_%d_%d", x, z), Vector3.new(0.6, 0.05, 20), CFrame.new(x, 0.62, z))
	end
end

local function addRoadMarkingsHorizontal(z, xMin, xMax)
	for x = xMin, xMax, 54 do
		makeLaneStripe(string.format("StripeH_%d_%d", z, x), Vector3.new(20, 0.05, 0.6), CFrame.new(x, 0.62, z))
	end
end

local function addCrosswalk(position, orientation)
	for i = -5, 5 do
		local offset = i * 2.6
		local size = orientation == "X" and Vector3.new(2.2, 0.06, 12) or Vector3.new(12, 0.06, 2.2)
		local cframe = orientation == "X"
			and CFrame.new(position + Vector3.new(offset, 0.63, 0))
			or CFrame.new(position + Vector3.new(0, 0.63, offset))
		makePart(sections.Roads, string.format("Crosswalk_%s_%d", orientation, i), size, cframe, Color3.fromRGB(235, 235, 235), Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CastShadow = false,
		})
	end
end

local function makeTree(position, district, scale)
	scale = scale or 1
	local trunk = makePart(sections.Props, "TreeTrunk", Vector3.new(2 * scale, 15 * scale, 2 * scale), CFrame.new(position + Vector3.new(0, 7.5 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(93, 67, 45), Enum.Material.Wood, { Shape = Enum.PartType.Cylinder })
	tagNearMiss(trunk, district)
	for index, offset in ipairs({
		Vector3.new(0, 18, 0),
		Vector3.new(-3.6, 16, 2.4),
		Vector3.new(3.6, 16, -2.4),
		Vector3.new(0, 14, -4),
	}) do
		local crown = makePart(sections.Props, "TreeCrown" .. tostring(index), Vector3.new(9 * scale, 8 * scale, 9 * scale), CFrame.new(position + (offset * scale)), Color3.fromRGB(68, 126, 77), Enum.Material.Grass, { Shape = Enum.PartType.Ball })
		tagNearMiss(crown, district)
	end
end

local function makeLightPole(position, district, height)
	height = height or 16
	local pole = makePart(sections.Props, "LightPole", Vector3.new(0.8, height, 0.8), CFrame.new(position + Vector3.new(0, height * 0.5, 0)), Color3.fromRGB(52, 55, 60), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	tagNearMiss(pole, district)
	local arm = makePart(sections.Props, "LightArm", Vector3.new(0.5, 0.5, 5), CFrame.new(position + Vector3.new(0, height - 1.5, -2.3)), Color3.fromRGB(76, 79, 84), Enum.Material.Metal)
	tagNearMiss(arm, district)
	local lamp = makePart(sections.Props, "Lamp", Vector3.new(1.6, 0.4, 1.6), CFrame.new(position + Vector3.new(0, height - 1.8, -4.4)), Color3.fromRGB(255, 230, 174), Enum.Material.Neon, { CanCollide = false })
	lamp:SetAttribute("District", district)
end

local function makeBench(position, district, yaw)
	yaw = yaw or 0
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
	local seat = makePart(sections.Props, "BenchSeat", Vector3.new(5.5, 0.4, 1.4), cf * CFrame.new(0, 1.3, 0), Color3.fromRGB(126, 90, 61), Enum.Material.Wood)
	tagNearMiss(seat, district)
	local back = makePart(sections.Props, "BenchBack", Vector3.new(5.5, 1.4, 0.35), cf * CFrame.new(0, 2.15, 0.52), Color3.fromRGB(126, 90, 61), Enum.Material.Wood)
	tagNearMiss(back, district)
	for _, x in ipairs({ -2.1, 2.1 }) do
		local leg = makePart(sections.Props, "BenchLeg", Vector3.new(0.35, 1.4, 0.35), cf * CFrame.new(x, 0.6, 0), Color3.fromRGB(52, 55, 60), Enum.Material.Metal)
		tagNearMiss(leg, district)
	end
end

local function makePlanter(position, district, size, plantScale)
	size = size or Vector3.new(10, 2, 10)
	plantScale = plantScale or 0.9
	local base = makePart(sections.Props, "PlanterBase", size, CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)), Color3.fromRGB(132, 138, 145), Enum.Material.Concrete)
	tagNearMiss(base, district)
	makeTree(position + Vector3.new(0, size.Y, 0), district, plantScale)
end

local function makeParkedCar(position, district, color, yaw)
	yaw = yaw or 0
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
	local body = makePart(sections.Props, "ParkedCarBody", Vector3.new(8, 1.6, 16), cf * CFrame.new(0, 2.1, 0), color, Enum.Material.SmoothPlastic)
	tagNearMiss(body, district)
	local cabin = makePart(sections.Props, "ParkedCarCabin", Vector3.new(6, 1.9, 7.5), cf * CFrame.new(0, 3.4, -1), Color3.fromRGB(189, 208, 224), Enum.Material.Glass, { Transparency = 0.25 })
	tagNearMiss(cabin, district)
	for _, wheelOffset in ipairs({
		Vector3.new(-3.3, 1.1, -5.2), Vector3.new(3.3, 1.1, -5.2),
		Vector3.new(-3.3, 1.1, 5.2), Vector3.new(3.3, 1.1, 5.2),
	}) do
		local wheel = makePart(sections.Props, "CarWheel", Vector3.new(1.3, 2.4, 2.4), cf * CFrame.new(wheelOffset) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(18, 18, 18), Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
		tagNearMiss(wheel, district)
	end
end

local function makeRowhouse(basePosition, district, width, depth, height, bodyColor, trimColor)
	local body = makePart(sections.Buildings, "RowhouseBody", Vector3.new(width, height, depth), CFrame.new(basePosition + Vector3.new(0, height * 0.5, 0)), bodyColor, Enum.Material.Brick)
	tagNearMiss(body, district)
	local roof = makePart(sections.Buildings, "RowhouseRoof", Vector3.new(width + 1, 1.4, depth + 1), CFrame.new(basePosition + Vector3.new(0, height + 0.7, 0)), palettes.RedlineRow.Roof, Enum.Material.Slate)
	tagNearMiss(roof, district)
	local cornice = makePart(sections.Buildings, "RowhouseCornice", Vector3.new(width + 1.2, 0.5, 1), CFrame.new(basePosition + Vector3.new(0, height - 0.1, -(depth * 0.5) - 0.45)), trimColor, Enum.Material.Wood)
	tagNearMiss(cornice, district)
	local stoopBase = makePart(sections.Props, "StoopBase", Vector3.new(width * 0.48, 1.4, 4.5), CFrame.new(basePosition + Vector3.new(0, 0.7, -(depth * 0.5) - 2.2)), trimColor, Enum.Material.Concrete)
	tagNearMiss(stoopBase, district)
	for step = 1, 3 do
		local stepPart = makePart(sections.Props, "StoopStep", Vector3.new(width * 0.42, 0.4, 1.2), CFrame.new(basePosition + Vector3.new(0, 0.2 * step, -(depth * 0.5) - 4.8 + (step * 1.2))), Color3.fromRGB(171, 162, 150), Enum.Material.Concrete)
		tagNearMiss(stepPart, district)
	end
	local door = makePart(sections.Buildings, "Door", Vector3.new(2.1, 4, 0.2), CFrame.new(basePosition + Vector3.new(0, 2.2, -(depth * 0.5) - 0.12)), Color3.fromRGB(69, 45, 31), Enum.Material.Wood)
	tagNearMiss(door, district)
	for _, x in ipairs({ -(width * 0.24), width * 0.24 }) do
		for _, y in ipairs({ 3.2, 7.1 }) do
			local window = makePart(sections.Buildings, "Window", Vector3.new(2.1, 2.2, 0.2), CFrame.new(basePosition + Vector3.new(x, y, -(depth * 0.5) - 0.16)), palettes.RedlineRow.Window, Enum.Material.Glass, { Transparency = 0.18 })
			tagNearMiss(window, district)
		end
	end
end

local function makeMidrise(basePosition, district, width, depth, height, bodyColor, accentColor)
	local body = makePart(sections.Buildings, "MidriseBody", Vector3.new(width, height, depth), CFrame.new(basePosition + Vector3.new(0, height * 0.5, 0)), bodyColor, Enum.Material.Concrete)
	tagNearMiss(body, district)
	local crown = makePart(sections.Buildings, "MidriseCrown", Vector3.new(width + 2, 2.2, depth + 2), CFrame.new(basePosition + Vector3.new(0, height + 1.1, 0)), palettes.PennMarket.Roof, Enum.Material.Metal)
	tagNearMiss(crown, district)
	local podium = makePart(sections.Buildings, "MidrisePodium", Vector3.new(width + 8, 8, depth + 8), CFrame.new(basePosition + Vector3.new(0, 4, 0)), Color3.fromRGB(90, 92, 97), Enum.Material.Concrete)
	tagNearMiss(podium, district)
	for _, x in ipairs({ -(width * 0.33), 0, width * 0.33 }) do
		local windowBand = makePart(sections.Buildings, "WindowBand", Vector3.new(width * 0.16, height - 10, 0.25), CFrame.new(basePosition + Vector3.new(x, height * 0.56, -(depth * 0.5) - 0.15)), palettes.PennMarket.Window, Enum.Material.Glass, { Transparency = 0.2 })
		tagNearMiss(windowBand, district)
	end
	local entry = makePart(sections.Buildings, "TowerEntry", Vector3.new(width * 0.42, 6, 1), CFrame.new(basePosition + Vector3.new(0, 3.2, -(depth * 0.5) - 0.5)), accentColor, Enum.Material.Metal)
	tagNearMiss(entry, district)
end

local function makeWarehouse(basePosition, district, width, depth, height, bodyColor, accentColor)
	local shell = makePart(sections.Buildings, "WarehouseShell", Vector3.new(width, height, depth), CFrame.new(basePosition + Vector3.new(0, height * 0.5, 0)), bodyColor, Enum.Material.Metal)
	tagNearMiss(shell, district)
	local roof = makePart(sections.Buildings, "WarehouseRoof", Vector3.new(width + 2, 1.6, depth + 2), CFrame.new(basePosition + Vector3.new(0, height + 0.8, 0)), palettes.IronHarbor.Roof, Enum.Material.Metal)
	tagNearMiss(roof, district)
	for _, x in ipairs({ -(width * 0.28), 0, width * 0.28 }) do
		local door = makePart(sections.Buildings, "WarehouseDoor", Vector3.new(width * 0.18, height * 0.42, 0.4), CFrame.new(basePosition + Vector3.new(x, height * 0.22, -(depth * 0.5) - 0.2)), Color3.fromRGB(55, 59, 64), Enum.Material.Metal)
		tagNearMiss(door, district)
	end
	local stripe = makePart(sections.Buildings, "WarehouseStripe", Vector3.new(width + 0.5, 1.2, 0.3), CFrame.new(basePosition + Vector3.new(0, height * 0.72, -(depth * 0.5) - 0.16)), accentColor, Enum.Material.Neon)
	tagNearMiss(stripe, district)
end

local function makeCrane(basePosition, district)
	local mast = makePart(sections.Props, "CraneMast", Vector3.new(6, 54, 6), CFrame.new(basePosition + Vector3.new(0, 27, 0)), Color3.fromRGB(198, 151, 56), Enum.Material.Metal)
	tagNearMiss(mast, district)
	local boom = makePart(sections.Props, "CraneBoom", Vector3.new(72, 4, 4), CFrame.new(basePosition + Vector3.new(28, 49, 0)), Color3.fromRGB(214, 168, 62), Enum.Material.Metal)
	tagNearMiss(boom, district)
	local hook = makePart(sections.Props, "CraneHook", Vector3.new(1, 18, 1), CFrame.new(basePosition + Vector3.new(54, 38, 0)), Color3.fromRGB(55, 58, 62), Enum.Material.Metal)
	tagNearMiss(hook, district)
end

local function makePier(basePosition, district, width, depth)
	local deck = makePart(sections.Waterfront, "PierDeck", Vector3.new(width, 2, depth), CFrame.new(basePosition + Vector3.new(0, 1, 0)), Color3.fromRGB(118, 99, 71), Enum.Material.WoodPlanks)
	tagNearMiss(deck, district)
	for x = -(width * 0.5) + 8, (width * 0.5) - 8, 20 do
		for _, z in ipairs({ -(depth * 0.5) + 4, (depth * 0.5) - 4 }) do
			local post = makePart(sections.Waterfront, "PierPost", Vector3.new(2.2, 10, 2.2), CFrame.new(basePosition + Vector3.new(x, -4, z)), Color3.fromRGB(77, 61, 44), Enum.Material.Wood)
			tagNearMiss(post, district)
		end
	end
end

local function makeBerm(position, district, size, yaw)
	yaw = yaw or 0
	local mound = makePart(sections.Ground, "Berm", size, CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)) * CFrame.Angles(0, math.rad(yaw), 0), Color3.fromRGB(124, 95, 59), Enum.Material.Ground)
	tagSurface(mound, district, "OffRoad")
end

local function makeRock(position, district, size)
	local rock = makePart(sections.Props, "Rock", size, CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)), Color3.fromRGB(108, 99, 91), Enum.Material.Slate)
	tagNearMiss(rock, district)
end

local function makeDistrictPlate(district)
	local palette = palettes[district.Name]
	local plate = makePart(sections.Ground, district.Name, district.Size, CFrame.new(district.Position), palette and palette.Ground or Config.World.DistrictColors[district.Name], district.Material or Enum.Material.Concrete)
	tagSurface(plate, district.Name, district.Surface)
	local halo = makePart(sections.Ground, district.Name .. "Halo", Vector3.new(district.Size.X - 20, 0.4, district.Size.Z - 20), CFrame.new(district.Position + Vector3.new(0, 0.85, 0)), palette and palette.Trim or Color3.fromRGB(180, 180, 180), Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 0.92,
		CastShadow = false,
	})
	halo:SetAttribute("District", district.Name)
end

local function makeSpawnLot(spawnDef)
	local palette = palettes[spawnDef.District] or palettes.City
	local baseCFrame = CFrame.new(spawnDef.Position) * CFrame.Angles(0, math.rad(spawnDef.Heading or 0), 0)
	local lot = makePart(sections.Props, spawnDef.Name .. "Lot", Vector3.new(42, 0.6, 26), baseCFrame * CFrame.new(0, 0.3, 0), Color3.fromRGB(52, 54, 58), Enum.Material.Asphalt)
	tagSurface(lot, spawnDef.District, "Street")
	local padGlow = makePart(sections.Props, spawnDef.Name .. "PadGlow", Vector3.new(12, 0.16, 12), baseCFrame * CFrame.new(0, 0.69, 0), spawnDef.Color, Enum.Material.Neon, {
		CanCollide = false,
		Transparency = 0.18,
		CastShadow = false,
	})
	padGlow:SetAttribute("District", spawnDef.District)
	local awning = makePart(sections.Props, spawnDef.Name .. "Awning", Vector3.new(22, 0.8, 8), baseCFrame * CFrame.new(0, 5.4, -10), palette.Accent, Enum.Material.Metal)
	tagNearMiss(awning, spawnDef.District)
	local backWall = makePart(sections.Props, spawnDef.Name .. "Wall", Vector3.new(22, 9, 1.5), baseCFrame * CFrame.new(0, 4.5, -14), Color3.fromRGB(63, 66, 72), Enum.Material.Concrete)
	tagNearMiss(backWall, spawnDef.District)
	addSurfaceGui(backWall, spawnDef.Name, Color3.fromRGB(245, 245, 245))
	for offset = -12, 12, 8 do
		makeLightPole((baseCFrame * CFrame.new(offset, 0, 14)).Position, spawnDef.District, 13)
	end
end

applyLighting()

makePart(sections.Ground, "VoidPlate", Vector3.new(2400, 8, 2400), CFrame.new(0, -6, 0), Color3.fromRGB(65, 67, 72), Enum.Material.Concrete)
makePart(sections.Background, "SeaPlate", Vector3.new(760, 18, 2200), CFrame.new(1080, Config.World.WaterLevel - 1, 0), Color3.fromRGB(43, 92, 130), Enum.Material.Water)
makePart(sections.Waterfront, "HarborWater", Vector3.new(420, 14, 1800), CFrame.new(900, Config.World.WaterLevel, 0), Color3.fromRGB(41, 97, 141), Enum.Material.Water)
makePart(sections.Waterfront, "CanalWater", Vector3.new(510, 11, 54), CFrame.new(390, Config.World.WaterLevel + 0.4, -310), Color3.fromRGB(55, 114, 156), Enum.Material.Water)
makePart(sections.Background, "BackdropWest", Vector3.new(40, 120, 2000), CFrame.new(-1090, 55, 0), Color3.fromRGB(74, 83, 95), Enum.Material.Slate)
makePart(sections.Background, "BackdropNorth", Vector3.new(2200, 100, 40), CFrame.new(0, 45, -1090), Color3.fromRGB(92, 106, 117), Enum.Material.Slate)
makePart(sections.Background, "BackdropSouth", Vector3.new(2200, 80, 40), CFrame.new(0, 35, 1090), Color3.fromRGB(114, 104, 92), Enum.Material.Slate)

for _, district in ipairs(districtDefs) do
	makeDistrictPlate(district)
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
	makeSidewalk("AvenueSidewalkL_" .. tostring(x), Vector3.new(10, 1, 1840), CFrame.new(x - 26, 0.3, 0), district)
	makeSidewalk("AvenueSidewalkR_" .. tostring(x), Vector3.new(10, 1, 1840), CFrame.new(x + 26, 0.3, 0), district)
	makePart(sections.Roads, "AvenueCurbL_" .. tostring(x), Vector3.new(1.2, 0.6, 1840), CFrame.new(x - 20.8, 0.55, 0), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete)
	makePart(sections.Roads, "AvenueCurbR_" .. tostring(x), Vector3.new(1.2, 0.6, 1840), CFrame.new(x + 20.8, 0.55, 0), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete)
	addRoadMarkingsVertical(x, -840, 840)
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
	makeSidewalk("StreetSidewalkTop_" .. tostring(z), Vector3.new(1840, 1, 10), CFrame.new(0, 0.3, z - 26), district)
	makeSidewalk("StreetSidewalkBottom_" .. tostring(z), Vector3.new(1840, 1, 10), CFrame.new(0, 0.3, z + 26), district)
	makePart(sections.Roads, "StreetCurbTop_" .. tostring(z), Vector3.new(1840, 0.6, 1.2), CFrame.new(0, 0.55, z - 20.8), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete)
	makePart(sections.Roads, "StreetCurbBottom_" .. tostring(z), Vector3.new(1840, 0.6, 1.2), CFrame.new(0, 0.55, z + 20.8), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete)
	addRoadMarkingsHorizontal(z, -840, 840)
end

for _, position in ipairs({
	Vector3.new(-540, 0, -300), Vector3.new(-300, 0, -300), Vector3.new(-60, 0, -300),
	Vector3.new(-60, 0, -60), Vector3.new(180, 0, -60), Vector3.new(420, 0, 180),
	Vector3.new(660, 0, -300), Vector3.new(-540, 0, 420),
}) do
	addCrosswalk(position, "X")
	addCrosswalk(position, "Z")
end

for z = -780, 780, 180 do
	makeLightPole(Vector3.new(-808, 0, z), "RedlineRow")
	makeLightPole(Vector3.new(-272, 0, z), "PennMarket")
	makeLightPole(Vector3.new(248, 0, z), "PennMarket")
	makeLightPole(Vector3.new(508, 0, z), "IronHarbor")
	makeLightPole(Vector3.new(688, 0, z), "CanalSide")
end

makeRoad("HarborExpress", Vector3.new(900, 1, 28), CFrame.new(40, 34, 480), "PennMarket")
makePart(sections.Roads, "HarborExpressMedian", Vector3.new(900, 0.35, 2), CFrame.new(40, 34.55, 480), Color3.fromRGB(238, 214, 104), Enum.Material.Neon, { CanCollide = false })
for _, offset in ipairs({ -190, -70, 70, 190 }) do
	makePart(sections.Props, "ExpressSupport" .. tostring(offset), Vector3.new(16, 34, 16), CFrame.new(offset, 17, 480), Color3.fromRGB(112, 112, 118), Enum.Material.Concrete)
	makePart(sections.Props, "SupportBase" .. tostring(offset), Vector3.new(24, 3, 24), CFrame.new(offset, 1.5, 480), Color3.fromRGB(92, 92, 96), Enum.Material.Concrete)
end
for x = -380, 460, 120 do
	makePart(sections.Roads, "ExpressBarrierL" .. tostring(x), Vector3.new(10, 3, 1), CFrame.new(x, 35.6, 466), Color3.fromRGB(188, 188, 192), Enum.Material.Concrete)
	makePart(sections.Roads, "ExpressBarrierR" .. tostring(x), Vector3.new(10, 3, 1), CFrame.new(x, 35.6, 494), Color3.fromRGB(188, 188, 192), Enum.Material.Concrete)
end

makePart(sections.Waterfront, "CanalFloor", Vector3.new(520, 3, 66), CFrame.new(390, -9.5, -310), Color3.fromRGB(118, 121, 124), Enum.Material.Concrete)
local canalLeft = makePart(sections.Waterfront, "CanalLeftWall", Vector3.new(520, 18, 8), CFrame.new(390, -0.5, -281), Color3.fromRGB(153, 156, 162), Enum.Material.Concrete)
local canalRight = makePart(sections.Waterfront, "CanalRightWall", Vector3.new(520, 18, 8), CFrame.new(390, -0.5, -339), Color3.fromRGB(153, 156, 162), Enum.Material.Concrete)
tagNearMiss(canalLeft, "CanalSide")
tagNearMiss(canalRight, "CanalSide")
makePart(sections.Waterfront, "CanalPromenadeNorth", Vector3.new(520, 2, 18), CFrame.new(390, 1, -260), Color3.fromRGB(128, 138, 144), Enum.Material.Concrete)
makePart(sections.Waterfront, "CanalPromenadeSouth", Vector3.new(520, 2, 18), CFrame.new(390, 1, -360), Color3.fromRGB(128, 138, 144), Enum.Material.Concrete)
for x = 150, 610, 46 do
	makePart(sections.Waterfront, "CanalRailNorth" .. tostring(x), Vector3.new(1.2, 3, 1.2), CFrame.new(x, 2.5, -270), Color3.fromRGB(68, 72, 77), Enum.Material.Metal)
	makePart(sections.Waterfront, "CanalRailSouth" .. tostring(x), Vector3.new(1.2, 3, 1.2), CFrame.new(x, 2.5, -350), Color3.fromRGB(68, 72, 77), Enum.Material.Metal)
	if x < 610 then
		makePart(sections.Waterfront, "CanalRailBeamNorth" .. tostring(x), Vector3.new(46, 0.35, 0.4), CFrame.new(x + 23, 3.5, -270), Color3.fromRGB(102, 111, 118), Enum.Material.Metal)
		makePart(sections.Waterfront, "CanalRailBeamSouth" .. tostring(x), Vector3.new(46, 0.35, 0.4), CFrame.new(x + 23, 3.5, -350), Color3.fromRGB(102, 111, 118), Enum.Material.Metal)
	end
end

makePart(sections.Waterfront, "HarborBulkhead", Vector3.new(28, 22, 1800), CFrame.new(762, 2, 0), Color3.fromRGB(108, 114, 120), Enum.Material.Concrete)
makePart(sections.Waterfront, "HarborWalk", Vector3.new(90, 2, 900), CFrame.new(714, 1, -180), Color3.fromRGB(124, 129, 133), Enum.Material.Concrete)
makePier(Vector3.new(800, 0, 210), "IronHarbor", 130, 52)
makePier(Vector3.new(790, 0, -120), "CanalSide", 110, 44)
for z = -520, 120, 160 do
	makeLightPole(Vector3.new(748, 0, z), "CanalSide", 15)
	makeBench(Vector3.new(712, 0, z + 30), "CanalSide", 90)
end

for x = -760, -400, 40 do
	for z = -230, 430, 132 do
		local width = 22 + ((math.abs(x + z) % 3) * 2)
		local height = 20 + ((math.abs((x / 20) - (z / 15)) % 3) * 6)
		local bodyTone = ({
			Color3.fromRGB(136, 89, 74),
			Color3.fromRGB(154, 102, 82),
			Color3.fromRGB(121, 74, 60),
			Color3.fromRGB(170, 114, 84),
		})[((math.abs(x + z) / 2) % 4) + 1]
		makeRowhouse(Vector3.new(x, 0, z), "RedlineRow", width, 42, height, bodyTone, palettes.RedlineRow.Trim)
	end
	makeParkedCar(Vector3.new(x + 14, 0, -345), "RedlineRow", Color3.fromRGB(185, 61, 56), 90)
end

local cornerStore = makePart(sections.Buildings, "CornerStore", Vector3.new(44, 18, 52), CFrame.new(-412, 9, -332), Color3.fromRGB(126, 83, 64), Enum.Material.Brick)
tagNearMiss(cornerStore, "RedlineRow")
local storeSign = makePart(sections.Buildings, "CornerStoreSign", Vector3.new(26, 4, 1), CFrame.new(-412, 13, -358.6), palettes.RedlineRow.Accent, Enum.Material.Neon)
tagNearMiss(storeSign, "RedlineRow")
addSurfaceGui(storeSign, "REDLINE MART", Color3.fromRGB(255, 248, 226))

for _, tower in ipairs({
	{ Position = Vector3.new(-120, 0, -180), Width = 84, Depth = 84, Height = 56, Accent = palettes.PennMarket.Accent },
	{ Position = Vector3.new(40, 0, -120), Width = 78, Depth = 74, Height = 82, Accent = Color3.fromRGB(114, 193, 244) },
	{ Position = Vector3.new(140, 0, 20), Width = 72, Depth = 72, Height = 68, Accent = palettes.PennMarket.Accent },
	{ Position = Vector3.new(-100, 0, 120), Width = 88, Depth = 88, Height = 52, Accent = Color3.fromRGB(255, 194, 104) },
	{ Position = Vector3.new(80, 0, 180), Width = 92, Depth = 80, Height = 74, Accent = Color3.fromRGB(115, 223, 246) },
}) do
	makeMidrise(tower.Position, "PennMarket", tower.Width, tower.Depth, tower.Height, Color3.fromRGB(106, 111, 120), tower.Accent)
end

makePart(sections.Ground, "PennPlaza", Vector3.new(110, 2, 86), CFrame.new(14, 1, 274), Color3.fromRGB(136, 138, 145), Enum.Material.Concrete)
for _, offset in ipairs({ Vector3.new(-28, 0, -18), Vector3.new(28, 0, -18), Vector3.new(-28, 0, 18), Vector3.new(28, 0, 18) }) do
	makePlanter(Vector3.new(14, 0, 274) + offset, "PennMarket", Vector3.new(16, 2.2, 16), 0.75)
end
makeBench(Vector3.new(-14, 0, 274), "PennMarket", 0)
makeBench(Vector3.new(42, 0, 274), "PennMarket", 180)
makeParkedCar(Vector3.new(-44, 0, 228), "PennMarket", Color3.fromRGB(78, 130, 196), 0)
makeParkedCar(Vector3.new(72, 0, 228), "PennMarket", Color3.fromRGB(222, 181, 73), 0)

makePart(sections.Ground, "DruidGreen", Vector3.new(860, 2, 300), CFrame.new(-180, 0, -640), Color3.fromRGB(72, 127, 82), Enum.Material.Grass)
makePart(sections.Ground, "DruidPathNorth", Vector3.new(520, 1, 12), CFrame.new(-180, 0.4, -700), Color3.fromRGB(176, 170, 157), Enum.Material.Concrete)
makePart(sections.Ground, "DruidPathSouth", Vector3.new(620, 1, 12), CFrame.new(-160, 0.4, -596), Color3.fromRGB(176, 170, 157), Enum.Material.Concrete)
makePart(sections.Ground, "SkatePad", Vector3.new(180, 1, 96), CFrame.new(-270, 0.45, -688), Color3.fromRGB(112, 118, 122), Enum.Material.Concrete)
for x = -520, 130, 80 do
	makeTree(Vector3.new(x, 0, -736), "DruidHeights", 1)
end
for _, offset in ipairs({ Vector3.new(-100, 0, -635), Vector3.new(20, 0, -652), Vector3.new(160, 0, -670) }) do
	makePlanter(Vector3.new(-180, 0, -640) + offset, "DruidHeights", Vector3.new(14, 2.2, 14), 0.72)
end
makeBench(Vector3.new(-350, 0, -610), "DruidHeights", 30)
makeBench(Vector3.new(-80, 0, -718), "DruidHeights", -25)
makeBerm(Vector3.new(140, 0, -730), "DruidHeights", Vector3.new(120, 18, 70), 24)
makeBerm(Vector3.new(-520, 0, -560), "DruidHeights", Vector3.new(96, 12, 64), -16)

for _, yard in ipairs({
	{ Position = Vector3.new(360, 0, 120), Width = 110, Depth = 88, Height = 26 },
	{ Position = Vector3.new(510, 0, 130), Width = 120, Depth = 82, Height = 30 },
	{ Position = Vector3.new(680, 0, 120), Width = 104, Depth = 92, Height = 24 },
	{ Position = Vector3.new(360, 0, 320), Width = 128, Depth = 80, Height = 26 },
	{ Position = Vector3.new(540, 0, 330), Width = 120, Depth = 90, Height = 30 },
	{ Position = Vector3.new(700, 0, 320), Width = 108, Depth = 84, Height = 28 },
}) do
	makeWarehouse(yard.Position, "IronHarbor", yard.Width, yard.Depth, yard.Height, Color3.fromRGB(86, 92, 98), palettes.IronHarbor.Accent)
end

makeCrane(Vector3.new(610, 0, 535), "IronHarbor")
makeCrane(Vector3.new(760, 0, 420), "IronHarbor")
for x = 360, 760, 100 do
	makePart(sections.Props, "HarborFencePost" .. tostring(x), Vector3.new(1.2, 4, 1.2), CFrame.new(x, 2, 566), Color3.fromRGB(86, 89, 94), Enum.Material.Metal)
	if x < 760 then
		makePart(sections.Props, "HarborFenceRail" .. tostring(x), Vector3.new(100, 0.3, 0.3), CFrame.new(x + 50, 3.6, 566), Color3.fromRGB(122, 126, 132), Enum.Material.Metal)
	end
end
for z = 120, 500, 110 do
	makeParkedCar(Vector3.new(760, 0, z), "IronHarbor", Color3.fromRGB(92, 157, 220), 90)
end

for _, loft in ipairs({
	{ Position = Vector3.new(250, 0, -160), Width = 92, Depth = 74, Height = 36 },
	{ Position = Vector3.new(520, 0, -110), Width = 98, Depth = 82, Height = 34 },
	{ Position = Vector3.new(680, 0, -120), Width = 88, Depth = 72, Height = 30 },
	{ Position = Vector3.new(520, 0, -470), Width = 120, Depth = 88, Height = 44 },
}) do
	makeMidrise(loft.Position, "CanalSide", loft.Width, loft.Depth, loft.Height, Color3.fromRGB(88, 104, 118), palettes.CanalSide.Accent)
end

makePart(sections.Waterfront, "BoardwalkDeck", Vector3.new(120, 2, 250), CFrame.new(760, 1, -100), Color3.fromRGB(121, 104, 74), Enum.Material.WoodPlanks)
for z = -200, 0, 40 do
	makeLightPole(Vector3.new(804, 0, z), "CanalSide", 14)
	makeBench(Vector3.new(728, 0, z + 12), "CanalSide", 90)
end
for _, patch in ipairs({ Vector3.new(615, 0, -405), Vector3.new(708, 0, -380), Vector3.new(728, 0, -60) }) do
	makePlanter(patch, "CanalSide", Vector3.new(18, 2, 12), 0.68)
end

makePart(sections.Ground, "QuarryDirt", Vector3.new(460, 2, 560), CFrame.new(-720, 0, 580), Color3.fromRGB(128, 96, 62), Enum.Material.Ground)
makeBerm(Vector3.new(-800, 0, 470), "QuarryRun", Vector3.new(120, 18, 110), 0)
makeBerm(Vector3.new(-650, 0, 610), "QuarryRun", Vector3.new(136, 20, 120), 28)
makeBerm(Vector3.new(-710, 0, 760), "QuarryRun", Vector3.new(96, 16, 80), -20)
for _, rock in ipairs({
	Vector3.new(-842, 0, 410), Vector3.new(-792, 0, 688), Vector3.new(-618, 0, 432),
	Vector3.new(-560, 0, 740), Vector3.new(-724, 0, 548),
}) do
	makeRock(rock, "QuarryRun", Vector3.new(16, 12, 14))
end
for _, treePos in ipairs({ Vector3.new(-540, 0, 474), Vector3.new(-884, 0, 560), Vector3.new(-570, 0, 794) }) do
	makeTree(treePos, "QuarryRun", 0.85)
end
local trailShed = makePart(sections.Props, "TrailShed", Vector3.new(34, 14, 24), CFrame.new(-848, 7, 612), Color3.fromRGB(102, 87, 62), Enum.Material.WoodPlanks)
tagNearMiss(trailShed, "QuarryRun")
local trailSign = makePart(sections.Props, "TrailSign", Vector3.new(14, 5, 1), CFrame.new(-848, 8, 624), palettes.QuarryRun.Accent, Enum.Material.Neon)
addSurfaceGui(trailSign, "QUARRY RUN", Color3.fromRGB(57, 42, 24))

local signDefs = {
	{ Text = "REDLINE ROW", District = "RedlineRow", Position = Vector3.new(-650, 8, -350) },
	{ Text = "PENN MARKET", District = "PennMarket", Position = Vector3.new(-40, 8, -350) },
	{ Text = "DRUID HEIGHTS", District = "DruidHeights", Position = Vector3.new(-180, 8, -760) },
	{ Text = "IRON HARBOR", District = "IronHarbor", Position = Vector3.new(560, 8, 580) },
	{ Text = "CANAL SIDE", District = "CanalSide", Position = Vector3.new(760, 8, -470) },
	{ Text = "QUARRY RUN", District = "QuarryRun", Position = Vector3.new(-790, 8, 790) },
}

for _, sign in ipairs(signDefs) do
	local palette = palettes[sign.District] or palettes.City
	local post = makePart(sections.DistrictSigns, sign.Text .. "_Post", Vector3.new(3.2, 16, 1.2), CFrame.new(sign.Position), Color3.fromRGB(47, 49, 54), Enum.Material.Metal)
	tagNearMiss(post, sign.District)
	local board = makePart(sections.DistrictSigns, sign.Text .. "_Board", Vector3.new(20, 8, 1.2), CFrame.new(sign.Position + Vector3.new(0, 6, 0)), palette.Accent, Enum.Material.Metal)
	tagNearMiss(board, sign.District)
	addSurfaceGui(board, sign.Text, Color3.fromRGB(253, 249, 238))
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

makePart(policeGenerated, "StationBase", Vector3.new(92, 2, 64), CFrame.new(315, 1, -45), Color3.fromRGB(132, 132, 142), Enum.Material.Concrete)
makePart(policeGenerated, "StationForecourt", Vector3.new(46, 1, 34), CFrame.new(315, 0.4, 8), Color3.fromRGB(48, 49, 54), Enum.Material.Asphalt)
makeMidrise(Vector3.new(315, 0, -45), "PennMarket", 74, 40, 24, Color3.fromRGB(92, 98, 108), Color3.fromRGB(96, 164, 220))
local stationSign = makePart(policeGenerated, "StationSign", Vector3.new(22, 5, 1), CFrame.new(315, 12, -66), Color3.fromRGB(85, 147, 214), Enum.Material.Neon)
addSurfaceGui(stationSign, "METRO POLICE", Color3.fromRGB(255, 255, 255))

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
	makeSpawnLot(spawnDef)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = spawnDef.Name
	spawn.Size = Vector3.new(12, 0.2, 12)
	spawn.CFrame = CFrame.new(spawnDef.Position + Vector3.new(0, 0.72, 0)) * CFrame.Angles(0, math.rad(spawnDef.Heading or 0), 0)
	spawn.Transparency = 0.82
	spawn.Color = spawnDef.Color
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CanCollide = false
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

local function obstacleColors(district)
	local palette = palettes[district] or palettes.City
	return {
		Base = palette.Accent,
		Trim = palette.Trim,
		Dark = palette.Roof,
	}
end

local function addRamp(obstacle)
	local colors = obstacleColors(obstacle.District)
	local ramp = Instance.new("WedgePart")
	ramp.Name = obstacle.Name
	ramp.Size = obstacle.Size
	ramp.CFrame = CFrame.new(obstacle.Position) * CFrame.Angles(math.rad(obstacle.Rotation.X), math.rad(obstacle.Rotation.Y), math.rad(obstacle.Rotation.Z))
	ramp.Color = colors.Base
	ramp.Material = Enum.Material.Metal
	ramp.Anchored = true
	ramp.Parent = rampsGenerated
	tagNearMiss(ramp, obstacle.District)
	makePart(rampsGenerated, obstacle.Name .. "Deck", Vector3.new(obstacle.Size.X, 1.2, obstacle.Size.Z * 0.4), ramp.CFrame * CFrame.new(0, obstacle.Size.Y * 0.36, obstacle.Size.Z * 0.28), colors.Dark, Enum.Material.Metal)
	makePart(rampsGenerated, obstacle.Name .. "TrimL", Vector3.new(0.6, obstacle.Size.Y, obstacle.Size.Z), ramp.CFrame * CFrame.new(-(obstacle.Size.X * 0.5) + 0.3, 0, 0), colors.Trim, Enum.Material.Metal)
	makePart(rampsGenerated, obstacle.Name .. "TrimR", Vector3.new(0.6, obstacle.Size.Y, obstacle.Size.Z), ramp.CFrame * CFrame.new((obstacle.Size.X * 0.5) - 0.3, 0, 0), colors.Trim, Enum.Material.Metal)
end

local function addStairSet(obstacle)
	for step = 1, 6 do
		local stepPart = makePart(rampsGenerated, obstacle.Name .. "_Step" .. tostring(step), Vector3.new(obstacle.Size.X, 1 + step, 4), CFrame.new(obstacle.Position + Vector3.new(0, (step * 0.5), (step * 4))), Color3.fromRGB(146, 146, 146), Enum.Material.Concrete)
		tagNearMiss(stepPart, obstacle.District)
	end
	makePart(rampsGenerated, obstacle.Name .. "RailL", Vector3.new(1, 6, 28), CFrame.new(obstacle.Position + Vector3.new(-(obstacle.Size.X * 0.5) - 1, 3.5, 14)), Color3.fromRGB(89, 93, 99), Enum.Material.Metal)
	makePart(rampsGenerated, obstacle.Name .. "RailR", Vector3.new(1, 6, 28), CFrame.new(obstacle.Position + Vector3.new((obstacle.Size.X * 0.5) + 1, 3.5, 14)), Color3.fromRGB(89, 93, 99), Enum.Material.Metal)
end

local function addGap(obstacle)
	local colors = obstacleColors(obstacle.District)
	makePart(rampsGenerated, obstacle.Name .. "_DeckA", Vector3.new(obstacle.Size.X * 0.4, 2, obstacle.Size.Z), CFrame.new(obstacle.Position + Vector3.new(-(obstacle.Size.X * 0.3), obstacle.Size.Y, 0)), colors.Dark, Enum.Material.Metal)
	makePart(rampsGenerated, obstacle.Name .. "_DeckB", Vector3.new(obstacle.Size.X * 0.4, 2, obstacle.Size.Z), CFrame.new(obstacle.Position + Vector3.new((obstacle.Size.X * 0.3), obstacle.Size.Y, 0)), colors.Dark, Enum.Material.Metal)
	addRamp({ Name = obstacle.Name .. "_Launch", Position = obstacle.Position + Vector3.new(-(obstacle.Size.X * 0.48), obstacle.Size.Y - 4, 0), Size = Vector3.new(18, 8, obstacle.Size.Z + 8), Rotation = Vector3.new(0, 90, 0), District = obstacle.District })
	addRamp({ Name = obstacle.Name .. "_Landing", Position = obstacle.Position + Vector3.new((obstacle.Size.X * 0.48), obstacle.Size.Y - 4, 0), Size = Vector3.new(18, 8, obstacle.Size.Z + 8), Rotation = Vector3.new(0, -90, 0), District = obstacle.District })
end

local function addCanalJump(obstacle)
	makePart(rampsGenerated, obstacle.Name .. "Arch", Vector3.new(32, 2, 116), CFrame.new(obstacle.Position + Vector3.new(0, 5.5, 0)), Color3.fromRGB(110, 117, 124), Enum.Material.Metal)
	addRamp({ Name = obstacle.Name .. "_WestRamp", Position = obstacle.Position + Vector3.new(-90, 4, 0), Size = Vector3.new(24, 12, 30), Rotation = Vector3.new(0, 90, 0), District = obstacle.District })
	addRamp({ Name = obstacle.Name .. "_EastRamp", Position = obstacle.Position + Vector3.new(90, 4, 0), Size = Vector3.new(24, 12, 30), Rotation = Vector3.new(0, -90, 0), District = obstacle.District })
end

local function addQuarterPipe(obstacle)
	addRamp(obstacle)
	local baseCf = CFrame.new(obstacle.Position) * CFrame.Angles(math.rad(obstacle.Rotation.X), math.rad(obstacle.Rotation.Y), math.rad(obstacle.Rotation.Z))
	makePart(rampsGenerated, obstacle.Name .. "_Deck", Vector3.new(obstacle.Size.X, 2, 20), CFrame.new(obstacle.Position + Vector3.new(0, obstacle.Size.Y * 0.8, obstacle.Size.Z * 0.35)), Color3.fromRGB(72, 76, 82), Enum.Material.Metal)
	makePart(rampsGenerated, obstacle.Name .. "_SideL", Vector3.new(1, obstacle.Size.Y, obstacle.Size.Z), baseCf * CFrame.new(-(obstacle.Size.X * 0.5) + 0.5, 0, 0), Color3.fromRGB(176, 181, 189), Enum.Material.Metal)
	makePart(rampsGenerated, obstacle.Name .. "_SideR", Vector3.new(1, obstacle.Size.Y, obstacle.Size.Z), baseCf * CFrame.new((obstacle.Size.X * 0.5) - 0.5, 0, 0), Color3.fromRGB(176, 181, 189), Enum.Material.Metal)
end

local function addDirtJump(obstacle)
	local dirt = Instance.new("WedgePart")
	dirt.Name = obstacle.Name
	dirt.Size = obstacle.Size
	dirt.CFrame = CFrame.new(obstacle.Position) * CFrame.Angles(0, math.rad(obstacle.Rotation.Y), 0)
	dirt.Color = Color3.fromRGB(137, 100, 62)
	dirt.Material = Enum.Material.Ground
	dirt.Anchored = true
	dirt.Parent = rampsGenerated
	tagNearMiss(dirt, obstacle.District)
	makePart(rampsGenerated, obstacle.Name .. "_Cap", Vector3.new(obstacle.Size.X, 0.5, obstacle.Size.Z * 0.2), dirt.CFrame * CFrame.new(0, obstacle.Size.Y * 0.42, obstacle.Size.Z * 0.28), Color3.fromRGB(171, 148, 97), Enum.Material.Ground)
end

local function addContainerStack(obstacle)
	local colors = {
		Color3.fromRGB(59, 105, 170),
		Color3.fromRGB(170, 94, 64),
		Color3.fromRGB(85, 129, 104),
	}
	for layer = 0, 2 do
		for column = -1, 1 do
			local container = makePart(rampsGenerated, obstacle.Name .. "_Container_" .. tostring(layer) .. "_" .. tostring(column), Vector3.new(22, 10, 10), CFrame.new(obstacle.Position + Vector3.new(column * 22, (layer * 10), layer % 2 == 0 and 0 or 11)) * CFrame.Angles(0, math.rad(obstacle.Rotation.Y or 0), 0), colors[(layer % #colors) + 1], Enum.Material.Metal)
			tagNearMiss(container, obstacle.District)
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
