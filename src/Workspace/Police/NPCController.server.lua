local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local PoliceService = require(ServerScriptService.Services.PoliceService)

while not ReplicatedStorage:GetAttribute("StreetLegalBootstrapReady") or not Workspace:GetAttribute("StreetLegalWorldReady") do
	task.wait(0.25)
end

PoliceService:Init(script.Parent)
