local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local IceController = {}

local ACTIVE_ICE_FOLDER_NAME = "ActiveIce"
local DEPOSIT_PROMPT_NAME = "DepositPrompt"
local GRAB_PROMPT_NAME = "GrabPrompt"

local started = false
local connectedPrompts: { [ProximityPrompt]: boolean } = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")

assert(gameplayRequest:IsA("RemoteEvent"), "ReplicatedStorage.Remotes.GameplayRequest must be a RemoteEvent")

local function connectGrabPrompt(descendant: Instance)
    if not descendant:IsA("ProximityPrompt") or descendant.Name ~= GRAB_PROMPT_NAME then
        return
    end

    if connectedPrompts[descendant] then
        return
    end
    connectedPrompts[descendant] = true

    descendant.Triggered:Connect(function()
        local visualIce = descendant.Parent
        if not visualIce or not visualIce:IsA("BasePart") then
            return
        end

        local iceInstanceID = visualIce:GetAttribute("IceInstanceID")
        if type(iceInstanceID) ~= "string" then
            return
        end

        gameplayRequest:FireServer("GrabIce", iceInstanceID)
    end)
end


local function connectDepositPrompt(descendant: Instance, pen: Model)
    if not descendant:IsA("ProximityPrompt") or descendant.Name ~= DEPOSIT_PROMPT_NAME then
        return
    end

    if not descendant:IsDescendantOf(pen) or connectedPrompts[descendant] then
        return
    end
    connectedPrompts[descendant] = true

    descendant.Triggered:Connect(function()
        gameplayRequest:FireServer("DepositCarriedIce", pen)
    end)
end

function IceController.Start()
    if started then
        return
    end
    started = true

    local activeIceFolder = Workspace:WaitForChild(ACTIVE_ICE_FOLDER_NAME)
    local prototypeBase = Workspace:WaitForChild("PrototypeBase")
    local pen = prototypeBase:WaitForChild("Pen")

    assert(pen:IsA("Model"), "Workspace.PrototypeBase.Pen must be a Model")

    for _, descendant in activeIceFolder:GetDescendants() do
        connectGrabPrompt(descendant)
    end

    for _, descendant in pen:GetDescendants() do
        connectDepositPrompt(descendant, pen)
    end

    activeIceFolder.DescendantAdded:Connect(connectGrabPrompt)
    pen.DescendantAdded:Connect(function(descendant)
        connectDepositPrompt(descendant, pen)
    end)
end

return IceController
