local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RegionConfig = require(ReplicatedStorage.Shared.RegionConfig)

local RegionSignController = {}

local SIGN_NAME = "RecommendedWarmthSign"
local SURFACE_GUI_NAME = "RecommendedWarmthSurfaceGui"

local started = false

local function formatInteger(value: number): string
    local digits = tostring(value)
    local parts = {}

    while #digits > 3 do
        table.insert(parts, 1, string.sub(digits, -3))
        digits = string.sub(digits, 1, -4)
    end

    table.insert(parts, 1, digits)
    return table.concat(parts, ",")
end

local function createLabel(
    name: string,
    text: string,
    position: UDim2,
    size: UDim2,
    textColor: Color3
): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = textColor
    label.TextScaled = true
    label.TextStrokeColor3 = Color3.fromRGB(5, 10, 16)
    label.TextStrokeTransparency = 0.35
    return label
end

local function attachSignPresentation(signPart: BasePart, displayName: string, recommendedWarmth: number): ()
    local existingGui = signPart:FindFirstChild(SURFACE_GUI_NAME)
    if existingGui then
        existingGui:Destroy()
    end

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = SURFACE_GUI_NAME
    surfaceGui.Adornee = signPart
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.AlwaysOnTop = false
    surfaceGui.LightInfluence = 0
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 40
    surfaceGui.Parent = signPart

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(12, 22, 32)
    background.BackgroundTransparency = 0.08
    background.BorderSizePixel = 0
    background.Parent = surfaceGui

    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(174, 226, 255)
    border.Thickness = 5
    border.Transparency = 0.15
    border.Parent = background

    local regionName = createLabel(
        "RegionName",
        displayName,
        UDim2.fromScale(0.04, 0.07),
        UDim2.fromScale(0.92, 0.34),
        Color3.fromRGB(245, 250, 255)
    )
    regionName.Parent = background

    local guidance = createLabel(
        "Guidance",
        "RECOMMENDED WARMTH",
        UDim2.fromScale(0.08, 0.43),
        UDim2.fromScale(0.84, 0.19),
        Color3.fromRGB(174, 226, 255)
    )
    guidance.Parent = background

    local value = createLabel(
        "RecommendedWarmth",
        formatInteger(recommendedWarmth),
        UDim2.fromScale(0.08, 0.64),
        UDim2.fromScale(0.84, 0.28),
        Color3.fromRGB(255, 220, 112)
    )
    value.Parent = background
end

function RegionSignController.Start(): ()
    if started then
        return
    end
    started = true

    local progressionRegions = Workspace:WaitForChild("ProgressionRegions")

    for regionId, regionData in pairs(RegionConfig) do
        local region = progressionRegions:WaitForChild(regionId)
        local signPart = region:WaitForChild(SIGN_NAME)

        assert(region:IsA("Folder"), string.format("Workspace.ProgressionRegions.%s must be a Folder", regionId))
        assert(signPart:IsA("BasePart"), string.format("%s.%s must be a BasePart", regionId, SIGN_NAME))

        attachSignPresentation(signPart, regionData.DisplayName, regionData.RecommendedWarmth)
    end
end

return RegionSignController
