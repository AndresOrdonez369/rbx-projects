-- Edit-time: HUD layout pass (2026-10-14) on StarterGui.MainHud. DROP is 80 px tall so it stays a 44 px touch target at HudScale 0.55.
--   TopCenter    : Warmth panel (moved from BottomCenter) above the Great Frost card.
--   BottomCenter : action row = survival ToolSlot (replaces the Roblox Backpack) + CarriedIcePanel with DROP.
--   RightRail    : Creatures button (moved from LeftRail) above the MountCard (portrait, name, Vitality).
--   LeftRail     : larger Cash pill, Archive button.
local L = require(game.ServerStorage.__UIAuthoring:Clone())
local C, I = L.C, L.Img
local hud = game.StarterGui.MainHud
local top, bottom, left = hud.TopCenter, hud.BottomCenter, hud.LeftRail

local function keyHint(text, props)
    props.Name = "KeyHint"
    props.Size = UDim2.fromOffset(22, 22)
    props.BackgroundTransparency = 0
    props.BackgroundColor3 = C.Well
    props.Text = text
    props.TextSize = 15
    props.NoOutline = true
    return L.text(props, { L.corner(7), L.stroke(C.Ice, 1.5, 0.35, "Rim") })
end

-- ===== TopCenter: Warmth above the Great Frost card =====
local warmth = bottom:FindFirstChild("WarmthPanel") or top:FindFirstChild("WarmthPanel")
warmth.Parent = top
warmth.LayoutOrder = 1
warmth.Size = UDim2.fromOffset(460, 64)
top.CountdownCard.LayoutOrder = 2
top.ObjectiveCard.LayoutOrder = 3
top.Size = UDim2.fromOffset(480, 200)

-- ===== BottomCenter: action row =====
local oldVitality = bottom:FindFirstChild("VitalityPanel")
if oldVitality then
    oldVitality:Destroy()
end
L.replace(bottom, "ToolSlot")
L.replace(bottom, "CarriedIcePanel")
bottom.Size = UDim2.fromOffset(570, 100)
local row = bottom.UIListLayout
row.FillDirection = Enum.FillDirection.Horizontal
row.HorizontalAlignment = Enum.HorizontalAlignment.Center
row.VerticalAlignment = Enum.VerticalAlignment.Bottom
row.Padding = UDim.new(0, 14)

local slot = L.new("TextButton", {
    Name = "ToolSlot",
    Size = UDim2.fromOffset(80, 80),
    LayoutOrder = 1,
    BackgroundColor3 = C.White,
    BackgroundTransparency = 0.06,
    AutoButtonColor = true,
    Text = "",
    Parent = bottom,
}, {
    L.corner(18),
    L.grad(C.PanelTop, C.PanelBottom, 90, "PanelGradient"),
    L.stroke(C.Ice, 2.5, 0.35, "Rim"),
    L.new("UIScale", { Name = "Press" }),
})
L.icon(I.Pick, { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(58, 58), ZIndex = 2, Parent = slot })
keyHint("1", { Position = UDim2.fromOffset(5, 5), ZIndex = 3, Parent = slot })
local lock = L.new("Frame", { Name = "LockOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Well, BackgroundTransparency = 0.3, Visible = false, ZIndex = 4, Parent = slot }, { L.corner(18) })
L.icon(I.Lock, { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -7), Size = UDim2.fromOffset(34, 34), ZIndex = 5, Parent = lock })
L.text({ Name = "Caption", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -5), Size = UDim2.new(1, -6, 0, 14), FontFace = L.BodyHeavy, Text = "CARRYING", TextSize = 12, TextColor3 = C.IceSoft, OutlineThickness = 1.5, ZIndex = 5, Parent = lock })

local carried = L.panel({ Name = "CarriedIcePanel", Size = UDim2.fromOffset(360, 88), LayoutOrder = 2, Visible = false, Parent = bottom }, {
    L.new("UIScale", { Name = "Pop" }),
}, 18)
L.icon(I.Ice, { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(62, 62), ZIndex = 2, Parent = carried })
L.icon(I.Star, { Name = "SpecialBadge", Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), Visible = false, ZIndex = 3, Parent = carried })
L.text({ Name = "Title", Position = UDim2.fromOffset(78, 13), Size = UDim2.fromOffset(150, 16), FontFace = L.BodyHeavy, Text = "CARRIED ICE", TextSize = 14, TextColor3 = C.IceSoft, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 1.5, ZIndex = 2, Parent = carried })
L.text({ Name = "IceName", Position = UDim2.fromOffset(78, 29), Size = UDim2.fromOffset(150, 28), Text = "REGULAR ICE", TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 2.5, ZIndex = 2, Parent = carried })
L.text({ Name = "Drain", Position = UDim2.fromOffset(78, 58), Size = UDim2.fromOffset(150, 16), FontFace = L.BodyHeavy, Text = "WARMTH DRAIN ×2", TextSize = 13, TextColor3 = C.EmberLight, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 1.5, ZIndex = 2, Parent = carried })
local drop = L.button({ Name = "DropButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(112, 80), Text = "DROP", TextSize = 26, Radius = 14, ZIndex = 2, Parent = carried }, C.Danger)
keyHint("G", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -8), ZIndex = 4, Parent = drop })

-- ===== RightRail: Creatures button + MountCard =====
local right = hud:FindFirstChild("RightRail")
local creaturesButton = left.MenuButtons:FindFirstChild("CreaturesButton") or (right and right:FindFirstChild("CreaturesButton"))
creaturesButton.Parent = nil
if right then
    right:Destroy()
end
right = L.new("Frame", {
    Name = "RightRail",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.45, 0),
    Size = UDim2.fromOffset(180, 330),
    BackgroundTransparency = 1,
}, {
    L.list(Enum.FillDirection.Vertical, 12, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
})
L.hudScale(right)
creaturesButton.LayoutOrder = 1
creaturesButton.Parent = right

local mount = L.panel({ Name = "MountCard", Size = UDim2.fromOffset(168, 200), LayoutOrder = 2, Visible = false, Parent = right }, nil, 18)
local portraitFrame = L.new("Frame", { Name = "PortraitFrame", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(146, 112), BackgroundColor3 = C.White, ZIndex = 2, Parent = mount }, {
    L.corner(14),
    L.grad(Color3.fromRGB(64, 104, 150), Color3.fromRGB(16, 30, 52), 90, "Sky"),
    L.stroke(C.Outline, 2, 0, "Rim"),
})
local portrait = L.new("ViewportFrame", {
    Name = "Portrait",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Ambient = Color3.fromRGB(190, 205, 225),
    LightColor = Color3.fromRGB(255, 250, 240),
    LightDirection = Vector3.new(-0.6, -1, -0.4),
    ZIndex = 3,
    Parent = portraitFrame,
})
portrait:SetAttribute("FieldOfView", 30)
L.text({ Name = "CreatureName", Position = UDim2.new(0, 8, 0, 124), Size = UDim2.new(1, -16, 0, 26), Text = "Tyrannosaurus", TextSize = 19, OutlineThickness = 2.5, ZIndex = 2, Parent = mount })
local bar = L.bar({ Name = "BarBackground", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 158), Size = UDim2.new(1, -20, 0, 26), ZIndex = 2, Parent = mount }, Color3.fromRGB(105, 205, 240), 9)
L.text({ Name = "Value", Size = UDim2.fromScale(1, 1), Text = "100 / 100", TextSize = 16, OutlineThickness = 2, ZIndex = 4, Parent = bar })
local tag = L.new("Frame", { Name = "StateTag", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, 8), Size = UDim2.fromOffset(250, 24), BackgroundColor3 = C.IceSoft, Visible = false, ZIndex = 3, Parent = mount }, {
    L.round(), L.stroke(C.Outline, 2, 0),
})
L.text({ Name = "State", Size = UDim2.fromScale(1, 1), FontFace = L.BodyHeavy, Text = "FROSTED · RETURN TO YOUR HEARTH", TextSize = 13, TextColor3 = C.Outline, NoOutline = true, ZIndex = 4, Parent = tag })
right.Parent = hud

-- ===== LeftRail: bigger Cash, Archive only =====
local cash = left.CashPill
cash.Size = UDim2.fromOffset(250, 60)
cash.Icon.Size = UDim2.fromOffset(66, 66)
cash.Icon.Position = UDim2.new(0, -8, 0.5, 0)
cash.CashLabel.Position = UDim2.fromOffset(64, 0)
cash.CashLabel.Size = UDim2.new(1, -74, 1, 0)
cash.CashLabel.TextSize = 32
left.MenuButtons.Size = UDim2.fromOffset(92, 92)

-- ===== Corner pass (2026-10-16): Cash bottom-left, Great Frost timer bottom-right, Warmth alone at the top =====
-- TouchOffset (read by HudScaleController) lifts/shifts the corners clear of Roblox's thumbstick and jump button.
local function corner(name, anchor, position, size, touchOffset)
    local frame = hud:FindFirstChild(name) or Instance.new("Frame")
    frame.Name = name
    frame.AnchorPoint = anchor
    frame.Position = position
    frame.Size = size
    frame.BackgroundTransparency = 1
    frame:SetAttribute("TouchOffset", touchOffset)
    if not frame:FindFirstChild("HudScale") then
        L.hudScale(frame)
    end
    frame.Parent = hud
    return frame
end

local bottomLeft = corner("BottomLeft", Vector2.new(0, 1), UDim2.new(0, 14, 1, -14), UDim2.fromOffset(260, 70), UDim2.fromScale(0, -0.3))
local bottomRight = corner("BottomRight", Vector2.new(1, 1), UDim2.new(1, -14, 1, -14), UDim2.fromOffset(230, 60), UDim2.fromScale(-0.22, 0))

local cashPill = left:FindFirstChild("CashPill") or bottomLeft:FindFirstChild("CashPill")
cashPill.Parent = bottomLeft
cashPill.AnchorPoint = Vector2.new(0, 1)
cashPill.Position = UDim2.new(0, 8, 1, 0)

local countdown = top:FindFirstChild("CountdownCard") or bottomRight:FindFirstChild("CountdownCard")
countdown.Parent = bottomRight
countdown.AnchorPoint = Vector2.new(1, 1)
countdown.Position = UDim2.fromScale(1, 1)

return "HUD layout built"
