-- Edit-time authoring helpers used (via a temporary ServerStorage ModuleScript) to build the UI prefabs.
local L = {}

L.Img = {
    Flame = "rbxassetid://98458032632941",
    Coin = "rbxassetid://107659112864488",
    Paw = "rbxassetid://110255764867027",
    Snowflake = "rbxassetid://76699192361413",
    Book = "rbxassetid://90141175677641",
    Bolt = "rbxassetid://80114421700035",
    Size = "rbxassetid://75435069572364",
    Home = "rbxassetid://137610863080596",
    Ice = "rbxassetid://119987542854075",
    Drop = "rbxassetid://123801979946861",
    Star = "rbxassetid://120268416254621",
    Close = "rbxassetid://74988003229479",
    Up = "rbxassetid://101376868623211",
    Tag = "rbxassetid://102849500770956",
    Chevron = "rbxassetid://139269822353656",
    Lock = "rbxassetid://84007290985525",
    Pen = "rbxassetid://93389250147048",
    Timer = "rbxassetid://75359006409181",
    FrostVignette = "rbxassetid://127975599556141",
    WarmVignette = "rbxassetid://110468241334755",
    Glow = "rbxassetid://117109697599396",
    Rays = "rbxassetid://103757732184118",
    Sparkle = "rbxassetid://105494368736348",
    SnowTile = "rbxassetid://123144014846355",
    Pick = "rbxassetid://122291332970540",
    HomeArrow = "rbxassetid://95802547412232",
}

L.C = {
    PanelTop = Color3.fromRGB(34, 58, 92),
    PanelBottom = Color3.fromRGB(14, 26, 46),
    Panel = Color3.fromRGB(18, 32, 54),
    Well = Color3.fromRGB(7, 14, 26),
    Ice = Color3.fromRGB(127, 219, 255),
    IceSoft = Color3.fromRGB(196, 238, 255),
    Ember = Color3.fromRGB(255, 122, 40),
    EmberLight = Color3.fromRGB(255, 196, 82),
    Gold = Color3.fromRGB(255, 204, 72),
    Mint = Color3.fromRGB(110, 232, 180),
    Danger = Color3.fromRGB(255, 84, 72),
    Green = Color3.fromRGB(76, 214, 110),
    Blue = Color3.fromRGB(70, 156, 255),
    Wood = Color3.fromRGB(196, 126, 66),
    Text = Color3.fromRGB(244, 250, 255),
    TextDim = Color3.fromRGB(150, 182, 212),
    Outline = Color3.fromRGB(8, 16, 28),
    White = Color3.new(1, 1, 1),
}

L.Display = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
L.Body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
L.BodyHeavy = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)

function L.new(className, props, children)
    local inst = Instance.new(className)
    if inst:IsA("GuiObject") then
        inst.BorderSizePixel = 0
    end
    local parent = nil
    for key, value in props or {} do
        if key == "Parent" then
            parent = value
        else
            inst[key] = value
        end
    end
    for _, child in children or {} do
        child.Parent = inst
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

function L.corner(radius)
    return L.new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function L.round()
    return L.new("UICorner", { CornerRadius = UDim.new(1, 0) })
end

function L.stroke(color, thickness, transparency, name)
    return L.new("UIStroke", {
        Name = name or "UIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or L.C.Outline,
        Thickness = thickness or 2,
        Transparency = transparency or 0,
        LineJoinMode = Enum.LineJoinMode.Round,
    })
end

function L.textStroke(color, thickness, transparency)
    return L.new("UIStroke", {
        Name = "TextOutline",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Color = color or L.C.Outline,
        Thickness = thickness or 2,
        Transparency = transparency or 0,
        LineJoinMode = Enum.LineJoinMode.Round,
    })
end

function L.grad(top, bottom, rotation, name)
    return L.new("UIGradient", {
        Name = name or "UIGradient",
        Color = ColorSequence.new(top, bottom),
        Rotation = rotation or 90,
    })
end

function L.pad(all, x)
    local h = UDim.new(0, x or all)
    local v = UDim.new(0, all)
    return L.new("UIPadding", { PaddingLeft = h, PaddingRight = h, PaddingTop = v, PaddingBottom = v })
end

function L.list(direction, padding, hAlign, vAlign)
    return L.new("UIListLayout", {
        FillDirection = direction,
        Padding = UDim.new(0, padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
    })
end

function L.panel(props, children, radius)
    props.BackgroundColor3 = props.BackgroundColor3 or L.C.White
    props.BackgroundTransparency = props.BackgroundTransparency or 0.06
    local kids = {
        L.corner(radius or 14),
        L.grad(L.C.PanelTop, L.C.PanelBottom, 90, "PanelGradient"),
        L.stroke(L.C.Ice, 2, 0.55, "Rim"),
    }
    for _, child in children or {} do
        table.insert(kids, child)
    end
    return L.new("Frame", props, kids)
end

function L.text(props, children)
    props.BackgroundTransparency = props.BackgroundTransparency or 1
    props.FontFace = props.FontFace or L.Display
    props.TextColor3 = props.TextColor3 or L.C.Text
    props.TextSize = props.TextSize or 18
    props.Text = props.Text or ""
    local kids = children or {}
    if props.NoOutline then
        props.NoOutline = nil
    else
        table.insert(kids, L.textStroke(props.OutlineColor, props.OutlineThickness, props.OutlineTransparency))
    end
    props.OutlineColor = nil
    props.OutlineThickness = nil
    props.OutlineTransparency = nil
    return L.new("TextLabel", props, kids)
end

function L.icon(image, props)
    props.BackgroundTransparency = 1
    props.Image = image
    props.ScaleType = props.ScaleType or Enum.ScaleType.Fit
    return L.new("ImageLabel", props)
end

function L.button(props, color, children)
    local face = color
    local top = face:Lerp(Color3.new(1, 1, 1), 0.28)
    local bottom = face:Lerp(Color3.new(0, 0, 0), 0.18)
    local text = props.Text or ""
    local textSize = props.TextSize or 20
    local font = props.FontFace or L.Display
    local radius = props.Radius or 12
    props.Radius = nil
    props.Text = ""
    props.TextSize = nil
    props.FontFace = nil
    props.BackgroundColor3 = L.C.White
    props.AutoButtonColor = true
    local kids = {
        L.corner(radius),
        L.grad(top, bottom, 90, "Face"),
        L.stroke(L.C.Outline, 2.5, 0, "Rim"),
    }
    for _, child in children or {} do
        table.insert(kids, child)
    end
    local button = L.new("TextButton", props, kids)
    if text ~= "" then
        L.text({ Name = "Label", Size = UDim2.fromScale(1, 1), Text = text, TextSize = textSize, FontFace = font, OutlineThickness = 2, ZIndex = (props.ZIndex or 1) + 1, Parent = button })
    end
    return button
end

function L.badge(image, size, ring, props)
    props.Size = UDim2.fromOffset(size, size)
    props.BackgroundColor3 = L.C.White
    local badge = L.new("Frame", props, {
        L.round(),
        L.grad(L.C.PanelTop:Lerp(ring, 0.25), L.C.PanelBottom, 90, "BadgeGradient"),
        L.stroke(ring, 3, 0, "Ring"),
    })
    L.icon(image, {
        Name = "Icon",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.78, 0.78),
        ZIndex = (props.ZIndex or 1) + 1,
        Parent = badge,
    })
    return badge
end

function L.bar(props, fillColor, radius)
    props.BackgroundColor3 = props.BackgroundColor3 or L.C.Well
    props.BackgroundTransparency = props.BackgroundTransparency or 0.1
    props.ClipsDescendants = true
    local well = L.new("Frame", props, {
        L.corner(radius or 8),
        L.stroke(L.C.Outline, 2, 0, "Rim"),
    })
    local fill = L.new("Frame", {
        Name = "Fill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = fillColor,
        ZIndex = (props.ZIndex or 1) + 1,
        Parent = well,
    }, {
        L.corner(radius or 8),
        L.new("UIGradient", {
            Name = "Shine",
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.45, Color3.fromRGB(235, 235, 235)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 175, 175)),
            }),
        }),
    })
    return well, fill
end

function L.hudScale(parent)
    return L.new("UIScale", { Name = "HudScale", Parent = parent })
end

function L.screen(name, displayOrder, props)
    local p = props or {}
    p.Name = name
    p.ResetOnSpawn = false
    p.DisplayOrder = displayOrder
    p.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    return L.new("ScreenGui", p)
end

function L.replace(parent, name)
    local old = parent:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

return L
