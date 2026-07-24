---------------------------------------------------------------
--- GAME CHECK
---------------------------------------------------------------

local executor = identifyexecutor()

if game.GameId ~= 7488668004 then
    kick("Game not supported")
    return
end

warn("LOADING SCRIPT")

---------------------------------------------------------------
--- UI LIBRARY
---------------------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
   name = "Bake or Die",
   -- No icon in the topbar. Gen1 used Icon = 0 to mean "none", but Gen2 treats 0
   -- as a real value and builds a visible 32x32 ImageLabel with an empty Image,
   -- which is the blank gap before the title. Omitting icon builds no label.
   showName = "Rayfield", -- for mobile users to unhide Rayfield, change if you'd like

   theme = "default", -- "default", "cobalt", "ember", "amethyst", "frost", "rose"

   configuration = {
      autoSave = true,
      autoLoad = true,
      customFolder = nil, -- Create a custom folder for your hub/game
      fileName = "Default"
   },
})
---------------------------------------------------------------
--- WINDOW RESIZING (copied from NEMESIS)
---------------------------------------------------------------
-- Lifted from ~/NEMESIS/source.lua:3090. Same grip, same icon, same stretch
-- curve, same smoothing loop and same constants. Only the bindings differ,
-- because NEMESIS owns its window and this one is Gen2's:
--
--   * NEMESIS's root has ClipsDescendants = true, so its grip can sit 4px from
--     the corner and any overhang past the rounded corner is simply clipped
--     away. Gen2's window does NOT clip (it has to let dropdowns and shadows
--     escape), and its corner radius is 20 rather than NEMESIS's 16, so at 4px
--     the icon's corner lands outside the curve and draws over the game. 8px
--     puts it back inside: the curve's centre is 20px in, and the icon corner
--     is then 12*sqrt(2) = 17 away, within the 20 radius.
--   * minW is NEMESIS's 820 because its top bar is that wide. This window is
--     475 by default, so 820 would make the first drag jump it wider. The
--     library's own floor of 380x320 is used instead.
--   * ZIndex 7/8 becomes 150/151, since Gen2 paints a bottom fade at 100
--     across the whole window that would otherwise cover the grip.
--   * The cursor position comes from MouseMoved, which reports in the same
--     space as AbsolutePosition, instead of GetMouseLocation with a hand
--     applied GUI inset correction.
--   * Writing the size goes through applySize so Gen2's own record of the
--     window size, the drag pill and the bottom fade all stay in step.
do
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local GuiService = game:GetService("GuiService")

    local main = Window.main
    local screenGui = main:FindFirstAncestorWhichIsA("ScreenGui")
    local scale = 1

    local function tween(object, properties, info)
        TweenService:Create(object, info, properties):Play()
    end

    -- Gen2 sizes the page's bottom fade as Size = {1,0},{-0.093,100}, so the
    -- taller the window gets the SHORTER the fade becomes: 54px at a 500 tall
    -- window, 24px at 820. Both the fade and the window are rounded by 20, but
    -- Roblox clamps a corner radius to half the height, so once the fade drops
    -- under 40px its corners round tighter than the window's and its squarer
    -- bottom corners jut out past the curve, drawing a dark line across the
    -- bottom. Clamping the fade keeps the two curves identical at any height.
    local bottomFade, fadeScaleY, fadeOffsetY, fadeMinHeight
    local windowRadius = 20

    do
        local windowCorner = main:FindFirstChildOfClass("UICorner")
        if windowCorner then
            windowRadius = windowCorner.CornerRadius.Offset
        end

        for _, child in ipairs(main:GetChildren()) do
            if child:IsA("Frame") and child.ZIndex == 100 and child:FindFirstChildOfClass("UIGradient") then
                bottomFade = child
                break
            end
        end

        if bottomFade then
            local fadeCorner = bottomFade:FindFirstChildOfClass("UICorner")
            local radius = (fadeCorner and fadeCorner.CornerRadius.Offset) or windowRadius
            fadeScaleY = bottomFade.Size.Y.Scale
            fadeOffsetY = bottomFade.Size.Y.Offset
            fadeMinHeight = radius * 2
        end
    end

    local function clampBottomFade(height)
        if not bottomFade then return end
        local intended = fadeOffsetY + fadeScaleY * height
        bottomFade.Size = UDim2.new(1, 0, 0, math.max(fadeMinHeight, intended))
    end

    -- NEMESIS just assigns root.Size; here the library's own bookkeeping has to
    -- follow, or show / hide / minimise will each tween back to 475x500.
    local W, H = main.AbsoluteSize.X, main.AbsoluteSize.Y

    local function applySize(width, height)
        width, height = math.floor(width + 0.5), math.floor(height + 0.5)
        W, H = width, height

        if main.Size.X.Offset == width and main.Size.Y.Offset == height then
            return
        end

        main.Size = UDim2.fromOffset(width, height)
        Window.size = UDim2.fromOffset(width, height)
        clampBottomFade(height)

        if Window.drag and Window.drag.drag then
            local pos = main.Position
            Window.drag.drag.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + height / 2 + 15)
        end
    end

    -- minimum size keeps the whole top bar visible; below this things overlap
    local minW = 380
    local minH = 320

    local resizeGrip = Instance.new("ImageButton")
    resizeGrip.Name = "ResizeGrip"
    resizeGrip.AnchorPoint = Vector2.new(1, 1)
    resizeGrip.Position = UDim2.new(1, -8, 1, -8)
    resizeGrip.Size = UDim2.fromOffset(54, 54)
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Image = ""
    resizeGrip.AutoButtonColor = false
    resizeGrip.ZIndex = 150
    resizeGrip.Parent = main

    -- 9-sliced so the curved icon stretches cleanly toward the cursor
    local resizeIcon = Instance.new("ImageLabel")
    resizeIcon.Name = "Icon"
    resizeIcon.AnchorPoint = Vector2.new(1, 1)
    resizeIcon.Position = UDim2.new(1, 0, 1, 0)
    resizeIcon.Size = UDim2.fromOffset(18, 18)
    resizeIcon.BackgroundTransparency = 1
    resizeIcon.Image = "rbxassetid://86527207319523"
    resizeIcon.ImageColor3 = Color3.fromRGB(90, 90, 98)
    resizeIcon.ImageTransparency = 0
    resizeIcon.ScaleType = Enum.ScaleType.Slice
    resizeIcon.SliceCenter = Rect.new(51, 52, 51, 52)
    resizeIcon.SliceScale = 0.5
    resizeIcon.ZIndex = 151
    resizeIcon.Parent = resizeGrip

    -- SIRIUS-style smooth resize: a RenderStepped loop where the visual size
    -- eases toward a cursor-driven target each frame (frame-rate independent
    -- exponential smoothing), so the window butter-glides to follow the cursor.
    local SMOOTH_K = 26          -- higher = tighter cursor-follow (SIRIUS ~28)
    local resizing = false
    local hovering = false
    local startPointer, startW, startH
    local targetW, targetH = W, H
    local visualW, visualH = W, H
    local loopConn
    local hoverX, hoverY

    Window.__resizing = false

    local function getPointer(input)
        if input and input.UserInputType == Enum.UserInputType.Touch then
            return Vector2.new(input.Position.X, input.Position.Y)
        end
        return UserInputService:GetMouseLocation()
    end

    local function maxSize()
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        return math.max(minW, vp.X / scale - 40), math.max(minH, vp.Y / scale - 40)
    end

    -- SIRIUS stretch: normalize the cursor's position inside the grip, then
    -- stretch the icon NON-uniformly toward it (wider/taller as you move in)
    -- Whichever way the cursor's Y is reported, it has to be in the same space
    -- as AbsolutePosition or relY pins to an end and that axis stops responding
    -- (the top approach going dead is exactly that). Rather than assume a sign
    -- for the GUI inset, this resolves it from the geometry: while the cursor is
    -- over the grip its Y must fall inside the grip's rect, so if the raw
    -- reading does not, whichever of y+inset / y-inset does is the right space.
    local resolvedYOffset = 0

    local function resolveY(y, top, height)
        if y >= top and y <= top + height then
            return y
        end

        local inset = 0
        pcall(function() inset = GuiService:GetGuiInset().Y end)

        for _, candidate in ipairs({ y + inset, y - inset }) do
            if candidate >= top and candidate <= top + height then
                resolvedYOffset = candidate - y
                return candidate
            end
        end

        return y + resolvedYOffset
    end

    local function normResize()
        local pos, sz = resizeGrip.AbsolutePosition, resizeGrip.AbsoluteSize

        local mx, my
        if hoverX then
            mx, my = hoverX, hoverY
        else
            local raw = UserInputService:GetMouseLocation()
            mx, my = raw.X, raw.Y
        end

        my = resolveY(my, pos.Y, sz.Y)

        local relX = (mx - pos.X) / math.max(sz.X, 1)
        local relY = (my - pos.Y) / math.max(sz.Y, 1)
        return Vector2.new(1 - math.clamp(relX, 0, 1), 1 - math.clamp(relY, 0, 1))
    end

    local function stretchIcon(duration)
        local n = normResize()
        tween(resizeIcon, {
            Size = UDim2.new(0, 20 + n.X * 30, 0, 20 + n.Y * 30),
            ImageColor3 = Color3.fromRGB(125, 125, 135),
        }, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    end

    local function pressIcon()
        tween(resizeIcon, {
            Size = UDim2.new(0, 30, 0, 30),
            ImageColor3 = Color3.fromRGB(150, 150, 160),
        }, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    end

    local function resetIcon()
        tween(resizeIcon, {
            Size = UDim2.new(0, 18, 0, 18),
            ImageColor3 = Color3.fromRGB(90, 90, 98),
        }, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    end

    local function stopLoop()
        if loopConn then loopConn:Disconnect(); loopConn = nil end
    end

    local function startLoop()
        stopLoop()
        visualW, visualH = W, H
        loopConn = RunService.RenderStepped:Connect(function(dt)
            local alpha = 1 - math.exp(-dt * SMOOTH_K)
            visualW = visualW + (targetW - visualW) * alpha
            visualH = visualH + (targetH - visualH) * alpha
            applySize(visualW, visualH)
            if not resizing
                and math.abs(visualW - targetW) <= 0.45
                and math.abs(visualH - targetH) <= 0.45 then
                applySize(targetW, targetH)
                stopLoop()
                Window.__resizing = false
            end
        end)
    end

    resizeGrip.MouseEnter:Connect(function()
        hovering = true
        if not resizing then stretchIcon(0.18) end
    end)

    resizeGrip.MouseLeave:Connect(function()
        hovering = false
        hoverX, hoverY = nil, nil
        if not resizing then resetIcon() end
    end)

    -- moving the cursor inside the grip restretches the icon toward it
    resizeGrip.MouseMoved:Connect(function(x, y)
        hoverX, hoverY = x, y
        if not resizing then stretchIcon(0.14) end
    end)

    resizeGrip.InputChanged:Connect(function(input)
        if resizing then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            hoverX, hoverY = input.Position.X, input.Position.Y
            stretchIcon(0.14)
        end
    end)

    resizeGrip.InputBegan:Connect(function(input)
        if Window.hidden or Window.minimised then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            Window.__resizing = true
            startPointer = getPointer(input)
            startW, startH = W, H
            targetW, targetH = W, H
            pressIcon()
            startLoop()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = getPointer(input) - startPointer
            local maxW, maxH = maxSize()
            -- *2: window is centre-anchored, so the corner tracks the cursor
            targetW = math.clamp(startW + (delta.X / scale) * 2, minW, maxW)
            targetH = math.clamp(startH + (delta.Y / scale) * 2, minH, maxH)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if resizing then
                resizing = false
                if hovering then stretchIcon(0.18) else resetIcon() end
            end
        end
    end)

    -- the grip has no place on a collapsed window
    main:GetPropertyChangedSignal("Size"):Connect(function()
        resizeGrip.Visible = not (Window.minimised or Window.hidden)
        clampBottomFade(main.AbsoluteSize.Y)
    end)

    clampBottomFade(main.AbsoluteSize.Y)
end
---------------------------------------------------------------
--- GEN2 COMPATIBILITY HELPERS
---------------------------------------------------------------

-- Gen2 has no CreateLabel. A label is a button with its interaction stripped
-- out, which renders the same card row Gen1 labels did. The returned handle
-- keeps a :Set(text) method so labels can still be updated at runtime.
local function CreateLabel(parent, text, icon)
    local label = parent:CreateButton({
        name = text,
        icon = icon,
        callback = function() end,
    })

    if label.interact then
        label.interact.Active = false
        label.interact.Interactable = false
    end
    if label.hoverOverlay then
        label.hoverOverlay.Visible = false
    end

    function label.Set(_, newText)
        label.name = newText
        if label.title then
            label.title.Text = newText
        end
    end

    return label
end

-- Gen2 builds a dropdown as a clipping root that grows to reveal the option
-- panel:
--     main  = Frame{ Size = (1,-20),(0,41), ClipsDescendants = true }
--     top   = Frame{ Size = (1,0),(0,41) }    -- header, carries a UIStroke
--     panel = Frame{ Size = (1,0),(1,-47) }   -- option list, carries a UIStroke
--
-- top and panel sit flush with main's edges, and a UIStroke draws outward from
-- its parent's bounds, so the outer half of both borders falls outside main's
-- clip rect and gets cut off. main has to keep clipping (that growth is what
-- wipes the panel in and out), so each stroke is moved onto a host frame inset
-- by the stroke thickness. The border then renders in the 1px ring inside main.
-- The stroke instances are reused, so every tween the library runs still applies.
local function insetStrokeHost(parent, name, size, position, anchor, radius)
    local host = Instance.new("Frame")
    host.Name = name
    host.BackgroundTransparency = 1
    host.BorderSizePixel = 0
    host.Size = size
    host.Position = position
    host.AnchorPoint = anchor
    host.ZIndex = 2

    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius
    corner.Parent = host

    host.Parent = parent
    return host
end

-- Gen2 sizes an open dropdown to its contents and caps it at 180px:
--     _openHeight = math.min(180, 95 + rows*38 + (rows-1)*5 + 2)
-- so a dropdown holding one or two options opens as a tiny sliver. Gen1 always
-- opened the same tall panel no matter how many options were in it, which is
-- what makes it read as a proper list, so the same fixed height is used here.
-- _open, _close and _resizeToOptions all call self:_openHeight(), and an
-- instance field shadows the shared metatable method, so overriding it per
-- dropdown is enough.
local DROPDOWN_OPEN_HEIGHT = 270

local function CreateDropdown(parent, props)

    local dropdown = parent:CreateDropdown(props)

    if dropdown and dropdown._optionFrames then
        function dropdown._openHeight()
            return DROPDOWN_OPEN_HEIGHT
        end
    end

    if not dropdown then return dropdown end
    if not dropdown.main or not dropdown.top or not dropdown.panel then return dropdown end
    if dropdown.main:FindFirstChild("TopStrokeHost") then return dropdown end

    local topCorner = dropdown.top:FindFirstChildOfClass("UICorner")
    local radius = topCorner and topCorner.CornerRadius or UDim.new(0, 12)
    local inner = UDim.new(radius.Scale, math.max(0, radius.Offset - 1))

    local topStroke = dropdown.top:FindFirstChildOfClass("UIStroke")
    if topStroke then
        topStroke.Parent = insetStrokeHost(
            dropdown.main,
            "TopStrokeHost",
            UDim2.new(1, -2, 0, dropdown.top.Size.Y.Offset - 2),
            UDim2.fromOffset(1, 1),
            Vector2.new(0, 0),
            inner
        )
    end

    -- The option list gives its canvas 2px of bottom padding but none at the
    -- top, so the first option sits flush with the ScrollingFrame's clip edge
    -- and its rounded top corner and outward stroke get sliced off. Match the
    -- bottom padding so the first row clears the boundary.
    if dropdown.list then
        local listPadding = dropdown.list:FindFirstChildOfClass("UIPadding")
        if listPadding and listPadding.PaddingTop.Offset < 2 then
            listPadding.PaddingTop = UDim.new(0, 2)
        end
    end

    if dropdown.panelStroke then
        dropdown.panelStroke.Parent = insetStrokeHost(
            dropdown.main,
            "PanelStrokeHost",
            UDim2.new(1, -2, 1, dropdown.panel.Size.Y.Offset - 2),
            UDim2.new(1, -1, 1, -1),
            Vector2.new(1, 1),
            inner
        )
    end

    return dropdown
end

---------------------------------------------------------------

local HomeTab = Window:CreateTab({ name = "Home", icon = 4483362458 })
local CombatTab = Window:CreateTab({ name = "Combat", icon = 4483362458 })
local AutofarmTab = Window:CreateTab({ name = "Autofarm", icon = 4483362458 })
local ItemsTab = Window:CreateTab({ name = "Items", icon = 4483362458 })
local PlayerTab = Window:CreateTab({ name = "Player", icon = 4483362458 })
local VisualsTab = Window:CreateTab({ name = "Visuals", icon = 4483362458 })
local TeleportTab = Window:CreateTab({ name = "Teleport", icon = 4483362458 })
local SettingsTab = Window:CreateTab({ name = "Settings", icon = 4483362458 })
local ScriptsTab = Window:CreateTab({ name = "Scripts", icon = 4483362458 })
local DiabloTab = Window:CreateTab({ name = "DIABLO", icon = 4483362458 })
local GodTab = Window:CreateTab({ name = "GOD", icon = 4483362458 })

local Section = HomeTab:CreateSection({ name = "Disord Server" })

local Button = HomeTab:CreateButton({
   name = "Discord Server (Click to copy Invite Link)",
   callback = function()
    setclipboard("https://discord.gg/YkbtBWb36K")
   end,
})

local Section = HomeTab:CreateSection({ name = "Update Log" })

--// Added
local Label = CreateLabel(HomeTab, "[+] Config Saving/Loading", 4483362458)
local Label = CreateLabel(HomeTab, "[+] Auto Make Pies", 4483362458)
local Label = CreateLabel(HomeTab, "[+] Auto Pickup Ingredients", 4483362458)
local Label = CreateLabel(HomeTab, "[+] Performance Settings", 4483362458)
--//Improved
local Label = CreateLabel(HomeTab, "[+] Improved Auto Sell Pie", 4483362458)

---------------------------------------------------------------
--- SERVICES / MODULES
---------------------------------------------------------------

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local isLobbyPlace

if game.Workspace:GetAttribute("Place") ~= nil then
    isLobbyPlace = true
else
    isLobbyPlace = false
end


local ClientRemotes
local ObjectsLibrary
local InventoryModule
local CameraModule
local DayNightClient
local InteractablesModule

if not isLobbyPlace then
    ClientRemotes = require(game.ReplicatedStorage.Client.ClientRemotes)
    ObjectsLibrary = require(game.ReplicatedStorage.Shared.ObjectsLibrary)
    InventoryModule = require(game.ReplicatedStorage.Client.Systems.Inventory)
    CameraModule = require(game.ReplicatedStorage.Client.Systems.CharacterController.Camera)
    DayNightClient = require(game.ReplicatedStorage.Client.Systems.DayNightClient)
    InteractablesModule = require(game.ReplicatedStorage.Client.Systems.Interactables)
end


---------------------------------------------------------------
--- VARIBLES
---------------------------------------------------------------

local plr = game.Players.LocalPlayer

local Stations = game.Workspace:FindFirstChild("Stations")
local Interactables = game.Workspace:FindFirstChild("Interactables")
local Containers = game.Workspace:FindFirstChild("Containers")
local Monsters = game.Workspace:FindFirstChild("Monsters")
local Defenses = game.Workspace:FindFirstChild("Defenses")

local Mixer = nil

local params = OverlapParams.new()
local shopParams = OverlapParams.new()

local FurnitureProducts
local SkipDayPrompt
local MixerPrompt = nil

local HotbarGui = nil
local SlotsGui = nil

local TeleportDebounce = false
local originalcf

local canSkipNights = false

local ShopDropdown
local ItemsDropdown
local KaWeaponDropdown
local ConfigDropdown

local sConfigName = nil

getgenv().NoProjectileDamage = false
getgenv().DropStack = false
getgenv().NoRecoil = false

local KillAuraInfiniteRange = false
local KillAuraWeapon = nil
local KillAuraWeaponOveride = nil
local KillAuraRange = 50
local KillAuraDelayTime = 0
local CurrentKillAuraSlot = nil

local ActiveWeaponSlot = nil
local CanModifyFirerate = false
local ModifiedFirerate = 0

local BringAllItemsTime = 0

local IgnoreBombIngredients = false

local oldLighting = nil


---------------------------------------------------------------
--- SCRIPT CONNECTIONS
---------------------------------------------------------------

getgenv().hitByProjectileHook = getgenv().hitByProjectileHook
getgenv().dropItemHook = getgenv().dropItemHook
getgenv().recoilHook = getgenv().recoilHook

local originalWeaponValues = {}

local PROMPTIGNORELIST = {
    "ShippingContainer",
    "PricklyCactus",
}

local ITEM_IDENTITY_TAGS = {
    ["Healing"] = "Heals",
    ["ReviveKit"] = "Heals",
    ["Firearm"] = "Gun",
    ["Ingredient"] = "Food",
    ["Raw"] = "Food",
    ["BakedGood"] = "Food",
    ["Melee"] = "Melee",
    ["Wood"] = "Wood",
    ["Metal"] = "Metal",
    ["PerkDrink"] = "Drink",
    ["Ammo"] = "Ammo",
}

local connections = {

    --// THREADS \\--

    BringAllItemsThread = nil,
    SingleShopBuy = nil,
    MultiShopBuy = nil,

    --// CONNECTIONS \\--

    plrGuiAddedConnection = nil,
    plrGuiRemovedConnection = nil,
    promptAddedConnection  = nil,
    SlotsGuiAddedConnection = nil,
    SlotsGuiRemovedConnection = nil,
    FullBrightConnection = nil,
    LowGraphicsConnection = nil,

    --// COROUTINES \\--

    KillAuraCoroutine     = nil,
    AutoPickupCorpses     = nil,
    AutoGrindCorpses      = nil,
    AutoGrindItems        = nil,
    AutoPickupGrindables  = nil,
    AutoBakePies          = nil,
    AutoSellPies          = nil,
    AutoRepair            = nil,
    AutoSkipDay           = nil,
    AutoOpenAllChest      = nil,
    AutoPickupBlueprints  = nil,
    AutoMakePies          = nil,
    AutoPickupIngredients = nil,
    AutoRoll              = nil,
    AutoChainsaw          = nil,
    AutoWizardSpell       = nil,
    AutoCannonBlast       = nil,
    FlyLoop               = nil,
    NoclipLoop            = nil,
    InfJumpConnection     = nil,
    AntiAFK               = nil,
    MonsterESP            = nil,
    FreecamLoop           = nil,
    FreecamInput          = nil,
    GodKillAura           = nil,
    GodRangeVis           = nil,
    GodMobList            = nil,
}

local threads = {}

---------------------------------------------------------------
--- SCRIPT FUNCTIONS
---------------------------------------------------------------

local function getItemSlot(itemName, itemType)

    if HotbarGui and SlotsGui then

        for _, frame in pairs(SlotsGui:GetChildren()) do
            if frame:IsA("Frame") then

                local ImgButton = frame.Frame.ImageButton
                local ItemName = ImgButton:FindFirstChild("Name")
                local ItemType = ImgButton:FindFirstChild("SlotType")

                if ItemName and ItemName.Text == itemName or ItemType and ItemType.Text == itemType then

                    local ItemSlot = ImgButton.SlotNumber.Text
                    return ItemSlot, ItemName and ItemName.Text
                end
            end
        end
        return false
    end

    return nil
end

-- Find the hotbar slot holding an item whose ObjectsLibrary entry carries the
-- given tag (e.g. "WizardStaff", "HandCannon"). The chainsaw is tagged "Melee"
-- but routes through its own remote, so it is matched by name instead. Returns
-- the numeric slot string, or nil.
local function getSlotByTag(tag, nameMatch)

    if not (HotbarGui and SlotsGui) then return nil end
    if isLobbyPlace then return nil end

    for _, frame in pairs(SlotsGui:GetChildren()) do
        if frame:IsA("Frame") then

            local ImgButton = frame:FindFirstChild("Frame") and frame.Frame:FindFirstChild("ImageButton")
            if ImgButton then

                local ItemName = ImgButton:FindFirstChild("Name")
                if ItemName then

                    local objName = string.gsub(ItemName.Text, "%s+", "")
                    local info = ObjectsLibrary.Objects[objName]

                    if not info then
                        for n, obj in pairs(ObjectsLibrary.Objects) do
                            if obj.DisplayName == ItemName.Text then info = obj objName = n break end
                        end
                    end

                    local matched = false
                    if nameMatch and string.find(string.lower(objName), string.lower(nameMatch), 1, true) then
                        matched = true
                    elseif tag and info and info.Tags and table.find(info.Tags, tag) then
                        matched = true
                    end

                    if matched then
                        return ImgButton.SlotNumber.Text
                    end
                end
            end
        end
    end

    return nil
end

local function getObjectData(tag)

    for _, object in pairs(Interactables:GetChildren()) do

        local objectData = ObjectsLibrary.GetObjectData(object.Name)

        if not objectData then continue end

        if objectData.Tags and table.find(objectData.Tags, tag) then

            return objectData, object
        end
    end
end

local function pickupPies(pieTag, list)

    local pieData, model = getObjectData(pieTag, list)

    if not pieData then return end
    if not model then return end

    for index, data in pairs(pieData) do
        if not model.Parent then continue end
        ClientRemotes.pickupObject.fire(model:GetAttribute("ObjectUUID"))
    end
end

local function dropAllItemsInStack()
    local activeSlot = InventoryModule.getActiveSlot()
    if activeSlot then
        local state = InventoryModule.getState()
        for i = 1, #state[activeSlot].storedObjects do
            ClientRemotes.dropObject.fire({})
        end
    end
end

--[[
local function refreshShopItemsList()

    for _, object in pairs(Interactables:GetChildren()) do
        if not object:GetAttribute("IsProduct") then continue end
        if table.find(ShopDropdown.options, object.Name) then continue end

        table.insert(ShopDropdown.options, object.Name)
    end

    ShopDropdown:Refresh(ShopDropdown.options)
end
]]

local function refreshWeaponList()

    if not KaWeaponDropdown then return end

    local options = {"None"}

    if HotbarGui and SlotsGui then

        for _, frame in pairs(SlotsGui:GetChildren()) do
            if frame:IsA("Frame") then

                local ImgButton = frame.Frame.ImageButton
                local SlotType = ImgButton:FindFirstChild("SlotType")

                if SlotType ~= nil and SlotType.Text == "Melee" then
                    local SlotName = ImgButton:FindFirstChild("Name")
                    if SlotName and not table.find(options, SlotName.Text) then
                        table.insert(options, SlotName.Text)
                    end
                end
            end
        end
    end

    KaWeaponDropdown:Refresh(options)
end

---------------------------------------------------------------
--- CONFIG SAVING / LOADING FUNCTIONS
---------------------------------------------------------------

local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			warn("Rayfield | Function failed with error: ", result)
			return false
		else
			return result
		end
	end
end

local function LoadConfiguration(configName)
    if not configName then return end
    return Window:Load(configName)
end

local function SaveConfiguration(fileName)
    if not fileName then return end
    return Window:Save(fileName)
end

local function refreshConfigList()
    local configs = Window:ListConfigs()
    ConfigDropdown:Refresh(configs)
    configs = nil
end

---------------------------------------------------------------
--- INIT / SHUTDOWN SCRIPT
---------------------------------------------------------------

local function shutdownScript(fullShutdown)

    for key, c in pairs(connections) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        elseif type(c) == "thread" then
            pcall(coroutine.close, c)
        end
        connections[key] = nil
    end

    getgenv().NoProjectileDamage = false
    getgenv().DropStack = false
    getgenv().NoRecoil = false

    ITEM_IDENTITY_TAGS = nil
    PROMPTIGNORELIST = nil

    if fullShutdown then
        Window:Unload()
    end
end

local function initScript()

    if isLobbyPlace then return end

    HotbarGui = plr.PlayerGui:FindFirstChild("Hotbar")
    SlotsGui = nil

    if HotbarGui then
        SlotsGui = HotbarGui:FindFirstChild("Slots")
    end

    FurnitureProducts = Stations:FindFirstChild("FurnitureStore"):FindFirstChild("Products")
    SkipDayPrompt = workspace.Stations.OpenSign.Switch.PromptAtt.SkipDayPrompt

    Mixer = Stations:FindFirstChild("Mixer") or Stations:FindFirstChild("AutoMixer")

    params.IncludeInstances = {Interactables}
    shopParams.IncludeInstances = {Stations}

    if not Monsters:FindFirstChild("EvilScientistBoss") and #game.Workspace.World.ScienceFacility.BossRoom.Environment.Back.Destroy2:GetChildren() <= 0 then
        canSkipNights = true
    end

    connections.plrGuiAddedConnection = plr.PlayerGui.ChildAdded:Connect(function(gui)
        if gui.Name == "Hotbar" and gui:FindFirstChild("Slots") then

            HotbarGui = gui
            SlotsGui = HotbarGui:FindFirstChild("Slots")

            connections.SlotsGuiAddedConnection = SlotsGui.ChildAdded:Connect(function(frame)
                local SlotType = frame.Frame.ImageButton:FindFirstChild("SlotType")
                if SlotType and SlotType.Text == "Melee" then
                    refreshWeaponList()
                end
            end)
            connections.SlotsGuiRemovedConnection = SlotsGui.ChildRemoved:Connect(function()
                refreshWeaponList()
            end)
        end
    end)
    connections.plrGuiRemovedConnection = plr.PlayerGui.ChildRemoved:Connect(function(gui)
        if gui.Name == "Hotbar" then
            HotbarGui = nil
            SlotsGui = nil
            if connections.SlotsGuiAddedConnection then
                connections.SlotsGuiAddedConnection:Disconnect()
                connections.SlotsGuiAddedConnection = nil
            end
            if connections.SlotsGuiRemovedConnection then
                connections.SlotsGuiRemovedConnection:Disconnect()
                connections.SlotsGuiRemovedConnection = nil
            end
        end
    end)

    if HotbarGui and SlotsGui then
        connections.SlotsGuiAddedConnection = SlotsGui.ChildAdded:Connect(function(gui)
            if gui:FindFirstChild("Frame") and gui:FindFirstChild("Frame"):FindFirstChild("ImageButton") then
                local SlotType = gui.Frame.ImageButton:FindFirstChild("SlotType")
                if SlotType and SlotType.Text == "Melee" then
                    refreshWeaponList()
                end
            end
        end)
        connections.SlotsGuiRemovedConnection = SlotsGui.ChildRemoved:Connect(function()
            refreshWeaponList()
        end)
    end

    --refreshShopItemsList()
    refreshWeaponList()
end


local Section = CombatTab:CreateSection({ name = "Combat" })

local KillAuraWeaponLabel = CreateLabel(CombatTab, "Kill Aura Weapon Slot: nil", 4483362458)

KaWeaponDropdown = CreateDropdown(CombatTab, {
    name = "Kill Aura Weapon (Weapon Overide)",
    options = {"None"},
    value = "None",
    multiSelect = false,
    flag = "AuraWeaponOveride", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Option)
        if Option == "None" or Option == nil then
            KillAuraWeaponOveride = nil
        else
            KillAuraWeaponOveride = Option
        end
    end,
})

local Toggle = CombatTab:CreateToggle({
   name = "Infinite Range (Overides Kill Aura Range)",
   value = false,
   flag = "InfRange", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   callback = function(Value)
    KillAuraInfiniteRange = Value
   end,
})

local Slider = CombatTab:CreateSlider({
   name = "Kill Aura Delay Time (IF YOURE LAGGY)",
   range = {0, 0.5},
   increment = 0.01,
   suffix = "Delay Time",
   value = KillAuraDelayTime,
   flag = "AuraDelay",
   callback = function(Value)
    KillAuraDelayTime = Value
   end,
})

local Slider = CombatTab:CreateSlider({
   name = "Kill Aura Range",
   range = {1, 300},
   increment = 1,
   suffix = "Distance",
   value = KillAuraRange,
   flag = "AuraRange", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   callback = function(Value)
    KillAuraRange = Value
   end,
})

local Toggle = CombatTab:CreateToggle({
    name = "Kill Aura (Must have melee weapon in hotbar)",
    value = false,
    flag = "KillAura", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)

        if connections.KillAuraCoroutine ~= nil then
            coroutine.close(connections.KillAuraCoroutine)
            connections.KillAuraCoroutine = nil
        end

        if Value then
            connections.KillAuraCoroutine = coroutine.create(function()
                while task.wait(KillAuraDelayTime) do
                    local SlotId = nil
                    if KillAuraWeaponOveride ~= nil then
                        SlotId = getItemSlot(KillAuraWeaponOveride)
                    else
                        SlotId = getItemSlot(nil, "Melee")
                    end

                    if CurrentKillAuraSlot ~= SlotId then
                        CurrentKillAuraSlot = tostring(SlotId)
                        KillAuraWeaponLabel:Set(tostring("Kill Aura Weapon Slot: "..CurrentKillAuraSlot))
                    end
                    if tonumber(SlotId) then
                        for _, mob in pairs(Monsters:GetChildren()) do
                            if mob:FindFirstChild("HumanoidRootPart")then
                                if KillAuraInfiniteRange then
                                    ClientRemotes.meleeAttack.fire({
                                        monsters = {mob},
                                        civilians = {},
                                        activeSlot = tonumber(SlotId)
                                    })
                                else
                                    local distance = (plr.Character.HumanoidRootPart.Position - mob:FindFirstChild("HumanoidRootPart").Position).Magnitude
                                    if distance <= KillAuraRange then
                                        ClientRemotes.meleeAttack.fire({
                                            monsters = {mob},
                                            civilians = {},
                                            activeSlot = tonumber(SlotId)
                                        })
                                    end
                                end
                                --[[
                                if KillAuraDelayTime > 0 then
                                    task.wait(KillAuraDelayTime)
                                end
                                ]]
                            end
                        end
                    end
                end
            end)
            coroutine.resume(connections.KillAuraCoroutine)
        end
    end,
})

local Section = CombatTab:CreateSection({ name = "No Damage Stuff" })

local Toggle = CombatTab:CreateToggle({
    name = "No Projectile Damage",
    value = false,
    flag = "ProjectileDmg",
    callback = function(Value)
        getgenv().NoProjectileDamage = Value

        if isLobbyPlace then return end

        if getgenv().hitByProjectileHook == nil then
            getgenv().hitByProjectileHook = hookfunction(ClientRemotes.hitByProjectile.fire, function(self)
                if getgenv().NoProjectileDamage == true then
                    self = nil
                end
                return getgenv().hitByProjectileHook(self)
            end)
        end
    end,
})

local Section = CombatTab:CreateSection({ name = "Gun Mods" })

local Label = CreateLabel(CombatTab, "Re-equip weapon to apply mods", 4483362458)

local Toggle = CombatTab:CreateToggle({
    name = "No Recoil",
    value = false,
    flag = "NoRecoil", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if isLobbyPlace then return end
        if not CameraModule then return end
        getgenv().NoRecoil = Value
        if getgenv().recoilHook == nil then
            CameraModule = require(game.ReplicatedStorage.Client.Systems.CharacterController.Camera)
            getgenv().recoilHook = hookfunction(CameraModule.recoil, function(self, args)

                if getgenv().NoRecoil then
                    return
                end

                return getgenv().recoilHook(self, args)
            end)
        end
    end,
})

local Toggle = CombatTab:CreateToggle({
    name = "Infinite Ammo",
    value = false,
    flag = "InfiniteAmmo", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if isLobbyPlace then return end
        for _, object in pairs(ObjectsLibrary.Objects) do
            local success, errormsg = pcall(function()
                object.getPrefab()
            end)

            if not success then continue end

            local objectName = tostring(object.getPrefab())
            local state = ObjectsLibrary.Objects[objectName]
            if not state then continue end
            if not state.ReloadDuration then continue end

            if Value then
                if not originalWeaponValues[objectName] then
                    originalWeaponValues[objectName] = {}
                    originalWeaponValues[objectName].ReloadDuration = state.ReloadDuration
                elseif not originalWeaponValues[objectName].ReloadDuration then
                    originalWeaponValues[objectName].ReloadDuration = state.ReloadDuration
                end
                state.ReloadDuration = 0
            else
                if not originalWeaponValues[objectName] then continue end
                if not originalWeaponValues[objectName].ReloadDuration then continue end
                state.ReloadDuration = originalWeaponValues[objectName].ReloadDuration
            end
        end
    end,
})

local Toggle = CombatTab:CreateToggle({
    name = "Force Auto",
    value = false,
    flag = "ForceAuto", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if isLobbyPlace then return end
        for _, object in pairs(ObjectsLibrary.Objects) do
        local success, errormsg = pcall(function()
                object.getPrefab()
            end)

            if not success then continue end

            local objectName = tostring(object.getPrefab())
            local state = ObjectsLibrary.Objects[objectName]
            if not state then continue end
            if not state.Mode then continue end
            if Value then
                if state.Mode == "Auto" then continue end
                if not originalWeaponValues[objectName] then
                    originalWeaponValues[objectName] = {}
                    originalWeaponValues[objectName].Mode = state.Mode
                    elseif not originalWeaponValues[objectName].Mode then
                        originalWeaponValues[objectName].Mode = state.Mode
                end
                state.Mode = "Auto"
            else
                if not originalWeaponValues[objectName] then continue end
                if not originalWeaponValues[objectName].Mode then continue end
                state.Mode = originalWeaponValues[objectName].Mode
            end
        end
    end,
})

local Toggle = CombatTab:CreateToggle({
    name = "Fire Rate (TOGGLE THIS TO ACTIVATE FIRERATE)",
    value = false,
    flag = "FireRateToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        CanModifyFirerate = Value
        if isLobbyPlace then return end
        for _, object in pairs(ObjectsLibrary.Objects) do
            local success, errormsg = pcall(function()
                object.getPrefab()
            end)

            if not success then continue end

            local objectName = tostring(object.getPrefab())
            local state = ObjectsLibrary.Objects[objectName]

            if not state then continue end
            if not state.FireRate then continue end

            if CanModifyFirerate then
                if not originalWeaponValues[objectName] then
                    originalWeaponValues[objectName] = {}
                    originalWeaponValues[objectName].FireRate = state.FireRate
                elseif not originalWeaponValues[objectName].FireRate then
                    originalWeaponValues[objectName].FireRate = state.FireRate
                end
                state.FireRate = ModifiedFirerate
            else
                if not originalWeaponValues[objectName] then continue end
                if not originalWeaponValues[objectName].FireRate then continue end
                state.FireRate = originalWeaponValues[objectName].FireRate
            end
        end
    end,
})

local Slider = CombatTab:CreateSlider({
    name = "Fire Rate",
    range = {0, 1},
    increment = .1,
    suffix = "Fire Rate",
    value = ModifiedFirerate,
    flag = "FireRate", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        ModifiedFirerate = Value
        if isLobbyPlace then return end
        if CanModifyFirerate then
            for _, object in pairs(ObjectsLibrary.Objects) do

               local success, errormsg = pcall(function()
                    object.getPrefab()
                end)

                if not success then continue end

                local objectName = tostring(object.getPrefab())
                local state = ObjectsLibrary.Objects[objectName]

                if not state then continue end
                if not state.FireRate then continue end

                state.FireRate = ModifiedFirerate
            end
        end
   end,
})

local Section = CombatTab:CreateSection({ name = "Melee" })

local Label = CreateLabel(CombatTab, "Re-equip weapon to apply mods", 4483362458)

local Toggle = CombatTab:CreateToggle({
    name = "No melee hit cooldown",
    value = false,
    flag = "NoMeleeCooldown", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if isLobbyPlace then return end
        for _, object in pairs(ObjectsLibrary.Objects) do
            local success, errormsg = pcall(function()
                object.getPrefab()
            end)

            if not success then continue end

            local objectName = tostring(object.getPrefab())
            local state = ObjectsLibrary.Objects[objectName]
            if not state then continue end
            if not state.AttackDebounce then continue end

            if Value then
                if not originalWeaponValues[objectName] then
                    originalWeaponValues[objectName] = {}
                    originalWeaponValues[objectName].AttackDebounce = state.AttackDebounce
                elseif not originalWeaponValues[objectName].AttackDebounce then
                    originalWeaponValues[objectName].AttackDebounce = state.AttackDebounce
                end
                state.AttackDebounce = 0
            else
                if not originalWeaponValues[objectName] then continue end
                if not originalWeaponValues[objectName].AttackDebounce then continue end
                state.AttackDebounce = originalWeaponValues[objectName].AttackDebounce
            end
        end
    end,
})

--[[
local Section = AutofarmTab:CreateSection({ name = "Auto Roll" })

local CrateDropdown = CreateDropdown(AutofarmTab, {
    name = "Crate",
    options = {"Option 1", "Option 2"},
    value = nil,
    multiSelect = true,
    flag = "Dropdown1",
    callback = function(Options)
    end,
})

local CrateDropdown = CreateDropdown(AutofarmTab, {
    name = "Currency",
    options = {"Nuggets", "Coins"},
    value = nil,
    multiSelect = false,
    flag = "Dropdown1",
    callback = function(Options)
    end,
})

local RollTimeSlider = AutofarmTab:CreateSlider({
    name = "Roll Time",
    range = {0, 1},
    increment = .1,
    suffix = "Time between rolls",
    value = 0.5,
    flag = "RollTime",
    callback = function(Value)

    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Roll",
    value = false,
    flag = "AutoRoll",
    callback = function(Value)
        if not isLobbyPlace then return end

        if connections.AutoRoll ~= nil then
            coroutine.close(connections.AutoRoll)
            connections.AutoRoll = nil
        end

        if Value then

            connections.AutoRoll = coroutine.create(function()
                while task.wait(RollTimeSlider.value) do
                    for _, crate in pairs(CrateDropdown) do

                        ClientRemotes.lobby.openCase.fire({
                            currency = "nuggets",
                            caseId = "EliteCase"
                        })

                    end
                end
            end)

            coroutine.resume(connections.AutoRoll)
        end
   end,
})
]]

local Section = AutofarmTab:CreateSection({ name = "Auto Skip Day" })

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Skip Day",
    value = false,
    flag = "SkipDay",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoSkipDay ~= nil then
            coroutine.close(connections.AutoSkipDay)
            connections.AutoSkipDay = nil
        end

        if Value then
            connections.AutoSkipDay = coroutine.create(function()
                local skippingDay = false
                while task.wait(1) do
                    if not canSkipNights then
                        if not Monsters:FindFirstChild("EvilScientistBoss") and #game.Workspace.World.ScienceFacility.BossRoom.Environment.Back.Destroy2:GetChildren() == 0 then
                            canSkipNights = true
                        end
                        continue
                    end
                    local currentState
                    if not DayNightClient then
                        if game.Workspace.Lighting.ClockTime ~= 0 then
                            currentState = "Day"
                        end
                    else
                        currentState = DayNightClient.getCurrentState().phase
                    end

                    if not skippingDay and canSkipNights and currentState == "Day" and not TeleportDebounce then
                        skippingDay = true
                        local originalCFrame = plr.Character.HumanoidRootPart.CFrame
                        repeat
                            plr.Character.HumanoidRootPart:PivotTo(CFrame.new(-31.6075058, 51.5765266, 87.6397552, 0.999986291, 0, -0.00523759052, 0, 1, 0, 0.00523759052, 0, 0.999986291))
                            fireproximityprompt(SkipDayPrompt)
                            task.wait(0.1)
                        until not SkipDayPrompt.Enabled
                        plr.Character.HumanoidRootPart:PivotTo(originalCFrame)
                        skippingDay = false
                    end
                end
            end)
            coroutine.resume(connections.AutoSkipDay)
        end
   end,
})

local Section = AutofarmTab:CreateSection({ name = "Misc Auto" })

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Repair",
    value = false,
    flag = "AutoRepair",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoRepair ~= nil then
            coroutine.close(connections.AutoRepair)
            connections.AutoRepair = nil
        end

        if Value then
            connections.AutoRepair = coroutine.create(function()
                while task.wait(0.1) do
                    for index, barrier in pairs(Defenses:GetChildren()) do
                        if barrier:FindFirstChildWhichIsA("Part") then
                            local SlotId = getItemSlot(nil, "Repair Tool")
                            if tonumber(SlotId) then
                                ClientRemotes.repairSwing.fire({
                                    activeSlot = tonumber(SlotId),
                                    defenses = {barrier:FindFirstChildWhichIsA("Part")},
                                    monsters = {}
                                })
                            end
                        end
                    end
                end
            end)
            coroutine.resume(connections.AutoRepair)
        end

    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Pickup Blueprints (Every 15 seconds)",
    value = false,
    flag = "PickupBlueprints",
    callback = function(Value)
    if isLobbyPlace then return end

        if connections.AutoPickupBlueprints ~= nil then
            coroutine.close(connections.AutoPickupBlueprints)
            connections.AutoPickupBlueprints = nil
        end

        if Value then
            connections.AutoPickupBlueprints = coroutine.create(function()
                while task.wait(15) do
                    if TeleportDebounce then continue end
                    local originalCFrame = plr.Character.HumanoidRootPart.CFrame
                    for _, blueprint in pairs(game.Workspace:GetChildren()) do
                        if blueprint.Name == "Blueprint" then
                            plr.Character.HumanoidRootPart:PivotTo(blueprint.PrimaryPart.CFrame)
                            task.wait(0.2)
                            fireproximityprompt(blueprint.Blueprint.ProximityPrompt)
                            task.wait(0.25)
                        end
                    end
                    plr.Character.HumanoidRootPart:PivotTo(originalCFrame)
                end
            end)
            coroutine.resume(connections.AutoPickupBlueprints)
        end
    end,
})

local Section = AutofarmTab:CreateSection({ name = "Autofarm Pies" })

local Toggle = AutofarmTab:CreateToggle({
    name = "Ignore Explosive Ingredients",
    value = false,
    flag = "IgnoreBombIngredients",
    callback = function(Value)
        IgnoreBombIngredients = Value
    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Pickup Ingredients",
    value = false,
    flag = "PickupIngredients",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoPickupIngredients ~= nil then
            coroutine.close(connections.AutoPickupIngredients)
            connections.AutoPickupIngredients = nil
        end

        if Value then
            connections.AutoPickupIngredients = coroutine.create(function()
                while task.wait(0.1) do

                    for _, item in pairs(Interactables:GetChildren()) do
                        if item:GetAttribute("ObjectUUID") == nil then continue end
                        local ObjectInfo = ObjectsLibrary.Objects[item.Name]
                        if ObjectInfo == nil then continue end
                        if not ObjectInfo.Tags then continue end
                        if not table.find(ObjectInfo.Tags, "Ingredient") then continue end

                        if IgnoreBombIngredients then
                            if table.find(ObjectInfo.Tags, "Explosive") or table.find(ObjectInfo.Tags, "ExplosiveMine") then
                                continue
                            end
                        end

                        if not Mixer then
                            Mixer = Stations:FindFirstChild("Mixer") or Stations:FindFirstChild("AutoMixer")
                            continue
                        end

                        local parts = game.Workspace:GetPartsInPart(Mixer.PrimaryPart, params)

                        local items = {}

                        for _, v in pairs(parts) do
                            if not table.find(items, v.Parent:GetAttribute("ObjectUUID")) then
                                table.insert(items, v.Parent:GetAttribute("ObjectUUID"))
                            end
                        end

                        if not table.find(items, item:GetAttribute("ObjectUUID")) then
                            ClientRemotes.pickupObject.fire(item:GetAttribute("ObjectUUID"))
                        end

                        items = nil

                    end

                end
            end)
            coroutine.resume(connections.AutoPickupIngredients)
        end
    end,
})

local IngredientAmountSlider = AutofarmTab:CreateSlider({
    name = "Required Ingredients Amount",
    range = {1, 6},
    increment = 1,
    suffix = "Amount",
    value = 6,
    flag = "IngredientAmount",
    callback = function(Value)
    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Make Pies",
    value = false,
    flag = "MakePies",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoMakePies ~= nil then
            coroutine.close(connections.AutoMakePies)
            connections.AutoMakePies = nil
        end

        if Value then
            connections.AutoMakePies = coroutine.create(function()

                while task.wait(0.1) do

                    if not Mixer then
                        Mixer = Stations:FindFirstChild("Mixer") or Stations:FindFirstChild("AutoMixer")
                        continue
                    end

                    local dist = (plr.Character.HumanoidRootPart.Position - Mixer.PrimaryPart.Position).Magnitude

                    local SlotId, ItemName = getItemSlot(nil, "Ingredient")

                    local parts = game.Workspace:GetPartsInPart(Mixer.PrimaryPart, params)

                    local items = {}

                    for _, v in pairs(parts) do
                        if not table.find(items, v.Parent:GetAttribute("ObjectUUID")) then
                            table.insert(items, v.Parent:GetAttribute("ObjectUUID"))
                        end
                    end

                    if SlotId and ItemName then
                        if #items < 6 then
                            local NewName = string.gsub(ItemName, "%s+", "")
                            local ObjectInfo = ObjectsLibrary.Objects[NewName]

                            if ObjectInfo == nil then
                                for _, objInfo in pairs(ObjectsLibrary.Objects) do
                                    if not objInfo.DisplayName then continue end
                                    if objInfo.DisplayName == ItemName then
                                        ObjectInfo = objInfo
                                    end
                                end
                            end

                            if ObjectInfo and ObjectInfo.Tags then
                                if table.find(ObjectInfo.Tags, "Ingredient") then
                                    if IgnoreBombIngredients then
                                        if table.find(ObjectInfo.Tags, "Explosive") or table.find(ObjectInfo.Tags, "ExplosiveMine") then
                                            continue
                                        end
                                    end
                                    ClientRemotes.switchSlot.fire(tonumber(SlotId))
                                    ClientRemotes.dropObject.fire({
                                        objectDeposit = Mixer.ObjectDeposit
                                    })
                                end
                            end
                        end
                    end

                    if #items >= IngredientAmountSlider.value then
                        if Mixer then
                            if not MixerPrompt then
                                for _, prompt in pairs(Mixer:GetDescendants()) do
                                    if prompt:IsA("ProximityPrompt") then
                                        MixerPrompt = prompt
                                        break
                                    end
                                end
                            end
                            fireproximityprompt(MixerPrompt)
                        end
                    end

                    items = nil

                end
            end)
            coroutine.resume(connections.AutoMakePies)
        end

    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Bake Pies",
    value = false,
    flag = "BakePies",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoBakePies ~= nil then
            coroutine.close(connections.AutoBakePies)
            connections.AutoBakePies = nil
        end

        if Value then
            connections.AutoBakePies = coroutine.create(function()
                while task.wait(0.1) do
                    pickupPies("Raw")
                    local SlotId = getItemSlot(nil, "Raw Good")
                    if tonumber(SlotId) then
                        local Oven = game.Workspace.Stations:FindFirstChild("Oven") or game.Workspace.Stations:FindFirstChild("UpgradedOven")
                        if Oven then
                            ClientRemotes.switchSlot.fire(tonumber(SlotId))
                            ClientRemotes.dropObject.fire({
                                objectDeposit = Oven.ObjectDeposit
                            })
                        end
                    end
                end
            end)
            coroutine.resume(connections.AutoBakePies)
        end

    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Sell Pies",
    value = false,
    flag = "SellPies",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoSellPies ~= nil then
            coroutine.close(connections.AutoSellPies)
            connections.AutoSellPies = nil
        end

        if Value then
            connections.AutoSellPies = coroutine.create(function()
                while true do
                    pickupPies("BakedGood")
                    local SlotId = getItemSlot(nil, "Baked Good")
                    if tonumber(SlotId) then
                        ClientRemotes.switchSlot.fire(tonumber(SlotId))
                        for _, SellStand in pairs(Stations:GetChildren()) do
                            if SellStand.Name ~= "SellStand" then continue end
                            ClientRemotes.dropObject.fire({
                                objectDeposit = SellStand.ObjectDeposit
                            })
                            task.wait(0.2)
                        end
                    end
                    task.wait(0.1)
                end
            end)
            coroutine.resume(connections.AutoSellPies)
        end
    end,
})

local Section = AutofarmTab:CreateSection({ name = "Autofarm Corpses" })

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Pickup Corpses",
    value = false,
    flag = "PickupCorpses",
    callback = function(Value)
    if isLobbyPlace then return end

        if connections.AutoPickupCorpses ~= nil then
            coroutine.close(connections.AutoPickupCorpses)
            connections.AutoPickupCorpses = nil
        end

        if Value then
            connections.AutoPickupCorpses = coroutine.create(function()

                while task.wait(0.1) do

                    local data, model = getObjectData("Corpse")

                    if not model then continue end
                    if not model.Parent then continue end

                    ClientRemotes.pickupObject.fire(model:GetAttribute("ObjectUUID"))

                end
            end)
            coroutine.resume(connections.AutoPickupCorpses)
        end

    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Grind Corpses",
    value = false,
    flag = "GrindCorpses",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoGrindCorpses ~= nil then
            coroutine.close(connections.AutoGrindCorpses)
            connections.AutoGrindCorpses = nil
        end

        if Value then
            connections.AutoGrindCorpses = coroutine.create(function()
                while task.wait(0.1) do
                    local SlotId = getItemSlot(nil, "Corpse")
                    if tonumber(SlotId) then
                        ClientRemotes.switchSlot.fire(tonumber(SlotId))
                        task.wait()
                        ClientRemotes.dropObject.fire({
                            objectDeposit = Stations.Grinder.ObjectDeposit
                        })
                    end
                end
            end)
            coroutine.resume(connections.AutoGrindCorpses)
        end
    end,
})

local Section = AutofarmTab:CreateSection({ name = "Autofarm Items" })

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Pickup Grindable Items",
    value = false,
    flag = "PickupGItems",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoPickupGrindables ~= nil then
            coroutine.close(connections.AutoPickupGrindables)
            connections.AutoPickupGrindables = nil
        end

        if Value then
            connections.AutoPickupGrindables = coroutine.create(function()

                while task.wait(0.1) do

                    local data, model = getObjectData("CraftingPart")

                    if not data then continue end
                    if not model then continue end
                    if not model.Parent then continue end

                    ClientRemotes.pickupObject.fire(model:GetAttribute("ObjectUUID"))
                end
            end)
            coroutine.resume(connections.AutoPickupGrindables)
        end
    end,
})

local Toggle = AutofarmTab:CreateToggle({
    name = "Auto Grind Items",
    value = false,
    flag = "GrindItems",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoGrindItems ~= nil then
            coroutine.close(connections.AutoGrindItems)
            connections.AutoGrindItems = nil
        end

        if Value then
            connections.AutoGrindItems = coroutine.create(function()
                while task.wait(0.1) do
                    local SlotId = getItemSlot(nil, "Crafting Part")
                    if tonumber(SlotId) then
                        ClientRemotes.switchSlot.fire(tonumber(SlotId))
                        ClientRemotes.dropObject.fire({
                            objectDeposit = Stations.BlueprintsTable.ObjectDeposit
                        })
                    end
                end
            end)
            coroutine.resume(connections.AutoGrindItems)
        end
    end,
})

local Section = ItemsTab:CreateSection({ name = "Unlock/Opening" })

local Button = ItemsTab:CreateButton({
    name = "Unlock Raygun",
    callback = function()
        if isLobbyPlace then return end

        local Raygun = workspace.World.ScienceFacility:FindFirstChild("Raygun")
        if Raygun then
            if TeleportDebounce == false then
                TeleportDebounce = true
                local originalCFrame = plr.Character.HumanoidRootPart.CFrame
                plr.Character.HumanoidRootPart:PivotTo(workspace.World.ScienceFacility.Raygun.PrimaryPart.CFrame)
                task.wait(0.2)
                fireproximityprompt(workspace.World.ScienceFacility.Raygun.Handle.ProximityPrompt)
                task.wait(0.25)
                plr.Character.HumanoidRootPart:PivotTo(originalCFrame)
                TeleportDebounce = false
            end
        end
    end,
})

local Button = ItemsTab:CreateButton({
    name = "Open All Chest",
    callback = function()
        if isLobbyPlace then return end
        if connections.AutoOpenAllChest ~= nil then return end

        if TeleportDebounce == false then
            TeleportDebounce = true
            connections.AutoOpenAllChest = coroutine.create(function()
                originalcf = plr.Character.HumanoidRootPart.CFrame
                for _, container in pairs(Containers:GetChildren()) do
                    if table.find(PROMPTIGNORELIST, container.Name) then continue end
                    local prompt = container.PrimaryPart:FindFirstChildWhichIsA("ProximityPrompt")
                    if prompt then
                        if prompt.Enabled then
                            repeat
                                local objSize = container:GetExtentsSize()
                                plr.Character.HumanoidRootPart:PivotTo(CFrame.new(container.PrimaryPart.Position + Vector3.new(0, objSize.Y / 2, 0)))
                                --plr.Character.HumanoidRootPart:PivotTo(container.PrimaryPart.CFrame)
                                task.wait(0.2)
                                fireproximityprompt(prompt)
                            until prompt.Enabled == false
                            plr.Character.HumanoidRootPart:PivotTo(originalcf)
                        end
                    end
                end
                TeleportDebounce = false
                connections.AutoOpenAllChest = nil
            end)
            coroutine.resume(connections.AutoOpenAllChest)
        end
    end,
})

local Button = ItemsTab:CreateButton({
    name = "Stop Opening Chest",
    callback = function()
        if isLobbyPlace then return end
        if connections.AutoOpenAllChest ~= nil then
            coroutine.close(connections.AutoOpenAllChest)
            connections.AutoOpenAllChest = nil
            TeleportDebounce = false
            plr.Character.HumanoidRootPart:PivotTo(originalcf)
        end
    end,
})

local Section = ItemsTab:CreateSection({ name = "Inventory Stuff" })

local Toggle = ItemsTab:CreateToggle({
    name = "Drop Entire Stack (Drops entire stack of item instead of 1)",
    value = false,
    flag = "DropStack",
    callback = function(Value)
        getgenv().DropStack = Value

        if isLobbyPlace then return end

        if getgenv().dropItemHook == nil then

            getgenv().dropItemHook = hookfunction(InventoryModule.dropObject, function(self, args)

                if getgenv().DropStack then
                    dropAllItemsInStack()
                end

                return getgenv().dropItemHook(self, args)
            end)
        end
    end,
})

local Section = ItemsTab:CreateSection({ name = "World" })

local Toggle = ItemsTab:CreateToggle({
    name = "Instant Proximity Prompts",
    value = false,
    flag = "InstantPrompts", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if Value then
            if connections.promptAddedConnection == nil then
                connections.promptAddedConnection = game.DescendantAdded:Connect(function(prompt)
                    if prompt:IsA("ProximityPrompt") then
                        prompt.HoldDuration = 0
                    end
                end)
            end
            for _, prompt in pairs(game:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    prompt.HoldDuration = 0
                end
            end
        else
            if connections.promptAddedConnection then
                connections.promptAddedConnection:Disconnect()
                connections.promptAddedConnection = nil
            end
        end
    end,
})

if not isLobbyPlace then
    local Section = ItemsTab:CreateSection({ name = "Codes" })
    if game.Workspace:GetAttribute("RaygunCode") then
        local Label = CreateLabel(ItemsTab, tostring("Raygun Code "..game.Workspace:GetAttribute("RaygunCode")), 4483362458)
    end
    if game.Workspace:GetAttribute("BankVaultCode") then
        local Label = CreateLabel(ItemsTab, tostring("Bank Code "..game.Workspace:GetAttribute("BankVaultCode")), 4483362458)
    end
    if game.Workspace:GetAttribute("GateCode") then
        local Label = CreateLabel(ItemsTab, tostring("Gate Code "..game.Workspace:GetAttribute("GateCode")), 4483362458)
    end
end

local Section = ItemsTab:CreateSection({ name = "Bring Stuff" })

local Button = ItemsTab:CreateButton({
    name = "Bring All Corpses",
    callback = function()
        if Interactables then
            for _, mob in pairs(Interactables:GetChildren()) do
                if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
                    mob.HumanoidRootPart.Anchored = false
                    mob:PivotTo(plr.Character.HumanoidRootPart.CFrame)
                end
            end
        end
    end,
})

ItemsDropdown = CreateDropdown(ItemsTab, {
    name = "Item Sorting",
    options = {"All", "Metal", "Wood", "Heals", "Drinks", "Food", "Ammo", "Gun", "Melee"},
    value = {},
    multiSelect = true,
    callback = function(Options)
    end,
})

local Input = ItemsTab:CreateInput({
    name = "Bring Time (Time before next item is brought)",
    value = "0",
    placeholder = "Time",
    clearOnFocus = false,
    flag = "BringTime",
    callback = function(Text)
        if tonumber(Text) then
            BringAllItemsTime = tonumber(Text)
        end
    end,
})

local Button = ItemsTab:CreateButton({
    name = "Stop Bring",
    callback = function()
        if connections.BringAllItemsThread then
            task.cancel(connections.BringAllItemsThread)
            connections.BringAllItemsThread = nil
        end
    end,
})

local Button = ItemsTab:CreateButton({
    name = "Bring All Items (Select Items from Item Sorting Dropdown)",
    callback = function()
        if Interactables then
            connections.BringAllItemsThread = task.spawn(function()

                if not ItemsDropdown.value[1] then return end

                for _, object in pairs(Interactables:GetChildren()) do

                    local objectData = ObjectsLibrary.GetObjectData(object.Name)

                    if object:GetAttribute("IsProduct") then continue end

                    if objectData and (objectData.Tags) then

                        local teleportObject = false

                        for _, v in pairs(objectData.Tags) do
                            local tag = ITEM_IDENTITY_TAGS[v]
                            if not tag then continue end
                            if table.find(ItemsDropdown.value, tag) or table.find(ItemsDropdown.value, "All") then
                                teleportObject = true
                                continue
                            end
                        end

                        if not teleportObject and objectData.Resources then
                            for name, amount in pairs(objectData.Resources) do
                                local tag = ITEM_IDENTITY_TAGS[name]
                                if not tag then continue end
                                if table.find(ItemsDropdown.value, tag) or table.find(ItemsDropdown.value, "All") then
                                    teleportObject = true
                                    continue
                                end
                            end
                        end

                        if teleportObject then
                            object:PivotTo(plr.Character.HumanoidRootPart.CFrame)
                        end
                    end
                end

            end)
        end
    end,
})

local Section = PlayerTab:CreateSection({ name = "Player" })

local Slider = PlayerTab:CreateSlider({
    name = "Walk Speed",
    range = {16, 200},
    increment = 1,
    suffix = "Walk Speed",
    value = 16,
    flag = "WalkSpeed", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if plr.Character then
            if plr.Character:FindFirstChild("Humanoid") then
                plr.Character:FindFirstChild("Humanoid").WalkSpeed = Value
            end
        end
    end,
})

local Slider = PlayerTab:CreateSlider({
    name = "Jump Power",
    range = {7, 200},
    increment = 1,
    suffix = "Jump Power",
    value = 7,
    flag = "JumpPower", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if plr.Character then
            if plr.Character:FindFirstChild("Humanoid") then
                plr.Character:FindFirstChild("Humanoid").JumpHeight = Value
                plr.Character:FindFirstChild("Humanoid").JumpPower = Value
            end
        end
    end,
})

local Slider = PlayerTab:CreateSlider({
    name = "Hip Height",
    range = {0, 200},
    increment = 1,
    suffix = "Hip Height",
    value = 0,
    flag = "HipHeight", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    callback = function(Value)
        if plr.Character then
            if plr.Character:FindFirstChild("Humanoid") then
                plr.Character:FindFirstChild("Humanoid").HipHeight = Value
                plr.Character:FindFirstChild("Humanoid").HipHeight = Value
            end
        end
    end,
})

local Section = VisualsTab:CreateSection({ name = "Performance" })

local Toggle = VisualsTab:CreateToggle({
    name = "Full Bright",
    value = false,
    flag = "FullBright",
    callback = function(Value)

        if connections.FullBrightConnection ~= nil then
            connections.FullBrightConnection:Disconnect()
            connections.FullBrightConnection = nil
            if not oldLighting then return end
            game.Lighting.Ambient = oldLighting
            oldLighting = nil
        end

        if Value then
            connections.FullBrightConnection = game.Lighting.Changed:Connect(function(c)
                if c ~= "Ambient" then return end
                if game.Lighting.Ambient == Color3.fromRGB(255,255,255) then return end

                oldLighting = game.Lighting.Ambient
                game.Lighting.Ambient = Color3.fromRGB(255,255,255)
            end)
            oldLighting = game.Lighting.Ambient
            game.Lighting.Ambient = Color3.fromRGB(255,255,255)
        end
    end,
})

local Toggle = VisualsTab:CreateToggle({
    name = "Soft Lighting (Helps alot with fps)",
    value = false,
    flag = "SoftLighting",
    callback = function(Value)
        if Value then
            game.Lighting.LightingStyle = "Soft"
        else
            game.Lighting.LightingStyle = "Realistic"
        end
    end,
})

local Toggle = VisualsTab:CreateToggle({
    name = "No Shadows",
    value = false,
    flag = "Shadows",
    callback = function(Value)
        if Value then
            game.Lighting.GlobalShadows = false
        else
            game.Lighting.GlobalShadows = true
        end
    end,
})

local Toggle = VisualsTab:CreateToggle({
    name = "Prioritize Lighting Quality",
    value = false,
    flag = "LightingQuality",
    callback = function(Value)
        if Value then
            game.Lighting.PrioritizeLightingQuality = false
        else
            game.Lighting.PrioritizeLightingQuality = true
        end
    end,
})

local Toggle = VisualsTab:CreateToggle({
    name = "Low Graphics (Cannot Undo)",
    value = false,
    flag = "LowGraphics",
    callback = function(Value)

        if connections.LowGraphicsConnection ~= nil then
            connections.LowGraphicsConnection:Disconnect()
            connections.LowGraphicsConnection = nil
        end

        if Value then
            connections.LowGraphicsConnection = game.Workspace.ChildAdded:Connect(function(part)
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.SmoothPlastic
                end
            end)
            for _, part in pairs(game.Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.SmoothPlastic
                end
            end
        end
    end,
})

local Section = TeleportTab:CreateSection({ name = "Teleport Places" })

local Button = TeleportTab:CreateButton({
    name = "Diner",
    callback = function()
        plr.Character.HumanoidRootPart:PivotTo(CFrame.new(-25.4952583, 51.5765266, 113.329155, 0.999390781, 0, -0.0349008106, 0, 1, 0, 0.0349008106, 0, 0.999390781))
    end,
})

local Section = TeleportTab:CreateSection({ name = "Shop" })

local Button = TeleportTab:CreateButton({
   name = "Gunsmith",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(-2.86344862, 52.5618553, -44.8382301, 0.99955982, 3.85610441e-08, -0.0296673011, -3.96685529e-08, 1, -3.67423532e-08, 0.0296673011, 3.79030389e-08, 0.99955982))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "General Store",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(-45.5317917, 52.7282677, -39.9384003, 0.99999845, 5.68280356e-08, 0.00174740492, -5.67526044e-08, 1, -4.32155396e-08, -0.00174740492, 4.31163052e-08, 0.99999845))
   end,
})

local Section = TeleportTab:CreateSection({ name = "Sewer" })

local Button = TeleportTab:CreateButton({
   name = "Sewer Entrace",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(4.73190546, 50.9999886, 224.72876, 0.00350446557, 5.82111532e-08, -0.999993861, -6.93240931e-09, 1, 5.81872186e-08, 0.999993861, 6.72845157e-09, 0.00350446557))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Sewer Boss Entrance",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(124.220787, 19.3403263, 381.808533, -0.0261552893, 2.20136407e-08, 0.999657869, 9.82992576e-10, 1, -2.19954561e-08, -0.999657869, 4.0735873e-10, -0.0261552893))
   end,
})

local Section = TeleportTab:CreateSection({ name = "Buildings" })

local Button = TeleportTab:CreateButton({
   name = "Farm",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(-204.322388, 51.9999886, 325.71344, -0.999701262, 2.04478177e-08, 0.0244425517, 2.02537702e-08, 1, -8.18648527e-09, -0.0244425517, -7.68898545e-09, -0.999701262))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Hospital Entrance",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(-432.749451, 50.9999886, 26.5814838, 0.99955982, 4.50539162e-09, -0.0296678878, -7.5755775e-09, 1, -1.03372734e-07, 0.0296678878, 1.03551983e-07, 0.99955982))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Hospital Inside",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(-407.410767, 51.9601974, -17.6847801, 0.999193907, -1.77343846e-08, -0.0401440375, 2.21213412e-08, 1, 1.08836211e-07, 0.0401440375, -1.09636524e-07, 0.999193907))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Gas Station",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(605.598328, 51.140892, 128.689407, -0.745464265, 4.55767646e-09, -0.66654563, -1.66282152e-08, 1, 2.54347423e-08, 0.66654563, 3.00441556e-08, -0.745464265))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Warehouse",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(595.51593, 51.299984, -178.209183, -0.034901619, 3.68586264e-08, -0.999390781, -4.94374675e-08, 1, 3.86075953e-08, 0.999390781, 5.07548137e-08, -0.034901619))
   end,
})

local Section = TeleportTab:CreateSection({ name = "Bank" })

local Button = TeleportTab:CreateButton({
   name = "Bank Entrance",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(947.820374, 51.1499901, -127.2257, 0.0139589133, -1.09914893e-07, -0.999902546, 1.16175674e-08, 1, -1.0976342e-07, 0.999902546, -1.00842579e-08, 0.0139589133))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Bank Vault",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(1047.89075, 65.6000214, -152.643051, -0.99999404, 2.38245832e-08, 0.00344848656, 2.38440272e-08, 1, 5.59722135e-09, -0.00344848656, 5.67941383e-09, -0.99999404))
   end,
})

local Section = TeleportTab:CreateSection({ name = "Science Facility" })

local Button = TeleportTab:CreateButton({
   name = "Facility Entrance",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(462.922363, 51.1365395, -291.396637, 0.999657571, 4.01022948e-09, -0.0261680838, -4.62200012e-09, 1, -2.33180248e-08, 0.0261680838, 2.34309887e-08, 0.999657571))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Facility Boss Entrance",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(362.51178, 90.9593048, -410.928497, 0.0349235162, -4.46385471e-08, 0.999390006, 3.32030381e-09, 1, 4.45497683e-08, -0.999390006, 1.76244386e-09, 0.0349235162))
   end,
})

local Button = TeleportTab:CreateButton({
   name = "Raygun Room",
   callback = function()
    plr.Character.HumanoidRootPart:PivotTo(CFrame.new(454.691406, 54.4593163, -579.64679, 0.998135149, -7.96201576e-08, -0.0610427745, 8.49372626e-08, 1, 8.45098214e-08, 0.0610427745, -8.9537032e-08, 0.998135149))
   end,
})

local Section = SettingsTab:CreateSection({ name = "Config" })

ConfigDropdown = CreateDropdown(SettingsTab, {
   name = "Configs",
   options = Window:ListConfigs(),
   value = nil,
   multiSelect = false,
   callback = function(Options)
   end,
})

local Button = SettingsTab:CreateButton({
    name = "Refresh List",
    callback = function()
        refreshConfigList()
    end,
})

local Button = SettingsTab:CreateButton({
    name = "Delete Config",
    callback = function()
        local selected = ConfigDropdown.value[1]
        if selected then
            Window:DeleteConfig(selected)
            task.wait()
            refreshConfigList()
        end
    end,
})

local Button = SettingsTab:CreateButton({
    name = "Load Config",
    callback = function()
        local selected = ConfigDropdown.value[1]
        if selected then
            LoadConfiguration(selected)
        else
            warn("Config system issue")
        end
    end,
})

local Input = SettingsTab:CreateInput({
    name = "Config Name",
    value = "",
    placeholder = "Configuration Name",
    clearOnFocus = false,
    callback = function(Text)
        local cName = tostring(Text)
        if cName then
            sConfigName = cName
        end
    end,
})

local Button = SettingsTab:CreateButton({
    name = "Save Config",
    callback = function()
        SaveConfiguration(sConfigName)
        task.wait()
        refreshConfigList()
    end,
})

local Section = SettingsTab:CreateSection({ name = "Themes" })

local ThemesDropdown = CreateDropdown(SettingsTab, {
    name = "Preset Themes",
    options = {"Default","Cobalt","Ember","Amethyst","Frost","Rose"},
    value = nil,
    multiSelect = false,
    callback = function(Options)
    end,
})

local Button = SettingsTab:CreateButton({
    name = "Set Theme",
    callback = function()
        if ThemesDropdown.value[1] then
            Window:ChangeTheme(string.lower(ThemesDropdown.value[1]))
        end
    end,
})

local Section = SettingsTab:CreateSection({ name = "Script Shutdown" })

local Button = SettingsTab:CreateButton({
    name = "Unload Script",
    callback = function()
        shutdownScript(true)
    end,
})

local Section = ScriptsTab:CreateSection({ name = "Load Scripts" })

local Button = ScriptsTab:CreateButton({
    name = "Load Infinite Yield",
    callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})

---------------------------------------------------------------
--- DIABLO
---------------------------------------------------------------
-- Abilities wired to real game ClientRemotes. Every remote here is verified
-- against the game's own Zap schema (ReplicatedStorage.Shared.ZapTooling).
-- Built inside its own function so the many throwaway element handles get a
-- fresh 200-register budget instead of piling onto the main chunk's.

local function buildDiabloTab()
local Section = DiabloTab:CreateSection({ name = "Revives" })

local Button = DiabloTab:CreateButton({
    name = "Revive Everyone (Free)",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.useFreeReviveEveryone.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Revive Self (Free)",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.useFreeRevive.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Clutch Revive",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.useClutchRevive.fire()
    end,
})

local Section = DiabloTab:CreateSection({ name = "Abilities" })

local Button = DiabloTab:CreateButton({
    name = "Activate Overcharge",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.activateOvercharge.fire()
    end,
})

local Section = DiabloTab:CreateSection({ name = "Character" })

local Button = DiabloTab:CreateButton({
    name = "Reset Character",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.resetCharacter.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Return to Lobby",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.returnToLobby.fire()
    end,
})

--// Batch 2 — verified sendable (have .fire in ClientRemotes) with schemas
--// matched to ReplicatedStorage.Shared.ZapTooling.

local Section = DiabloTab:CreateSection({ name = "Nugget Revives" })

local Button = DiabloTab:CreateButton({
    name = "Nugget Revive Everyone",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.useNuggetsReviveEveryone.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Nugget Revive Self",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.useNuggetsRevive.fire()
    end,
})

local Section = DiabloTab:CreateSection({ name = "World" })

local Button = DiabloTab:CreateButton({
    name = "Open Raygun Room",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.openRaygunRoom.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Open Facility Gate",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.openFacilityGate.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Insert Bakers DVD",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.insertBakersDvd.fire()
    end,
})

local Section = DiabloTab:CreateSection({ name = "Utility" })

local Button = DiabloTab:CreateButton({
    name = "Claim Group Reward",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.claimGroupReward.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Dismount Vehicle",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.dismountVehicle.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Activate Summon",
    callback = function()
        if isLobbyPlace then return end
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        ClientRemotes.activateSummon.fire({ direction = hrp.CFrame.LookVector })
    end,
})

--// Batch 3 — auto combat. chainsawAttack mirrors the melee kill-aura shape
--// {monsters, corpses, activeSlot}; castWizardSpell takes {cframe, slotIndex}.
--// Both remotes verified sendable; slots resolved by ObjectsLibrary tag/name.

local Section = DiabloTab:CreateSection({ name = "Auto Combat" })

local ChainsawRange = 60
local WizardRange = 120

local Slider = DiabloTab:CreateSlider({
    name = "Chainsaw / Spell Range",
    range = {10, 300},
    increment = 5,
    suffix = "Distance",
    value = ChainsawRange,
    flag = "DiabloRange",
    callback = function(Value)
        ChainsawRange = Value
        WizardRange = Value
    end,
})

local Toggle = DiabloTab:CreateToggle({
    name = "Auto Chainsaw (hold a Chainsaw)",
    value = false,
    flag = "AutoChainsaw",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoChainsaw ~= nil then
            coroutine.close(connections.AutoChainsaw)
            connections.AutoChainsaw = nil
        end

        if Value then
            connections.AutoChainsaw = coroutine.create(function()
                while task.wait(0.1) do
                    local slot = getSlotByTag(nil, "Chainsaw")
                    if not tonumber(slot) then continue end
                    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end

                    local targets = {}
                    for _, mob in pairs(Monsters:GetChildren()) do
                        local root = mob:FindFirstChild("HumanoidRootPart")
                        if root and (hrp.Position - root.Position).Magnitude <= ChainsawRange then
                            table.insert(targets, mob)
                        end
                    end

                    if #targets > 0 then
                        ClientRemotes.chainsawAttack.fire({
                            monsters = targets,
                            corpses = {},
                            activeSlot = tonumber(slot),
                        })
                    end
                end
            end)
            coroutine.resume(connections.AutoChainsaw)
        end
    end,
})

local Toggle = DiabloTab:CreateToggle({
    name = "Auto Wizard Spell (hold a Wizard Staff)",
    value = false,
    flag = "AutoWizardSpell",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoWizardSpell ~= nil then
            coroutine.close(connections.AutoWizardSpell)
            connections.AutoWizardSpell = nil
        end

        if Value then
            connections.AutoWizardSpell = coroutine.create(function()
                while task.wait(0.15) do
                    local slot = getSlotByTag("WizardStaff") or getSlotByTag("UndeadStaff")
                    if not tonumber(slot) then continue end
                    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end

                    local closest, bestDist
                    for _, mob in pairs(Monsters:GetChildren()) do
                        local root = mob:FindFirstChild("HumanoidRootPart")
                        if root then
                            local d = (hrp.Position - root.Position).Magnitude
                            if d <= WizardRange and (not bestDist or d < bestDist) then
                                closest, bestDist = root, d
                            end
                        end
                    end

                    if closest then
                        ClientRemotes.castWizardSpell.fire({
                            cframe = closest.CFrame,
                            slotIndex = tonumber(slot),
                        })
                    end
                end
            end)
            coroutine.resume(connections.AutoWizardSpell)
        end
    end,
})

--// Batch 4 — castCannonBlast mirrors the wizard shape {cframe, slotIndex};
--// throwPie takes {slotIndex} and throws the pie in the active slot.

local Toggle = DiabloTab:CreateToggle({
    name = "Auto Cannon Blast (hold a Hand Cannon)",
    value = false,
    flag = "AutoCannonBlast",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.AutoCannonBlast ~= nil then
            coroutine.close(connections.AutoCannonBlast)
            connections.AutoCannonBlast = nil
        end

        if Value then
            connections.AutoCannonBlast = coroutine.create(function()
                while task.wait(0.15) do
                    local slot = getSlotByTag("HandCannon")
                    if not tonumber(slot) then continue end
                    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end

                    local closest, bestDist
                    for _, mob in pairs(Monsters:GetChildren()) do
                        local root = mob:FindFirstChild("HumanoidRootPart")
                        if root then
                            local d = (hrp.Position - root.Position).Magnitude
                            if d <= WizardRange and (not bestDist or d < bestDist) then
                                closest, bestDist = root, d
                            end
                        end
                    end

                    if closest then
                        ClientRemotes.castCannonBlast.fire({
                            cframe = closest.CFrame,
                            slotIndex = tonumber(slot),
                        })
                    end
                end
            end)
            coroutine.resume(connections.AutoCannonBlast)
        end
    end,
})

local Section = DiabloTab:CreateSection({ name = "Throwables" })

local Button = DiabloTab:CreateButton({
    name = "Throw Pie (active slot)",
    callback = function()
        if isLobbyPlace then return end
        local slot = InventoryModule.getActiveSlot()
        if not tonumber(slot) then return end
        ClientRemotes.throwPie.fire({ slotIndex = tonumber(slot) })
    end,
})

--// Batch 5 — client-side movement. Works in the lobby too (no ClientRemotes),
--// so these are live-verifiable anywhere, not just in a match.

local Section = DiabloTab:CreateSection({ name = "Movement" })

local UserInputService = game:GetService("UserInputService")

local FlySpeed = 60

local Slider = DiabloTab:CreateSlider({
    name = "Fly Speed",
    range = {10, 300},
    increment = 5,
    suffix = "Speed",
    value = FlySpeed,
    flag = "DiabloFlySpeed",
    callback = function(Value)
        FlySpeed = Value
    end,
})

local Toggle = DiabloTab:CreateToggle({
    name = "Fly (WASD + Space/Shift)",
    value = false,
    flag = "DiabloFly",
    callback = function(Value)

        if connections.FlyLoop ~= nil then
            connections.FlyLoop:Disconnect()
            connections.FlyLoop = nil
        end

        -- The game ignores BodyVelocity (velocity is server-authoritative), but
        -- direct CFrame writes replicate, so flight is done by stepping the root
        -- part's CFrame each frame. Verified moving the character in-client.
        if Value then
            connections.FlyLoop = RunService.RenderStepped:Connect(function(dt)
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local cam = workspace.CurrentCamera
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end

                if dir.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + dir.Unit * FlySpeed * dt
                end
            end)
        end
    end,
})

local Toggle = DiabloTab:CreateToggle({
    name = "Noclip",
    value = false,
    flag = "DiabloNoclip",
    callback = function(Value)

        if connections.NoclipLoop ~= nil then
            connections.NoclipLoop:Disconnect()
            connections.NoclipLoop = nil
        end

        if Value then
            connections.NoclipLoop = RunService.Stepped:Connect(function()
                local char = plr.Character
                if not char then return end
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end)
        end
    end,
})

local Toggle = DiabloTab:CreateToggle({
    name = "Infinite Jump",
    value = false,
    flag = "DiabloInfJump",
    callback = function(Value)

        if connections.InfJumpConnection ~= nil then
            connections.InfJumpConnection:Disconnect()
            connections.InfJumpConnection = nil
        end

        if Value then
            connections.InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end,
})

--// Batch 6 — client-side utility. Anti-AFK works anywhere; Monster ESP and
--// Teleport to Nearest Monster are game-specific but use proven primitives
--// (Highlight, CFrame writes).

local Section = DiabloTab:CreateSection({ name = "Utility+" })

local Toggle = DiabloTab:CreateToggle({
    name = "Anti AFK",
    value = false,
    flag = "DiabloAntiAFK",
    callback = function(Value)

        if connections.AntiAFK ~= nil then
            connections.AntiAFK:Disconnect()
            connections.AntiAFK = nil
        end

        if Value then
            local vu = game:GetService("VirtualUser")
            connections.AntiAFK = plr.Idled:Connect(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end,
})

local Toggle = DiabloTab:CreateToggle({
    name = "Monster ESP",
    value = false,
    flag = "DiabloMonsterESP",
    callback = function(Value)

        if connections.MonsterESP ~= nil then
            connections.MonsterESP:Disconnect()
            connections.MonsterESP = nil
        end

        local function clearEsp()
            if not Monsters then return end
            for _, mob in pairs(Monsters:GetChildren()) do
                local h = mob:FindFirstChild("DiabloESP")
                if h then h:Destroy() end
            end
        end

        if isLobbyPlace then return end

        if Value then
            connections.MonsterESP = RunService.Heartbeat:Connect(function()
                if not Monsters then return end
                for _, mob in pairs(Monsters:GetChildren()) do
                    if mob:IsA("Model") and not mob:FindFirstChild("DiabloESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "DiabloESP"
                        hl.FillColor = Color3.fromRGB(255, 60, 60)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.6
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = mob
                    end
                end
            end)
        else
            clearEsp()
        end
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Teleport to Nearest Monster",
    callback = function()
        if isLobbyPlace then return end
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local closest, bestDist
        for _, mob in pairs(Monsters:GetChildren()) do
            local root = mob:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (hrp.Position - root.Position).Magnitude
                if not bestDist or d < bestDist then
                    closest, bestDist = root, d
                end
            end
        end

        if closest then
            hrp.CFrame = closest.CFrame * CFrame.new(0, 0, 6)
        end
    end,
})

--// Batch 7 — server tools. TeleportService + Teleport methods + HttpGet all
--// verified present in the executor.

local Section = DiabloTab:CreateSection({ name = "Server" })

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local Button = DiabloTab:CreateButton({
    name = "Rejoin Server",
    callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Server Hop (new server)",
    callback = function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok then return end

        local decoded = HttpService:JSONDecode(body)
        if not decoded or not decoded.data then return end

        local candidates = {}
        for _, srv in ipairs(decoded.data) do
            if type(srv.id) == "string" and srv.id ~= game.JobId and srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers then
                table.insert(candidates, srv.id)
            end
        end

        if #candidates > 0 then
            local pick = candidates[math.random(1, #candidates)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, plr)
        end
    end,
})

--// Batch 8 — progression triggers. All no-arg, verified sendable, matched to
--// the game's Zap schema.

local Section = DiabloTab:CreateSection({ name = "Progression" })

local Button = DiabloTab:CreateButton({
    name = "Skip Cutscene",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.finishCutscene.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Flag Entered Sewer",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.enteredSewer.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Flag Entered Science Lab",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.enteredScienceLab.fire()
    end,
})

local Button = DiabloTab:CreateButton({
    name = "Flag Opened Blueprint Table",
    callback = function()
        if isLobbyPlace then return end
        ClientRemotes.openedBlueprintTable.fire()
    end,
})

--// Batch 9 — camera. FOV setting and scriptable camera both verified live in
--// the executor.

local Section = DiabloTab:CreateSection({ name = "Camera" })

local Slider = DiabloTab:CreateSlider({
    name = "Field of View",
    range = {30, 120},
    increment = 1,
    suffix = "FOV",
    value = 70,
    flag = "DiabloFOV",
    callback = function(Value)
        workspace.CurrentCamera.FieldOfView = Value
    end,
})

-- Smooth cinematic freecam by richie0866 (Orca, MIT), hosted alongside this
-- script. It uses spring-smoothed velocity/pan/FOV and sinks its own movement
-- input through ContextActionService, so the character does not walk while it
-- runs. Loaded once on first toggle and cached.
local orcaFreecam = nil

local function getFreecam()
    if orcaFreecam == nil then
        local ok, mod = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/showcase-assets/main/freecam.lua"))()
        end)
        orcaFreecam = (ok and type(mod) == "table" and mod) or false
    end
    return orcaFreecam or nil
end

-- This game runs CameraMode = LockFirstPerson, which re-pins the camera to the
-- head every frame and would override the freecam. Release it to Classic while
-- freecam runs, and restore the exact prior mode/zoom afterward.
local savedCameraMode, savedMinZoom

local Toggle = DiabloTab:CreateToggle({
    name = "Freecam (Orca: WASD, mouse, scroll = FOV)",
    value = false,
    flag = "DiabloFreecam",
    callback = function(Value)
        local fc = getFreecam()
        if not fc then return end

        if Value then
            savedCameraMode = plr.CameraMode
            savedMinZoom = plr.CameraMinZoomDistance
            plr.CameraMode = Enum.CameraMode.Classic
            plr.CameraMinZoomDistance = 0.5
            fc.EnableFreecam()
        else
            fc.DisableFreecam()
            if savedCameraMode ~= nil then
                plr.CameraMode = savedCameraMode
                savedCameraMode = nil
            end
            if savedMinZoom ~= nil then
                plr.CameraMinZoomDistance = savedMinZoom
                savedMinZoom = nil
            end
        end
    end,
})
end

buildDiabloTab()

---------------------------------------------------------------
--- GOD
---------------------------------------------------------------
-- Universal kill aura. Damage is dealt with whatever weapon is equipped:
--   * a Gun fires fireProjectile with the in-range mob Humanoids as the hit
--     list (verified 220 -> 0 on a CactusCreeper),
--   * a Melee fires meleeAttack with the mob Models (the game's own path).
-- Mobs are read live from workspace.Monsters. Range is adjustable and can be
-- drawn as a translucent sphere around the player.
-- Built in its own function so its element handles get a fresh register budget.

local function buildGodTab()

local GodAuraRange = 60
local GodAuraDelay = 0.1

local Section = GodTab:CreateSection({ name = "Kill Aura" })

local MobListLabel = CreateLabel(GodTab, "Mobs in range: (aura off)", 4483362458)

local Slider = GodTab:CreateSlider({
    name = "Aura Range",
    range = {10, 500},
    increment = 5,
    suffix = "Distance",
    value = GodAuraRange,
    flag = "GodAuraRange",
    callback = function(Value)
        GodAuraRange = Value
    end,
})

local Slider = GodTab:CreateSlider({
    name = "Aura Delay (raise if laggy)",
    range = {0, 0.5},
    increment = 0.01,
    suffix = "s",
    value = GodAuraDelay,
    flag = "GodAuraDelay",
    callback = function(Value)
        GodAuraDelay = Value
    end,
})

-- collect the mobs inside the aura, plus a live type breakdown
local function collectMobs()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local mons = game.Workspace:FindFirstChild("Monsters")
    local inRange, counts = {}, {}
    if not hrp or not mons then return inRange, counts end

    for _, mob in pairs(mons:GetChildren()) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        local hum = mob:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            if (hrp.Position - root.Position).Magnitude <= GodAuraRange then
                table.insert(inRange, mob)
                counts[mob.Name] = (counts[mob.Name] or 0) + 1
            end
        end
    end
    return inRange, counts
end

local Toggle = GodTab:CreateToggle({
    name = "Kill Aura (Gun or Melee)",
    value = false,
    flag = "GodKillAura",
    callback = function(Value)
        if isLobbyPlace then return end

        if connections.GodKillAura ~= nil then
            coroutine.close(connections.GodKillAura)
            connections.GodKillAura = nil
        end
        if connections.GodMobList ~= nil then
            coroutine.close(connections.GodMobList)
            connections.GodMobList = nil
        end

        if not Value then
            MobListLabel:Set("Mobs in range: (aura off)")
            return
        end

        -- live mob-list label
        connections.GodMobList = coroutine.create(function()
            while task.wait(0.3) do
                local _, counts = collectMobs()
                local parts = {}
                for name, c in pairs(counts) do parts[#parts + 1] = name .. " x" .. c end
                MobListLabel:Set(#parts > 0 and ("In range: " .. table.concat(parts, ", ")) or "Mobs in range: none")
            end
        end)
        coroutine.resume(connections.GodMobList)

        -- the aura itself
        connections.GodKillAura = coroutine.create(function()
            while task.wait(GodAuraDelay) do
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                local targets = collectMobs()
                if #targets == 0 then continue end

                local gunSlot = getItemSlot(nil, "Gun")
                local meleeSlot = getItemSlot(nil, "Melee")

                if tonumber(gunSlot) then
                    -- fireProjectile hits up to 16 humanoids per call
                    local humanoids = {}
                    for _, mob in ipairs(targets) do
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hum then
                            table.insert(humanoids, hum)
                            if #humanoids >= 16 then break end
                        end
                    end
                    local first = targets[1]:FindFirstChild("HumanoidRootPart")
                    if first and #humanoids > 0 then
                        ClientRemotes.fireProjectile.fire({
                            slotIndex = tonumber(gunSlot),
                            direction = (first.Position - hrp.Position).Unit,
                            humanoids = humanoids,
                            hitPosition = first.Position,
                            normal = Vector3.new(0, 1, 0),
                        })
                    end
                elseif tonumber(meleeSlot) then
                    ClientRemotes.meleeAttack.fire({
                        monsters = targets,
                        civilians = {},
                        activeSlot = tonumber(meleeSlot),
                    })
                end
            end
        end)
        coroutine.resume(connections.GodKillAura)
    end,
})

local Section = GodTab:CreateSection({ name = "Range Visual" })

local GodAuraColor = Color3.fromRGB(255, 60, 60)
local GodAuraTransparency = 0.55

local Toggle = GodTab:CreateToggle({
    name = "Show Aura Range",
    value = false,
    flag = "GodShowRange",
    callback = function(Value)

        if connections.GodRangeVis ~= nil then
            connections.GodRangeVis:Disconnect()
            connections.GodRangeVis = nil
        end

        local existing = game.Workspace:FindFirstChild("GodAuraSphere")
        if existing then existing:Destroy() end

        if Value then
            -- Neon renders as a solid glow visible from inside the ball, unlike
            -- ForceField which was nearly transparent. A SelectionSphere on top
            -- gives a crisp coloured outline so the edge reads clearly too.
            local sphere = Instance.new("Part")
            sphere.Name = "GodAuraSphere"
            sphere.Shape = Enum.PartType.Ball
            sphere.Material = Enum.Material.Neon
            sphere.Color = GodAuraColor
            sphere.Transparency = GodAuraTransparency
            sphere.CanCollide = false
            sphere.CanQuery = false
            sphere.CanTouch = false
            sphere.Anchored = true
            sphere.Massless = true
            sphere.CastShadow = false
            sphere.Parent = game.Workspace

            local outline = Instance.new("SelectionSphere")
            outline.Name = "Outline"
            outline.Adornee = sphere
            outline.SurfaceTransparency = 1
            outline.Color3 = GodAuraColor
            outline.Transparency = 0.2
            outline.Parent = sphere

            connections.GodRangeVis = RunService.RenderStepped:Connect(function()
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not hrp or not sphere.Parent then return end
                sphere.Size = Vector3.new(1, 1, 1) * GodAuraRange * 2
                sphere.CFrame = CFrame.new(hrp.Position)
                sphere.Color = GodAuraColor
                sphere.Transparency = GodAuraTransparency
                outline.Color3 = GodAuraColor
            end)
        end
    end,
})

local ColorPicker = GodTab:CreateColorPicker({
    name = "Aura Range Color",
    color = GodAuraColor,
    flag = "GodAuraColor",
    callback = function(color)
        GodAuraColor = color
        local sphere = game.Workspace:FindFirstChild("GodAuraSphere")
        if sphere then
            sphere.Color = color
            local outline = sphere:FindFirstChild("Outline")
            if outline then outline.Color3 = color end
        end
    end,
})

local Slider = GodTab:CreateSlider({
    name = "Range Visual Opacity",
    range = {0, 90},
    increment = 5,
    suffix = "%",
    value = 45,
    flag = "GodRangeOpacity",
    callback = function(Value)
        -- higher slider = more opaque, so transparency is the inverse
        GodAuraTransparency = 1 - (Value / 100)
    end,
})

end

buildGodTab()

---------------------------------------------------------------
--- TITLE FITTING
---------------------------------------------------------------
-- Every Gen2 element builds its title holder as a hardcoded 170px box:
--     container = Frame{ Size = UDim2.new(0,170,0,16), Position = (0,20,0.5,0) }
-- That offset never scales, so a long name is truncated with an ellipsis no
-- matter how wide the window gets. This pass gives each title the real space
-- left over between the 20px inset and whatever control sits on the right, and
-- claws back some width from the slider track, which is a fixed 222px and eats
-- half the row on its own. It reruns whenever the window is resized.

local function fitElementTitles()

    local elements = {}

    for _, tab in pairs(Window.tabs or {}) do
        for _, element in pairs(tab.elements or {}) do
            if element.container and element.container.Parent then
                table.insert(elements, element)
            end
        end
    end

    -- a wide window flips sliders into a row layout where the library flexes the
    -- title across the whole element already, so those are left alone
    local function libraryHandlesIt(element)
        return element.track ~= nil
            and element.titleFlex ~= nil
            and element.titleFlex.FlexMode == Enum.UIFlexMode.Fill
    end

    -- pass 1: shrink the slider tracks, so pass 2 measures the new positions
    for _, element in pairs(elements) do
        if element.track and not element.minimal and not libraryHandlesIt(element) then
            local host = element.container.Parent
            if host.AbsoluteSize.X > 0 then
                local trackWidth = math.clamp(math.floor(host.AbsoluteSize.X * 0.34), 110, 222)
                element.track.Size = UDim2.new(0, trackWidth, 0, element.track.Size.Y.Offset)
            end
        end
    end

    task.wait()

    -- pass 2: grow each title up to whatever sits on its right
    for _, element in pairs(elements) do

        local container = element.container
        local host = container.Parent

        if host and host.AbsoluteSize.X > 0 and not libraryHandlesIt(element) then

            local hostLeft = host.AbsolutePosition.X
            local containerLeft = container.AbsolutePosition.X - hostLeft
            local limit = host.AbsoluteSize.X - 20

            for _, sibling in ipairs(host:GetChildren()) do
                if sibling:IsA("GuiObject") and sibling ~= container and sibling.AbsoluteSize.X > 0 then
                    local left = sibling.AbsolutePosition.X - hostLeft
                    -- ignore the full width overlays and hit areas that start at
                    -- the element's own left edge
                    if left > containerLeft + 20 and left < limit then
                        limit = left
                    end
                end
            end

            local width = math.max(140, limit - containerLeft - 12)
            container.Size = UDim2.new(0, width, 0, container.Size.Y.Offset)
        end
    end
end

task.spawn(fitElementTitles)

do
    -- refitting walks every element in every tab, so it must never run while a
    -- resize is in flight: doing that each frame is what makes a drag stutter.
    -- It waits for the smoothing loop to settle, then runs once.
    local pending = false

    local function scheduleFit()
        if pending then return end
        pending = true

        task.spawn(function()
            repeat task.wait(0.15) until not Window.__resizing
            task.wait(0.1)
            pending = false
            fitElementTitles()
        end)
    end

    Window.main:GetPropertyChangedSignal("AbsoluteSize"):Connect(scheduleFit)
end

initScript()
