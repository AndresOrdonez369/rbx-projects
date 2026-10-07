local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashController = require(script.Parent.Controllers.CashController)
local CreatureVisualController = require(script.Parent.Controllers.CreatureVisualController)
local CreatureVitalityController = require(script.Parent.Controllers.CreatureVitalityController)
local FrostSpritePresentationController = require(script.Parent.Controllers.FrostSpritePresentationController)
local HearthController = require(script.Parent.Controllers.HearthController)
local CreatureInventoryController = require(script.Parent.Controllers.CreatureInventoryController)
local IceController = require(script.Parent.Controllers.IceController)
local OwnBaseController = require(script.Parent.Controllers.OwnBaseController)
local RevealController = require(script.Parent.Controllers.RevealController)
local RegionSignController = require(script.Parent.Controllers.RegionSignController)
local SurvivalToolController = require(script.Parent.Controllers.SurvivalToolController)
local ThawTimerController = require(script.Parent.Controllers.ThawTimerController)
local WarmthController = require(script.Parent.Controllers.WarmthController)
local WorldCycleController = require(script.Parent.Controllers.WorldCycleController)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

gameplayEvent.OnClientEvent:Connect(function(eventName)
    if eventName ~= "RemoteTestAcknowledged" then
        return
    end

    print("[SharedRemotes] Client received RemoteTestAcknowledged via GameplayEvent")
end)

OwnBaseController.Start()
IceController.Start()
RevealController.Start()
ThawTimerController.Start()
CashController.Start()
HearthController.Start()
RegionSignController.Start()
WarmthController.Start()
CreatureVisualController.Start()
CreatureVitalityController.Start()
CreatureInventoryController.Start()
WorldCycleController.Start()
SurvivalToolController.Start()
FrostSpritePresentationController.Start()

print("[SharedRemotes] Client sent ClientReady via GameplayRequest")
gameplayRequest:FireServer("ClientReady")
