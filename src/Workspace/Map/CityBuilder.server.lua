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

local RIDE_SURFACE_TOP_Y = 0.6
local EXPRESS_TOP_Y = 34.6
local ROAD_CENTERS_X = { -780, -540, -300, -60, 180, 420, 660 }
local ROAD_CENTERS_Z = { -780, -540, -300, -60, 180, 420, 660 }
local ROAD_RESERVATION_PADDING = 20
local BUILDING_CLEARANCE_BUFFER = 8

local surfaceAreas = {}
local roadReservations = {}
local lotReservations = {}

local function cframeWithTop(position, size, topY, rotationSource)
	local resolvedTopY = topY
	if resolvedTopY == nil then
		resolvedTopY = RIDE_SURFACE_TOP_Y
	end
	local targetPosition = Vector3.new(position.X, resolvedTopY - (size.Y * 0.5), position.Z)
	if rotationSource then
		return CFrame.fromMatrix(targetPosition, rotationSource.XVector, rotationSource.YVector, rotationSource.ZVector)
	end
	return CFrame.new(targetPosition)
end

local function rectFromCenter(position, size, bufferX, bufferZ)
	local xBuffer = bufferX or 0
	local zBuffer = bufferZ or xBuffer
	return {
		MinX = position.X - (size.X * 0.5) - xBuffer,
		MaxX = position.X + (size.X * 0.5) + xBuffer,
		MinZ = position.Z - (size.Z * 0.5) - zBuffer,
		MaxZ = position.Z + (size.Z * 0.5) + zBuffer,
	}
end

local function rectsOverlap(a, b)
	return a.MinX < b.MaxX and a.MaxX > b.MinX and a.MinZ < b.MaxZ and a.MaxZ > b.MinZ
end

local function reserveRect(list, name, position, size, bufferX, bufferZ)
	local rect = rectFromCenter(position, size, bufferX, bufferZ)
	rect.Name = name
	table.insert(list, rect)
	return rect
end

local function overlapsReservations(rect, reservations)
	local hits = {}
	for _, reserved in ipairs(reservations) do
		if rectsOverlap(rect, reserved) then
			table.insert(hits, reserved.Name)
		end
	end
	return #hits > 0, hits
end

local function registerSurfaceArea(name, position, size, topY, district, surfaceType)
	local area = rectFromCenter(position, size)
	area.Name = name
	area.TopY = topY
	area.District = district
	area.SurfaceType = surfaceType
	table.insert(surfaceAreas, area)
	return area
end

local function surfaceTopAt(x, z, defaultTopY)
	local topY = defaultTopY or 0
	for _, area in ipairs(surfaceAreas) do
		if x >= area.MinX and x <= area.MaxX and z >= area.MinZ and z <= area.MaxZ and area.TopY >= topY then
			topY = area.TopY
		end
	end
	return topY
end

local function snapToSurface(position, extraY)
	local topY = surfaceTopAt(position.X, position.Z, position.Y)
	return Vector3.new(position.X, topY + (extraY or 0), position.Z), topY
end

local function reserveLotOrWarn(name, position, size, bufferX, bufferZ)
	local lotRect = rectFromCenter(position, size, bufferX, bufferZ)
	local roadBlocked, roadHits = overlapsReservations(lotRect, roadReservations)
	if roadBlocked then
		warn(string.format("[StreetLegal] Skipped %s; overlaps road clearance: %s", name, table.concat(roadHits, ", ")))
		return false
	end

	local lotBlocked, lotHits = overlapsReservations(lotRect, lotReservations)
	if lotBlocked then
		warn(string.format("[StreetLegal] Skipped %s; overlaps reserved lot: %s", name, table.concat(lotHits, ", ")))
		return false
	end

	lotRect.Name = name
	table.insert(lotReservations, lotRect)
	return true
end

local function localPoint(baseCFrame, offset)
	return (baseCFrame * CFrame.new(offset)).Position
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
	local className = "Part"
	if options and options.ClassName then
		className = options.ClassName
	end

	local part = Instance.new(className)
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color or Color3.fromRGB(255, 255, 255)
	part.Material = material or Enum.Material.Concrete
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true

	local canCollide = true
	if options and options.CanCollide ~= nil then
		canCollide = options.CanCollide
	end
	part.CanCollide = canCollide

	local transparency = 0
	if options and options.Transparency then
		transparency = options.Transparency
	end
	part.Transparency = transparency

	local castShadow = true
	if options and options.CastShadow ~= nil then
		castShadow = options.CastShadow
	end
	part.CastShadow = castShadow

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

local function makeTopSurface(parent, name, size, position, topY, rotationSource, color, material, district, surfaceType, options)
	local part = tagSurface(makePart(parent, name, size, cframeWithTop(position, size, topY, rotationSource), color, material, options), district, surfaceType)
	registerSurfaceArea(name, position, size, topY, district, surfaceType)
	return part
end

local function makeAbsoluteSurface(parent, name, size, cframe, color, material, district, surfaceType, options)
	local part = tagSurface(makePart(parent, name, size, cframe, color, material, options), district, surfaceType)
	registerSurfaceArea(name, cframe.Position, size, cframe.Position.Y + (size.Y * 0.5), district, surfaceType)
	return part
end

local function makeRoad(name, size, cframe, district, topY)
	return makeTopSurface(sections.Roads, name, size, cframe.Position, topY or RIDE_SURFACE_TOP_Y, cframe, Color3.fromRGB(37, 41, 46), Enum.Material.Asphalt, district, "Street")
end

local function makeSidewalk(name, size, cframe, district, topY)
	return makeTopSurface(sections.Roads, name, size, cframe.Position, topY or RIDE_SURFACE_TOP_Y, cframe, Color3.fromRGB(148, 148, 152), Enum.Material.Concrete, district, "Sidewalk")
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
		local size
		local cframe
		if orientation == "X" then
			size = Vector3.new(2.2, 0.06, 12)
			cframe = CFrame.new(position + Vector3.new(offset, 0.63, 0))
		else
			size = Vector3.new(12, 0.06, 2.2)
			cframe = CFrame.new(position + Vector3.new(0, 0.63, offset))
		end
		makePart(sections.Roads, string.format("Crosswalk_%s_%d", orientation, i), size, cframe, Color3.fromRGB(235, 235, 235), Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CastShadow = false,
		})
	end
end

local function makeTree(position, district, scale, options)
	scale = scale or 1
	options = options or {}
	if not options.SkipSurfaceSnap then
		position = snapToSurface(position)
	end

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
	position = snapToSurface(position)
	local pole = makePart(sections.Props, "LightPole", Vector3.new(0.8, height, 0.8), CFrame.new(position + Vector3.new(0, height * 0.5, 0)), Color3.fromRGB(52, 55, 60), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	tagNearMiss(pole, district)
	local arm = makePart(sections.Props, "LightArm", Vector3.new(0.5, 0.5, 5), CFrame.new(position + Vector3.new(0, height - 1.5, -2.3)), Color3.fromRGB(76, 79, 84), Enum.Material.Metal)
	tagNearMiss(arm, district)
	local lamp = makePart(sections.Props, "Lamp", Vector3.new(1.6, 0.4, 1.6), CFrame.new(position + Vector3.new(0, height - 1.8, -4.4)), Color3.fromRGB(255, 230, 174), Enum.Material.Neon, { CanCollide = false })
	lamp:SetAttribute("District", district)
end

local function makeBench(position, district, yaw)
	yaw = yaw or 0
	position = snapToSurface(position)
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
	position = snapToSurface(position)
	local base = makePart(sections.Props, "PlanterBase", size, CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)), Color3.fromRGB(132, 138, 145), Enum.Material.Concrete)
	tagNearMiss(base, district)
	makeTree(position + Vector3.new(0, size.Y, 0), district, plantScale, { SkipSurfaceSnap = true })
end

local function makeParkedCar(position, district, color, yaw)
	yaw = yaw or 0
	position = snapToSurface(position)
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

local function makeRowhouse(basePosition, district, width, depth, height, bodyColor, trimColor, yaw)
	yaw = yaw or 0
	local baseCFrame = CFrame.new(basePosition) * CFrame.Angles(0, math.rad(yaw), 0)
	local palette = palettes[district] or palettes.RedlineRow
	local body = makePart(sections.Buildings, "RowhouseBody", Vector3.new(width, height, depth), baseCFrame * CFrame.new(0, height * 0.5, 0), bodyColor, Enum.Material.Brick)
	tagNearMiss(body, district)
	local roof = makePart(sections.Buildings, "RowhouseRoof", Vector3.new(width + 1, 1.4, depth + 1), baseCFrame * CFrame.new(0, height + 0.7, 0), palette.Roof, Enum.Material.Slate)
	tagNearMiss(roof, district)
	local cornice = makePart(sections.Buildings, "RowhouseCornice", Vector3.new(width + 1.2, 0.5, 1), baseCFrame * CFrame.new(0, height - 0.1, -(depth * 0.5) - 0.45), trimColor, Enum.Material.Wood)
	tagNearMiss(cornice, district)
	local stoopBase = makePart(sections.Props, "StoopBase", Vector3.new(width * 0.48, 1.4, 4.5), baseCFrame * CFrame.new(0, 0.7, -(depth * 0.5) - 2.2), trimColor, Enum.Material.Concrete)
	tagNearMiss(stoopBase, district)
	for step = 1, 3 do
		local stepPart = makePart(sections.Props, "StoopStep", Vector3.new(width * 0.42, 0.4, 1.2), baseCFrame * CFrame.new(0, 0.2 * step, -(depth * 0.5) - 4.8 + (step * 1.2)), Color3.fromRGB(171, 162, 150), Enum.Material.Concrete)
		tagNearMiss(stepPart, district)
	end
	local door = makePart(sections.Buildings, "Door", Vector3.new(2.1, 4, 0.2), baseCFrame * CFrame.new(0, 2.2, -(depth * 0.5) - 0.12), Color3.fromRGB(69, 45, 31), Enum.Material.Wood)
	tagNearMiss(door, district)
	for _, x in ipairs({ -(width * 0.24), width * 0.24 }) do
		for _, y in ipairs({ 3.2, 7.1 }) do
			local window = makePart(sections.Buildings, "Window", Vector3.new(2.1, 2.2, 0.2), baseCFrame * CFrame.new(x, y, -(depth * 0.5) - 0.16), palette.Window, Enum.Material.Glass, { Transparency = 0.18 })
			tagNearMiss(window, district)
		end
	end
end

local function makeMidrise(basePosition, district, width, depth, height, bodyColor, accentColor, yaw)
	yaw = yaw or 0
	local baseCFrame = CFrame.new(basePosition) * CFrame.Angles(0, math.rad(yaw), 0)
	local palette = palettes[district] or palettes.City
	local body = makePart(sections.Buildings, "MidriseBody", Vector3.new(width, height, depth), baseCFrame * CFrame.new(0, height * 0.5, 0), bodyColor, Enum.Material.Concrete)
	tagNearMiss(body, district)
	local crown = makePart(sections.Buildings, "MidriseCrown", Vector3.new(width + 2, 2.2, depth + 2), baseCFrame * CFrame.new(0, height + 1.1, 0), palette.Roof, Enum.Material.Metal)
	tagNearMiss(crown, district)
	local podium = makePart(sections.Buildings, "MidrisePodium", Vector3.new(width + 8, 8, depth + 8), baseCFrame * CFrame.new(0, 4, 0), Color3.fromRGB(90, 92, 97), Enum.Material.Concrete)
	tagNearMiss(podium, district)
	for _, x in ipairs({ -(width * 0.33), 0, width * 0.33 }) do
		local windowBand = makePart(sections.Buildings, "WindowBand", Vector3.new(width * 0.16, height - 10, 0.25), baseCFrame * CFrame.new(x, height * 0.56, -(depth * 0.5) - 0.15), palette.Window, Enum.Material.Glass, { Transparency = 0.2 })
		tagNearMiss(windowBand, district)
	end
	local entry = makePart(sections.Buildings, "TowerEntry", Vector3.new(width * 0.42, 6, 1), baseCFrame * CFrame.new(0, 3.2, -(depth * 0.5) - 0.5), accentColor, Enum.Material.Metal)
	tagNearMiss(entry, district)
end

local function makeWarehouse(basePosition, district, width, depth, height, bodyColor, accentColor, yaw)
	yaw = yaw or 0
	local baseCFrame = CFrame.new(basePosition) * CFrame.Angles(0, math.rad(yaw), 0)
	local palette = palettes[district] or palettes.City
	local shell = makePart(sections.Buildings, "WarehouseShell", Vector3.new(width, height, depth), baseCFrame * CFrame.new(0, height * 0.5, 0), bodyColor, Enum.Material.Metal)
	tagNearMiss(shell, district)
	local roof = makePart(sections.Buildings, "WarehouseRoof", Vector3.new(width + 2, 1.6, depth + 2), baseCFrame * CFrame.new(0, height + 0.8, 0), palette.Roof, Enum.Material.Metal)
	tagNearMiss(roof, district)
	for _, x in ipairs({ -(width * 0.28), 0, width * 0.28 }) do
		local door = makePart(sections.Buildings, "WarehouseDoor", Vector3.new(width * 0.18, height * 0.42, 0.4), baseCFrame * CFrame.new(x, height * 0.22, -(depth * 0.5) - 0.2), Color3.fromRGB(55, 59, 64), Enum.Material.Metal)
		tagNearMiss(door, district)
	end
	local stripe = makePart(sections.Buildings, "WarehouseStripe", Vector3.new(width + 0.5, 1.2, 0.3), baseCFrame * CFrame.new(0, height * 0.72, -(depth * 0.5) - 0.16), accentColor, Enum.Material.Neon)
	tagNearMiss(stripe, district)
end

local function makeCrane(basePosition, district, yaw)
	yaw = yaw or 0
	basePosition = snapToSurface(basePosition)
	local baseCFrame = CFrame.new(basePosition) * CFrame.Angles(0, math.rad(yaw), 0)
	local mast = makePart(sections.Props, "CraneMast", Vector3.new(6, 54, 6), baseCFrame * CFrame.new(0, 27, 0), Color3.fromRGB(198, 151, 56), Enum.Material.Metal)
	tagNearMiss(mast, district)
	local boom = makePart(sections.Props, "CraneBoom", Vector3.new(72, 4, 4), baseCFrame * CFrame.new(28, 49, 0), Color3.fromRGB(214, 168, 62), Enum.Material.Metal)
	tagNearMiss(boom, district)
	local hook = makePart(sections.Props, "CraneHook", Vector3.new(1, 18, 1), baseCFrame * CFrame.new(54, 38, 0), Color3.fromRGB(55, 58, 62), Enum.Material.Metal)
	tagNearMiss(hook, district)
end

local function makePier(basePosition, district, width, depth)
	local deck = makeTopSurface(sections.Waterfront, "PierDeck", Vector3.new(width, 2, depth), basePosition, RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(118, 99, 71), Enum.Material.WoodPlanks, district, "Sidewalk")
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
	position = snapToSurface(position)
	local mound = makePart(sections.Ground, "Berm", size, CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)) * CFrame.Angles(0, math.rad(yaw), 0), Color3.fromRGB(124, 95, 59), Enum.Material.Ground)
	tagSurface(mound, district, "OffRoad")
end

local function makeRock(position, district, size)
	position = snapToSurface(position)
	local rock = makePart(sections.Props, "Rock", size, CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)), Color3.fromRGB(108, 99, 91), Enum.Material.Slate)
	tagNearMiss(rock, district)
end

local function makeDistrictPlate(district)
	local palette = palettes[district.Name]
	local plate = makeAbsoluteSurface(sections.Ground, district.Name, district.Size, CFrame.new(district.Position), (palette and palette.Ground) or Config.World.DistrictColors[district.Name], district.Material or Enum.Material.Concrete, district.Name, district.Surface)
	local halo = makePart(sections.Ground, district.Name .. "Halo", Vector3.new(district.Size.X - 20, 0.4, district.Size.Z - 20), CFrame.new(district.Position + Vector3.new(0, 0.85, 0)), (palette and palette.Trim) or Color3.fromRGB(180, 180, 180), Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 0.92,
		CastShadow = false,
	})
	halo:SetAttribute("District", district.Name)
	return plate
end

local function makeSpawnLot(spawnDef)
	local palette = palettes[spawnDef.District] or palettes.City
	local lotTopY = math.max(surfaceTopAt(spawnDef.Position.X, spawnDef.Position.Z, 0), RIDE_SURFACE_TOP_Y)
	local lotBasePosition = Vector3.new(spawnDef.Position.X, lotTopY, spawnDef.Position.Z)
	local baseCFrame = CFrame.new(lotBasePosition) * CFrame.Angles(0, math.rad(spawnDef.Heading or 0), 0)
	local lot = makeTopSurface(sections.Props, spawnDef.Name .. "Lot", Vector3.new(42, 0.6, 26), spawnDef.Position, lotTopY, baseCFrame, Color3.fromRGB(52, 54, 58), Enum.Material.Asphalt, spawnDef.District, "Street")
	local padGlow = makePart(sections.Props, spawnDef.Name .. "PadGlow", Vector3.new(12, 0.16, 12), baseCFrame * CFrame.new(0, 0.09, 0), spawnDef.Color, Enum.Material.Neon, {
		CanCollide = false,
		Transparency = 0.18,
		CastShadow = false,
	})
	padGlow:SetAttribute("District", spawnDef.District)
	local awning = makePart(sections.Props, spawnDef.Name .. "Awning", Vector3.new(22, 0.8, 8), baseCFrame * CFrame.new(0, 4.8, -10), palette.Accent, Enum.Material.Metal)
	tagNearMiss(awning, spawnDef.District)
	local backWall = makePart(sections.Props, spawnDef.Name .. "Wall", Vector3.new(22, 9, 1.5), baseCFrame * CFrame.new(0, 4.5, -14), Color3.fromRGB(63, 66, 72), Enum.Material.Concrete)
	tagNearMiss(backWall, spawnDef.District)
	addSurfaceGui(backWall, spawnDef.Name, Color3.fromRGB(245, 245, 245))
	for offset = -12, 12, 8 do
		makeLightPole(localPoint(baseCFrame, Vector3.new(offset, 0, 14)), spawnDef.District, 13)
	end
	return lot, lotTopY
end

local function rowhouseBodyColor(x, z)
	local variants = {
		Color3.fromRGB(136, 89, 74),
		Color3.fromRGB(154, 102, 82),
		Color3.fromRGB(121, 74, 60),
		Color3.fromRGB(170, 114, 84),
	}
	local index = ((math.abs(x + z) / 2) % #variants) + 1
	return variants[index]
end

local function placeRowhouseLot(name, position, yaw)
	local width = 22 + ((math.abs(position.X + position.Z) % 3) * 2)
	local depth = 42
	local height = 20 + ((math.abs((position.X / 20) - (position.Z / 15)) % 3) * 6)
	if reserveLotOrWarn(name, position, Vector3.new(width, 1, depth + 12), 4, 6) then
		makeRowhouse(position, "RedlineRow", width, depth, height, rowhouseBodyColor(position.X, position.Z), palettes.RedlineRow.Trim, yaw)
	end
end

local function placeMidriseLot(name, position, width, depth, height, district, accentColor, yaw)
	if reserveLotOrWarn(name, position, Vector3.new(width + 8, 1, depth + 8), BUILDING_CLEARANCE_BUFFER, BUILDING_CLEARANCE_BUFFER) then
		makeMidrise(position, district, width, depth, height, Color3.fromRGB(106, 111, 120), accentColor, yaw)
	end
end

local function placeWarehouseLot(name, position, width, depth, height, district, accentColor, yaw)
	if reserveLotOrWarn(name, position, Vector3.new(width + 10, 1, depth + 10), BUILDING_CLEARANCE_BUFFER, BUILDING_CLEARANCE_BUFFER) then
		makeWarehouse(position, district, width, depth, height, Color3.fromRGB(86, 92, 98), accentColor, yaw)
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

for _, x in ipairs(ROAD_CENTERS_X) do
	local district = "CanalSide"
	if x < -220 then
		district = "RedlineRow"
	elseif x < 240 then
		district = "PennMarket"
	elseif x < 600 then
		district = "IronHarbor"
	end
	makeRoad("Avenue_" .. tostring(x), Vector3.new(42, 1, 1840), CFrame.new(x, 0, 0), district)
	makeSidewalk("AvenueSidewalkL_" .. tostring(x), Vector3.new(10, 1, 1840), CFrame.new(x - 26, 0, 0), district)
	makeSidewalk("AvenueSidewalkR_" .. tostring(x), Vector3.new(10, 1, 1840), CFrame.new(x + 26, 0, 0), district)
	makePart(sections.Roads, "AvenueCurbL_" .. tostring(x), Vector3.new(0.4, 0.08, 1840), CFrame.new(x - 20.8, RIDE_SURFACE_TOP_Y + 0.04, 0), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete, {
		CanCollide = false,
		CastShadow = false,
	})
	makePart(sections.Roads, "AvenueCurbR_" .. tostring(x), Vector3.new(0.4, 0.08, 1840), CFrame.new(x + 20.8, RIDE_SURFACE_TOP_Y + 0.04, 0), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete, {
		CanCollide = false,
		CastShadow = false,
	})
	addRoadMarkingsVertical(x, -840, 840)
	reserveRect(roadReservations, "AvenueCorridor_" .. tostring(x), Vector3.new(x, 0, 0), Vector3.new(42 + ROAD_RESERVATION_PADDING, 8, 1840 + ROAD_RESERVATION_PADDING))
end

for _, z in ipairs(ROAD_CENTERS_Z) do
	local district = "QuarryRun"
	if z < -420 then
		district = "DruidHeights"
	elseif z < 240 then
		district = "PennMarket"
	elseif z < 520 then
		district = "IronHarbor"
	end
	makeRoad("Street_" .. tostring(z), Vector3.new(1840, 1, 42), CFrame.new(0, 0, z), district)
	makeSidewalk("StreetSidewalkTop_" .. tostring(z), Vector3.new(1840, 1, 10), CFrame.new(0, 0, z - 26), district)
	makeSidewalk("StreetSidewalkBottom_" .. tostring(z), Vector3.new(1840, 1, 10), CFrame.new(0, 0, z + 26), district)
	makePart(sections.Roads, "StreetCurbTop_" .. tostring(z), Vector3.new(1840, 0.08, 0.4), CFrame.new(0, RIDE_SURFACE_TOP_Y + 0.04, z - 20.8), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete, {
		CanCollide = false,
		CastShadow = false,
	})
	makePart(sections.Roads, "StreetCurbBottom_" .. tostring(z), Vector3.new(1840, 0.08, 0.4), CFrame.new(0, RIDE_SURFACE_TOP_Y + 0.04, z + 20.8), Color3.fromRGB(176, 176, 176), Enum.Material.Concrete, {
		CanCollide = false,
		CastShadow = false,
	})
	addRoadMarkingsHorizontal(z, -840, 840)
	reserveRect(roadReservations, "StreetCorridor_" .. tostring(z), Vector3.new(0, 0, z), Vector3.new(1840 + ROAD_RESERVATION_PADDING, 8, 42 + ROAD_RESERVATION_PADDING))
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

makeRoad("HarborExpress", Vector3.new(900, 1, 28), CFrame.new(40, 0, 480), "PennMarket", EXPRESS_TOP_Y)
makePart(sections.Roads, "HarborExpressMedian", Vector3.new(900, 0.35, 2), CFrame.new(40, EXPRESS_TOP_Y + 0.175, 480), Color3.fromRGB(238, 214, 104), Enum.Material.Neon, { CanCollide = false })
for _, offset in ipairs({ -190, -70, 70, 190 }) do
	makePart(sections.Props, "ExpressSupport" .. tostring(offset), Vector3.new(16, 34, 16), CFrame.new(offset, 17, 480), Color3.fromRGB(112, 112, 118), Enum.Material.Concrete)
	makePart(sections.Props, "SupportBase" .. tostring(offset), Vector3.new(24, 3, 24), CFrame.new(offset, 1.5, 480), Color3.fromRGB(92, 92, 96), Enum.Material.Concrete)
end
for x = -380, 460, 120 do
	makePart(sections.Roads, "ExpressBarrierL" .. tostring(x), Vector3.new(10, 3, 1), CFrame.new(x, EXPRESS_TOP_Y + 1.5, 466), Color3.fromRGB(188, 188, 192), Enum.Material.Concrete)
	makePart(sections.Roads, "ExpressBarrierR" .. tostring(x), Vector3.new(10, 3, 1), CFrame.new(x, EXPRESS_TOP_Y + 1.5, 494), Color3.fromRGB(188, 188, 192), Enum.Material.Concrete)
end

makePart(sections.Waterfront, "CanalFloor", Vector3.new(520, 3, 66), CFrame.new(390, -9.5, -310), Color3.fromRGB(118, 121, 124), Enum.Material.Concrete)
local canalLeft = makePart(sections.Waterfront, "CanalLeftWall", Vector3.new(520, 18, 8), CFrame.new(390, -0.5, -281), Color3.fromRGB(153, 156, 162), Enum.Material.Concrete)
local canalRight = makePart(sections.Waterfront, "CanalRightWall", Vector3.new(520, 18, 8), CFrame.new(390, -0.5, -339), Color3.fromRGB(153, 156, 162), Enum.Material.Concrete)
tagNearMiss(canalLeft, "CanalSide")
tagNearMiss(canalRight, "CanalSide")
makeTopSurface(sections.Waterfront, "CanalPromenadeNorth", Vector3.new(520, 2, 18), Vector3.new(390, 0, -260), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(128, 138, 144), Enum.Material.Concrete, "CanalSide", "Sidewalk")
makeTopSurface(sections.Waterfront, "CanalPromenadeSouth", Vector3.new(520, 2, 18), Vector3.new(390, 0, -360), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(128, 138, 144), Enum.Material.Concrete, "CanalSide", "Sidewalk")
for x = 150, 610, 46 do
	local northTopY = surfaceTopAt(x, -270, 0)
	local southTopY = surfaceTopAt(x, -350, 0)
	makePart(sections.Waterfront, "CanalRailNorth" .. tostring(x), Vector3.new(1.2, 3, 1.2), CFrame.new(x, northTopY + 1.5, -270), Color3.fromRGB(68, 72, 77), Enum.Material.Metal)
	makePart(sections.Waterfront, "CanalRailSouth" .. tostring(x), Vector3.new(1.2, 3, 1.2), CFrame.new(x, southTopY + 1.5, -350), Color3.fromRGB(68, 72, 77), Enum.Material.Metal)
	if x < 610 then
		makePart(sections.Waterfront, "CanalRailBeamNorth" .. tostring(x), Vector3.new(46, 0.35, 0.4), CFrame.new(x + 23, northTopY + 3.15, -270), Color3.fromRGB(102, 111, 118), Enum.Material.Metal)
		makePart(sections.Waterfront, "CanalRailBeamSouth" .. tostring(x), Vector3.new(46, 0.35, 0.4), CFrame.new(x + 23, southTopY + 3.15, -350), Color3.fromRGB(102, 111, 118), Enum.Material.Metal)
	end
end

makePart(sections.Waterfront, "HarborBulkhead", Vector3.new(28, 22, 1800), CFrame.new(762, 2, 0), Color3.fromRGB(108, 114, 120), Enum.Material.Concrete)
makeTopSurface(sections.Waterfront, "HarborWalk", Vector3.new(90, 2, 900), Vector3.new(714, 0, -180), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(124, 129, 133), Enum.Material.Concrete, "CanalSide", "Sidewalk")
makePier(Vector3.new(800, 0, 210), "IronHarbor", 130, 52)
makePier(Vector3.new(790, 0, -120), "CanalSide", 110, 44)
for z = -520, 120, 160 do
	makeLightPole(Vector3.new(748, 0, z), "CanalSide", 15)
	makeBench(Vector3.new(712, 0, z + 30), "CanalSide", 90)
end

if reserveLotOrWarn("RedlineBacklotPad", Vector3.new(-668, 0, -180), Vector3.new(110, 1, 38), 4, 4) then
	makeTopSurface(sections.Ground, "RedlineBacklotPad", Vector3.new(110, 1, 38), Vector3.new(-668, 0, -180), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(108, 105, 100), Enum.Material.Concrete, "RedlineRow", "Sidewalk")
end

for _, x in ipairs({ -724, -684, -644, -604 }) do
	for _, row in ipairs({
		{ Z = -358, Yaw = 180 },
		{ Z = -240, Yaw = 0 },
		{ Z = -120, Yaw = 180 },
		{ Z = -2, Yaw = 0 },
		{ Z = 120, Yaw = 180 },
		{ Z = 240, Yaw = 0 },
	}) do
		placeRowhouseLot(string.format("RedlineWest_%d_%d", x, row.Z), Vector3.new(x, 0, row.Z), row.Yaw)
	end
end

for _, x in ipairs({ -484, -444, -404, -364 }) do
	for _, row in ipairs({
		{ Z = -240, Yaw = 0 },
		{ Z = -120, Yaw = 180 },
		{ Z = -2, Yaw = 0 },
		{ Z = 120, Yaw = 180 },
		{ Z = 240, Yaw = 0 },
	}) do
		placeRowhouseLot(string.format("RedlineEast_%d_%d", x, row.Z), Vector3.new(x, 0, row.Z), row.Yaw)
	end
end
for _, x in ipairs({ -484, -444 }) do
	placeRowhouseLot(string.format("RedlineNorthStrip_%d", x), Vector3.new(x, 0, -358), 180)
end

makeParkedCar(Vector3.new(-710, 0, -344), "RedlineRow", Color3.fromRGB(185, 61, 56), 90)
makeParkedCar(Vector3.new(-650, 0, -344), "RedlineRow", Color3.fromRGB(126, 135, 148), 90)

local cornerStoreBase = Vector3.new(-392, 0, -364)
if reserveLotOrWarn("CornerStoreLot", cornerStoreBase, Vector3.new(48, 1, 56), 4, 6) then
	local cornerStore = makePart(sections.Buildings, "CornerStore", Vector3.new(44, 18, 52), CFrame.new(cornerStoreBase + Vector3.new(0, 9, 0)), Color3.fromRGB(126, 83, 64), Enum.Material.Brick)
	tagNearMiss(cornerStore, "RedlineRow")
	local storeSign = makePart(sections.Buildings, "CornerStoreSign", Vector3.new(26, 4, 1), CFrame.new(cornerStoreBase + Vector3.new(0, 13, -26.6)), palettes.RedlineRow.Accent, Enum.Material.Neon)
	tagNearMiss(storeSign, "RedlineRow")
	addSurfaceGui(storeSign, "REDLINE MART", Color3.fromRGB(255, 248, 226))
end

if reserveLotOrWarn("PennConstructionPad", Vector3.new(56, 0, -228), Vector3.new(96, 1, 60), 4, 4) then
	makeTopSurface(sections.Ground, "PennConstructionPad", Vector3.new(96, 1, 60), Vector3.new(56, 0, -228), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(128, 130, 134), Enum.Material.Concrete, "PennMarket", "Sidewalk")
	makePart(sections.Props, "ConstructionBarrierWest", Vector3.new(1.2, 3, 52), CFrame.new(10, 2.1, -228), Color3.fromRGB(216, 138, 62), Enum.Material.Metal)
	makePart(sections.Props, "ConstructionBarrierEast", Vector3.new(1.2, 3, 52), CFrame.new(102, 2.1, -228), Color3.fromRGB(216, 138, 62), Enum.Material.Metal)
end

placeMidriseLot("PennNorthwest", Vector3.new(-182, 0, -176), 72, 72, 56, "PennMarket", palettes.PennMarket.Accent, 180)
placeMidriseLot("PennNortheast", Vector3.new(72, 0, -164), 76, 70, 74, "PennMarket", Color3.fromRGB(114, 193, 244), 180)
placeMidriseLot("PennSouthwest", Vector3.new(-176, 0, 72), 84, 78, 50, "PennMarket", Color3.fromRGB(255, 194, 104), 0)
placeMidriseLot("PennSoutheast", Vector3.new(76, 0, 68), 86, 80, 70, "PennMarket", Color3.fromRGB(115, 223, 246), 0)
placeMidriseLot("PennAnnex", Vector3.new(-186, 0, 278), 66, 62, 46, "PennMarket", palettes.PennMarket.Accent, 0)

if reserveLotOrWarn("PennPlaza", Vector3.new(44, 0, 278), Vector3.new(104, 2, 92), 4, 4) then
	makeTopSurface(sections.Ground, "PennPlaza", Vector3.new(104, 2, 92), Vector3.new(44, 0, 278), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(136, 138, 145), Enum.Material.Concrete, "PennMarket", "Sidewalk")
end
for _, offset in ipairs({ Vector3.new(-28, 0, -20), Vector3.new(28, 0, -20), Vector3.new(-28, 0, 20), Vector3.new(28, 0, 20) }) do
	makePlanter(Vector3.new(44, 0, 278) + offset, "PennMarket", Vector3.new(16, 2.2, 16), 0.75)
end
makeBench(Vector3.new(12, 0, 278), "PennMarket", 0)
makeBench(Vector3.new(76, 0, 278), "PennMarket", 180)
makeParkedCar(Vector3.new(-4, 0, 232), "PennMarket", Color3.fromRGB(78, 130, 196), 0)
makeParkedCar(Vector3.new(92, 0, 232), "PennMarket", Color3.fromRGB(222, 181, 73), 0)

makeTopSurface(sections.Ground, "DruidGreen", Vector3.new(860, 2, 300), Vector3.new(-180, 0, -640), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(72, 127, 82), Enum.Material.Grass, "DruidHeights", "OffRoad")
makeTopSurface(sections.Ground, "DruidPathNorth", Vector3.new(520, 1, 12), Vector3.new(-180, 0, -700), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(176, 170, 157), Enum.Material.Concrete, "DruidHeights", "Sidewalk")
makeTopSurface(sections.Ground, "DruidPathSouth", Vector3.new(620, 1, 12), Vector3.new(-160, 0, -596), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(176, 170, 157), Enum.Material.Concrete, "DruidHeights", "Sidewalk")
makeTopSurface(sections.Ground, "SkatePad", Vector3.new(180, 1, 96), Vector3.new(-270, 0, -688), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(112, 118, 122), Enum.Material.Concrete, "DruidHeights", "Sidewalk")
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

if reserveLotOrWarn("HarborContainerPad", Vector3.new(780, 0, 248), Vector3.new(92, 1, 60), 4, 4) then
	makeTopSurface(sections.Ground, "HarborContainerPad", Vector3.new(92, 1, 60), Vector3.new(780, 0, 248), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(112, 116, 122), Enum.Material.Concrete, "IronHarbor", "Sidewalk")
end

placeWarehouseLot("HarborNorthWest", Vector3.new(300, 0, 92), 110, 88, 26, "IronHarbor", palettes.IronHarbor.Accent, 180)
placeWarehouseLot("HarborNorthMid", Vector3.new(540, 0, 92), 120, 82, 30, "IronHarbor", palettes.IronHarbor.Accent, 180)
placeWarehouseLot("HarborNorthEast", Vector3.new(780, 0, 92), 104, 92, 24, "IronHarbor", palettes.IronHarbor.Accent, 180)
placeWarehouseLot("HarborSouthWest", Vector3.new(300, 0, 328), 128, 80, 26, "IronHarbor", palettes.IronHarbor.Accent, 0)
placeWarehouseLot("HarborSouthMid", Vector3.new(540, 0, 328), 120, 90, 30, "IronHarbor", palettes.IronHarbor.Accent, 0)
placeWarehouseLot("HarborSouthEast", Vector3.new(780, 0, 328), 108, 84, 28, "IronHarbor", palettes.IronHarbor.Accent, 0)

makeCrane(Vector3.new(610, 0, 520), "IronHarbor", 0)
makeCrane(Vector3.new(780, 0, 470), "IronHarbor", 20)
for x = 360, 760, 100 do
	makePart(sections.Props, "HarborFencePost" .. tostring(x), Vector3.new(1.2, 4, 1.2), CFrame.new(x, 2, 566), Color3.fromRGB(86, 89, 94), Enum.Material.Metal)
	if x < 760 then
		makePart(sections.Props, "HarborFenceRail" .. tostring(x), Vector3.new(100, 0.3, 0.3), CFrame.new(x + 50, 3.6, 566), Color3.fromRGB(122, 126, 132), Enum.Material.Metal)
	end
end
for _, z in ipairs({ 84, 204, 324 }) do
	makeParkedCar(Vector3.new(836, 0, z), "IronHarbor", Color3.fromRGB(92, 157, 220), 90)
end

placeMidriseLot("CanalNorthWest", Vector3.new(540, 0, -420), 118, 86, 44, "CanalSide", palettes.CanalSide.Accent, 180)
placeMidriseLot("CanalNorthEast", Vector3.new(792, 0, -420), 92, 74, 34, "CanalSide", palettes.CanalSide.Accent, 180)
placeMidriseLot("CanalMidWest", Vector3.new(540, 0, -156), 96, 78, 34, "CanalSide", palettes.CanalSide.Accent, 0)
placeMidriseLot("CanalEastPier", Vector3.new(854, 0, -150), 56, 66, 28, "CanalSide", palettes.CanalSide.Accent, 0)

makeTopSurface(sections.Waterfront, "BoardwalkDeck", Vector3.new(120, 2, 250), Vector3.new(760, 0, -100), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(121, 104, 74), Enum.Material.WoodPlanks, "CanalSide", "Sidewalk")
for z = -200, 0, 40 do
	makeLightPole(Vector3.new(804, 0, z), "CanalSide", 14)
	makeBench(Vector3.new(728, 0, z + 12), "CanalSide", 90)
end
for _, patch in ipairs({ Vector3.new(615, 0, -405), Vector3.new(708, 0, -380), Vector3.new(728, 0, -60) }) do
	makePlanter(patch, "CanalSide", Vector3.new(18, 2, 12), 0.68)
end

makeTopSurface(sections.Ground, "QuarryDirt", Vector3.new(460, 2, 560), Vector3.new(-720, 0, 580), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(128, 96, 62), Enum.Material.Ground, "QuarryRun", "OffRoad")
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
local trailShedBase = snapToSurface(Vector3.new(-848, 0, 612))
local trailShed = makePart(sections.Props, "TrailShed", Vector3.new(34, 14, 24), CFrame.new(trailShedBase + Vector3.new(0, 7, 0)), Color3.fromRGB(102, 87, 62), Enum.Material.WoodPlanks)
tagNearMiss(trailShed, "QuarryRun")
for _, postOffset in ipairs({ -5, 5 }) do
	makePart(sections.Props, "TrailSignPost" .. tostring(postOffset), Vector3.new(0.8, 6, 0.8), CFrame.new(trailShedBase + Vector3.new(postOffset, 3, 625 - 612)), Color3.fromRGB(74, 61, 42), Enum.Material.Wood)
end
local trailSign = makePart(sections.Props, "TrailSign", Vector3.new(14, 5, 1), CFrame.new(trailShedBase + Vector3.new(0, 6.5, 13)), palettes.QuarryRun.Accent, Enum.Material.Neon)
tagNearMiss(trailSign, "QuarryRun")
addSurfaceGui(trailSign, "QUARRY RUN", Color3.fromRGB(57, 42, 24))

local signDefs = {
	{ Text = "REDLINE ROW", District = "RedlineRow", Position = Vector3.new(-650, 0, -350) },
	{ Text = "PENN MARKET", District = "PennMarket", Position = Vector3.new(-40, 0, -350) },
	{ Text = "DRUID HEIGHTS", District = "DruidHeights", Position = Vector3.new(-180, 0, -760) },
	{ Text = "IRON HARBOR", District = "IronHarbor", Position = Vector3.new(560, 0, 580) },
	{ Text = "CANAL SIDE", District = "CanalSide", Position = Vector3.new(760, 0, -470) },
	{ Text = "QUARRY RUN", District = "QuarryRun", Position = Vector3.new(-790, 0, 790) },
}

for _, sign in ipairs(signDefs) do
	local palette = palettes[sign.District] or palettes.City
	local signBase = snapToSurface(sign.Position)
	local post = makePart(sections.DistrictSigns, sign.Text .. "_Post", Vector3.new(3.2, 16, 1.2), CFrame.new(signBase + Vector3.new(0, 8, 0)), Color3.fromRGB(47, 49, 54), Enum.Material.Metal)
	tagNearMiss(post, sign.District)
	local board = makePart(sections.DistrictSigns, sign.Text .. "_Board", Vector3.new(20, 8, 1.2), CFrame.new(signBase + Vector3.new(0, 14, 0)), palette.Accent, Enum.Material.Metal)
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

if reserveLotOrWarn("PoliceStationLot", Vector3.new(315, 0, -140), Vector3.new(96, 1, 88), 6, 6) then
	makePart(policeGenerated, "StationBase", Vector3.new(96, 2, 72), CFrame.new(315, 1, -140), Color3.fromRGB(132, 132, 142), Enum.Material.Concrete)
	makeTopSurface(policeGenerated, "StationForecourt", Vector3.new(50, 1, 36), Vector3.new(315, 0, -110), RIDE_SURFACE_TOP_Y, nil, Color3.fromRGB(48, 49, 54), Enum.Material.Asphalt, "PennMarket", "Street")
	makeMidrise(Vector3.new(315, 0, -150), "PennMarket", 74, 40, 24, Color3.fromRGB(92, 98, 108), Color3.fromRGB(96, 164, 220), 180)
	local stationSign = makePart(policeGenerated, "StationSign", Vector3.new(22, 5, 1), CFrame.new(315, 12, -129), Color3.fromRGB(85, 147, 214), Enum.Material.Neon)
	addSurfaceGui(stationSign, "METRO POLICE", Color3.fromRGB(255, 255, 255))
end

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
	if reserveLotOrWarn("SpawnLot_" .. spawnDef.Name, spawnDef.Position, Vector3.new(48, 1, 38), 4, 4) then
		local lot, lotTopY = makeSpawnLot(spawnDef)
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = spawnDef.Name
		spawn.Size = Vector3.new(12, 0.2, 12)
		spawn.CFrame = CFrame.new(spawnDef.Position + Vector3.new(0, lotTopY + 0.12, 0)) * CFrame.Angles(0, math.rad(spawnDef.Heading or 0), 0)
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
		lot.Name = spawnDef.Name .. "Lot"
	end
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

local function obstacleRotation(obstacle)
	local rotation = obstacle.Rotation or Vector3.new(0, 0, 0)
	return CFrame.Angles(math.rad(rotation.X or 0), math.rad(rotation.Y or 0), math.rad(rotation.Z or 0))
end

local function obstacleBaseCFrame(obstacle, halfHeight)
	local surfaceTop = surfaceTopAt(obstacle.Position.X, obstacle.Position.Z, obstacle.Position.Y or 0)
	local yOffset = obstacle.YOffset or 0
	local centerPosition = Vector3.new(obstacle.Position.X, surfaceTop + halfHeight + yOffset, obstacle.Position.Z)
	return CFrame.new(centerPosition) * obstacleRotation(obstacle), surfaceTop
end

local function makeObstaclePart(name, size, cframe, color, material, district, options)
	local part = makePart(rampsGenerated, name, size, cframe, color, material, options)
	tagNearMiss(part, district)
	return part
end

local function createRamp(name, size, baseCFrame, district, colors, options)
	options = options or {}
	local ramp = Instance.new("WedgePart")
	ramp.Name = name
	ramp.Size = size
	ramp.CFrame = baseCFrame
	ramp.Color = colors.Base
	ramp.Material = options.Material or Enum.Material.Metal
	ramp.Anchored = true
	ramp.Parent = rampsGenerated
	tagNearMiss(ramp, district)

	local deckLength = options.DeckLength or math.max(10, size.Z * 0.3)
	local deckOffsetY = options.DeckOffsetY or (size.Y * 0.38)
	local deckOffsetZ = options.DeckOffsetZ or ((size.Z * 0.5) - (deckLength * 0.5) - 1.2)
	makeObstaclePart(name .. "Deck", Vector3.new(size.X, 1.2, deckLength), baseCFrame * CFrame.new(0, deckOffsetY, deckOffsetZ), colors.Dark, options.Material or Enum.Material.Metal, district)
	makeObstaclePart(name .. "TrimL", Vector3.new(0.6, size.Y, size.Z), baseCFrame * CFrame.new(-(size.X * 0.5) + 0.3, 0, 0), colors.Trim, options.Material or Enum.Material.Metal, district)
	makeObstaclePart(name .. "TrimR", Vector3.new(0.6, size.Y, size.Z), baseCFrame * CFrame.new((size.X * 0.5) - 0.3, 0, 0), colors.Trim, options.Material or Enum.Material.Metal, district)

	local runUpLength = options.RunUpLength or 18
	if runUpLength > 0 then
		makeObstaclePart(name .. "RunUp", Vector3.new(size.X + 4, 0.4, runUpLength), baseCFrame * CFrame.new(0, -(size.Y * 0.5) + 0.2, -(size.Z * 0.5) - (runUpLength * 0.5) + 3), colors.Dark, options.Material or Enum.Material.Metal, district)
	end

	if size.Y >= 18 then
		makeObstaclePart(name .. "Support", Vector3.new(math.max(8, size.X - 2), math.max(10, size.Y - 4), math.max(8, size.Z * 0.35)), baseCFrame * CFrame.new(0, -(size.Y * 0.22), size.Z * 0.1), colors.Trim, options.Material or Enum.Material.Metal, district)
	end

	return ramp
end

local function addRamp(obstacle)
	local colors = obstacleColors(obstacle.District)
	local baseCFrame = obstacleBaseCFrame(obstacle, obstacle.Size.Y * 0.5)
	createRamp(obstacle.Name, obstacle.Size, baseCFrame, obstacle.District, colors, {
		RunUpLength = obstacle.RunUpLength,
		DeckLength = obstacle.DeckLength,
		Material = obstacle.Material,
	})
end

local function addStairSet(obstacle)
	local colors = obstacleColors(obstacle.District)
	local surfaceTop = surfaceTopAt(obstacle.Position.X, obstacle.Position.Z, obstacle.Position.Y or 0)
	local baseCFrame = CFrame.new(Vector3.new(obstacle.Position.X, surfaceTop, obstacle.Position.Z)) * obstacleRotation(obstacle)
	local stepCount = obstacle.StepCount or 6
	local stepRise = obstacle.Size.Y / stepCount
	local stepDepth = obstacle.Size.Z / stepCount
	for step = 1, stepCount do
		local stepHeight = stepRise * step
		local stepCenterZ = -(obstacle.Size.Z * 0.5) + (stepDepth * (step - 0.5))
		makeObstaclePart(obstacle.Name .. "_Step" .. tostring(step), Vector3.new(obstacle.Size.X, stepHeight, stepDepth), baseCFrame * CFrame.new(0, stepHeight * 0.5, stepCenterZ), Color3.fromRGB(146, 146, 146), Enum.Material.Concrete, obstacle.District)
	end
	makeObstaclePart(obstacle.Name .. "Landing", Vector3.new(obstacle.Size.X, 1.2, 12), baseCFrame * CFrame.new(0, obstacle.Size.Y + 0.6, (obstacle.Size.Z * 0.5) + 6), colors.Dark, Enum.Material.Concrete, obstacle.District)
	makeObstaclePart(obstacle.Name .. "RailL", Vector3.new(1, obstacle.Size.Y + 3, obstacle.Size.Z + 12), baseCFrame * CFrame.new(-(obstacle.Size.X * 0.5) - 1, (obstacle.Size.Y * 0.5) + 1.5, 6), Color3.fromRGB(89, 93, 99), Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "RailR", Vector3.new(1, obstacle.Size.Y + 3, obstacle.Size.Z + 12), baseCFrame * CFrame.new((obstacle.Size.X * 0.5) + 1, (obstacle.Size.Y * 0.5) + 1.5, 6), Color3.fromRGB(89, 93, 99), Enum.Material.Metal, obstacle.District)
end

local function addGap(obstacle)
	local colors = obstacleColors(obstacle.District)
	local surfaceTop = surfaceTopAt(obstacle.Position.X, obstacle.Position.Z, obstacle.Position.Y or 0)
	local baseCFrame = CFrame.new(Vector3.new(obstacle.Position.X, surfaceTop, obstacle.Position.Z)) * obstacleRotation(obstacle)
	local totalSpan = obstacle.Size.X
	local width = obstacle.Size.Z
	local platformHeight = obstacle.PlatformHeight or math.max(4, obstacle.Size.Y * 0.4)
	local gapLength = obstacle.GapLength or math.max(22, totalSpan * 0.24)
	local deckLength = (totalSpan - gapLength) * 0.5
	local deckOffsetY = platformHeight - 1
	local leftDeckCenterX = -((gapLength * 0.5) + (deckLength * 0.5))
	local rightDeckCenterX = (gapLength * 0.5) + (deckLength * 0.5)

	makeObstaclePart(obstacle.Name .. "_DeckA", Vector3.new(deckLength, 2, width), baseCFrame * CFrame.new(leftDeckCenterX, deckOffsetY, 0), colors.Dark, Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "_DeckB", Vector3.new(deckLength, 2, width), baseCFrame * CFrame.new(rightDeckCenterX, deckOffsetY, 0), colors.Dark, Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "_SupportA", Vector3.new(deckLength * 0.72, platformHeight, width * 0.72), baseCFrame * CFrame.new(leftDeckCenterX, platformHeight * 0.5, 0), colors.Trim, Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "_SupportB", Vector3.new(deckLength * 0.72, platformHeight, width * 0.72), baseCFrame * CFrame.new(rightDeckCenterX, platformHeight * 0.5, 0), colors.Trim, Enum.Material.Metal, obstacle.District)

	local rampLength = obstacle.RampLength or 22
	createRamp(obstacle.Name .. "_Launch", Vector3.new(width + 4, platformHeight, rampLength), baseCFrame * CFrame.new(-(gapLength * 0.5 + deckLength + (rampLength * 0.5)), platformHeight * 0.5, 0) * CFrame.Angles(0, math.rad(90), 0), obstacle.District, colors, {
		RunUpLength = obstacle.RunUpLength or 18,
		DeckLength = math.max(8, platformHeight * 0.9),
	})
	createRamp(obstacle.Name .. "_Landing", Vector3.new(width + 4, platformHeight, rampLength), baseCFrame * CFrame.new(gapLength * 0.5 + deckLength + (rampLength * 0.5), platformHeight * 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0), obstacle.District, colors, {
		RunUpLength = obstacle.RunUpLength or 18,
		DeckLength = math.max(8, platformHeight * 0.9),
	})
end

local function addCanalJump(obstacle)
	local colors = obstacleColors(obstacle.District)
	local baseCFrame = CFrame.new(Vector3.new(obstacle.Position.X, obstacle.Position.Y or 0, obstacle.Position.Z)) * obstacleRotation(obstacle)
	local jumpWidth = obstacle.Size.X
	local platformDepth = obstacle.PlatformDepth or 20
	local platformHeight = obstacle.PlatformHeight or 6
	local gapDepth = obstacle.GapLength or 66
	local rampLength = obstacle.RampLength or 22

	local northDeckPos = localPoint(baseCFrame, Vector3.new(0, 0, -((gapDepth * 0.5) + (platformDepth * 0.5))))
	local southDeckPos = localPoint(baseCFrame, Vector3.new(0, 0, (gapDepth * 0.5) + (platformDepth * 0.5)))
	local northTop = surfaceTopAt(northDeckPos.X, northDeckPos.Z, 0)
	local southTop = surfaceTopAt(southDeckPos.X, southDeckPos.Z, 0)

	local northDeckCFrame = CFrame.new(Vector3.new(northDeckPos.X, northTop, northDeckPos.Z)) * obstacleRotation(obstacle)
	local southDeckCFrame = CFrame.new(Vector3.new(southDeckPos.X, southTop, southDeckPos.Z)) * obstacleRotation(obstacle)
	makeObstaclePart(obstacle.Name .. "NorthDeck", Vector3.new(jumpWidth, 2, platformDepth), northDeckCFrame * CFrame.new(0, platformHeight - 1, 0), colors.Dark, Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "SouthDeck", Vector3.new(jumpWidth, 2, platformDepth), southDeckCFrame * CFrame.new(0, platformHeight - 1, 0), colors.Dark, Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "NorthSupport", Vector3.new(jumpWidth * 0.72, platformHeight, platformDepth * 0.72), northDeckCFrame * CFrame.new(0, platformHeight * 0.5, 0), colors.Trim, Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "SouthSupport", Vector3.new(jumpWidth * 0.72, platformHeight, platformDepth * 0.72), southDeckCFrame * CFrame.new(0, platformHeight * 0.5, 0), colors.Trim, Enum.Material.Metal, obstacle.District)

	createRamp(obstacle.Name .. "NorthRamp", Vector3.new(jumpWidth * 0.46, platformHeight, rampLength), northDeckCFrame * CFrame.new(0, platformHeight * 0.5, -((platformDepth * 0.5) + (rampLength * 0.5))) * CFrame.Angles(0, math.rad(180), 0), obstacle.District, colors, {
		RunUpLength = obstacle.RunUpLength or 24,
	})
	createRamp(obstacle.Name .. "SouthRamp", Vector3.new(jumpWidth * 0.46, platformHeight, rampLength), southDeckCFrame * CFrame.new(0, platformHeight * 0.5, (platformDepth * 0.5) + (rampLength * 0.5)) * CFrame.Angles(0, 0, 0), obstacle.District, colors, {
		RunUpLength = obstacle.RunUpLength or 24,
	})

	local archHeight = math.max(northTop, southTop) + platformHeight + 8
	makeObstaclePart(obstacle.Name .. "ArchBeam", Vector3.new(jumpWidth * 0.7, 2, gapDepth + 16), CFrame.new(obstacle.Position.X, archHeight, obstacle.Position.Z) * obstacleRotation(obstacle), Color3.fromRGB(110, 117, 124), Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "ArchPostL", Vector3.new(2, archHeight - Config.World.WaterLevel, 2), CFrame.new(obstacle.Position.X - (jumpWidth * 0.28), (archHeight - Config.World.WaterLevel) * 0.5 + Config.World.WaterLevel, obstacle.Position.Z) * obstacleRotation(obstacle), Color3.fromRGB(96, 102, 108), Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "ArchPostR", Vector3.new(2, archHeight - Config.World.WaterLevel, 2), CFrame.new(obstacle.Position.X + (jumpWidth * 0.28), (archHeight - Config.World.WaterLevel) * 0.5 + Config.World.WaterLevel, obstacle.Position.Z) * obstacleRotation(obstacle), Color3.fromRGB(96, 102, 108), Enum.Material.Metal, obstacle.District)
end

local function addQuarterPipe(obstacle)
	local colors = obstacleColors(obstacle.District)
	local baseCFrame = obstacleBaseCFrame(obstacle, obstacle.Size.Y * 0.5)
	createRamp(obstacle.Name, obstacle.Size, baseCFrame, obstacle.District, colors, {
		RunUpLength = obstacle.RunUpLength or 16,
		DeckLength = math.max(10, obstacle.Size.X * 0.35),
	})
	local deckLength = obstacle.DeckLength or 18
	makeObstaclePart(obstacle.Name .. "_Deck", Vector3.new(obstacle.Size.X, 2, deckLength), baseCFrame * CFrame.new(0, obstacle.Size.Y - 1, (obstacle.Size.Z * 0.5) + (deckLength * 0.5) - 2), Color3.fromRGB(72, 76, 82), Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "_SideL", Vector3.new(1, obstacle.Size.Y, obstacle.Size.Z + deckLength), baseCFrame * CFrame.new(-(obstacle.Size.X * 0.5) + 0.5, obstacle.Size.Y * 0.5, deckLength * 0.5), Color3.fromRGB(176, 181, 189), Enum.Material.Metal, obstacle.District)
	makeObstaclePart(obstacle.Name .. "_SideR", Vector3.new(1, obstacle.Size.Y, obstacle.Size.Z + deckLength), baseCFrame * CFrame.new((obstacle.Size.X * 0.5) - 0.5, obstacle.Size.Y * 0.5, deckLength * 0.5), Color3.fromRGB(176, 181, 189), Enum.Material.Metal, obstacle.District)
end

local function addDirtJump(obstacle)
	local colors = obstacleColors(obstacle.District)
	local baseCFrame = obstacleBaseCFrame(obstacle, obstacle.Size.Y * 0.5)
	createRamp(obstacle.Name, obstacle.Size, baseCFrame, obstacle.District, colors, {
		RunUpLength = obstacle.RunUpLength or 18,
		DeckLength = math.max(8, obstacle.Size.X * 0.3),
		Material = Enum.Material.Ground,
	})
	local dirtCap = makeObstaclePart(obstacle.Name .. "_Cap", Vector3.new(obstacle.Size.X, 0.5, obstacle.Size.Z * 0.2), baseCFrame * CFrame.new(0, obstacle.Size.Y * 0.42, obstacle.Size.Z * 0.22), Color3.fromRGB(171, 148, 97), Enum.Material.Ground, obstacle.District)
	dirtCap.Color = Color3.fromRGB(171, 148, 97)
	makeObstaclePart(obstacle.Name .. "_LandingMound", Vector3.new(obstacle.Size.X * 0.9, math.max(4, obstacle.Size.Y * 0.35), 12), baseCFrame * CFrame.new(0, obstacle.Size.Y * 0.78, (obstacle.Size.Z * 0.5) + 8), Color3.fromRGB(145, 108, 66), Enum.Material.Ground, obstacle.District)
end

local function addContainerStack(obstacle)
	local baseSurfaceTop = surfaceTopAt(obstacle.Position.X, obstacle.Position.Z, obstacle.Position.Y or 0)
	local baseCFrame = CFrame.new(Vector3.new(obstacle.Position.X, baseSurfaceTop, obstacle.Position.Z)) * obstacleRotation(obstacle)
	local colors = {
		Color3.fromRGB(59, 105, 170),
		Color3.fromRGB(170, 94, 64),
		Color3.fromRGB(85, 129, 104),
	}
	for layer = 0, 2 do
		for column = -1, 1 do
			local container = makeObstaclePart(obstacle.Name .. "_Container_" .. tostring(layer) .. "_" .. tostring(column), Vector3.new(22, 10, 10), baseCFrame * CFrame.new(column * 22, 5 + (layer * 10), (layer % 2 == 0 and 0 or 11)), colors[(layer % #colors) + 1], Enum.Material.Metal, obstacle.District)
			container.Color = colors[(layer % #colors) + 1]
		end
	end
	createRamp(obstacle.Name .. "_Launch", Vector3.new(20, 14, 28), baseCFrame * CFrame.new(-(obstacle.Size.X * 0.5) - 14, 7, 0) * CFrame.Angles(0, math.rad(90), 0), obstacle.District, obstacleColors(obstacle.District), {
		RunUpLength = obstacle.RunUpLength or 24,
		DeckLength = 10,
	})
	makeObstaclePart(obstacle.Name .. "_ServiceDeck", Vector3.new(24, 1.2, 12), baseCFrame * CFrame.new(-12, 16, 5), Color3.fromRGB(82, 87, 92), Enum.Material.Metal, obstacle.District)
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
