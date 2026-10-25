-- ============================================================
-- Hello Hub - Supreme Evade Edition (All-in-One)
-- Features: Inf Jump, Inf Slide, ESP, Auto Evade, Animations
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then return end

-- ⭐ ไอดีรูปภาพของคุณ
local ASSET_DECORATION = "rbxassetid://113307759811921"
local ASSET_BACKGROUND = "rbxassetid://136946660345051"

-- ============ Theme & Config ============
local Theme = {
    main = Color3.fromRGB(15, 8, 5),
    panel = Color3.fromRGB(25, 12, 8),
    card = Color3.fromRGB(40, 20, 12),
    accent = Color3.fromRGB(255, 115, 0),
    accentGlow = Color3.fromRGB(255, 170, 50),
    text = Color3.fromRGB(255, 255, 255),
    text_dim = Color3.fromRGB(180, 140, 120),
    success = Color3.fromRGB(0, 255, 120),
    danger = Color3.fromRGB(255, 50, 50)
}

local state = {
    -- Movement
    autoJump = false, infJump = false, jumpPower = 50, speedEnabled = false,
    walkSpeed = 35, infiniteSlide = false, fly = false,
    -- Survival & Evade
    autoRevive = false, antiRagdoll = false, autoEvade = false, evadeRange = 50,
    autoCollect = false, nextbotEsp = false, godmode = false,
    -- Utility
    noclip = false, antiAfk = false, fullbright = false,
    -- UI
    jumpBtnToggled = false, lockBtns = false
}

local character, humanoid, rootPart
local flyBodyVel, flyBodyGyro = nil, nil
local espHighlights = {}
local jumpDebounce = false

-- ============ Helpers ============
local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "Parent" then inst[k] = v end end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end
local function corner(i, r) return create("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = i }) end
local function stroke(i, c, t) return create("UIStroke", { Color = c or Theme.accent, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = i }) end
local function gradient(i, c1, c2, rot) return create("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 0, Parent = i }) end

-- ============ Character Setup ============
local function onCharacterAdded(char)
    character = char
    humanoid = char:WaitForChild("Humanoid", 5)
    rootPart = char:WaitForChild("HumanoidRootPart", 5)
    if humanoid then 
        humanoid.JumpPower = state.jumpPower
        humanoid.WalkSpeed = state.speedEnabled and state.walkSpeed or 16 
    end
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    state.fly = false; state.godmode = false
end
if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

-- ============ Notifications ============
local activeNotifs = {}
local function notify(title, text, color)
    local notifGui = playerGui:FindFirstChild("HelloHubNotifs") or create("ScreenGui", { Name = "HelloHubNotifs", ResetOnSpawn = false, DisplayOrder = 100000, Parent = playerGui })
    color = color or Theme.accent
    
    local n = create("Frame", { Size = UDim2.new(0, 260, 0, 60), Position = UDim2.new(0.5, 400, 0, 20 + #activeNotifs * 70), BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.15, Parent = notifGui })
    corner(n, 10); stroke(n, color, 2)
    
    create("Frame", { Size = UDim2.new(0, 4, 1, -12), Position = UDim2.new(0, 0, 0, 6), BackgroundColor3 = color, Parent = n }); corner(n:GetChildren()[1], 2)
    create("TextLabel", { Size = UDim2.new(1, -25, 0, 20), Position = UDim2.new(0, 15, 0, 10), BackgroundTransparency = 1, Text = title, TextColor3 = color, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = n })
    create("TextLabel", { Size = UDim2.new(1, -25, 0, 20), Position = UDim2.new(0, 15, 0, 30), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = n })
    
    table.insert(activeNotifs, n)
    TweenService:Create(n, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -280, 0, 20 + (#activeNotifs-1) * 70) }):Play()
    
    task.delay(3, function()
        TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 400, 0, n.Position.Y.Offset) }):Play()
        task.wait(0.3)
        for i, v in ipairs(activeNotifs) do if v == n then table.remove(activeNotifs, i) break end end
        n:Destroy()
    end)
end

-- ============ UI Widgets ============
local ui = { tabs = {} }

local function addToggle(p, name, text, def, cb)
    local isOn = def
    local frame = create("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Theme.card, BackgroundTransparency = 0.3, Text = "", AutoButtonColor = false, Active = true, ZIndex = 15, Parent = p })
    corner(frame, 8); stroke(frame, Color3.fromRGB(80, 40, 10), 1)
    
    create("TextLabel", { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Active = false, ZIndex = 16, Parent = frame })
    local bg = create("Frame", { Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -56, 0.5, -11), BackgroundColor3 = Color3.fromRGB(15, 8, 4), Active = false, ZIndex = 16, Parent = frame })
    corner(bg, 11)
    local knob = create("Frame", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Color3.fromRGB(200, 200, 200), Active = false, ZIndex = 17, Parent = bg })
    corner(knob, 9)
    
    local function updateVisual()
        if isOn then
            TweenService:Create(bg, TweenInfo.new(0.3), { BackgroundColor3 = Theme.accent }):Play()
            TweenService:Create(knob, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255,255,255) }):Play()
        else
            TweenService:Create(bg, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(15, 8, 4) }):Play()
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Color3.fromRGB(200, 200, 200) }):Play()
        end
    end
    updateVisual()
    
    frame.MouseEnter:Connect(function() TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play() end)
    frame.MouseLeave:Connect(function() TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundTransparency = 0.3 }):Play() end)
    
    frame.MouseButton1Click:Connect(function()
        isOn = not isOn
        updateVisual()
        if cb then pcall(cb, isOn) end
    end)
end

local function addSection(p, title)
    local f = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 10, Parent = p })
    create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = title:upper(), TextColor3 = Theme.accentGlow, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Active = false, ZIndex = 11, Parent = f })
    create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.accent, BackgroundTransparency = 0.5, Active = false, ZIndex = 11, Parent = f })
end

local function addButton(p, text, color, cb)
    local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = color or Theme.card, BackgroundTransparency = 0.2, Text = text, TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, Active = true, ZIndex = 15, Parent = p })
    corner(btn, 8); stroke(btn, color or Color3.fromRGB(80, 40, 10), 1)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundTransparency = 0.2 }):Play() end)
    btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
end

local function addSlider(p, name, text, min, max, def, cb)
    local f = create("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Theme.card, BackgroundTransparency = 0.3, ZIndex = 15, Parent = p })
    corner(f, 8); stroke(f, Color3.fromRGB(80, 40, 10), 1)
    local lbl = create("TextLabel", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1, Text = text .. ": " .. def, TextColor3 = Theme.text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Active = false, ZIndex = 16, Parent = f })
    local bar = create("Frame", { Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 0, 34), BackgroundColor3 = Color3.fromRGB(15, 8, 4), Active = false, ZIndex = 16, Parent = f })
    corner(bar, 3)
    local fill = create("Frame", { Size = UDim2.new((def-min)/(max-min), 0, 1, 0), BackgroundColor3 = Theme.accent, Active = false, ZIndex = 17, Parent = bar })
    corner(fill, 3); gradient(fill, Theme.accent, Theme.accentGlow, 0)
    local db = create("TextButton", { Size = UDim2.new(1, 0, 4, 0), Position = UDim2.new(0, 0, -1.5, 0), BackgroundTransparency = 1, Text = "", Active = true, ZIndex = 18, Parent = bar })
    local dragging = false
    local function setVal(x)
        local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min) * pct + 0.5)
        fill.Size = UDim2.new(pct, 0, 1, 0); lbl.Text = text .. ": " .. val; if cb then pcall(cb, val) end
    end
    db.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; setVal(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setVal(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

local function createCard(parent, iconText, title, value, sub)
    local c = create("Frame", { Size = UDim2.new(0.48, 0, 0, 90), BackgroundColor3 = Theme.card, BackgroundTransparency = 0.4, Active = false, ZIndex = 10, Parent = parent })
    corner(c, 10); stroke(c, Theme.accent, 1)
    create("TextLabel", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 12, 0, 12), BackgroundTransparency = 1, Text = iconText, TextColor3 = Theme.accentGlow, TextSize = 18, Active = false, ZIndex = 11, Parent = c })
    create("TextLabel", { Size = UDim2.new(1, -40, 0, 20), Position = UDim2.new(0, 42, 0, 14), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.text_dim, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Active = false, ZIndex = 11, Parent = c })
    create("TextLabel", { Size = UDim2.new(1, -15, 0, 30), Position = UDim2.new(0, 15, 0, 35), BackgroundTransparency = 1, Text = value, TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Active = false, ZIndex = 11, Parent = c })
    create("TextLabel", { Size = UDim2.new(1, -15, 0, 15), Position = UDim2.new(0, 15, 0, 65), BackgroundTransparency = 1, Text = sub, TextColor3 = Theme.text_dim, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Active = false, ZIndex = 11, Parent = c })
    
    c.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.2, Size = UDim2.new(0.49, 0, 0, 92), Position = UDim2.new(-0.005, 0, -1, 0) }):Play() end)
    c.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.4, Size = UDim2.new(0.48, 0, 0, 90), Position = UDim2.new(0, 0, 0, 0) }):Play() end)
    return c
end

-- ============ ⭐ ระบบกระโดด Evade Bypass ============
local function attemptJump()
    if not humanoid or humanoid.Health <= 0 or not rootPart then return end
    if jumpDebounce then return end
    
    if humanoid.FloorMaterial ~= Enum.Material.Air then
        jumpDebounce = true
        pcall(function()
            humanoid.Jump = true
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
        task.wait(0.1)
        jumpDebounce = false
    else
        if state.infJump then
            jumpDebounce = true
            pcall(function()
                -- ใช้ Velocity ดันขึ้น 50 ไม่ลอยฟ้า
                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 50, rootPart.Velocity.Z)
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
            task.wait(0.1)
            jumpDebounce = false
        end
    end
end

-- ============ Floating UI ============
local floatGui
local function buildFloatingUI()
    if floatGui then floatGui:Destroy() end
    floatGui = create("ScreenGui", { Name = "HelloHubFloating", ResetOnSpawn = false, DisplayOrder = 99999, Parent = playerGui })

    local jumpContainer = create("Frame", { Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.05, 0, 0.6, 0), BackgroundTransparency = 1, Parent = floatGui })
    local glow = create("Frame", { Size = UDim2.new(1, 10, 1, 10), Position = UDim2.new(0, -5, 0, -5), BackgroundColor3 = Theme.accent, BackgroundTransparency = 0.6, Active = false, Parent = jumpContainer })
    corner(glow, 35)
    TweenService:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.2, Size = UDim2.new(1, 16, 1, 16), Position = UDim2.new(0, -8, 0, -8) }):Play()
    
    local jumpBtn = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(20, 10, 5), Text = "⤒", TextColor3 = Theme.accent, Font = Enum.Font.GothamBold, TextSize = 32, AutoButtonColor = false, Parent = jumpContainer })
    corner(jumpBtn, 30); stroke(jumpBtn, Theme.accent, 2)

    local function updateJumpVisual()
        if state.jumpBtnToggled then
            TweenService:Create(jumpBtn, TweenInfo.new(0.3), { BackgroundColor3 = Theme.accent, TextColor3 = Color3.fromRGB(20, 10, 5) }):Play()
        else
            TweenService:Create(jumpBtn, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(20, 10, 5), TextColor3 = Theme.accent }):Play()
        end
    end

    local jPressPos, jStartPos, jDragging = nil, nil, false
    jumpBtn.InputBegan:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            jPressPos = i.Position; jStartPos = jumpContainer.Position; jDragging = false 
        end 
    end)
    jumpBtn.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
            if not jDragging then 
                state.jumpBtnToggled = not state.jumpBtnToggled
                updateJumpVisual()
                if state.jumpBtnToggled then attemptJump() end
            end
            jPressPos = nil 
        end 
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not jPressPos or not (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then return end
        local d = i.Position - jPressPos
        if not jDragging and (math.abs(d.X) > 15 or math.abs(d.Y) > 15) then jDragging = true end
        if jDragging and not state.lockBtns then jumpContainer.Position = UDim2.new(jStartPos.X.Scale, jStartPos.X.Offset + d.X, jStartPos.Y.Scale, jStartPos.Y.Offset + d.Y) end
    end)

    local iconContainer = create("Frame", { Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.04, 0, 0.4, 0), BackgroundTransparency = 1, Parent = floatGui })
    local iconGlow = create("Frame", { Size = UDim2.new(1, 6, 1, 6), Position = UDim2.new(0, -3, 0, -3), BackgroundColor3 = Theme.accentGlow, BackgroundTransparency = 0.5, Active = false, Parent = iconContainer })
    corner(iconGlow, 28)
    local toggleIcon = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.accent, Text = "🎃", TextColor3 = Color3.fromRGB(20, 10, 5), Font = Enum.Font.GothamBold, TextSize = 24, AutoButtonColor = false, Parent = iconContainer })
    corner(toggleIcon, 25); stroke(toggleIcon, Color3.fromRGB(255, 200, 100), 2)
    TweenService:Create(iconGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.2, Size = UDim2.new(1, 14, 1, 14), Position = UDim2.new(0, -7, 0, -7) }):Play()
    
    local iPressPos, iStartPos, iDragging = nil, nil, false
    toggleIcon.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then iPressPos = i.Position; iStartPos = iconContainer.Position; iDragging = false end end)
    toggleIcon.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then if not iDragging then local sg = playerGui:FindFirstChild("HelloHubUI"); if sg then sg.Enabled = not sg.Enabled end end; iPressPos = nil end end)
    UserInputService.InputChanged:Connect(function(i)
        if not iPressPos or not (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then return end
        local d = i.Position - iPressPos
        if not iDragging and (math.abs(d.X) > 15 or math.abs(d.Y) > 15) then iDragging = true end
        if iDragging and not state.lockBtns then iconContainer.Position = UDim2.new(iStartPos.X.Scale, iStartPos.X.Offset + d.X, iStartPos.Y.Scale, iStartPos.Y.Offset + d.Y) end
    end)
end

-- ============ Main GUI ============
local function buildGUI()
    for _, g in ipairs(playerGui:GetChildren()) do if g.Name == "HelloHubUI" then g:Destroy() end end

    local sg = create("ScreenGui", { Name = "HelloHubUI", ResetOnSpawn = false, DisplayOrder = 99998, Parent = playerGui })
    create("ImageLabel", { Size = UDim2.new(0, 540, 0, 340), Position = UDim2.new(0.5, -270, 0.5, -170), BackgroundTransparency = 1, Image = "rbxassetid://1316045217", ImageColor3 = Color3.fromRGB(0,0,0), ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(10,10,118,118), ZIndex = 1, Parent = sg })

    local main = create("Frame", { Size = UDim2.new(0, 520, 0, 320), Position = UDim2.new(0.5, -260, 0.5, -160), BackgroundColor3 = Theme.main, Active = true, ClipsDescendants = true, ZIndex = 2, Parent = sg })
    corner(main, 10); stroke(main, Theme.accent, 2)

    create("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = ASSET_BACKGROUND, ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0.4, Active = false, ZIndex = 3, Parent = main })
    create("ImageLabel", { Size = UDim2.new(1.15, 0, 1.15, 0), Position = UDim2.new(-0.075, 0, -0.075, 0), BackgroundTransparency = 1, Image = ASSET_DECORATION, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 0.2, Active = false, ZIndex = 4, Parent = main })
    create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.6, Active = false, ZIndex = 5, Parent = main }); corner(main:GetChildren()[5], 10)

    local topBar = create("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, Active = true, ZIndex = 10, Parent = main })
    create("TextLabel", { Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, Text = "Hello Hub", TextColor3 = Theme.accentGlow, Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Active = false, ZIndex = 11, Parent = topBar })

    local hideBtn = create("TextButton", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -75, 0.5, -14), BackgroundColor3 = Theme.card, Text = "—", TextColor3 = Theme.accentGlow, Font = Enum.Font.GothamBold, ZIndex = 11, Parent = topBar })
    corner(hideBtn, 6); stroke(hideBtn, Theme.accent, 1)
    hideBtn.MouseButton1Click:Connect(function() sg.Enabled = false end)

    local closeBtn = create("TextButton", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -40, 0.5, -14), BackgroundColor3 = Theme.card, Text = "✕", TextColor3 = Theme.accentGlow, Font = Enum.Font.GothamBold, ZIndex = 11, Parent = topBar })
    corner(closeBtn, 6); stroke(closeBtn, Theme.accent, 1)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy(); if floatGui then floatGui:Destroy() end; notify("System", "ปิด GUI แล้ว", Theme.danger) end)

    local mPressPos, mStartPos, mDragging = nil, nil, false
    topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mPressPos = i.Position; mStartPos = main.Position; mDragging = true end end)
    UserInputService.InputChanged:Connect(function(i) if mDragging and mPressPos and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - mPressPos; main.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + d.X, mStartPos.Y.Scale, mStartPos.Y.Offset + d.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mDragging = false; mPressPos = nil end end)

    local sidebar = create("Frame", { Size = UDim2.new(0, 130, 1, -60), Position = UDim2.new(0, 15, 0, 50), BackgroundTransparency = 1, ZIndex = 10, Parent = main })
    create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })

    local content = create("Frame", { Size = UDim2.new(1, -165, 1, -65), Position = UDim2.new(0, 155, 0, 50), BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.4, ZIndex = 10, Parent = main })
    corner(content, 10); stroke(content, Color3.fromRGB(80, 40, 10), 1.5)

    local function createTab(name, iconText)
        local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.card, BackgroundTransparency = 0.3, Text = "  " .. iconText .. "   " .. name, TextColor3 = Theme.text_dim, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Active = true, ZIndex = 15, Parent = sidebar })
        corner(btn, 8); stroke(btn, Theme.accent, 0)
        local indicator = create("Frame", { Size = UDim2.new(0, 3, 0.6, 0), Position = UDim2.new(0, 0, 0.2, 0), BackgroundColor3 = Theme.accent, Visible = false, Active = false, ZIndex = 16, Parent = btn })
        corner(indicator, 2)
        local scroll = create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.accent, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Active = true, ZIndex = 11, Parent = content })
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
        create("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = scroll })
        ui.tabs[name] = { btn = btn, scroll = scroll, indicator = indicator }
        btn.MouseButton1Click:Connect(function()
            for n, t in pairs(ui.tabs) do
                t.scroll.Visible = (n == name); t.indicator.Visible = (n == name)
                TweenService:Create(t.btn, TweenInfo.new(0.2), { BackgroundColor3 = (n == name) and Theme.accent or Theme.card, BackgroundTransparency = (n == name) and 0 or 0.3, TextColor3 = (n == name) and Color3.fromRGB(20,10,5) or Theme.text_dim }):Play()
                local s = t.btn:FindFirstChildOfClass("UIStroke")
                if s then TweenService:Create(s, TweenInfo.new(0.2), { Transparency = (n == name) and 0 or 1 }):Play() end
            end
        end)
        return scroll
    end

    local dashTab = createTab("Dash", "🏠")
    local moveTab = createTab("Move", "🏃")
    local evadeTab = createTab("Evade", "💨")
    local visTab = createTab("Visuals", "👁️")
    local utilTab = createTab("Utility", "🛠️")
    local cfgTab = createTab("Settings", "⚙️")

    -- [ Dashboard ]
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Welcome, " .. player.Name, TextColor3 = Theme.accentGlow, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Active = false, ZIndex = 12, Parent = dashTab })
    local grid = create("Frame", { Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1, ZIndex = 12, Parent = dashTab })
    create("UIGridLayout", { CellSize = UDim2.new(0.48, 0, 0, 90), CellPadding = UDim2.new(0.04, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
    createCard(grid, "👥", "Players", tostring(#Players:GetPlayers()), "Connected")
    createCard(grid, "📶", "Ping", "0 ms", "Network state")
    createCard(grid, "📍", "Region", "SG", "Detected")
    createCard(grid, "🛡️", "Status", "Healthy", "Systems OK")

    -- [ Movement ]
    addSection(moveTab, "Jump & Fly")
    addToggle(moveTab, "autoJump", "Auto Jump", state.autoJump, function(v) state.autoJump = v end)
    addToggle(moveTab, "infJump", "Infinite Jump (Evade)", state.infJump, function(v) state.infJump = v end)
    addToggle(moveTab, "fly", "Enable Fly", state.fly, function(v)
        state.fly = v
        if v and rootPart then
            flyBodyVel = create("BodyVelocity", { MaxForce = Vector3.new(1e5, 1e5, 1e5), P = 1250, Parent = rootPart })
            flyBodyGyro = create("BodyGyro", { MaxTorque = Vector3.new(1e5, 1e5, 1e5), P = 1250, Parent = rootPart })
            humanoid.PlatformStand = true
        elseif not v then
            if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
            if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
            if humanoid then humanoid.PlatformStand = false end
        end
    end)
    addSection(moveTab, "Slide & Speed")
    addToggle(moveTab, "infiniteSlide", "Infinite Slide (พุ่งตัว)", state.infiniteSlide, function(v) state.infiniteSlide = v end)
    addToggle(moveTab, "speed", "Enable WalkSpeed", state.speedEnabled, function(v) state.speedEnabled = v; if humanoid then humanoid.WalkSpeed = v and state.walkSpeed or 16 end end)
    addSlider(moveTab, "walkSpeed", "WalkSpeed", 16, 100, 35, function(v) state.walkSpeed = v; if state.speedEnabled and humanoid then humanoid.WalkSpeed = v end end)

    -- [ Evade Tab ]
    addSection(evadeTab, "Survival")
    addToggle(evadeTab, "autoRevive", "Auto Revive", state.autoRevive, function(v) state.autoRevive = v end)
    addToggle(evadeTab, "antiRagdoll", "Anti-Ragdoll", state.antiRagdoll, function(v) state.antiRagdoll = v end)
    addSection(evadeTab, "Evade Specific")
    addToggle(evadeTab, "nextbotEsp", "Nextbot ESP", state.nextbotEsp, function(v) state.nextbotEsp = v; if not v then for _, h in pairs(espHighlights) do if h and h.Parent then h:Destroy() end end; espHighlights = {} end end)
    addToggle(evadeTab, "autoEvade", "Auto Evade (วาร์ปหนี)", state.autoEvade, function(v) state.autoEvade = v end)
    addSlider(evadeTab, "evadeRange", "Evade Distance", 10, 100, state.evadeRange, function(v) state.evadeRange = v end)
    addToggle(evadeTab, "autoCollect", "Auto Collect Items", state.autoCollect, function(v) state.autoCollect = v end)
    
    addSection(evadeTab, "Teleport")
    addButton(evadeTab, "⬆️ วาร์ปขึ้นที่สูงที่สุด", Theme.accent, function()
        if character and rootPart then
            local highestY = -math.huge; local targetPos = nil
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    if part.Position.Y > highestY then highestY = part.Position.Y; targetPos = part.Position + Vector3.new(0, 5, 0) end
                end
            end
            if targetPos then rootPart.CFrame = CFrame.new(targetPos); notify("Teleport", "วาร์ปขึ้นที่สูงแล้ว!", Theme.success) end
        end
    end)
    addButton(evadeTab, "⚡ วาร์ปหนี (ด่วน)", Theme.danger, function()
        if character and rootPart then
            local camCF = workspace.CurrentCamera.CFrame
            rootPart.CFrame = CFrame.new(rootPart.Position + (camCF.LookVector * 50) + Vector3.new(0, 20, 0))
            notify("Teleport", "วาร์ปหนีแล้ว!", Theme.success)
        end
    end)

    -- [ Visuals ]
    addSection(visTab, "Lighting")
    addToggle(visTab, "fullbright", "Fullbright", state.fullbright, function(v) state.fullbright = v; Lighting.Ambient = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70) end)
    
    -- [ Utility ]
    addSection(utilTab, "System")
    addToggle(utilTab, "noclip", "Noclip", state.noclip, function(v) state.noclip = v end)
    addToggle(utilTab, "antiAfk", "Anti AFK", state.antiAfk, function(v) state.antiAfk = v end)

    -- [ Settings ]
    addSection(cfgTab, "System")
    addToggle(cfgTab, "lockBtns", "🔒 ล็อกปุ่มลอย", state.lockBtns, function(v) state.lockBtns = v end)
    addToggle(cfgTab, "godmode", "Godmode", state.godmode, function(v) state.godmode = v end)
    addButton(cfgTab, "❌ ปิด GUI ทั้งหมด", Theme.danger, function() sg:Destroy(); if floatGui then floatGui:Destroy() end end)

    ui.tabs["Dash"].scroll.Visible = true
    ui.tabs["Dash"].indicator.Visible = true
    ui.tabs["Dash"].btn.BackgroundColor3 = Theme.accent
    ui.tabs["Dash"].btn.BackgroundTransparency = 0
    ui.tabs["Dash"].btn.TextColor3 = Color3.fromRGB(20,10,5)
    local dashStroke = ui.tabs["Dash"].btn:FindFirstChildOfClass("UIStroke")
    if dashStroke then dashStroke.Transparency = 0 end
    
    main.Position = UDim2.new(0.5, -260, 0.5, -100)
    main.BackgroundTransparency = 1
    TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -260, 0.5, -160), BackgroundTransparency = 0.1 }):Play()
end

-- ============ Main Loops ============
local function getClosestItem(itemName)
    if not rootPart then return nil, math.huge end
    local closest, minDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("Model")) and obj.Name:lower():find(itemName) then
            local pos = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")).Position or obj.Position
            if pos then
                local d = (pos - rootPart.Position).Magnitude
                if d < minDist then minDist = d; closest = pos end
            end
        end
    end
    return closest, minDist
end

local function getClosestNextbot()
    if not rootPart then return nil, math.huge end
    local closest, minDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local isBot = false
            if hum then if not Players:GetPlayerFromCharacter(obj) then isBot = true end
            elseif obj.Name:lower():find("bot") or obj.Name:lower():find("nextbot") or obj.Name:lower():find("killer") then isBot = true end
            if isBot then
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                if hrp then
                    local d = (hrp.Position - rootPart.Position).Magnitude
                    if d < minDist then minDist = d; closest = hrp end
                end
            end
        end
    end
    return closest, minDist
end

task.spawn(function()
    while task.wait(0.15) do
        if not humanoid or not rootPart or humanoid.Health <= 0 then continue end
        
        if state.autoRevive then
            for _, v in ipairs(character:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.ActionText:lower():find("revive") then
                    v:InputHoldBegin() task.wait(0.1) v:InputHoldEnd()
                end
            end
        end
        
        local botPart, botDist = getClosestNextbot()
        if state.nextbotEsp and botPart then
            local botModel = botPart.Parent
            if not espHighlights[botModel] or not espHighlights[botModel].Parent then
                espHighlights[botModel] = create("Highlight", { Parent = botModel, FillColor = Color3.fromRGB(255, 0, 0), OutlineColor = Color3.fromRGB(255, 255, 255), FillTransparency = 0.5, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop })
            end
        end
        
        if state.autoEvade and botPart and botDist < state.evadeRange then
            local camCF = workspace.CurrentCamera.CFrame
            rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 50, 0) - (botPart.Position - rootPart.Position).Unit * 30)
            notify("Auto Evade", "บอทเข้ามาใกล้! วาร์ปหนีแล้ว", Theme.danger)
            task.wait(1)
        end
        
        if state.autoCollect then
            local itemPos, dist = getClosestItem("candy")
            if not itemPos or dist > 100 then itemPos, dist = getClosestItem("item") end
            if itemPos and dist > 3 then humanoid:MoveTo(itemPos) end
        end
    end
end)

-- ⭐ ลูปการทำงานหลัก (Jump, Slide, Godmode)
RunService.Heartbeat:Connect(function()
    if not humanoid or not rootPart or humanoid.Health <= 0 then return end
    
    -- Auto Jump / Jump Button
    if (state.autoJump or state.jumpBtnToggled) and humanoid.FloorMaterial ~= Enum.Material.Air then
        attemptJump()
    end
    
    -- Infinite Slide (Bypass ด้วย Velocity)
    if state.infiniteSlide then
        local moveDir = humanoid.MoveDirection
        local camCF = workspace.CurrentCamera.CFrame
        if moveDir.Magnitude > 0.1 then
            -- พุ่งตามทิศทางที่กด WASD
            rootPart.Velocity = Vector3.new(moveDir.X * 60, rootPart.Velocity.Y, moveDir.Z * 60)
        else
            -- พุ่งไปข้างหน้าตามกล้อง
            rootPart.Velocity = Vector3.new(camCF.LookVector.X * 60, rootPart.Velocity.Y, camCF.LookVector.Z * 60)
        end
    end
    
    -- Anti-Ragdoll & Godmode & Speed
    if state.antiRagdoll then
        if humanoid:GetState() == Enum.HumanoidStateType.FallingDown or humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end
    if state.godmode and humanoid.Health < humanoid.MaxHealth then pcall(function() humanoid.Health = humanoid.MaxHealth end) end
    if state.speedEnabled and humanoid.WalkSpeed ~= state.walkSpeed then humanoid.WalkSpeed = state.walkSpeed end
end)

RunService.Stepped:Connect(function()
    if state.noclip and character then
        for _, part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end
end)

-- ⭐ ระบบกด Spacebar สำหรับ Inf Jump (PC)
UserInputService.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.Space then
        if state.infJump and humanoid and humanoid.FloorMaterial == Enum.Material.Air then
            attemptJump()
        end
    end
    if i.KeyCode == Enum.KeyCode.RightShift then
        local sg = playerGui:FindFirstChild("HelloHubUI")
        if sg then sg.Enabled = not sg.Enabled end
    end
end)

player.Idled:Connect(function()
    if state.antiAfk then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end
end)

-- Start
buildFloatingUI()
buildGUI()
notify("Hello Hub", "โหลดระบบ Evade สมบูรณ์แบบ!", Theme.success)
print("[HelloHub] ✅ Supreme Evade Edition Loaded!")
