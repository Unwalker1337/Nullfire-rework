local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Clipboard = setclipboard or toclipboard or function() end

local THEME = {
    Background = Color3.fromRGB(22, 22, 28),
    Header = Color3.fromRGB(28, 28, 36),
    Accent = Color3.fromRGB(0, 170, 255),
    Text = Color3.fromRGB(220, 220, 230),
    TextDim = Color3.fromRGB(140, 140, 150),
    EntryBg = Color3.fromRGB(30, 30, 38),
    EntryAlt = Color3.fromRGB(26, 26, 34),
    Green = Color3.fromRGB(0, 200, 120),
    Red = Color3.fromRGB(220, 50, 60),
    Orange = Color3.fromRGB(255, 170, 40),
    Border = Color3.fromRGB(40, 40, 50),
}

local function create(c, p, kids)
    local o = Instance.new(c)
    for k, v in pairs(p) do o[k] = v end
    for _, kid in ipairs(kids or {}) do kid.Parent = o end
    return o
end

local function trunc(s, n)
    return #s > n and s:sub(1, n - 3) .. "..." or s
end

local function fmtTime(sec)
    if not sec then return "--" end
    return string.format("%d:%02d", math.floor(sec / 60), math.floor(sec % 60))
end

local gui = Instance.new("ScreenGui")
gui.Name = "SoundSpy"
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = create("Frame", {
    Parent = gui, BackgroundColor3 = THEME.Background, BorderSizePixel = 0,
    Position = UDim2.new(0.5, -190, 0.5, -260), Size = UDim2.new(0, 380, 0, 520),
}, {
    create("UICorner", {CornerRadius = UDim.new(0, 8)}),
    create("Frame", {Name = "Header", BackgroundColor3 = THEME.Header, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 36)}, {
        create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        create("UIStroke", {Color = THEME.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}),
        create("Frame", {BackgroundColor3 = THEME.Accent, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2)}),
        create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0, 200, 1, 0), Font = Enum.Font.GothamSemibold, Text = "SoundSpy v2.0", TextColor3 = THEME.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}),
        create("ImageButton", {Name = "DragArea", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", ImageTransparency = 1, Active = false}),
        create("ImageButton", {Name = "CloseBtn", BackgroundColor3 = Color3.fromRGB(45, 45, 55), Position = UDim2.new(1, -30, 0, 8), Size = UDim2.new(0, 20, 0, 20)}, {
            create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.Gotham, Text = "x", TextColor3 = THEME.TextDim, TextSize = 18}),
        }),
    }),
    create("Frame", {Name = "Toolbar", BackgroundColor3 = THEME.Header, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 40)}, {
        create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center}),
        create("UIPadding", {PaddingLeft = UDim.new(0, 8)}),
        create("ImageButton", {Name = "RefreshBtn", BackgroundColor3 = THEME.Accent, BorderSizePixel = 0, Size = UDim2.new(0, 50, 0, 28), AutoButtonColor = false}, {
            create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamSemibold, Text = "Scan", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12}),
        }),
        create("ImageButton", {Name = "StopAllBtn", BackgroundColor3 = THEME.Red, BorderSizePixel = 0, Size = UDim2.new(0, 60, 0, 28), AutoButtonColor = false}, {
            create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamSemibold, Text = "Stop All", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12}),
        }),
        create("ImageButton", {Name = "PlayAllBtn", BackgroundColor3 = THEME.Green, BorderSizePixel = 0, Size = UDim2.new(0, 60, 0, 28), AutoButtonColor = false}, {
            create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamSemibold, Text = "Play All", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12}),
        }),
        create("ImageButton", {Name = "ExportBtn", BackgroundColor3 = THEME.Orange, BorderSizePixel = 0, Size = UDim2.new(0, 50, 0, 28), AutoButtonColor = false}, {
            create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamSemibold, Text = "Export", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12}),
        }),
    }),
    create("Frame", {Name = "SearchBox", BackgroundColor3 = THEME.EntryBg, BorderSizePixel = 0, Position = UDim2.new(0, 8, 0, 80), Size = UDim2.new(1, -16, 0, 28)}, {
        create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        create("UIStroke", {Color = THEME.Border, Thickness = 1}),
        create("TextBox", {Name = "Input", BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, PlaceholderColor3 = THEME.TextDim, PlaceholderText = "Filter by name or SoundId...", Text = "", TextColor3 = THEME.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false}),
    }),
    create("Frame", {Name = "InfoBar", BackgroundColor3 = THEME.EntryBg, BorderSizePixel = 0, Position = UDim2.new(0, 8, 0, 112), Size = UDim2.new(1, -16, 0, 22)}, {
        create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        create("TextLabel", {Name = "Label", BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = "scanning...", TextColor3 = THEME.TextDim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}),
    }),
    create("ScrollingFrame", {Name = "List", BackgroundColor3 = THEME.Background, BorderSizePixel = 0, Position = UDim2.new(0, 4, 0, 138), Size = UDim2.new(1, -8, 1, -142), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Accent, ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right}, {
        create("UIListLayout", {Name = "Layout", Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.Name}),
    }),
    create("UIStroke", {Color = THEME.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}),
})

local dragging, dragStart, framePos
frame.Header.DragArea.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = inp.Position; framePos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + d.X, framePos.Y.Scale, framePos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
frame.CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- tracking
local knownSounds = {}
local trackedSounds = {}
local activeConns = {}
local hooksActive = false

local function onNewSound(snd)
    if knownSounds[snd] then return end
    knownSounds[snd] = true
end

local function getSoundInfo(snd)
    local timeInfo = snd.TimeLength and snd.TimeLength > 0
        and fmtTime(snd.TimePosition) .. " / " .. fmtTime(snd.TimeLength) or "--"
    local id = snd.SoundId or ""
    local cleanId = id:match("rbxassetid://(%d+)") or id:match("(%d+)") or id
    return {
        instance = snd, name = snd.Name,
        parent = snd.Parent and snd.Parent:GetFullName() or "--",
        soundId = trunc(cleanId, 22), rawId = cleanId,
        volume = string.format("%.1f", snd.Volume),
        pitch = string.format("%.2f", snd.PlaybackSpeed),
        looping = snd.Looping, playing = snd.Playing, timeInfo = timeInfo,
    }
end

-- scanning: use all available methods
local function collectSounds()
    local found = {}
    local seen = {}
    local function add(snd)
        if typeof(snd) ~= "Instance" then return end
        local ok = pcall(function() return snd:IsA("Sound") end)
        if ok and snd:IsA("Sound") and not seen[snd] then
            seen[snd] = true
            table.insert(found, snd)
        end
    end

    -- 1) getinstances() — all instances in memory
    if getinstances then
        for _, obj in ipairs(getinstances()) do add(obj) end
    end

    -- 2) gethiddeninstances()
    if gethiddeninstances then
        for _, obj in ipairs(gethiddeninstances()) do add(obj) end
    end

    -- 3) getnilinstances()
    if getnilinstances then
        for _, obj in ipairs(getnilinstances()) do add(obj) end
    end

    -- 4) traditional service scan as fallback
    local services = {
        Workspace, ReplicatedStorage, ServerStorage, ServerScriptService,
        SoundService, StarterGui, StarterPlayer, ReplicatedFirst, Players,
    }
    for _, svc in ipairs(services) do
        local ok, kids = pcall(function() return svc:GetDescendants() end)
        if ok then
            for _, child in ipairs(kids) do add(child) end
        end
    end

    -- 5) any tracked via hooks
    for snd, _ in pairs(knownSounds) do add(snd) end

    return found
end

-- hooks
local function setupHooks()
    if hooksActive then return end
    hooksActive = true

    -- hook Instance.new for Sound creation
    local oldNew = Instance.new
    local safeNew = newcclosure or function(f, ...) return f(...) end
    Instance.new = safeNew(function(class, ...)
        local obj = oldNew(class, ...)
        if type(class) == "string" and (class == "Sound" or class == "AudioPlayer") then
            onNewSound(obj)
        end
        return obj
    end)

    -- hook Sound:Play to catch any sound that plays
    local oldPlay = Sound.Play
    local safePlay = newcclosure or function(f, ...) return f(...) end
    Sound.Play = safePlay(function(self, ...)
        if typeof(self) == "Instance" then
            onNewSound(self)
        end
        return oldPlay(self, ...)
    end)
end

-- UI helpers
local function stopSound(snd) snd:Stop() end
local function toggleSound(snd) if snd.Playing then snd:Pause() else snd:Resume() end end
local function updateVisual(entry, snd)
    local info = getSoundInfo(snd)
    entry.Indicator.BackgroundColor3 = info.playing and THEME.Green or THEME.TextDim
    entry.TimeLabel.Text = info.timeInfo
end

local function createEntry(info, i)
    local altBg = i % 2 == 0 and THEME.EntryBg or THEME.EntryAlt
    local entry = create("Frame", {BackgroundColor3 = altBg, BorderSizePixel = 0, Size = UDim2.new(1, -4, 0, 48), LayoutOrder = i}, {
        create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        create("Frame", {Name = "Indicator", BackgroundColor3 = info.playing and THEME.Green or THEME.TextDim, BorderSizePixel = 0, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0, 3, 1, 0)}, {
            create("UICorner", {CornerRadius = UDim.new(0, 2)}),
        }),
        create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 4), Size = UDim2.new(0, 170, 0, 16), Font = Enum.Font.GothamSemibold, Text = trunc(info.name, 24), TextColor3 = THEME.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}),
        create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 20), Size = UDim2.new(0, 220, 0, 14), Font = Enum.Font.Gotham, Text = trunc(info.parent, 44), TextColor3 = THEME.TextDim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}),
        create("TextLabel", {Name = "TimeLabel", BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 32), Size = UDim2.new(0, 120, 0, 14), Font = Enum.Font.Gotham, Text = info.timeInfo, TextColor3 = THEME.TextDim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}),
        create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1, -110, 0, 4), Size = UDim2.new(0, 100, 0, 14), Font = Enum.Font.Gotham, Text = "ID: " .. info.soundId, TextColor3 = THEME.TextDim, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right}),
        create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1, -110, 0, 16), Size = UDim2.new(0, 100, 0, 14), Font = Enum.Font.Gotham, Text = "Vol: " .. info.volume .. " Pitch: " .. info.pitch, TextColor3 = THEME.TextDim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right}),
        create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(1, -110, 0, 28), Size = UDim2.new(0, 100, 0, 14), Font = Enum.Font.Gotham, Text = info.looping and "Loop" or "Once", TextColor3 = info.looping and THEME.Orange or THEME.TextDim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right}),
        create("ImageButton", {Name = "CopyBtn", BackgroundColor3 = Color3.fromRGB(60, 60, 70), BorderSizePixel = 0, Position = UDim2.new(1, -78, 0, 30), Size = UDim2.new(0, 22, 0, 16), AutoButtonColor = false}, {
            create("UICorner", {CornerRadius = UDim.new(0, 3)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamSemibold, Text = "[]", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10}),
        }),
        create("ImageButton", {Name = "PlayBtn", BackgroundColor3 = info.playing and THEME.Orange or THEME.Green, BorderSizePixel = 0, Position = UDim2.new(1, -52, 0, 30), Size = UDim2.new(0, 22, 0, 16), AutoButtonColor = false}, {
            create("UICorner", {CornerRadius = UDim.new(0, 3)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamSemibold, Text = info.playing and "||" or ">", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10}),
        }),
        create("ImageButton", {Name = "StopBtn", BackgroundColor3 = THEME.Red, BorderSizePixel = 0, Position = UDim2.new(1, -26, 0, 30), Size = UDim2.new(0, 22, 0, 16), AutoButtonColor = false}, {
            create("UICorner", {CornerRadius = UDim.new(0, 3)}),
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamSemibold, Text = "#", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 10}),
        }),
    })

    local snd = info.instance
    entry.PlayBtn.MouseButton1Click:Connect(function() toggleSound(snd); updateVisual(entry, snd) end)
    entry.StopBtn.MouseButton1Click:Connect(function() stopSound(snd); updateVisual(entry, snd) end)
    entry.CopyBtn.MouseButton1Click:Connect(function()
        local id = snd.SoundId or ""
        local clean = id:match("rbxassetid://(%d+)") or id:match("(%d+)") or id
        pcall(function() Clipboard("rbxassetid://" .. clean) end)
        entry.CopyBtn.BackgroundColor3 = THEME.Green
        task.delay(0.5, function() entry.CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70) end)
    end)

    local conn = RunService.Heartbeat:Connect(function()
        if not snd or not snd.Parent then
            if conn then conn:Disconnect() end
            return
        end
        if snd.Playing then
            local i2 = getSoundInfo(snd)
            entry.Indicator.BackgroundColor3 = THEME.Green
            entry.TimeLabel.Text = i2.timeInfo
        else
            entry.Indicator.BackgroundColor3 = THEME.TextDim
        end
    end)
    table.insert(activeConns, conn)
    return entry
end

local cachedList = {}

local function refresh()
    for _, child in ipairs(frame.List:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, c in ipairs(activeConns) do pcall(c.Disconnect, c) end
    activeConns = {}

    local searchText = frame.SearchBox.Input.Text:lower()
    local allSounds = collectSounds()
    cachedList = allSounds

    local filtered = {}
    for _, snd in ipairs(allSounds) do
        if searchText == "" or snd.Name:lower():find(searchText, 1, true) or tostring(snd.SoundId):lower():find(searchText, 1, true) then
            table.insert(filtered, snd)
        end
    end
    table.sort(filtered, function(a, b)
        local pa = a.Parent and a.Parent:GetFullName() or a.Name
        local pb = b.Parent and b.Parent:GetFullName() or b.Name
        return pa:lower() < pb:lower()
    end)

    trackedSounds = {}
    for i, snd in ipairs(filtered) do
        local info = getSoundInfo(snd)
        local entry = createEntry(info, i)
        entry.Parent = frame.List
        trackedSounds[snd] = entry
    end

    local hookStatus = hooksActive and " (hooked)" or ""
    frame.InfoBar.Label.Text = #filtered .. " sound" .. (#filtered ~= 1 and "s" or "") .. hookStatus .. " found"
end

frame.RefreshBtn.MouseButton1Click:Connect(refresh)
frame.SearchBox.Input.FocusLost:Connect(function() refresh() end)
frame.SearchBox.Input.Changed:Connect(function(prop) if prop == "Text" then refresh() end end)
frame.StopAllBtn.MouseButton1Click:Connect(function()
    local any = false
    for snd, _ in pairs(trackedSounds) do pcall(function() snd:Stop(); any = true end) end
    if any then refresh() end
end)
frame.PlayAllBtn.MouseButton1Click:Connect(function()
    for snd, _ in pairs(trackedSounds) do pcall(function() snd:Play() end) end
    refresh()
end)
frame.ExportBtn.MouseButton1Click:Connect(function()
    local lines = {"SoundSpy Export v2.0", "---"}
    for _, snd in ipairs(cachedList) do
        local info = getSoundInfo(snd)
        table.insert(lines, string.format("%s | %s | ID: %s | Vol: %s | %s | %s",
            info.name, info.playing and "PLAYING" or "stopped",
            info.rawId, info.volume, info.looping and "loop" or "once", info.parent))
    end
    pcall(function() Clipboard(table.concat(lines, "\n")) end)
    local old = frame.ExportBtn.BackgroundColor3
    frame.ExportBtn.BackgroundColor3 = THEME.Green
    task.delay(0.8, function() frame.ExportBtn.BackgroundColor3 = old end)
end)

-- init
setupHooks()
refresh()

spawn(function()
    while gui and gui.Parent do
        task.wait(2)
        if frame.Visible then refresh() end
    end
end)

print("SoundSpy v2.0 loaded — hooks active:", hooksActive)
