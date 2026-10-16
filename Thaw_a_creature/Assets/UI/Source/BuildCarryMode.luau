-- Edit-time: carry-mode ("bring it home") prefabs, driven by Controllers.CarryModeController.
--   StarterGui.CarryModeFx          frost edges, wind streaks, BRING IT HOME banner, home compass, SAFE! arrival
--   MainHud.TopCenter.CarryInfo     drain chip + time-left estimate (+ Great Frost chip) under the Warmth panel
--   MainHud.TopCenter.WarmthPanel   Emphasis UIScale (the Warmth bar grows while carrying)
--   ReplicatedStorage.UITemplates.PenBeacon   warm light pillar over the own Pen (cloned locally while carrying)
local L = require(game.ServerStorage.__UIAuthoring:Clone())
local C, I = L.C, L.Img
local SG = game:GetService("StarterGui")
local T = game.ReplicatedStorage.UITemplates
local hud = SG.MainHud
local top = hud.TopCenter

local WARM = Color3.fromRGB(255, 176, 80)
local WARM_DEEP = Color3.fromRGB(255, 110, 40)
local DANGER = C.Danger

-- ===== StarterGui.CarryModeFx =====
L.replace(SG, "CarryModeFx")
local fx = L.screen("CarryModeFx", 8, { IgnoreGuiInset = true })

L.new("ImageLabel", {
    Name = "FrostEdges",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = I.FrostVignette,
    ScaleType = Enum.ScaleType.Stretch,
    ImageColor3 = Color3.fromRGB(215, 240, 255),
    ImageTransparency = 1,
    ZIndex = 1,
    Parent = fx,
})

L.new("Frame", { Name = "WarmFlash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WARM, BackgroundTransparency = 1, ZIndex = 1, Parent = fx })

local wind = L.new("Frame", { Name = "Wind", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = fx })
for index = 1, 10 do
    L.new("Frame", {
        Name = "Streak" .. index,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(110, 2),
        BackgroundColor3 = Color3.fromRGB(235, 248, 255),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = wind,
    }, {
        L.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }),
    })
end

-- Banner: BRING IT HOME
local banner = L.new("Frame", { Name = "Banner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(640, 110), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = fx })
L.hudScale(banner)
local bannerBody = L.new("Frame", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = banner }, { L.new("UIScale", { Name = "Pop" }) })
L.text({ Name = "Title", Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 66), Text = "BRING IT HOME", TextSize = 60, TextColor3 = C.White, OutlineThickness = 4, ZIndex = 6, Parent = bannerBody }, {
    L.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 238, 255)) }),
})
L.text({ Name = "Sub", Position = UDim2.fromOffset(0, 68), Size = UDim2.new(1, 0, 0, 30), FontFace = L.BodyHeavy, Text = "GET THE ICE TO YOUR PEN BEFORE THE COLD GETS YOU", TextSize = 20, TextColor3 = C.IceSoft, OutlineThickness = 2, ZIndex = 6, Parent = bannerBody })

-- Home compass: rotating arrow badge + distance pill, placed on the screen edge by code
local compass = L.new("Frame", { Name = "Compass", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(150, 120), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = fx })
L.hudScale(compass)
local badge = L.new("Frame", { Name = "Badge", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(78, 78), BackgroundColor3 = C.White, ZIndex = 5, Parent = compass }, {
    L.round(),
    L.grad(C.PanelTop, C.PanelBottom, 90, "BadgeGradient"),
    L.stroke(WARM, 3, 0, "Ring"),
    L.new("UIScale", { Name = "Pulse" }),
})
L.icon(I.HomeArrow, { Name = "Arrow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(52, 52), ZIndex = 6, Parent = badge })
L.text({ Name = "Distance", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = C.Panel, Text = "PEN · 142m", TextSize = 20, TextColor3 = WARM, OutlineThickness = 2, ZIndex = 6, Parent = compass }, {
    L.round(), L.stroke(WARM, 2, 0.2, "Rim"), L.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
})

-- Arrival: SAFE! / CLOSE ONE!
local arrival = L.new("Frame", { Name = "Arrival", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(720, 240), BackgroundTransparency = 1, Visible = false, ZIndex = 7, Parent = fx })
L.hudScale(arrival)
local arrivalBody = L.new("Frame", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 7, Parent = arrival }, { L.new("UIScale", { Name = "Pop" }) })
L.icon(I.Rays, { Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(340, 340), ImageColor3 = WARM, ImageTransparency = 0.25, ZIndex = 7, Parent = arrivalBody })
L.icon(I.Glow, { Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(620, 220), ScaleType = Enum.ScaleType.Stretch, ImageColor3 = WARM, ImageTransparency = 0.2, ZIndex = 8, Parent = arrivalBody })
L.text({ Name = "Title", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.new(1, -20, 0, 110), Text = "SAFE!", TextSize = 100, TextColor3 = C.White, OutlineColor = Color3.fromRGB(70, 28, 6), OutlineThickness = 5, ZIndex = 9, Parent = arrivalBody }, {
    L.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 180), WARM_DEEP) }),
})
L.text({ Name = "Sub", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.68), Size = UDim2.new(1, -20, 0, 32), FontFace = L.BodyHeavy, Text = "THE ICE MADE IT HOME", TextSize = 24, TextColor3 = Color3.fromRGB(255, 226, 170), OutlineColor = Color3.fromRGB(70, 28, 6), OutlineThickness = 2, ZIndex = 9, Parent = arrivalBody })

fx.Parent = SG

-- ===== MainHud: Warmth emphasis + carry info row =====
local warmth = top.WarmthPanel
L.replace(warmth, "Emphasis")
L.new("UIScale", { Name = "Emphasis", Parent = warmth })

L.replace(top, "CarryInfo")
local info = L.new("Frame", {
    Name = "CarryInfo",
    Size = UDim2.fromOffset(0, 30),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = C.White,
    BackgroundTransparency = 0.06,
    LayoutOrder = 2,
    Visible = false,
    Parent = top,
}, {
    L.round(),
    L.grad(C.PanelTop, C.PanelBottom, 90, "PanelGradient"),
    L.stroke(WARM_DEEP, 2, 0.15, "Rim"),
    L.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 12) }),
    L.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
})
L.text({ Name = "DrainChip", Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = DANGER, Text = "×2", TextSize = 16, OutlineThickness = 1.5, LayoutOrder = 1, Parent = info }, {
    L.round(), L.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
})
L.text({ Name = "Eta", Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Text = "~0:42 OF WARMTH LEFT", TextSize = 18, OutlineThickness = 2, LayoutOrder = 2, Parent = info })
L.text({ Name = "FrostChip", Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(70, 156, 255), FontFace = L.BodyHeavy, Text = "GREAT FROST IN 0:24", TextSize = 14, OutlineThickness = 1.5, Visible = false, LayoutOrder = 3, Parent = info }, {
    L.round(), L.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
})

-- ===== UITemplates.PenBeacon =====
L.replace(T, "PenBeacon")
local beacon = Instance.new("Model")
beacon.Name = "PenBeacon"
local height = 140
local pillar = L.new("Part", {
    Name = "Pillar",
    Shape = Enum.PartType.Cylinder,
    Size = Vector3.new(height, 3, 3),
    CFrame = CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
    Material = Enum.Material.Neon,
    Color = WARM,
    Transparency = 0.55,
    Anchored = true,
    CanCollide = false,
    CanQuery = false,
    CanTouch = false,
    CastShadow = false,
    Parent = beacon,
})
L.new("PointLight", { Color = WARM, Range = 24, Brightness = 2, Parent = pillar })
local tag = L.new("BillboardGui", { Name = "Tag", AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 3000, Size = UDim2.fromOffset(170, 40), StudsOffsetWorldSpace = Vector3.new(0, height * 0.2, 0), Parent = pillar })
L.text({ Name = "Label", Size = UDim2.fromScale(1, 1), Text = "YOUR PEN", TextSize = 26, TextColor3 = Color3.fromRGB(255, 226, 170), OutlineColor = Color3.fromRGB(70, 28, 6), OutlineThickness = 3, Parent = tag })
beacon.WorldPivot = CFrame.new(0, 0, 0)
beacon.Parent = T

return "carry mode prefabs built"
