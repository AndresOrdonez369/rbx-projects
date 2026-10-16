local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CreatureConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CreatureConfig"))

local CreaturePortrait = require(script.Parent.CreaturePortrait)

local CreatureVitalityController = {}

-- Prefab: StarterGui.MainHud.RightRail.MountCard (authored in Studio).
local HUD_NAME = "MainHud"
local HIT_FLASH_COLOR = Color3.fromRGB(255, 120, 100)
local NORMAL_BACKGROUND_COLOR = Color3.fromRGB(255, 255, 255)
local NORMAL_BACKGROUND_TRANSPARENCY = 0.06
local NORMAL_FILL_COLOR = Color3.fromRGB(105, 205, 240)
local FROSTED_FILL_COLOR = Color3.fromRGB(190, 232, 255)

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local started = false
local flashRevision = 0
local portraitCreatureID: string? = nil

type Hud = {
    Panel: Frame,
    Portrait: ViewportFrame,
    NameLabel: TextLabel,
    Fill: Frame,
    ValueLabel: TextLabel,
    StateLabel: GuiObject,
}

local function bindHud(): Hud
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local panel = playerGui:WaitForChild(HUD_NAME):WaitForChild("RightRail"):WaitForChild("MountCard") :: Frame
    local bar = panel:WaitForChild("BarBackground")

    return {
        Panel = panel,
        Portrait = panel:WaitForChild("PortraitFrame"):WaitForChild("Portrait") :: ViewportFrame,
        NameLabel = panel:WaitForChild("CreatureName") :: TextLabel,
        Fill = bar:WaitForChild("Fill") :: Frame,
        ValueLabel = bar:WaitForChild("Value") :: TextLabel,
        StateLabel = panel:WaitForChild("StateTag") :: GuiObject,
    }
end

local function updateHud(hud: Hud, data: any): ()
    if type(data) ~= "table" then
        return
    end

    local creatureID = data.EquippedCreature
    if creatureID == nil then
        hud.Panel.Visible = false
        return
    end
    if type(creatureID) ~= "string" then
        return
    end

    local vitality = data.CreatureVitality
    local vitalityMax = data.CreatureVitalityMax
    local frosted = data.CreatureFrosted
    if type(vitality) ~= "number" or type(vitalityMax) ~= "number" or vitalityMax <= 0
        or type(frosted) ~= "boolean"
    then
        return
    end

    -- Retried on later updates until CreatureVisuals has replicated and the portrait actually fills.
    if creatureID ~= portraitCreatureID then
        local creature = CreatureConfig[creatureID]
        hud.NameLabel.Text = if creature and type(creature.DisplayName) == "string" then creature.DisplayName else creatureID
        if CreaturePortrait.Fill(hud.Portrait, creatureID) then
            portraitCreatureID = creatureID
        end
    end

    hud.Panel.Visible = true
    hud.Fill.Size = UDim2.fromScale(math.clamp(vitality / vitalityMax, 0, 1), 1)
    hud.Fill.BackgroundColor3 = if frosted then FROSTED_FILL_COLOR else NORMAL_FILL_COLOR
    hud.ValueLabel.Text = string.format("%d / %d", math.round(vitality), math.round(vitalityMax))
    hud.StateLabel.Visible = frosted
end

local function flashCreatureHit(panel: Frame): ()
    flashRevision += 1
    local revision = flashRevision
    panel.BackgroundColor3 = HIT_FLASH_COLOR
    panel.BackgroundTransparency = 0.05

    task.delay(0.12, function()
        if revision ~= flashRevision or not panel.Parent then
            return
        end

        TweenService:Create(
            panel,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundColor3 = NORMAL_BACKGROUND_COLOR,
                BackgroundTransparency = NORMAL_BACKGROUND_TRANSPARENCY,
            }
        ):Play()
    end)
end

function CreatureVitalityController.Start(): ()
    if started then
        return
    end
    started = true

    local hud = bindHud()

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "EquippedCreatureChanged" then
            updateHud(hud, data)
        elseif eventName == "SurvivalFeedback"
            and type(data) == "table"
            and data.Kind == "CreatureHit"
            and hud.Panel.Visible
        then
            flashCreatureHit(hud.Panel)
        end
    end)
end

return CreatureVitalityController
