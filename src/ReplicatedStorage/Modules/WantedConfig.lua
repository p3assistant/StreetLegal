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
