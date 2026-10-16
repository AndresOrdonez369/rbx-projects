local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Prefab HUD clusters are authored at a 720p reference size; every UIScale named HudScale follows the viewport height.
local HudScaleController = {}

local SCALE_NAME = "HudScale"
-- Corner clusters authored with this UDim2 attribute move by it on touch devices, clear of the thumbstick / jump button.
local TOUCH_OFFSET_ATTRIBUTE = "TouchOffset"
local REFERENCE_HEIGHT = 720
local MIN_SCALE = 0.55
local MAX_SCALE = 1.6
-- The camera can report a 1x1 viewport while the client boots and its ViewportSize signal does not always follow
-- (seen in Studio Play); re-check periodically so the HUD never stays stuck at MIN_SCALE.
local RECHECK_INTERVAL = 0.5

local started = false
local scales: { [UIScale]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local currentScale = 1

local function computeScale(): number
    local camera = Workspace.CurrentCamera
    if not camera then
        return 1
    end

    return math.clamp(camera.ViewportSize.Y / REFERENCE_HEIGHT, MIN_SCALE, MAX_SCALE)
end

local function track(instance: Instance): ()
    if instance:IsA("UIScale") and instance.Name == SCALE_NAME then
        scales[instance] = true
        instance.Scale = currentScale
    elseif instance:IsA("GuiObject") and UserInputService.TouchEnabled then
        local touchOffset = instance:GetAttribute(TOUCH_OFFSET_ATTRIBUTE)
        if typeof(touchOffset) == "UDim2" then
            instance.Position += touchOffset
        end
    end
end

local function applyAll(): ()
    currentScale = computeScale()
    for scale in scales do
        if scale.Parent then
            scale.Scale = currentScale
        end
    end
end

function HudScaleController.GetScale(): number
    return currentScale
end

function HudScaleController.Start(): ()
    if started then
        return
    end
    started = true

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    currentScale = computeScale()
    for _, descendant in playerGui:GetDescendants() do
        track(descendant)
    end
    playerGui.DescendantAdded:Connect(track)

    local function bindCamera(): ()
        local camera = Workspace.CurrentCamera
        if camera then
            camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyAll)
        end
        applyAll()
    end
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
    bindCamera()

    local recheckElapsed = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        recheckElapsed += deltaTime
        if recheckElapsed < RECHECK_INTERVAL then
            return
        end
        recheckElapsed = 0
        if math.abs(computeScale() - currentScale) > 1e-3 then
            applyAll()
        end
    end)
end

return HudScaleController
