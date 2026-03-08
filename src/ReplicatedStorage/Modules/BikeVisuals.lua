local function deepMerge(base, overrides)
	local merged = {}
	for key, value in pairs(base) do
		if type(value) == "table" then
			merged[key] = deepMerge(value, {})
		else
			merged[key] = value
		end
	end

	for key, value in pairs(overrides or {}) do
		if type(value) == "table" and type(merged[key]) == "table" then
			merged[key] = deepMerge(merged[key], value)
		else
			merged[key] = value
		end
	end

	return merged
end

local baseProfile = {
	Geometry = {
		Wheelbase = 5.55,
		FrontWheelRadius = 1.18,
		RearWheelRadius = 1.24,
		WheelThickness = 0.56,
		FrontAxleY = 0.60,
		RearAxleY = 0.62,
		SeatHeight = 2.24,
		SeatLength = 2.1,
		SeatZ = 0.52,
		BatterySize = Vector3.new(1.12, 1.48, 1.46),
		BatteryY = 1.55,
		BatteryZ = 0.12,
		HeadTubeY = 2.16,
		HeadTubeZ = -1.44,
		HeadTubeTilt = -24,
		FrontFenderY = 1.92,
		FrontFenderZ = -2.12,
		FrontFenderPitch = 10,
		RearFenderY = 2.18,
		RearFenderZ = 1.96,
		RearFenderPitch = -5,
		TailRise = 8,
		HandleWidth = 2.62,
		HandleY = 2.55,
		HandleZ = -1.78,
		ForkSpread = 0.54,
		ForkPitch = -18,
		FrameWidth = 0.44,
		SwingarmLength = 2.12,
		SwingarmRise = 15,
		MotorY = 0.98,
		MotorZ = 0.32,
	},
	Colors = {
		Primary = Color3.fromRGB(232, 232, 232),
		Accent = Color3.fromRGB(255, 170, 60),
		Frame = Color3.fromRGB(57, 60, 68),
		Battery = Color3.fromRGB(36, 39, 44),
		Seat = Color3.fromRGB(24, 24, 24),
		Fork = Color3.fromRGB(204, 183, 108),
		Trim = Color3.fromRGB(154, 160, 166),
		Rim = Color3.fromRGB(72, 76, 84),
		Headlight = Color3.fromRGB(255, 247, 196),
		Taillight = Color3.fromRGB(255, 91, 91),
	},
}

local profiles = {
	harbor_100 = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 5.35,
			SeatHeight = 2.12,
			SeatLength = 1.96,
			HeadTubeZ = -1.34,
			HeadTubeTilt = -27,
			HandleWidth = 2.56,
			TailRise = 6,
		},
		Colors = {
			Primary = Color3.fromRGB(242, 152, 53),
			Accent = Color3.fromRGB(255, 209, 112),
			Frame = Color3.fromRGB(42, 44, 49),
			Battery = Color3.fromRGB(25, 27, 31),
			Seat = Color3.fromRGB(26, 26, 26),
			Fork = Color3.fromRGB(208, 188, 112),
			Trim = Color3.fromRGB(129, 134, 141),
			Rim = Color3.fromRGB(64, 66, 72),
		},
	}),
	row_125 = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 5.78,
			FrontWheelRadius = 1.2,
			RearWheelRadius = 1.26,
			SeatHeight = 2.28,
			SeatLength = 2.18,
			HeadTubeY = 2.2,
			HeadTubeTilt = -22,
			FrontFenderY = 1.98,
			HandleWidth = 2.72,
			TailRise = 10,
		},
		Colors = {
			Primary = Color3.fromRGB(215, 70, 70),
			Accent = Color3.fromRGB(255, 229, 229),
			Frame = Color3.fromRGB(45, 47, 52),
			Battery = Color3.fromRGB(33, 36, 41),
			Seat = Color3.fromRGB(28, 28, 28),
			Fork = Color3.fromRGB(199, 199, 206),
			Trim = Color3.fromRGB(155, 161, 170),
			Rim = Color3.fromRGB(74, 77, 84),
		},
	}),
	greenway_140 = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 5.48,
			FrontWheelRadius = 1.16,
			RearWheelRadius = 1.22,
			SeatHeight = 2.18,
			HeadTubeTilt = -25,
			FrontFenderPitch = 14,
			RearFenderPitch = -8,
			HandleWidth = 2.58,
			TailRise = 12,
		},
		Colors = {
			Primary = Color3.fromRGB(73, 184, 104),
			Accent = Color3.fromRGB(203, 255, 215),
			Frame = Color3.fromRGB(35, 43, 38),
			Battery = Color3.fromRGB(22, 27, 24),
			Seat = Color3.fromRGB(24, 24, 24),
			Fork = Color3.fromRGB(191, 203, 192),
			Trim = Color3.fromRGB(156, 166, 157),
			Rim = Color3.fromRGB(57, 65, 60),
		},
	}),
	druid_250 = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 5.72,
			FrontWheelRadius = 1.22,
			RearWheelRadius = 1.28,
			SeatHeight = 2.3,
			HeadTubeY = 2.23,
			HeadTubeTilt = -21,
			TailRise = 11,
			HandleWidth = 2.74,
		},
		Colors = {
			Primary = Color3.fromRGB(59, 138, 230),
			Accent = Color3.fromRGB(200, 229, 255),
			Frame = Color3.fromRGB(33, 40, 54),
			Battery = Color3.fromRGB(22, 26, 34),
			Seat = Color3.fromRGB(24, 24, 26),
			Fork = Color3.fromRGB(204, 212, 224),
			Trim = Color3.fromRGB(150, 165, 184),
			Rim = Color3.fromRGB(54, 62, 76),
		},
	}),
	canal_runner = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 5.82,
			FrontWheelRadius = 1.12,
			RearWheelRadius = 1.15,
			FrontAxleY = 0.56,
			RearAxleY = 0.57,
			SeatHeight = 2.16,
			SeatLength = 2.22,
			HeadTubeTilt = -18,
			FrontFenderY = 1.74,
			FrontFenderPitch = 4,
			RearFenderY = 2.08,
			TailRise = 5,
			HandleWidth = 2.7,
		},
		Colors = {
			Primary = Color3.fromRGB(137, 112, 232),
			Accent = Color3.fromRGB(228, 214, 255),
			Frame = Color3.fromRGB(41, 38, 54),
			Battery = Color3.fromRGB(25, 24, 33),
			Seat = Color3.fromRGB(30, 30, 34),
			Fork = Color3.fromRGB(205, 197, 232),
			Trim = Color3.fromRGB(170, 164, 197),
			Rim = Color3.fromRGB(61, 58, 77),
		},
	}),
	iron_450 = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 5.95,
			FrontWheelRadius = 1.24,
			RearWheelRadius = 1.3,
			SeatHeight = 2.34,
			SeatLength = 2.16,
			HeadTubeY = 2.25,
			HeadTubeTilt = -20,
			FrontFenderPitch = 8,
			RearFenderPitch = -4,
			TailRise = 13,
			HandleWidth = 2.76,
		},
		Colors = {
			Primary = Color3.fromRGB(255, 214, 74),
			Accent = Color3.fromRGB(255, 244, 193),
			Frame = Color3.fromRGB(44, 44, 45),
			Battery = Color3.fromRGB(28, 28, 28),
			Seat = Color3.fromRGB(22, 22, 22),
			Fork = Color3.fromRGB(218, 204, 136),
			Trim = Color3.fromRGB(162, 156, 133),
			Rim = Color3.fromRGB(73, 70, 61),
		},
	}),
	shoreline_rr = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 6.04,
			FrontWheelRadius = 1.2,
			RearWheelRadius = 1.22,
			SeatHeight = 2.22,
			SeatLength = 2.28,
			HeadTubeTilt = -17,
			FrontFenderPitch = 2,
			RearFenderPitch = -2,
			TailRise = 7,
			HandleWidth = 2.68,
		},
		Colors = {
			Primary = Color3.fromRGB(248, 248, 248),
			Accent = Color3.fromRGB(137, 221, 255),
			Frame = Color3.fromRGB(53, 60, 70),
			Battery = Color3.fromRGB(33, 39, 46),
			Seat = Color3.fromRGB(26, 26, 26),
			Fork = Color3.fromRGB(208, 217, 224),
			Trim = Color3.fromRGB(157, 176, 189),
			Rim = Color3.fromRGB(77, 86, 95),
		},
	}),
	blue_line = deepMerge(baseProfile, {
		Geometry = {
			Wheelbase = 5.88,
			FrontWheelRadius = 1.16,
			RearWheelRadius = 1.2,
			SeatHeight = 2.18,
			SeatLength = 2.18,
			HeadTubeTilt = -19,
			FrontFenderPitch = 6,
			RearFenderPitch = -3,
			TailRise = 6,
			HandleWidth = 2.7,
		},
		Colors = {
			Primary = Color3.fromRGB(54, 163, 255),
			Accent = Color3.fromRGB(195, 231, 255),
			Frame = Color3.fromRGB(28, 38, 52),
			Battery = Color3.fromRGB(20, 25, 32),
			Seat = Color3.fromRGB(21, 24, 28),
			Fork = Color3.fromRGB(186, 206, 221),
			Trim = Color3.fromRGB(126, 153, 170),
			Rim = Color3.fromRGB(48, 59, 71),
		},
	}),
}

profiles.default = baseProfile

return profiles
