local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Fills a prefab ViewportFrame with a creature's visual model (inventory cards, Archive tiles, HUD Mount Card).
local CreaturePortrait = {}

local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local DEFAULT_VIEWPORT_FOV = 40

local function getCreatureSource(creatureID: string): Model?
    local creatureVisuals = ReplicatedStorage:FindFirstChild(CREATURE_VISUALS_FOLDER_NAME)
    local source = creatureVisuals and creatureVisuals:FindFirstChild(creatureID)
    if source and source:IsA("Model") then
        return source
    end

    return nil
end

-- Frames the creature from a three-quarter angle; returns the focus point and distance for the detail spin.
function CreaturePortrait.Fill(viewport: ViewportFrame, creatureID: string): (Vector3?, number?)
    for _, existing in viewport:GetChildren() do
        if existing:IsA("Model") then
            existing:Destroy()
        end
    end

    local source = getCreatureSource(creatureID)
    if not source then
        return nil, nil
    end

    -- Cameras do not replicate inside GUI prefabs, so each viewport gets a local one (FOV from the prefab attribute).
    local camera = viewport:FindFirstChildOfClass("Camera")
    if not camera then
        camera = Instance.new("Camera")
        local fieldOfView = viewport:GetAttribute("FieldOfView")
        camera.FieldOfView = if type(fieldOfView) == "number" then fieldOfView else DEFAULT_VIEWPORT_FOV
        camera.Parent = viewport
    end

    local model = source:Clone()
    model.Parent = viewport

    -- A viewport does not repaint meshes that finish downloading after the clone; re-parent once they are loaded.
    task.spawn(function()
        ContentProvider:PreloadAsync({ model })
        if model.Parent == viewport then
            model.Parent = nil
            model.Parent = viewport
        end
    end)

    local boundsCFrame, boundsSize = model:GetBoundingBox()
    local pivot = model:GetPivot()
    local direction = (pivot.LookVector + pivot.RightVector * 0.6 + Vector3.new(0, 0.35, 0)).Unit
    local distance = boundsSize.Magnitude * 0.5 / math.tan(math.rad(camera.FieldOfView * 0.5)) * 1.05
    camera.CFrame = CFrame.lookAt(boundsCFrame.Position + direction * distance, boundsCFrame.Position)
    viewport.CurrentCamera = camera

    return boundsCFrame.Position, distance
end

return CreaturePortrait
