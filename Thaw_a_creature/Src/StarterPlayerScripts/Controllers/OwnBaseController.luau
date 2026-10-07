local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local OwnBaseController = {}

local BASES_FOLDER_NAME = "Bases"
local OWNER_USER_ID_ATTRIBUTE = "OwnerUserId"

local started = false
local basesFolder: Folder? = nil
local ownBase: Folder? = nil
local ownBaseFound = Instance.new("BindableEvent")

local function getBaseOf(instance: Instance): Instance?
    local folder = basesFolder
    if not folder then
        return nil
    end

    local current = instance
    while current and current.Parent ~= folder do
        current = current.Parent
    end

    return current
end

-- Server validation already rejects foreign-base requests; this only hides prompts a visitor cannot use.
local function suppressForeignPrompt(descendant: Instance): ()
    if not descendant:IsA("ProximityPrompt") or getBaseOf(descendant) == ownBase then
        return
    end

    descendant.Enabled = false
    descendant:GetPropertyChangedSignal("Enabled"):Connect(function()
        if descendant.Enabled then
            descendant.Enabled = false
        end
    end)
end

local function tryResolveOwnBase(): ()
    local folder = basesFolder
    if ownBase or not folder then
        return
    end

    for _, base in folder:GetChildren() do
        if base:IsA("Folder") and base:GetAttribute(OWNER_USER_ID_ATTRIBUTE) == Players.LocalPlayer.UserId then
            ownBase = base

            for _, descendant in folder:GetDescendants() do
                suppressForeignPrompt(descendant)
            end
            folder.DescendantAdded:Connect(suppressForeignPrompt)

            ownBaseFound:Fire(base)
            return
        end
    end
end

-- Yields until the server has assigned this player's base.
function OwnBaseController.WaitForOwnBase(): Folder
    local base = ownBase
    if base then
        return base
    end

    return ownBaseFound.Event:Wait()
end

function OwnBaseController.Start(): ()
    if started then
        return
    end
    started = true

    local folder = Workspace:WaitForChild(BASES_FOLDER_NAME)
    assert(folder:IsA("Folder"), string.format("Workspace.%s must be a Folder", BASES_FOLDER_NAME))
    basesFolder = folder

    local function watchBase(base: Instance): ()
        base:GetAttributeChangedSignal(OWNER_USER_ID_ATTRIBUTE):Connect(tryResolveOwnBase)
        tryResolveOwnBase()
    end

    for _, base in folder:GetChildren() do
        watchBase(base)
    end
    folder.ChildAdded:Connect(watchBase)
end

return OwnBaseController
