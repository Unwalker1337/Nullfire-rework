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

    UI = Window:AddTab("Настройки"),
}

local lp = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local ws = workspace
local ts = game:GetService("TweenService")
local ls = game:GetService("Lighting")

-- ожидание с таймаутом 15 секунд
do
    local t = 0
    repeat task.wait(0.5); t = t + 0.5 until ws:GetAttribute("ClientLoadedIn") or t > 15
    if not ws:GetAttribute("ClientLoadedIn") then
        Library:Notify("Ошибка: ClientLoadedIn не найден. UI может работать нестабильно.", 5)
    end
end
do
    local t = 0
    repeat task.wait(0.5); t = t + 0.5 until lp:GetAttribute("SetUpPlayerFully") or t > 15
    if not lp:GetAttribute("SetUpPlayerFully") then
        Library:Notify("Ошибка: SetUpPlayerFully не найден. UI может работать нестабильно.", 5)
    end
end

local LobbyMusic = rs:WaitForChild("LobbyMusic")
local OSTScreen = lp:WaitForChild("PlayerGui"):WaitForChild("OSTTVScreen")

local function rmt(n) return rs:FindFirstChild(n) end
local function fsrv(n, ...) local r = rmt(n); if r then r:FireServer(...) end end
local function fcl(n, ...) local r = rmt(n); if r then r:Fire(...) end end
local function nfy(t, tm) Library:Notify(t, tm or 3) end
local function tp(cf)
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cf
    end
end
local function tpf(cf, r) tp(cf); if r then fsrv(r) end end

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
local PlayerSettings = Tabs.Player:AddLeftGroupbox("Настройки")
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

-- ===================== WORLD =====================
local CheatGroup = Tabs.World:AddLeftGroupbox("Читы")
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