local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureRosterConfig = require(shared:WaitForChild("CreatureRosterConfig"))
local GameConfig = require(shared:WaitForChild("GameConfig"))
local IceConfig = require(shared:WaitForChild("IceConfig"))
local PenConfig = require(shared:WaitForChild("PenConfig"))
local RarityConfig = require(shared:WaitForChild("RarityConfig"))

local CreaturePortrait = require(script.Parent.CreaturePortrait)
local OwnBaseController = require(script.Parent.OwnBaseController)

local CreatureInventoryController = {}

-- Prefabs: StarterGui.CreatureMenu, StarterGui.MainHud (LeftRail.MenuButtons.ArchiveButton, RightRail.CreaturesButton) and
-- ReplicatedStorage.UITemplates.CreatureMenu (CreatureCard / ArchiveTile), all authored in Studio.
local MENU_NAME = "CreatureMenu"
local HUD_NAME = "MainHud"
local TEMPLATE_FOLDER_NAME = "CreatureMenu"
local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local ARCHIVE_ICE_ORDER = { "Regular", "Thick", "Ancient", "Black", "Meteor" }
local UNDISCOVERED_TEXT = "???"
local SELL_CONFIRM_SECONDS = 3
-- Equip, Pen and Sell are server-validated near the own Pen; mirror that range so buttons never fail silently.
local MANAGE_MAX_DISTANCE = math.min(GameConfig.PenManagementMaxDistance, GameConfig.EquipMaxDistance)
local BASE_CHECK_INTERVAL = 0.25
local ICE_INSTANCE_ID_ATTRIBUTE = "IceInstanceID"
local CARRYING_HINT_TEXT = "PLACE OR DROP YOUR ICE FIRST"

local CREATURES_TAB = "Creatures"
local ARCHIVE_TAB = "Archive"
local TAB_ACTIVE_TEXT = Color3.fromRGB(244, 250, 255)
local TAB_IDLE_TEXT = Color3.fromRGB(150, 182, 212)

local SELECTED_RIM_COLOR = Color3.fromRGB(255, 255, 255)
local SELECTED_RIM_THICKNESS = 4
local CARD_RIM_THICKNESS = 2.5
local UNDISCOVERED_RIM_COLOR = Color3.fromRGB(60, 84, 120)
local FALLBACK_RARITY_COLOR = Color3.fromRGB(210, 215, 225)

local EQUIP_COLOR = Color3.fromRGB(76, 214, 110)
local UNEQUIP_COLOR = Color3.fromRGB(70, 156, 255)
local SELL_COLOR = Color3.fromRGB(196, 88, 64)
local SELL_CONFIRM_COLOR = Color3.fromRGB(235, 52, 44)
local EQUIPPED_BADGE_COLOR = Color3.fromRGB(110, 232, 180)
local PEN_BADGE_COLOR = Color3.fromRGB(240, 180, 110)
local INVENTORY_CHIP_COLOR = Color3.fromRGB(196, 238, 255)
local DISABLED_COLOR = Color3.fromRGB(96, 110, 130)

local OPEN_POP_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local OPEN_POP_START = 0.86
local DETAIL_SPIN_SPEED = 0.5 -- radians per second, presentation only

local started = false

type Menu = {
    Gui: ScreenGui,
    Pop: UIScale,
    Title: TextLabel,
    TitleIcon: ImageLabel,
    CreaturesTab: GuiButton,
    ArchiveTab: GuiButton,
    CreaturesPage: GuiObject,
    ArchivePage: GuiObject,
    CreatureList: ScrollingFrame,
    EmptyState: GuiObject,
    Detail: GuiObject,
    DetailViewport: ViewportFrame,
    DetailGlow: ImageLabel,
    DetailName: TextLabel,
    RarityChip: TextLabel,
    StateChip: TextLabel,
    SizeLabel: TextLabel,
    SpeedLabel: TextLabel,
    IncomeLabel: TextLabel,
    PrimaryButton: GuiButton,
    SecondaryButton: GuiButton,
    SellButton: GuiButton,
    BaseHint: GuiObject,
    ArchiveList: ScrollingFrame,
    ArchiveCount: TextLabel,
    ArchiveFill: GuiObject,
    CardTemplate: GuiButton,
    TileTemplate: GuiObject,
}

type ArchiveEntry = {
    CreatureID: string,
    Tile: GuiObject,
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")
assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local currentTab = CREATURES_TAB
local cardsByGUID: { [string]: GuiButton } = {}
local recordsByGUID: { [string]: any } = {}
local orderedGUIDs: { string } = {}
local selectedGUID: string? = nil
local penHasCapacity = false
local archiveEntries: { ArchiveEntry } = {}
local archiveProgress = ""
local sellArmedAt: number? = nil
local detailModelID: string? = nil
local detailFocus: Vector3 = Vector3.zero
local detailDistance = 10
local detailAngle = 0
local spinConnection: RBXScriptConnection? = nil
local ownPenFloor: BasePart? = nil
local isAtBase = false -- true only when Equip / Pen / Sell can be used right now (at base and not carrying Ice)
local isCarrying = false
local baseHintText = ""

local function child(parent: Instance, ...: string): any
    local current = parent
    for _, name in { ... } do
        current = current:WaitForChild(name)
    end
    return current
end

local function setLabel(button: Instance, text: string): ()
    local label = button:FindFirstChild("Label")
    if label and label:IsA("TextLabel") then
        label.Text = text
    end
end

local function setFace(button: Instance, color: Color3): ()
    local face = button:FindFirstChild("Face")
    if face and face:IsA("UIGradient") then
        face.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.28), color:Lerp(Color3.new(0, 0, 0), 0.18))
    end
end

local function bindMenu(): Menu
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = playerGui:WaitForChild(MENU_NAME) :: ScreenGui
    local window = child(gui, "Window")
    local page = child(window, "Body", "CreaturesPage")
    local detail = child(page, "Detail")
    local actions = child(detail, "Actions")
    local archivePage = child(window, "Body", "ArchivePage")
    local templates = child(ReplicatedStorage, "UITemplates", TEMPLATE_FOLDER_NAME)

    return {
        Gui = gui,
        Pop = child(window, "Pop"),
        Title = child(window, "Header", "Title"),
        TitleIcon = child(window, "Header", "TitleIcon"),
        CreaturesTab = child(window, "Header", "Tabs", "CreaturesTab"),
        ArchiveTab = child(window, "Header", "Tabs", "ArchiveTab"),
        CreaturesPage = page,
        ArchivePage = archivePage,
        CreatureList = child(page, "CreatureList"),
        EmptyState = child(page, "EmptyState"),
        Detail = detail,
        DetailViewport = child(detail, "Viewport"),
        DetailGlow = child(detail, "Glow"),
        DetailName = child(detail, "CreatureName"),
        RarityChip = child(detail, "Chips", "RarityChip"),
        StateChip = child(detail, "Chips", "StateChip"),
        SizeLabel = child(detail, "Stats", "SizeStat", "Label"),
        SpeedLabel = child(detail, "Stats", "SpeedStat", "Label"),
        IncomeLabel = child(detail, "Stats", "IncomeStat", "Label"),
        PrimaryButton = child(actions, "PrimaryButton"),
        SecondaryButton = child(actions, "SecondaryButton"),
        SellButton = child(actions, "SellButton"),
        BaseHint = child(detail, "BaseHint"),
        ArchiveList = child(archivePage, "ArchiveList"),
        ArchiveCount = child(archivePage, "Progress", "Count"),
        ArchiveFill = child(archivePage, "Progress", "Bar", "Fill"),
        CardTemplate = child(templates, "CreatureCard"),
        TileTemplate = child(templates, "ArchiveTile"),
    }
end

local function getDisplayName(creatureID: string): string
    local creature = CreatureConfig[creatureID]
    if creature and type(creature.DisplayName) == "string" then
        return creature.DisplayName
    end

    return creatureID
end

local function getRarityUI(creatureID: string): (string, Color3)
    local creature = CreatureConfig[creatureID]
    local rarity = creature and creature.Rarity
    local rarityUI = rarity and RarityConfig[rarity] and RarityConfig[rarity].RarityUI
    if rarityUI then
        return string.upper(rarityUI.DisplayName), rarityUI.Color
    end

    return string.upper(if type(rarity) == "string" then rarity else ""), FALLBACK_RARITY_COLOR
end

local fillViewport = CreaturePortrait.Fill

-- Archive order follows the world: region by region, then rarity, as each species first appears.
local function getArchiveOrder(): { string }
    local order = {}
    local seen = {}
    for _, iceType in ARCHIVE_ICE_ORDER do
        local pools = IceConfig[iceType].CreaturePoolsByRarity
        for _, rarity in CreatureRosterConfig.RarityOrder do
            for _, creatureID in pools[rarity] do
                if not seen[creatureID] then
                    seen[creatureID] = true
                    table.insert(order, creatureID)
                end
            end
        end
    end

    return order
end

local function isValidCreatureRecord(record: any): boolean
    if type(record) ~= "table"
        or type(record.CreatureGUID) ~= "string"
        or record.CreatureGUID == ""
        or type(record.CreatureID) ~= "string"
        or CreatureConfig[record.CreatureID] == nil
        or type(record.Scale) ~= "number"
        or record.Scale ~= record.Scale
        or record.Scale <= 0
        or record.Scale >= math.huge
        or type(record.FinalIncome) ~= "number"
        or record.FinalIncome ~= record.FinalIncome
        or record.FinalIncome <= 0
        or record.FinalIncome >= math.huge
        or record.FinalIncome % 1 ~= 0
        or type(record.FinalWalkSpeed) ~= "number"
        or record.FinalWalkSpeed ~= record.FinalWalkSpeed
        or record.FinalWalkSpeed <= 0
        or record.FinalWalkSpeed >= math.huge
    then
        return false
    end

    if record.AllocationState == "Pen" then
        return type(record.PenSlotIndex) == "number"
            and record.PenSlotIndex % 1 == 0
            and record.PenSlotIndex >= 1
            and record.PenSlotIndex <= PenConfig.MaxSlots
    end

    return (record.AllocationState == "Inventory" or record.AllocationState == "Equipped")
        and record.PenSlotIndex == nil
end

local function isValidSellValue(value: any): boolean
    return type(value) == "number" and value > 0 and value < math.huge and value % 1 == 0
end

local function getStateText(record: any): string
    if record.AllocationState == "Pen" then
        return "PEN " .. record.PenSlotIndex
    elseif record.AllocationState == "Equipped" then
        return "EQUIPPED"
    end

    return "IN BAG"
end

local function disarmSell(menu: Menu): ()
    sellArmedAt = nil
    setFace(menu.SellButton, SELL_COLOR)
end

-- ===== detail pane =====
-- Carrier Commitment: the server rejects Equip, Pen and Sell while carrying Ice (the welded Ice carries its
-- IceInstanceID), so the menu mirrors it instead of failing silently.
local function isCarryingIce(character: Model?): boolean
    if not character then
        return false
    end
    for _, item in character:GetChildren() do
        if item:IsA("BasePart") and item:GetAttribute(ICE_INSTANCE_ID_ATTRIBUTE) ~= nil then
            return true
        end
    end
    return false
end

local function computeAtBase(): boolean
    local floor = ownPenFloor
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not floor or not root or not root:IsA("BasePart") then
        return false
    end
    return (root.Position - floor.Position).Magnitude <= MANAGE_MAX_DISTANCE
end

-- Management is available only at the own base and while not carrying Ice.
local function computeCanManage(): (boolean, boolean)
    local carrying = isCarryingIce(Players.LocalPlayer.Character)
    return computeAtBase() and not carrying, carrying
end

local function refreshDetail(menu: Menu): ()
    local carrying
    isAtBase, carrying = computeCanManage()
    isCarrying = carrying
    local record = if selectedGUID then recordsByGUID[selectedGUID] else nil
    menu.Detail.Visible = record ~= nil
    if not record then
        detailModelID = nil
        return
    end

    local rarityText, rarityColor = getRarityUI(record.CreatureID)
    menu.DetailName.Text = getDisplayName(record.CreatureID)
    menu.DetailGlow.ImageColor3 = rarityColor
    menu.RarityChip.Text = rarityText
    menu.RarityChip.BackgroundColor3 = rarityColor
    menu.StateChip.Text = getStateText(record)
    menu.StateChip.BackgroundColor3 = if record.AllocationState == "Equipped"
        then EQUIPPED_BADGE_COLOR
        elseif record.AllocationState == "Pen" then PEN_BADGE_COLOR
        else INVENTORY_CHIP_COLOR

    menu.SizeLabel.Text = string.format("Size %.2fx", record.Scale)
    menu.SpeedLabel.Text = string.format("Ride speed %.1f", record.FinalWalkSpeed)
    menu.IncomeLabel.Text = string.format("Pen income $%d/s", record.FinalIncome)

    if record.AllocationState == "Equipped" then
        setLabel(menu.PrimaryButton, "UNEQUIP")
        setFace(menu.PrimaryButton, UNEQUIP_COLOR)
        menu.SecondaryButton.Visible = false
    else
        setLabel(menu.PrimaryButton, "EQUIP")
        setFace(menu.PrimaryButton, EQUIP_COLOR)
        if record.AllocationState == "Pen" then
            setLabel(menu.SecondaryButton, "REMOVE FROM PEN")
            menu.SecondaryButton.Visible = true
        else
            setLabel(menu.SecondaryButton, "PLACE IN PEN")
            menu.SecondaryButton.Visible = penHasCapacity
        end
    end

    local canSell = isValidSellValue(record.SellValue)
    menu.SellButton.Visible = canSell
    if canSell and not sellArmedAt then
        setLabel(menu.SellButton, "SELL $" .. record.SellValue)
        setFace(menu.SellButton, SELL_COLOR)
    end

    menu.BaseHint.Visible = not isAtBase
    if menu.BaseHint:IsA("TextLabel") then
        if baseHintText == "" then
            baseHintText = menu.BaseHint.Text -- the prefab's own "return to base" text
        end
        menu.BaseHint.Text = if isCarrying then CARRYING_HINT_TEXT else baseHintText
    end
    if not isAtBase then
        for _, button in { menu.PrimaryButton, menu.SecondaryButton, menu.SellButton } do
            setFace(button, DISABLED_COLOR)
        end
    end

    -- Keep the two half-width buttons tidy when only one of them is shown.
    local secondaryShown = menu.SecondaryButton.Visible
    menu.SellButton.Size = if secondaryShown then UDim2.new(0.5, -3, 0, 40) else UDim2.new(1, 0, 0, 40)
    menu.SecondaryButton.Size = if canSell then UDim2.new(0.5, -3, 0, 40) else UDim2.new(1, 0, 0, 40)

    local modelKey = record.CreatureGUID
    if detailModelID ~= modelKey then
        detailModelID = modelKey
        local focus, distance = fillViewport(menu.DetailViewport, record.CreatureID)
        if focus and distance then
            detailFocus = focus
            detailDistance = distance
            detailAngle = 0
        end
    end
end

local function spinDetail(menu: Menu, deltaTime: number): ()
    local camera = menu.DetailViewport.CurrentCamera
    if not camera or not detailModelID then
        return
    end

    detailAngle += deltaTime * DETAIL_SPIN_SPEED
    local offset = Vector3.new(math.sin(detailAngle), 0.35, math.cos(detailAngle)).Unit * detailDistance
    camera.CFrame = CFrame.lookAt(detailFocus + offset, detailFocus)
end

-- ===== creature cards =====
local function styleCard(card: GuiButton, record: any, selected: boolean): ()
    local _, rarityColor = getRarityUI(record.CreatureID)
    local rim = card:FindFirstChild("Rim") :: UIStroke?
    if rim then
        rim.Color = if selected then SELECTED_RIM_COLOR else rarityColor
        rim.Thickness = if selected then SELECTED_RIM_THICKNESS else CARD_RIM_THICKNESS
    end
    local glow = card:FindFirstChild("Glow") :: ImageLabel
    local rarityBar = card:FindFirstChild("RarityBar") :: Frame
    local nameLabel = card:FindFirstChild("CreatureName") :: TextLabel
    glow.ImageColor3 = rarityColor
    rarityBar.BackgroundColor3 = rarityColor
    nameLabel.Text = getDisplayName(record.CreatureID)

    local badge = card:FindFirstChild("Badge") :: TextLabel
    if record.AllocationState == "Equipped" then
        badge.Text = "EQUIPPED"
        badge.BackgroundColor3 = EQUIPPED_BADGE_COLOR
        badge.Visible = true
    elseif record.AllocationState == "Pen" then
        badge.Text = "PEN " .. record.PenSlotIndex
        badge.BackgroundColor3 = PEN_BADGE_COLOR
        badge.Visible = true
    else
        badge.Visible = false
    end
end

local function refreshCardStyles(): ()
    for guid, card in cardsByGUID do
        styleCard(card, recordsByGUID[guid], guid == selectedGUID)
    end
end

local function selectCreature(menu: Menu, guid: string?): ()
    if guid ~= selectedGUID then
        disarmSell(menu)
    end
    selectedGUID = guid
    refreshCardStyles()
    refreshDetail(menu)
end

local function createCard(menu: Menu, record: any): GuiButton
    local card = menu.CardTemplate:Clone()
    card.Name = "Card_" .. record.CreatureGUID
    fillViewport(card:FindFirstChild("Icon") :: ViewportFrame, record.CreatureID)
    local guid = record.CreatureGUID
    card.Activated:Connect(function()
        selectCreature(menu, guid)
    end)
    card.Parent = menu.CreatureList
    return card
end

local function updateCreatures(menu: Menu, snapshot: any): ()
    if type(snapshot) ~= "table" or type(snapshot.Creatures) ~= "table" then
        return
    end

    local validRecords = {}
    local occupiedPenSlots = 0
    local seenGUIDs = {}
    for _, record in snapshot.Creatures do
        if isValidCreatureRecord(record) and not seenGUIDs[record.CreatureGUID] then
            seenGUIDs[record.CreatureGUID] = true
            table.insert(validRecords, record)
            if record.AllocationState == "Pen" then
                occupiedPenSlots += 1
            end
        end
    end

    -- The server sends the unlocked capacity; without a valid value the Pen is treated as full.
    local penCapacity = snapshot.PenCapacity
    local isValidCapacity = type(penCapacity) == "number"
        and penCapacity % 1 == 0
        and penCapacity >= 1
        and penCapacity <= PenConfig.MaxSlots
    penHasCapacity = isValidCapacity and occupiedPenSlots < penCapacity

    table.clear(recordsByGUID)
    table.clear(orderedGUIDs)
    for layoutOrder, record in validRecords do
        local guid = record.CreatureGUID
        recordsByGUID[guid] = record
        table.insert(orderedGUIDs, guid)
        local card = cardsByGUID[guid]
        if not card then
            card = createCard(menu, record)
            cardsByGUID[guid] = card
        end
        card.LayoutOrder = layoutOrder
    end

    for guid, card in cardsByGUID do
        if not recordsByGUID[guid] then
            card:Destroy()
            cardsByGUID[guid] = nil
        end
    end

    menu.EmptyState.Visible = #orderedGUIDs == 0
    local nextSelection = if selectedGUID and recordsByGUID[selectedGUID] then selectedGUID else orderedGUIDs[1]
    selectCreature(menu, nextSelection)
end

-- ===== archive =====
-- Undiscovered species stay a dark silhouette and "???"; discovery never reverses on the server.
local function updateArchive(menu: Menu, snapshot: any): ()
    if type(snapshot) ~= "table" or type(snapshot.DiscoveredCreatureIDs) ~= "table" then
        return
    end

    local discovered = {}
    for _, creatureID in snapshot.DiscoveredCreatureIDs do
        if type(creatureID) == "string" then
            discovered[creatureID] = true
        end
    end

    if #archiveEntries == 0 then
        for layoutOrder, creatureID in getArchiveOrder() do
            local tile = menu.TileTemplate:Clone()
            tile.Name = "Archive_" .. creatureID
            tile.LayoutOrder = layoutOrder
            tile.Parent = menu.ArchiveList
            table.insert(archiveEntries, { CreatureID = creatureID, Tile = tile })
        end
    end

    local discoveredCount = 0
    for _, entry in archiveEntries do
        local tile = entry.Tile
        local icon = tile:FindFirstChild("Icon") :: ViewportFrame
        if not icon:FindFirstChildWhichIsA("Model") then
            fillViewport(icon, entry.CreatureID)
        end

        local nameLabel = tile:FindFirstChild("CreatureName") :: TextLabel
        local rarityLabel = tile:FindFirstChild("Rarity") :: TextLabel
        local rim = tile:FindFirstChild("Rim") :: UIStroke
        local isDiscovered = discovered[entry.CreatureID] == true and CreatureConfig[entry.CreatureID] ~= nil
        if isDiscovered then
            discoveredCount += 1
            local rarityText, rarityColor = getRarityUI(entry.CreatureID)
            icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Text = getDisplayName(entry.CreatureID)
            rarityLabel.Text = rarityText
            rarityLabel.TextColor3 = rarityColor
            rim.Color = rarityColor
        else
            icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
            nameLabel.Text = UNDISCOVERED_TEXT
            rarityLabel.Text = ""
            rim.Color = UNDISCOVERED_RIM_COLOR
        end
    end

    archiveProgress = string.format("%d / %d", discoveredCount, #archiveEntries)
    menu.ArchiveCount.Text = archiveProgress
    menu.ArchiveFill.Size = UDim2.fromScale(if #archiveEntries > 0 then discoveredCount / #archiveEntries else 0, 1)
end

-- Creature models replicate after the first state update on a fresh join; fill any viewport that missed them.
local function refillMissingViewports(menu: Menu): ()
    for guid, card in cardsByGUID do
        local icon = card:FindFirstChild("Icon") :: ViewportFrame
        local record = recordsByGUID[guid]
        if record and not icon:FindFirstChildWhichIsA("Model") then
            fillViewport(icon, record.CreatureID)
        end
    end

    for _, entry in archiveEntries do
        local icon = entry.Tile:FindFirstChild("Icon") :: ViewportFrame
        if not icon:FindFirstChildWhichIsA("Model") then
            fillViewport(icon, entry.CreatureID)
        end
    end

    if detailModelID and not menu.DetailViewport:FindFirstChildWhichIsA("Model") then
        detailModelID = nil
        refreshDetail(menu)
    end
end

-- ===== open / tabs =====
local function setTab(menu: Menu, tab: string): ()
    currentTab = tab
    local showArchive = tab == ARCHIVE_TAB
    menu.CreaturesPage.Visible = not showArchive
    menu.ArchivePage.Visible = showArchive
    menu.Title.Text = if showArchive then "FROZEN ARCHIVE" else "CREATURES"
    local icon = (if showArchive then menu.ArchiveTab else menu.CreaturesTab):GetAttribute("Icon")
    if type(icon) == "string" then
        menu.TitleIcon.Image = icon
    end

    for button, active in { [menu.CreaturesTab] = not showArchive, [menu.ArchiveTab] = showArchive } do
        local selected = button:FindFirstChild("Selected") :: GuiObject
        local label = button:FindFirstChild("Label") :: TextLabel
        selected.Visible = active
        label.TextColor3 = if active then TAB_ACTIVE_TEXT else TAB_IDLE_TEXT
    end
end

local function setOpen(menu: Menu, open: boolean): ()
    if menu.Gui.Enabled == open then
        return
    end

    menu.Gui.Enabled = open
    disarmSell(menu)
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end

    if open then
        menu.Pop.Scale = OPEN_POP_START
        TweenService:Create(menu.Pop, OPEN_POP_INFO, { Scale = 1 }):Play()
        spinConnection = RunService.RenderStepped:Connect(function(deltaTime)
            spinDetail(menu, deltaTime)
        end)
    end
end

local function toggleTo(menu: Menu, tab: string): ()
    if menu.Gui.Enabled and currentTab == tab then
        setOpen(menu, false)
        return
    end

    setTab(menu, tab)
    setOpen(menu, true)
end

-- Two taps to sell: the first arms a short confirmation so a valuable copy is never sold by accident.
local function onSell(menu: Menu): ()
    local record = if selectedGUID then recordsByGUID[selectedGUID] else nil
    if not record or not isValidSellValue(record.SellValue) or not isAtBase then
        return
    end

    local now = os.clock()
    if sellArmedAt and now - sellArmedAt <= SELL_CONFIRM_SECONDS then
        disarmSell(menu)
        gameplayRequest:FireServer("SellCreature", record.CreatureGUID)
        -- Restore the label now; a rejected request sends no update that would otherwise reset "TAP AGAIN".
        refreshDetail(menu)
        return
    end

    sellArmedAt = now
    setLabel(menu.SellButton, "TAP AGAIN")
    setFace(menu.SellButton, SELL_CONFIRM_COLOR)
    task.delay(SELL_CONFIRM_SECONDS, function()
        if sellArmedAt == now then
            disarmSell(menu)
            refreshDetail(menu)
        end
    end)
end

local function bindActions(menu: Menu): ()
    menu.PrimaryButton.Activated:Connect(function()
        local record = if selectedGUID then recordsByGUID[selectedGUID] else nil
        if not record or not isAtBase then
            return
        end
        if record.AllocationState == "Equipped" then
            gameplayRequest:FireServer("UnequipCreature", record.CreatureGUID)
        else
            gameplayRequest:FireServer("EquipCreature", record.CreatureGUID)
        end
    end)

    menu.SecondaryButton.Activated:Connect(function()
        local record = if selectedGUID then recordsByGUID[selectedGUID] else nil
        if not record or not isAtBase then
            return
        end
        if record.AllocationState == "Pen" then
            gameplayRequest:FireServer("RemoveFromPen", record.CreatureGUID)
        elseif record.AllocationState == "Inventory" and penHasCapacity then
            gameplayRequest:FireServer("PlaceInPen", record.CreatureGUID)
        end
    end)

    menu.SellButton.Activated:Connect(function()
        onSell(menu)
    end)

    -- Re-evaluate the base range while the menu is open so the buttons and hint follow the player.
    local baseCheckElapsed = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        if not menu.Gui.Enabled then
            return
        end
        baseCheckElapsed += deltaTime
        if baseCheckElapsed < BASE_CHECK_INTERVAL then
            return
        end
        baseCheckElapsed = 0
        local canManage, carrying = computeCanManage()
        if canManage ~= isAtBase or carrying ~= isCarrying then
            disarmSell(menu)
            refreshDetail(menu)
        end
    end)

    task.spawn(function()
        local base = OwnBaseController.WaitForOwnBase()
        ownPenFloor = base:WaitForChild("Pen"):WaitForChild("PenFloor") :: BasePart
    end)
end

function CreatureInventoryController.Start(): ()
    if started then
        return
    end
    started = true

    local menu = bindMenu()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local hud = child(playerGui, HUD_NAME)

    setTab(menu, CREATURES_TAB)
    menu.Detail.Visible = false
    bindActions(menu)

    child(hud, "RightRail", "CreaturesButton").Activated:Connect(function()
        toggleTo(menu, CREATURES_TAB)
    end)
    child(hud, "LeftRail", "MenuButtons", "ArchiveButton").Activated:Connect(function()
        toggleTo(menu, ARCHIVE_TAB)
    end)
    menu.CreaturesTab.Activated:Connect(function()
        setTab(menu, CREATURES_TAB)
    end)
    menu.ArchiveTab.Activated:Connect(function()
        setTab(menu, ARCHIVE_TAB)
    end)
    child(menu.Gui, "Window", "CloseButton").Activated:Connect(function()
        setOpen(menu, false)
    end)
    child(menu.Gui, "Dim").Activated:Connect(function()
        setOpen(menu, false)
    end)

    task.spawn(function()
        local creatureVisuals = ReplicatedStorage:WaitForChild(CREATURE_VISUALS_FOLDER_NAME)
        creatureVisuals.ChildAdded:Connect(function()
            task.defer(refillMissingViewports, menu)
        end)
        refillMissingViewports(menu)
    end)

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "CreatureStateUpdated" then
            updateCreatures(menu, data)
            updateArchive(menu, data)
        end
    end)
end

return CreatureInventoryController
