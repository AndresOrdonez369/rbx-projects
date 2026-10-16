local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WarmthConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WarmthConfig"))

-- Bottom action row: the survival tool slot (replaces the default Roblox Backpack hotbar) and the Carried Ice panel.
-- Presentation and input only; the server still validates every swing and DropIce request.
local ActionBarController = {}

-- Prefab: StarterGui.MainHud.BottomCenter (ToolSlot, CarriedIcePanel), authored in Studio.
local HUD_NAME = "MainHud"
local TOOL_NAME = "SurvivalTool"
local TOOL_ATTRIBUTE = "IsSurvivalTool"
local ICE_INSTANCE_ID_ATTRIBUTE = "IceInstanceID"
local ICE_TYPE_ATTRIBUTE = "IceType"
local IS_SPECIAL_ATTRIBUTE = "IsSpecial"
local TOGGLE_TOOL_ACTION = "ToggleSurvivalTool"
local TOGGLE_TOOL_KEY = Enum.KeyCode.One
local EQUIPPED_RIM_COLOR = Color3.fromRGB(255, 204, 72)
local IDLE_RIM_COLOR = Color3.fromRGB(127, 219, 255)
local EQUIPPED_RIM_TRANSPARENCY = 0
local IDLE_RIM_TRANSPARENCY = 0.35
local RELEASE_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PRESSED_SCALE = 0.9
local PANEL_POP_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PANEL_POP_START = 0.8
-- DropIce is refused inside Home Camp (Grab never works there); mirror the server zone so DROP never fails silently.
local HOME_SAFE_ZONE_NAME = "HomeCampSafeZone"
local ZONE_CHECK_INTERVAL = 0.2
local DROP_DISABLED_COLOR = Color3.fromRGB(96, 110, 130)
local IN_CAMP_TEXT = "PLACE IT IN YOUR PEN"
local IN_CAMP_TEXT_COLOR = Color3.fromRGB(196, 238, 255)

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")

local started = false

type Hud = {
    ToolSlot: GuiButton,
    ToolRim: UIStroke,
    ToolPress: UIScale,
    ToolLock: GuiObject,
    ToolKeyHint: GuiObject,
    CarriedPanel: GuiObject,
    CarriedPop: UIScale,
    IceName: TextLabel,
    Drain: TextLabel,
    SpecialBadge: GuiObject,
    DropButton: GuiButton,
    DropFace: UIGradient,
    DropKeyHint: GuiObject,
}

local function bindHud(): Hud
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local row = playerGui:WaitForChild(HUD_NAME):WaitForChild("BottomCenter")
    local slot = row:WaitForChild("ToolSlot") :: GuiButton
    local panel = row:WaitForChild("CarriedIcePanel") :: GuiObject
    local dropButton = panel:WaitForChild("DropButton") :: GuiButton

    return {
        ToolSlot = slot,
        ToolRim = slot:WaitForChild("Rim") :: UIStroke,
        ToolPress = slot:WaitForChild("Press") :: UIScale,
        ToolLock = slot:WaitForChild("LockOverlay") :: GuiObject,
        ToolKeyHint = slot:WaitForChild("KeyHint") :: GuiObject,
        CarriedPanel = panel,
        CarriedPop = panel:WaitForChild("Pop") :: UIScale,
        IceName = panel:WaitForChild("IceName") :: TextLabel,
        Drain = panel:WaitForChild("Drain") :: TextLabel,
        SpecialBadge = panel:WaitForChild("SpecialBadge") :: GuiObject,
        DropButton = dropButton,
        DropFace = dropButton:WaitForChild("Face") :: UIGradient,
        DropKeyHint = dropButton:WaitForChild("KeyHint") :: GuiObject,
    }
end

local function isSurvivalTool(instance: Instance): boolean
    return instance:IsA("Tool") and instance.Name == TOOL_NAME and instance:GetAttribute(TOOL_ATTRIBUTE) == true
end

local function findTool(container: Instance?): Tool?
    if not container then
        return nil
    end
    for _, child in container:GetChildren() do
        if isSurvivalTool(child) then
            return child :: Tool
        end
    end
    return nil
end

local function getCarriedIce(): BasePart?
    local character = localPlayer.Character
    if not character then
        return nil
    end
    for _, child in character:GetChildren() do
        if child:IsA("BasePart") and child:GetAttribute(ICE_INSTANCE_ID_ATTRIBUTE) ~= nil then
            return child
        end
    end
    return nil
end

local function isInsideHomeCamp(): boolean
    local zone = Workspace:FindFirstChild(HOME_SAFE_ZONE_NAME)
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not zone or not zone:IsA("BasePart") or not root or not root:IsA("BasePart") then
        return false
    end
    local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
    local halfSize = zone.Size * 0.5
    return math.abs(localPosition.X) <= halfSize.X
        and math.abs(localPosition.Y) <= halfSize.Y
        and math.abs(localPosition.Z) <= halfSize.Z
end

local function formatMultiplier(value: number): string
    if value % 1 == 0 then
        return string.format("%d", value)
    end
    return string.format("%.1f", value)
end

local function pressFeedback(scale: UIScale): ()
    scale.Scale = PRESSED_SCALE
    TweenService:Create(scale, RELEASE_INFO, { Scale = 1 }):Play()
end

function ActionBarController.Start(): ()
    if started then
        return
    end
    started = true

    local hud = bindHud()
    local carriedIce: BasePart? = nil
    local inCamp = false
    local keysVisible = false
    local dropFaceColor = hud.DropFace.Color
    local drainTextColor = hud.Drain.TextColor3
    local disabledDropFace = ColorSequence.new(DROP_DISABLED_COLOR)

    -- The custom slot owns the hotbar; Roblox's Backpack GUI would duplicate it and overlap the HUD.
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

    local function refreshTool(): ()
        local equipped = findTool(localPlayer.Character) ~= nil
        local carrying = carriedIce ~= nil
        hud.ToolRim.Color = if equipped then EQUIPPED_RIM_COLOR else IDLE_RIM_COLOR
        hud.ToolRim.Transparency = if equipped then EQUIPPED_RIM_TRANSPARENCY else IDLE_RIM_TRANSPARENCY
        hud.ToolLock.Visible = carrying
    end

    local function refreshCarried(): ()
        local ice = getCarriedIce()
        local wasCarrying = carriedIce ~= nil
        carriedIce = ice

        if ice then
            local iceType = ice:GetAttribute(ICE_TYPE_ATTRIBUTE)
            hud.IceName.Text = string.upper(if type(iceType) == "string" then iceType .. " Ice" else "Ice")
            inCamp = isInsideHomeCamp()
            hud.Drain.Text = if inCamp
                then IN_CAMP_TEXT
                else string.format("WARMTH DRAIN ×%s", formatMultiplier(WarmthConfig.CarryDrainMultiplier))
            hud.Drain.TextColor3 = if inCamp then IN_CAMP_TEXT_COLOR else drainTextColor
            hud.DropFace.Color = if inCamp then disabledDropFace else dropFaceColor
            hud.DropKeyHint.Visible = keysVisible and not inCamp
            hud.SpecialBadge.Visible = ice:GetAttribute(IS_SPECIAL_ATTRIBUTE) == true
            hud.CarriedPanel.Visible = true
            if not wasCarrying then
                hud.CarriedPop.Scale = PANEL_POP_START
                TweenService:Create(hud.CarriedPop, PANEL_POP_INFO, { Scale = 1 }):Play()

                -- Carrier Commitment: the tool cannot be used while carrying, so it is put away on Grab.
                task.defer(function()
                    local character = localPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid and carriedIce and findTool(character) then
                        humanoid:UnequipTools()
                    end
                end)
            end
        else
            hud.CarriedPanel.Visible = false
        end

        refreshTool()
    end

    -- Carrier Commitment: no tool use while carrying, so the slot is locked instead of equipping.
    local function toggleTool(): ()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or carriedIce then
            return
        end

        pressFeedback(hud.ToolPress)
        if findTool(character) then
            humanoid:UnequipTools()
        else
            local tool = findTool(localPlayer:FindFirstChildOfClass("Backpack"))
            if tool then
                humanoid:EquipTool(tool)
            end
        end
    end

    hud.ToolSlot.Activated:Connect(toggleTool)
    ContextActionService:BindAction(TOGGLE_TOOL_ACTION, function(_actionName, inputState)
        if inputState == Enum.UserInputState.Begin then
            toggleTool()
        end
        return Enum.ContextActionResult.Sink
    end, false, TOGGLE_TOOL_KEY)

    hud.DropButton.Activated:Connect(function()
        if carriedIce and not inCamp then
            gameplayRequest:FireServer("DropIce")
        end
    end)

    local function refreshKeyHints(): ()
        keysVisible = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
        hud.ToolKeyHint.Visible = keysVisible
        hud.DropKeyHint.Visible = keysVisible and not inCamp
    end
    refreshKeyHints()
    UserInputService.LastInputTypeChanged:Connect(refreshKeyHints)

    -- While carrying, follow the player in and out of Home Camp so the DROP state stays truthful.
    local zoneCheckElapsed = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        if not carriedIce then
            return
        end
        zoneCheckElapsed += deltaTime
        if zoneCheckElapsed < ZONE_CHECK_INTERVAL then
            return
        end
        zoneCheckElapsed = 0
        if isInsideHomeCamp() ~= inCamp then
            refreshCarried()
        end
    end)

    local function watchCharacter(character: Model): ()
        character.ChildAdded:Connect(refreshCarried)
        character.ChildRemoved:Connect(refreshCarried)
        refreshCarried()
    end
    localPlayer.CharacterAdded:Connect(watchCharacter)
    if localPlayer.Character then
        watchCharacter(localPlayer.Character)
    end
end

return ActionBarController
