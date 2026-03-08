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
local SpawnService = require(ServerScriptService.Services.SpawnService)

-- StreamingEnabled is configured in default.project.json; runtime writes fail in Studio play mode.
ReplicatedStorage:SetAttribute("StreetLegalBootstrapReady", false)

DataService:Init(remotes)
WantedService:Init(DataService, remotes)
PurchaseService:Init(DataService, WantedService, remotes)
SpawnService:Init()

ReplicatedStorage:SetAttribute("StreetLegalBootstrapReady", true)
