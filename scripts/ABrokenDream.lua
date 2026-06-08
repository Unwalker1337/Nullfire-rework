--[[
    NullFire Hub - A Broken Dream
    https://github.com/Unwalker1337/Nullfire-rework
--]]

local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "NullFire Hub - A Broken Dream",
    Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2
})

local Tabs = {
    Music = Window:AddTab("Музыка"),
    Player = Window:AddTab("Игрок"),
    Teleports = Window:AddTab("Телепорты"),
    NPC = Window:AddTab("NPC"),
    World = Window:AddTab("Мир"),
    Effects = Window:AddTab("Эффекты"),
    UI = Window:AddTab("Настройки"),
}

local lp = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local ws = workspace
local ts = game:GetService("TweenService")
local ls = game:GetService("Lighting")

repeat task.wait() until ws:GetAttribute("ClientLoadedIn")
repeat task.wait() until lp:GetAttribute("SetUpPlayerFully")

local LobbyMusic = rs:WaitForChild("LobbyMusic")
local OSTScreen = lp:WaitForChild("PlayerGui"):WaitForChild("OSTTVScreen")
local SpeechGui = lp:WaitForChild("PlayerGui"):WaitForChild("SpeechGui")
local DonationGui = lp:WaitForChild("PlayerGui"):WaitForChild("DonationGui")
local ScreenFX = lp:WaitForChild("PlayerGui"):FindFirstChild("ScreenEffectGui")

local function rmt(n) return rs:FindFirstChild(n) end
local function fsrv(n, ...) local r = rmt(n); if r then r:FireServer(...) end end
local function fcl(n, ...) local r = rmt(n); if r then r:Fire(...) end end
local function say(t, o) fcl("SayThing", t, o or {"InfoText"}) end
local function nfy(t, tm) Library:Notify(t, tm or 3) end
local function tp(cf)
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cf
    end
end
local function tpf(cf, r) tp(cf); if r then fsrv(r) end end

local function getDreamEntries()
    local entries = {}
    local stored = lp:FindFirstChild("StoredThings")
    if stored then
        for _, c in pairs(stored:GetChildren()) do
            if c.Name == "DreamEntry" and c:IsA("StringValue") then
                table.insert(entries, c.Value)
            end
        end
    end
    return entries
end

-- ===================== MUZYKA =====================
local MusicGroup = Tabs.Music:AddLeftGroupbox("Музыкальный плеер")

local function getTracks()
    local t = {}
    for _, c in ipairs(LobbyMusic:GetChildren()) do
        if c:IsA("Sound") then table.insert(t, c) end
    end
    table.sort(t, function(a,b) return tonumber(a.Name) < tonumber(b.Name) end)
    return t
end

local function getTrackNames()
    local n = {}
    for _, t in ipairs(getTracks()) do table.insert(n, t:GetAttribute("RealName") or "Трек " .. t.Name) end
    return n
end

local TrackLabel
local function updateTrackLabel()
    local tracks = getTracks()
    local idx
    for i, t in ipairs(tracks) do
        if t.SoundId == LobbyMusic.SoundId then idx = i; break end
    end
    if idx then
        TrackLabel:SetText("Сейчас: " .. (tracks[idx]:GetAttribute("RealName") or "Трек " .. tracks[idx].Name) .. " (" .. idx .. "/" .. #tracks .. ")")
    else
        TrackLabel:SetText("Не играет")
    end
end

local function switchTrack(delta)
    local tracks = getTracks()
    local idx
    for i, t in ipairs(tracks) do
        if t.SoundId == LobbyMusic.SoundId then idx = i; break end
    end
    idx = idx or 0
    local new = idx + delta
    if new < 1 then new = #tracks elseif new > #tracks then new = 1 end
    if tracks[new] then
        local tr = tracks[new]
        LobbyMusic:Stop()
        LobbyMusic.Volume = tr.Volume
        LobbyMusic.SoundId = tr.SoundId
        if tr.PlaybackRegionsEnabled then
            LobbyMusic.PlaybackRegionsEnabled = true
            LobbyMusic.LoopRegion = tr.LoopRegion
            LobbyMusic.PlaybackRegion = tr.PlaybackRegion
        else
            LobbyMusic.PlaybackRegionsEnabled = false
        end
        LobbyMusic:Play()
        nfy("Трек: " .. (tr:GetAttribute("RealName") or "Трек " .. tr.Name))
        updateTrackLabel()
    end
end

TrackLabel = MusicGroup:AddLabel("Сканирование...")
MusicGroup:AddButton({ Text = "Предыдущий трек", Func = function() switchTrack(-1) end })
MusicGroup:AddButton({ Text = "Следующий трек", Func = function() switchTrack(1) end })
MusicGroup:AddButton({ Text = "Обновить", Func = updateTrackLabel })
MusicGroup:AddDivider()

MusicGroup:AddSlider("MusicVolume", {
    Text = "Громкость", Default = 100, Min = 0, Max = 200, Rounding = 0, Suffix = "%",
    Callback = function(v) LobbyMusic.Volume = v / 100 end
})

MusicGroup:AddToggle("MusicAutoNext", { Text = "Авто переключение", Default = false })

task.spawn(function()
    while task.wait(0.5) do
        if Toggles.MusicAutoNext and not LobbyMusic.Playing then switchTrack(1) end
    end
end)

local PlaylistGroup = Tabs.Music:AddRightGroupbox("Плейлист")
PlaylistGroup:AddDropdown("TrackSelect", {
    Values = getTrackNames(), Default = 1, Text = "Перейти к треку",
    Callback = function(val)
        local tracks = getTracks()
        for i, t in ipairs(tracks) do
            if (t:GetAttribute("RealName") or "Трек " .. t.Name) == val then
                LobbyMusic:Stop()
                LobbyMusic.Volume = t.Volume
                LobbyMusic.SoundId = t.SoundId
                if t.PlaybackRegionsEnabled then
                    LobbyMusic.PlaybackRegionsEnabled = true
                    LobbyMusic.LoopRegion = t.LoopRegion
                    LobbyMusic.PlaybackRegion = t.PlaybackRegion
                else
                    LobbyMusic.PlaybackRegionsEnabled = false
                end
                LobbyMusic:Play()
                updateTrackLabel()
                break
            end
        end
    end
})

PlaylistGroup:AddDivider()
local listLabel = PlaylistGroup:AddLabel("Загрузка...", true)
local function refreshTrackInfo()
    local tracks = getTracks()
    local lines = {}
    for i, t in ipairs(tracks) do
        local name = t:GetAttribute("RealName") or "Трек " .. t.Name
        local unused = t:GetAttribute("Unused") and " [скрыт]" or ""
        table.insert(lines, i .. ". " .. name .. unused)
    end
    if #lines == 0 then table.insert(lines, "Нет треков") end
    listLabel:SetText(table.concat(lines, "\n"))
end
PlaylistGroup:AddButton({ Text = "Обновить", Func = refreshTrackInfo })
task.delay(0.5, refreshTrackInfo)

-- ===================== PLAYER =====================
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Информация")
PlayerGroup:AddLabel("Chapter 2: " .. (lp:GetAttribute("CompletedCH2Binary") or "0"))
PlayerGroup:AddLabel("Устройство: " .. (lp:GetAttribute("device") or "ПК"))

PlayerGroup:AddDivider()
PlayerGroup:AddLabel("Dream Entries:", false)
local dreamEntryLabel = PlayerGroup:AddLabel("Загрузка...", true)
local function updateDreamEntries()
    local e = getDreamEntries()
    dreamEntryLabel:SetText(#e > 0 and table.concat(e, ", ") or "Нет")
end
task.delay(0.5, updateDreamEntries)

PlayerGroup:AddDivider()
PlayerGroup:AddLabel("Атрибуты:", false)
local attrsLabel = PlayerGroup:AddLabel("", true)
local function refreshAttrs()
    local lines = {}
    for _, k in ipairs({"CompletedCH2Binary","device","HasAeroportTicket","SetUpPlayerFully"}) do
        table.insert(lines, k .. " = " .. tostring(lp:GetAttribute(k)))
    end
    attrsLabel:SetText(table.concat(lines, "\n"))
end
PlayerGroup:AddButton({ Text = "Обновить", Func = refreshAttrs })

local PlayerSettings = Tabs.Player:AddRightGroupbox("Настройки")
PlayerSettings:AddToggle("UnlockMusic", {
    Text = "Разблокировать OST", Default = true,
    Callback = function(v)
        local f = OSTScreen:FindFirstChild("Frame")
        local c = OSTScreen:FindFirstChild("CantAccessText")
        if f then f.Visible = v end
        if c then c.Visible = not v end
    end
})

PlayerSettings:AddToggle("NoCutscene", { Text = "Блокировать катсцены", Default = false })
task.spawn(function()
    while task.wait(1) do
        if Toggles.NoCutscene and ws:GetAttribute("Cutscene") then
            ws:SetAttribute("Cutscene", nil)
        end
    end
end)

PlayerSettings:AddToggle("UnanchorCutscene", { Text = "Открепить при катсцене", Default = false })
task.spawn(function()
    while task.wait(0.5) do
        if Toggles.UnanchorCutscene and ws:GetAttribute("Cutscene") then
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.Anchored = false
            end
        end
    end
end)

PlayerSettings:AddDivider()
PlayerSettings:AddButton({ Text = "Force Nod (-5)", Func = function()
    local fn = rmt("ForceNod"); if fn then fn:Fire(-5) end
end})
PlayerSettings:AddButton({ Text = "Force FOV (-15)", Func = function()
    local fov = rmt("ForceFOVBindable"); if fov then fov:Fire(-15, 0.5) end
end})
PlayerSettings:AddButton({ Text = "Screenshake (3)", Func = function()
    local sh = rmt("ScreenshakeBindable"); if sh then sh:Fire(3) end
end})

PlayerSettings:AddDivider()
PlayerSettings:AddLabel("Донат:")
for _, item in ipairs({{"Донат 1",3344306026},{"Донат 2",3344306942},{"Донат 3",3344307148},{"Донат 4",3344307629}}) do
    PlayerSettings:AddButton({ Text = "Купить " .. item[1], Func = function()
        game:GetService("MarketplaceService"):PromptProductPurchase(lp, item[2])
    end})
end

-- ===================== TELEPORTS =====================
local TpLobby = Tabs.Teleports:AddLeftGroupbox("Лобби")
TpLobby:AddButton({ Text = "Main Hall Spawn", Func = function()
    local s = ws:FindFirstChild("SpawnLocations")
    if s then
        local loc = s:FindFirstChild("MainHallSpawnLocation")
        if loc then tpf(loc.CFrame, "selfTeleported") end
    end
end})
TpLobby:AddButton({ Text = "Выход Main Hall", Func = function()
    local cf = ws:GetAttribute("ExitMainHallCFrame")
    if cf then tpf(cf, "selfTeleported") end
end})
TpLobby:AddButton({ Text = "Выход Outside Minigame", Func = function()
    local cf = ws:GetAttribute("ExitOutsideMinigameCFrame")
    if cf then tpf(cf, "selfTeleported") end
end})

TpLobby:AddDivider()
TpLobby:AddLabel("Секретки:")
TpLobby:AddButton({ Text = "Секретный Main Hall", Func = function()
    local cf = ws:GetAttribute("SecretMainHallCFrame")
    if cf then tpf(cf, "selfTeleported") end
end})
TpLobby:AddButton({ Text = "Секретный выход", Func = function()
    local cf = ws:GetAttribute("SecretExitCFrame")
    if cf then tpf(cf, "selfTeleported") end
end})

TpLobby:AddDivider()
TpLobby:AddLabel("Падение в облака:")
TpLobby:AddButton({ Text = "Упасть", Func = function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local fall = ws:FindFirstChild("FallCatcherSpawns")
        if fall then
            local sp = fall:FindFirstChild("CatcherSpawn")
            if sp then
                ws:SetAttribute("Cutscene", true)
                lp.Character.HumanoidRootPart.Anchored = true
                lp.Character.HumanoidRootPart.CFrame = sp.CFrame
                ts:Create(lp.Character.HumanoidRootPart, TweenInfo.new(4, Enum.EasingStyle.Sine), {
                    CFrame = sp.CFrame - Vector3.new(0, 136, 0)
                }):Play()
                local fb = ls:FindFirstChild("FallBright")
                if fb then fb.Brightness = 1; ts:Create(fb, TweenInfo.new(1), {Brightness = 0}):Play() end
                ws:SetAttribute("WindFalling", true)
                task.delay(4, function()
                    ws:SetAttribute("WindFalling", nil)
                    ws:SetAttribute("Cutscene", nil)
                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.Anchored = false
                    end
                    local fn = rmt("ForceNod"); if fn then fn:Fire(-5) end
                    fsrv("FellIntoCloud")
                    local sh = rmt("ScreenshakeBindable"); if sh then sh:Fire(3) end
                end)
            end
        end
    end
end})

local WarpGroup = Tabs.Teleports:AddRightGroupbox("Зоны")
local function scanWarps()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "WarpTeleportPart" and c:IsA("BasePart") and c:GetAttribute("WarpTo") then
            WarpGroup:AddButton({ Text = "Warp: " .. (c.Parent and c.Parent.Name or "?"), Func = function()
                local w = c:GetAttribute("WarpTo")
                if w then tp(w) end
            end})
        end
    end
end
WarpGroup:AddButton({ Text = "Сканировать Warp", Func = scanWarps })
task.delay(1, scanWarps)

WarpGroup:AddDivider()
WarpGroup:AddLabel("Forcefield Borders:")
local function scanFF()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name:match("ForcefieldBorder") and c:IsA("BasePart") and c:GetAttribute("SideRelationship") then
            WarpGroup:AddButton({ Text = "FF: " .. c.Name, Func = function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    lp.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + c:GetAttribute("SideRelationship") * 370
                    fsrv("HeyITeleported")
                end
            end})
        end
    end
end
WarpGroup:AddButton({ Text = "Сканировать", Func = scanFF })
task.delay(1.5, scanFF)

WarpGroup:AddDivider()
WarpGroup:AddLabel("Blink Borders:")
local function scanBlink()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "BlinkBorder" and c:IsA("BasePart") then
            WarpGroup:AddButton({ Text = "Blink: " .. (c.Parent and c.Parent.Name or "?"), Func = function()
                if ws:GetAttribute("Cutscene") then return end
                local gb = c:GetAttribute("GoBackPlace")
                tp(gb or (lp.Character and lp.Character:GetAttribute("WhereSpawned")) or CFrame.new())
            end})
        end
    end
end
WarpGroup:AddButton({ Text = "Сканировать", Func = scanBlink })
task.delay(2, scanBlink)

local DoorGroup = Tabs.Teleports:AddLeftGroupbox("Двери в миры")
local function scanDoors()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "LobbyTeleportDoor" and c:IsA("BasePart") then
            local pid = c:GetAttribute("TeleportPlaceID") or "?"
            DoorGroup:AddButton({ Text = "Дверь [" .. pid .. "]", Func = function()
                tp(c.CFrame * CFrame.new(0, 0, -5))
                if pid ~= "?" then fsrv("LobbyDoorTP", pid) end
            end})
        end
    end
end
DoorGroup:AddButton({ Text = "Сканировать", Func = scanDoors })
task.delay(1, scanDoors)

-- ===================== NPC =====================
local NPCGroup = Tabs.NPC:AddLeftGroupbox("Диалоги")
NPCGroup:AddDropdown("SelectNPC", { Values = {"Minecraftpeter","SnoogleBrosPlayz"}, Default = 1, Text = "NPC" })
NPCGroup:AddButton({ Text = "Активировать диалог", Func = function()
    local name = Options.SelectNPC.Value
    local npcs = ws:FindFirstChild("RigNPCS")
    if npcs then
        local char = npcs:FindFirstChild(name)
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local prompt = root:FindFirstChild("ProximityPrompt")
                if prompt then fsrv("ProximityPromptTriggered", prompt) end
            end
        end
    end
end})
NPCGroup:AddButton({ Text = "Телепорт к NPC", Func = function()
    local name = Options.SelectNPC.Value
    local npcs = ws:FindFirstChild("RigNPCS")
    if npcs then
        local char = npcs:FindFirstChild(name)
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0,0,-3)
            end
        end
    end
end})

NPCGroup:AddDivider()
NPCGroup:AddLabel("SnoogleBrosPlayz текст:")
NPCGroup:AddInput("CustomNPCText", { Default = "", Text = "Текст", Placeholder = "Введи...",
    Callback = function(val) if val ~= "" then fcl("MakeSnoogleSaySomething", val) end end
})

local AnimGroup = Tabs.NPC:AddRightGroupbox("Анимации")
AnimGroup:AddButton({ Text = "Перезагрузить анимации", Func = function()
    local rigs = rs:FindFirstChild("Anims")
    if rigs then
        local ra = rigs:FindFirstChild("RigAnims")
        local npcs = ws:FindFirstChild("RigNPCS")
        if ra and npcs then
            for _, npc in pairs(npcs:GetChildren()) do
                local anim = ra:FindFirstChild(npc.Name)
                if anim and npc:FindFirstChild("Humanoid") then
                    local hum = npc:FindFirstChild("Humanoid")
                    if hum then
                        local animator = hum:FindFirstChild("Animator") or Instance.new("Animator", hum)
                        local track = animator:LoadAnimation(anim)
                        track.Priority = Enum.AnimationPriority.Action4
                        track.Looped = true
                        track:Play()
                    end
                end
            end
            nfy("Анимации перезагружены")
        end
    end
end})

local PaintGroup = Tabs.NPC:AddRightGroupbox("Dream Journal Paintings")
local function scanPaintings()
    local paintings = ws:FindFirstChild("DreamJournalPaintings")
    if paintings then
        local entries = getDreamEntries()
        for _, child in pairs(paintings:GetChildren()) do
            local dn = child.Name:gsub("Painting", "")
            local col = table.find(entries, dn)
            PaintGroup:AddButton({
                Text = (col and "[X] " or "[ ] ") .. dn,
                Func = function() nfy("Dream: " .. dn .. (col and " (собран)" or " (не собран)")) end
            })
        end
    end
end
PaintGroup:AddButton({ Text = "Обновить", Func = scanPaintings })
task.delay(1, scanPaintings)

-- ===================== WORLD =====================
local WorldGroup = Tabs.World:AddLeftGroupbox("Объекты")
WorldGroup:AddButton({ Text = "Сканировать воспоминания", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name:match("MemoryRecollector") and c:IsA("BasePart") then
            WorldGroup:AddButton({ Text = "Собрать: " .. c.Name, Func = function() fsrv("GotMemory", c) end})
        end
    end
end})

WorldGroup:AddDivider()
WorldGroup:AddLabel("Piano:")
WorldGroup:AddButton({ Text = "Случайная нота", Func = function() fsrv("PianoKeyPressed", math.random(1, 88)) end})

WorldGroup:AddDivider()
WorldGroup:AddLabel("Pocket Doors:")
WorldGroup:AddButton({ Text = "Сканировать", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name:match("PocketDoorDetector") and c:IsA("BasePart") then
            WorldGroup:AddButton({ Text = "Дверь: " .. c.Name, Func = function()
                fsrv("TouchedDoorDetector", c.Name)
            end})
        end
    end
end})

WorldGroup:AddDivider()
WorldGroup:AddLabel("Moving Signs:")
WorldGroup:AddToggle("ShakeSigns", { Text = "Трясти вывески", Default = false })
task.spawn(function()
    while task.wait(0.1) do
        if Toggles.ShakeSigns then
            local ss = ws:FindFirstChild("MovingSignStuff")
            if ss then
                for _, c in pairs(ss:GetDescendants()) do
                    if c:IsA("TextLabel") or c:IsA("ImageLabel") then
                        c.Position = UDim2.new(0.5 + math.random(-10,10)/1000, 0, 0.5 + math.random(-10,10)/1000, 0)
                    end
                end
            end
        end
    end
end)

WorldGroup:AddDivider()
WorldGroup:AddLabel("Прочее:")
WorldGroup:AddButton({ Text = "Поджечь дрова (нужна свеча)", Func = function()
    if lp.Character then
        local item = lp.Character:FindFirstChild("PickupableItem")
        if item and item:GetAttribute("OriginalName") == "Candle" then fsrv("WoodBurnt")
        else nfy("Нужна свеча в руке!") end
    end
end})
WorldGroup:AddButton({ Text = "Сбежать из палатки", Func = function() fsrv("TentEscaped") end})
WorldGroup:AddButton({ Text = "Tripwire", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "DazeTripWire" and c:IsA("BasePart") then fsrv("TriggeredTripwire", c); break end
    end
end})
WorldGroup:AddButton({ Text = "Lurking Shadow", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "LurkingShadow" and c:IsA("BasePart") then fcl("LurkingTouched", c); break end
    end
end})

WorldGroup:AddDivider()
WorldGroup:AddLabel("Выходы из миров:")
WorldGroup:AddButton({ Text = "RightFogBarrier", Func = function() fsrv("GoToInfiZone") end})
WorldGroup:AddButton({ Text = "FinalExit", Func = function() fsrv("FinalExited") end})
WorldGroup:AddButton({ Text = "FinalEscapeBarrier", Func = function() fsrv("ExitTPF") end})

local CheatGroup = Tabs.World:AddRightGroupbox("Читы")
CheatGroup:AddToggle("NoDeath", { Text = "God mode", Default = false })
task.spawn(function()
    while task.wait(0.3) do
        if Toggles.NoDeath and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            local hum = lp.Character.Humanoid
            if hum.Health <= 0 then
                hum.Health = hum.MaxHealth; hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end)
CheatGroup:AddToggle("NoBlinkCD", { Text = "No Blink CD", Default = false })
task.spawn(function()
    while task.wait(1) do if Toggles.NoBlinkCD then ws:SetAttribute("BlinkingBordering", nil) end end
end)
CheatGroup:AddToggle("NoWarpCD", { Text = "No Warp CD", Default = false })
task.spawn(function()
    while task.wait(0.5) do if Toggles.NoWarpCD then ws:SetAttribute("WarpTeleportCooldown", nil) end end
end)

CheatGroup:AddDivider()
CheatGroup:AddButton({ Text = "Hopekiller (Daze)", Func = function() fsrv("CaughtByDaze") end})
CheatGroup:AddButton({ Text = "Rubberband push", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "RubberbandBorder" and c:IsA("BasePart") then
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart:ApplyImpulse(c.CFrame.LookVector * lp.Character.HumanoidRootPart.AssemblyMass * 30)
            end; break
        end
    end
end})
CheatGroup:AddButton({ Text = "Убрать стены Chapter 2", Func = function()
    for _, c in pairs(ws:GetChildren()) do
        if c.Name == "WallRemoveOnCompletion" and c:IsA("BasePart") then
            c.Transparency = 1; c.CanCollide = false
        end
    end; nfy("Стены убраны")
end})
CheatGroup:AddButton({ Text = "Бросить предмет", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "DiscardPickupables" and c:IsA("BasePart") then
            local dp = c:GetAttribute("DropPos")
            if dp then fsrv("DropPickupable", dp) end; break
        end
    end
end})

-- ===================== EFFECTS =====================
local EffectGroup = Tabs.Effects:AddLeftGroupbox("Визуальные эффекты")
EffectGroup:AddButton({ Text = "Warp Effect", Func = function()
    local we = ls:FindFirstChild("WarpEffect")
    if we then local c = we:Clone(); c.Parent = ls; c.Enabled = true
        ts:Create(c, TweenInfo.new(1), {Brightness=0,Saturation=0,TintColor=Color3.fromRGB(255,255,255)}):Play()
        game:GetService("Debris"):AddItem(c, 1)
    end
end})
EffectGroup:AddButton({ Text = "Teleport Blur", Func = function()
    local tb = ls:FindFirstChild("TeleportBlur")
    if tb then tb.Size = 54; ts:Create(tb, TweenInfo.new(2), {Size = 0}):Play() end
end})
EffectGroup:AddButton({ Text = "Fall Bright", Func = function()
    local fb = ls:FindFirstChild("FallBright")
    if fb then fb.Brightness = 1; ts:Create(fb, TweenInfo.new(1), {Brightness = 0}):Play() end
end})
EffectGroup:AddDivider()

EffectGroup:AddLabel("Blink:")
EffectGroup:AddButton({ Text = "Воспроизвести Blink", Func = function()
    if not ScreenFX then return end
    local top = ScreenFX:FindFirstChild("BlinkFrameTop")
    local bot = ScreenFX:FindFirstChild("BlinkFrameBottom")
    local sfx = ScreenFX:FindFirstChild("BlinkSFX")
    if top and bot then
        local tc = top:Clone(); local bc = bot:Clone()
        tc.Parent = ScreenFX; bc.Parent = ScreenFX
        tc.Visible = true; bc.Visible = true
        ts:Create(tc, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, true, 0), {Position = UDim2.new(0.5,0,0,0)}):Play()
        ts:Create(bc, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, true, 0), {Position = UDim2.new(0.5,0,1,0)}):Play()
        if sfx then sfx:Play() end
        game:GetService("Debris"):AddItem(tc, 1.1); game:GetService("Debris"):AddItem(bc, 1.1)
    end
end})

EffectGroup:AddDivider()
EffectGroup:AddLabel("Exposure:")
EffectGroup:AddButton({ Text = "Exposure 0.75 -> 0", Func = function()
    ls.ExposureCompensation = 0.75
    ts:Create(ls, TweenInfo.new(1, Enum.EasingStyle.Cubic), {ExposureCompensation = 0}):Play()
end})

EffectGroup:AddDivider()
EffectGroup:AddLabel("Сообщения смерти:")
local deathMsgMap = {
    Lobby = {"How'd you even do that?"},
    Reality = {"Not yet."},
    ["Cloud Theater"] = {"Can you even die in a dream?","There's nothing below the clouds.","Dying does not progress.","You can't die from tranquility."},
    ["Dream Elementary"] = {"What's outside?","Make it through your school day."},
    ["Grassy Beach"] = {"Imagine far.","It's so peaceful."},
    ["The Twist"] = {"That didn't make you any closer to paradise."},
    Homescape = {"Do you think you become apart of the house if you die?","You lie down forever.","The carpet is really, really soft."},
    ["The Past Future"] = {"This city is supposed to be spotless.","I can hear the buildings and the trees at the same time."},
    ["Surreal Woodlands"] = {"Do you feel comfortable?","Everything can watch you.","The forest is way too quiet.","The roots absorb."},
    ["The In-Between"] = {"It gets colder and colder.","The lights feel like sunlight but the water feels so cold."},
}
local dreamKeys = {}
for k, _ in pairs(deathMsgMap) do table.insert(dreamKeys, k) end
EffectGroup:AddDropdown("DeathMsgSelect", { Values = dreamKeys, Default = 1, Text = "Дрим" })
EffectGroup:AddButton({ Text = "Показать сообщение", Func = function()
    local msgs = deathMsgMap[Options.DeathMsgSelect.Value]
    if msgs and #msgs > 0 then say(msgs[math.random(1, #msgs)]) end
end})

local SoundGroup = Tabs.Effects:AddRightGroupbox("Звуки")
SoundGroup:AddButton({ Text = "Warp Sound", Func = function()
    local s = rmt("WarpSound"); if s then s:Play() end
end})
SoundGroup:AddButton({ Text = "Land On Ground", Func = function()
    local s = rs:FindFirstChild("LandOnGroundSFX"); if s then s:Play() end
end})
SoundGroup:AddButton({ Text = "Land In Water", Func = function()
    local s = rs:FindFirstChild("LandInWaterSFX"); if s then s:Play() end
end})
SoundGroup:AddDivider()
SoundGroup:AddLabel("Звуки голосования:")
local function findSnd(name)
    for _, c in pairs(SpeechGui:GetDescendants()) do
        if c.Name == name and c:IsA("Sound") then return c end
    end
end
SoundGroup:AddButton({ Text = "Vote Start", Func = function()
    local s = findSnd("VoteStart"); if s then s:Play() end
end})
SoundGroup:AddButton({ Text = "Vote Pick", Func = function()
    local s = findSnd("VoteSoundPick"); if s then s:Play() end
end})
SoundGroup:AddButton({ Text = "Vote Hover", Func = function()
    local s = findSnd("VoteHover"); if s then s:Play() end
end})
SoundGroup:AddDivider()
SoundGroup:AddLabel("Звуки диалогов:")
SoundGroup:AddButton({ Text = "Type Sound", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("TypeSound"); if s then s:Play() end end
end})
SoundGroup:AddButton({ Text = "SubD Type", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("SubDTypeSound"); if s then s:Play() end end
end})
SoundGroup:AddButton({ Text = "Objective", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("ObjectiveSound"); if s then s:Play() end end
end})
SoundGroup:AddButton({ Text = "Info SFX", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("InfoSFX"); if s then s:Play() end end
end})

local DiaGroup = Tabs.Effects:AddRightGroupbox("Отладка диалогов")
DiaGroup:AddLabel("DialogueState: " .. tostring(ws:GetAttribute("DialogueState")))
DiaGroup:AddLabel("Voters: " .. tostring(ws:GetAttribute("CurrentDialogueVoters")))
DiaGroup:AddDivider()
DiaGroup:AddLabel("DialogueMoveOn:")
DiaGroup:AddButton({ Text = "MoveOn (Left)", Func = function() fsrv("DialogueMoveOn", "Left") end})
DiaGroup:AddButton({ Text = "MoveOn (Right)", Func = function() fsrv("DialogueMoveOn", "Right") end})
DiaGroup:AddButton({ Text = "MoveOn (default)", Func = function() fsrv("DialogueMoveOn") end})
DiaGroup:AddDivider()
DiaGroup:AddLabel("DeathEncounter: " .. tostring(ws:GetAttribute("DeathEncounter") or "none"))
DiaGroup:AddButton({ Text = "Сбросить", Func = function() ws:SetAttribute("DeathEncounter", nil) end})

-- ===================== UI =====================
local MenuGroup = Tabs.UI:AddLeftGroupbox("Меню")
MenuGroup:AddButton({ Text = "Выгрузить", Func = function() Library:Unload() end })
MenuGroup:AddLabel("Клавиша меню"):AddKeyPicker("MenuKeybind", {
    Default = "End", NoUI = true, Text = "Клавиша меню"
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("NullFireHub")
SaveManager:SetFolder("NullFireHub/ABrokenDream")
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)

updateTrackLabel()

Library:SetWatermark(("NullFire Hub | ABD | %s fps | %s ms"):format(60, 0))
Library:OnUnload(function() Library.Unloaded = true end)
SaveManager:LoadAutoloadConfig()