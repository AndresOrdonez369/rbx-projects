local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local SurvivalToolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SurvivalToolConfig"))

local ThawPlacementController = require(script.Parent.ThawPlacementController)

local IceController = {}

local ACTIVE_ICE_FOLDER_NAME = "ActiveIce"
local GRAB_PROMPT_NAME = "GrabPrompt"
local GRAB_HOLD_CANCELLED_EVENT = "GrabHoldCancelled"
-- Long enough for ProximityPromptService to drop the in-progress hold before the prompt is shown again.
local GRAB_PROMPT_RESET_SECONDS = 0.15
local MOUNT_STATE_ATTRIBUTE = "MountState"
local RIDING_MOUNT_STATE = "Riding"
-- Mirrors IceService's mounted Grab origin: ground beneath the rider + the on-foot height Mounted Strike uses.
local MOUNTED_GRAB_GROUND_RAY_DISTANCE = 300
local MOUNTED_GRAB_PROMPT_GATE_INTERVAL = 0.1
-- Intentional DropIce input (L-D14.5-T04), bound only while the local character carries Ice.
local DROP_ICE_ACTION = "DropCarriedIce"
local DROP_ICE_KEY = Enum.KeyCode.G
local ICE_INSTANCE_ID_ATTRIBUTE = "IceInstanceID"
local SILHOUETTE_PART_NAME = "SilhouettePart"
-- Wild Ice reads as a vague shape from afar and a suggestive one up close; Pen thaw stages are untouched.
local SILHOUETTE_CLEAR_DISTANCE = 45
local SILHOUETTE_VAGUE_DISTANCE = 140
local SILHOUETTE_VAGUE_TRANSPARENCY_MODIFIER = 0.8
local SILHOUETTE_UPDATE_INTERVAL = 0.2

local started = false
local connectedPrompts: { [ProximityPrompt]: boolean } = {}
local localPlayer = Players.LocalPlayer
local standingHipHeight: number? = nil
local isRidingForGrab = false
-- Local prompt activation distance only. On foot it is the canonical Grab distance. While Riding it is raised by the
-- rider's lift so Roblox can still reach the prompt from the saddle, but each prompt is only offered when the same
-- logical mounted origin the server uses is within the canonical distance (see gateMountedGrabPrompts). The server
-- always validates 14 studs itself, so no local value grants extra reach.
local grabPromptActivationDistance = GameConfig.GrabIceMaxDistance
local mountedGateElapsed = 0
local isDropActionBound = false

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")

-- Grab is a server-observed hold (L-D14.5-T03): the server watches this prompt's hold/trigger events and owns the
-- timing, so the client only presents the prompt and never requests the claim itself.
local function connectGrabPrompt(descendant: Instance)
    if not descendant:IsA("ProximityPrompt") or descendant.Name ~= GRAB_PROMPT_NAME then
        return
    end

    connectedPrompts[descendant] = true
    -- While Riding, a new prompt stays hidden until the next mounted range gate decides it.
    descendant.MaxActivationDistance = if isRidingForGrab then 0 else grabPromptActivationDistance
end

-- While Riding, the rider's root is lifted by the mount (MountController raises HipHeight), so the Grab prompt's
-- local activation distance grows by exactly that lift. On foot it stays at the canonical Grab distance.
local function refreshGrabPromptReach(): ()
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local isRiding = localPlayer:GetAttribute(MOUNT_STATE_ATTRIBUTE) == RIDING_MOUNT_STATE
    local riderLift = 0

    if humanoid then
        if not isRiding then
            standingHipHeight = humanoid.HipHeight
        elseif standingHipHeight then
            riderLift = math.max(0, humanoid.HipHeight - standingHipHeight)
        end
    end

    grabPromptActivationDistance = GameConfig.GrabIceMaxDistance + riderLift
    isRidingForGrab = isRiding
    mountedGateElapsed = MOUNTED_GRAB_PROMPT_GATE_INTERVAL

    -- On foot every Grab prompt uses the canonical distance directly; while Riding the gate sets each prompt.
    if isRiding then
        return
    end

    local activeIceFolder = Workspace:FindFirstChild(ACTIVE_ICE_FOLDER_NAME)
    if not activeIceFolder then
        return
    end

    for _, descendant in activeIceFolder:GetDescendants() do
        if descendant:IsA("ProximityPrompt") and descendant.Name == GRAB_PROMPT_NAME then
            descendant.MaxActivationDistance = grabPromptActivationDistance
        end
    end
end

-- Same origin as IceService while Riding: the ground beneath the rider, raised to on-foot attack height.
local function getMountedGrabOrigin(rootPart: BasePart): Vector3
    local excludedCharacters = {}
    for _, player in Players:GetPlayers() do
        if player.Character then
            table.insert(excludedCharacters, player.Character)
        end
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = excludedCharacters
    raycastParams.RespectCanCollide = true

    local groundResult = Workspace:Raycast(
        rootPart.Position,
        Vector3.new(0, -MOUNTED_GRAB_GROUND_RAY_DISTANCE, 0),
        raycastParams
    )
    if not groundResult then
        return rootPart.Position
    end

    return groundResult.Position + Vector3.new(0, SurvivalToolConfig.MountedCombatOriginHeight, 0)
end

-- While Riding, offer a Grab prompt only when the logical mounted origin is within the canonical Grab distance;
-- otherwise hide it (activation distance 0). Presentation only: the server re-checks the same rule.
local function gateMountedGrabPrompts(): ()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local activeIceFolder = Workspace:FindFirstChild(ACTIVE_ICE_FOLDER_NAME)
    if not rootPart or not rootPart:IsA("BasePart") or not activeIceFolder then
        return
    end

    local origin = getMountedGrabOrigin(rootPart)
    for _, descendant in activeIceFolder:GetDescendants() do
        if descendant:IsA("ProximityPrompt") and descendant.Name == GRAB_PROMPT_NAME then
            local interactionPart = descendant.Parent
            local isInReach = interactionPart ~= nil
                and interactionPart:IsA("BasePart")
                and (origin - interactionPart.Position).Magnitude <= GameConfig.GrabIceMaxDistance
            descendant.MaxActivationDistance = if isInReach then grabPromptActivationDistance else 0
        end
    end
end

local function watchCharacterForGrabReach(character: Model): ()
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end

    standingHipHeight = nil
    humanoid:GetPropertyChangedSignal("HipHeight"):Connect(refreshGrabPromptReach)
    refreshGrabPromptReach()
end

-- The server cancelled this player's hold (range, Safe Zone, death, premature...): restart the prompt's progress
-- locally so a fresh full hold is required. Presentation only.
local function resetGrabPromptProgress(iceInstanceID: any)
    if type(iceInstanceID) ~= "string" then
        return
    end

    local activeIceFolder = Workspace:FindFirstChild(ACTIVE_ICE_FOLDER_NAME)
    if not activeIceFolder then
        return
    end

    for _, descendant in activeIceFolder:GetDescendants() do
        if descendant:IsA("ProximityPrompt")
            and descendant.Name == GRAB_PROMPT_NAME
            and descendant.Parent
            and descendant.Parent:GetAttribute("IceInstanceID") == iceInstanceID
            and descendant.Enabled
        then
            descendant.Enabled = false
            task.delay(GRAB_PROMPT_RESET_SECONDS, function()
                if descendant.Parent then
                    descendant.Enabled = true
                end
            end)
        end
    end
end


-- The server welds the exact carried Ice (tagged with its IceInstanceID) to the carrier's character.
local function isCarryingIce(character: Model?): boolean
    if not character then
        return false
    end

    for _, child in character:GetChildren() do
        if child:IsA("BasePart") and child:GetAttribute(ICE_INSTANCE_ID_ATTRIBUTE) ~= nil then
            return true
        end
    end

    return false
end

local function handleDropIce(_actionName: string, inputState: Enum.UserInputState): Enum.ContextActionResult
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    gameplayRequest:FireServer("DropIce")
    return Enum.ContextActionResult.Sink
end

local function refreshDropAction(): ()
    local shouldBind = isCarryingIce(localPlayer.Character)
    if shouldBind == isDropActionBound then
        return
    end

    isDropActionBound = shouldBind
    if shouldBind then
        -- Keyboard only; the HUD Carried Ice panel (ActionBarController) provides the touch Drop button.
        ContextActionService:BindAction(DROP_ICE_ACTION, handleDropIce, false, DROP_ICE_KEY)
    else
        ContextActionService:UnbindAction(DROP_ICE_ACTION)
    end
end

local function watchCharacterForCarry(character: Model): ()
    character.ChildAdded:Connect(refreshDropAction)
    character.ChildRemoved:Connect(refreshDropAction)
    refreshDropAction()
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

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == GRAB_HOLD_CANCELLED_EVENT and type(data) == "table" then
            resetGrabPromptProgress(data.IceInstanceID)
        end
    end)

    localPlayer:GetAttributeChangedSignal(MOUNT_STATE_ATTRIBUTE):Connect(refreshGrabPromptReach)
    RunService.Heartbeat:Connect(function(deltaTime)
        if not isRidingForGrab then
            return
        end

        mountedGateElapsed += deltaTime
        if mountedGateElapsed < MOUNTED_GRAB_PROMPT_GATE_INTERVAL then
            return
        end
        mountedGateElapsed = 0
        gateMountedGrabPrompts()
    end)
    localPlayer.CharacterAdded:Connect(watchCharacterForGrabReach)
    localPlayer.CharacterAdded:Connect(watchCharacterForCarry)
    if localPlayer.Character then
        task.spawn(watchCharacterForGrabReach, localPlayer.Character)
        watchCharacterForCarry(localPlayer.Character)
    end

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

    -- Direct deposit (F-D15-T05C1.2): carrying Ice near the own Pen makes its floor a one-click / one-tap placement
    -- surface; there is no Deposit prompt any more.
    ThawPlacementController.Start()
end

return IceController
