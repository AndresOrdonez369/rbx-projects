local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RegionConfig = require(ReplicatedStorage.Shared.RegionConfig)

local RegionSignController = {}

local SIGN_NAME = "RecommendedWarmthSign"
local SURFACE_GUI_NAME = "RecommendedWarmthSurfaceGui"
local COMPACT_SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

-- Cold world signage + Warmth guidance: dark navy backing, icy accent, Warmth orange value.
local BACKING_COLOR = Color3.fromRGB(12, 22, 32)
local BORDER_COLOR = Color3.fromRGB(174, 226, 255)
local NAME_COLOR = Color3.fromRGB(226, 238, 248)
local LABEL_COLOR = Color3.fromRGB(150, 196, 226)
local VALUE_COLOR = Color3.fromRGB(255, 160, 56)
local YOUR_MAX_COLOR_BELOW = Color3.fromRGB(150, 168, 186)
local YOUR_MAX_COLOR_REACHED = Color3.fromRGB(255, 214, 168)
local TEXT_STROKE_COLOR = Color3.fromRGB(5, 10, 16)

type SignEntry = {
    Recommended: number,
    YourMaxLabel: TextLabel,
}

local started = false
local signEntries: { SignEntry } = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")
assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local function trimZeros(text: string): string
    if text:find(".", 1, true) then
        text = text:gsub("0+$", ""):gsub("%.$", "")
    end
    return text
end

local function formatScientific(abs: number): string
    local mantissa, exponent = string.format("%.2e", abs):match("^(.-)e([%+%-]?%d+)$")
    if not mantissa then
        return tostring(abs)
    end
    return string.format("%se%d", trimZeros(mantissa), tonumber(exponent) :: number)
end

-- Display only: 100, 1K, 40K, 2.5M, 80M, 8.2B ... falling back to scientific notation.
local function formatCompact(value: number): string
    local abs = math.abs(value)
    local rounded = math.round(abs)
    if rounded < 1000 then
        return tostring(rounded)
    end

    local index = math.max(math.floor(math.log10(abs) / 3), 1)
    for _ = 1, 2 do
        if index > #COMPACT_SUFFIXES then
            return formatScientific(abs)
        end

        local scaled = abs / (1000 ^ index)
        local decimals = if scaled < 100 then 2 elseif scaled < 1000 then 1 else 0
        local text = trimZeros(string.format("%." .. decimals .. "f", scaled))
        if (tonumber(text) :: number) < 1000 then
            return text .. COMPACT_SUFFIXES[index]
        end
        index += 1
    end

    return formatScientific(abs)
end

local function createLabel(
    name: string,
    text: string,
    position: UDim2,
    size: UDim2,
    textColor: Color3,
    font: Enum.Font,
    maxTextSize: number
): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.Font = font
    label.Text = text
    label.TextColor3 = textColor
    label.TextScaled = true
    label.TextStrokeColor3 = TEXT_STROKE_COLOR
    label.TextStrokeTransparency = 0.35

    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = 8
    constraint.MaxTextSize = maxTextSize
    constraint.Parent = label
    return label
end

-- Comparison only: never a gate, never red, no pass/fail wording.
local function applyPlayerMax(entry: SignEntry, maxWarmth: number): ()
    entry.YourMaxLabel.Text = "YOUR MAX " .. formatCompact(maxWarmth)
    entry.YourMaxLabel.TextColor3 = if maxWarmth >= entry.Recommended
        then YOUR_MAX_COLOR_REACHED
        else YOUR_MAX_COLOR_BELOW
    entry.YourMaxLabel.Visible = true
end

local function attachSignPresentation(signPart: BasePart, displayName: string, recommendedWarmth: number): SignEntry
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
    surfaceGui.PixelsPerStud = 20
    surfaceGui.Parent = signPart

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = BACKING_COLOR
    background.BackgroundTransparency = 0.06
    background.BorderSizePixel = 0
    background.Parent = surfaceGui

    local border = Instance.new("UIStroke")
    border.Color = BORDER_COLOR
    border.Thickness = 3
    border.Transparency = 0.2
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = background

    -- Hierarchy: value (hero) > region name > RECOMMENDED WARMTH label > your max.
    createLabel(
        "RegionName", displayName,
        UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.19),
        NAME_COLOR, Enum.Font.GothamBold, 44
    ).Parent = background

    createLabel(
        "Guidance", "RECOMMENDED WARMTH",
        UDim2.fromScale(0.1, 0.26), UDim2.fromScale(0.8, 0.1),
        LABEL_COLOR, Enum.Font.GothamBold, 24
    ).Parent = background

    createLabel(
        "RecommendedWarmth", formatCompact(recommendedWarmth),
        UDim2.fromScale(0.1, 0.37), UDim2.fromScale(0.8, 0.4),
        VALUE_COLOR, Enum.Font.GothamBlack, 100
    ).Parent = background

    local yourMax = createLabel(
        "YourMax", "",
        UDim2.fromScale(0.15, 0.81), UDim2.fromScale(0.7, 0.11),
        YOUR_MAX_COLOR_BELOW, Enum.Font.GothamBold, 20
    )
    yourMax.Visible = false -- appears once the replicated MaxWarmth is known
    yourMax.Parent = background

    return {
        Recommended = recommendedWarmth,
        YourMaxLabel = yourMax,
    }
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

        table.insert(signEntries, attachSignPresentation(signPart, regionData.DisplayName, regionData.RecommendedWarmth))
    end

    -- Presentation only: reads the replicated MaxWarmth; never gates or changes anything.
    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName ~= "WarmthUpdated" or type(data) ~= "table" then
            return
        end

        local maxWarmth = data.MaxWarmth
        if type(maxWarmth) ~= "number" or maxWarmth ~= maxWarmth or maxWarmth < 0 or maxWarmth >= math.huge then
            return
        end

        for _, entry in signEntries do
            applyPlayerMax(entry, maxWarmth)
        end
    end)
end

return RegionSignController
