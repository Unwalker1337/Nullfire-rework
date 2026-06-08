local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "NullFire Hub -- A Broken Dream",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Music = Window:AddTab("Music"),
    Player = Window:AddTab("Player"),
    Teleports = Window:AddTab("Teleports"),
    NPCs = Window:AddTab("NPCs"),
    UI = Window:AddTab("UI Settings"),
}

local lp = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local ws = workspace

repeat task.wait() until ws:GetAttribute("ClientLoadedIn")
repeat task.wait() until lp:GetAttribute("SetUpPlayerFully")

local LobbyMusic = rs:WaitForChild("LobbyMusic")
local OSTScreen = lp:WaitForChild("PlayerGui"):WaitForChild("OSTTVScreen")

local function fire(name, ...)
    local r = rs:FindFirstChild(name)
    if r then r:FireServer(...) end
end

local function fireClient(name, ...)
    local r = rs:FindFirstChild(name)
    if r then r:Fire(...) end
end

local function notify(text)
    Library:Notify(text)
end

-- MUSIC TAB
local MusicGroup = Tabs.Music:AddLeftGroupbox("Music Player")

local function getTracks()
    local tracks = {}
    for _, child in ipairs(LobbyMusic:GetChildren()) do
        if child:IsA("Sound") then table.insert(tracks, child) end
    end
    table.sort(tracks, function(a, b) return tonumber(a.Name) < tonumber(b.Name) end)
    return tracks
end

local function getTrackNames()
    local names = {}
    for _, t in ipairs(getTracks()) do
        table.insert(names, t:GetAttribute("RealName") or "Track " .. t.Name)
    end
    return names
end

local TrackLabel

local function updateTrackLabel()
    local tracks = getTracks()
    local currentIdx = nil
    for i, t in ipairs(tracks) do
        if t.SoundId == LobbyMusic.SoundId then
            currentIdx = i; break
        end
    end
    if currentIdx then
        local name = tracks[currentIdx]:GetAttribute("RealName") or "Track " .. tracks[currentIdx].Name
        TrackLabel:SetText("Now Playing: " .. name .. " (" .. currentIdx .. "/" .. #tracks .. ")")
    else
        TrackLabel:SetText("Not playing")
    end
end

local function switchTrack(delta)
    local tracks = getTracks()
    local currentIdx = nil
    for i, t in ipairs(tracks) do
        if t.SoundId == LobbyMusic.SoundId then currentIdx = i; break end
    end
    if not currentIdx then currentIdx = 0 end
    local newIdx = currentIdx + delta
    if newIdx < 1 then newIdx = #tracks elseif newIdx > #tracks then newIdx = 1 end
    if tracks[newIdx] then
        LobbyMusic:Stop()
        LobbyMusic.Volume = tracks[newIdx].Volume
        LobbyMusic.SoundId = tracks[newIdx].SoundId
        if tracks[newIdx].PlaybackRegionsEnabled then
            LobbyMusic.PlaybackRegionsEnabled = true
            LobbyMusic.LoopRegion = tracks[newIdx].LoopRegion
            LobbyMusic.PlaybackRegion = tracks[newIdx].PlaybackRegion
        else
            LobbyMusic.PlaybackRegionsEnabled = false
        end
        LobbyMusic:Play()
        notify("Track: " .. (tracks[newIdx]:GetAttribute("RealName") or "Track " .. tracks[newIdx].Name))
        updateTrackLabel()
    end
end

TrackLabel = MusicGroup:AddLabel("Scanning tracks...")

MusicGroup:AddButton({ Text = "Previous Track", Func = function() switchTrack(-1) end })
MusicGroup:AddButton({ Text = "Next Track", Func = function() switchTrack(1) end })
MusicGroup:AddButton({ Text = "Rescan Tracks", Func = updateTrackLabel })

MusicGroup:AddDivider()

MusicGroup:AddSlider("MusicVolume", {
    Text = "Volume Override", Default = 100, Min = 0, Max = 200, Rounding = 0, Suffix = "%",
    Callback = function(v) LobbyMusic.Volume = v / 100 end
})

MusicGroup:AddToggle("MusicAutoNext", {
    Text = "Auto-skip when track ends", Default = false,
})

task.spawn(function()
    while task.wait(0.5) do
        if Toggles.MusicAutoNext and not LobbyMusic.Playing then
            switchTrack(1)
        end
    end
end)

local TrackListGroup = Tabs.Music:AddRightGroupbox("Track List")

local TrackDropdown
TrackDropdown = TrackListGroup:AddDropdown("TrackSelect", {
    Values = getTrackNames(), Default = 1, Text = "Jump to track",
    Callback = function(val)
        local tracks = getTracks()
        for i, t in ipairs(tracks) do
            local name = t:GetAttribute("RealName") or "Track " .. t.Name
            if name == val then
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

local function refreshTrackDropdown()
    TaskDropdown:SetValues(getTrackNames())
end

TrackListGroup:AddLabel("Unused tracks are hidden in OST")

-- PLAYER TAB
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player Info")

PlayerGroup:AddLabel("Chapter 2: " .. (lp:GetAttribute("CompletedCH2Binary") or "0"))

PlayerGroup:AddToggle("UnlockMusic", {
    Text = "Unlock OST (show if locked)", Default = true,
    Callback = function(v)
        OSTScreen:WaitForChild("Frame").Visible = v
        OSTScreen:WaitForChild("CantAccessText").Visible = not v
    end
})

PlayerGroup:AddDivider()

local function getDreamEntries()
    local entries = {}
    local stored = lp:FindFirstChild("StoredThings")
    if stored then
        for _, child in pairs(stored:GetChildren()) do
            if child.Name == "DreamEntry" and child:IsA("StringValue") then
                table.insert(entries, child.Value)
            end
        end
    end
    return entries
end

PlayerGroup:AddLabel("Dream Entries: " .. table.concat(getDreamEntries(), ", "))

PlayerGroup:AddDivider()

PlayerGroup:AddButton({ Text = "Force Nod (-5)", Func = function()
    local fn = rs:FindFirstChild("ForceNod")
    if fn then fn:Fire(-5) end
end})

PlayerGroup:AddToggle("NoCutscene", { Text = "Block cutscenes", Default = false })

task.spawn(function()
    while task.wait(1) do
        if Toggles.NoCutscene and ws:GetAttribute("Cutscene") then
            ws:SetAttribute("Cutscene", nil)
        end
    end
end)

-- TELEPORTS TAB
local TeleportGroup = Tabs.Teleports:AddLeftGroupbox("Lobby Teleports")

TeleportGroup:AddButton({ Text = "Main Hall Spawn", Func = function()
    local spawn = ws:FindFirstChild("SpawnLocations")
    if spawn then
        local loc = spawn:FindFirstChild("MainHallSpawnLocation")
        if loc and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = loc.CFrame
            fire("selfTeleported")
        end
    end
end})

TeleportGroup:AddButton({ Text = "Exit to Main Hall", Func = function()
    local cf = ws:GetAttribute("ExitMainHallCFrame")
    if cf and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cf
        fire("selfTeleported")
    end
end})

TeleportGroup:AddButton({ Text = "Secret Main Hall", Func = function()
    local cf = ws:GetAttribute("SecretMainHallCFrame")
    if cf and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cf
        fire("selfTeleported")
    end
end})

TeleportGroup:AddButton({ Text = "Secret Exit", Func = function()
    local cf = ws:GetAttribute("SecretExitCFrame")
    if cf and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cf
        fire("selfTeleported")
    end
end})

TeleportGroup:AddDivider()
TeleportGroup:AddLabel("Lobby Doors", false)

local function refreshDoors()
    for _, child in pairs(ws:GetDescendants()) do
        if child.Name == "LobbyTeleportDoor" and child:IsA("BasePart") then
            local placeId = child:GetAttribute("TeleportPlaceID") or "?"
            local doorName = child.Parent and child.Parent.Name or "Door"
            TeleportGroup:AddButton({ Text = doorName .. " [" .. placeId .. "]", Func = function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    lp.Character.HumanoidRootPart.CFrame = child.CFrame * CFrame.new(0, 0, -5)
                end
                fire("LobbyDoorTP", placeId)
            end})
        end
    end
end

TeleportGroup:AddButton({ Text = "Scan Doors", Func = refreshDoors })
task.delay(1, refreshDoors)

-- NPCS TAB
local NPCGroup = Tabs.NPCs:AddLeftGroupbox("NPC Interactions")

NPCGroup:AddDropdown("SelectNPC", {
    Values = { "Minecraftpeter", "SnoogleBrosPlayz" }, Default = 1, Text = "Select NPC",
})

NPCGroup:AddButton({ Text = "Trigger Prompt", Func = function()
    local name = Options.SelectNPC.Value
    local npc = ws:FindFirstChild("RigNPCS")
    if npc then
        local char = npc:FindFirstChild(name)
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local prompt = root:FindFirstChild("ProximityPrompt")
                if prompt then
                    fire("ProximityPromptTriggered", prompt)
                end
            end
        end
    end
end})

NPCGroup:AddButton({ Text = "Teleport to NPC", Func = function()
    local name = Options.SelectNPC.Value
    local npc = ws:FindFirstChild("RigNPCS")
    if npc then
        local char = npc:FindFirstChild(name)
        if char and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                lp.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -3)
            end
        end
    end
end})

NPCGroup:AddDivider()
NPCGroup:AddLabel("Make Snoogle say:")
NPCGroup:AddInput("CustomNPCText", {
    Default = "", Text = "Text", Placeholder = "Enter text",
    Callback = function(val)
        if val ~= "" then fireClient("MakeSnoogleSaySomething", val) end
    end
})

-- Dream Journal Paintings
local PaintingsGroup = Tabs.NPCs:AddRightGroupbox("Dream Journal Paintings")

local function refreshPaintings()
    for _, child in pairs(PaintingsGroup:GetChildren()) do
        if child:IsA("TextButton") then pcall(child.Destroy, child) end
    end
    local paintings = ws:FindFirstChild("DreamJournalPaintings")
    if paintings then
        local entries = getDreamEntries()
        PaintingsGroup:AddLabel("Paintings:", false)
        for _, child in pairs(paintings:GetChildren()) do
            local dreamName = child.Name:gsub("Painting", "")
            local collected = table.find(entries, dreamName)
            PaintingsGroup:AddButton({
                Text = (collected and "[X] " or "[ ] ") .. dreamName,
                Func = function()
                    notify("Dream: " .. dreamName .. (collected and " (collected)" or " (not collected)"))
                end
            })
        end
    end
end

PaintingsGroup:AddButton({ Text = "Refresh", Func = refreshPaintings })
task.delay(1, refreshPaintings)

-- UI SETTINGS
local MenuGroup = Tabs.UI:AddLeftGroupbox("Menu")

MenuGroup:AddButton({ Text = "Unload", Func = function() Library:Unload() end })
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "End", NoUI = true, Text = "Menu keybind"
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

Library:SetWatermark(("NullFire Hub | %%s fps | %%s ms"):format(60, 0))

Library:OnUnload(function() Library.Unloaded = true end)
SaveManager:LoadAutoloadConfig()
