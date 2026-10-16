local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Presents a validated wilderness contest knockback on the local character (L-D14.5-T05). The server owns
-- eligibility, timing and every consequence; this only applies the physical shove it described, because the
-- client owns its character's physics.
local PlayerContestController = {}

local KNOCKBACK_EVENT = "ContestKnockback"
local TOPPLE_ANGULAR_SPEED = 4

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local started = false
local ragdollRevision = 0

local function isFiniteNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function applyKnockback(data: any): ()
    if type(data) ~= "table"
        or typeof(data.Direction) ~= "Vector3"
        or not isFiniteNumber(data.HorizontalSpeed)
        or not isFiniteNumber(data.VerticalSpeed)
        or not isFiniteNumber(data.Duration)
        or data.Duration <= 0
    then
        return
    end

    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return
    end

    ragdollRevision += 1
    local revision = ragdollRevision
    local direction = Vector3.new(data.Direction.X, 0, data.Direction.Z)
    direction = if direction.Magnitude > 0.001 then direction.Unit else Vector3.zero

    humanoid.PlatformStand = true
    rootPart.AssemblyLinearVelocity = direction * data.HorizontalSpeed + Vector3.new(0, data.VerticalSpeed, 0)
    rootPart.AssemblyAngularVelocity = direction:Cross(Vector3.yAxis) * -TOPPLE_ANGULAR_SPEED

    task.delay(data.Duration, function()
        if revision ~= ragdollRevision or not humanoid.Parent then
            return
        end

        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
end

function PlayerContestController.Start(): ()
    if started then
        return
    end
    started = true

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == KNOCKBACK_EVENT then
            applyKnockback(data)
        end
    end)
end

return PlayerContestController
