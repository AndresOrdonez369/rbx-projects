-- Direct Ice deposit (F-D15-T05C1.2). While the local player carries Ice near their own Pen, the Pen floor simply is a
-- placement surface: desktop shows a subtle ghost of the exact carried Ice under the pointer (snapped to the nearest
-- valid spot) and ONE left click places it; touch places with ONE tap inside the Pen. No prompt, no mode, no panel,
-- no confirm: walking away, dropping or losing the Ice just removes the ghost.
-- Client input + preview only. The server validates and finalizes every placement (IceService.TryDepositCarriedIce ->
-- ThawService.ValidatePlacement, same rules from Shared.ThawPlacement). The ghost is local, non-collidable,
-- non-queryable and non-touchable, shows only the exact footprint (no silhouette, nothing hidden) and has no authority.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(shared:WaitForChild("GameConfig"))
local PenConfig = require(shared:WaitForChild("PenConfig"))
local ThawPlacement = require(shared:WaitForChild("ThawPlacement"))

local OwnBaseController = require(script.Parent.OwnBaseController)

local ThawPlacementController = {}

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameplayRequest = remotes:WaitForChild("GameplayRequest")
local gameplayEvent = remotes:WaitForChild("GameplayEvent")

local RESULT_EVENT = "ThawPlacementResult"
local ICE_INSTANCE_ID_ATTRIBUTE = "IceInstanceID"
local PEN_LEVEL_ATTRIBUTE = "PenLevel"
local PLAYER_FOLDER_PREFIX = "Player_"
-- Mirrors the server's own-Pen interaction distance (root -> PenFloor), kept slightly inside it.
local ELIGIBLE_DISTANCE = GameConfig.DepositIceMaxDistance - 0.5
local SURFACE_TOLERANCE = 1 -- a click / tap counts only when it lands on the own Pen floor (+ this margin)
local SNAP_RADIUS = 10 -- the nearest valid spot is searched this far around the pointer (clears the gate strip)
local SNAP = 0.25
local PENDING_TIMEOUT = 3
local FLASH_SECONDS = 1.2
local GHOST_COLOR = Color3.fromRGB(205, 236, 255)
local INVALID_COLOR = Color3.fromRGB(255, 135, 135)
local GHOST_TRANSPARENCY = 0.72
local SUGGEST_TRANSPARENCY = 0.84 -- suggested spot while the pointer is not over the Pen (and on touch)
local REASON_TEXT = {
    OutsidePen = "Keep the Ice inside your Pen",
    GateArea = "Keep the gate clear",
    Overlap = "Too close to another Ice",
    TooFar = "Move closer to that spot",
    StaleIce = "You're no longer carrying that Ice",
    Rejected = "Can't place there",
}

local started = false
local ownBase: Instance? = nil
local lastInput = "Mouse"
local pending = false
local pendingUntil = 0
local pendingX, pendingZ = 0, 0
local flashUntil = 0
local flashText = ""
local flashX, flashZ = 0, 0
local ghost: Part? = nil
local outline: SelectionBox? = nil
local hint: TextLabel? = nil
local cacheKey: string? = nil
local cacheX, cacheZ, cacheAuto = 0, 0, false

local function findCarriedIce(): BasePart?
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

-- Everything needed for one frame / one input, or nil when depositing is not possible right now.
local function getContext()
    local base = ownBase
    local ice = findCarriedIce()
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local pen = base and base:FindFirstChild("Pen")
    local origin = pen and pen:FindFirstChild("PenOrigin")
    local floor = pen and pen:FindFirstChild("PenFloor")
    if not ice or not root or not root:IsA("BasePart") or not origin or not origin:IsA("BasePart")
        or not floor or not floor:IsA("BasePart")
        or (root.Position - floor.Position).Magnitude > ELIGIBLE_DISTANCE
    then
        return nil
    end
    local level = base:GetAttribute(PEN_LEVEL_ATTRIBUTE)
    return {
        Base = base,
        Pen = pen,
        Ice = ice,
        IceID = ice:GetAttribute(ICE_INSTANCE_ID_ATTRIBUTE),
        Level = level,
        Depth = PenConfig.Levels[if PenConfig.IsValidLevel(level) then level else 1].Depth,
        Origin = origin.CFrame,
        FloorY = origin.Position.Y,
        HalfX = ice.Size.X / 2,
        HalfZ = ice.Size.Z / 2,
    }
end

-- Own thawing Ice as authoritative footprints (positions/sizes replicated from the server visuals).
local function getOccupied(ctx): { ThawPlacement.Box }
    local occupied = {}
    local thawVisuals = ctx.Base:FindFirstChild("ThawVisuals")
    local folder = thawVisuals and thawVisuals:FindFirstChild(PLAYER_FOLDER_PREFIX .. localPlayer.UserId)
    if folder then
        for _, ice in folder:GetChildren() do
            if ice:IsA("BasePart") then
                local p = ctx.Origin:PointToObjectSpace(ice.Position)
                local halfX, halfZ = ice.Size.X / 2, ice.Size.Z / 2
                table.insert(occupied, {
                    X = p.X,
                    Z = p.Z,
                    HalfX = halfX,
                    HalfZ = halfZ,
                    Oversize = ThawPlacement.IsOversize(ctx.Level, halfX, halfZ),
                })
            end
        end
    end
    return occupied
end

-- Ray -> Pen-local X/Z on the Pen floor plane (no physics raycast: creatures, cards and Ice never block the floor).
local function rayToPen(ctx, ray: Ray): (number?, number?)
    if ray.Direction.Y > -1e-4 then
        return nil, nil
    end
    local t = (ctx.FloorY - ray.Origin.Y) / ray.Direction.Y
    if t < 0 then
        return nil, nil
    end
    local p = ctx.Origin:PointToObjectSpace(ray.Origin + ray.Direction * t)
    return p.X, p.Z
end

-- Only points on the own Pen floor are placement targets (never the apron, banner, Hearth or the outside world).
local function onPenSurface(ctx, x: number, z: number): boolean
    local half = PenConfig.Width / 2 + SURFACE_TOLERANCE
    return math.abs(x) <= half and z >= -SURFACE_TOLERANCE and z <= ctx.Depth + SURFACE_TOLERANCE
end

-- Spot for a click at the pointer (cached while the pointer, footprint and Ice layout are unchanged): the nearest valid
-- spot around the pointer, else the first valid spot anywhere in the Pen, else (Pen full for this footprint) the
-- server's own deterministic least-overlap packing spot, sent as an Auto request. Thawing is unlimited, so a deposit
-- never fails for lack of room (Technical Spec §31) and the carrier is never stuck in Carrier Commitment.
local function resolve(ctx, x: number, z: number): (number, number, boolean)
    local occupied = getOccupied(ctx)
    local parts = { tostring(ctx.Level), string.format("%.2f,%.2f", ctx.HalfX, ctx.HalfZ) }
    table.insert(parts, string.format("%.1f,%.1f", math.round(x / SNAP) * SNAP, math.round(z / SNAP) * SNAP))
    for _, box in occupied do
        table.insert(parts, string.format("%.1f,%.1f,%.1f", box.X, box.Z, box.HalfX))
    end
    local key = table.concat(parts, "|")
    if key ~= cacheKey then
        cacheKey = key
        local nearX, nearZ = ThawPlacement.FindNearest(ctx.Level, x, z, ctx.HalfX, ctx.HalfZ, occupied, SNAP_RADIUS)
        if nearX and nearZ then
            cacheX, cacheZ, cacheAuto = nearX, nearZ, false
        else
            local fallbackX, fallbackZ, fitsCleanly = ThawPlacement.FindFallback(ctx.Level, ctx.HalfX, ctx.HalfZ, occupied)
            cacheX, cacheZ, cacheAuto = fallbackX, fallbackZ, not fitsCleanly
        end
    end
    return cacheX, cacheZ, cacheAuto
end

local function hideGhost()
    if ghost then
        ghost:Destroy()
        ghost, outline, hint = nil, nil, nil
    end
end

local function ensureGhost(size: Vector3): Part
    if ghost and ghost.Size == size then
        return ghost
    end
    hideGhost()
    local part = Instance.new("Part")
    part.Name = "ThawPlacementGhost"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Material = Enum.Material.SmoothPlastic
    part.Size = size
    local box = Instance.new("SelectionBox")
    box.LineThickness = 0.04
    box.SurfaceTransparency = 1
    box.Transparency = 0.45
    box.Adornee = part
    box.Parent = part
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Hint"
    billboard.Size = UDim2.fromOffset(220, 24)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 1.2, 0)
    billboard.LightInfluence = 0
    billboard.MaxDistance = 90
    billboard.Parent = part
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 15
    text.TextColor3 = Color3.fromRGB(240, 248, 255)
    text.TextStrokeTransparency = 0.45
    text.TextTransparency = 0.1
    text.Parent = billboard
    part.Parent = Workspace.CurrentCamera
    ghost, outline, hint = part, box, text
    return part
end

local function showGhost(ctx, x: number, z: number, color: Color3, transparency: number, text: string)
    local part = ensureGhost(ctx.Ice.Size)
    part.CFrame = ctx.Origin * CFrame.new(x, part.Size.Y / 2 + 0.05, z)
    part.Color = color
    part.Transparency = transparency
    if outline then
        outline.Color3 = color
    end
    if hint then
        hint.Text = text
    end
end

local function flash(x: number, z: number, text: string)
    flashUntil = os.clock() + FLASH_SECONDS
    flashText = text
    flashX, flashZ = x, z
end

-- One intentional click / tap on the own Pen floor = one placement request. Anything else is ignored.
local function tryPlace(ray: Ray)
    local ctx = getContext()
    if not ctx or pending then
        return
    end
    local rawX, rawZ = rayToPen(ctx, ray)
    if not rawX or not onPenSurface(ctx, rawX, rawZ) then
        return
    end
    local x, z, auto = resolve(ctx, rawX, rawZ)
    pending = true
    pendingUntil = os.clock() + PENDING_TIMEOUT
    pendingX, pendingZ = x, z
    flashUntil = 0
    local request = if auto
        then { IceInstanceID = ctx.IceID, Auto = true }
        else { IceInstanceID = ctx.IceID, X = x, Z = z }
    gameplayRequest:FireServer("DepositCarriedIce", ctx.Pen, request)
end

local function pointerRay(): Ray?
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end
    if lastInput == "Gamepad" then
        local size = camera.ViewportSize
        return camera:ViewportPointToRay(size.X / 2, size.Y / 2)
    end
    local location = UserInputService:GetMouseLocation()
    return camera:ViewportPointToRay(location.X, location.Y)
end

local function step()
    local ctx = getContext()
    if not ctx then
        pending = false
        flashUntil = 0
        hideGhost()
        return
    end
    local now = os.clock()
    if pending and now > pendingUntil then
        pending = false
    end
    if pending then
        showGhost(ctx, pendingX, pendingZ, GHOST_COLOR, GHOST_TRANSPARENCY, "")
        return
    end
    if now < flashUntil then
        showGhost(ctx, flashX, flashZ, INVALID_COLOR, GHOST_TRANSPARENCY, flashText)
        return
    end
    local touch = lastInput == "Touch"
    if not touch then
        local ray = pointerRay()
        local rawX, rawZ
        if ray then
            rawX, rawZ = rayToPen(ctx, ray)
        end
        if rawX and onPenSurface(ctx, rawX, rawZ) then
            local x, z = resolve(ctx, rawX, rawZ)
            showGhost(ctx, x, z, GHOST_COLOR, GHOST_TRANSPARENCY, if lastInput == "Gamepad" then "R2 TO PLACE" else "CLICK TO PLACE")
            return
        end
    end
    -- Pointer off the Pen (or touch, which has no hover): a faint suggested spot so the surface is discoverable.
    local x, z = resolve(ctx, 0, ctx.Depth * 0.35)
    showGhost(ctx, x, z, GHOST_COLOR, SUGGEST_TRANSPARENCY, if touch then "TAP YOUR PEN TO PLACE" else "CLICK YOUR PEN TO PLACE")
end

local function onResult(eventName: any, data: any)
    if eventName ~= RESULT_EVENT or type(data) ~= "table" then
        return
    end
    pending = false
    if data.Accepted ~= true then
        flash(pendingX, pendingZ, REASON_TEXT[data.Reason] or REASON_TEXT.Rejected)
    end
end

function ThawPlacementController.Start(): ()
    if started then
        return
    end
    started = true

    task.spawn(function()
        ownBase = OwnBaseController.WaitForOwnBase()
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.Touch then
            lastInput = "Touch"
        elseif inputType == Enum.UserInputType.MouseButton1 then
            lastInput = "Mouse"
            -- GUI buttons, prompts, the banner and cards set processed: only clicks on the world can deposit.
            if not processed then
                local ray = pointerRay()
                if ray then
                    tryPlace(ray)
                end
            end
        elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
            lastInput = "Gamepad"
            if not processed then
                local ray = pointerRay()
                if ray then
                    tryPlace(ray)
                end
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            lastInput = "Mouse"
        elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2 then
            lastInput = "Gamepad"
        end
    end)
    -- One tap in the world (never a UI tap, drag or pinch) = one placement attempt.
    UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean)
        lastInput = "Touch"
        local camera = Workspace.CurrentCamera
        if processedByUI or not camera then
            return
        end
        tryPlace(camera:ScreenPointToRay(position.X, position.Y))
    end)
    gameplayEvent.OnClientEvent:Connect(onResult)
    RunService.RenderStepped:Connect(step)
end

return ThawPlacementController
