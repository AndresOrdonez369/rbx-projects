local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureRosterConfig = require(shared:WaitForChild("CreatureRosterConfig"))
local CreatureStatPresentation = require(shared:WaitForChild("CreatureStatPresentation"))
local RarityConfig = require(shared:WaitForChild("RarityConfig"))

local CreatureRevealService = {}

local ARTIST_CREATURES_FOLDER_NAME = "Creatures"
local RUNTIME_TEMPLATES_FOLDER_NAME = "RuntimeCreatureVisualTemplates"
local REPLICATED_CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local PRESENTATION_ROOT_NAME = "CreaturePresentationRoot"
local TEMPORARY_REVEAL_PRESENTATION_ATTRIBUTE = "IsTemporaryRevealPresentation"
local TEMPORARY_REVEAL_PRESENTATION_LIFETIME_SECONDS = 2
local VALID_SILHOUETTE_PROFILES = {
    Compact = true,
    AgileQuadruped = true,
    HeavyBeast = true,
    GiantAncient = true,
    MythicUnknown = true,
}

local creatureModels: Folder? = nil
local hasStarted = false

local function isFiniteNumber(value: any): boolean
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

local function normalizeArtistModelName(name: string): string
    return string.lower(name)
end

local function buildArtistModelLookup(artistContainer: Folder): ({ [string]: Model }, { [string]: boolean })
    local modelsByNormalizedName: { [string]: { Model } } = {}

    for _, child in artistContainer:GetChildren() do
        if child:IsA("Model") then
            local normalizedName = normalizeArtistModelName(child.Name)
            local matchingModels = modelsByNormalizedName[normalizedName]
            if not matchingModels then
                matchingModels = {}
                modelsByNormalizedName[normalizedName] = matchingModels
            end

            table.insert(matchingModels, child)
        end
    end

    local lookup: { [string]: Model } = {}
    local ambiguousNames: { [string]: boolean } = {}

    for normalizedName, matchingModels in modelsByNormalizedName do
        if #matchingModels == 1 then
            lookup[normalizedName] = matchingModels[1]
            continue
        end

        ambiguousNames[normalizedName] = true
        local sourceNames = {}
        for _, model in matchingModels do
            table.insert(sourceNames, model.Name)
        end
        table.sort(sourceNames)

        warn(string.format(
            "[CreatureRevealService] Ambiguous direct-child artist Models normalize to %q: %s; matching creature presentation is unavailable",
            normalizedName,
            table.concat(sourceNames, ", ")
        ))
    end

    return lookup, ambiguousNames
end

local function makePresentationSafe(model: Model): ()
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("LuaSourceContainer") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
            descendant.Massless = true
        end
    end
end

local function normalizeArtistModel(source: Model, creatureID: string): Model?
    local sourcePartCount = 0
    local sourceHasScripts = false

    for _, descendant in source:GetDescendants() do
        if descendant:IsA("BasePart") then
            sourcePartCount += 1
        elseif descendant:IsA("LuaSourceContainer") then
            sourceHasScripts = true
        end
    end

    if sourcePartCount == 0 then
        warn(string.format(
            "[CreatureRevealService] Workspace.Creatures.%s has no BaseParts and cannot be presented",
            source.Name
        ))
        return nil
    end

    if sourceHasScripts then
        warn(string.format(
            "[CreatureRevealService] Workspace.Creatures.%s contains scripts; runtime presentation clones remove them",
            source.Name
        ))
    end

    local model = source:Clone()
    makePresentationSafe(model)

    local boundsCFrame, boundsSize = model:GetBoundingBox()
    local sourcePivot = model:GetPivot()
    local desiredPivot = CFrame.new(
        boundsCFrame.Position.X,
        boundsCFrame.Position.Y - boundsSize.Y * 0.5,
        boundsCFrame.Position.Z
    ) * sourcePivot.Rotation

    local root = model.PrimaryPart
    if root then
        root.PivotOffset = root.CFrame:ToObjectSpace(desiredPivot)
    else
        root = Instance.new("Part")
        root.Name = PRESENTATION_ROOT_NAME
        root.Size = Vector3.new(0.2, 0.2, 0.2)
        root.CFrame = desiredPivot
        root.Transparency = 1
        root.Anchored = true
        root.CanCollide = false
        root.CanQuery = false
        root.CanTouch = false
        root.Parent = model
        model.PrimaryPart = root
    end

    model.Name = creatureID
    model:SetAttribute("CreatureID", creatureID)
    model:SetAttribute("PresentationRootName", root.Name)

    return model
end

local function getOrCreateCleanFolder(parent: Instance, folderName: string): Folder
    local existing = parent:FindFirstChild(folderName)
    if existing then
        if existing:IsA("Folder") then
            existing:ClearAllChildren()
            return existing
        end

        warn(string.format("[CreatureRevealService] Replacing non-Folder %s.%s", parent:GetFullName(), folderName))
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = parent
    return folder
end

local function validateRosterConfiguration(): ()
    local configuredCreatureIDs = {}

    for order, rarity in CreatureRosterConfig.RarityOrder do
        local rarityConfig = RarityConfig[rarity]
        assert(rarityConfig, string.format("RarityConfig must define %s", rarity))
        assert(rarityConfig.Order == order, string.format("RarityConfig.%s.Order must be %d", rarity, order))

        local creatureIDs = CreatureRosterConfig.CreatureIDsByRarity[rarity]
        assert(type(creatureIDs) == "table", string.format("Creature roster must define %s members", rarity))

        for _, creatureID in creatureIDs do
            assert(not configuredCreatureIDs[creatureID], string.format("Duplicate roster CreatureID %s", creatureID))
            configuredCreatureIDs[creatureID] = true

            local creature = CreatureConfig[creatureID]
            assert(creature, string.format("CreatureConfig must define roster creature %s", creatureID))
            assert(creature.CreatureID == creatureID, string.format("CreatureConfig.%s.CreatureID must match its key", creatureID))
            assert(
                type(creature.Rarity) == "string" and RarityConfig[creature.Rarity],
                string.format("CreatureConfig.%s.Rarity must name a configured rarity", creatureID)
            )
            assert(creature.Rarity == rarity, string.format("CreatureConfig.%s must be %s", creatureID, rarity))
            assert(creature.DisplayName == creatureID, string.format("CreatureConfig.%s.DisplayName must be %s", creatureID, creatureID))
            assert(creature.ModelName == creatureID, string.format("CreatureConfig.%s.ModelName must be %s", creatureID, creatureID))
            assert(
                type(creature.SilhouetteProfile) == "string" and VALID_SILHOUETTE_PROFILES[creature.SilhouetteProfile],
                string.format("CreatureConfig.%s.SilhouetteProfile must be supported", creatureID)
            )
            assert(
                isFiniteNumber(creature.ReferenceWeight) and creature.ReferenceWeight > 0,
                string.format("CreatureConfig.%s.ReferenceWeight must be finite and positive", creatureID)
            )
            assert(
                isFiniteNumber(creature.BaseVisualScale) and creature.BaseVisualScale > 0,
                string.format("CreatureConfig.%s.BaseVisualScale must be finite and positive", creatureID)
            )
            assert(
                isFiniteNumber(creature.BaseIncomePerSecond) and creature.BaseIncomePerSecond >= 0,
                string.format("CreatureConfig.%s.BaseIncomePerSecond must be finite and non-negative", creatureID)
            )
            assert(
                isFiniteNumber(creature.BaseWalkSpeed) and creature.BaseWalkSpeed > 0,
                string.format("CreatureConfig.%s.BaseWalkSpeed must be finite and positive", creatureID)
            )
        end
    end

    for creatureID in CreatureConfig do
        assert(configuredCreatureIDs[creatureID], string.format("CreatureConfig contains non-roster creature %s", creatureID))
    end
end

local function publishClientCreatureVisuals(container: Folder): ()
    local replicatedVisuals = getOrCreateCleanFolder(ReplicatedStorage, REPLICATED_CREATURE_VISUALS_FOLDER_NAME)

    for _, source in container:GetChildren() do
        local visual = source:Clone()
        makePresentationSafe(visual)
        visual.Parent = replicatedVisuals
    end
end

function CreatureRevealService.Present(
    creatureGUID: string,
    creatureID: string,
    stats: CreatureStatPresentation.DisplayStats,
    revealCFrame: CFrame,
    viewerPosition: Vector3,
    parent: Instance
): Model?
    local container = creatureModels
    assert(container, "CreatureRevealService must be started before presenting a creature")

    local creature = CreatureConfig[creatureID]
    if not creature then
        warn(string.format("[CreatureRevealService] No CreatureConfig entry for revealed CreatureID %s", creatureID))
        return nil
    end

    local source = container:FindFirstChild(creature.ModelName)
    if not source or not source:IsA("Model") then
        warn(string.format(
            "[CreatureRevealService] Creature %s was granted, but Workspace.Creatures.%s was unavailable at server start",
            creatureID,
            creature.ModelName
        ))
        return nil
    end

    local revealedModel = source:Clone()
    makePresentationSafe(revealedModel)
    local authoredTemplateScale = revealedModel:GetScale()
    revealedModel:ScaleTo(authoredTemplateScale * stats.Scale)
    revealedModel:SetAttribute("CreatureGUID", creatureGUID)
    revealedModel:SetAttribute("SizeScale", stats.Scale)

    local revealPosition = revealCFrame.Position
    local horizontalViewerPosition = Vector3.new(viewerPosition.X, revealPosition.Y, viewerPosition.Z)
    local horizontalOffset = horizontalViewerPosition - revealPosition
    local presentationCFrame = revealCFrame

    if horizontalOffset.Magnitude > 0.001 then
        presentationCFrame = CFrame.lookAt(revealPosition, horizontalViewerPosition)
    end

    revealedModel:PivotTo(presentationCFrame)
    revealedModel.Parent = parent
    CreatureStatPresentation.Attach(revealedModel, stats)

    return revealedModel
end

function CreatureRevealService.PresentTemporary(
    creatureGUID: string,
    creatureID: string,
    stats: CreatureStatPresentation.DisplayStats,
    revealCFrame: CFrame,
    viewerPosition: Vector3,
    parent: Instance
): Model?
    local revealedModel = CreatureRevealService.Present(
        creatureGUID,
        creatureID,
        stats,
        revealCFrame,
        viewerPosition,
        parent
    )
    if not revealedModel then
        return nil
    end

    revealedModel.Name = "TemporaryReveal_" .. creatureID
    revealedModel:SetAttribute(TEMPORARY_REVEAL_PRESENTATION_ATTRIBUTE, true)

    task.delay(TEMPORARY_REVEAL_PRESENTATION_LIFETIME_SECONDS, function()
        if revealedModel.Parent then
            revealedModel:Destroy()
        end
    end)

    return revealedModel
end

function CreatureRevealService.Start(): ()
    if hasStarted then
        return
    end
    hasStarted = true

    validateRosterConfiguration()

    local runtimeTemplates = getOrCreateCleanFolder(ServerStorage, RUNTIME_TEMPLATES_FOLDER_NAME)
    creatureModels = runtimeTemplates

    local artistContainer = Workspace:FindFirstChild(ARTIST_CREATURES_FOLDER_NAME)
    if not artistContainer or not artistContainer:IsA("Folder") then
        warn("[CreatureRevealService] Workspace.Creatures is missing or is not a Folder; creature ownership remains functional but visuals are unavailable")
        publishClientCreatureVisuals(runtimeTemplates)
        return
    end

    local artistModelsByNormalizedName, ambiguousArtistModelNames = buildArtistModelLookup(artistContainer)

    for _, rarity in CreatureRosterConfig.RarityOrder do
        for _, creatureID in CreatureRosterConfig.CreatureIDsByRarity[rarity] do
            local creature = CreatureConfig[creatureID]
            local normalizedModelName = normalizeArtistModelName(creature.ModelName)
            local source = artistModelsByNormalizedName[normalizedModelName]

            if not source then
                if ambiguousArtistModelNames[normalizedModelName] then
                    continue
                end

                warn(string.format(
                    "[CreatureRevealService] Expected artist Model Workspace.Creatures.%s for CreatureID %s",
                    creature.ModelName,
                    creatureID
                ))
                continue
            end

            local normalizedSuccessfully, normalizedOrError = pcall(normalizeArtistModel, source, creatureID)
            if not normalizedSuccessfully then
                warn(string.format(
                    "[CreatureRevealService] Failed to normalize Workspace.Creatures.%s: %s",
                    creature.ModelName,
                    tostring(normalizedOrError)
                ))
                continue
            end

            local normalized = normalizedOrError :: Model?
            if normalized then
                normalized.Parent = runtimeTemplates
            end
        end
    end

    publishClientCreatureVisuals(runtimeTemplates)
end

return CreatureRevealService
