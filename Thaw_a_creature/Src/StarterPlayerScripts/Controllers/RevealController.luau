local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RarityConfig = require(shared:WaitForChild("RarityConfig"))
local CreatureConfig = require(shared:WaitForChild("CreatureConfig"))

local OwnBaseController = require(script.Parent.OwnBaseController)

local localPlayer = Players.LocalPlayer

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

local revealGui: ScreenGui? = nil
local revealLabel: TextLabel? = nil
local revealScale: UIScale? = nil
local revealStroke: UIStroke? = nil
local revealGeneration = 0

local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local TEMP_REVEAL_PREFIX = "TemporaryReveal_"

local ownThawVisuals: Folder? = nil
local lastSmashPosition: Vector3? = nil

local legendarySeq = 0
local impactInstances: { Instance } = {}
local fovBase: number? = nil
local fovTween: Tween? = nil

local function ensureRevealUI()
	if revealGui and revealGui.Parent then
		return
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "RarityRevealUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Name = "RevealLabel"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.22)
	label.Size = UDim2.fromScale(0.70, 0.14)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = true
	label.TextTransparency = 1
	label.Visible = false
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = label

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = label

	revealGui = gui
	revealLabel = label
	revealScale = scale
	revealStroke = stroke
end

local function cleanupImpact()
	for _, instance in impactInstances do
		if instance.Parent then
			instance:Destroy()
		end
	end
	table.clear(impactInstances)
end

local function restoreFov()
	if fovTween then
		fovTween:Cancel()
		fovTween = nil
	end
	if fovBase then
		local camera = workspace.CurrentCamera
		if camera then
			camera.FieldOfView = fovBase
		end
		fovBase = nil
	end
end

local function track(instance: Instance): Instance
	table.insert(impactInstances, instance)
	return instance
end

local function findRevealModel(creatureID: string, waitTime: number): Model?
	local deadline = os.clock() + waitTime
	repeat
		if ownThawVisuals then
			local found = ownThawVisuals:FindFirstChild(TEMP_REVEAL_PREFIX .. creatureID, true)
			if found and found:IsA("Model") and found:GetAttribute("IsTemporaryRevealPresentation") == true then
				return found
			end
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return nil
end

local function newEmitter(parent: Instance, color: Color3, speed: NumberRange, size: number, lifeScale: number): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Texture = SPARKLE_TEXTURE
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.6 * lifeScale, 1.1 * lifeScale)
	emitter.Speed = speed
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 3
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = parent
	return emitter
end

local function playLegendaryImpact(seq: number, creatureID: string, impact: any, goldColor: Color3)
	local iceColor = impact.IceColor or Color3.fromRGB(170, 225, 255)

	-- Origin: temporary reveal model, else cached smash position, else skip world effects.
	local model = findRevealModel(creatureID, impact.ModelWait or 0.5)
	if seq ~= legendarySeq then
		return
	end

	local origin: Vector3? = nil
	local groundY: number? = nil
	if model then
		local cf, size = model:GetBoundingBox()
		origin = cf.Position
		groundY = cf.Position.Y - size.Y / 2
	elseif lastSmashPosition then
		origin = lastSmashPosition
		groundY = lastSmashPosition.Y - 2
	end

	-- Subtle gold screen flash.
	if revealGui and revealGui.Parent then
		local flash = Instance.new("Frame")
		flash.Name = "LegendaryFlash"
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = goldColor
		flash.BackgroundTransparency = impact.FlashTransparency or 0.65
		flash.BorderSizePixel = 0
		flash.ZIndex = 0
		flash.Parent = revealGui
		track(flash)
		TweenService:Create(flash, TweenInfo.new(impact.FlashTime or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
	end

	-- One temporary impact sound (placeholder bundled asset).
	if type(impact.SoundId) == "string" and impact.SoundId ~= "" then
		local sound = Instance.new("Sound")
		sound.Name = "LegendaryImpactSound"
		sound.SoundId = impact.SoundId
		sound.Volume = impact.SoundVolume or 0.7
		sound.PlaybackSpeed = impact.SoundSpeed or 1
		sound.Parent = SoundService
		track(sound)
		sound:Play()
	end

	-- Brief FOV punch; never touches CameraType.
	local camera = workspace.CurrentCamera
	if camera then
		if fovTween then
			fovTween:Cancel()
			fovTween = nil
		end
		if not fovBase then
			fovBase = camera.FieldOfView
		end
		local base = fovBase :: number
		local outTime = impact.FovOutTime or 0.08
		local backTime = impact.FovBackTime or 0.4
		fovTween = TweenService:Create(camera, TweenInfo.new(outTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = base + (impact.FovPunch or 6),
		})
		fovTween:Play()
		task.delay(outTime, function()
			if seq ~= legendarySeq then
				return
			end
			local cam = workspace.CurrentCamera
			if not cam then
				fovBase = nil
				return
			end
			fovTween = TweenService:Create(cam, TweenInfo.new(backTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				FieldOfView = base,
			})
			fovTween:Play()
			task.delay(backTime + 0.05, function()
				if seq == legendarySeq then
					restoreFov()
				end
			end)
		end)
	end

	if model then
		local highlight = Instance.new("Highlight")
		highlight.Name = "LegendaryHighlight"
		highlight.Adornee = model
		highlight.FillColor = goldColor
		highlight.OutlineColor = iceColor
		highlight.FillTransparency = 0.55
		highlight.OutlineTransparency = 0
		highlight.Parent = model
		track(highlight)
		local hlTime = impact.HighlightTime or 0.8
		TweenService:Create(highlight, TweenInfo.new(hlTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			FillTransparency = 1,
			OutlineTransparency = 1,
		}):Play()
		task.delay(hlTime + 0.05, function()
			if highlight.Parent then
				highlight:Destroy()
			end
		end)
	end

	if not origin then
		return
	end

	-- Anchor part: one-shot particle burst + light pulse.
	local anchor = Instance.new("Part")
	anchor.Name = "LegendaryImpactAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(origin)
	anchor.Parent = workspace
	track(anchor)

	local burstSize = impact.BurstSize or 1.4
	local burstSpeed = impact.BurstSpeedScale or 1
	local lifeScale = impact.BurstLifetimeScale or 1
	local goldEmitter = newEmitter(anchor, goldColor, NumberRange.new(18 * burstSpeed, 34 * burstSpeed), burstSize, lifeScale)
	local iceEmitter = newEmitter(anchor, iceColor, NumberRange.new(10 * burstSpeed, 22 * burstSpeed), burstSize * 0.7, lifeScale)
	goldEmitter:Emit(impact.GoldBurstCount or 40)
	iceEmitter:Emit(impact.IceBurstCount or 24)

	local light = Instance.new("PointLight")
	light.Color = goldColor
	light.Brightness = 0
	light.Range = impact.LightRange or 22
	light.Shadows = false
	light.Parent = anchor
	TweenService:Create(light, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = impact.LightBrightness or 6,
	}):Play()
	task.delay(0.1, function()
		if light.Parent then
			TweenService:Create(light, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Brightness = 0,
			}):Play()
		end
	end)

	-- Expanding shockwave ring.
	local ring = Instance.new("Part")
	ring.Name = "LegendaryShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = goldColor
	ring.Transparency = 0.25
	ring.Size = Vector3.new(0.15, 1, 1)
	ring.CFrame = CFrame.new(origin.X, (groundY or origin.Y) + 0.3, origin.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	track(ring)
	local ringSize = impact.RingSize or 26
	TweenService:Create(ring, TweenInfo.new(impact.RingTime or 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.15, ringSize, ringSize),
		Transparency = 1,
	}):Play()
end

local function startLegendaryImpact(creatureID: string, impact: any, goldColor: Color3)
	legendarySeq += 1
	local seq = legendarySeq
	cleanupImpact()

	task.spawn(function()
		local ok, err = pcall(playLegendaryImpact, seq, creatureID, impact, goldColor)
		if not ok then
			warn(string.format("[RevealController] Legendary impact failed: %s", tostring(err)))
		end
	end)

	task.delay(impact.CleanupTime or 2.6, function()
		if seq == legendarySeq then
			cleanupImpact()
			restoreFov()
		end
	end)
end

local function showRarityReveal(creatureID: string, rarity: string)
	local rarityEntry = RarityConfig[rarity]
	if type(rarityEntry) ~= "table" then
		warn(string.format("[RevealController] Unknown rarity %s", rarity))
		return
	end

	local profileName = rarityEntry.RevealPresentationProfile
	local profileEntry = nil

	if type(profileName) == "string" then
		profileEntry = RarityConfig[profileName]
	end

	if type(profileEntry) ~= "table" then
		profileEntry = rarityEntry
	end

	local rarityUI = profileEntry.RarityUI
	if type(rarityUI) ~= "table" then
		rarityUI = {}
	end

	local creatureEntry = CreatureConfig[creatureID]
	local displayName = creatureID

	if type(creatureEntry) == "table"
		and type(creatureEntry.DisplayName) == "string"
		and creatureEntry.DisplayName ~= ""
	then
		displayName = creatureEntry.DisplayName
	end

	ensureRevealUI()

	if not revealLabel or not revealScale or not revealStroke then
		return
	end

	revealGeneration += 1
	local generation = revealGeneration

	revealLabel.Text = string.format(
		"%s\n%s",
		displayName,
		string.upper(rarityUI.DisplayName or rarity)
	)

	revealLabel.TextColor3 = rarityUI.Color or Color3.new(1, 1, 1)
	revealLabel.TextTransparency = 0
	revealStroke.Transparency = rarityUI.StrokeTransparency or 0.5

	revealScale.Scale = 0.85
	revealLabel.Visible = true

	TweenService:Create(
		revealScale,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Scale = rarityUI.PulseScale or 1,
		}
	):Play()

	local impact = profileEntry.RevealImpact
	local textHold = 1.15
	if type(impact) == "table" and type(impact.TextHold) == "number" then
		textHold = impact.TextHold
	end

	if rarity == "Legendary" and type(impact) == "table" then
		startLegendaryImpact(creatureID, impact, rarityUI.Color or Color3.fromRGB(255, 193, 69))
	end

	task.delay(textHold, function()
		if generation ~= revealGeneration then
			return
		end

		local textTween = TweenService:Create(
			revealLabel,
			TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				TextTransparency = 1,
			}
		)

		local strokeTween = TweenService:Create(
			revealStroke,
			TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = 1,
			}
		)

		textTween:Play()
		strokeTween:Play()

		task.delay(0.32, function()
			if generation == revealGeneration and revealLabel then
				revealLabel.Visible = false
			end
		end)
	end)
end

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

        lastSmashPosition = visualIce.Position

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

	local creatureID = firstValue
	local rarity = secondValue

	activeSessionID = nil
	activeThawID = nil

	showRarityReveal(creatureID, rarity)
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
        ownThawVisuals = thawVisuals

        for _, descendant in thawVisuals:GetDescendants() do
            connectReadyPrompt(descendant, thawVisuals)
        end

        thawVisuals.DescendantAdded:Connect(function(descendant)
            connectReadyPrompt(descendant, thawVisuals)
        end)
    end)
end

return RevealController
