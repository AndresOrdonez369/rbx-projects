local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local CreatureRosterConfig = require(shared:WaitForChild("CreatureRosterConfig"))
local IceConfig = require(shared:WaitForChild("IceConfig"))
local PenConfig = require(shared:WaitForChild("PenConfig"))
local RarityConfig = require(shared:WaitForChild("RarityConfig"))

local CreatureInventoryController = {}

local HUD_NAME = "CreatureInventoryHud"
local CREATURE_VISUALS_FOLDER_NAME = "CreatureVisuals"
local ARCHIVE_ICE_ORDER = { "Regular", "Thick", "Ancient", "Black", "Meteor" }
local ARCHIVE_ROW_HEIGHT = 64
local UNDISCOVERED_TEXT = "???"
local SELL_CONFIRM_SECONDS = 3
local SELL_BUTTON_COLOR = Color3.fromRGB(122, 70, 52)
local SELL_CONFIRM_COLOR = Color3.fromRGB(190, 58, 46)
local started = false

type ArchiveEntry = {
    CreatureID: string,
    Icon: ViewportFrame,
    NameLabel: TextLabel,
    RarityLabel: TextLabel,
}

type Archive = {
    List: ScrollingFrame,
    Button: TextButton,
    Title: TextLabel,
    Entries: { ArchiveEntry },
    Progress: string,
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")
assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local function makeTextLabel(name: string, text: string, textSize: number): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(245, 248, 255)
    label.TextSize = textSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left

    return label
end

local function makeButton(name: string, text: string): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.AutoButtonColor = true
    button.BackgroundColor3 = Color3.fromRGB(55, 112, 154)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14

    return button
end

local function createHud(): (ScrollingFrame, Archive)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local existingHud = playerGui:FindFirstChild(HUD_NAME)
    if existingHud then
        existingHud:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = HUD_NAME
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 20
    screenGui.Parent = playerGui

    local openButton = makeButton("CreaturesButton", "CREATURES")
    openButton.AnchorPoint = Vector2.new(1, 0)
    openButton.Position = UDim2.new(1, -24, 0, 24)
    openButton.Size = UDim2.fromOffset(150, 48)
    openButton.Parent = screenGui

    local panel = Instance.new("Frame")
    panel.Name = "CreaturePanel"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -24, 0, 82)
    panel.Size = UDim2.new(1, -48, 0.72, 0)
    panel.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui

    local panelSizeConstraint = Instance.new("UISizeConstraint")
    panelSizeConstraint.MaxSize = Vector2.new(360, 10000)
    panelSizeConstraint.Parent = panel

    local title = makeTextLabel("Title", "CREATURES", 22)
    title.Font = Enum.Font.GothamBold
    title.Position = UDim2.fromOffset(16, 10)
    title.Size = UDim2.new(1, -32, 0, 32)
    title.Parent = panel

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Position = UDim2.fromOffset(16, 48)
    divider.Size = UDim2.new(1, -32, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(92, 107, 122)
    divider.BorderSizePixel = 0
    divider.Parent = panel

    local creatureList = Instance.new("ScrollingFrame")
    creatureList.Name = "CreatureList"
    creatureList.Position = UDim2.fromOffset(12, 58)
    creatureList.Size = UDim2.new(1, -24, 1, -70)
    creatureList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    creatureList.BackgroundTransparency = 1
    creatureList.BorderSizePixel = 0
    creatureList.CanvasSize = UDim2.fromOffset(0, 0)
    creatureList.ScrollBarThickness = 8
    creatureList.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Name = "Layout"
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = creatureList

    local emptyLabel = makeTextLabel("EmptyLabel", "No creatures owned yet.", 17)
    emptyLabel.Size = UDim2.new(1, -8, 0, 52)
    emptyLabel.Parent = creatureList

    local archiveButton = makeButton("ArchiveButton", "ARCHIVE")
    archiveButton.AnchorPoint = Vector2.new(1, 0)
    archiveButton.Position = UDim2.new(1, -16, 0, 12)
    archiveButton.Size = UDim2.fromOffset(132, 30)
    archiveButton.TextSize = 13
    archiveButton.Parent = panel

    local archiveList = Instance.new("ScrollingFrame")
    archiveList.Name = "ArchiveList"
    archiveList.Position = UDim2.fromOffset(12, 58)
    archiveList.Size = UDim2.new(1, -24, 1, -70)
    archiveList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    archiveList.BackgroundTransparency = 1
    archiveList.BorderSizePixel = 0
    archiveList.CanvasSize = UDim2.fromOffset(0, 0)
    archiveList.ScrollBarThickness = 8
    archiveList.Visible = false
    archiveList.Parent = panel

    local archiveLayout = Instance.new("UIListLayout")
    archiveLayout.Name = "Layout"
    archiveLayout.Padding = UDim.new(0, 6)
    archiveLayout.SortOrder = Enum.SortOrder.LayoutOrder
    archiveLayout.Parent = archiveList

    local archive: Archive = {
        List = archiveList,
        Button = archiveButton,
        Title = title,
        Entries = {},
        Progress = "",
    }

    openButton.Activated:Connect(function()
        panel.Visible = not panel.Visible
    end)

    archiveButton.Activated:Connect(function()
        local showArchive = not archiveList.Visible
        archiveList.Visible = showArchive
        creatureList.Visible = not showArchive
        title.Text = if showArchive then "FROZEN ARCHIVE  " .. archive.Progress else "CREATURES"
        archiveButton.Text = if showArchive then "CREATURES" else "ARCHIVE " .. archive.Progress
    end)

    return creatureList, archive
end

local function clearCreatureRows(creatureList: ScrollingFrame): ()
    for _, child in creatureList:GetChildren() do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function getDisplayName(creatureID: string): string
    local creature = CreatureConfig[creatureID]
    if creature and type(creature.DisplayName) == "string" then
        return creature.DisplayName
    end

    return creatureID
end

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

local function ensureArchiveIcon(viewport: ViewportFrame, creatureID: string): ()
    if viewport:FindFirstChildWhichIsA("Model") then
        return
    end

    local creatureVisuals = ReplicatedStorage:FindFirstChild(CREATURE_VISUALS_FOLDER_NAME)
    local source = creatureVisuals and creatureVisuals:FindFirstChild(creatureID)
    if not source or not source:IsA("Model") then
        return
    end

    local model = source:Clone()
    model.Parent = viewport

    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    local boundsCFrame, boundsSize = model:GetBoundingBox()
    local pivot = model:GetPivot()
    local direction = (pivot.LookVector + pivot.RightVector * 0.6 + Vector3.new(0, 0.35, 0)).Unit
    local distance = boundsSize.Magnitude * 0.5 / math.tan(math.rad(camera.FieldOfView * 0.5)) * 1.1
    camera.CFrame = CFrame.lookAt(boundsCFrame.Position + direction * distance, boundsCFrame.Position)
    camera.Parent = viewport
    viewport.CurrentCamera = camera
end

local function createArchiveRow(archiveList: ScrollingFrame, creatureID: string, layoutOrder: number): ArchiveEntry
    local row = Instance.new("Frame")
    row.Name = "ArchiveRow_" .. creatureID
    row.LayoutOrder = layoutOrder
    row.Size = UDim2.new(1, -8, 0, ARCHIVE_ROW_HEIGHT)
    row.BackgroundColor3 = Color3.fromRGB(32, 43, 55)
    row.BorderSizePixel = 0
    row.Parent = archiveList

    local icon = Instance.new("ViewportFrame")
    icon.Name = "Icon"
    icon.Position = UDim2.fromOffset(6, 6)
    icon.Size = UDim2.fromOffset(ARCHIVE_ROW_HEIGHT - 12, ARCHIVE_ROW_HEIGHT - 12)
    icon.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
    icon.BorderSizePixel = 0
    icon.Ambient = Color3.fromRGB(200, 200, 200)
    icon.LightColor = Color3.fromRGB(255, 255, 255)
    icon.Parent = row

    local nameLabel = makeTextLabel("CreatureName", UNDISCOVERED_TEXT, 17)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Position = UDim2.fromOffset(ARCHIVE_ROW_HEIGHT + 4, 8)
    nameLabel.Size = UDim2.new(1, -(ARCHIVE_ROW_HEIGHT + 12), 0, 24)
    nameLabel.Parent = row

    local rarityLabel = makeTextLabel("Rarity", "", 14)
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Position = UDim2.fromOffset(ARCHIVE_ROW_HEIGHT + 4, 34)
    rarityLabel.Size = UDim2.new(1, -(ARCHIVE_ROW_HEIGHT + 12), 0, 20)
    rarityLabel.Parent = row

    return {
        CreatureID = creatureID,
        Icon = icon,
        NameLabel = nameLabel,
        RarityLabel = rarityLabel,
    }
end

-- Undiscovered species stay a dark silhouette and "???"; discovery never reverses on the server.
local function updateArchive(archive: Archive, snapshot: any): ()
    if type(snapshot) ~= "table" or type(snapshot.DiscoveredCreatureIDs) ~= "table" then
        return
    end

    local discovered = {}
    for _, creatureID in snapshot.DiscoveredCreatureIDs do
        if type(creatureID) == "string" then
            discovered[creatureID] = true
        end
    end

    if #archive.Entries == 0 then
        for layoutOrder, creatureID in getArchiveOrder() do
            table.insert(archive.Entries, createArchiveRow(archive.List, creatureID, layoutOrder))
        end
    end

    local discoveredCount = 0
    for _, entry in archive.Entries do
        local creature = CreatureConfig[entry.CreatureID]
        local isDiscovered = discovered[entry.CreatureID] == true and creature ~= nil
        ensureArchiveIcon(entry.Icon, entry.CreatureID)

        if isDiscovered then
            discoveredCount += 1
            local rarityUI = RarityConfig[creature.Rarity] and RarityConfig[creature.Rarity].RarityUI
            entry.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            entry.NameLabel.Text = getDisplayName(entry.CreatureID)
            entry.RarityLabel.Text = string.upper(if rarityUI then rarityUI.DisplayName else creature.Rarity)
            entry.RarityLabel.TextColor3 = if rarityUI then rarityUI.Color else Color3.fromRGB(245, 248, 255)
        else
            entry.Icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
            entry.NameLabel.Text = UNDISCOVERED_TEXT
            entry.RarityLabel.Text = ""
        end
    end

    archive.Progress = string.format("%d / %d", discoveredCount, #archive.Entries)
    archive.Button.Text = if archive.List.Visible then "CREATURES" else "ARCHIVE " .. archive.Progress
    if archive.List.Visible then
        archive.Title.Text = "FROZEN ARCHIVE  " .. archive.Progress
    end
end

local function getAllocationText(record: any): string
    if record.AllocationState == "Pen" then
        return "PEN " .. record.PenSlotIndex
    end

    return string.upper(record.AllocationState)
end

-- Two taps to sell: the first arms a short confirmation so a valuable copy is never sold by accident.
local function addSellButton(row: Frame, record: any): ()
    local sellValue = record.SellValue
    if type(sellValue) ~= "number" or sellValue <= 0 or sellValue >= math.huge or sellValue % 1 ~= 0 then
        return
    end

    local sellText = "SELL  $" .. sellValue
    local sellButton = makeButton("SellButton", sellText)
    sellButton.Position = UDim2.fromOffset(12, 128)
    sellButton.Size = UDim2.new(1, -24, 0, 30)
    sellButton.BackgroundColor3 = SELL_BUTTON_COLOR
    sellButton.TextSize = 13
    sellButton.Parent = row

    local armedAt: number? = nil
    sellButton.Activated:Connect(function()
        local now = os.clock()
        if armedAt and now - armedAt <= SELL_CONFIRM_SECONDS then
            armedAt = nil
            gameplayRequest:FireServer("SellCreature", record.CreatureGUID)
            return
        end

        armedAt = now
        sellButton.Text = "TAP AGAIN TO SELL  $" .. sellValue
        sellButton.BackgroundColor3 = SELL_CONFIRM_COLOR
        task.delay(SELL_CONFIRM_SECONDS, function()
            if armedAt == now and sellButton.Parent then
                armedAt = nil
                sellButton.Text = sellText
                sellButton.BackgroundColor3 = SELL_BUTTON_COLOR
            end
        end)
    end)
end

local function createCreatureRow(
    creatureList: ScrollingFrame,
    record: any,
    layoutOrder: number,
    penHasCapacity: boolean
): ()
    local creatureGUID = record.CreatureGUID
    local row = Instance.new("Frame")
    row.Name = "CreatureRow_" .. layoutOrder
    row.LayoutOrder = layoutOrder
    row.Size = UDim2.new(1, -8, 0, 170)
    row.BackgroundColor3 = Color3.fromRGB(32, 43, 55)
    row.BorderSizePixel = 0
    row.Parent = creatureList

    local nameLabel = makeTextLabel("CreatureName", getDisplayName(record.CreatureID), 18)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Position = UDim2.fromOffset(12, 8)
    nameLabel.Size = UDim2.new(1, -24, 0, 26)
    nameLabel.Parent = row

    local statLabel = makeTextLabel(
        "CopyStats",
        string.format(
            "SIZE %.2fx  ·  SPEED %.1f  ·  PEN $%d/s",
            record.Scale,
            record.FinalWalkSpeed,
            record.FinalIncome
        ),
        14
    )
    statLabel.Position = UDim2.fromOffset(12, 35)
    statLabel.Size = UDim2.new(1, -24, 0, 24)
    statLabel.Parent = row

    local allocationLabel = makeTextLabel("AllocationState", getAllocationText(record), 14)
    allocationLabel.Font = Enum.Font.GothamBold
    allocationLabel.Position = UDim2.fromOffset(12, 58)
    allocationLabel.Size = UDim2.new(1, -24, 0, 20)
    allocationLabel.Parent = row

    if record.AllocationState == "Inventory" then
        local equipButton = makeButton("EquipButton", "EQUIP")
        equipButton.Position = UDim2.fromOffset(12, 86)
        equipButton.Size = UDim2.new(0.5, -16, 0, 34)
        equipButton.Activated:Connect(function()
            gameplayRequest:FireServer("EquipCreature", creatureGUID)
        end)
        equipButton.Parent = row

        if penHasCapacity then
            local placeButton = makeButton("PlaceInPenButton", "PLACE IN PEN")
            placeButton.AnchorPoint = Vector2.new(1, 0)
            placeButton.Position = UDim2.new(1, -12, 0, 86)
            placeButton.Size = UDim2.new(0.5, -16, 0, 34)
            placeButton.TextSize = 13
            placeButton.Activated:Connect(function()
                gameplayRequest:FireServer("PlaceInPen", creatureGUID)
            end)
            placeButton.Parent = row
        end
    elseif record.AllocationState == "Pen" then
        local equipButton = makeButton("EquipButton", "EQUIP")
        equipButton.Position = UDim2.fromOffset(12, 86)
        equipButton.Size = UDim2.new(0.5, -16, 0, 34)
        equipButton.Activated:Connect(function()
            gameplayRequest:FireServer("EquipCreature", creatureGUID)
        end)
        equipButton.Parent = row

        local removeButton = makeButton("RemoveFromPenButton", "REMOVE FROM PEN")
        removeButton.AnchorPoint = Vector2.new(1, 0)
        removeButton.Position = UDim2.new(1, -12, 0, 86)
        removeButton.Size = UDim2.new(0.5, -16, 0, 34)
        removeButton.TextSize = 12
        removeButton.Activated:Connect(function()
            gameplayRequest:FireServer("RemoveFromPen", creatureGUID)
        end)
        removeButton.Parent = row
    else
        local unequipButton = makeButton("UnequipButton", "UNEQUIP")
        unequipButton.Position = UDim2.fromOffset(12, 86)
        unequipButton.Size = UDim2.new(1, -24, 0, 34)
        unequipButton.Activated:Connect(function()
            gameplayRequest:FireServer("UnequipCreature", creatureGUID)
        end)
        unequipButton.Parent = row
    end

    addSellButton(row, record)
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

local function updateHud(creatureList: ScrollingFrame, snapshot: any): ()
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

    clearCreatureRows(creatureList)
    -- The server sends the unlocked capacity; without a valid value the Pen is treated as full.
    local penCapacity = snapshot.PenCapacity
    local isValidCapacity = type(penCapacity) == "number"
        and penCapacity % 1 == 0
        and penCapacity >= 1
        and penCapacity <= PenConfig.MaxSlots
    local penHasCapacity = isValidCapacity and occupiedPenSlots < penCapacity
    for layoutOrder, record in validRecords do
        createCreatureRow(creatureList, record, layoutOrder, penHasCapacity)
    end

    if #validRecords == 0 then
        local emptyLabel = makeTextLabel("EmptyLabel", "No creatures owned yet.", 17)
        emptyLabel.Size = UDim2.new(1, -8, 0, 52)
        emptyLabel.Parent = creatureList
    end
end

function CreatureInventoryController.Start(): ()
    if started then
        return
    end
    started = true

    local creatureList, archive = createHud()

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "CreatureStateUpdated" then
            updateHud(creatureList, data)
            updateArchive(archive, data)
        end
    end)
end

return CreatureInventoryController
