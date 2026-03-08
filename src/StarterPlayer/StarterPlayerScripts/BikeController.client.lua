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
	Grounded = false,
	GroundNormal = Vector3.yAxis,
	WheelieArmedUntil = 0,
	WheelieTriggerUntil = 0,
	WheelieCooldownUntil = 0,
	WheelieActive = false,
	WheeliePitch = 0,
	WheelieTargetPitch = 0,
	LastWheelieTapAt = 0,
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

local function approach(current, target, delta)
	if current < target then
		return math.min(current + delta, target)
	end
	return math.max(current - delta, target)
end

local function resetWheelie(controllerState)
	controllerState.WheelieArmedUntil = 0
	controllerState.WheelieTriggerUntil = 0
	controllerState.WheelieCooldownUntil = 0
	controllerState.WheelieActive = false
	controllerState.WheeliePitch = 0
	controllerState.WheelieTargetPitch = 0
	controllerState.LastWheelieTapAt = 0
end

local function getGroundInfo(origin, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false

	local result = Workspace:Raycast(origin + Vector3.new(0, 2.5, 0), Vector3.new(0, -Config.Bike.GroundRayLength, 0), params)
	if not result then
		return false, nil, "Unknown"
	end

	return true, result, result.Instance:GetAttribute("SurfaceType") or "Unknown"
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

local function applyTraversalAssist(controllerState, groundResult, look, dt)
	local hull = controllerState.Hull
	if not hull or not groundResult then
		return
	end

	local rideAssist = Config.Bike.RideAssist
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { controllerState.BikeModel, player.Character }
	params.IgnoreWater = false

	local desiredCenterY = groundResult.Position.Y + rideAssist.TargetCenterHeight
	local heightError = desiredCenterY - hull.Position.Y
	if heightError > rideAssist.HeightSnapThreshold and hull.AssemblyLinearVelocity.Y <= 8 then
		local lift = hull.AssemblyMass * rideAssist.SuspensionForce * heightError * dt
		hull:ApplyImpulse(Vector3.new(0, lift, 0))
	end

	if controllerState.Speed <= 0.5 then
		return
	end

	local frontOrigin = hull.Position + (look * rideAssist.FrontProbeDistance)
	local frontResult = Workspace:Raycast(frontOrigin + Vector3.new(0, 2.5, 0), Vector3.new(0, -Config.Bike.GroundRayLength, 0), params)
	if not frontResult then
		return
	end

	local stepHeight = frontResult.Position.Y - groundResult.Position.Y
	if stepHeight > 0.12 and stepHeight <= rideAssist.StepHeight then
		local factor = math.clamp(stepHeight / rideAssist.StepHeight, 0.2, 1)
		local lift = hull.AssemblyMass * rideAssist.StepLiftImpulse * factor
		hull:ApplyImpulse(Vector3.new(0, lift, 0))
	end
end

local function boostWheelie(controllerState, amount)
	local wheelieConfig = Config.Bike.Wheelie
	controllerState.WheelieActive = true
	controllerState.WheelieTargetPitch = math.clamp(
		math.max(controllerState.WheelieTargetPitch, wheelieConfig.SustainAngle) + amount,
		wheelieConfig.SustainAngle,
		wheelieConfig.MaxAngle
	)
	controllerState.LastWheelieTapAt = currentTime()
end

local function tryStartWheelie(controllerState, grounded, throttle, look, topSpeed)
	local nowStamp = currentTime()
	local wheelieConfig = Config.Bike.Wheelie
	if controllerState.WheelieTriggerUntil <= 0 or nowStamp > controllerState.WheelieTriggerUntil then
		return
	end
	if nowStamp < controllerState.WheelieCooldownUntil then
		return
	end

	local speedMph = math.max(0, controllerState.Speed) / Config.Bike.MphToStuds
	if not grounded or throttle <= 0 or speedMph < wheelieConfig.MinSpeedMph or not controllerState.Hull then
		return
	end

	controllerState.WheelieTriggerUntil = 0
	controllerState.WheelieArmedUntil = 0
	controllerState.WheelieCooldownUntil = nowStamp + wheelieConfig.Cooldown
	controllerState.WheelieActive = true
	controllerState.WheelieTargetPitch = wheelieConfig.PopAngle
	controllerState.LastWheelieTapAt = nowStamp
	controllerState.Speed = math.min(topSpeed, controllerState.Speed + (wheelieConfig.PopSpeedBoostMph * Config.Bike.MphToStuds))

	local impulsePosition = controllerState.Hull.Position - (look * (controllerState.Hull.Size.Z * 0.28))
	controllerState.Hull:ApplyImpulseAtPosition(
		Vector3.new(0, controllerState.Hull.AssemblyMass * wheelieConfig.PopImpulse, 0),
		impulsePosition
	)
end

local function updateWheelie(controllerState, grounded, throttle, look, topSpeed, dt)
	local wheelieConfig = Config.Bike.Wheelie
	tryStartWheelie(controllerState, grounded, throttle, look, topSpeed)

	local speedMph = math.max(0, controllerState.Speed) / Config.Bike.MphToStuds
	if controllerState.WheelieActive then
		if speedMph < wheelieConfig.SustainSpeedMph or throttle < 0 then
			controllerState.WheelieTargetPitch = math.max(0, controllerState.WheelieTargetPitch - (wheelieConfig.ExitRate * dt))
		else
			local minTarget = throttle > 0 and wheelieConfig.SustainAngle or 0
			if currentTime() - controllerState.LastWheelieTapAt > wheelieConfig.TapGrace then
				controllerState.WheelieTargetPitch = math.max(minTarget, controllerState.WheelieTargetPitch - (wheelieConfig.DecayRate * dt))
			else
				controllerState.WheelieTargetPitch = math.max(controllerState.WheelieTargetPitch, minTarget)
			end
		end

		if controllerState.WheelieTargetPitch <= 0.05 and controllerState.WheeliePitch <= 0.05 then
			controllerState.WheelieActive = false
			controllerState.WheelieTargetPitch = 0
		end
	else
		controllerState.WheelieTargetPitch = 0
	end

	local rate = controllerState.WheelieTargetPitch > controllerState.WheeliePitch and wheelieConfig.RiseRate or wheelieConfig.FallRate
	controllerState.WheeliePitch = approach(controllerState.WheeliePitch, controllerState.WheelieTargetPitch, rate * dt)
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
	controllerState.Grounded = false
	controllerState.GroundNormal = Vector3.yAxis
	resetWheelie(controllerState)

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
	local steer = controllerState.Seat.SteerFloat * (Config.Bike.ArcadeController.SteeringInputSign or -1)
	local nowStamp = currentTime()
	local grounded, groundResult, surfaceType = getGroundInfo(hull.Position, { controllerState.BikeModel, character })
	controllerState.Grounded = grounded
	controllerState.GroundNormal = groundResult and groundResult.Normal or Vector3.yAxis

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
	updateWheelie(controllerState, grounded, throttle, look, topSpeed, dt)

	local currentVelocity = hull.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
	local sideVelocity = horizontalVelocity - (look * horizontalVelocity:Dot(look))
	local targetHorizontal = (look * controllerState.Speed) - (sideVelocity * Config.Bike.ArcadeController.SideSlipDamp)
	hull.AssemblyLinearVelocity = Vector3.new(targetHorizontal.X, currentVelocity.Y, targetHorizontal.Z)

	if grounded and groundResult then
		applyTraversalAssist(controllerState, groundResult, look, dt)
	end

	if controllerState.Align then
		controllerState.Align.CFrame = CFrame.new(hull.Position)
			* CFrame.Angles(0, controllerState.Yaw, 0)
			* CFrame.Angles(math.rad(-controllerState.WheeliePitch), 0, 0)
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
		if controllerState.WheelieActive and controllerState.WheeliePitch > 1.5 then
			gear = "Wheelie"
		else
			gear = surfaceType == "OffRoad" and "Trail" or "Drive"
		end
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
	elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		controller.WheelieArmedUntil = currentTime() + Config.Bike.Wheelie.ArmWindow
	elseif input.KeyCode == Enum.KeyCode.W then
		local nowStamp = currentTime()
		if controller.BikeModel and controller.BikeDef then
			if controller.WheelieActive then
				boostWheelie(controller, Config.Bike.Wheelie.BalanceTapAngle)
				controller.Speed = math.min(controller.BikeDef.TopSpeedStuds, controller.Speed + (Config.Bike.Wheelie.TapBoostMph * Config.Bike.MphToStuds))
			elseif nowStamp <= controller.WheelieArmedUntil then
				controller.WheelieTriggerUntil = nowStamp + Config.Bike.Wheelie.TriggerWindow
				controller.LastWheelieTapAt = nowStamp
			end
		end
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
		resetWheelie(controller)
		if currentTime() >= controller.ComboExpiresAt then
			player:SetAttribute("StreetLegalComboText", "")
			player:SetAttribute("StreetLegalComboScore", 0)
		end
		clearHudState()
	end
end)
