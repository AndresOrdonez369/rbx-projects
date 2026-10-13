local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local OwnBaseController = require(script.Parent.OwnBaseController)

local IceController = {}

local ACTIVE_ICE_FOLDER_NAME = "ActiveIce"
local DEPOSIT_PROMPT_NAME = "DepositPrompt"
local GRAB_PROMPT_NAME = "GrabPrompt"
local SILHOUETTE_PART_NAME = "SilhouettePart"
-- Wild Ice reads as a vague shape from afar and a suggestive one up close; Pen thaw stages are untouched.
local SILHOUETTE_CLEAR_DISTANCE = 45
local SILHOUETTE_VAGUE_DISTANCE = 140
local SILHOUETTE_VAGUE_TRANSPARENCY_MODIFIER = 0.8
local SILHOUETTE_UPDATE_INTERVAL = 0.2

local started = false
local connectedPrompts: { [ProximityPrompt]: boolean } = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")

local function connectGrabPrompt(descendant: Instance)
    if not descendant:IsA("ProximityPrompt") or descendant.Name ~= GRAB_PROMPT_NAME then
        return
    end

    if connectedPrompts[descendant] then
        return
    end
    connectedPrompts[descendant] = true

    descendant.Triggered:Connect(function()
        local visualIce = descendant.Parent
        if not visualIce or not visualIce:IsA("BasePart") then
            return
        end

        local iceInstanceID = visualIce:GetAttribute("IceInstanceID")
        if type(iceInstanceID) ~= "string" then
            return
        end

        gameplayRequest:FireServer("GrabIce", iceInstanceID)
    end)
end


local function connectDepositPrompt(descendant: Instance, pen: Model)
    if not descendant:IsA("ProximityPrompt") or descendant.Name ~= DEPOSIT_PROMPT_NAME then
        return
    end

    if not descendant:IsDescendantOf(pen) or connectedPrompts[descendant] then
        return
    end
    connectedPrompts[descendant] = true

    descendant.Triggered:Connect(function()
        gameplayRequest:FireServer("DepositCarriedIce", pen)
    end)
end

local function setSilhouetteTransparencyModifier(visualIce: Instance, modifier: number)
    for _, child in visualIce:GetChildren() do
        if child:IsA("BasePart") and child.Name == SILHOUETTE_PART_NAME then
            child.LocalTransparencyModifier = modifier
        end
    end
end

local function updateWildSilhouettes(activeIceFolder: Instance)
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local cameraPosition = camera.CFrame.Position
    for _, visualIce in activeIceFolder:GetChildren() do
        if visualIce:IsA("BasePart") then
            local distance = (visualIce.Position - cameraPosition).Magnitude
            local vagueness = math.clamp(
                (distance - SILHOUETTE_CLEAR_DISTANCE) / (SILHOUETTE_VAGUE_DISTANCE - SILHOUETTE_CLEAR_DISTANCE),
                0,
                1
            )
            setSilhouetteTransparencyModifier(visualIce, vagueness * SILHOUETTE_VAGUE_TRANSPARENCY_MODIFIER)
        end
    end
end

function IceController.Start()
    if started then
        return
    end
    started = true

    local activeIceFolder = Workspace:WaitForChild(ACTIVE_ICE_FOLDER_NAME)

    for _, descendant in activeIceFolder:GetDescendants() do
        connectGrabPrompt(descendant)
    end

    activeIceFolder.DescendantAdded:Connect(connectGrabPrompt)

    -- Carried or deposited Ice leaves the wild field and must not keep a distance fade.
    activeIceFolder.ChildRemoved:Connect(function(visualIce)
        setSilhouetteTransparencyModifier(visualIce, 0)
    end)

    local silhouetteElapsed = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        silhouetteElapsed += deltaTime
        if silhouetteElapsed < SILHOUETTE_UPDATE_INTERVAL then
            return
        end
        silhouetteElapsed = 0
        updateWildSilhouettes(activeIceFolder)
    end)

    task.spawn(function()
        local pen = OwnBaseController.WaitForOwnBase():WaitForChild("Pen")
        assert(pen:IsA("Model"), string.format("%s must be a Model", pen:GetFullName()))

        for _, descendant in pen:GetDescendants() do
            connectDepositPrompt(descendant, pen)
        end

        pen.DescendantAdded:Connect(function(descendant)
            connectDepositPrompt(descendant, pen)
        end)
    end)
end

return IceController
