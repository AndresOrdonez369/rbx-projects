local L = require(game.ServerStorage.__UIAuthoring:Clone())
local C, I = L.C, L.Img
local SG = game:GetService("StarterGui")
local T = game.ReplicatedStorage.UITemplates

-- ===== RarityRevealUI =====
L.replace(SG, "RarityRevealUI")
local rv = L.screen("RarityRevealUI", 50, { IgnoreGuiInset = true })
L.new("Frame", { Name = "LegendaryFlash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Gold, BackgroundTransparency = 1, ZIndex = 0, Parent = rv })
local card = L.new("CanvasGroup", { Name = "RevealCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.24), Size = UDim2.fromOffset(620, 260), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 2, Parent = rv })
L.hudScale(card)
L.new("UIScale", { Name = "Pop", Parent = card })
L.icon(I.Rays, { Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(330, 330), ImageTransparency = 0.25, ZIndex = 2, Parent = card })
L.icon(I.Glow, { Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(560, 220), ScaleType = Enum.ScaleType.Stretch, ImageTransparency = 0.2, ZIndex = 3, Parent = card })
L.text({ Name = "CreatureName", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.new(1, -20, 0, 90), Text = "Penguin", TextSize = 76, TextColor3 = C.White, OutlineThickness = 5, ZIndex = 5, Parent = card }, {
    L.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 235, 255)) }),
})
L.text({ Name = "Rarity", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.64), Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(210, 215, 225), Text = "COMMON", TextSize = 28, TextColor3 = C.Outline, NoOutline = true, ZIndex = 6, Parent = card }, {
    L.round(), L.stroke(C.Outline, 3, 0), L.new("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22) }),
})
rv.Parent = SG

-- ===== PenUpgradeToast =====
L.replace(SG, "PenUpgradeToast")
local pt = L.screen("PenUpgradeToast", 30, { IgnoreGuiInset = true, Enabled = false })
local toast = L.new("Frame", { Name = "Toast", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.24), Size = UDim2.fromOffset(520, 130), BackgroundTransparency = 1, Parent = pt })
L.hudScale(toast)
L.new("UIScale", { Name = "Pop", Parent = toast })
L.icon(I.Pen, { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.32), Size = UDim2.fromOffset(64, 64), Parent = toast })
L.new("TextLabel", { Name = "Title", Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, FontFace = L.Display, Text = "PEN LV. 2", TextSize = 60, TextColor3 = Color3.fromRGB(255, 232, 160), TextStrokeColor3 = Color3.fromRGB(40, 22, 6), TextStrokeTransparency = 0.2, Parent = toast })
L.new("TextLabel", { Name = "Sub", Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, FontFace = L.Display, Text = "+1 CREATURE CAPACITY", TextSize = 32, TextColor3 = Color3.fromRGB(150, 255, 160), TextStrokeColor3 = Color3.fromRGB(10, 40, 14), TextStrokeTransparency = 0.2, Parent = toast })
pt.Parent = SG

-- ===== ThawPlacementGui =====
L.replace(SG, "ThawPlacementGui")
local tp = L.screen("ThawPlacementGui", 25, { Enabled = false })
local tpPanel = L.panel({ Name = "Panel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.76), Size = UDim2.fromOffset(380, 128), Parent = tp }, nil, 18)
L.hudScale(tpPanel)
L.icon(I.Ice, { Name = "Icon", Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(36, 36), Parent = tpPanel })
L.text({ Name = "Title", Position = UDim2.fromOffset(56, 8), Size = UDim2.new(1, -70, 0, 26), Text = "PLACE YOUR ICE", TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 2.5, Parent = tpPanel })
L.text({ Name = "Status", Position = UDim2.fromOffset(56, 34), Size = UDim2.new(1, -70, 0, 20), FontFace = L.BodyHeavy, Text = "Move to aim, then PLACE", TextSize = 16, TextColor3 = C.Mint, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 1.5, Parent = tpPanel })
local row = L.new("Frame", { Name = "Buttons", Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Parent = tpPanel }, {
    L.list(Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
})
L.button({ Name = "Place", Size = UDim2.fromOffset(112, 46), Text = "PLACE", TextSize = 20, LayoutOrder = 1, Parent = row }, C.Green)
L.button({ Name = "Auto", Size = UDim2.fromOffset(112, 46), Text = "AUTO", TextSize = 20, LayoutOrder = 2, Parent = row }, C.Blue)
L.button({ Name = "Cancel", Size = UDim2.fromOffset(112, 46), Text = "CANCEL", TextSize = 20, LayoutOrder = 3, Parent = row }, C.Danger)
tp.Parent = SG

-- ===== MountSpeedWind =====
L.replace(SG, "MountSpeedWind")
local wind = L.screen("MountSpeedWind", 0, { IgnoreGuiInset = true, Enabled = false })
for index = 1, 8 do
    L.new("Frame", { Name = "Streak" .. index, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(80, 2), BackgroundColor3 = Color3.fromRGB(235, 248, 255), BackgroundTransparency = 1, Parent = wind }, {
        L.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }),
    })
end
wind.Parent = SG

-- ===== world templates =====
local function bb(name, props)
    L.replace(T, name)
    props.Name = name
    props.LightInfluence = 0
    return L.new("BillboardGui", props)
end

-- Thaw timer
local tt = bb("ThawTimerBillboard", { AlwaysOnTop = true, MaxDistance = 100, Size = UDim2.fromOffset(212, 58), Enabled = false })
local ttp = L.new("Frame", { Name = "Panel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0.06, Parent = tt }, {
    L.corner(14), L.grad(C.PanelTop, C.PanelBottom, 90, "PanelGradient"), L.stroke(C.Ice, 2, 0.45, "Stroke"),
})
L.new("Frame", { Name = "ReadyFace", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, Visible = false, ZIndex = 1, Parent = ttp }, {
    L.corner(14), L.grad(Color3.fromRGB(255, 244, 222), Color3.fromRGB(255, 205, 150), 90),
})
L.icon(I.Drop, { Name = "ThawIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(40, 40), ZIndex = 3, Parent = ttp })
L.icon(I.Ice, { Name = "ReadyIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(40, 40), Visible = false, ZIndex = 3, Parent = ttp })
L.text({ Name = "Title", Position = UDim2.fromOffset(50, 5), Size = UDim2.fromOffset(90, 20), FontFace = L.BodyHeavy, Text = "THAWING", TextSize = 15, TextColor3 = C.IceSoft, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 1.5, ZIndex = 3, Parent = ttp })
L.text({ Name = "TimeLabel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 2), Size = UDim2.fromOffset(80, 26), Text = "1:23", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Right, OutlineThickness = 2, ZIndex = 3, Parent = ttp })
L.text({ Name = "ReadyLabel", Position = UDim2.fromOffset(50, 2), Size = UDim2.new(1, -58, 0, 28), Text = "READY TO CRACK!", TextSize = 19, TextColor3 = Color3.fromRGB(255, 255, 255), OutlineColor = Color3.fromRGB(120, 40, 6), OutlineThickness = 2.5, Visible = false, ZIndex = 3, Parent = ttp })
L.bar({ Name = "BarBackground", Position = UDim2.fromOffset(50, 32), Size = UDim2.new(1, -60, 0, 16), ZIndex = 3, Parent = ttp }, Color3.fromRGB(110, 170, 255), 8)
tt.Parent = T

-- Creature stat card
local cs = bb("CreatureStatBillboard", { AlwaysOnTop = true, MaxDistance = 180, Size = UDim2.fromOffset(150, 58) })
local csb = L.new("Frame", { Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0.12, Parent = cs }, {
    L.corner(14), L.grad(C.PanelTop, C.PanelBottom, 90, "PanelGradient"), L.stroke(C.Ice, 2, 0.5, "Rim"),
    L.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
    L.list(Enum.FillDirection.Vertical, 0, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
})
local function statLine(name, img, text, color, order)
    local r = L.new("Frame", { Name = name, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = order, Parent = csb })
    L.icon(img, { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(22, 22), Parent = r })
    L.text({ Name = "Label", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 1, 0), Text = text, TextSize = 19, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 2, Parent = r })
end
statLine("Speed", I.Bolt, "22.0", Color3.fromRGB(255, 240, 150), 1)
statLine("Income", I.Coin, "$2/s", Color3.fromRGB(150, 255, 140), 2)
L.new("TextLabel", { Name = "Stats", Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "", Visible = false, LayoutOrder = 3, Parent = csb })
cs.Parent = T

-- Frost Sprite readability
local fs = bb("SurvivalReadability", { AlwaysOnTop = true, MaxDistance = 70, Size = UDim2.fromOffset(80, 46), StudsOffsetWorldSpace = Vector3.new(0, 3.1, 0) })
L.text({ Name = "AttackWarning", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(30, 26), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(255, 92, 70), Text = "!", TextSize = 22, TextColor3 = Color3.fromRGB(255, 248, 220), OutlineThickness = 2, Visible = false, Parent = fs }, {
    L.round(), L.stroke(Color3.fromRGB(255, 240, 180), 2, 0),
})
L.new("Frame", { Name = "HealthBackground", Position = UDim2.fromOffset(6, 31), Size = UDim2.new(1, -12, 0, 11), BackgroundColor3 = C.Well, ClipsDescendants = true, Parent = fs }, {
    L.round(), L.stroke(C.Outline, 2, 0),
    L.new("Frame", { Name = "HealthFill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(115, 215, 240) }, { L.round() }),
})
fs.Parent = T

-- Region sign
L.replace(T, "RecommendedWarmthSurfaceGui")
local rs = L.new("SurfaceGui", { Name = "RecommendedWarmthSurfaceGui", Face = Enum.NormalId.Front, AlwaysOnTop = false, LightInfluence = 0, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 20 })
local rsb = L.new("Frame", { Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, Parent = rs }, {
    L.grad(Color3.fromRGB(26, 46, 74), Color3.fromRGB(8, 16, 30), 90, "PanelGradient"), L.stroke(C.IceSoft, 4, 0.15, "Rim"),
})
L.new("ImageLabel", { Name = "Snow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = I.SnowTile, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(160, 160), ImageTransparency = 0.5, Parent = rsb })
local function signText(name, text, pos, size, color, font, maxSize)
    return L.new("TextLabel", { Name = name, Position = pos, Size = size, BackgroundTransparency = 1, FontFace = font, Text = text, TextColor3 = color, TextScaled = true, TextStrokeColor3 = C.Outline, TextStrokeTransparency = 0.2, ZIndex = 2, Parent = rsb }, {
        L.new("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = maxSize }),
    })
end
signText("RegionName", "Frozen Fields", UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.19), Color3.fromRGB(230, 244, 255), L.Display, 48)
signText("Guidance", "RECOMMENDED WARMTH", UDim2.fromScale(0.1, 0.26), UDim2.fromScale(0.8, 0.1), Color3.fromRGB(150, 200, 235), L.BodyHeavy, 26)
L.new("ImageLabel", { Name = "Flame", BackgroundTransparency = 1, Image = I.Flame, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromScale(0.04, 0.4), Size = UDim2.fromScale(0.16, 0.34), ZIndex = 2, Parent = rsb })
signText("RecommendedWarmth", "12.5K", UDim2.fromScale(0.18, 0.37), UDim2.fromScale(0.72, 0.4), Color3.fromRGB(255, 168, 60), L.Display, 110)
signText("YourMax", "YOUR MAX 4.2K", UDim2.fromScale(0.15, 0.81), UDim2.fromScale(0.7, 0.11), Color3.fromRGB(150, 168, 186), L.BodyHeavy, 22)
rs.Parent = T

-- Hearth status
local hs = bb("HearthStatus", { AlwaysOnTop = true, MaxDistance = 110, Size = UDim2.fromOffset(250, 82), StudsOffsetWorldSpace = Vector3.new(0, 8.5, 0), Enabled = false })
local hb = L.new("Frame", { Name = "Background", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0.06, Parent = hs }, {
    L.corner(14), L.grad(Color3.fromRGB(78, 42, 22), Color3.fromRGB(34, 18, 10), 90, "PanelGradient"), L.stroke(Color3.fromRGB(255, 150, 60), 2, 0.2, "Stroke"),
    L.new("UIScale", { Name = "UpgradePunch" }),
})
L.new("ImageLabel", { Name = "Flame", BackgroundTransparency = 1, Image = I.Flame, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.02, 0.5), Size = UDim2.fromScale(0.2, 0.74), Parent = hb })
local function hearthText(name, text, pos, size, color, font, maxSize)
    return L.new("TextLabel", { Name = name, Position = pos, Size = size, BackgroundTransparency = 1, FontFace = font, Text = text, TextColor3 = color, TextScaled = true, TextStrokeColor3 = Color3.fromRGB(30, 12, 4), TextStrokeTransparency = 0.15, TextXAlignment = Enum.TextXAlignment.Left, Parent = hb }, {
        L.new("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = maxSize }),
    })
end
hearthText("Level", "HEARTH LV. 1", UDim2.fromScale(0.24, 0.08), UDim2.fromScale(0.72, 0.26), Color3.fromRGB(255, 236, 190), L.Display, 17)
hearthText("Training", "+12 MAX WARMTH/s", UDim2.fromScale(0.24, 0.36), UDim2.fromScale(0.72, 0.32), Color3.fromRGB(255, 176, 78), L.Display, 22)
hearthText("Upgrade", "NEXT LV. 2 · $100", UDim2.fromScale(0.24, 0.72), UDim2.fromScale(0.72, 0.2), Color3.fromRGB(205, 186, 160), L.BodyHeavy, 14)
hs.Parent = T

-- Warm zone ground decal
L.replace(T, "WarmZonePresentation")
local wz = L.new("SurfaceGui", { Name = "WarmZonePresentation", Face = Enum.NormalId.Top, LightInfluence = 0, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, CanvasSize = Vector2.new(920, 760) })
L.new("ImageLabel", { Name = "WarmGroundGlow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.02, 1.02), BackgroundTransparency = 1, Image = I.Glow, ScaleType = Enum.ScaleType.Stretch, ImageColor3 = Color3.fromRGB(255, 150, 50), ImageTransparency = 0.72, Parent = wz })
L.new("Frame", { Name = "Ring", Position = UDim2.fromScale(0.03, 0.05), Size = UDim2.fromScale(0.94, 0.9), BackgroundTransparency = 1, Parent = wz }, {
    L.new("UICorner", { CornerRadius = UDim.new(0.18, 0) }), L.stroke(Color3.fromRGB(255, 181, 79), 6, 0.5, "Border"),
})
L.new("TextLabel", { Name = "WarmZoneMeaning", Position = UDim2.fromScale(0.1, 0.07), Size = UDim2.fromScale(0.8, 0.09), BackgroundTransparency = 1, FontFace = L.Display, Text = "WARM ZONE  •  TRAINS MAX WARMTH  •  REFILLS", TextColor3 = Color3.fromRGB(255, 214, 140), TextScaled = true, TextStrokeColor3 = Color3.fromRGB(75, 34, 8), TextStrokeTransparency = 0.4, TextTransparency = 0.1, Parent = wz })
wz.Parent = T

-- Pen cash popup
local pc = bb("PenCashPopup", { Size = UDim2.fromOffset(160, 46), AlwaysOnTop = true, ResetOnSpawn = false, Enabled = false })
L.new("TextLabel", { Name = "Amount", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, FontFace = L.Display, Text = "+$12", TextSize = 30, TextColor3 = Color3.fromRGB(130, 255, 120), TextStrokeColor3 = Color3.fromRGB(10, 40, 14), TextStrokeTransparency = 0.15, Parent = pc })
L.new("UIScale", { Name = "Punch", Parent = pc })
pc.Parent = T

-- Pen banner (432x228 px canvas at 60 px/stud on the BannerBoard)
L.replace(T, "PenBanner")
local pb = L.new("SurfaceGui", { Name = "PenBanner", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 60, LightInfluence = 0.25, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
local body = L.new("Frame", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = pb })
local function penText(name, y, h, size, color, font, text)
    return L.new("TextLabel", { Name = name, Position = UDim2.new(0, 10, 0, y), Size = UDim2.new(1, -20, 0, h), BackgroundTransparency = 1, FontFace = font, TextSize = size, TextColor3 = color, TextStrokeColor3 = Color3.fromRGB(30, 18, 10), TextStrokeTransparency = 0.25, Text = text, Parent = body })
end
penText("Title", 4, 56, 52, Color3.fromRGB(255, 238, 200), L.Display, "PEN LV. 1")
penText("Income", 58, 40, 36, Color3.fromRGB(150, 255, 140), L.Display, "TOTAL $12/s")
penText("Count", 98, 34, 28, Color3.fromRGB(245, 228, 196), L.BodyHeavy, "3 / 4 CREATURES")
L.new("TextButton", { Name = "Upgrade", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140), Size = UDim2.new(1, -28, 0, 72), FontFace = L.Display, TextSize = 32, TextColor3 = Color3.fromRGB(40, 26, 8), BackgroundColor3 = Color3.fromRGB(255, 200, 70), AutoButtonColor = true, Text = "UPGRADE PEN  $500", Parent = body }, {
    L.corner(16), L.stroke(Color3.fromRGB(70, 44, 18), 4, 0, "Stroke"),
})
pb.Parent = T

return "built2"
