export type DisplayStats = {
    Scale: number,
    FinalIncome: number,
    FinalWalkSpeed: number,
}

local CreatureStatPresentation = {}

local ATTACHMENT_NAME = "CreatureStatAttachment"
local BILLBOARD_NAME = "CreatureStatBillboard"
local BILLBOARD_WIDTH = 176
local BILLBOARD_HEIGHT = 52
local HEIGHT_MARGIN_STUDS = 1.25

local function isFinitePositiveNumber(value: any): boolean
    return type(value) == "number"
        and value == value
        and value > 0
        and value < math.huge
end

function CreatureStatPresentation.IsValidDisplayStats(stats: any): boolean
    return type(stats) == "table"
        and isFinitePositiveNumber(stats.Scale)
        and isFinitePositiveNumber(stats.FinalIncome)
        and stats.FinalIncome % 1 == 0
        and isFinitePositiveNumber(stats.FinalWalkSpeed)
end

local function removeExistingPresentation(model: Model): ()
    for _, descendant in model:GetDescendants() do
        if descendant.Name == ATTACHMENT_NAME or descendant.Name == BILLBOARD_NAME then
            descendant:Destroy()
        end
    end
end

function CreatureStatPresentation.Attach(model: Model, stats: DisplayStats): BillboardGui?
    if not CreatureStatPresentation.IsValidDisplayStats(stats) then
        return nil
    end

    removeExistingPresentation(model)

    local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not root then
        return nil
    end

    local boundsCFrame, boundsSize = model:GetBoundingBox()
    local labelWorldPosition = boundsCFrame:PointToWorldSpace(
        Vector3.new(0, boundsSize.Y * 0.5 + HEIGHT_MARGIN_STUDS, 0)
    )

    local attachment = Instance.new("Attachment")
    attachment.Name = ATTACHMENT_NAME
    attachment.Position = root.CFrame:PointToObjectSpace(labelWorldPosition)
    attachment.Parent = root

    local billboard = Instance.new("BillboardGui")
    billboard.Name = BILLBOARD_NAME
    billboard.Adornee = attachment
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 180
    billboard.Size = UDim2.fromOffset(BILLBOARD_WIDTH, BILLBOARD_HEIGHT)
    billboard.Parent = attachment

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(18, 27, 36)
    background.BackgroundTransparency = 0.18
    background.BorderSizePixel = 0
    background.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = background

    local text = Instance.new("TextLabel")
    text.Name = "Stats"
    text.Position = UDim2.fromOffset(6, 3)
    text.Size = UDim2.new(1, -12, 1, -6)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.Text = string.format(
        "SPEED %.1f\nPEN $%d/s",
        stats.FinalWalkSpeed,
        stats.FinalIncome
    )
    text.TextColor3 = Color3.fromRGB(245, 248, 255)
    text.TextSize = 17
    text.TextStrokeColor3 = Color3.fromRGB(8, 12, 17)
    text.TextStrokeTransparency = 0.55
    text.Parent = background

    return billboard
end

return CreatureStatPresentation
