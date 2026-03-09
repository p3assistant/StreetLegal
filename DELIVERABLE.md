Update Addendum — 2026-03-09 Wheelie Hotfix

- Fixed the wheelie failure in live gameplay.
- Root causes were corrected in the bike controller: Roblox-mounted `Ctrl`/`W` inputs are now accepted even when seat controls mark them as processed, and the wheelie pitch/impulse were flipped so the front end now rotates upward instead of being driven nose-down.
- Final control behavior stays the same in spirit: tap `Ctrl`, then tap `W` to pop the wheelie; tap `W` again while the front is up to keep working the balance point.
- Chat/text focus still blocks those keys intentionally so typing in UI does not trigger stunts.

Update Addendum — 2026-03-08 Stronger Environment + UX + Bike Pass

- First spawn auto-opens the garage and focuses free starter bikes.
- HUD keeps a persistent Garage / Spawn Bike button on screen so players are never dumped on foot without direction.
- If no bike is active, a centered callout explicitly tells the player to select and spawn one.
- Free-bike flow centers on one-click `Equip & Spawn` from the garage.
- Bike visuals were rebuilt into more recognizable electric dirt bike silhouettes using Roblox parts/primitives, then refined further with added bodywork/detail pieces for stronger modern e-bike read.
- Bike names/descriptions were refreshed toward original e-dirt-bike-inspired lineup language instead of generic placeholder bikes.
- New visual tuning module: `src/ReplicatedStorage/Modules/BikeVisuals.lua`
- Steering input was corrected so `A`/left now yaws the bike left and `D`/right yaws it right.
- Traversal surfaces were normalized so roads, sidewalks, plazas, promenade/boardwalk space, and major park/quarry ride zones sit on effectively uniform rideable heights with decorative curbs no longer blocking bikes.
- Keyboard wheelie controls were added: tap `Ctrl`, then press `W` to pop a wheelie; repeated `W` taps let the rider hold and rebalance the balance point.
- The map generator received a substantial art-direction pass: improved lighting/atmosphere, road dressing, district identity, waterfront treatment, park/quarry shaping, props, signage, harbor structures, and more deliberate building silhouettes.

Assumptions

- Placeholder map art/models are acceptable as long as the Roblox Studio MVP is functional. This build uses primitive-generated geometry so the gameplay loop works immediately.
- Police riders use server-driven humanoid/pathfinding chasers with bike visuals instead of full physics-driven NPC motorcycles. That keeps the MVP stable, performant, and actually testable now.
- Premium monetization hooks are included, but `GamePassId` values remain placeholders until the production experience is published and IDs are assigned.
- Bike handling uses a practical arcade controller: `VehicleSeat` for Roblox-native input + a hidden stability hull + `AlignOrientation` for upright feel + server-side speed validation.
- DataStore behavior in Studio may fall back to session-only behavior if API services are unavailable or the place is unpublished.

A) One-Page Game Design Doc (GDD)

**Title:** Street Legal  
**Genre:** Open-world multiplayer dirt bike stunt / police-heat sandbox  
**Platform:** Roblox (mobile + PC first)  
**Fantasy:** You’re ripping through a Baltimore-inspired city on dirt bikes that range from stock starters to loud, fast illegal builds. Hit alleys, parks, rooftops, canals, stair sets, construction ramps, docks, and off-road trails while managing heat from local police.

**Core Loop**
1. Spawn or buy a bike from the garage.
2. Cruise the city, chain jumps, and explore districts.
3. Earn cash by landing stunts.
4. Spend cash on faster or more specialized bikes.
5. Manage heat from illegal riding, speeding, noise, and collisions.
6. Escape patrols, or get arrested and reset at the station.

**Player Motivation**
- Master the city’s stunt lines.
- Unlock bikes with distinct feel/stats.
- Learn safe routes vs. risky “heat-heavy” routes.
- Improve combo score and speed skill without needing pay-to-win monetization.

**Progression**
- 3 free starter bikes capped at 34–38 MPH.
- Mid-tier cash bikes at 46–58 MPH.
- Endgame cash/premium hook bikes at 68–80 MPH.
- Persistence for cash, owned bikes, equipped bike, and stunt/arrest stats.

**Session Structure**
- Quick session: spawn + hit a stunt circuit for 5–10 minutes.
- Mid session: unlock a new bike or outrun police across multiple districts.
- Long session: master routes, grind stunt payouts, and test higher-speed bikes.

**Ethical Monetization**
- Core fun is fully playable on free bikes.
- Premium hooks are optional and not required to access the main loop.
- Better bikes help, but the game is still skill-first and route-based.

B) World Design

**World Theme:** A fictional, Baltimore-inspired city with rowhouse density, industrial shoreline, green spaces, drainage infrastructure, elevated highway, and rough off-road edges. It is not a direct map rip.

**Districts**
- **Redline Row** — rowhouse zone with alleys, rooftops, tight stunt lines, and side-street rhythm.
- **Penn Market** — central commercial core with mid-rise blocks, intersections, and highway access.
- **Druid Heights** — parkland/skate area with stairs, quarter-pipe-style obstacles, and green cut-throughs.
- **Iron Harbor** — industrial docks, warehouses, yard lanes, shipping containers, and heavy wide-line jumps.
- **Canal Side** — shoreline/canal route with drainage gaps, boardwalk gaps, and water-adjacent risk.
- **Quarry Run** — off-road dirt zone with trail jumps and forgiving stunt terrain for freeride play.

**Obstacle Inventory in MVP**
- Rooftop jump
- Construction launch ramp
- Stair set
- Canal jump line
- Highway gap
- Quarter-pipe / skatepark feature
- Harbor container stack launch
- Dirt trail jump A
- Dirt trail jump B
- Boardwalk gap

**Navigation Shape**
- Major north/south and east/west roads for readable routing
- Narrower alleys and side streets for technical riding
- Elevated road segment for spectacle and speed
- Shoreline edge and canal for visual identity + gap gameplay

C) Systems Design

**Bike System**
- Each bike has: top speed, acceleration, handling, jump, durability, unlock type, and legal/illegal street status.
- Spawn/equip/purchase is server-authoritative via a validated `RemoteFunction`.
- Bike ownership and selected bike are saved to DataStores.
- Physics model uses a hidden stability hull for reliable balance and multiplayer sync, plus visual bike parts welded on top.

**Bike Physics Guidance / Tuning**
- Controller path: `StarterPlayer/StarterPlayerScripts/BikeController.client.lua`
- Feel parameters live mainly in `ReplicatedStorage/Modules/Config.lua`
- Best knobs to tune:
  - `Config.Bike.ArcadeController.BaseAcceleration`
  - `Config.Bike.ArcadeController.BaseBrake`
  - `Config.Bike.ArcadeController.BaseTurnRate`
  - `Config.Bike.ArcadeController.SideSlipDamp`
  - `Config.Bike.HopImpulse`
  - per-bike `Acceleration`, `Handling`, `Jump`, `Durability`, `TopSpeedMph`
- Current approach is intentionally “good-feel arcade,” not hardcore sim. That is the right MVP move for Roblox dirt-bike traversal.

**Wanted / Heat System**
- Heat rises from illegal street bikes, speeding, excessive speed, collisions, near misses, and stunt noise.
- Heat decays over time when the player stops doing stupid stuff.
- Wanted level drives police pursuit urgency.
- Arrest flow: caught → teleported to station → fine applied → wanted reset → cooldown before immediate retrigger.

**Police System**
- Police patrol between generated patrol nodes.
- When a player has heat and is within range, officers switch from patrol to chase.
- Pursuit uses `PathfindingService` with periodic repaths.
- Officers arrest players within distance threshold.

**UI / UX**
- `M` opens the garage/shop.
- Garage supports browse / buy / equip / spawn.
- HUD shows speed, gear, district, wanted state, combo text, and minimap.
- `R` respawns the equipped bike.
- `Q` triggers hop/jump impulse.
- `Ctrl`, then `W` pops a wheelie.
- Repeated `W` taps while the wheelie is up nudge the balance point higher and keep the wheelie alive.

**Multiplayer / Anti-Exploit**
- Currency, ownership, wanted state, and arrest logic are server authoritative.
- Client controls local bike feel for responsiveness, but server checks bike ownership and clamps excessive speed.
- Remote usage is validated by action type and bike ownership.

**Performance**
- `StreamingEnabled = true`
- World uses simple, low-instance-count primitives rather than expensive unique art
- Police update loop is lightweight and uses a small officer count
- Wanted scanning runs on a sensible server interval

D) Roblox Implementation Plan

```text
ReplicatedStorage/
  Remotes/
    Manifest.lua
  Modules/
    Config.lua
    BikeDefinitions.lua
    WantedConfig.lua
ServerScriptService/
  Bootstrap.server.lua
  Services/
    DataService.lua
    PurchaseService.lua
    WantedService.lua
    PoliceService.lua
StarterGui/
  UI/
    BikeMenu.client.lua
    HUD.client.lua
StarterPlayer/
  StarterPlayerScripts/
    BikeController.client.lua
Workspace/
  Map/
    CityBuilder.server.lua
  Spawns/
    SpawnData.lua
  Police/
    NPCController.server.lua
  Ramps/
    ObstacleCatalog.lua
```

**Execution Order**
1. `Bootstrap.server.lua` creates remotes and initializes server services.
2. `CityBuilder.server.lua` generates the playable city, spawn pads, patrol nodes, and obstacle set.
3. `NPCController.server.lua` waits for bootstrap/world readiness, then starts police patrol/chase logic.
4. Client scripts provide garage UX, HUD, and bike feel.

**Remote Inventory**
- `BikeAction` (`RemoteFunction`) — validated garage/shop/spawn/equip actions
- `ClientTelemetry` (`RemoteEvent`) — stunt/near-miss reporting with server-side checks
- `DataSync` (`RemoteEvent`) — server → client profile snapshot updates
- `WantedState` (`RemoteEvent`) — server → client heat updates
- `Notification` (`RemoteEvent`) — server → client toasts/messages
- `PoliceState` (`RemoteEvent`) — server → client arrest/pursuit state

E) Code (Luau) — runnable script skeletons + key logic

The following code is the actual runnable MVP implementation in this project.

### `ReplicatedStorage/Modules/Config.lua`

```lua
local RunService = game:GetService("RunService")

local Config = {
	Experience = {
		Name = "Street Legal",
		Version = "0.1.0",
		Build = "mvp-production",
	},
	Gameplay = {
		DataStoreName = "StreetLegal_PlayerData_v1",
		AutosaveInterval = 60,
		PoliceScanInterval = 1,
		ArrestCooldown = 20,
		DevelopmentMode = RunService:IsStudio(),
		MaxBikeDistanceFromPlayer = 260,
		BikeRespawnHeight = 8,
		TeleportSpawnOffset = 16,
	},
	Economy = {
		StarterCash = 2500,
		StarterBikeId = "harbor_100",
		ArrestFineBase = 250,
		ArrestFinePerLevel = 175,
		StuntPayoutMultiplier = 0.06,
		StuntPayoutMin = 15,
		StuntPayoutMax = 250,
		CashCap = 250000,
	},
	Bike = {
		MphToStuds = 1.6,
		MaxServerSpeedBuffer = 1.22,
		GroundRayLength = 5.5,
		HopImpulse = 105,
		JumpCooldown = 0.85,
		NearMissRadius = 10,
		NearMissTelemetryCooldown = 2.4,
		ArcadeController = {
			BaseAcceleration = 68,
			BaseBrake = 90,
			BaseTurnRate = 1.7,
			CoastDrag = 2.1,
			ReverseSpeedFactor = 0.35,
			AirControlFactor = 0.2,
			SideSlipDamp = 0.22,
		},
		Stability = {
			Responsiveness = 30,
			MaxTorque = 1000000,
			UprightLookOffset = 10,
		},
	},
	Police = {
		OfficerCount = 6,
		PatrolSpeed = 18,
		ChaseSpeed = 27,
		DetectionRange = 140,
		PursuitMaxRange = 320,
		ArrestDistance = 9,
		RepathInterval = 1.2,
		LineOfSightGrace = 3,
	},
	World = {
		Bounds = {
			Min = Vector3.new(-960, -40, -960),
			Max = Vector3.new(960, 220, 960),
		},
		StreetY = 0,
		WaterLevel = -8,
		PoliceStationPosition = Vector3.new(315, 8, -45),
		DistrictColors = {
			PennMarket = Color3.fromRGB(74, 74, 78),
			RedlineRow = Color3.fromRGB(122, 69, 53),
			DruidHeights = Color3.fromRGB(64, 108, 76),
			IronHarbor = Color3.fromRGB(88, 92, 95),
			CanalSide = Color3.fromRGB(67, 92, 112),
			QuarryRun = Color3.fromRGB(112, 90, 60),
		},
	},
	UI = {
		Primary = Color3.fromRGB(255, 170, 60),
		Accent = Color3.fromRGB(255, 233, 164),
		Danger = Color3.fromRGB(255, 79, 79),
		Success = Color3.fromRGB(103, 225, 146),
		Background = Color3.fromRGB(17, 20, 25),
		Panel = Color3.fromRGB(24, 28, 35),
	},
}

return Config

```

### `ReplicatedStorage/Modules/BikeDefinitions.lua`

```lua
local Config = require(script.Parent.Config)

local function studsPerSecond(mph)
	return math.floor(mph * Config.Bike.MphToStuds + 0.5)
end

local Bikes = {
	harbor_100 = {
		Id = "harbor_100",
		DisplayName = "Harbor 100",
		UnlockType = "Free",
		Price = 0,
		GamePassId = 0,
		Tier = 1,
		TopSpeedMph = 34,
		TopSpeedStuds = studsPerSecond(34),
		Acceleration = 0.92,
		Handling = 0.95,
		Jump = 0.88,
		Durability = 0.95,
		IllegalOnStreet = false,
		PoliceHeatMultiplier = 1,
		Description = "Balanced starter bike built for learning lines and city hops.",
		Paint = Color3.fromRGB(242, 152, 53),
	},
	row_125 = {
		Id = "row_125",
		DisplayName = "Row 125",
		UnlockType = "Free",
		Price = 0,
		GamePassId = 0,
		Tier = 1,
		TopSpeedMph = 38,
		TopSpeedStuds = studsPerSecond(38),
		Acceleration = 1.0,
		Handling = 0.9,
		Jump = 0.92,
		Durability = 0.9,
		IllegalOnStreet = false,
		PoliceHeatMultiplier = 1,
		Description = "Quick starter with more snap for stair sets and park gaps.",
		Paint = Color3.fromRGB(215, 70, 70),
	},
	greenway_140 = {
		Id = "greenway_140",
		DisplayName = "Greenway 140",
		UnlockType = "Free",
		Price = 0,
		GamePassId = 0,
		Tier = 1,
		TopSpeedMph = 36,
		TopSpeedStuds = studsPerSecond(36),
		Acceleration = 0.87,
		Handling = 1.02,
		Jump = 1.0,
		Durability = 0.84,
		IllegalOnStreet = false,
		PoliceHeatMultiplier = 1,
		Description = "Lightweight freeride starter with the best hop response in the free tier.",
		Paint = Color3.fromRGB(73, 184, 104),
	},
	druid_250 = {
		Id = "druid_250",
		DisplayName = "Druid 250",
		UnlockType = "Cash",
		Price = 2800,
		GamePassId = 0,
		Tier = 2,
		TopSpeedMph = 46,
		TopSpeedStuds = studsPerSecond(46),
		Acceleration = 1.08,
		Handling = 0.96,
		Jump = 1.06,
		Durability = 1.0,
		IllegalOnStreet = false,
		PoliceHeatMultiplier = 1.05,
		Description = "Mid-tier dirt bike with stronger acceleration and cleaner landings.",
		Paint = Color3.fromRGB(59, 138, 230),
	},
	canal_runner = {
		Id = "canal_runner",
		DisplayName = "Canal Runner",
		UnlockType = "Cash",
		Price = 5200,
		GamePassId = 0,
		Tier = 3,
		TopSpeedMph = 58,
		TopSpeedStuds = studsPerSecond(58),
		Acceleration = 1.16,
		Handling = 1.04,
		Jump = 1.08,
		Durability = 0.98,
		IllegalOnStreet = true,
		PoliceHeatMultiplier = 1.2,
		Description = "Street-modified stunt bike. Fast, loud, and very obvious to police.",
		Paint = Color3.fromRGB(137, 112, 232),
	},
	iron_450 = {
		Id = "iron_450",
		DisplayName = "Iron 450",
		UnlockType = "Cash",
		Price = 9000,
		GamePassId = 0,
		Tier = 4,
		TopSpeedMph = 68,
		TopSpeedStuds = studsPerSecond(68),
		Acceleration = 1.22,
		Handling = 0.9,
		Jump = 1.12,
		Durability = 1.15,
		IllegalOnStreet = true,
		PoliceHeatMultiplier = 1.3,
		Description = "Heavy race-tuned build with brutal pull and a bigger arrest profile.",
		Paint = Color3.fromRGB(255, 214, 74),
	},
	shoreline_rr = {
		Id = "shoreline_rr",
		DisplayName = "Shoreline RR",
		UnlockType = "Cash",
		Price = 14500,
		GamePassId = 0,
		Tier = 5,
		TopSpeedMph = 80,
		TopSpeedStuds = studsPerSecond(80),
		Acceleration = 1.3,
		Handling = 0.94,
		Jump = 1.1,
		Durability = 1.08,
		IllegalOnStreet = true,
		PoliceHeatMultiplier = 1.45,
		Description = "Late-game speed bike for highway gaps and long coastal runs.",
		Paint = Color3.fromRGB(248, 248, 248),
	},
	blue_line = {
		Id = "blue_line",
		DisplayName = "Blue Line Special",
		UnlockType = "Gamepass",
		Price = 0,
		GamePassId = 0,
		Tier = 4,
		TopSpeedMph = 72,
		TopSpeedStuds = studsPerSecond(72),
		Acceleration = 1.2,
		Handling = 1.05,
		Jump = 1.02,
		Durability = 1.05,
		IllegalOnStreet = true,
		PoliceHeatMultiplier = 1.35,
		Description = "Optional premium cosmetic-performance hybrid hook. GamePassId is a placeholder by default.",
		Paint = Color3.fromRGB(54, 163, 255),
	},
}

return Bikes

```

### `ReplicatedStorage/Modules/WantedConfig.lua`

```lua
local WantedConfig = {
	MaxHeat = 140,
	Decay = {
		Delay = 8,
		Interval = 4,
		Amount = 2,
	},
	Levels = {
		{ Threshold = 0, Label = "Clean" },
		{ Threshold = 15, Label = "Observed" },
		{ Threshold = 35, Label = "Hot" },
		{ Threshold = 65, Label = "Pursuit" },
		{ Threshold = 100, Label = "Lockdown" },
	},
	Infractions = {
		IllegalStreetBike = { Heat = 6, Cooldown = 8 },
		Speeding = { Heat = 4, Cooldown = 4 },
		ExcessiveSpeed = { Heat = 9, Cooldown = 4 },
		NearMiss = { Heat = 7, Cooldown = 3 },
		Collision = { Heat = 10, Cooldown = 5 },
		StuntNoise = { Heat = 5, Cooldown = 5 },
		EscapeMove = { Heat = 8, Cooldown = 7 },
	},
}

return WantedConfig

```

### `ReplicatedStorage/Remotes/Manifest.lua`

```lua
return {
	{ Name = "BikeAction", ClassName = "RemoteFunction" },
	{ Name = "ClientTelemetry", ClassName = "RemoteEvent" },
	{ Name = "DataSync", ClassName = "RemoteEvent" },
	{ Name = "WantedState", ClassName = "RemoteEvent" },
	{ Name = "Notification", ClassName = "RemoteEvent" },
	{ Name = "PoliceState", ClassName = "RemoteEvent" },
}

```

### `ServerScriptService/Bootstrap.server.lua`

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local remoteManifest = require(ReplicatedStorage.Remotes.Manifest)

local remotes = {}
for _, definition in ipairs(remoteManifest) do
	local remote = ReplicatedStorage.Remotes:FindFirstChild(definition.Name)
	if not remote then
		remote = Instance.new(definition.ClassName)
		remote.Name = definition.Name
		remote.Parent = ReplicatedStorage.Remotes
	end
	remotes[definition.Name] = remote
end

local DataService = require(ServerScriptService.Services.DataService)
local WantedService = require(ServerScriptService.Services.WantedService)
local PurchaseService = require(ServerScriptService.Services.PurchaseService)

Workspace.StreamingEnabled = true
ReplicatedStorage:SetAttribute("StreetLegalBootstrapReady", false)

DataService:Init(remotes)
WantedService:Init(DataService, remotes)
PurchaseService:Init(DataService, WantedService, remotes)

ReplicatedStorage:SetAttribute("StreetLegalBootstrapReady", true)

```

### `ServerScriptService/Services/DataService.lua`

```lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)

local DataService = {
	Profiles = {},
	Remotes = nil,
	Store = nil,
	Initialized = false,
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

	for bikeId, bike in pairs(BikeDefinitions) do
		if bike.UnlockType == "Free" then
			profile.OwnedBikes[bikeId] = true
		end
	end

	if not profile.OwnedBikes[profile.EquippedBikeId] then
		for bikeId, owned in pairs(profile.OwnedBikes) do
			if owned then
				profile.EquippedBikeId = bikeId
				break
			end
		end
	end

	return profile
end

function DataService:Init(remotes)
	if self.Initialized then
		return
	end

	self.Initialized = true
	self.Remotes = remotes
	self.Store = DataStoreService:GetDataStore(Config.Gameplay.DataStoreName)

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
	local ok, savedData = pcall(function()
		return self.Store:GetAsync(tostring(player.UserId))
	end)

	if ok and type(savedData) == "table" then
		profile = reconcile(savedData, buildDefaultProfile())
	end

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

```

### `ServerScriptService/Services/PurchaseService.lua`

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)

local PurchaseService = {
	ActiveBikes = {},
	RuntimeFolder = nil,
	BikesFolder = nil,
	DataService = nil,
	WantedService = nil,
	Remotes = nil,
	Initialized = false,
}

local function now()
	return Workspace:GetServerTimeNow()
end

local function createWeld(parent, part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = parent
	return weld
end

local function createPart(parent, name, size, cframe, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = true
	part.Anchored = false
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function getRuntimeFolder()
	local runtimeFolder = Workspace:FindFirstChild("StreetLegalRuntime")
	if not runtimeFolder then
		runtimeFolder = Instance.new("Folder")
		runtimeFolder.Name = "StreetLegalRuntime"
		runtimeFolder.Parent = Workspace
	end

	local bikesFolder = runtimeFolder:FindFirstChild("Bikes")
	if not bikesFolder then
		bikesFolder = Instance.new("Folder")
		bikesFolder.Name = "Bikes"
		bikesFolder.Parent = runtimeFolder
	end

	return runtimeFolder, bikesFolder
end

local function copyBikeForClient(_, bikeId)
	local bike = BikeDefinitions[bikeId]
	local payload = {
		Id = bike.Id,
		DisplayName = bike.DisplayName,
		UnlockType = bike.UnlockType,
		Price = bike.Price,
		GamePassId = bike.GamePassId,
		Tier = bike.Tier,
		TopSpeedMph = bike.TopSpeedMph,
		Acceleration = bike.Acceleration,
		Handling = bike.Handling,
		Jump = bike.Jump,
		Durability = bike.Durability,
		IllegalOnStreet = bike.IllegalOnStreet,
		Description = bike.Description,
	}
	return payload
end

function PurchaseService:Init(dataService, wantedService, remotes)
	if self.Initialized then
		return
	end

	self.Initialized = true
	self.DataService = dataService
	self.WantedService = wantedService
	self.Remotes = remotes
	self.RuntimeFolder, self.BikesFolder = getRuntimeFolder()

	self.Remotes.BikeAction.OnServerInvoke = function(player, action, payload)
		return self:HandleBikeAction(player, action, payload)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end

		for bikeId, bike in pairs(BikeDefinitions) do
			if bike.GamePassId == gamePassId and gamePassId ~= 0 then
				self.DataService:GrantBike(player, bikeId)
				self.DataService:SetEquippedBike(player, bikeId)
				if self.Remotes.Notification then
					self.Remotes.Notification:FireClient(player, {
						Type = "success",
						Text = string.format("Unlocked %s.", bike.DisplayName),
					})
				end
				break
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:DespawnBike(player)
	end)
end

function PurchaseService:GetCatalog(player)
	local catalog = {}
	for bikeId, bike in pairs(BikeDefinitions) do
		local entry = copyBikeForClient(player, bikeId)
		entry.Owned = self.DataService:OwnsBike(player, bikeId)
		table.insert(catalog, entry)
	end

	table.sort(catalog, function(a, b)
		if a.Tier == b.Tier then
			return a.Price < b.Price
		end
		return a.Tier < b.Tier
	end)

	return catalog
end

function PurchaseService:GetGarageState(player)
	return {
		Success = true,
		Catalog = self:GetCatalog(player),
		Snapshot = self.DataService:GetClientSnapshot(player),
	}
end

function PurchaseService:GetSpawnCFrame(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local forward = rootPart.CFrame.LookVector
		return CFrame.new(rootPart.Position + (forward * Config.Gameplay.TeleportSpawnOffset) + Vector3.new(0, Config.Gameplay.BikeRespawnHeight, 0), rootPart.Position + (forward * 60))
	end

	local spawns = Workspace:FindFirstChild("Spawns")
	if spawns then
		for _, descendant in ipairs(spawns:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("SpawnPad") then
				return descendant.CFrame + Vector3.new(0, Config.Gameplay.BikeRespawnHeight, 0)
			end
		end
	end

	return CFrame.new(0, 8, 0)
end

function PurchaseService:SetBikeNetworkOwner(model, player)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			pcall(function()
				descendant:SetNetworkOwner(player)
			end)
		end
	end
end

function PurchaseService:CreateBikeModel(player, bikeId)
	local bike = BikeDefinitions[bikeId]
	local model = Instance.new("Model")
	model.Name = string.format("%s_%d", bikeId, player.UserId)
	model:SetAttribute("StreetLegalBike", true)
	model:SetAttribute("BikeId", bikeId)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("IllegalOnStreet", bike.IllegalOnStreet)
	model:SetAttribute("TopSpeedStuds", bike.TopSpeedStuds)
	model:SetAttribute("SpawnTime", now())

	local spawnCFrame = self:GetSpawnCFrame(player)
	local paint = bike.Paint or Color3.fromRGB(255, 255, 255)

	local hull = createPart(model, "Hull", Vector3.new(4.2, 1.2, 7), spawnCFrame, paint, Enum.Material.SmoothPlastic, 1)
	hull.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.8, 0.1, 1, 1)
	model.PrimaryPart = hull

	local frame = createPart(model, "Frame", Vector3.new(1.4, 1, 5), spawnCFrame * CFrame.new(0, 1.2, 0), paint, Enum.Material.Metal, 0)
	local tank = createPart(model, "Tank", Vector3.new(1.6, 1.4, 1.8), spawnCFrame * CFrame.new(0, 1.9, -0.2), paint, Enum.Material.SmoothPlastic, 0)
	local handle = createPart(model, "HandleBar", Vector3.new(3.2, 0.3, 0.3), spawnCFrame * CFrame.new(0, 2.35, -1.65), Color3.fromRGB(35, 35, 35), Enum.Material.Metal, 0)
	local rearWheel = createPart(model, "RearWheel", Vector3.new(2.4, 2.4, 0.8), spawnCFrame * CFrame.new(0, 1.1, 2.35) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(28, 28, 28), Enum.Material.Rubber, 0)
	local frontWheel = createPart(model, "FrontWheel", Vector3.new(2.2, 2.2, 0.7), spawnCFrame * CFrame.new(0, 1.1, -2.3) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(28, 28, 28), Enum.Material.Rubber, 0)
	rearWheel.Shape = Enum.PartType.Cylinder
	frontWheel.Shape = Enum.PartType.Cylinder
	local skidLeft = createPart(model, "SkidLeft", Vector3.new(0.6, 0.6, 3.5), spawnCFrame * CFrame.new(-1.5, 0.6, 0), paint, Enum.Material.SmoothPlastic, 1)
	local skidRight = createPart(model, "SkidRight", Vector3.new(0.6, 0.6, 3.5), spawnCFrame * CFrame.new(1.5, 0.6, 0), paint, Enum.Material.SmoothPlastic, 1)

	for _, part in ipairs({ frame, tank, handle, rearWheel, frontWheel, skidLeft, skidRight }) do
		createWeld(part, hull, part)
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.CFrame = spawnCFrame * CFrame.new(0, 2.2, 0.6)
	seat.Color = Color3.fromRGB(30, 30, 30)
	seat.Material = Enum.Material.SmoothPlastic
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.Parent = model
	createWeld(seat, hull, seat)

	local bodyAttachment = Instance.new("Attachment")
	bodyAttachment.Name = "BodyAttachment"
	bodyAttachment.Parent = hull

	local align = Instance.new("AlignOrientation")
	align.Name = "BodyAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = bodyAttachment
	align.Responsiveness = Config.Bike.Stability.Responsiveness
	align.MaxTorque = Config.Bike.Stability.MaxTorque
	align.RigidityEnabled = false
	align.ReactionTorqueEnabled = false
	align.CFrame = spawnCFrame
	align.Parent = hull

	local enginePitch = Instance.new("NumberValue")
	enginePitch.Name = "EnginePitch"
	enginePitch.Value = 1
	enginePitch.Parent = model

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if not occupant then
			player:SetAttribute("StreetLegalMounted", false)
			return
		end

		if player.Character and occupant.Parent == player.Character then
			player:SetAttribute("StreetLegalMounted", true)
		else
			occupant.Sit = false
		end
	end)

	local lastCollision = 0
	hull.Touched:Connect(function(hit)
		if not model.Parent then
			return
		end
		if player.Character and hit:IsDescendantOf(player.Character) then
			return
		end
		if hit:IsDescendantOf(model) then
			return
		end

		local speed = hull.AssemblyLinearVelocity.Magnitude
		local stamp = now()
		if speed >= 36 and stamp - lastCollision > 1 then
			lastCollision = stamp
			if self.WantedService then
				self.WantedService:AddHeat(player, "Collision")
			end
			hull.AssemblyLinearVelocity *= 0.62
		end
	end)

	model.Parent = self.BikesFolder
	self:SetBikeNetworkOwner(model, player)

	return model
end

function PurchaseService:DespawnBike(player)
	local active = self.ActiveBikes[player]
	if active and active.Parent then
		active:Destroy()
	end
	self.ActiveBikes[player] = nil
	player:SetAttribute("StreetLegalActiveBikeId", nil)
	player:SetAttribute("StreetLegalMounted", false)
	return true
end

function PurchaseService:SpawnBike(player, bikeId)
	if not BikeDefinitions[bikeId] then
		return { Success = false, Message = "Unknown bike." }
	end

	if not self.DataService:OwnsBike(player, bikeId) then
		return { Success = false, Message = "Bike not owned." }
	end

	self:DespawnBike(player)

	local model = self:CreateBikeModel(player, bikeId)
	self.ActiveBikes[player] = model
	player:SetAttribute("StreetLegalActiveBikeId", bikeId)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = model:FindFirstChild("Seat")
	if humanoid and seat then
		task.delay(0.15, function()
			if humanoid.Parent and seat.Parent then
				seat:Sit(humanoid)
			end
		end)
	end

	return {
		Success = true,
		Message = string.format("Spawned %s.", BikeDefinitions[bikeId].DisplayName),
		BikeId = bikeId,
	}
end

function PurchaseService:BuyBike(player, bikeId)
	local bike = BikeDefinitions[bikeId]
	if not bike then
		return { Success = false, Message = "Bike not found." }
	end

	if self.DataService:OwnsBike(player, bikeId) then
		return { Success = true, Message = "Bike already owned.", Snapshot = self.DataService:GetClientSnapshot(player) }
	end

	if bike.UnlockType == "Cash" then
		local ok, reason = self.DataService:SpendCash(player, bike.Price)
		if not ok then
			return { Success = false, Message = reason or "Purchase failed." }
		end
		self.DataService:GrantBike(player, bikeId)
		self.DataService:SetEquippedBike(player, bikeId)
		return { Success = true, Message = string.format("Purchased %s.", bike.DisplayName), Snapshot = self.DataService:GetClientSnapshot(player) }
	end

	if bike.UnlockType == "Gamepass" then
		if bike.GamePassId == 0 then
			return { Success = false, Message = "GamePassId placeholder is not configured yet." }
		end

		local ownsPass = false
		pcall(function()
			ownsPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, bike.GamePassId)
		end)

		if ownsPass then
			self.DataService:GrantBike(player, bikeId)
			self.DataService:SetEquippedBike(player, bikeId)
			return { Success = true, Message = string.format("Unlocked %s.", bike.DisplayName), Snapshot = self.DataService:GetClientSnapshot(player) }
		end

		MarketplaceService:PromptGamePassPurchase(player, bike.GamePassId)
		return { Success = false, Message = "Game pass prompt opened." }
	end

	return { Success = false, Message = "This bike is not purchasable." }
end

function PurchaseService:EquipBike(player, bikeId)
	if not BikeDefinitions[bikeId] then
		return { Success = false, Message = "Unknown bike." }
	end

	if not self.DataService:OwnsBike(player, bikeId) then
		return { Success = false, Message = "Bike not owned." }
	end

	self.DataService:SetEquippedBike(player, bikeId)
	return { Success = true, Message = string.format("Equipped %s.", BikeDefinitions[bikeId].DisplayName), Snapshot = self.DataService:GetClientSnapshot(player) }
end

function PurchaseService:HandleBikeAction(player, action, payload)
	payload = payload or {}
	local profile = self.DataService:GetProfile(player)
	if not profile then
		profile = self.DataService:LoadProfile(player)
	end
	player:SetAttribute("StreetLegalProfileReady", profile ~= nil)

	if action == "GetGarage" then
		return self:GetGarageState(player)
	elseif action == "BuyBike" then
		return self:BuyBike(player, payload.BikeId)
	elseif action == "EquipBike" then
		return self:EquipBike(player, payload.BikeId)
	elseif action == "SpawnBike" then
		local bikeId = payload.BikeId or profile.EquippedBikeId
		return self:SpawnBike(player, bikeId)
	elseif action == "DespawnBike" then
		self:DespawnBike(player)
		return { Success = true, Message = "Bike stored." }
	elseif action == "RespawnBike" then
		local bikeId = payload.BikeId or profile.EquippedBikeId
		return self:SpawnBike(player, bikeId)
	end

	return { Success = false, Message = "Unsupported action." }
end

return PurchaseService

```

### `ServerScriptService/Services/WantedService.lua`

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)
local WantedConfig = require(ReplicatedStorage.Modules.WantedConfig)

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
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if action == "StuntLanded" then
		local score = tonumber(payload.Score) or 0
		local airtime = tonumber(payload.Airtime) or 0
		if score <= 0 or score > 4000 or airtime < 0 or airtime > 12 then
			return
		end

		self:AwardStunt(player, score)
		local surface = self:GetSurfaceInfo(rootPart.Position, { character })
		if surface == "Street" then
			self:AddHeat(player, "StuntNoise")
		end
	elseif action == "NearMiss" then
		local speed = rootPart.AssemblyLinearVelocity.Magnitude / Config.Bike.MphToStuds
		if speed < 25 then
			return
		end
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
		local surface, district = self:GetSurfaceInfo(rootPart.Position, { character })
		player:SetAttribute("StreetLegalDistrict", district)
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
	self:PushState(player, true)

	self:DestroyActiveBike(player)
	self.DataService:AdjustCash(player, -fine)
	self.DataService:RecordArrest(player)

	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(Config.World.PoliceStationPosition))
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

```

### `ServerScriptService/Services/PoliceService.lua`

```lua
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

```

### `StarterPlayer/StarterPlayerScripts/BikeController.client.lua`

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Modules.Config)
local BikeDefinitions = require(ReplicatedStorage.Modules.BikeDefinitions)

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local telemetryRemote = remotesFolder:WaitForChild("ClientTelemetry")

local controller = {
	Character = nil,
	Humanoid = nil,
	BikeModel = nil,
	Hull = nil,
	Seat = nil,
	Align = nil,
	BikeDef = nil,
	Yaw = 0,
	Speed = 0,
	HopQueued = false,
	NextHopAt = 0,
	AirborneAt = nil,
	AirborneYaw = nil,
	ComboExpiresAt = 0,
	NextNearMissAt = 0,
}

local function clearHudState()
	player:SetAttribute("StreetLegalSpeedMph", 0)
	player:SetAttribute("StreetLegalGear", "Neutral")
	player:SetAttribute("StreetLegalBikeName", "On Foot")
	player:SetAttribute("StreetLegalComboText", "")
	player:SetAttribute("StreetLegalComboScore", 0)
end

local function currentTime()
	return Workspace:GetServerTimeNow()
end

local function getCharacterParts()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	return character, humanoid
end

local function getYawFromCFrame(cf)
	local _, yaw, _ = cf:ToOrientation()
	return yaw
end

local function getGroundInfo(origin, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false

	local result = Workspace:Raycast(origin + Vector3.new(0, 2, 0), Vector3.new(0, -Config.Bike.GroundRayLength, 0), params)
	if not result then
		return false, nil, "Unknown"
	end

	return true, result.Instance, result.Instance:GetAttribute("SurfaceType") or "Unknown"
end

local function getActiveBikeFromSeat(humanoid)
	local seatPart = humanoid.SeatPart
	if not seatPart or not seatPart:IsA("VehicleSeat") then
		return nil
	end

	local model = seatPart:FindFirstAncestorOfClass("Model")
	if not model or not model:GetAttribute("StreetLegalBike") then
		return nil
	end

	if model:GetAttribute("OwnerUserId") ~= player.UserId then
		return nil
	end

	return model
end

local function scanForNearMiss(controllerState)
	if not controllerState.Hull then
		return
	end

	local nowStamp = currentTime()
	if nowStamp < controllerState.NextNearMissAt then
		return
	end

	local speedMph = math.abs(controllerState.Speed) / Config.Bike.MphToStuds
	if speedMph < 25 then
		return
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { controllerState.BikeModel, player.Character }
	local nearbyParts = Workspace:GetPartBoundsInRadius(controllerState.Hull.Position, Config.Bike.NearMissRadius, params)
	for _, part in ipairs(nearbyParts) do
		if part:GetAttribute("NearMissTarget") then
			controllerState.NextNearMissAt = nowStamp + Config.Bike.NearMissTelemetryCooldown
			telemetryRemote:FireServer("NearMiss", {
				Part = part.Name,
				Speed = speedMph,
			})
			break
		end
	end
end

local function applyCombo(controllerState, airtime)
	if airtime < 0.35 then
		return
	end

	local spinAmount = math.abs(controllerState.Yaw - (controllerState.AirborneYaw or controllerState.Yaw))
	local score = math.floor((airtime * 170) + (spinAmount * 28) + (math.abs(controllerState.Speed) / Config.Bike.MphToStuds * 1.5))
	score = math.clamp(score, 25, 2500)
	local comboText = string.format("AIR %0.1fs • %d", airtime, score)
	player:SetAttribute("StreetLegalComboText", comboText)
	player:SetAttribute("StreetLegalComboScore", score)
	controllerState.ComboExpiresAt = currentTime() + 3
	telemetryRemote:FireServer("StuntLanded", {
		Score = score,
		Airtime = airtime,
	})
end

local function setActiveBike(controllerState, bikeModel)
	if controllerState.BikeModel == bikeModel then
		return
	end

	controllerState.BikeModel = bikeModel
	controllerState.Hull = bikeModel and bikeModel:FindFirstChild("Hull") or nil
	controllerState.Seat = bikeModel and bikeModel:FindFirstChild("Seat") or nil
	controllerState.Align = controllerState.Hull and controllerState.Hull:FindFirstChild("BodyAlign") or nil
	controllerState.BikeDef = bikeModel and BikeDefinitions[bikeModel:GetAttribute("BikeId")] or nil
	controllerState.Speed = 0
	controllerState.AirborneAt = nil
	controllerState.AirborneYaw = nil

	if controllerState.Hull then
		controllerState.Yaw = getYawFromCFrame(controllerState.Hull.CFrame)
	end

	if controllerState.BikeDef then
		player:SetAttribute("StreetLegalBikeName", controllerState.BikeDef.DisplayName)
	else
		player:SetAttribute("StreetLegalBikeName", "On Foot")
	end
end

local function updateBikePhysics(controllerState, dt)
	if not controllerState.BikeModel or not controllerState.Hull or not controllerState.Seat or not controllerState.BikeDef then
		return
	end

	local bike = controllerState.BikeDef
	local hull = controllerState.Hull
	local character = player.Character
	local throttle = controllerState.Seat.ThrottleFloat
	local steer = controllerState.Seat.SteerFloat
	local nowStamp = currentTime()
	local grounded, _, surfaceType = getGroundInfo(hull.Position, { controllerState.BikeModel, character })
	local topSpeed = bike.TopSpeedStuds
	local accel = Config.Bike.ArcadeController.BaseAcceleration * bike.Acceleration
	local brake = Config.Bike.ArcadeController.BaseBrake * bike.Durability
	local turnRate = Config.Bike.ArcadeController.BaseTurnRate * bike.Handling
	local reverseMax = topSpeed * Config.Bike.ArcadeController.ReverseSpeedFactor

	if grounded then
		if throttle > 0 then
			controllerState.Speed = math.min(topSpeed, controllerState.Speed + (accel * throttle * dt))
		elseif throttle < 0 then
			if controllerState.Speed > 0 then
				controllerState.Speed = math.max(0, controllerState.Speed - (brake * dt))
			else
				controllerState.Speed = math.max(-reverseMax, controllerState.Speed + (accel * throttle * dt))
			end
		else
			local drag = Config.Bike.ArcadeController.CoastDrag * topSpeed * dt * 0.12
			if math.abs(controllerState.Speed) < drag then
				controllerState.Speed = 0
			elseif controllerState.Speed > 0 then
				controllerState.Speed -= drag
			else
				controllerState.Speed += drag
			end
		end
	else
		controllerState.Speed *= (1 - (0.025 * dt))
	end

	local steerFactor = math.clamp((math.abs(controllerState.Speed) / math.max(1, topSpeed)) + 0.2, 0.18, 1.2)
	local airFactor = grounded and 1 or Config.Bike.ArcadeController.AirControlFactor
	controllerState.Yaw += steer * turnRate * steerFactor * airFactor * dt * (controllerState.Speed >= 0 and 1 or -1)

	local look = CFrame.fromOrientation(0, controllerState.Yaw, 0).LookVector
	local currentVelocity = hull.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
	local sideVelocity = horizontalVelocity - (look * horizontalVelocity:Dot(look))
	local targetHorizontal = (look * controllerState.Speed) - (sideVelocity * Config.Bike.ArcadeController.SideSlipDamp)
	hull.AssemblyLinearVelocity = Vector3.new(targetHorizontal.X, currentVelocity.Y, targetHorizontal.Z)

	if controllerState.Align then
		controllerState.Align.CFrame = CFrame.lookAt(hull.Position, hull.Position + look, Vector3.yAxis)
	end

	if controllerState.HopQueued and grounded and nowStamp >= controllerState.NextHopAt then
		controllerState.HopQueued = false
		controllerState.NextHopAt = nowStamp + Config.Bike.JumpCooldown
		local impulse = Vector3.new(0, hull.AssemblyMass * Config.Bike.HopImpulse * bike.Jump, 0)
		hull:ApplyImpulse(impulse)
	end

	if not grounded and not controllerState.AirborneAt then
		controllerState.AirborneAt = nowStamp
		controllerState.AirborneYaw = controllerState.Yaw
	elseif grounded and controllerState.AirborneAt then
		applyCombo(controllerState, nowStamp - controllerState.AirborneAt)
		controllerState.AirborneAt = nil
		controllerState.AirborneYaw = nil
	end

	scanForNearMiss(controllerState)

	local speedMph = math.floor((math.abs(controllerState.Speed) / Config.Bike.MphToStuds) + 0.5)
	local gear = "Neutral"
	if controllerState.Speed > 1 then
		gear = surfaceType == "OffRoad" and "Trail" or "Drive"
	elseif controllerState.Speed < -1 then
		gear = "Reverse"
	end

	if nowStamp >= controllerState.ComboExpiresAt then
		player:SetAttribute("StreetLegalComboText", "")
		player:SetAttribute("StreetLegalComboScore", 0)
	end

	player:SetAttribute("StreetLegalSpeedMph", speedMph)
	player:SetAttribute("StreetLegalGear", gear)
	player:SetAttribute("StreetLegalBikeName", bike.DisplayName)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		controller.HopQueued = true
	end
end)

player.CharacterAdded:Connect(function(character)
	controller.Character = character
	controller.Humanoid = character:WaitForChild("Humanoid")
	clearHudState()
end)

controller.Character, controller.Humanoid = getCharacterParts()
clearHudState()

RunService.RenderStepped:Connect(function(dt)
	if not controller.Humanoid or not controller.Humanoid.Parent then
		return
	end

	local activeBike = getActiveBikeFromSeat(controller.Humanoid)
	setActiveBike(controller, activeBike)

	if controller.BikeModel then
		updateBikePhysics(controller, dt)
	else
		if currentTime() >= controller.ComboExpiresAt then
			player:SetAttribute("StreetLegalComboText", "")
			player:SetAttribute("StreetLegalComboScore", 0)
		end
		clearHudState()
	end
end)

```

### `StarterGui/UI/BikeMenu.client.lua`

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Modules.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local bikeAction = remotesFolder:WaitForChild("BikeAction")
local dataSync = remotesFolder:WaitForChild("DataSync")
local notificationRemote = remotesFolder:WaitForChild("Notification")

local state = {
	Catalog = {},
	Snapshot = {
		Cash = 0,
		OwnedBikes = {},
		EquippedBikeId = nil,
	},
	SelectedBikeId = nil,
	Message = "",
	Busy = false,
}

local existingGui = playerGui:FindFirstChild("StreetLegalGarage")
if existingGui then
	existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetLegalGarage"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.3
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.78, 0.74)
panel.BackgroundColor3 = Config.UI.Panel
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 46)
title.Position = UDim2.fromOffset(12, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 28
title.TextColor3 = Config.UI.Accent
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Street Legal Garage"
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -24, 0, 22)
subtitle.Position = UDim2.fromOffset(12, 52)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(190, 195, 201)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Starter bikes are free. Progression bikes unlock with cash. Premium hook is optional."
subtitle.Parent = panel

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0, 220, 0, 30)
cashLabel.Position = UDim2.new(1, -232, 0, 18)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextSize = 18
cashLabel.TextColor3 = Config.UI.Success
cashLabel.TextXAlignment = Enum.TextXAlignment.Right
cashLabel.Text = "$0"
cashLabel.Parent = panel

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.fromOffset(14, 90)
listFrame.Size = UDim2.new(0.42, -20, 1, -148)
listFrame.BackgroundColor3 = Config.UI.Background
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.fromOffset(0, 0)
listFrame.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 12)
listCorner.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = listFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 10)
listPadding.PaddingLeft = UDim.new(0, 10)
listPadding.PaddingRight = UDim.new(0, 10)
listPadding.PaddingBottom = UDim.new(0, 10)
listPadding.Parent = listFrame

local detailFrame = Instance.new("Frame")
detailFrame.Position = UDim2.new(0.45, 0, 0, 90)
detailFrame.Size = UDim2.new(0.55, -16, 1, -148)
detailFrame.BackgroundColor3 = Config.UI.Background
detailFrame.BorderSizePixel = 0
detailFrame.Parent = panel

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 12)
detailCorner.Parent = detailFrame

local bikeName = Instance.new("TextLabel")
bikeName.Size = UDim2.new(1, -20, 0, 40)
bikeName.Position = UDim2.fromOffset(12, 12)
bikeName.BackgroundTransparency = 1
bikeName.Font = Enum.Font.GothamBlack
bikeName.TextSize = 26
bikeName.TextColor3 = Config.UI.Primary
bikeName.TextXAlignment = Enum.TextXAlignment.Left
bikeName.Text = "Select a bike"
bikeName.Parent = detailFrame

local bikeDesc = Instance.new("TextLabel")
bikeDesc.Size = UDim2.new(1, -24, 0, 70)
bikeDesc.Position = UDim2.fromOffset(12, 54)
bikeDesc.BackgroundTransparency = 1
bikeDesc.Font = Enum.Font.Gotham
bikeDesc.TextSize = 16
bikeDesc.TextWrapped = true
bikeDesc.TextColor3 = Color3.fromRGB(208, 212, 217)
bikeDesc.TextXAlignment = Enum.TextXAlignment.Left
bikeDesc.TextYAlignment = Enum.TextYAlignment.Top
bikeDesc.Text = ""
bikeDesc.Parent = detailFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -24, 0, 150)
statsLabel.Position = UDim2.fromOffset(12, 132)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 18
statsLabel.TextWrapped = true
statsLabel.TextColor3 = Color3.fromRGB(227, 228, 231)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Text = ""
statsLabel.Parent = detailFrame

local buttonRow = Instance.new("Frame")
buttonRow.Size = UDim2.new(1, -24, 0, 46)
buttonRow.Position = UDim2.new(0, 12, 1, -92)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = detailFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, -24, 0, 24)
messageLabel.Position = UDim2.new(0, 12, 1, -38)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextSize = 16
messageLabel.TextColor3 = Config.UI.Accent
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Text = "[M] closes garage"
messageLabel.Parent = detailFrame

local function makeButton(text, widthScale, color)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(widthScale, -8, 1, 0)
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(18, 18, 18)
	button.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Parent = buttonRow
	return button
end

local equipButton = makeButton("Equip", 0.32, Config.UI.Accent)
local buyButton = makeButton("Buy", 0.32, Config.UI.Primary)
local spawnButton = makeButton("Spawn", 0.32, Config.UI.Success)
spawnButton.Position = UDim2.new(0.68, 0, 0, 0)
buyButton.Position = UDim2.new(0.34, 0, 0, 0)
equipButton.Position = UDim2.new(0, 0, 0, 0)

local function setMessage(text, color)
	state.Message = text
	messageLabel.Text = text
	messageLabel.TextColor3 = color or Config.UI.Accent
end

local function setSnapshot(snapshot)
	if not snapshot then
		return
	end
	state.Snapshot = snapshot
	cashLabel.Text = string.format("$%d", snapshot.Cash or 0)
end

local function findBike(id)
	for _, bike in ipairs(state.Catalog) do
		if bike.Id == id then
			return bike
		end
	end
	return nil
end

local function updateDetails()
	local bike = findBike(state.SelectedBikeId)
	if not bike then
		bikeName.Text = "Select a bike"
		bikeDesc.Text = "Choose a bike from the left list."
		statsLabel.Text = ""
		return
	end

	bikeName.Text = bike.DisplayName
	bikeDesc.Text = bike.Description
	local owned = state.Snapshot.OwnedBikes and state.Snapshot.OwnedBikes[bike.Id]
	local costText = bike.UnlockType == "Cash" and ("$" .. tostring(bike.Price)) or (bike.UnlockType == "Gamepass" and "Game Pass" or "Free")
	statsLabel.Text = table.concat({
		string.format("Ownership: %s", owned and "Owned" or "Locked"),
		string.format("Unlock: %s", costText),
		string.format("Top Speed: %d MPH", bike.TopSpeedMph),
		string.format("Acceleration: %.2f", bike.Acceleration),
		string.format("Handling: %.2f", bike.Handling),
		string.format("Jump: %.2f", bike.Jump),
		string.format("Durability: %.2f", bike.Durability),
		string.format("Street Heat: %s", bike.IllegalOnStreet and "High" or "Low"),
	}, "\n")

	equipButton.Text = state.Snapshot.EquippedBikeId == bike.Id and "Equipped" or "Equip"
	buyButton.Text = owned and "Owned" or (bike.UnlockType == "Cash" and ("Buy $" .. tostring(bike.Price)) or (bike.UnlockType == "Gamepass" and "Unlock" or "Free"))
	spawnButton.Text = "Spawn"
end

local function renderCatalog()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, bike in ipairs(state.Catalog) do
		local owned = state.Snapshot.OwnedBikes and state.Snapshot.OwnedBikes[bike.Id]
		local row = Instance.new("TextButton")
		row.Name = bike.Id
		row.Size = UDim2.new(1, -4, 0, 62)
		row.BackgroundColor3 = state.SelectedBikeId == bike.Id and Color3.fromRGB(52, 60, 74) or Color3.fromRGB(34, 39, 46)
		row.AutoButtonColor = true
		row.Text = ""
		row.LayoutOrder = index
		row.Parent = listFrame
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -16, 0, 24)
		nameLabel.Position = UDim2.fromOffset(10, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 18
		nameLabel.TextColor3 = owned and Config.UI.Accent or Color3.fromRGB(223, 227, 231)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = bike.DisplayName
		nameLabel.Parent = row

		local metaLabel = Instance.new("TextLabel")
		metaLabel.Size = UDim2.new(1, -16, 0, 20)
		metaLabel.Position = UDim2.fromOffset(10, 34)
		metaLabel.BackgroundTransparency = 1
		metaLabel.Font = Enum.Font.Gotham
		metaLabel.TextSize = 14
		metaLabel.TextColor3 = Color3.fromRGB(175, 181, 188)
		metaLabel.TextXAlignment = Enum.TextXAlignment.Left
		metaLabel.Text = string.format("%d MPH • %s", bike.TopSpeedMph, owned and "Owned" or bike.UnlockType)
		metaLabel.Parent = row

		row.MouseButton1Click:Connect(function()
			state.SelectedBikeId = bike.Id
			renderCatalog()
			updateDetails()
		end)
	end

	task.defer(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end)
end

local function refreshGarage()
	if state.Busy then
		return
	end
	state.Busy = true
	local ok, response = pcall(function()
		return bikeAction:InvokeServer("GetGarage")
	end)
	state.Busy = false

	if not ok or not response then
		setMessage("Garage sync failed.", Config.UI.Danger)
		return
	end

	state.Catalog = response.Catalog or {}
	setSnapshot(response.Snapshot or state.Snapshot)
	if not state.SelectedBikeId then
		state.SelectedBikeId = state.Snapshot.EquippedBikeId or (state.Catalog[1] and state.Catalog[1].Id)
	end
	if not findBike(state.SelectedBikeId) and state.Catalog[1] then
		state.SelectedBikeId = state.Catalog[1].Id
	end
	renderCatalog()
	updateDetails()
end

local function invokeAction(action)
	if state.Busy or not state.SelectedBikeId then
		return
	end
	state.Busy = true
	local ok, response = pcall(function()
		return bikeAction:InvokeServer(action, { BikeId = state.SelectedBikeId })
	end)
	state.Busy = false

	if not ok or not response then
		setMessage("Action failed.", Config.UI.Danger)
		return
	end

	if response.Snapshot then
		setSnapshot(response.Snapshot)
	end

	setMessage(response.Message or "Done.", response.Success and Config.UI.Success or Config.UI.Danger)
	refreshGarage()
end

equipButton.MouseButton1Click:Connect(function()
	invokeAction("EquipBike")
end)

buyButton.MouseButton1Click:Connect(function()
	local bike = findBike(state.SelectedBikeId)
	if bike and bike.UnlockType == "Free" then
		setMessage("This bike is already free.", Config.UI.Accent)
		return
	end
	invokeAction("BuyBike")
end)

spawnButton.MouseButton1Click:Connect(function()
	invokeAction("SpawnBike")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.M then
		gui.Enabled = not gui.Enabled
		if gui.Enabled then
			refreshGarage()
			setMessage("M closes garage", Config.UI.Accent)
		end
	end
end)

dataSync.OnClientEvent:Connect(function(snapshot)
	setSnapshot(snapshot)
	updateDetails()
	renderCatalog()
end)

notificationRemote.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.Text then
		setMessage(payload.Text, payload.Type == "danger" and Config.UI.Danger or Config.UI.Accent)
	end
end)

refreshGarage()

```

### `StarterGui/UI/HUD.client.lua`

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Modules.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local wantedStateRemote = remotesFolder:WaitForChild("WantedState")
local policeStateRemote = remotesFolder:WaitForChild("PoliceState")
local notificationRemote = remotesFolder:WaitForChild("Notification")
local dataSyncRemote = remotesFolder:WaitForChild("DataSync")
local bikeAction = remotesFolder:WaitForChild("BikeAction")

local existingGui = playerGui:FindFirstChild("StreetLegalHUD")
if existingGui then
	existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetLegalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local speedFrame = Instance.new("Frame")
speedFrame.Position = UDim2.new(0, 18, 1, -130)
speedFrame.Size = UDim2.fromOffset(240, 104)
speedFrame.BackgroundColor3 = Config.UI.Background
speedFrame.BackgroundTransparency = 0.08
speedFrame.Parent = root
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 14)
speedCorner.Parent = speedFrame

local bikeLabel = Instance.new("TextLabel")
bikeLabel.Size = UDim2.new(1, -18, 0, 22)
bikeLabel.Position = UDim2.fromOffset(12, 10)
bikeLabel.BackgroundTransparency = 1
bikeLabel.Font = Enum.Font.GothamBold
bikeLabel.TextSize = 16
bikeLabel.TextColor3 = Config.UI.Accent
bikeLabel.TextXAlignment = Enum.TextXAlignment.Left
bikeLabel.Text = "On Foot"
bikeLabel.Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -18, 0, 44)
speedLabel.Position = UDim2.fromOffset(12, 28)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBlack
speedLabel.TextSize = 36
speedLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Text = "0 MPH"
speedLabel.Parent = speedFrame

local gearLabel = Instance.new("TextLabel")
gearLabel.Size = UDim2.new(1, -18, 0, 20)
gearLabel.Position = UDim2.fromOffset(12, 74)
gearLabel.BackgroundTransparency = 1
gearLabel.Font = Enum.Font.Gotham
gearLabel.TextSize = 16
gearLabel.TextColor3 = Color3.fromRGB(190, 195, 202)
gearLabel.TextXAlignment = Enum.TextXAlignment.Left
gearLabel.Text = "Neutral"
gearLabel.Parent = speedFrame

local heatFrame = Instance.new("Frame")
heatFrame.Position = UDim2.new(0, 18, 0, 18)
heatFrame.Size = UDim2.fromOffset(280, 90)
heatFrame.BackgroundColor3 = Config.UI.Background
heatFrame.BackgroundTransparency = 0.08
heatFrame.Parent = root
local heatCorner = Instance.new("UICorner")
heatCorner.CornerRadius = UDim.new(0, 14)
heatCorner.Parent = heatFrame

local wantedLabel = Instance.new("TextLabel")
wantedLabel.Size = UDim2.new(1, -20, 0, 24)
wantedLabel.Position = UDim2.fromOffset(12, 10)
wantedLabel.BackgroundTransparency = 1
wantedLabel.Font = Enum.Font.GothamBlack
wantedLabel.TextSize = 20
wantedLabel.TextColor3 = Config.UI.Danger
wantedLabel.TextXAlignment = Enum.TextXAlignment.Left
wantedLabel.Text = "HEAT: CLEAN"
wantedLabel.Parent = heatFrame

local heatBarBg = Instance.new("Frame")
heatBarBg.Position = UDim2.fromOffset(12, 44)
heatBarBg.Size = UDim2.new(1, -24, 0, 18)
heatBarBg.BackgroundColor3 = Color3.fromRGB(46, 49, 55)
heatBarBg.Parent = heatFrame
local heatBarBgCorner = Instance.new("UICorner")
heatBarBgCorner.CornerRadius = UDim.new(1, 0)
heatBarBgCorner.Parent = heatBarBg

local heatBar = Instance.new("Frame")
heatBar.Size = UDim2.new(0, 0, 1, 0)
heatBar.BackgroundColor3 = Config.UI.Danger
heatBar.Parent = heatBarBg
local heatCorner2 = Instance.new("UICorner")
heatCorner2.CornerRadius = UDim.new(1, 0)
heatCorner2.Parent = heatBar

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, -24, 0, 18)
promptLabel.Position = UDim2.fromOffset(12, 66)
promptLabel.BackgroundTransparency = 1
promptLabel.Font = Enum.Font.Gotham
promptLabel.TextSize = 13
promptLabel.TextColor3 = Color3.fromRGB(190, 195, 202)
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Text = "M Garage • R Respawn • Q Hop • Break line of sight to cool heat"
promptLabel.Parent = heatFrame

local comboLabel = Instance.new("TextLabel")
comboLabel.AnchorPoint = Vector2.new(0.5, 0)
comboLabel.Position = UDim2.fromScale(0.5, 0.12)
comboLabel.Size = UDim2.fromOffset(360, 34)
comboLabel.BackgroundTransparency = 1
comboLabel.Font = Enum.Font.GothamBlack
comboLabel.TextSize = 26
comboLabel.TextColor3 = Config.UI.Accent
comboLabel.Text = ""
comboLabel.Parent = root

local toastLabel = Instance.new("TextLabel")
toastLabel.AnchorPoint = Vector2.new(0.5, 0)
toastLabel.Position = UDim2.fromScale(0.5, 0.18)
toastLabel.Size = UDim2.fromOffset(420, 28)
toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 18
toastLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
toastLabel.Text = ""
toastLabel.Parent = root

local miniMap = Instance.new("Frame")
miniMap.Position = UDim2.new(1, -150, 0, 18)
miniMap.Size = UDim2.fromOffset(132, 132)
miniMap.BackgroundColor3 = Config.UI.Background
miniMap.BackgroundTransparency = 0.08
miniMap.Parent = root
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 14)
miniCorner.Parent = miniMap

local miniTitle = Instance.new("TextLabel")
miniTitle.Size = UDim2.new(1, 0, 0, 20)
miniTitle.BackgroundTransparency = 1
miniTitle.Font = Enum.Font.GothamBold
miniTitle.TextSize = 14
miniTitle.TextColor3 = Config.UI.Accent
miniTitle.Text = "CITY MAP"
miniTitle.Parent = miniMap

local mapCanvas = Instance.new("Frame")
mapCanvas.Position = UDim2.fromOffset(8, 24)
mapCanvas.Size = UDim2.fromOffset(116, 100)
mapCanvas.BackgroundColor3 = Color3.fromRGB(28, 31, 37)
mapCanvas.Parent = miniMap
local mapCanvasCorner = Instance.new("UICorner")
mapCanvasCorner.CornerRadius = UDim.new(0, 10)
mapCanvasCorner.Parent = mapCanvas

local function addMiniDistrict(name, pos, size, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = pos
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel = 0
	frame.Parent = mapCanvas
	return frame
end

addMiniDistrict("RedlineRow", UDim2.new(0.02, 0, 0.16, 0), UDim2.new(0.28, 0, 0.62, 0), Config.World.DistrictColors.RedlineRow)
addMiniDistrict("PennMarket", UDim2.new(0.32, 0, 0.18, 0), UDim2.new(0.24, 0, 0.56, 0), Config.World.DistrictColors.PennMarket)
addMiniDistrict("DruidHeights", UDim2.new(0.12, 0, 0.02, 0), UDim2.new(0.48, 0, 0.16, 0), Config.World.DistrictColors.DruidHeights)
addMiniDistrict("IronHarbor", UDim2.new(0.58, 0, 0.46, 0), UDim2.new(0.28, 0, 0.38, 0), Config.World.DistrictColors.IronHarbor)
addMiniDistrict("CanalSide", UDim2.new(0.72, 0, 0.12, 0), UDim2.new(0.24, 0, 0.28, 0), Config.World.DistrictColors.CanalSide)
addMiniDistrict("QuarryRun", UDim2.new(0.0, 0, 0.72, 0), UDim2.new(0.22, 0, 0.24, 0), Config.World.DistrictColors.QuarryRun)

local playerDot = Instance.new("Frame")
playerDot.Size = UDim2.fromOffset(8, 8)
playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerDot.BorderSizePixel = 0
playerDot.Parent = mapCanvas
local playerDotCorner = Instance.new("UICorner")
playerDotCorner.CornerRadius = UDim.new(1, 0)
playerDotCorner.Parent = playerDot

local districtLabel = Instance.new("TextLabel")
districtLabel.Position = UDim2.new(1, -240, 0, 160)
districtLabel.Size = UDim2.fromOffset(220, 24)
districtLabel.BackgroundTransparency = 1
districtLabel.Font = Enum.Font.GothamBold
districtLabel.TextSize = 16
districtLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
districtLabel.TextXAlignment = Enum.TextXAlignment.Right
districtLabel.Text = "District: Unknown"
districtLabel.Parent = root

local localState = {
	Heat = 0,
	Level = 0,
	Label = "Clean",
	EquippedBikeId = nil,
	ToastExpiresAt = 0,
}

local function setToast(text, color)
	toastLabel.Text = text or ""
	toastLabel.TextColor3 = color or Color3.fromRGB(245, 245, 245)
	localState.ToastExpiresAt = os.clock() + 3
end

local function getCurrentRootPart()
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function refreshSpeed()
	local speed = player:GetAttribute("StreetLegalSpeedMph") or 0
	local gear = player:GetAttribute("StreetLegalGear") or "Neutral"
	local bikeName = player:GetAttribute("StreetLegalBikeName") or "On Foot"
	local combo = player:GetAttribute("StreetLegalComboText") or ""
	local district = player:GetAttribute("StreetLegalDistrict") or "Unknown"
	bikeLabel.Text = bikeName
	speedLabel.Text = string.format("%d MPH", speed)
	gearLabel.Text = gear
	comboLabel.Text = combo
	districtLabel.Text = "District: " .. district
end

local function refreshHeat()
	wantedLabel.Text = string.format("HEAT: %s", string.upper(localState.Label or "Clean"))
	heatBar.Size = UDim2.new(math.clamp((localState.Heat or 0) / 140, 0, 1), 0, 1, 0)
end

local function refreshMinimap()
	local rootPart = getCurrentRootPart()
	if not rootPart then
		return
	end

	local minBounds = Config.World.Bounds.Min
	local maxBounds = Config.World.Bounds.Max
	local xAlpha = math.clamp((rootPart.Position.X - minBounds.X) / (maxBounds.X - minBounds.X), 0, 1)
	local zAlpha = math.clamp((rootPart.Position.Z - minBounds.Z) / (maxBounds.Z - minBounds.Z), 0, 1)
	playerDot.Position = UDim2.new(xAlpha, -4, zAlpha, -4)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		local ok, response = pcall(function()
			return bikeAction:InvokeServer("RespawnBike", { BikeId = localState.EquippedBikeId })
		end)
		if ok and response then
			setToast(response.Message or "Bike respawned.", response.Success and Config.UI.Success or Config.UI.Danger)
		end
	end
end)

wantedStateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	localState.Heat = payload.Heat or 0
	localState.Level = payload.Level or 0
	localState.Label = payload.Label or "Clean"
	refreshHeat()
end)

policeStateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.Type == "ARRESTED" then
		setToast(string.format("Arrested by %s • Fine $%d", payload.Officer or "BPD", payload.Fine or 0), Config.UI.Danger)
	end
end)

notificationRemote.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.Text then
		setToast(payload.Text, payload.Type == "danger" and Config.UI.Danger or (payload.Type == "success" and Config.UI.Success or Config.UI.Accent))
	end
end)

dataSyncRemote.OnClientEvent:Connect(function(snapshot)
	if type(snapshot) ~= "table" then
		return
	end
	localState.EquippedBikeId = snapshot.EquippedBikeId
end)

for _, attributeName in ipairs({ "StreetLegalSpeedMph", "StreetLegalGear", "StreetLegalBikeName", "StreetLegalComboText", "StreetLegalDistrict" }) do
	player:GetAttributeChangedSignal(attributeName):Connect(refreshSpeed)
end

refreshSpeed()
refreshHeat()

RunService.RenderStepped:Connect(function()
	refreshMinimap()
	if toastLabel.Text ~= "" and os.clock() >= localState.ToastExpiresAt then
		toastLabel.Text = ""
	end
	refreshSpeed()
end)

```

### `Workspace/Police/NPCController.server.lua`

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local PoliceService = require(ServerScriptService.Services.PoliceService)

while not ReplicatedStorage:GetAttribute("StreetLegalBootstrapReady") or not Workspace:GetAttribute("StreetLegalWorldReady") do
	task.wait(0.25)
end

PoliceService:Init(script.Parent)

```

F) Testing & Launch Checklist

- [x] Rojo project created and mapped to required Roblox services/folders
- [x] Build artifact generated with `rojo build`
- [x] Runtime world generator creates city districts, roads, spawns, patrol nodes, shoreline, and obstacle set
- [x] Free and paid bikes defined with stat differences and persistence hooks
- [x] Server-authoritative garage/shop/equip/spawn flow implemented
- [x] Wanted/heat escalation implemented
- [x] Police patrol + chase + arrest loop implemented
- [x] HUD + garage UI implemented
- [x] README written with Studio + Rojo workflow
- [x] Git repo initialized, pushed to GitHub

**Recommended Studio QA Pass**
- [ ] Open `build/StreetLegal.rbxlx` in Roblox Studio
- [ ] Press Play and verify the world generates fully
- [ ] Open garage with `M`
- [ ] Spawn each free starter bike
- [ ] Confirm `R` respawns the equipped bike
- [ ] Confirm `Q` hop works while mounted
- [ ] Confirm `Ctrl` then `W` reliably pops a wheelie
- [ ] Confirm repeated `W` taps visibly sustain/control the wheelie
- [ ] Trigger heat with speeding and illegal bikes
- [ ] Confirm police begin patrol/chase and can arrest
- [ ] Confirm arrest teleports to station and removes heat
- [ ] Confirm DataStore persistence in a published testing place with API services enabled
- [ ] Replace placeholder `GamePassId` values before live premium rollout
- [ ] Tune district art pass, lighting polish, VFX, and sound before public launch

G) Milestones

**Milestone 1 — Foundation**
- Rojo project initialized
- Shared config and bike catalogs defined
- Git + GitHub repo created

**Milestone 2 — Core Gameplay MVP**
- Bike spawn/equip/persistence loop
- Functional arcade dirt-bike controller
- Runtime city generation with Baltimore-inspired districting
- Stunt payouts and garage UX

**Milestone 3 — Law/Heat Layer**
- Wanted system
- Police patrol, chase, arrest flow
- Server-side validation and state broadcasting

**Milestone 4 — Build + Handoff**
- Rojo build artifact produced
- README written
- Final deliverable generated
- Repo pushed with working MVP codebase

**Best Next Steps After This MVP**
1. Replace primitive map art with authored district kits while preserving current routing.
2. Add audio/VFX (engine loops, sirens, landings, heat escalation feedback).
3. Add more stunt scoring types (wheelies, stoppies, line multipliers, rooftop route bonuses).
4. Add civilian traffic/ped AI for richer near-miss gameplay.
5. Convert premium hook from placeholder IDs to production marketplace setup.
