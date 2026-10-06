local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FrostSpritePresentationController = {}

local ACTIVE_SPRITE_FOLDER_NAME = "ActiveFrostSprites"
local CORE_PART_NAME = "Core"
local PRESENTATION_NAME = "SurvivalReadability"
local HIT_HIGHLIGHT_NAME = "ConfirmedHit"
local TELEGRAPH_HIGHLIGHT_NAME = "AttackTelegraph"

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

type SpritePresentation = {
    Fill: Frame,
    Warning: TextLabel,
    TelegraphHighlight: Highlight,
    HitHighlight: Highlight,
}

local started = false
local connectedSprites: { [Model]: boolean } = setmetatable({}, { __mode = "k" })
local presentationBySprite: { [Model]: SpritePresentation } = setmetatable({}, { __mode = "k" })
local hitFlashRevisionBySprite: { [Model]: number } = setmetatable({}, { __mode = "k" })

local function createPresentation(sprite: Model, core: BasePart): SpritePresentation
    local billboard = Instance.new("BillboardGui")
    billboard.Name = PRESENTATION_NAME
    billboard.Adornee = core
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 70
    billboard.Size = UDim2.fromOffset(70, 40)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.1, 0)
    billboard.Parent = sprite

    local warning = Instance.new("TextLabel")
    warning.Name = "AttackWarning"
    warning.Position = UDim2.fromOffset(0, 0)
    warning.Size = UDim2.new(1, 0, 0, 22)
    warning.BackgroundTransparency = 1
    warning.Font = Enum.Font.GothamBlack
    warning.Text = "!"
    warning.TextColor3 = Color3.fromRGB(255, 105, 80)
    warning.TextSize = 25
    warning.TextStrokeColor3 = Color3.fromRGB(255, 240, 180)
    warning.TextStrokeTransparency = 0
    warning.Visible = false
    warning.Parent = billboard

    local barBackground = Instance.new("Frame")
    barBackground.Name = "HealthBackground"
    barBackground.Position = UDim2.fromOffset(5, 26)
    barBackground.Size = UDim2.new(1, -10, 0, 9)
    barBackground.BackgroundColor3 = Color3.fromRGB(18, 28, 38)
    barBackground.BorderSizePixel = 0
    barBackground.ClipsDescendants = true
    barBackground.Parent = billboard

    local fill = Instance.new("Frame")
    fill.Name = "HealthFill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.fromRGB(115, 215, 240)
    fill.BorderSizePixel = 0
    fill.Parent = barBackground

    local telegraphHighlight = Instance.new("Highlight")
    telegraphHighlight.Name = TELEGRAPH_HIGHLIGHT_NAME
    telegraphHighlight.Adornee = sprite
    telegraphHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    telegraphHighlight.FillColor = Color3.fromRGB(255, 120, 75)
    telegraphHighlight.FillTransparency = 0.45
    telegraphHighlight.OutlineColor = Color3.fromRGB(255, 235, 150)
    telegraphHighlight.OutlineTransparency = 0
    telegraphHighlight.Enabled = false
    telegraphHighlight.Parent = sprite

    local hitHighlight = Instance.new("Highlight")
    hitHighlight.Name = HIT_HIGHLIGHT_NAME
    hitHighlight.Adornee = sprite
    hitHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hitHighlight.FillColor = Color3.fromRGB(255, 255, 255)
    hitHighlight.FillTransparency = 0.08
    hitHighlight.OutlineColor = Color3.fromRGB(145, 235, 255)
    hitHighlight.OutlineTransparency = 0
    hitHighlight.Enabled = false
    hitHighlight.Parent = sprite

    return {
        Fill = fill,
        Warning = warning,
        TelegraphHighlight = telegraphHighlight,
        HitHighlight = hitHighlight,
    }
end

local function updateHealth(sprite: Model, presentation: SpritePresentation): ()
    local currentHealth = sprite:GetAttribute("CurrentHealth")
    local maxHealth = sprite:GetAttribute("MaxHealth")
    if type(currentHealth) ~= "number" or type(maxHealth) ~= "number" or maxHealth <= 0 then
        return
    end

    presentation.Fill.Size = UDim2.fromScale(math.clamp(currentHealth / maxHealth, 0, 1), 1)
end

local function updateTelegraph(sprite: Model, presentation: SpritePresentation): ()
    local isTelegraphing = sprite:GetAttribute("IsTelegraphing") == true
    presentation.Warning.Visible = isTelegraphing
    presentation.TelegraphHighlight.Enabled = isTelegraphing
end

local function flashConfirmedHit(sprite: Model, presentation: SpritePresentation): ()
    local revision = (hitFlashRevisionBySprite[sprite] or 0) + 1
    hitFlashRevisionBySprite[sprite] = revision
    presentation.HitHighlight.Enabled = true

    task.delay(0.12, function()
        if hitFlashRevisionBySprite[sprite] == revision and presentation.HitHighlight.Parent then
            presentation.HitHighlight.Enabled = false
        end
    end)
end

local function connectSprite(instance: Instance): ()
    if not instance:IsA("Model") or connectedSprites[instance] then
        return
    end

    local core = instance:FindFirstChild(CORE_PART_NAME)
    if not core or not core:IsA("BasePart") then
        return
    end

    connectedSprites[instance] = true
    local presentation = createPresentation(instance, core)
    presentationBySprite[instance] = presentation
    updateHealth(instance, presentation)
    updateTelegraph(instance, presentation)

    instance:GetAttributeChangedSignal("CurrentHealth"):Connect(function()
        updateHealth(instance, presentation)
    end)
    instance:GetAttributeChangedSignal("IsTelegraphing"):Connect(function()
        updateTelegraph(instance, presentation)
    end)
end

function FrostSpritePresentationController.Start(): ()
    if started then
        return
    end
    started = true

    local activeSprites = Workspace:WaitForChild(ACTIVE_SPRITE_FOLDER_NAME)
    assert(activeSprites:IsA("Folder"), string.format("Workspace.%s must be a Folder", ACTIVE_SPRITE_FOLDER_NAME))

    for _, child in activeSprites:GetChildren() do
        connectSprite(child)
    end
    activeSprites.ChildAdded:Connect(connectSprite)

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName ~= "SurvivalFeedback" or type(data) ~= "table" or data.Kind ~= "ToolHit" then
            return
        end

        local target = data.Target
        if typeof(target) ~= "Instance" or not target:IsA("Model") then
            return
        end

        local presentation = presentationBySprite[target]
        if presentation then
            flashConfirmedHit(target, presentation)
        end
    end)
end

return FrostSpritePresentationController
