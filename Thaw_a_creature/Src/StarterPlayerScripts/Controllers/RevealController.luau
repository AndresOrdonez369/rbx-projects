local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OwnBaseController = require(script.Parent.OwnBaseController)

local RevealController = {}

local READY_PROMPT_NAME = "ReadyPrompt"
local THAW_VISUALS_FOLDER_NAME = "ThawVisuals"

local started = false
local connectedPrompts: { [ProximityPrompt]: boolean } = setmetatable({}, { __mode = "k" })

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")
assert(gameplayEvent:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayEvent must be a RemoteEvent")

local activeSessionID: string? = nil
local activeThawID: string? = nil

local function connectReadyPrompt(descendant: Instance, thawVisuals: Folder)
    if not descendant:IsA("ProximityPrompt") or descendant.Name ~= READY_PROMPT_NAME then
        return
    end

    if not descendant:IsDescendantOf(thawVisuals) or connectedPrompts[descendant] then
        return
    end
    connectedPrompts[descendant] = true

    descendant.Triggered:Connect(function()
        local visualIce = descendant.Parent
        if not visualIce or not visualIce:IsA("BasePart") then
            return
        end

        local thawID = visualIce:GetAttribute("ThawID")
        if type(thawID) ~= "string" or thawID == "" then
            return
        end

        if activeSessionID and activeThawID == thawID then
            gameplayRequest:FireServer("Crack", activeSessionID)
            return
        end

        gameplayRequest:FireServer("BeginReveal", thawID)
    end)
end

function RevealController.Start()
    if started then
        return
    end
    started = true

    gameplayEvent.OnClientEvent:Connect(function(action, firstValue, secondValue)
        if action == "CreatureRevealed" then
            if type(firstValue) ~= "string"
                or firstValue == ""
                or type(secondValue) ~= "string"
                or secondValue == ""
            then
                return
            end

            activeSessionID = nil
            activeThawID = nil
            return
        end

        if action ~= "RevealSessionStarted"
            or type(firstValue) ~= "string"
            or firstValue == ""
            or type(secondValue) ~= "string"
            or secondValue == ""
        then
            return
        end

        activeSessionID = firstValue
        activeThawID = secondValue
    end)

    task.spawn(function()
        local thawVisuals = OwnBaseController.WaitForOwnBase():WaitForChild(THAW_VISUALS_FOLDER_NAME)
        assert(thawVisuals:IsA("Folder"), string.format("%s must be a Folder", thawVisuals:GetFullName()))

        for _, descendant in thawVisuals:GetDescendants() do
            connectReadyPrompt(descendant, thawVisuals)
        end

        thawVisuals.DescendantAdded:Connect(function(descendant)
            connectReadyPrompt(descendant, thawVisuals)
        end)
    end)
end

return RevealController
