local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RegionConfig = require(ReplicatedStorage.Shared.RegionConfig)

local RegionSignController = {}

local SIGN_NAME = "RecommendedWarmthSign"
local SURFACE_GUI_NAME = "RecommendedWarmthSurfaceGui" -- template: ReplicatedStorage.UITemplates.RecommendedWarmthSurfaceGui
local COMPACT_SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

-- Comparison colours for the player's own Max Warmth (the rest of the sign styling lives in the prefab).
local YOUR_MAX_COLOR_BELOW = Color3.fromRGB(150, 168, 186)
local YOUR_MAX_COLOR_REACHED = Color3.fromRGB(255, 214, 168)

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

    local surfaceGui = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild(SURFACE_GUI_NAME):Clone()
    surfaceGui.Name = SURFACE_GUI_NAME
    surfaceGui.Adornee = signPart

    local background = surfaceGui:WaitForChild("Background")
    local regionName = background:WaitForChild("RegionName") :: TextLabel
    local recommended = background:WaitForChild("RecommendedWarmth") :: TextLabel
    regionName.Text = displayName
    recommended.Text = formatCompact(recommendedWarmth)
    local yourMax = background:WaitForChild("YourMax") :: TextLabel
    yourMax.Visible = false -- appears once the replicated MaxWarmth is known
    surfaceGui.Parent = signPart

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
