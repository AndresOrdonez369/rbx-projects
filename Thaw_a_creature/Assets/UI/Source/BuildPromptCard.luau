-- Edit-time: builds ReplicatedStorage.UITemplates.PromptCard, the custom ProximityPrompt look driven by PromptController.
local L = require(game.ServerStorage.__UIAuthoring:Clone())
local C = L.C
local T = game.ReplicatedStorage.UITemplates

local BADGE = 60
local KEY_INSET = 14
local TAP_ICON = "rbxasset://textures/ui/Controls/TouchTapIcon.png"

L.replace(T, "PromptCard")
local pc = L.new("BillboardGui", {
    Name = "PromptCard",
    Active = true,
    AlwaysOnTop = true,
    ClipsDescendants = false,
    LightInfluence = 0,
    ResetOnSpawn = false,
    Size = UDim2.fromOffset(380, 96),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local card = L.panel({
    Name = "Card",
    Active = true,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(0, 76),
    AutomaticSize = Enum.AutomaticSize.X,
    Parent = pc,
}, {
    L.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 20) }),
    L.list(Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
    L.new("UIScale", { Name = "Pop" }),
}, 20)
card.Rim.Thickness = 2.5
card.Rim.Transparency = 0.35

-- Badge: tap/click target. Track ring + two clipped half-discs swept by UIGradient rotation form the hold ring.
local badge = L.new("TextButton", {
    Name = "Badge",
    Size = UDim2.fromOffset(BADGE, BADGE),
    BackgroundTransparency = 1,
    AutoButtonColor = false,
    Text = "",
    LayoutOrder = 1,
    ZIndex = 2,
    Parent = card,
})
L.new("Frame", { Name = "Track", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Well, BackgroundTransparency = 0.15, ZIndex = 2, Parent = badge }, {
    L.round(), L.stroke(C.Outline, 2, 0, "Rim"),
})
local ring = L.new("Frame", { Name = "Ring", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = badge })
local function half(name, x, discX)
    local clip = L.new("Frame", { Name = name, Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3, Parent = ring })
    L.new("Frame", { Name = "Disc", Position = UDim2.fromScale(discX, 0), Size = UDim2.fromScale(2, 1), BackgroundColor3 = C.White, ZIndex = 3, Parent = clip }, {
        L.round(),
        L.new("UIGradient", {
            Name = "Sweep",
            Color = ColorSequence.new(C.IceSoft, C.Ice),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 1),
                NumberSequenceKeypoint.new(0.501, 0),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Rotation = 0,
        }),
    })
end
half("Left", 0, 0)
half("Right", 0.5, -1)
ring.Left.Disc.Sweep.Rotation = 0
ring.Right.Disc.Sweep.Rotation = -180

local key = L.new("Frame", {
    Name = "Key",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, -KEY_INSET, 1, -KEY_INSET),
    BackgroundColor3 = C.White,
    ZIndex = 4,
    Parent = badge,
}, {
    L.round(),
    L.grad(C.White, Color3.fromRGB(176, 222, 248), 90, "Face"),
    L.stroke(C.Outline, 2.5, 0, "Rim"),
    L.new("UIScale", { Name = "Press" }),
})
L.text({ Name = "KeyLabel", Size = UDim2.fromScale(1, 1), Text = "E", TextSize = 28, TextColor3 = C.Outline, NoOutline = true, ZIndex = 5, Parent = key })
L.icon(TAP_ICON, { Name = "KeyIcon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.72, 0.72), ImageColor3 = C.Outline, Visible = false, ZIndex = 5, Parent = key })
L.text({
    Name = "HoldTag",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 1, -2),
    Size = UDim2.fromOffset(40, 16),
    BackgroundTransparency = 0,
    BackgroundColor3 = C.Ice,
    FontFace = L.BodyHeavy,
    Text = "HOLD",
    TextSize = 12,
    TextColor3 = C.Outline,
    NoOutline = true,
    ZIndex = 6,
    Parent = badge,
}, { L.round(), L.stroke(C.Outline, 2, 0, "Rim") })

local texts = L.new("Frame", {
    Name = "Texts",
    Size = UDim2.fromOffset(0, BADGE),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    LayoutOrder = 2,
    ZIndex = 2,
    Parent = card,
}, {
    L.list(Enum.FillDirection.Vertical, 0, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
})
L.text({ Name = "ObjectText", Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, FontFace = L.BodyHeavy, Text = "Ice", TextSize = 17, TextColor3 = C.IceSoft, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 1.5, LayoutOrder = 1, ZIndex = 2, Parent = texts })
L.text({ Name = "ActionText", Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, Text = "Grab Ice", TextSize = 28, TextXAlignment = Enum.TextXAlignment.Left, OutlineThickness = 2.5, LayoutOrder = 2, ZIndex = 2, Parent = texts })

pc.Parent = T
return "PromptCard built"
