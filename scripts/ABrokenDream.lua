--[[
    NullFire Hub - A Broken Dream
    https://github.com/Unwalker1337/Nullfire-rework
--]]
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = 'NullFire Hub - A Broken Dream',
    Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2
})

local Tabs = {
    Music = Window:AddTab('Музыка'),
    Player = Window:AddTab('Игрок'),
    Teleports = Window:AddTab('Телепорты'),
    NPC = Window:AddTab('NPC'),
    World = Window:AddTab('Мир'),
    Effects = Window:AddTab('Эффекты'),
    UI = Window:AddTab('Настройки UI'),
}

local lp = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local ws = workspace
local ts = game:GetService("TweenService")
local ls = game:GetService("Lighting")
local uis = game:GetService("UserInputService")

repeat task.wait() until ws:GetAttribute("ClientLoadedIn")
repeat task.wait() until lp:GetAttribute("SetUpPlayerFully")

local LobbyMusic = rs:WaitForChild("LobbyMusic")
local OSTScreen = lp:WaitForChild("PlayerGui"):WaitForChild("OSTTVScreen")
local SpeechGui = lp:WaitForChild("PlayerGui"):WaitForChild("SpeechGui")
local DonationGui = lp:WaitForChild("PlayerGui"):WaitForChild("DonationGui")
local ScreenFX = lp:WaitForChild("PlayerGui"):FindFirstChild("ScreenEffectGui")

local function remote(name) return rs:FindFirstChild(name) end
local function fireSrv(name, ...)
    local r = remote(name)
    if r then r:FireServer(...) end
end
local function fireCl(name, ...)
    local r = remote(name)
    if r then r:Fire(...) end
end
local function sayThing(text, opts)
    opts = opts or {"InfoText"}
    fireCl("SayThing", text, opts)
end
local function notify(text, time)
    Library:Notify(text, time or 3)
end
local function tpTo(cf)
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cf
    end
end
local function tpWithFire(cf, rn)
    tpTo(cf)
    if rn then fireSrv(rn) end
end

-- ===== MUZYKA =====
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
    for _, t in ipairs(getTracks()) do
        table.insert(n, t:GetAttribute("RealName") or "Трек " .. t.Name)
    end
    return n
endlocal TrackLabel
local function updateTrackLabel()
    local tracks = getTracks()
    local idx
    for i, t in ipairs(tracks) do
        if t.SoundId == LobbyMusic.SoundId then idx = i; break end
    end
    if idx then
        local name = tracks[idx]:GetAttribute("RealName") or "Track " .. tracks[idx].Name
        TrackLabel:SetText("Now: " .. name .. " (" .. idx .. "/" .. #tracks .. ")")
    else
        TrackLabel:SetText("Stopped")
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
        updateTrackLabel()
    end
end

TrackLabel = MusicGroup:AddLabel("Scanning...")
MusicGroup:AddButton({ Text = "Prev", Func = function() switchTrack(-1) end })
MusicGroup:AddButton({ Text = "Next", Func = function() switchTrack(1) end })
MusicGroup:AddButton({ Text = "Refresh", Func = updateTrackLabel })
MusicGroup:AddDivider()
MusicGroup:AddSlider("MusicVolume", {
    Text = "Volume", Default = 100, Min = 0, Max = 200, Rounding = 0, Suffix = "%",
    Callback = function(v) LobbyMusic.Volume = v / 100 end
})
MusicGroup:AddToggle("MusicAutoNext", {
    Text = "Auto next", Default = false,
})
task.spawn(function()
    while task.wait(0.5) do
        if Toggles.MusicAutoNext and not LobbyMusic.Playing then
            switchTrack(1)
        end
    end
end)

local PlaylistGroup = Tabs.Music:AddRightGroupbox("Playlist")
PlaylistGroup:AddDropdown("TrackSelect", {
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
PlaylistGroup:AddDivider()
local listLabel = PlaylistGroup:AddLabel("Loading...", true)
local function refreshTrackInfo()
    local tracks = getTracks()
    local lines = {}
    for i, t in ipairs(tracks) do
        local name = t:GetAttribute("RealName") or "Track " .. t.Name
        local unused = t:GetAttribute("Unused") and " [hidden]" or ""
        table.insert(lines, i .. ". " .. name .. unused)
    end
    if #lines == 0 then table.insert(lines, "No tracks") end
    listLabel:SetText(table.concat(lines, "\n"))
end
PlaylistGroup:AddButton({ Text = "Refresh", Func = refreshTrackInfo })
task.delay(0.5, refreshTrackInfo)
-- ===== PLAYER =====
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player Info")
PlayerGroup:AddLabel("Chapter 2: " .. (lp:GetAttribute("CompletedCH2Binary") or "0"))
PlayerGroup:AddLabel("Device: " .. (lp:GetAttribute("device") or "PC"))

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

PlayerGroup:AddDivider()
PlayerGroup:AddLabel("Dream Entries:", false)
local dreamEntryLabel = PlayerGroup:AddLabel("Loading...", true)
local function updateDreamEntries()
    local e = getDreamEntries()
    dreamEntryLabel:SetText(#e > 0 and table.concat(e, ", ") or "None")
end
task.delay(0.5, updateDreamEntries)

PlayerGroup:AddDivider()
PlayerGroup:AddLabel("Attributes:", false)
local attrsLabel = PlayerGroup:AddLabel("", true)
local function refreshAttrs()
    local a = {
        CompletedCH2Binary = lp:GetAttribute("CompletedCH2Binary"),
        device = lp:GetAttribute("device"),
        HasAeroportTicket = lp:GetAttribute("HasAeroportTicket"),
        SetUpPlayerFully = lp:GetAttribute("SetUpPlayerFully"),
    }
    local lines = {}
    for k, v in pairs(a) do
        table.insert(lines, k .. " = " .. tostring(v))
    end
    attrsLabel:SetText(table.concat(lines, "\n"))
end
PlayerGroup:AddButton({ Text = "Refresh Attributes", Func = refreshAttrs })

local PlayerSettings = Tabs.Player:AddRightGroupbox("Settings")
PlayerSettings:AddToggle("UnlockMusic", {
    Text = "Unlock OST", Default = true,
    Callback = function(v)
        local f = OSTScreen:FindFirstChild("Frame")
        local c = OSTScreen:FindFirstChild("CantAccessText")
        if f then f.Visible = v end
        if c then c.Visible = not v end
    end
})
PlayerSettings:AddToggle("NoCutscene", { Text = "Block cutscenes", Default = false })
task.spawn(function()
    while task.wait(1) do
        if Toggles.NoCutscene and ws:GetAttribute("Cutscene") then
            ws:SetAttribute("Cutscene", nil)
        end
    end
end)
PlayerSettings:AddToggle("UnanchorOnCutscene", {
    Text = "Unanchor in cutscene", Default = false
})
task.spawn(function()
    while task.wait(0.5) do
        if Toggles.UnanchorOnCutscene and ws:GetAttribute("Cutscene") then
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.Anchored = false
            end
        end
    end
end)

PlayerSettings:AddDivider()
PlayerSettings:AddButton({ Text = "Force Nod (-5)", Func = function()
    local fn = remote("ForceNod")
    if fn then fn:Fire(-5) end
end})
PlayerSettings:AddButton({ Text = "Force FOV (-15)", Func = function()
    local fov = remote("ForceFOVBindable")
    if fov then fov:Fire(-15, 0.5) end
end})
PlayerSettings:AddButton({ Text = "Screenshake", Func = function()
    local sh = remote("ScreenshakeBindable")
    if sh then sh:Fire(3) end
end})

PlayerSettings:AddDivider()
PlayerSettings:AddLabel("Donations:", false)
local donatProducts = {
    {"Donation 1 (3344306026)", 3344306026},
    {"Donation 2 (3344306942)", 3344306942},
    {"Donation 3 (3344307148)", 3344307148},
    {"Donation 4 (3344307629)", 3344307629},
}
for _, item in ipairs(donatProducts) do
    PlayerSettings:AddButton({ Text = "Buy " .. item[1], Func = function()
        game:GetService("MarketplaceService"):PromptProductPurchase(lp, item[2])
    end})
end
-- ===== TELEPORTS =====
local TpLobby = Tabs.Teleports:AddLeftGroupbox("Lobby")
TpLobby:AddButton({ Text = "Main Hall Spawn", Func = function()
    local s = ws:FindFirstChild("SpawnLocations")
    if s then
        local loc = s:FindFirstChild("MainHallSpawnLocation")
        if loc then tpWithFire(loc.CFrame, "selfTeleported") end
    end
end})
TpLobby:AddButton({ Text = "Exit Main Hall", Func = function()
    local cf = ws:GetAttribute("ExitMainHallCFrame")
    if cf then tpWithFire(cf, "selfTeleported") end
end})
TpLobby:AddButton({ Text = "Exit Outside Minigame", Func = function()
    local cf = ws:GetAttribute("ExitOutsideMinigameCFrame")
    if cf then tpWithFire(cf, "selfTeleported") end
end})

TpLobby:AddDivider()
TpLobby:AddLabel("Secrets:")
TpLobby:AddButton({ Text = "Secret Main Hall", Func = function()
    local cf = ws:GetAttribute("SecretMainHallCFrame")
    if cf then tpWithFire(cf, "selfTeleported") end
end})
TpLobby:AddButton({ Text = "Secret Exit", Func = function()
    local cf = ws:GetAttribute("SecretExitCFrame")
    if cf then tpWithFire(cf, "selfTeleported") end
end})

TpLobby:AddDivider()
TpLobby:AddLabel("Cloud Theater Fall:")
TpLobby:AddButton({ Text = "Fall into clouds", Func = function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local fallSpawns = ws:FindFirstChild("FallCatcherSpawns")
        if fallSpawns then
            local sp = fallSpawns:FindFirstChild("CatcherSpawn")
            if sp then
                ws:SetAttribute("Cutscene", true)
                lp.Character.HumanoidRootPart.Anchored = true
                lp.Character.HumanoidRootPart.CFrame = sp.CFrame
                ts:Create(lp.Character.HumanoidRootPart, TweenInfo.new(4, Enum.EasingStyle.Sine), {
                    CFrame = sp.CFrame - Vector3.new(0, 136, 0)
                }):Play()
                local fb = ls:FindFirstChild("FallBright")
                if fb then
                    fb.Brightness = 1
                    ts:Create(fb, TweenInfo.new(1), {Brightness = 0}):Play()
                end
                ws:SetAttribute("WindFalling", true)
                task.delay(4, function()
                    ws:SetAttribute("WindFalling", nil)
                    ws:SetAttribute("Cutscene", nil)
                    lp.Character.HumanoidRootPart.Anchored = false
                    local fn = remote("ForceNod")
                    if fn then fn:Fire(-5) end
                    fireSrv("FellIntoCloud")
                    local sh = remote("ScreenshakeBindable")
                    if sh then sh:Fire(3) end
                end)
            end
        end
    end
end})

local WarpGroup = Tabs.Teleports:AddRightGroupbox("Zones & Warps")

local function scanWarpParts()
    WarpGroup:AddLabel("Warp Teleports:", false)
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "WarpTeleportPart" and c:IsA("BasePart") and c:GetAttribute("WarpTo") then
            local target = c.Parent and c.Parent.Name or "Warp"
            WarpGroup:AddButton({ Text = "Warp: " .. target, Func = function()
                local warp = c:GetAttribute("WarpTo")
                if warp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    lp.Character.HumanoidRootPart.CFrame = warp
                    local w = remote("WarpSound")
                    if w then w:Play() end
                    local fov = remote("ForceFOVBindable")
                    if fov then fov:Fire(-15, 0.5) end
                end
            end})
        end
    end
end
WarpGroup:AddButton({ Text = "Scan Warps", Func = scanWarpParts })
task.delay(1, scanWarpParts)

WarpGroup:AddDivider()
WarpGroup:AddLabel("Forcefield Borders:", false)
local function scanFF()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name:match("ForcefieldBorder") and c:IsA("BasePart") and c:GetAttribute("SideRelationship") then
            WarpGroup:AddButton({ Text = "FF: " .. c.Name, Func = function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    lp.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + c:GetAttribute("SideRelationship") * 370
                    fireSrv("HeyITeleported")
                end
            end})
        end
    end
end
WarpGroup:AddButton({ Text = "Scan Forcefields", Func = scanFF })
task.delay(1.5, scanFF)

WarpGroup:AddDivider()
WarpGroup:AddLabel("Blink Borders:", false)
local function scanBlink()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "BlinkBorder" and c:IsA("BasePart") then
            WarpGroup:AddButton({ Text = "Blink: " .. (c.Parent and c.Parent.Name or "?"), Func = function()
                if ws:GetAttribute("Cutscene") then return end
                local goBack = c:GetAttribute("GoBackPlace")
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    lp.Character.HumanoidRootPart.CFrame = goBack or (lp.Character:GetAttribute("WhereSpawned") or lp.Character.HumanoidRootPart.CFrame)
                end
            end})
        end
    end
end
WarpGroup:AddButton({ Text = "Scan Blink", Func = scanBlink })
task.delay(2, scanBlink)

local DoorGroup = Tabs.Teleports:AddLeftGroupbox("Sub-place Doors")
local function scanDoors()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "LobbyTeleportDoor" and c:IsA("BasePart") then
            local pid = c:GetAttribute("TeleportPlaceID") or "?"
            local dname = (c.Parent and c.Parent.Name) or "Door"
            DoorGroup:AddButton({ Text = dname .. " [Place: " .. pid .. "]", Func = function()
                tpTo(c.CFrame * CFrame.new(0, 0, -5))
                if pid ~= "?" then fireSrv("LobbyDoorTP", pid) end
            end})
        end
    end
end
DoorGroup:AddButton({ Text = "Scan Doors", Func = scanDoors })
task.delay(1, scanDoors)
-- ===== NPC =====
local NPCGroup = Tabs.NPC:AddLeftGroupbox("NPC Dialogues")
local npcNames = {"Minecraftpeter", "SnoogleBrosPlayz"}
NPCGroup:AddDropdown("SelectNPC", { Values = npcNames, Default = 1, Text = "Select NPC" })
NPCGroup:AddButton({ Text = "Trigger Prompt", Func = function()
    local name = Options.SelectNPC.Value
    local npcs = ws:FindFirstChild("RigNPCS")
    if npcs then
        local char = npcs:FindFirstChild(name)
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local prompt = root:FindFirstChild("ProximityPrompt")
                if prompt then fireSrv("ProximityPromptTriggered", prompt) end
            end
        end
    end
end})
NPCGroup:AddButton({ Text = "Teleport to NPC", Func = function()
    local name = Options.SelectNPC.Value
    local npcs = ws:FindFirstChild("RigNPCS")
    if npcs then
        local char = npcs:FindFirstChild(name)
        if char and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then lp.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0,0,-3) end
        end
    end
end})

NPCGroup:AddDivider()
NPCGroup:AddLabel("SnoogleBrosPlayz custom text:")
NPCGroup:AddInput("CustomNPCText", {
    Default = "", Text = "Text", Placeholder = "Enter...",
    Callback = function(val)
        if val ~= "" then fireCl("MakeSnoogleSaySomething", val) end
    end
})
NPCGroup:AddLabel("Display bubble at Snoogle:")
NPCGroup:AddInput("BubbleText", {
    Default = "", Text = "Bubble", Placeholder = "Bubble text...",
    Callback = function(val)
        if val ~= "" then
            local tcs = game:GetService("TextChatService")
            local sn = ws:FindFirstChild("RigNPCS")
            if sn then
                local sno = sn:FindFirstChild("SnoogleBrosPlayz")
                if sno and sno:FindFirstChild("Head") then
                    tcs:DisplayBubble(sno.Head, val)
                end
            end
        end
    end
})

local AnimGroup = Tabs.NPC:AddRightGroupbox("NPC Animations")
AnimGroup:AddButton({ Text = "Reload NPC Animations", Func = function()
    local anims = rs:FindFirstChild("Anims")
    if anims then
        local rigs = anims:FindFirstChild("RigAnims")
        local npcs = ws:FindFirstChild("RigNPCS")
        if rigs and npcs then
            for _, npc in pairs(npcs:GetChildren()) do
                local anim = rigs:FindFirstChild(npc.Name)
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
            notify("Animations reloaded")
        end
    end
end})

local PaintGroup = Tabs.NPC:AddRightGroupbox("Dream Journal Paintings")
local function scanPaintings()
    for _, child in pairs(PaintGroup:GetChildren()) do
        if child:IsA("TextButton") then pcall(child.Destroy, child) end
    end
    local paintings = ws:FindFirstChild("DreamJournalPaintings")
    if paintings then
        local entries = getDreamEntries()
        PaintGroup:AddLabel("Paintings:", false)
        for _, child in pairs(paintings:GetChildren()) do
            local dreamName = child.Name:gsub("Painting", "")
            local collected = table.find(entries, dreamName)
            PaintGroup:AddButton({
                Text = (collected and "[X] " or "[ ] ") .. dreamName,
                Func = function()
                    notify("Dream: " .. dreamName .. (collected and " (collected)" or " (not collected)"))
                end
            })
        end
    end
end
PaintGroup:AddButton({ Text = "Refresh", Func = scanPaintings })
task.delay(1, scanPaintings)
-- ===== WORLD =====
local WorldGroup = Tabs.World:AddLeftGroupbox("World Objects")
local function scanMemories()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name:match("MemoryRecollector") and c:IsA("BasePart") then
            WorldGroup:AddButton({ Text = "Collect: " .. c.Name, Func = function()
                fireSrv("GotMemory", c)
            end})
        end
    end
end
WorldGroup:AddButton({ Text = "Scan Memories", Func = scanMemories })
task.delay(1, scanMemories)

WorldGroup:AddDivider()
WorldGroup:AddLabel("Piano Keys:")
WorldGroup:AddButton({ Text = "Play random note", Func = function()
    fireSrv("PianoKeyPressed", math.random(1, 88))
end})

WorldGroup:AddDivider()
WorldGroup:AddLabel("Pocket Doors:")
local function scanPocketDoors()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name:match("PocketDoorDetector") and c:IsA("BasePart") then
            WorldGroup:AddButton({ Text = "Door: " .. c.Name, Func = function()
                fireSrv("TouchedDoorDetector", c.Name)
            end})
        end
    end
end
WorldGroup:AddButton({ Text = "Scan Doors", Func = scanPocketDoors })
task.delay(1.5, scanPocketDoors)

WorldGroup:AddDivider()
WorldGroup:AddLabel("Moving Signs:")
WorldGroup:AddToggle("ShakeSigns", { Text = "Shake signs", Default = false })
task.spawn(function()
    while task.wait(0.1) do
        if Toggles.ShakeSigns then
            local ss = ws:FindFirstChild("MovingSignStuff")
            if ss then
                for _, child in pairs(ss:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("ImageLabel") then
                        child.Position = UDim2.new(0.5 + math.random(-10,10)/1000, 0, 0.5 + math.random(-10,10)/1000, 0)
                    end
                end
            end
        end
    end
end)

WorldGroup:AddDivider()
WorldGroup:AddLabel("Burnable Wood (need candle):")
WorldGroup:AddButton({ Text = "Burn wood", Func = function()
    if lp.Character then
        local item = lp.Character:FindFirstChild("PickupableItem")
        if item and item:GetAttribute("OriginalName") == "Candle" then
            fireSrv("WoodBurnt")
        else
            notify("Need candle in hand!")
        end
    end
end})

WorldGroup:AddDivider()
WorldGroup:AddLabel("Tent / Tripwire / Lurking:")
WorldGroup:AddButton({ Text = "Escape tent", Func = function() fireSrv("TentEscaped") end})
WorldGroup:AddButton({ Text = "Trigger Tripwire", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "DazeTripWire" and c:IsA("BasePart") then
            fireSrv("TriggeredTripwire", c); break
        end
    end
end})
WorldGroup:AddButton({ Text = "Trigger Lurking", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "LurkingShadow" and c:IsA("BasePart") then
            fireCl("LurkingTouched", c); break
        end
    end
end})

WorldGroup:AddDivider()
WorldGroup:AddLabel("World Exits:")
WorldGroup:AddButton({ Text = "RightFogBarrier (Woodlands)", Func = function() fireSrv("GoToInfiZone") end})
WorldGroup:AddButton({ Text = "FinalExit (Woodlands)", Func = function() fireSrv("FinalExited") end})
WorldGroup:AddButton({ Text = "FinalEscapeBarrier (TPF)", Func = function() fireSrv("ExitTPF") end})
WorldGroup:AddButton({ Text = "CliffsideSW Border", Func = function()
    ws:SetAttribute("TouchedCliffsideBorder", true)
    sayThing("It's too steep for me to walk over.")
end})

local CheatGroup = Tabs.World:AddRightGroupbox("Cheats")
CheatGroup:AddToggle("NoDeath", { Text = "God mode", Default = false })
task.spawn(function()
    while task.wait(0.3) do
        if Toggles.NoDeath and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            local hum = lp.Character.Humanoid
            if hum.Health <= 0 and hum:GetState() == Enum.HumanoidStateType.Dead then
                hum.Health = hum.MaxHealth
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end)

CheatGroup:AddToggle("NoBlinkCD", { Text = "No Blink cooldown", Default = false })
task.spawn(function()
    while task.wait(1) do
        if Toggles.NoBlinkCD then
            ws:SetAttribute("BlinkingBordering", nil)
        end
    end
end)

CheatGroup:AddToggle("NoWarpCD", { Text = "No Warp cooldown", Default = false })
task.spawn(function()
    while task.wait(0.5) do
        if Toggles.NoWarpCD then
            ws:SetAttribute("WarpTeleportCooldown", nil)
        end
    end
end)

CheatGroup:AddDivider()
CheatGroup:AddButton({ Text = "Trigger Hopekiller", Func = function()
    fireSrv("CaughtByDaze")
end})
CheatGroup:AddButton({ Text = "Rubberband push", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "RubberbandBorder" and c:IsA("BasePart") then
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = lp.Character.HumanoidRootPart
                hrp:ApplyImpulse(c.CFrame.LookVector * hrp.AssemblyMass * 30)
            end
            break
        end
    end
end})
CheatGroup:AddButton({ Text = "Remove WallRemoveOnCompletion", Func = function()
    for _, c in pairs(ws:GetChildren()) do
        if c.Name == "WallRemoveOnCompletion" and c:IsA("BasePart") then
            c.Transparency = 1; c.CanCollide = false
        end
    end
    notify("Walls removed")
end})
CheatGroup:AddButton({ Text = "Discard held item", Func = function()
    for _, c in pairs(ws:GetDescendants()) do
        if c.Name == "DiscardPickupables" and c:IsA("BasePart") then
            if lp.Character and lp.Character:FindFirstChild("PickupableItem") then
                local dp = c:GetAttribute("DropPos")
                if dp then fireSrv("DropPickupable", dp) end
            end
            break
        end
    end
end})
-- ===== EFFECTS =====
local EffectGroup = Tabs.Effects:AddLeftGroupbox("Visual Effects")
EffectGroup:AddButton({ Text = "Warp Effect (green)", Func = function()
    local we = ls:FindFirstChild("WarpEffect")
    if we then
        local c = we:Clone(); c.Parent = ls; c.Enabled = true
        ts:Create(c, TweenInfo.new(1), {Brightness = 0, Saturation = 0, TintColor = Color3.fromRGB(255,255,255)}):Play()
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
EffectGroup:AddLabel("Blink Effect:")
EffectGroup:AddButton({ Text = "Play Blink", Func = function()
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
EffectGroup:AddLabel("Death Messages:")
EffectGroup:AddDropdown("DeathMsgSelect", {
    Values = {"Lobby","Reality","Cloud Theater","Dream Elementary","Grassy Beach","The Twist","Homescape","The Past Future","Surreal Woodlands","The In-Between"},
    Default = 1, Text = "Select dream"
})
EffectGroup:AddButton({ Text = "Show random message", Func = function()
    local msgs = {
        Lobby = {"How'd you even do that?"},
        Reality = {"Not yet."},
        ["Cloud Theater"] = {"Can you even die in a dream?", "There's nothing below the clouds.", "Dying does not progress.", "You can't die from tranquility."},
        ["Dream Elementary"] = {"What's outside?", "Make it through your school day."},
        ["Grassy Beach"] = {"Imagine far. Imagine far. Imagine far.", "It's so peaceful."},
        ["The Twist"] = {"That didn't make you any closer to paradise."},
        Homescape = {"Do you think you become apart of the house if you die?", "You lie down forever.", "The carpet is really, really soft."},
        ["The Past Future"] = {"This city is supposed to be spotless. Clean.", "Don't just lie down like that.", "I can hear the buildings and the trees at the same time."},
        ["Surreal Woodlands"] = {"Do you feel comfortable?", "Everything can watch you.", "This forest is way too quiet.", "The roots absorb."},
        ["The In-Between"] = {"It gets colder and colder.", "The lights feel like sunlight but the water feels so cold."},
    }
    local dream = Options.DeathMsgSelect.Value
    local m = msgs[dream]
    if m and #m > 0 then sayThing(m[math.random(1, #m)]) end
end})

local SoundEffectGroup = Tabs.Effects:AddRightGroupbox("Sound Effects")
SoundEffectGroup:AddButton({ Text = "Warp Sound", Func = function()
    local s = remote("WarpSound"); if s then s:Play() end
end})
SoundEffectGroup:AddButton({ Text = "Land On Ground", Func = function()
    local s = rs:FindFirstChild("LandOnGroundSFX"); if s then s:Play() end
end})
SoundEffectGroup:AddButton({ Text = "Land In Water", Func = function()
    local s = rs:FindFirstChild("LandInWaterSFX"); if s then s:Play() end
end})

SoundEffectGroup:AddDivider()
SoundEffectGroup:AddLabel("Vote Sounds:")
local function findSound(name)
    for _, c in pairs(SpeechGui:GetDescendants()) do
        if c.Name == name and c:IsA("Sound") then return c end
    end
end
SoundEffectGroup:AddButton({ Text = "Vote Start", Func = function()
    local s = findSound("VoteStart"); if s then s:Play() end
end})
SoundEffectGroup:AddButton({ Text = "Vote Pick", Func = function()
    local s = findSound("VoteSoundPick"); if s then s:Play() end
end})
SoundEffectGroup:AddButton({ Text = "Vote Hover", Func = function()
    local s = findSound("VoteHover"); if s then s:Play() end
end})

SoundEffectGroup:AddDivider()
SoundEffectGroup:AddLabel("Dialogue Sounds:")
SoundEffectGroup:AddButton({ Text = "Type Sound", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("TypeSound"); if s then s:Play() end end
end})
SoundEffectGroup:AddButton({ Text = "SubD Type", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("SubDTypeSound"); if s then s:Play() end end
end})
SoundEffectGroup:AddButton({ Text = "Objective", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("ObjectiveSound"); if s then s:Play() end end
end})
SoundEffectGroup:AddButton({ Text = "Info SFX", Func = function()
    local mf = SpeechGui:FindFirstChild("MainFrame")
    if mf then local s = mf:FindFirstChild("InfoSFX"); if s then s:Play() end end
end})

local DiaGroup = Tabs.Effects:AddRightGroupbox("Dialogue Debug")
DiaGroup:AddLabel("DialogueState: " .. tostring(ws:GetAttribute("DialogueState")))
DiaGroup:AddLabel("Voters: " .. tostring(ws:GetAttribute("CurrentDialogueVoters")))
DiaGroup:AddDivider()
DiaGroup:AddLabel("Fire DialogueMoveOn:")
DiaGroup:AddButton({ Text = "MoveOn (Left)", Func = function() fireSrv("DialogueMoveOn", "Left") end})
DiaGroup:AddButton({ Text = "MoveOn (Right)", Func = function() fireSrv("DialogueMoveOn", "Right") end})
DiaGroup:AddButton({ Text = "MoveOn (default)", Func = function() fireSrv("DialogueMoveOn") end})
DiaGroup:AddDivider()
DiaGroup:AddLabel("DeathEncounter: " .. tostring(ws:GetAttribute("DeathEncounter") or "none"))
DiaGroup:AddButton({ Text = "Reset DeathEncounter", Func = function()
    ws:SetAttribute("DeathEncounter", nil)
end})

-- ===== UI SETTINGS =====
local MenuGroup = Tabs.UI:AddLeftGroupbox("Menu")
MenuGroup:AddButton({ Text = "Unload", Func = function() Library:Unload() end })
MenuGroup:AddLabel("Menu key"):AddKeyPicker("MenuKeybind", {
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

Library:SetWatermark(("NullFire Hub | ABD | %%s fps | %%s ms"):format(60, 0))
Library:OnUnload(function() Library.Unloaded = true end)
SaveManager:LoadAutoloadConfig()
