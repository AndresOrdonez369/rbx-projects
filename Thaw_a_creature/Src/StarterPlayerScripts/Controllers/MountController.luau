local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))

-- Ride/Unride input plus the local rider's seated pose and mount-scaled camera.
-- The server owns MountState and Speed; this controller only requests changes and presents them.
local MountController = {}

local TOGGLE_RIDE_ACTION = "ToggleRide"
local TOGGLE_RIDE_KEY = Enum.KeyCode.R
local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local RIDER_ANCHOR_ATTRIBUTE = "RiderAnchorOffset"
local MOUNT_CREATURE_ID_ATTRIBUTE = "MountCreatureID"
local MOUNT_SCALE_ATTRIBUTE = "MountScale"
local MOUNT_STATE_ATTRIBUTE = "MountState"
local FOLLOWING_STATE = "Following"
local RIDING_STATE = "Riding"
local R15_SIT_ANIMATION_ID = "rbxassetid://2506281703"
local R6_SIT_ANIMATION_ID = "rbxassetid://178130996"
-- R6 legs add two studs below the root that R15 already counts in HipHeight.
local R6_LEG_HEIGHT = 2
-- Camera pulls back with the mount so giant copies stay readable; gameplay reach is unchanged.
local RIDING_CAMERA_DISTANCE_PER_ANCHOR_HEIGHT = 2.5
local RIDING_CAMERA_MAX_MIN_ZOOM = 60

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local creatureVisuals = ReplicatedStorage:WaitForChild(CREATURE_VISUALS_FOLDER_NAME)

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")

type RiderPose = {
    Humanoid: Humanoid,
    StandingHipHeight: number,
    SitTrack: AnimationTrack?,
}

local started = false
local isActionBound = false
local riderPose: RiderPose? = nil
local standingCameraMinZoom = localPlayer.CameraMinZoomDistance

local function getMountState(): string?
    local state = localPlayer:GetAttribute(MOUNT_STATE_ATTRIBUTE)
    return if type(state) == "string" then state else nil
end

local function getScaledRiderAnchor(): Vector3?
    local creatureID = localPlayer:GetAttribute(MOUNT_CREATURE_ID_ATTRIBUTE)
    local scale = localPlayer:GetAttribute(MOUNT_SCALE_ATTRIBUTE)
    local creature = type(creatureID) == "string" and CreatureConfig[creatureID]
    local template = creature and creatureVisuals:FindFirstChild(creature.ModelName)
    local anchor = template and template:GetAttribute(RIDER_ANCHOR_ATTRIBUTE)
    if typeof(anchor) ~= "Vector3" or type(scale) ~= "number" then
        return nil
    end

    return anchor * scale
end

local function clearRiderPose(): ()
    local pose = riderPose
    riderPose = nil
    localPlayer.CameraMinZoomDistance = standingCameraMinZoom

    if not pose then
        return
    end

    if pose.SitTrack then
        pose.SitTrack:Stop()
        pose.SitTrack:Destroy()
    end
    if pose.Humanoid.Parent then
        pose.Humanoid.HipHeight = pose.StandingHipHeight
    end
end

local function applyRiderPose(): ()
    clearRiderPose()

    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local riderAnchor = getScaledRiderAnchor()
    if getMountState() ~= RIDING_STATE or not humanoid or not riderAnchor then
        return
    end

    local isR6 = humanoid.RigType == Enum.HumanoidRigType.R6
    local pose: RiderPose = {
        Humanoid = humanoid,
        StandingHipHeight = humanoid.HipHeight,
        SitTrack = nil,
    }

    -- Raise the root so the rider sits on the mount's scaled anchor.
    humanoid.HipHeight = math.max(riderAnchor.Y - (if isR6 then R6_LEG_HEIGHT else 0), 0)

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local animation = Instance.new("Animation")
        animation.AnimationId = if isR6 then R6_SIT_ANIMATION_ID else R15_SIT_ANIMATION_ID
        local loaded, track = pcall(animator.LoadAnimation, animator, animation)
        if loaded and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play()
            pose.SitTrack = track
        end
    end

    localPlayer.CameraMinZoomDistance = math.clamp(
        riderAnchor.Y * RIDING_CAMERA_DISTANCE_PER_ANCHOR_HEIGHT,
        standingCameraMinZoom,
        RIDING_CAMERA_MAX_MIN_ZOOM
    )
    riderPose = pose
end

local function handleToggleRide(_actionName: string, inputState: Enum.UserInputState): Enum.ContextActionResult
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    local state = getMountState()
    if state == FOLLOWING_STATE then
        gameplayRequest:FireServer("RideEquippedCreature")
    elseif state == RIDING_STATE then
        gameplayRequest:FireServer("UnrideEquippedCreature")
    end

    return Enum.ContextActionResult.Sink
end

local function refreshMountPresentation(): ()
    local state = getMountState()
    local canToggle = state == FOLLOWING_STATE or state == RIDING_STATE

    if canToggle and not isActionBound then
        ContextActionService:BindAction(TOGGLE_RIDE_ACTION, handleToggleRide, true, TOGGLE_RIDE_KEY)
        isActionBound = true
    elseif not canToggle and isActionBound then
        ContextActionService:UnbindAction(TOGGLE_RIDE_ACTION)
        isActionBound = false
    end

    if isActionBound then
        ContextActionService:SetTitle(TOGGLE_RIDE_ACTION, if state == RIDING_STATE then "Unride" else "Ride")
    end

    applyRiderPose()
end

function MountController.Start(): ()
    if started then
        return
    end
    started = true

    for _, attributeName in { MOUNT_STATE_ATTRIBUTE, MOUNT_CREATURE_ID_ATTRIBUTE, MOUNT_SCALE_ATTRIBUTE } do
        localPlayer:GetAttributeChangedSignal(attributeName):Connect(refreshMountPresentation)
    end

    localPlayer.CharacterAdded:Connect(function()
        riderPose = nil
        refreshMountPresentation()
    end)

    refreshMountPresentation()
end

return MountController
