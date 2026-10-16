local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CashController = {}

-- Prefab: StarterGui.MainHud.BottomLeft.CashPill (authored in Studio).
local HUD_NAME = "MainHud"
local GAIN_PUNCH_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GAIN_PUNCH_SCALE = 1.08
local started = false
local lastCash: number? = nil

type Hud = {
    Label: TextLabel,
    Pill: GuiObject,
}

local function bindHud(): Hud
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local pill = playerGui:WaitForChild(HUD_NAME):WaitForChild("BottomLeft"):WaitForChild("CashPill") :: GuiObject

    return {
        Label = pill:WaitForChild("CashLabel") :: TextLabel,
        Pill = pill,
    }
end

local function formatCash(cash: number): string
    local digits = string.format("%d", cash)
    local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if formatted:sub(1, 1) == "," then
        formatted = formatted:sub(2)
    end

    return "$" .. formatted
end

local function punch(pill: GuiObject): ()
    local scale = pill:FindFirstChild("Punch")
    if not scale or not scale:IsA("UIScale") then
        return
    end

    scale.Scale = GAIN_PUNCH_SCALE
    TweenService:Create(scale, GAIN_PUNCH_INFO, { Scale = 1 }):Play()
end

local function updateHud(hud: Hud, data: any): ()
    if type(data) ~= "table" then
        return
    end

    local cash = data.Cash
    if type(cash) ~= "number"
        or cash < 0
        or cash >= math.huge
        or cash % 1 ~= 0
    then
        return
    end

    hud.Label.Text = formatCash(cash)
    if lastCash ~= nil and cash > lastCash then
        punch(hud.Pill)
    end
    lastCash = cash
end

function CashController.Start(): ()
    if started then
        return
    end
    started = true

    local hud = bindHud()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplayEvent = remotes:WaitForChild("GameplayEvent")

    assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

    gameplayEvent.OnClientEvent:Connect(function(eventName, data)
        if eventName == "CashUpdated" then
            updateHud(hud, data)
        end
    end)
end

return CashController
