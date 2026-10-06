local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))
local GameConfig = require(shared:WaitForChild("GameConfig"))

local CreatureInventoryController = {}

local HUD_NAME = "CreatureInventoryHud"
local started = false

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

local function createHud(): ScrollingFrame
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

    openButton.Activated:Connect(function()
        panel.Visible = not panel.Visible
    end)

    return creatureList
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

local function getAllocationText(record: any): string
    if record.AllocationState == "Pen" then
        return "PEN " .. record.PenSlotIndex
    end

    return string.upper(record.AllocationState)
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
    row.Size = UDim2.new(1, -8, 0, 132)
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
            and record.PenSlotIndex <= GameConfig.ActivePenCreatureSlots
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
    local penHasCapacity = occupiedPenSlots < GameConfig.ActivePenCreatureSlots
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

    local creatureList = createHud()

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "CreatureStateUpdated" then
            updateHud(creatureList, data)
        end
    end)
end

return CreatureInventoryController
