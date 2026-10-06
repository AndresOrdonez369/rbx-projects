local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local IceConfig = require(shared:WaitForChild("IceConfig"))
local RarityConfig = require(shared:WaitForChild("RarityConfig"))
local SizeConfig = require(shared:WaitForChild("SizeConfig"))
local ThawConfig = require(shared:WaitForChild("ThawConfig"))
local WorldCycleConfig = require(shared:WaitForChild("WorldCycleConfig"))
local StudioTestConfig = require(script.Parent.Parent:WaitForChild("StudioTestConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local CreatureRevealService = require(script.Parent.CreatureRevealService)
local CreatureService = require(script.Parent.CreatureService)
local IceVisualFactory = require(script.Parent.IceVisualFactory)
local PlayerStateService = require(script.Parent.PlayerStateService)

export type DepositedIce = {
    IceType: string,
    CreatureID: string,
    Rarity: string,
    WeightMultiplier: number,
}

local ThawService = {}

local INITIAL_BONUS_PROGRESS_SECONDS = 0
local THAW_VISUALS_FOLDER_NAME = "ThawVisuals"
local PLAYER_FOLDER_PREFIX = "Player_"
local READY_PROMPT_NAME = "ReadyPrompt"
local THAW_READY_AT_ATTRIBUTE = "ThawReadyAt"
local GRID_COLUMNS = 2
local GRID_VISUAL_PADDING = 1.5
local GRID_FIRST_ROW_PADDING = 0.5
local MAX_PROTOTYPE_VISUAL_WIDTH = math.max(
    IceVisualFactory.GetBaseSize("Regular").X,
    IceVisualFactory.GetBaseSize("Thick").X
)
local MAX_PROTOTYPE_VISUAL_DEPTH = math.max(
    IceVisualFactory.GetBaseSize("Regular").Z,
    IceVisualFactory.GetBaseSize("Thick").Z
)
local GRID_COLUMN_SPACING = MAX_PROTOTYPE_VISUAL_WIDTH + GRID_VISUAL_PADDING
local GRID_ROW_SPACING = MAX_PROTOTYPE_VISUAL_DEPTH + GRID_VISUAL_PADDING
local REQUIRED_REVEAL_HITS = 3
local PRESENTATION_SURFACE_EPSILON = 0.001
local JACKPOT_CREATURE_ID = "Nidhogg"
local JACKPOT_WEIGHT_MULTIPLIER = 125

local visualsByPlayer: { [Player]: { [string]: BasePart } } = {}
local lastBeginRevealRequestAtByPlayer: { [Player]: number } = {}
local issuedSessionIDs: { [string]: boolean } = {}
local thawVisualsFolder: Folder? = nil
local penFloor: BasePart? = nil
local presentationSurfaceY: number? = nil
local hasStarted = false
local presentationUpdateElapsed = 0
local DAY_PHASE = "Day"
local GREAT_FROST_PHASE = "GreatFrost"
local currentWorldCyclePhase = DAY_PHASE
local activeGreatFrostCycleIndex: number? = nil
local activeGreatFrostStartedAtTime: number? = nil
local activeGreatFrostEndsAtTime: number? = nil
local lastCompletedGreatFrostCycleIndex: number? = nil

local function isJackpotHarnessEnabled(): boolean
    return RunService:IsStudio() and StudioTestConfig.EnableJackpotHarness == true
end

assert(
    WorldCycleConfig.GreatFrostThawMultiplier > 1,
    "WorldCycleConfig.GreatFrostThawMultiplier must be greater than one"
)

local function getGreatFrostOverlapRealSeconds(
    thawItem: PlayerStateService.ThawItem,
    frostStartedAtTime: number,
    frostContributionEndsAtTime: number
): number
    local overlapStart = math.max(thawItem.DepositedAtTime, frostStartedAtTime)
    local availableFrostRealSeconds = math.max(0, frostContributionEndsAtTime - overlapStart)
    if availableFrostRealSeconds == 0 then
        return 0
    end

    local effectiveElapsedAtOverlapStart = overlapStart
        - thawItem.DepositedAtTime
        + thawItem.BonusProgressSeconds
    local effectiveSecondsUntilReady = thawItem.BaseDurationSeconds - effectiveElapsedAtOverlapStart
    if effectiveSecondsUntilReady <= 0 then
        return 0
    end

    local realSecondsUntilReady = effectiveSecondsUntilReady / WorldCycleConfig.GreatFrostThawMultiplier
    return math.min(availableFrostRealSeconds, realSecondsUntilReady)
end

local function getEffectiveElapsedAtTime(
    thawItem: PlayerStateService.ThawItem,
    currentTime: number
): number
    local elapsed = currentTime - thawItem.DepositedAtTime + thawItem.BonusProgressSeconds
    local frostStartedAtTime = activeGreatFrostStartedAtTime
    local frostEndsAtTime = activeGreatFrostEndsAtTime

    if currentWorldCyclePhase == GREAT_FROST_PHASE and frostStartedAtTime and frostEndsAtTime then
        local contributionEndsAtTime = math.min(currentTime, frostEndsAtTime)
        local activeFrostRealSeconds = getGreatFrostOverlapRealSeconds(
            thawItem,
            frostStartedAtTime,
            contributionEndsAtTime
        )
        elapsed += activeFrostRealSeconds * (WorldCycleConfig.GreatFrostThawMultiplier - 1)
    end

    return elapsed
end

local function isBeginRevealRateLimited(player: Player): boolean
    local now = os.clock()
    local lastRequestAt = lastBeginRevealRequestAtByPlayer[player]
    lastBeginRevealRequestAtByPlayer[player] = now

    return lastRequestAt ~= nil and now - lastRequestAt < ThawConfig.BeginRevealRequestMinInterval
end

local function generateSessionID(): string
    local sessionID = HttpService:GenerateGUID(false)

    while issuedSessionIDs[sessionID] do
        sessionID = HttpService:GenerateGUID(false)
    end

    issuedSessionIDs[sessionID] = true
    return sessionID
end

local function updateReadyInteraction(visualIce: BasePart, isReady: boolean, currentRevealHit: number)
    local actionText = if currentRevealHit == REQUIRED_REVEAL_HITS - 1 then "Smash Ice" else "Crack Ice"

    local interactionPart = IceVisualFactory.GetInteractionPart(visualIce)
    local existingPrompt = interactionPart:FindFirstChild(READY_PROMPT_NAME)

    if not isReady then
        if existingPrompt then
            existingPrompt:Destroy()
        end
        return
    end

    if existingPrompt then
        assert(
            existingPrompt:IsA("ProximityPrompt"),
            string.format("%s must be a ProximityPrompt", existingPrompt:GetFullName())
        )
        existingPrompt.Enabled = true
        existingPrompt.ActionText = actionText
        return
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = READY_PROMPT_NAME
    prompt.ActionText = actionText
    prompt.ObjectText = "Ready to Crack"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = ThawConfig.ReadyPromptMaxActivationDistance
    prompt.RequiresLineOfSight = false
    prompt.Parent = interactionPart
end

local function getVisualStage(progress: number): string
    if progress >= ThawConfig.VisualStages.Ready.MinimumProgress then
        return "Ready"
    end

    if progress >= ThawConfig.VisualStages.NearlyReady.MinimumProgress then
        return "NearlyReady"
    end

    if progress >= ThawConfig.VisualStages.Thawing.MinimumProgress then
        return "Thawing"
    end

    return "Frozen"
end

local function updatePresentation(
    visualIce: BasePart,
    thawItem: PlayerStateService.ThawItem,
    readyInteractionAvailable: boolean,
    currentRevealHit: number
)
    local currentTime = Workspace:GetServerTimeNow()
    local effectiveElapsed = getEffectiveElapsedAtTime(thawItem, currentTime)
    local progress = math.clamp(effectiveElapsed / thawItem.BaseDurationSeconds, 0, 1)
    local isReady = progress >= 1
    local effectiveSecondsUntilReady = math.max(0, thawItem.BaseDurationSeconds - effectiveElapsed)
    local readyAt = currentTime + effectiveSecondsUntilReady

    visualIce:SetAttribute(THAW_READY_AT_ATTRIBUTE, readyAt)
    local stageName = getVisualStage(progress)
    IceVisualFactory.ApplyThawStage(visualIce, stageName)
    IceVisualFactory.ApplyRevealHit(visualIce, currentRevealHit)
    updateReadyInteraction(visualIce, isReady and readyInteractionAvailable, currentRevealHit)
end

local function getRevealHit(playerState: PlayerStateService.PlayerState, thawID: string): number
    local activeRevealSession = playerState.ActiveRevealSession
    if activeRevealSession and activeRevealSession.ThawID == thawID then
        return activeRevealSession.CurrentHit
    end

    return 0
end

local function generateThawID(activeThawItems: { [string]: PlayerStateService.ThawItem }): string
    local thawID = HttpService:GenerateGUID(false)

    while activeThawItems[thawID] ~= nil do
        thawID = HttpService:GenerateGUID(false)
    end

    return thawID
end

local function getPlayerFolder(player: Player): Folder
    local container = thawVisualsFolder
    assert(container, "ThawService must be started before creating thaw visuals")
    assert(container:IsDescendantOf(Workspace), "Workspace.PrototypeBase.ThawVisuals must be in Workspace")

    local folderName = PLAYER_FOLDER_PREFIX .. player.UserId
    local existingFolder = container:FindFirstChild(folderName)
    if existingFolder then
        assert(existingFolder:IsA("Folder"), string.format("%s.%s must be a Folder", container:GetFullName(), folderName))
        return existingFolder
    end

    local folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = container

    return folder
end

local function getSortedThawItems(activeThawItems: { [string]: PlayerStateService.ThawItem }): { PlayerStateService.ThawItem }
    local sortedThawItems = {}

    for _, thawItem in activeThawItems do
        table.insert(sortedThawItems, thawItem)
    end

    table.sort(sortedThawItems, function(left, right)
        if left.DepositedAtTime == right.DepositedAtTime then
            return left.ThawID < right.ThawID
        end

        return left.DepositedAtTime < right.DepositedAtTime
    end)

    return sortedThawItems
end

local function getDisplayCFrame(displayIndex: number, iceType: string, weightMultiplier: number): CFrame
    local anchor = penFloor
    local surfaceY = presentationSurfaceY
    assert(anchor, "ThawService must be started before positioning thaw visuals")
    assert(surfaceY, "ThawService must have a presentation surface before positioning thaw visuals")

    local zeroBasedIndex = displayIndex - 1
    local column = zeroBasedIndex % GRID_COLUMNS
    local row = math.floor(zeroBasedIndex / GRID_COLUMNS)
    local xOffset = (column - (GRID_COLUMNS - 1) * 0.5) * GRID_COLUMN_SPACING
    local zOffset = anchor.Size.Z * 0.5
        + MAX_PROTOTYPE_VISUAL_DEPTH * 0.5
        + GRID_FIRST_ROW_PADDING
        + row * GRID_ROW_SPACING
    local visualSize = IceVisualFactory.GetScaledSize(iceType, weightMultiplier)
    local horizontalCFrame = anchor.CFrame * CFrame.new(xOffset, 0, zOffset)
    local position = Vector3.new(
        horizontalCFrame.Position.X,
        surfaceY + visualSize.Y * 0.5,
        horizontalCFrame.Position.Z
    )

    return CFrame.new(position) * horizontalCFrame.Rotation
end

local function createVisual(
    player: Player,
    thawItem: PlayerStateService.ThawItem,
    displayIndex: number,
    readyInteractionAvailable: boolean
): BasePart
    local creature = CreatureConfig[thawItem.CreatureID]
    assert(creature, string.format("Unknown creature %s in ThawItem %s", thawItem.CreatureID, thawItem.ThawID))

    local playerFolder = getPlayerFolder(player)
    local visualIce = IceVisualFactory.Create(
        thawItem.IceType,
        creature.SilhouetteProfile,
        thawItem.WeightMultiplier,
        getDisplayCFrame(displayIndex, thawItem.IceType, thawItem.WeightMultiplier),
        playerFolder
    )
    local configured, configurationError = pcall(function()
        visualIce.Name = thawItem.IceType .. "ThawIce"
        visualIce:SetAttribute("ThawID", thawItem.ThawID)
        IceVisualFactory.GetInteractionPart(visualIce):SetAttribute("ThawID", thawItem.ThawID)
        local playerState = PlayerStateService.GetState(player)
        assert(playerState, "Player state must exist while creating a thaw visual")
        updatePresentation(visualIce, thawItem, readyInteractionAvailable, getRevealHit(playerState, thawItem.ThawID))

        assert(visualIce:IsDescendantOf(Workspace), "Created thaw visual must be parented under Workspace")
        assert(
            visualIce.Size.X > 0 and visualIce.Size.Y > 0 and visualIce.Size.Z > 0,
            "Created thaw visual must have a non-zero size"
        )
        assert(visualIce.Transparency < 1, "Created thaw visual must be visible")
        assert(
            visualIce.Position.Y - visualIce.Size.Y * 0.5
                >= (presentationSurfaceY or 0) - PRESENTATION_SURFACE_EPSILON,
            "Created thaw visual must be above the base presentation surface"
        )
    end)

    if not configured then
        visualIce:Destroy()
        error(configurationError, 0)
    end

    return visualIce
end

local function updateThawPresentations()
    for player, playerVisuals in visualsByPlayer do
        local playerState = PlayerStateService.GetState(player)
        if playerState then
            for thawID, visualIce in playerVisuals do
                local thawItem = playerState.ActiveThawItems[thawID]
                if thawItem and visualIce:IsDescendantOf(Workspace) then
                    local activeRevealSession = playerState.ActiveRevealSession
                    local readyInteractionAvailable = playerState.CurrentlyCarryingIceID == nil
                        and (activeRevealSession == nil or activeRevealSession.ThawID == thawID)
                    local updated, updateError = pcall(
                        updatePresentation,
                        visualIce,
                        thawItem,
                        readyInteractionAvailable,
                        getRevealHit(playerState, thawID)
                    )
                    if not updated then
                        visualIce:Destroy()
                        playerVisuals[thawID] = nil
                        warn(string.format(
                            "[ThawService] Failed to update ThawItem %s visual for %s: %s",
                            thawID,
                            player.Name,
                            tostring(updateError)
                        ))
                    end
                end
            end
        end
    end
end

local function removePlayerVisuals(player: Player)
    local playerVisuals = visualsByPlayer[player]
    if playerVisuals then
        for _, visualIce in playerVisuals do
            visualIce:Destroy()
        end
    end

    visualsByPlayer[player] = nil

    local container = thawVisualsFolder
    local playerFolder = container and container:FindFirstChild(PLAYER_FOLDER_PREFIX .. player.UserId)
    if playerFolder then
        playerFolder:Destroy()
    end
end

function ThawService.RefreshPlayerVisuals(player: Player): ()
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        removePlayerVisuals(player)
        return
    end

    local playerVisuals = visualsByPlayer[player]
    if not playerVisuals then
        playerVisuals = {}
        visualsByPlayer[player] = playerVisuals
    end

    for thawID, visualIce in playerVisuals do
        if playerState.ActiveThawItems[thawID] == nil then
            visualIce:Destroy()
            playerVisuals[thawID] = nil
        end
    end

    for displayIndex, thawItem in getSortedThawItems(playerState.ActiveThawItems) do
        local refreshed, refreshError = pcall(function()
            local activeRevealSession = playerState.ActiveRevealSession
            local readyInteractionAvailable = playerState.CurrentlyCarryingIceID == nil
                and (activeRevealSession == nil or activeRevealSession.ThawID == thawItem.ThawID)
            local visualIce = playerVisuals[thawItem.ThawID]
            if visualIce and (
                not visualIce:IsDescendantOf(Workspace)
                or visualIce:GetAttribute("IceType") ~= thawItem.IceType
                or visualIce:GetAttribute("ThawID") ~= thawItem.ThawID
            ) then
                visualIce:Destroy()
                playerVisuals[thawItem.ThawID] = nil
                visualIce = nil
            end

            if not visualIce then
                visualIce = createVisual(player, thawItem, displayIndex, readyInteractionAvailable)
                playerVisuals[thawItem.ThawID] = visualIce
            else
                IceVisualFactory.SetCFrame(
                    visualIce,
                    getDisplayCFrame(displayIndex, thawItem.IceType, thawItem.WeightMultiplier)
                )
                updatePresentation(
                    visualIce,
                    thawItem,
                    readyInteractionAvailable,
                    getRevealHit(playerState, thawItem.ThawID)
                )
            end
        end)

        if not refreshed then
            local failedVisual = playerVisuals[thawItem.ThawID]
            if failedVisual then
                failedVisual:Destroy()
                playerVisuals[thawItem.ThawID] = nil
            end

            warn(string.format(
                "[ThawService] Failed to refresh ThawItem %s visual for %s: %s",
                thawItem.ThawID,
                player.Name,
                tostring(refreshError)
            ))
        end
    end
end

function ThawService.CreateFromDepositedIce(
    player: Player,
    depositedIce: DepositedIce
): PlayerStateService.ThawItem?
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return nil
    end

    local iceTypeConfig = IceConfig[depositedIce.IceType]
    if not iceTypeConfig then
        return nil
    end

    local creature = CreatureConfig[depositedIce.CreatureID]
    if not creature
        or creature.Rarity ~= depositedIce.Rarity
        or not RarityConfig[depositedIce.Rarity]
        or type(depositedIce.WeightMultiplier) ~= "number"
    then
        return nil
    end
    SizeConfig.GetVisualScale(depositedIce.WeightMultiplier)

    local thawID = generateThawID(playerState.ActiveThawItems)
    local thawItem: PlayerStateService.ThawItem = {
        ThawID = thawID,
        PlayerUserID = player.UserId,
        IceType = depositedIce.IceType,
        CreatureID = depositedIce.CreatureID,
        Rarity = depositedIce.Rarity,
        WeightMultiplier = depositedIce.WeightMultiplier,
        DepositedAtTime = Workspace:GetServerTimeNow(),
        BaseDurationSeconds = iceTypeConfig.BaseThawDuration,
        BonusProgressSeconds = INITIAL_BONUS_PROGRESS_SECONDS,
    }

    playerState.ActiveThawItems[thawID] = thawItem

    local refreshed, refreshError = pcall(ThawService.RefreshPlayerVisuals, player)
    if not refreshed then
        warn(string.format("Failed to refresh thaw visuals for %s: %s", player.Name, tostring(refreshError)))
    end

    return thawItem
end

function ThawService.GetByID(player: Player, thawID: string): PlayerStateService.ThawItem?
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return nil
    end

    return playerState.ActiveThawItems[thawID]
end

function ThawService.GetAll(player: Player): { [string]: PlayerStateService.ThawItem }?
    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return nil
    end

    return playerState.ActiveThawItems
end

function ThawService.GetProgress(thawItem: PlayerStateService.ThawItem): number
    assert(thawItem.BaseDurationSeconds > 0, "ThawItem BaseDurationSeconds must be greater than zero")

    local currentTime = Workspace:GetServerTimeNow()
    local elapsed = getEffectiveElapsedAtTime(thawItem, currentTime)

    return math.clamp(elapsed / thawItem.BaseDurationSeconds, 0, 1)
end

function ThawService.HandleWorldCyclePhaseChanged(
    currentPhase: string,
    cycleIndex: number,
    phaseStartedAtTime: number,
    phaseEndsAtTime: number
): ()
    if currentPhase == GREAT_FROST_PHASE then
        if activeGreatFrostCycleIndex == cycleIndex or lastCompletedGreatFrostCycleIndex == cycleIndex then
            return
        end

        currentWorldCyclePhase = GREAT_FROST_PHASE
        activeGreatFrostCycleIndex = cycleIndex
        activeGreatFrostStartedAtTime = phaseStartedAtTime
        activeGreatFrostEndsAtTime = phaseEndsAtTime

        for _, player in Players:GetPlayers() do
            ThawService.RefreshPlayerVisuals(player)
        end

        return
    end

    if currentPhase ~= DAY_PHASE then
        return
    end

    local completedCycleIndex = activeGreatFrostCycleIndex
    local frostStartedAtTime = activeGreatFrostStartedAtTime
    local frostEndsAtTime = activeGreatFrostEndsAtTime
    local foldedCompletedFrost = false

    if completedCycleIndex ~= nil
        and frostStartedAtTime ~= nil
        and frostEndsAtTime ~= nil
        and lastCompletedGreatFrostCycleIndex ~= completedCycleIndex
    then
        local completedFrostEndsAtTime = math.min(frostEndsAtTime, phaseStartedAtTime)

        for _, player in Players:GetPlayers() do
            local playerState = PlayerStateService.GetState(player)
            if playerState then
                for _, thawItem in playerState.ActiveThawItems do
                    local frostOverlapRealSeconds = getGreatFrostOverlapRealSeconds(
                        thawItem,
                        frostStartedAtTime,
                        completedFrostEndsAtTime
                    )
                    thawItem.BonusProgressSeconds += frostOverlapRealSeconds
                        * (WorldCycleConfig.GreatFrostThawMultiplier - 1)
                end
            end
        end

        lastCompletedGreatFrostCycleIndex = completedCycleIndex
        foldedCompletedFrost = true

    end

    currentWorldCyclePhase = DAY_PHASE
    activeGreatFrostCycleIndex = nil
    activeGreatFrostStartedAtTime = nil
    activeGreatFrostEndsAtTime = nil

    if foldedCompletedFrost then
        for _, player in Players:GetPlayers() do
            ThawService.RefreshPlayerVisuals(player)
        end
    end
end

function ThawService.TryBeginReveal(player: Player, thawID: any): boolean
    if type(thawID) ~= "string" or thawID == "" then
        return false
    end

    if isBeginRevealRateLimited(player) then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return false
    end

    if playerState.IsFrozen then
        return false
    end

    if playerState.CurrentlyCarryingIceID ~= nil then
        return false
    end

    local thawItem = playerState.ActiveThawItems[thawID]
    if not thawItem then
        return false
    end

    if thawItem.PlayerUserID ~= player.UserId then
        return false
    end

    if ThawService.GetProgress(thawItem) < 1 then
        return false
    end

    local playerVisuals = visualsByPlayer[player]
    local visualIce = playerVisuals and playerVisuals[thawID]
    if not visualIce or not visualIce:IsDescendantOf(Workspace) then
        return false
    end

    local interactionPart = IceVisualFactory.GetInteractionPart(visualIce)
    if (rootPart.Position - interactionPart.Position).Magnitude > ThawConfig.BeginRevealMaxDistance then
        return false
    end

    if playerState.ActiveRevealSession ~= nil then
        return false
    end

    local firstHitTime = Workspace:GetServerTimeNow()
    local revealSession: PlayerStateService.RevealSession = {
        SessionID = generateSessionID(),
        PlayerUserID = player.UserId,
        ThawID = thawID,
        CurrentHit = 1,
        RequiredHits = REQUIRED_REVEAL_HITS,
        LastHitTime = firstHitTime,
    }
    playerState.ActiveRevealSession = revealSession

    ThawService.RefreshPlayerVisuals(player)
    gameplayEvent:FireClient(player, "RevealSessionStarted", revealSession.SessionID, thawID)

    return true
end

function ThawService.TryCrack(player: Player, sessionID: any): boolean
    if type(sessionID) ~= "string" or sessionID == "" then
        return false
    end

    local playerState = PlayerStateService.GetState(player)
    if not playerState then
        return false
    end

    local revealSession = playerState.ActiveRevealSession
    if not revealSession then
        return false
    end

    if revealSession.SessionID ~= sessionID or revealSession.PlayerUserID ~= player.UserId then
        return false
    end

    local thawItem = playerState.ActiveThawItems[revealSession.ThawID]
    if not thawItem then
        return false
    end

    if thawItem.PlayerUserID ~= player.UserId or thawItem.IsResolving then
        return false
    end

    if revealSession.RequiredHits ~= REQUIRED_REVEAL_HITS then
        return false
    end

    if revealSession.CurrentHit ~= 1 and revealSession.CurrentHit ~= 2 then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
        return false
    end

    local playerVisuals = visualsByPlayer[player]
    if not playerVisuals then
        return false
    end

    local visualIce = playerVisuals[revealSession.ThawID]
    if not visualIce or not visualIce:IsDescendantOf(Workspace) then
        return false
    end

    local interactionPart = IceVisualFactory.GetInteractionPart(visualIce)
    if (rootPart.Position - interactionPart.Position).Magnitude > ThawConfig.CrackMaxDistance then
        return false
    end

    local acceptedHitTime = Workspace:GetServerTimeNow()
    local lastHitTime = revealSession.LastHitTime
    if lastHitTime == nil or acceptedHitTime - lastHitTime < ThawConfig.CrackRequestMinInterval then
        return false
    end

    if revealSession.CurrentHit == 2 then
        local hasValidSize = pcall(SizeConfig.GetVisualScale, thawItem.WeightMultiplier)
        if not hasValidSize then
            warn(string.format(
                "[ThawService] Refusing final reveal for ThawItem %s with malformed WeightMultiplier %s",
                thawItem.ThawID,
                tostring(thawItem.WeightMultiplier)
            ))
            return false
        end

        thawItem.IsResolving = true

        local creatureID = thawItem.CreatureID
        local rarity = thawItem.Rarity
        local surfaceY = presentationSurfaceY
        assert(surfaceY, "ThawService must have a presentation surface before revealing a creature")
        local revealPosition = Vector3.new(visualIce.Position.X, surfaceY, visualIce.Position.Z)
        local revealCFrame = CFrame.new(revealPosition) * visualIce.CFrame.Rotation
        local revealParent = visualIce.Parent
        assert(revealParent, "Thaw visual must have a parent before revealing a creature")
        local creatureGUID = CreatureService.CreateCreatureCopy(player, creatureID, thawItem.WeightMultiplier)
        if not creatureGUID then
            thawItem.IsResolving = nil
            return false
        end
        local creatureStats = CreatureService.GetCreatureCopyStats(playerState, creatureGUID)
        assert(creatureStats, string.format("Revealed CreatureGUID %s must have valid derived stats", creatureGUID))
        CreatureService.AssignRevealedCreatureToFirstEmptyPenSlot(player, creatureGUID)

        if isJackpotHarnessEnabled()
            and creatureID == JACKPOT_CREATURE_ID
            and thawItem.WeightMultiplier == JACKPOT_WEIGHT_MULTIPLIER
        then
            print(string.format(
                "[D6-R10] jackpot-revealed creatureGuid=%s weight=%d scale=%.3f income=%d speed=%.1f",
                creatureGUID,
                thawItem.WeightMultiplier,
                creatureStats.Scale,
                creatureStats.FinalIncome,
                creatureStats.FinalWalkSpeed
            ))
        end

        playerState.ActiveThawItems[thawItem.ThawID] = nil
        visualIce:Destroy()
        playerVisuals[thawItem.ThawID] = nil
        playerState.ActiveRevealSession = nil

        local presentationSucceeded, presentedModelOrError = pcall(
            CreatureRevealService.PresentTemporary,
            creatureGUID,
            creatureID,
            creatureStats,
            revealCFrame,
            rootPart.Position,
            revealParent
        )
        if not presentationSucceeded then
            warn(string.format(
                "[ThawService] Creature %s was granted but its reveal presentation failed: %s",
                creatureID,
                presentedModelOrError
            ))
        end

        gameplayEvent:FireClient(player, "CreatureRevealed", creatureID, rarity)
        CreatureService.SendCreatureStateUpdate(player)

        return true
    end

    revealSession.CurrentHit += 1
    revealSession.LastHitTime = acceptedHitTime
    IceVisualFactory.ApplyRevealHit(visualIce, revealSession.CurrentHit)
    updateReadyInteraction(visualIce, true, revealSession.CurrentHit)

    return true
end

function ThawService.Start(): ()
    if hasStarted then
        return
    end

    hasStarted = true

    local prototypeBase = Workspace:WaitForChild("PrototypeBase")
    local pen = prototypeBase:WaitForChild("Pen")
    local depositPart = pen:WaitForChild("PenFloor")
    local homeGround = prototypeBase:WaitForChild("HomeGround")
    local warmZone = prototypeBase:WaitForChild("WarmZone")
    local container = prototypeBase:WaitForChild(THAW_VISUALS_FOLDER_NAME)

    assert(prototypeBase:IsA("Folder"), "Workspace.PrototypeBase must be a Folder")
    assert(pen:IsA("Model"), "Workspace.PrototypeBase.Pen must be a Model")
    assert(depositPart:IsA("BasePart"), "Workspace.PrototypeBase.Pen.PenFloor must be a BasePart")
    assert(homeGround:IsA("BasePart"), "Workspace.PrototypeBase.HomeGround must be a BasePart")
    assert(warmZone:IsA("BasePart"), "Workspace.PrototypeBase.WarmZone must be a BasePart")
    assert(container:IsA("Folder"), "Workspace.PrototypeBase.ThawVisuals must be a Folder")

    container:ClearAllChildren()
    thawVisualsFolder = container
    penFloor = depositPart
    presentationSurfaceY = math.max(
        homeGround.Position.Y + homeGround.Size.Y * 0.5,
        warmZone.Position.Y + warmZone.Size.Y * 0.5
    )

    Players.PlayerRemoving:Connect(function(player)
        lastBeginRevealRequestAtByPlayer[player] = nil
        removePlayerVisuals(player)
    end)
    RunService.Heartbeat:Connect(function(deltaTime)
        presentationUpdateElapsed += deltaTime
        if presentationUpdateElapsed < ThawConfig.PresentationUpdateIntervalSeconds then
            return
        end

        presentationUpdateElapsed = 0
        updateThawPresentations()
    end)

    for _, player in Players:GetPlayers() do
        ThawService.RefreshPlayerVisuals(player)
    end
end

return ThawService
