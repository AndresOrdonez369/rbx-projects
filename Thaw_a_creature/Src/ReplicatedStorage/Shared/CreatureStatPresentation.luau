local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type DisplayStats = {
    Scale: number,
    FinalIncome: number,
    FinalWalkSpeed: number,
}

local CreatureStatPresentation = {}

local ATTACHMENT_NAME = "CreatureStatAttachment"
local BILLBOARD_NAME = "CreatureStatBillboard"
local HEIGHT_MARGIN_STUDS = 1.25
local TEMPLATE_FOLDER_NAME = "UITemplates" -- prefab: ReplicatedStorage.UITemplates.CreatureStatBillboard

local function getTemplate(): BillboardGui?
    local folder = ReplicatedStorage:FindFirstChild(TEMPLATE_FOLDER_NAME)
    local template = folder and folder:FindFirstChild(BILLBOARD_NAME)
    if template and template:IsA("BillboardGui") then
        return template
    end

    warn("[CreatureStatPresentation] Missing ReplicatedStorage.UITemplates." .. BILLBOARD_NAME)
    return nil
end

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

local function formatCompact(value: number): string
    if value < 1000 then
        return string.format("%d", value)
    end

    local index = math.min(math.floor(math.log10(value) / 3), #SUFFIXES)
    local scaled = value / 1000 ^ index
    local decimals = if scaled < 10 then 2 elseif scaled < 100 then 1 else 0
    return string.format("%." .. decimals .. "f%s", scaled, SUFFIXES[index])
end

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

    local template = getTemplate()
    if not template then
        attachment:Destroy()
        return nil
    end

    local billboard = template:Clone()
    billboard.Name = BILLBOARD_NAME
    billboard.Adornee = attachment

    local background = billboard:WaitForChild("Background")
    local speedLabel = background:WaitForChild("Speed"):WaitForChild("Label") :: TextLabel
    local incomeLabel = background:WaitForChild("Income"):WaitForChild("Label") :: TextLabel
    speedLabel.Text = string.format("%.1f", stats.FinalWalkSpeed)
    incomeLabel.Text = "$" .. formatCompact(stats.FinalIncome) .. "/s"

    -- Hidden machine-readable copy in the legacy format; Pen presentation reads exact income from it.
    local legacy = background:WaitForChild("Stats") :: TextLabel
    legacy.Text = string.format("SPEED %.1f\nPEN $%d/s", stats.FinalWalkSpeed, stats.FinalIncome)
    billboard.Parent = attachment

    return billboard
end

return CreatureStatPresentation
