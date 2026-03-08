local RunService = game:GetService("RunService")

local Config = {
	Experience = {
		Name = "Street Legal",
		Version = "0.3.0",
		Build = "environment-art-pass",
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
