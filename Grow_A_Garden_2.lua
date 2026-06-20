local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "G A G 2",
    Footer = "v1.4",
    Icon = "leaf",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main     = Window:AddTab("Main",     "tractor"),
    Garden   = Window:AddTab("Garden",   "leaf"),
    Pet      = Window:AddTab("Pet",      "star"),
    Shop     = Window:AddTab("Shop",     "store"),
    Event    = Window:AddTab("Event",    "calendar"),
    Night    = Window:AddTab("Night",    "moon"),
    Player   = Window:AddTab("Player",   "user"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- SERVICES
local RunService          = game:GetService("RunService")
local Players             = game:GetService("Players")
local Workspace           = game:GetService("Workspace")
local Lighting            = game:GetService("Lighting")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualUser         = game:GetService("VirtualUser")
local CollectionService   = game:GetService("CollectionService")
local LocalPlayer         = Players.LocalPlayer

local Event           = ReplicatedStorage.SharedModules.Packet.RemoteEvent
local SELL_ALL_PACKET = buffer.fromstring("\x9C\x00\x12")

_G.HarvestInterval     = 0.1
_G.StealInterval       = 0.1
_G.CollectSeedInterval = 0.1

local Mutations = {
    ['Aurora']      = { pricemultiplier = 1.5  },
    ['Bloodlit']    = { pricemultiplier = 60  },
    ['Chained']     = { pricemultiplier = 8   },
    ['Electric']    = { pricemultiplier = 25  },
    ['Frozen']      = { pricemultiplier = 14  },
    ['Gold']        = { pricemultiplier = 10  },
    ['Pizza']       = { pricemultiplier = 5   },
    ['Rainbow']     = { pricemultiplier = 30  },
    ['Solarflare']  = { pricemultiplier = 5   },
    ['Starstruck']  = { pricemultiplier = 50  },
}

local Fruits = {
    ['Carrot']         = { rarity = 'Common',    sellprice = 5,     hasfruit = false },
    ['Strawberry']     = { rarity = 'Common',    sellprice = 3    },
    ['Blueberry']      = { rarity = 'Common',    sellprice = 5    },
    ['Tulip']          = { rarity = 'Uncommon',  sellprice = 60,    hasfruit = false },
    ['Tomato']         = { rarity = 'Uncommon',  sellprice = 9    },
    ['Apple']          = { rarity = 'Uncommon',  sellprice = 12   },
    ['Bamboo']         = { rarity = 'Rare',      sellprice = 800,   hasfruit = false },
    ['Corn']           = { rarity = 'Rare',      sellprice = 34   },
    ['Cactus']         = { rarity = 'Rare',      sellprice = 40   },
    ['Pineapple']      = { rarity = 'Rare',      sellprice = 30   },
    ['Baby Cactus']    = { rarity = 'Rare',      sellprice = 70   },
    ['Horned Melon']   = { rarity = 'Rare',      sellprice = 200  },
    ['Mushroom']       = { rarity = 'Epic',      sellprice = 13000, hasfruit = false },
    ['Green Bean']     = { rarity = 'Epic',      sellprice = 10   },
    ['Banana']         = { rarity = 'Epic',      sellprice = 35   },
    ['Grape']          = { rarity = 'Epic',      sellprice = 45   },
    ['Coconut']        = { rarity = 'Epic',      sellprice = 60   },
    ['Mango']          = { rarity = 'Epic',      sellprice = 90   },
    ['Glow Mushroom']  = { rarity = 'Epic',      sellprice = 700  },
    ['Dragon Fruit']   = { rarity = 'Legendary', sellprice = 150  },
    ['Acorn']          = { rarity = 'Legendary', sellprice = 200  },
    ['Cherry']         = { rarity = 'Legendary', sellprice = 350  },
    ['Sunflower']      = { rarity = 'Legendary', sellprice = 1750 },
    ['Poison Ivy']     = { rarity = 'Legendary', sellprice = 1700 },
    ['Venus Fly Trap'] = { rarity = 'Mythic',    sellprice = 3000 },
    ['Pomegranate']    = { rarity = 'Mythic',    sellprice = 900  },
    ['Poison Apple']   = { rarity = 'Mythic',    sellprice = 900  },
    ['Venom Spitter']  = { rarity = 'Mythic',    sellprice = 900  },
    ['Ghost Pepper']   = { rarity = 'Mythic',    sellprice = 2500 },
    ['Moon Bloom']     = { rarity = 'Super',     sellprice = 9000 },
    ["Dragon's Breath"]= { rarity = 'Super',     sellprice = 3400 },
}

local Pets = {
    ['Frog'] = {rarity='Common',price=10000},
    ['Bunny'] = {rarity='Common',price=20000},
    ['Owl'] = {rarity='Uncommon',price=25000},
    ['Deer'] = {rarity='Rare',price=50000},
    ['Robin'] = {rarity='Legendary',price=75000},
    ['Bee'] = {rarity='Legendary',price=1000000},
    ['Unicorn'] = {rarity='Legendary',price=4000000},
    ['Monkey'] = {rarity='Mythic',price=1000000},
    ['Golden Dragonfly'] = {rarity='Mythic',price=3000000},
    ['Raccoon'] = {rarity='Super',price=5000000},
    ['Black Dragon'] = {rarity='Super',price=1000000},
    ['Ice Serpent'] = {rarity='Super',price=20000000},
}

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Super" }
local RARITY_ORDER = {}
for i, r in ipairs(RARITIES) do RARITY_ORDER[r] = i end

----------------------------------------------------------------
-- SHARED HELPERS
----------------------------------------------------------------

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function waitAnchor()
    local hrp = getHRP()
    if not hrp then warn("[GAG2] waitAnchor: no HumanoidRootPart") return end
    hrp.Anchored = true
    task.wait(4.5)
    hrp.Anchored = false
end

local function GetMyPlot()
    local gardens = Workspace:FindFirstChild("Gardens")
    if not gardens then return nil end
    for _, plot in ipairs(gardens:GetChildren()) do
        if plot:GetAttribute("Owner") == LocalPlayer.Name then
            return plot
        end
    end
    return nil
end

local function firePP(Object)
    local pp = nil
    if Object:IsA("ProximityPrompt") then
        pp = Object
    else
        for _, v in pairs(Object:GetDescendants()) do
            if v:IsA("ProximityPrompt") then pp = v break end
        end
    end
    if not pp then warn("[GAG2] ProximityPrompt not found") return end
    if not fireproximityprompt then warn("[GAG2] Executor does not support fireproximityprompt") return end
    fireproximityprompt(pp)
end

local function IsNight()
    return workspace:GetAttribute("ActivePhase") == "Night"
end

-- Parse mutation attribute into a list of mutation name strings
local function ParseMutations(model)
    local mutationAttr = model:GetAttribute("Mutation")
    local list = {}
    if typeof(mutationAttr) == "table" then
        for _, m in ipairs(mutationAttr) do table.insert(list, tostring(m)) end
    elseif typeof(mutationAttr) == "string" and mutationAttr ~= "" then
        for m in string.gmatch(mutationAttr, "[^,]+") do
            table.insert(list, m:match("^%s*(.-)%s*$"))
        end
    end
    return list
end

local function GetFruitName(model)
    return model:GetAttribute("FruitType")
        or model:GetAttribute("SeedName")
        or model:GetAttribute("Type")
        or model.Name
end

local function GetFruitRarity(model)
    local name = GetFruitName(model)
    local data = Fruits[name]
    return data and data.rarity or model:GetAttribute("Rarity") or nil
end

----------------------------------------------------------------
-- MAIN TAB
----------------------------------------------------------------

local FarmGroup       = Tabs.Main:AddLeftGroupbox("Farming",       "sprout")
local HarvestFilter   = Tabs.Main:AddRightGroupbox("Harvest Filter", "filter")

-- ── State ──────────────────────────────────────────────────────────────────
local autoHarvestEnabled = false
local autoHarvestThread  = nil

-- Filter state — empty table = any (no toggle needed)
local harvestFilterMutations = {}   -- { [mutName] = true }; empty = harvest any mutation
local harvestFilterFruits    = {}   -- { [fruitName] = true }; empty = harvest any fruit

-- ── Filter logic ───────────────────────────────────────────────────────────
-- Empty table = no filter active (harvest anything).
-- Non-empty table = whitelist — fruit must match at least one entry.
local function FruitPassesFilter(model)
    if next(harvestFilterMutations) then
        local muts  = ParseMutations(model)
        local found = false
        for _, m in ipairs(muts) do
            if harvestFilterMutations[m] then found = true break end
        end
        if not found then return false end
    end

    if next(harvestFilterFruits) then
        if not harvestFilterFruits[GetFruitName(model)] then return false end
    end

    return true
end

local function GetHarvestables()
    local results = {}
    local myPlot  = GetMyPlot()
    if not myPlot then return results end
    local plants  = myPlot:FindFirstChild("Plants")
    if not plants then return results end
    for _, desc in ipairs(plants:GetDescendants()) do
        if desc:GetAttribute("FruitId") and FruitPassesFilter(desc) then
            table.insert(results, desc)
        end
    end
    return results
end

-- Plants whose Fruits table entry has hasfruit = false never carry fruit on the
-- plant model itself — they must be harvested as a whole plant instead of waiting
-- for individual fruit instances to spawn.
local function GetNoFruitPlants()
    local results = {}
    local myPlot  = GetMyPlot()
    if not myPlot then return results end
    local plants  = myPlot:FindFirstChild("Plants")
    if not plants then return results end
    for _, plant in ipairs(plants:GetChildren()) do
        local name = GetFruitName(plant)
        local data = Fruits[name]
        if data and data.hasfruit == false then
            table.insert(results, plant)
        end
    end
    return results
end

-- Net API (same ReplicatedStorage path the game uses)
local Net = nil
pcall(function()
    Net = require(ReplicatedStorage.SharedModules.Networking)
end)

local CollectionService = game:GetService("CollectionService")
local harvestDebounce   = {}

local function AutoHarvestLoop()
    while autoHarvestEnabled do
        local myId  = LocalPlayer.UserId
        local myPlot = GetMyPlot()

        -- Collect via CollectionService tag (fastest — no descendant scan)
        local tagged = CollectionService:GetTagged("HarvestPrompt")
        local list   = {}
        for _, pp in ipairs(tagged) do
            if pp:IsA("ProximityPrompt") and pp.Parent and pp:IsDescendantOf(workspace) then
                local m = pp.Parent:FindFirstAncestorWhichIsA("Model")
                if m and tonumber(m:GetAttribute("UserId")) == myId and m:GetAttribute("PlantId") then
                    if FruitPassesFilter(m) then
                        table.insert(list, m)
                    end
                end
            end
        end

        -- Also sweep Plants folder for hasfruit=false plants (pass filter too)
        if myPlot then
            local plants = myPlot:FindFirstChild("Plants")
            if plants then
                for _, plant in ipairs(plants:GetChildren()) do
                    local name = GetFruitName(plant)
                    local data = Fruits[name]
                    if data and data.hasfruit == false and FruitPassesFilter(plant) then
                        table.insert(list, plant)
                    end
                end
            end
        end

        local now = os.clock()
        for _, m in ipairs(list) do
            if not autoHarvestEnabled then break end
            local pid = m:GetAttribute("PlantId")
            local fid = m:GetAttribute("FruitId")
            local key = tostring(pid) .. "|" .. tostring(fid)
            if not harvestDebounce[key] or now - harvestDebounce[key] > 0.15 then
                harvestDebounce[key] = now
                if Net then
                    pcall(function() Net.Garden.CollectFruit:Fire(pid, fid or "") end)
                else
                    firePP(m)
                end
            end
        end

        if #tagged == 0 then table.clear(harvestDebounce) end
        task.wait(0)   -- yield every frame
    end
end

-- ── Auto Harvest Toggle ────────────────────────────────────────────────────
FarmGroup:AddToggle("AutoHarvest", {
    Text     = "Auto Harvest",
    Default  = false,
    Tooltip  = "Automatically harvest plants on your plot (respects filters)",
    Callback = function(v)
        autoHarvestEnabled = v
        if v then
            if not autoHarvestThread or coroutine.status(autoHarvestThread) == "dead" then
                autoHarvestThread = task.spawn(AutoHarvestLoop)
            end
        end
    end,
})

-- ── Harvest Filters UI ─────────────────────────────────────────────────────
-- No toggles — selecting items activates the filter; clearing all = harvest anything.
local mutationNames = {}
for k in pairs(Mutations) do table.insert(mutationNames, k) end
table.sort(mutationNames)

HarvestFilter:AddLabel("Mutation Filter (empty = any)")
HarvestFilter:AddDropdown("HarvestMutSelect", {
    Values   = mutationNames,
    Default  = nil,
    Text     = "Mutation Whitelist",
    Multi    = true,
    Tooltip  = "Select mutations to whitelist. Clear all selections to harvest any mutation.",
    Callback = function(v)
        harvestFilterMutations = {}
        if type(v) == "table" then
            for k2, state in pairs(v) do
                if type(k2) == "string" and state == true then
                    harvestFilterMutations[k2] = true
                elseif type(k2) == "number" and type(state) == "string" then
                    harvestFilterMutations[state] = true
                end
            end
        elseif type(v) == "string" and v ~= "" then
            harvestFilterMutations[v] = true
        end
    end,
})

HarvestFilter:AddDivider()

local fruitNames = {}
for k in pairs(Fruits) do table.insert(fruitNames, k) end
table.sort(fruitNames)

HarvestFilter:AddLabel("Fruit Filter (empty = any)")
HarvestFilter:AddDropdown("HarvestFruitSelect", {
    Values   = fruitNames,
    Default  = nil,
    Text     = "Fruit Whitelist",
    Multi    = true,
    Tooltip  = "Select fruits to whitelist. Clear all selections to harvest any fruit.",
    Callback = function(v)
        harvestFilterFruits = {}
        if type(v) == "table" then
            for k2, state in pairs(v) do
                if type(k2) == "string" and state == true then
                    harvestFilterFruits[k2] = true
                elseif type(k2) == "number" and type(state) == "string" then
                    harvestFilterFruits[state] = true
                end
            end
        elseif type(v) == "string" and v ~= "" then
            harvestFilterFruits[v] = true
        end
    end,
})

-- ── Prickle Damage toggle ──────────────────────────────────────────────────
local prickleLoop = nil

local function SetPrickleOnAllOtherPlots()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return 0 end
    local count = 0
    for _, plot in ipairs(gardens:GetChildren()) do
        if plot:GetAttribute("Owner") == LocalPlayer.Name then continue end
        for _, desc in ipairs(plot:GetDescendants()) do
            if desc:GetAttribute("SeedName") == "Cactus" then
                pcall(function() desc:Destroy() end)
                count += 1
            end
        end
    end
    return count
end

FarmGroup:AddDivider()

FarmGroup:AddToggle("PrickleDamage", {
    Text     = "Prickle Damage",
    Default  = true,
    Tooltip  = "Destroy Cactus plants on other players' plots",
    Callback = function(v)
        if prickleLoop then task.cancel(prickleLoop) prickleLoop = nil end
        if not v then return end
        SetPrickleOnAllOtherPlots()
        prickleLoop = task.spawn(function()
            while Toggles.PrickleDamage.Value do
                SetPrickleOnAllOtherPlots()
                task.wait(0.5)
            end
        end)
    end,
})

----------------------------------------------------------------
-- NIGHT TAB  (Auto Steal — moved here)
----------------------------------------------------------------

local NightStealGroup    = Tabs.Night:AddLeftGroupbox("Auto Steal",    "sword")
local NightSettingGroup  = Tabs.Night:AddRightGroupbox("Steal Settings", "settings")

-- ── State ──────────────────────────────────────────────────────────────────
local autoStealEnabled    = false
local stealMode           = "all"
local stealPriority       = "any"
local stealTargetPlayer   = nil
local stealThread         = nil
local stealPlayerDropdown = nil
local stealInterval       = 0.1

local stealStatus         = "idle"
local stealStatusLabel    = nil
local stealCount          = 0
local stealLimit          = 50
local stealCountConn      = nil

local plotFruitCache      = {}
local STEAL_ESCAPE_DIST   = 20

-- ── Helpers ────────────────────────────────────────────────────────────────
local function SetStealStatus(s)
    stealStatus = s
    if stealStatusLabel then
        local icons = { idle = "⬜", waiting = "🟡", stealing = "🟢" }
        local icon  = icons[s] or "⬜"
        local label = icon .. " " .. s:upper() .. string.format("  (%d/%d)", stealCount, stealLimit)
        pcall(function() stealStatusLabel:SetText(label) end)
    end
end

local function RefreshStealStatus() SetStealStatus(stealStatus) end

-- FruitValueCalc from the game's own module (same as file 2 reference).
-- Falls back to manual scoring when the module is unavailable.
local FruitValueCalc = nil
pcall(function()
    FruitValueCalc = require(ReplicatedStorage.SharedModules.FruitValueCalc)
end)

local function valueOf(model)
    local name = model:GetAttribute("CorePartName") or model:GetAttribute("SeedName")
    if not name then return 0 end
    if FruitValueCalc then
        local ok, v = pcall(FruitValueCalc, name,
            model:GetAttribute("SizeMulti") or 1,
            model:GetAttribute("Mutation"),
            LocalPlayer,
            model:GetAttribute("DecayAlpha"))
        if ok and type(v) == "number" then return v end
    end
    -- manual fallback: base sell price × size × mutation multiplier
    local size      = tonumber(model:GetAttribute("SizeMulti")) or 1
    local basePrice = (Fruits[name] and Fruits[name].sellprice) or 1
    local mutAttr   = model:GetAttribute("Mutation")
    local mutMul    = 1
    local function applyMut(m)
        local md = Mutations[m:match("^%s*(.-)%s*$")]
        if md then mutMul = mutMul * (md.pricemultiplier or 1) end
    end
    if typeof(mutAttr) == "table" then
        for _, m in ipairs(mutAttr) do applyMut(tostring(m)) end
    elseif typeof(mutAttr) == "string" and mutAttr ~= "" then
        for m in string.gmatch(mutAttr, "[^,]+") do applyMut(m) end
    end
    return basePrice * size * mutMul
end

local function GetStealFruitScore(model)
    -- "highest mutation" and "highest size" use raw attribute counts for sorting
    if stealPriority == "highest mutation" then
        local mutAttr = model:GetAttribute("Mutation")
        local c = 0
        if typeof(mutAttr) == "table" then c = #mutAttr
        elseif typeof(mutAttr) == "string" then
            for _ in string.gmatch(mutAttr, "[^,]+") do c += 1 end
        elseif mutAttr then c = 1 end
        return c
    elseif stealPriority == "highest size" then
        return tonumber(model:GetAttribute("SizeMulti")) or 0
    else
        -- "any" → use actual game value calculation (highest value first)
        return valueOf(model)
    end
end

local function GetPlotByOwner(ownerName)
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return nil end
    for _, plot in ipairs(gardens:GetChildren()) do
        if plot:GetAttribute("Owner") == ownerName then return plot end
    end
    return nil
end

local function BuildPlotFruitCache()
    plotFruitCache = {}
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return end
    for _, plot in ipairs(gardens:GetChildren()) do
        local owner = plot:GetAttribute("Owner")
        if not owner or owner == "" or owner == LocalPlayer.Name then continue end
        local plants = plot:FindFirstChild("Plants")
        if not plants then continue end
        local fruits = {}
        for _, desc in ipairs(plants:GetDescendants()) do
            if desc:IsA("Model") and desc:GetAttribute("FruitId") then
                table.insert(fruits, desc)
            end
        end
        table.sort(fruits, function(a, b)
            return GetStealFruitScore(a) > GetStealFruitScore(b)
        end)
        if #fruits > 0 then plotFruitCache[owner] = fruits end
    end
end

task.defer(BuildPlotFruitCache)

local gardens = workspace:WaitForChild("Gardens")

-- Plot reference cloning (anti-fall boundary)
local PLOT_REFERENCE_RAISE_Y = 50

local function CloneAndRaisePlotReference(plot)
    local ref = plot:FindFirstChild("PlotSizeReference")
    if not ref or not ref:IsA("BasePart") then return end
    if plot:FindFirstChild("PlotSizeReference_Raised") then return end
    local clone = ref:Clone()
    clone.Name        = "PlotSizeReference_Raised"
    clone.CanCollide  = true
    clone.Anchored    = true
    clone.CFrame      = ref.CFrame + Vector3.new(0, PLOT_REFERENCE_RAISE_Y, 0)
    clone.Transparency = 0.5
    clone.Parent      = plot
end

local function SetupAllPlotReferences()
    for _, plot in ipairs(gardens:GetChildren()) do
        CloneAndRaisePlotReference(plot)
    end
end

task.defer(SetupAllPlotReferences)

gardens.ChildAdded:Connect(function(plot)
    task.defer(function() CloneAndRaisePlotReference(plot) end)
end)

gardens.DescendantAdded:Connect(function(desc)
    if not (desc:IsA("Model") and desc:GetAttribute("FruitId")) then return end
    for _, plot in ipairs(gardens:GetChildren()) do
        local owner = plot:GetAttribute("Owner")
        if owner and owner ~= LocalPlayer.Name then
            local plants = plot:FindFirstChild("Plants")
            if plants and desc:IsDescendantOf(plants) then
                plotFruitCache[owner] = plotFruitCache[owner] or {}
                table.insert(plotFruitCache[owner], desc)
                table.sort(plotFruitCache[owner], function(a, b)
                    return GetStealFruitScore(a) > GetStealFruitScore(b)
                end)
                break
            end
        end
    end
end)

gardens.DescendantRemoving:Connect(function(desc)
    if not (desc:IsA("Model") and desc:GetAttribute("FruitId")) then return end
    for owner, fruits in pairs(plotFruitCache) do
        for i, f in ipairs(fruits) do
            if f == desc then table.remove(fruits, i) break end
        end
    end
end)

local function IsPlayerNearby(player, maxDist)
    if not getHRP() then return false end
    local theirHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not theirHRP then return false end
    return (getHRP().Position - theirHRP.Position).Magnitude <= maxDist
end

local function StopStealCountWatcher()
    if stealCountConn then stealCountConn:Disconnect() stealCountConn = nil end
end

local function StartStealCountWatcher()
    StopStealCountWatcher()
    local char = LocalPlayer.Character
    if not char then return end
    stealCountConn = char.DescendantAdded:Connect(function(desc)
        if stealStatus ~= "stealing" then return end
        if desc:IsA("Model") and desc:GetAttribute("FruitId") then
            stealCount += 1
            RefreshStealStatus()
        end
    end)
end

local function ResetStealCount()
    stealCount = 0
    RefreshStealStatus()
end

LocalPlayer.CharacterAdded:Connect(function()
    if autoStealEnabled then task.defer(StartStealCountWatcher) end
end)

local function EscapeToOwnPlot()
    local myPlot = GetMyPlot()
    if not myPlot then return end
    local spawn = myPlot:FindFirstChild("PlotSizeReference") or myPlot:FindFirstChild("SpawnPoint")
    if spawn and spawn:IsA("BasePart") and getHRP() then
        getHRP().Anchored = false
        getHRP().CFrame   = spawn.CFrame
        Library:Notify({ Title = "Auto Steal", Description = "Owner approaching — escaped!", Time = 3 })
    end
end

local function ReturnToOwnPlotLimitReached()
    local myPlot = GetMyPlot()
    if not getHRP() then return end
    if myPlot then
        local spawn = myPlot:FindFirstChild("PlotSizeReference") or myPlot:FindFirstChild("SpawnPoint")
        if spawn and spawn:IsA("BasePart") then getHRP().CFrame = spawn.CFrame end
    end
    Library:Notify({
        Title       = "Auto Steal",
        Description = string.format("Limit reached (%d/%d) — returned to own plot", stealCount, stealLimit),
        Time        = 4,
    })
end

local function GetStealTargetPlayers()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if stealMode == "selected player" and player.Name ~= stealTargetPlayer then continue end
        if player:GetAttribute("IsInOwnGarden") == false then
            table.insert(targets, player)
        end
    end
    return targets
end

-- StealFlags for holdDuration (optional, graceful fail)
local StealFlags = nil
pcall(function()
    StealFlags = require(ReplicatedStorage.SharedModules.Flags.StealFlags)
end)

local function AutoStealLoop()
    StartStealCountWatcher()
    SetStealStatus("waiting")

    while autoStealEnabled do
        if not IsNight() then
            SetStealStatus("waiting")
            task.wait(0.3)
            continue
        end

        if stealCount >= stealLimit then
            SetStealStatus("waiting")
            ReturnToOwnPlotLimitReached()
            while autoStealEnabled and stealCount >= stealLimit do task.wait(0.5) end
            continue
        end

        -- Build steal list from CollectionService tag (same as reference file)
        local list = {}
        local myId = LocalPlayer.UserId
        for _, prompt in ipairs(CollectionService:GetTagged("StealPrompt")) do
            if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt:IsDescendantOf(workspace) then
                local m = prompt.Parent:FindFirstAncestorWhichIsA("Model")
                if m then
                    local uid  = tonumber(m:GetAttribute("UserId"))
                    local pid  = m:GetAttribute("PlantId")
                    local seed = m:GetAttribute("SeedName") or m:GetAttribute("CorePartName")
                    -- mode filter: all / selected player
                    local ownerPlayer = nil
                    if uid and uid ~= myId and pid then
                        if stealMode == "all" then
                            ownerPlayer = Players:GetPlayerByUserId(uid)
                        elseif stealMode == "selected player" and stealTargetPlayer then
                            ownerPlayer = Players:FindFirstChild(stealTargetPlayer)
                            if not ownerPlayer or ownerPlayer.UserId ~= uid then
                                ownerPlayer = nil
                            end
                        end
                    end
                    if ownerPlayer and ownerPlayer:GetAttribute("IsInOwnGarden") == false then
                        -- pass escape-distance check
                        if not IsPlayerNearby(ownerPlayer, STEAL_ESCAPE_DIST) then
                            local stealable = true
                            if StealFlags then
                                pcall(function()
                                    stealable = StealFlags.IsPlantStealable(seed)
                                end)
                            end
                            if stealable then
                                list[#list + 1] = {
                                    m      = m,
                                    pr     = prompt,
                                    uid    = uid,
                                    pid    = pid,
                                    fid    = m:GetAttribute("FruitId"),
                                    seed   = seed,
                                    owner  = ownerPlayer,
                                    score  = GetStealFruitScore(m),
                                }
                            end
                        end
                    end
                end
            end
        end

        if #list == 0 then
            SetStealStatus("waiting")
            task.wait(0.3)
            continue
        end

        -- Sort by score descending (highest value / mutation / size first)
        table.sort(list, function(a, b) return a.score > b.score end)

        -- Save position, teleport to first plot SpawnPoint
        local saved = getHRP() and getHRP().CFrame

        SetStealStatus("stealing")

        for _, e in ipairs(list) do
            if not autoStealEnabled then break end
            if stealCount >= stealLimit then break end
            if not (e.m and e.m.Parent) then continue end

            -- Re-check owner still away
            if e.owner:GetAttribute("IsInOwnGarden") ~= false then continue end
            if IsPlayerNearby(e.owner, STEAL_ESCAPE_DIST) then
                SetStealStatus("waiting")
                EscapeToOwnPlot()
                break
            end

            -- Teleport onto the fruit
            if getHRP() then
                local ok, pivot = pcall(function() return e.m:GetPivot() end)
                if ok then
                    getHRP().CFrame = pivot * CFrame.new(0, 3, 0)
                end
            end

            -- Use Net.Steal if available (reference method), else firePP fallback
            if Net then
                local holdDur = e.pr.HoldDuration
                if (holdDur == nil or holdDur == 0) and StealFlags then
                    pcall(function() holdDur = StealFlags.GetStealHoldDuration(e.seed) end)
                end
                pcall(function() Net.Steal.BeginSteal:Fire(e.uid, e.pid, e.fid or "") end)
                if holdDur and holdDur > 0 then task.wait(holdDur + 0.15) end
                pcall(function() Net.Steal.CompleteSteal:Fire() end)
            else
                firePP(e.pr)
            end

            task.wait(stealInterval)
        end

        -- Return home
        if getHRP() and saved then getHRP().CFrame = saved end
        if getHRP() then getHRP().Anchored = false end

        if stealCount >= stealLimit then
            SetStealStatus("waiting")
            ReturnToOwnPlotLimitReached()
            while autoStealEnabled and stealCount >= stealLimit do task.wait(0.5) end
        else
            SetStealStatus("waiting")
        end

        task.wait(0.1)
    end

    StopStealCountWatcher()
    SetStealStatus("idle")
end

-- ── Anti Steal ────────────────────────────────────────────────────────────
local antiStealEnabled = false
local antiStealThread  = nil

local function findShovel()
    local function scan(c)
        if not c then return nil end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("Shovel") ~= nil then return t end
        end
    end
    return scan(LocalPlayer.Character) or scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
end

local function findIntruders()
    local myPlot = GetMyPlot()
    if not myPlot then return {} end
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        -- Player is in our garden if their attribute matches our plot owner name,
        -- or if their HRP is physically inside our plot bounds.
        local ch    = p.Character
        local tHRP  = ch and ch:FindFirstChild("HumanoidRootPart")
        if not tHRP then continue end
        -- Use GardenZoneData if available (same as reference)
        local gzd = ReplicatedStorage:FindFirstChild("GardenZoneData")
        local myPlotId = LocalPlayer:GetAttribute("PlotId")
        if gzd and myPlotId then
            local v = gzd:FindFirstChild(p.Name)
            if v and v.Value == myPlotId then
                table.insert(out, p)
            end
        else
            -- fallback: spatial check inside plot bounds
            local ref = myPlot:FindFirstChild("PlotSizeReference")
            if ref and ref:IsA("BasePart") then
                local rel = ref.CFrame:PointToObjectSpace(tHRP.Position)
                local hs  = ref.Size / 2
                if math.abs(rel.X) < hs.X and math.abs(rel.Z) < hs.Z then
                    table.insert(out, p)
                end
            end
        end
    end
    return out
end

local function AntiStealLoop()
    while antiStealEnabled do
        if IsNight() then
            local intruders = findIntruders()
            local shovel    = findShovel()
            if #intruders > 0 and getHRP() then
                local saved = getHRP().CFrame
                if shovel then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:EquipTool(shovel) end) end
                end
                for _, p in ipairs(intruders) do
                    if not antiStealEnabled then break end
                    local ch   = p.Character
                    local tHRP = ch and ch:FindFirstChild("HumanoidRootPart")
                    if tHRP then
                        local tp = tHRP.Position
                        local h2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if h2 then
                            h2.CFrame = CFrame.new(tp + Vector3.new(0, 0, 5), tp)
                        end
                        if Net then
                            pcall(function() Net.Shovel.SwingShovel:Fire() end)
                            pcall(function() Net.Shovel.HitPlayer:Fire(p.UserId) end)
                        end
                        task.wait(0.66) -- server swing cooldown
                    end
                end
                local hb = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hb then hb.CFrame = saved end
            end
        end
        task.wait(antiStealEnabled and 0.2 or 1)
    end
end

workspace:GetAttributeChangedSignal("ActivePhase"):Connect(function()
    if workspace:GetAttribute("ActivePhase") == "Night" then
        BuildPlotFruitCache()
    end
end)

-- ── Night Tab UI ───────────────────────────────────────────────────────────

NightStealGroup:AddToggle("AutoSteal", {
    Text     = "Auto Steal",
    Default  = false,
    Tooltip  = "Night only: teleport to unattended plots and steal fruits",
    Callback = function(v)
        autoStealEnabled = v
        if v then
            BuildPlotFruitCache()
            StartStealCountWatcher()
            if not stealThread or coroutine.status(stealThread) == "dead" then
                stealThread = task.spawn(AutoStealLoop)
            end
            Library:Notify({
                Title       = "Auto Steal",
                Description = IsNight() and "Active — Night detected" or "Waiting for Night...",
                Time        = 3,
            })
        else
            if getHRP() then getHRP().Anchored = false end
            StopStealCountWatcher()
            SetStealStatus("idle")
            Library:Notify({ Title = "Auto Steal", Description = "Stopped", Time = 2 })
        end
    end,
})

stealStatusLabel = NightStealGroup:AddLabel("⬜ IDLE  (0/" .. stealLimit .. ")")

NightStealGroup:AddDivider()

NightStealGroup:AddButton({
    Text    = "Reset Counter",
    Func    = function()
        ResetStealCount()
        Library:Notify({ Title = "Auto Steal", Description = "Counter reset to 0", Time = 2 })
    end,
    Tooltip = "Manually reset the stolen fruit counter to 0",
})

NightStealGroup:AddButton({
    Text    = "Refresh Fruit Cache",
    Func    = function()
        BuildPlotFruitCache()
        Library:Notify({ Title = "Auto Steal", Description = "Fruit cache rebuilt", Time = 2 })
    end,
    Tooltip = "Manually rescan all plots and rebuild fruit cache",
})

NightStealGroup:AddButton({
    Text    = "Return to Own Plot",
    Func    = function()
        EscapeToOwnPlot()
    end,
    Tooltip = "Immediately teleport back to your own plot",
})

NightStealGroup:AddDivider()

NightStealGroup:AddToggle("AntiSteal", {
    Text     = "Anti Steal",
    Default  = false,
    Tooltip  = "Night only: detect intruders in your plot and hit them with your shovel",
    Callback = function(v)
        antiStealEnabled = v
        if v then
            if not antiStealThread or coroutine.status(antiStealThread) == "dead" then
                antiStealThread = task.spawn(AntiStealLoop)
            end
            Library:Notify({ Title = "Anti Steal", Description = "Active — watching your plot", Time = 3 })
        else
            Library:Notify({ Title = "Anti Steal", Description = "Stopped", Time = 2 })
        end
    end,
})

-- Settings on right groupbox
NightSettingGroup:AddDropdown("StealMode", {
    Values   = { "all", "selected player" },
    Default  = "all",
    Text     = "Steal Mode",
    Tooltip  = "Target all unattended players, or one specific player",
    Callback = function(v)
        stealMode = v
        if v == "selected player" and stealPlayerDropdown then
            local names = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then table.insert(names, p.Name) end
            end
            if #names == 0 then names = { "— no players —" } end
            stealPlayerDropdown:SetValues(names)
        end
    end,
})

local function GetOtherPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    if #names == 0 then names = { "— no players —" } end
    return names
end

stealPlayerDropdown = NightSettingGroup:AddDropdown("StealTargetPlayer", {
    Values   = GetOtherPlayerNames(),
    Default  = nil,
    Multi       = true,
    Text     = "Target Player",
    Tooltip  = "Active only when Steal Mode is 'selected player'",
    Callback = function(v) stealTargetPlayer = v end,
})

NightSettingGroup:AddButton({
    Text    = "Refresh Player List",
    Func    = function()
        stealPlayerDropdown:SetValues(GetOtherPlayerNames())
        Library:Notify({ Title = "Auto Steal", Description = "Player list refreshed", Time = 2 })
    end,
    Tooltip = "Refresh player list",
})

NightSettingGroup:AddDropdown("StealPriority", {
    Values   = { "any", "highest mutation", "highest size" },
    Default  = "any",
    Text     = "Fruit Priority",
    Tooltip  = "Which fruit attribute to prioritize when stealing",
    Callback = function(v)
        stealPriority = v
        BuildPlotFruitCache()
    end,
})

NightSettingGroup:AddSlider("StealInterval", {
    Text     = "Steal Interval (s)",
    Default  = 0.1,
    Min      = 0.05,
    Max      = 1,
    Rounding = 2,
    Tooltip  = "Wait between stealing each fruit",
    Callback = function(v) stealInterval = v end,
})

NightSettingGroup:AddSlider("StealLimit", {
    Text     = "Bag Limit",
    Default  = 50,
    Min      = 10,
    Max      = 200,
    Rounding = 0,
    Tooltip  = "Return to own plot when stolen model count reaches this",
    Callback = function(v)
        stealLimit = v
        RefreshStealStatus()
    end,
})

NightSettingGroup:AddSlider("EscapeDistance", {
    Text     = "Escape Distance (studs)",
    Default  = 20,
    Min      = 5,
    Max      = 60,
    Rounding = 0,
    Tooltip  = "Flee to own plot if owner is closer than this distance",
    Callback = function(v) STEAL_ESCAPE_DIST = v end,
})

----------------------------------------------------------------
-- GARDEN TAB
----------------------------------------------------------------

-- ── Auto Plant Seeds ────────────────────────────────────────────────────────
local PlantGroup = Tabs.Garden:AddRightGroupbox("Auto Plant Seeds", "sprout")

local autoPlantEnabled = false
local autoPlantStack   = false    -- true = stack all seeds on one spot
local plantStackPoint  = nil      -- Vector3 for stack mode
local autoPlantThread  = nil

local function groundPointUnder(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = CollectionService:GetTagged("PlantArea")
    local r = workspace:Raycast(pos + Vector3.new(0, 12, 0), Vector3.new(0, -60, 0), params)
    return r and r.Position
end

local function currentStackPoint()
    if plantStackPoint then return plantStackPoint end
    if not getHRP() then return nil end
    return groundPointUnder(getHRP().Position) or (getHRP().Position - Vector3.new(0, 2.5, 0))
end

local function autoPlantOnce()
    if not Net then return end  -- Net required for PlantSeed remote

    -- Find plot via PlotId attribute (same as reference)
    local plotId = LocalPlayer:GetAttribute("PlotId")
    local plot   = plotId and workspace:FindFirstChild("Gardens")
        and workspace.Gardens:FindFirstChild("Plot" .. tostring(plotId))
    if not plot then
        -- fallback: find by owner name
        plot = GetMyPlot()
    end
    if not plot then return end

    -- Collect seed tools from Backpack + Character
    local seedTools = {}
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("SeedTool") ~= nil then
                table.insert(seedTools, t)
            end
        end
    end
    scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
    scan(LocalPlayer.Character)
    if #seedTools == 0 then return end

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

    -- STACK MODE: dump every seed onto one point
    if autoPlantStack then
        local pt = currentStackPoint()
        if not pt then return end
        for _, tool in ipairs(seedTools) do
            if not (autoPlantEnabled and autoPlantStack) then break end
            local seedName = tool:GetAttribute("SeedTool")
            local count    = tool:GetAttribute("Count") or 1
            if hum then pcall(function() hum:EquipTool(tool) end) end
            for _ = 1, count do
                if not (autoPlantEnabled and autoPlantStack) or not tool.Parent then break end
                pcall(function() Net.Plant.PlantSeed:Fire(pt, seedName, tool) end)
                task.wait(0.07)
            end
        end
        return
    end

    -- SPREAD MODE: plant into evenly spaced free slots across the PlantArea
    local CELL, MIN2 = 2, 1.3 * 1.3
    local buckets = {}
    local function bk(cx, cz) return cx .. "," .. cz end
    local function addPt(p)
        local cx, cz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
        local key = bk(cx, cz)
        if not buckets[key] then buckets[key] = {} end
        table.insert(buckets[key], p)
    end
    local function tooClose(p)
        local cx, cz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
        for dx = -1, 1 do for dz = -1, 1 do
            local b = buckets[bk(cx + dx, cz + dz)]
            if b then for _, q in ipairs(b) do
                local ax, az = p.X - q.X, p.Z - q.Z
                if ax * ax + az * az < MIN2 then return true end
            end end
        end end
        return false
    end

    -- Seed bucket with existing plant positions
    local plantsFolder = plot:FindFirstChild("Plants")
    if plantsFolder then
        for _, pl in ipairs(plantsFolder:GetChildren()) do
            local ok, cf = pcall(function() return pl:GetPivot() end)
            local p = ok and cf.Position or (pl:IsA("BasePart") and pl.Position)
            if p then addPt(p) end
        end
    end

    -- Generate free slots over PlantArea parts inside our plot
    local GAP   = 2.5
    local slots = {}
    for _, pa in ipairs(CollectionService:GetTagged("PlantArea")) do
        if pa:IsA("BasePart") and pa.Size.Y < 1 and pa:IsDescendantOf(plot) then
            local sx, sz = pa.Size.X, pa.Size.Z
            local lx = -sx / 2 + GAP / 2
            while lx < sx / 2 do
                local lz = -sz / 2 + GAP / 2
                while lz < sz / 2 do
                    local world = (pa.CFrame * CFrame.new(lx, pa.Size.Y / 2 + 0.05, lz)).Position
                    if not tooClose(world) then
                        addPt(world)
                        table.insert(slots, world)
                    end
                    lz = lz + GAP
                end
                lx = lx + GAP
            end
        end
    end
    if #slots == 0 then return end

    -- Plant each seed tool across available slots
    local si = 1
    for _, tool in ipairs(seedTools) do
        if not autoPlantEnabled or si > #slots then break end
        local seedName = tool:GetAttribute("SeedTool")
        local count    = tool:GetAttribute("Count") or 1
        if hum then pcall(function() hum:EquipTool(tool) end) end
        for _ = 1, count do
            if not autoPlantEnabled or si > #slots then break end
            if not tool.Parent then break end
            local pos = slots[si]; si += 1
            pcall(function() Net.Plant.PlantSeed:Fire(pos, seedName, tool) end)
            task.wait(0.07)
        end
    end
end

local function AutoPlantLoop()
    while autoPlantEnabled do
        pcall(autoPlantOnce)
        task.wait(0.6)
    end
end

PlantGroup:AddToggle("AutoPlant", {
    Text     = "Auto Plant Seeds",
    Default  = false,
    Tooltip  = "Automatically plant seeds from your inventory into your plot",
    Callback = function(v)
        autoPlantEnabled = v
        if v then
            if not autoPlantThread or coroutine.status(autoPlantThread) == "dead" then
                autoPlantThread = task.spawn(AutoPlantLoop)
            end
            Library:Notify({ Title = "Auto Plant", Description = "Started", Time = 2 })
        else
            Library:Notify({ Title = "Auto Plant", Description = "Stopped", Time = 2 })
        end
    end,
})

PlantGroup:AddToggle("PlantStackMode", {
    Text     = "Stack Mode",
    Default  = false,
    Tooltip  = "Stack all seeds on one spot instead of spreading across the plot",
    Callback = function(v)
        autoPlantStack = v
    end,
})

PlantGroup:AddButton({
    Text    = "Set Stack Spot (stand here)",
    Func    = function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            plantStackPoint = groundPointUnder(hrp.Position)
                or (hrp.Position - Vector3.new(0, 2.5, 0))
            Library:Notify({ Title = "Auto Plant", Description = "Stack spot set at current position", Time = 2 })
        else
            Library:Notify({ Title = "Auto Plant", Description = "Character not found", Time = 2 })
        end
    end,
    Tooltip = "Stand where you want all seeds stacked, then press this",
})

PlantGroup:AddButton({
    Text    = "Clear Stack Spot",
    Func    = function()
        plantStackPoint = nil
        Library:Notify({ Title = "Auto Plant", Description = "Stack spot cleared — will use current position", Time = 2 })
    end,
    Tooltip = "Remove the saved stack spot (defaults to standing position)",
})

-- ── Fruit ESP ──────────────────────────────────────────────────────────────
local GardenGroup = Tabs.Garden:AddLeftGroupbox("Fruit ESP", "apple")

local espMode       = "highest mutation + size"
local espEnabled    = false
local espScope      = "all plots"
local selectedPlots = {}
local ESPObjects    = {}
local espDirty      = true     -- flag: rebuild candidates on next tick
local espCandidates = {}       -- current list of highlighted fruits
local espTimer      = 0

local function GetOtherPlotOwners()
    local names = {}
    local g = workspace:FindFirstChild("Gardens")
    if not g then return { "— no plots —" } end
    for _, plot in ipairs(g:GetChildren()) do
        local owner = plot:GetAttribute("Owner")
        if owner and owner ~= "" and owner ~= LocalPlayer.Name then
            table.insert(names, owner)
        end
    end
    if #names == 0 then names = { "— no plots —" } end
    return names
end

GardenGroup:AddToggle("FruitESP", {
    Text     = "Fruit ESP",
    Default  = false,
    Callback = function(v)
        espEnabled = v
        espDirty = true
    end
})

GardenGroup:AddDropdown("ESPMode", {
    Values   = { "highest mutation + size", "highest size", "highest mutation" },
    Default  = "highest mutation + size",
    Text     = "ESP Mode",
    Callback = function(v) espMode = v espDirty = true end
})

local espScopePlotDropdown = nil

GardenGroup:AddDropdown("ESPScope", {
    Values   = { "all plots", "my plot", "selected plots" },
    Default  = "all plots",
    Text     = "ESP Scope",
    Callback = function(v)
        espScope      = v
        selectedPlots = {}
        espDirty      = true
        if espScopePlotDropdown then
            espScopePlotDropdown:SetValue(nil)
            espScopePlotDropdown:SetValues(GetOtherPlotOwners())
        end
    end
})

espScopePlotDropdown = GardenGroup:AddDropdown("ESPPlotSelect", {
    Values      = GetOtherPlotOwners(),
    Default     = nil,
    Text        = "Select Plot (multi)",
    MultiSelect = true,
    Tooltip     = "Active only when ESP Scope is 'selected plots'",
    Callback    = function(v)
        selectedPlots = {}
        if type(v) == "table" then
            for _, name in ipairs(v) do selectedPlots[name] = true end
        elseif type(v) == "string" then
            selectedPlots[v] = true
        end
        espDirty = true
    end
})

GardenGroup:AddButton({
    Text    = "Refresh Plot List",
    Func    = function()
        espScopePlotDropdown:SetValues(GetOtherPlotOwners())
        Library:Notify({ Title = "ESP", Description = "Plot list refreshed", Time = 2 })
    end,
    Tooltip = "Refresh other players' plot list"
})

local function getFruitScore(model)
    local size          = tonumber(model:GetAttribute("SizeMulti")) or 0
    local mutationAttr  = model:GetAttribute("Mutation")
    local mutationCount = 0
    if typeof(mutationAttr) == "table" then
        mutationCount = #mutationAttr
    elseif typeof(mutationAttr) == "string" then
        for _ in string.gmatch(mutationAttr, "[^,]+") do mutationCount += 1 end
    elseif mutationAttr then
        mutationCount = 1
    end
    if espMode == "highest size" then return size
    elseif espMode == "highest mutation" then return mutationCount
    else return (mutationCount * 100000) + size end
end

local function clearFruitESP()
    for _, hl in pairs(ESPObjects) do if hl then hl:Destroy() end end
    table.clear(ESPObjects)
    table.clear(espCandidates)
end

local function isFruitInScope(fruitModel)
    if espScope == "all plots" then return true end
    local g = workspace:FindFirstChild("Gardens")
    if not g then return false end
    for _, plot in ipairs(g:GetChildren()) do
        local plants = plot:FindFirstChild("Plants")
        if plants and fruitModel:IsDescendantOf(plants) then
            local owner = plot:GetAttribute("Owner")
            if espScope == "my plot" then return owner == LocalPlayer.Name
            elseif espScope == "selected plots" then return selectedPlots[owner] == true end
        end
    end
    return false
end

-- Rebuild candidates every 0.5s; apply/remove highlights every frame
RunService.Heartbeat:Connect(function(dt)
    if not espEnabled then
        if next(ESPObjects) then clearFruitESP() end
        return
    end

    espTimer += dt
    -- Rebuild candidate list every 0.5s (expensive scan)
    if espDirty or espTimer >= 0.5 then
        espDirty = false
        espTimer = 0

        local g = workspace:FindFirstChild("Gardens")
        if not g then return end

        local highestScore = -math.huge
        local newCandidates = {}

        for _, obj in ipairs(g:GetDescendants()) do
            if obj:IsA("Model") and obj:GetAttribute("FruitId") and isFruitInScope(obj) then
                local score = getFruitScore(obj)
                if score > highestScore then
                    highestScore = score
                    table.clear(newCandidates)
                    table.insert(newCandidates, obj)
                elseif score == highestScore then
                    table.insert(newCandidates, obj)
                end
            end
        end

        espCandidates = newCandidates
    end

    -- Apply ESP to candidates, remove from non-candidates
    local valid = {}
    for _, fruit in ipairs(espCandidates) do
        if fruit and fruit.Parent then
            valid[fruit] = true
            if not ESPObjects[fruit] then
                local hl = Instance.new("Highlight")
                hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency    = 0.5
                hl.OutlineTransparency = 0
                hl.Adornee             = fruit
                hl.Parent              = fruit
                ESPObjects[fruit]      = hl
            end
        end
    end

    for model, hl in pairs(ESPObjects) do
        if not valid[model] then
            hl:Destroy()
            ESPObjects[model] = nil
        end
    end
end)

-- Mark ESP dirty when gardens change
gardens.DescendantAdded:Connect(function(desc)
    if desc:IsA("Model") and desc:GetAttribute("FruitId") then espDirty = true end
end)
gardens.DescendantRemoving:Connect(function(desc)
    if desc:IsA("Model") and desc:GetAttribute("FruitId") then espDirty = true end
end)

-- ── Teleport to Plot ───────────────────────────────────────────────────────
local TeleportGroup = Tabs.Garden:AddRightGroupbox("Teleport to Plot", "map-pin")

local function GetPlotOwnerList()
    local list = {}
    local g    = workspace:FindFirstChild("Gardens")
    if not g then return { "— no plots —" } end
    for _, plot in ipairs(g:GetChildren()) do
        local owner = plot:GetAttribute("Owner")
        if owner and owner ~= "" then table.insert(list, owner) end
    end
    if #list == 0 then list = { "— no plots —" } end
    return list
end

local selectedTpPlot = nil
local tpPlotDropdown = TeleportGroup:AddDropdown("TpPlotSelect", {
    Values   = GetPlotOwnerList(),
    Default  = nil,
    Text     = "Select Plot Owner",
    Callback = function(v) selectedTpPlot = v end
})

TeleportGroup:AddButton({
    Text    = "Refresh Plot List",
    Func    = function()
        tpPlotDropdown:SetValues(GetPlotOwnerList())
        Library:Notify({ Title = "Teleport", Description = "Plot list refreshed", Time = 2 })
    end,
    Tooltip = "Refresh the list of occupied plots"
})

TeleportGroup:AddButton({
    Text    = "Teleport",
    Func    = function()
        if not selectedTpPlot then
            Library:Notify({ Title = "Teleport", Description = "No plot selected", Time = 2 })
            return
        end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local g = workspace:FindFirstChild("Gardens")
        if not g then return end
        for _, plot in ipairs(g:GetChildren()) do
            if plot:GetAttribute("Owner") == selectedTpPlot then
                local spawn = plot:FindFirstChild("SpawnPoint")
                if spawn and spawn:IsA("BasePart") then
                    hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
                    Library:Notify({ Title = "Teleport", Description = "Teleported to " .. selectedTpPlot .. "'s plot", Time = 2 })
                else
                    Library:Notify({ Title = "Teleport", Description = "SpawnPoint not found", Time = 2 })
                end
                return
            end
        end
        Library:Notify({ Title = "Teleport", Description = "Plot not found for " .. selectedTpPlot, Time = 2 })
    end,
    Tooltip = "Teleport to the selected plot's SpawnPoint"
})

----------------------------------------------------------------
-- PET TAB
----------------------------------------------------------------

local WildPetFolder = workspace:WaitForChild("Map"):WaitForChild("WildPetSpawns")

local petESPEnabled   = false
local PetESPObjects   = {}
local activePetModels = {}
local selectedPetKey  = nil
local petTpDropdown   = nil

local PetESPGroup    = Tabs.Pet:AddLeftGroupbox("Wild Pet ESP",      "eye")
local PetTpGroup     = Tabs.Pet:AddLeftGroupbox("Teleport to Pet",   "map-pin")
local PetBuyGroup    = Tabs.Pet:AddRightGroupbox("Auto Buy Pet",     "shopping-cart")

local function RefreshPetDropdown()
    if not petTpDropdown then return end
    local names = {}
    for key in pairs(activePetModels) do table.insert(names, key) end
    table.sort(names)
    if #names == 0 then names = { "— no pets —" } selectedPetKey = nil end
    petTpDropdown:SetValues(names)
end

local function AddPetESP(petModel)
    if PetESPObjects[petModel] then return end
    local hl = Instance.new("Highlight")
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor           = Color3.fromRGB(255, 220, 50)
    hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency    = 0.4
    hl.OutlineTransparency = 0
    hl.Adornee             = petModel
    hl.Parent              = petModel

    local rootPart = petModel:FindFirstChildWhichIsA("BasePart")
    local billboard
    if rootPart then
        billboard             = Instance.new("BillboardGui")
        billboard.Size        = UDim2.new(0, 120, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee     = rootPart
        billboard.AlwaysOnTop = true
        billboard.Parent      = rootPart
        local label = Instance.new("TextLabel")
        label.Size                   = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3             = Color3.fromRGB(255, 255, 50)
        label.TextStrokeTransparency = 0
        label.Font                   = Enum.Font.GothamBold
        label.TextScaled             = true
        label.Text                   = petModel:GetAttribute("PetName") or petModel.Name
        label.Parent                 = billboard
    end
    PetESPObjects[petModel] = { highlight = hl, billboard = billboard }
end

local function RemovePetESP(petModel)
    local data = PetESPObjects[petModel]
    if not data then return end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    PetESPObjects[petModel] = nil
end

local function PetKey(pet)
    return (pet:GetAttribute("PetName") or pet.Name) .. "_" .. tostring(pet):sub(-6)
end

local function RegisterPet(pet)
    if not pet:IsA("Model") then return end
    local key = PetKey(pet)
    activePetModels[key] = pet
    if petESPEnabled then AddPetESP(pet) end
    RefreshPetDropdown()
end

local function UnregisterPet(pet)
    RemovePetESP(pet)
    activePetModels[PetKey(pet)] = nil
    RefreshPetDropdown()
end

for _, pet in ipairs(WildPetFolder:GetChildren()) do RegisterPet(pet) end

WildPetFolder.ChildAdded:Connect(function(pet)
    task.wait()
    RegisterPet(pet)
    Library:Notify({ Title = "Wild Pet Spawned!", Description = pet:GetAttribute("PetName") or pet.Name, Time = 4 })
end)

WildPetFolder.ChildRemoved:Connect(function(pet) UnregisterPet(pet) end)

PetESPGroup:AddToggle("WildPetESP", {
    Text     = "Wild Pet ESP",
    Default  = false,
    Tooltip  = "Highlight wild pets with name tags",
    Callback = function(v)
        petESPEnabled = v
        if v then
            for _, model in pairs(activePetModels) do AddPetESP(model) end
        else
            for model in pairs(PetESPObjects) do RemovePetESP(model) end
        end
    end
})

petTpDropdown = PetTpGroup:AddDropdown("TpPetSelect", {
    Values   = { "— no pets —" },
    Default  = nil,
    Text     = "Select Wild Pet",
    Tooltip  = "Choose a spawned wild pet to teleport to",
    Callback = function(v) selectedPetKey = v end
})

PetTpGroup:AddButton({
    Text    = "Teleport to Pet",
    Func    = function()
        if not selectedPetKey then
            Library:Notify({ Title = "Teleport", Description = "No pet selected", Time = 2 })
            return
        end
        local petModel = activePetModels[selectedPetKey]
        if not petModel or not petModel.Parent then
            Library:Notify({ Title = "Teleport", Description = "Pet no longer exists", Time = 2 })
            activePetModels[selectedPetKey] = nil
            RefreshPetDropdown()
            return
        end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local root = petModel:FindFirstChildWhichIsA("BasePart")
        if root then
            hrp.CFrame = root.CFrame
            waitAnchor()
            Library:Notify({ Title = "Teleport", Description = "Teleported to " .. (petModel:GetAttribute("PetName") or petModel.Name), Time = 2 })
        else
            Library:Notify({ Title = "Teleport", Description = "Pet has no BasePart", Time = 2 })
        end
    end,
    Tooltip = "Teleport to the selected wild pet"
})

-- ── Auto Buy Pet ───────────────────────────────────────────────────────────
local RARITY_RANK = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5,
    Mythic = 6, Mythical = 6, Godly = 7, Divine = 8, Secret = 9, Prismatic = 10,
}

local autoBuyPet      = false
local autoBuyPetThread = nil
local selectedPetName = nil   -- name filter; nil = any
local petBuyDropdown  = nil

-- Map: display label → raw pet name
local petLabelToName = {}

local function fmtPrice(n)
    local s = tostring(math.floor(n))
    local r, len = "", #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then r = r .. "," end
        r = r .. s:sub(i, i)
    end
    return r
end

-- Build labels sorted by rarity then price; format: "PetName | 10,000"
local function GetWildPetNames()
    petLabelToName = {}
    local labels = {}
    local seen   = {}

    -- Static Pets table — sort by rarity rank ascending, then price ascending
    local sorted = {}
    for name, data in pairs(Pets) do
        table.insert(sorted, { name = name, data = data })
    end
    table.sort(sorted, function(a, b)
        local ra = RARITY_RANK[a.data.rarity] or 0
        local rb = RARITY_RANK[b.data.rarity] or 0
        if ra ~= rb then return ra < rb end
        return (a.data.price or 0) < (b.data.price or 0)
    end)
    for _, e in ipairs(sorted) do
        local label = e.name .. " | " .. fmtPrice(e.data.price or 0)
        seen[e.name]          = true
        petLabelToName[label] = e.name
        table.insert(labels, label)
    end

    -- Supplement from live WildPetRef
    local map = workspace:FindFirstChild("Map")
    local refFolder = map and map:FindFirstChild("WildPetRef")
    if refFolder then
        for _, ref in ipairs(refFolder:GetChildren()) do
            local n = ref:GetAttribute("PetName") or ref.Name
            if not seen[n] then
                seen[n] = true
                local price = ref:GetAttribute("Price") or 0
                local label = n .. " | " .. fmtPrice(price)
                petLabelToName[label] = n
                table.insert(labels, label)
            end
        end
    end

    if #labels == 0 then
        labels = { "— no pets available —" }
    end
    return labels
end

local function pickBestWildPet(refFolder)
    local best, bestRank = nil, -1
    for _, ref in ipairs(refFolder:GetChildren()) do
        if ref:IsA("BasePart") and (ref:GetAttribute("OwnerUserId") or 0) == 0 then
            -- Name filter
            if selectedPetName and ref:GetAttribute("PetName") ~= selectedPetName then continue end
            local r    = ref:GetAttribute("Rarity")
            local rank = (r and RARITY_RANK[r]) or 0
            if rank > bestRank then bestRank = rank best = ref end
        end
    end
    return best
end

local function AutoBuyPetLoop()
    while autoBuyPet do
        local map       = workspace:FindFirstChild("Map")
        local refFolder = map and map:FindFirstChild("WildPetRef")
        if refFolder and Net then
            local best = pickBestWildPet(refFolder)
            if best then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local saved = hrp.CFrame
                    local t0    = os.clock()
                    while autoBuyPet and best.Parent
                        and (best:GetAttribute("OwnerUserId") or 0) == 0
                        and os.clock() - t0 < 30 do
                        hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 2))
                        pcall(function() Net.Pets.WildPetTame:Fire(best) end)
                        task.wait(0.1)
                    end
                    hrp.CFrame = saved
                    -- short cooldown before scanning for next pet
                    task.wait(1)
                end
            end
        end
        task.wait(0.5)
    end
end

PetBuyGroup:AddToggle("AutoBuyPet", {
    Text     = "Auto Buy Pet",
    Default  = false,
    Tooltip  = "Automatically tame the highest-rarity unowned wild pet",
    Callback = function(v)
        autoBuyPet = v
        if v then
            if not autoBuyPetThread or coroutine.status(autoBuyPetThread) == "dead" then
                autoBuyPetThread = task.spawn(AutoBuyPetLoop)
            end
            Library:Notify({ Title = "Auto Buy Pet", Description = "Started", Time = 2 })
        else
            Library:Notify({ Title = "Auto Buy Pet", Description = "Stopped", Time = 2 })
        end
    end,
})

petBuyDropdown = PetBuyGroup:AddDropdown("PetBuySelect", {
    Values   = GetWildPetNames(),
    Default  = nil,
    Text     = "Target Pet (any if none)",
    Tooltip  = "Leave blank to buy any highest-rarity pet; select one to filter by name",
    Callback = function(v)
        -- Decode label ("PetName | price") back to raw pet name
        if type(v) == "string" then
            selectedPetName = petLabelToName[v] or nil
        else
            selectedPetName = nil
        end
    end,
})

PetBuyGroup:AddButton({
    Text    = "Refresh Pet List",
    Func    = function()
        if petBuyDropdown then petBuyDropdown:SetValues(GetWildPetNames()) end
        Library:Notify({ Title = "Auto Buy Pet", Description = "Pet list refreshed", Time = 2 })
    end,
    Tooltip = "Reload wild pet names from the map",
})

PetBuyGroup:AddLabel("Highest rarity unowned pet is targeted when no filter is set.")

----------------------------------------------------------------
-- SHOP TAB
----------------------------------------------------------------

local ShopBtnGroup  = Tabs.Shop:AddLeftGroupbox("Shop Shortcuts", "store")
local AutoSellGroup = Tabs.Shop:AddRightGroupbox("Auto Sell", "coins")

local function ToggleShopGui(name, label)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local gui = playerGui:FindFirstChild(name, true)
    if gui then
        gui.Enabled = not gui.Enabled
        Library:Notify({ Title = "Garden Robot 2", Description = label .. (gui.Enabled and " opened!" or " closed!"), Time = 2 })
    else
        Library:Notify({ Title = "Garden Robot 2", Description = name .. " not found in PlayerGui", Time = 2 })
    end
end

ShopBtnGroup:AddButton({ Text = "Seed Shop",  Func = function() ToggleShopGui("SeedShop",  "Seed Shop")  end, Tooltip = "Toggle Seed Shop UI" })
ShopBtnGroup:AddButton({ Text = "Gear Shop",  Func = function() ToggleShopGui("GearShop",  "Gear Shop")  end, Tooltip = "Toggle Gear Shop UI" })
ShopBtnGroup:AddButton({ Text = "Crate Shop", Func = function() ToggleShopGui("CrateShop", "Crate Shop") end, Tooltip = "Toggle Crate Shop UI" })

local autoSellEnabled = false
local autoSellThread  = nil
local sellInterval    = 5

local function AutoSellLoop()
    while autoSellEnabled do
        pcall(function() Event:FireServer(SELL_ALL_PACKET) end)
        task.wait(sellInterval)
    end
end

AutoSellGroup:AddButton({
    Text     = "Sell Now",
    Func     = function()
        pcall(function() Event:FireServer(SELL_ALL_PACKET) end)
        Library:Notify({ Title = "Auto Sell", Description = "Sold once", Time = 2 })
    end,
    Tooltip  = "Sell all items one time, right now",
})

AutoSellGroup:AddToggle("AutoSell", {
    Text     = "Auto Sell",
    Default  = false,
    Tooltip  = "Automatically sell all items at the set interval",
    Callback = function(v)
        autoSellEnabled = v
        if v then
            if not autoSellThread or coroutine.status(autoSellThread) == "dead" then
                autoSellThread = task.spawn(AutoSellLoop)
            end
            Library:Notify({ Title = "Auto Sell", Description = "Started", Time = 2 })
        else
            Library:Notify({ Title = "Auto Sell", Description = "Stopped", Time = 2 })
        end
    end,
})

AutoSellGroup:AddSlider("SellInterval", {
    Text     = "Sell Interval (s)",
    Default  = 5,
    Min      = 5,
    Max      = 20,
    Rounding = 0,
    Tooltip  = "Time between each auto sell",
    Callback = function(v) sellInterval = v end,
})

-- ── Auto Buy Seeds ─────────────────────────────────────────────────────────
local AutoBuySeedGroup = Tabs.Shop:AddLeftGroupbox("Auto Buy Seeds", "sprout")

-- Helper: read stock from ReplicatedStorage.StockValues
local function stockFolder(shop)
    local sv = ReplicatedStorage:FindFirstChild("StockValues")
    local sh = sv and sv:FindFirstChild(shop)
    return sh and sh:FindFirstChild("Items")
end

local function listItems(shop)
    local out = {}
    local f = stockFolder(shop)
    if f then
        for _, v in ipairs(f:GetChildren()) do
            if v:IsA("ValueBase") then table.insert(out, v.Name) end
        end
        table.sort(out)
    end
    return out
end

local seedNames = listItems("SeedShop")
if #seedNames == 0 then seedNames = { "— shop empty —" } end
local seedSelected    = {}
local autoBuySeed     = false
local autoBuySeedThread = nil
local seedBuyDropdown = nil

for _, n in ipairs(seedNames) do seedSelected[n] = false end

local function AutoBuySeedLoop()
    while autoBuySeed do
        local f = stockFolder("SeedShop")
        if f and Net then
            for _, v in ipairs(f:GetChildren()) do
                if not autoBuySeed then break end
                if v:IsA("ValueBase") and v.Value > 0 and seedSelected[v.Name] then
                    local n = math.min(v.Value, 50)
                    for _ = 1, n do
                        if not autoBuySeed then break end
                        pcall(function() Net.SeedShop.PurchaseSeed:Fire(v.Name) end)
                        task.wait(0.06)
                    end
                end
            end
        end
        task.wait(1.5)
    end
end

AutoBuySeedGroup:AddToggle("AutoBuySeed", {
    Text     = "Auto Buy Seeds",
    Default  = false,
    Tooltip  = "Automatically purchase selected seeds when in stock",
    Callback = function(v)
        autoBuySeed = v
        if v then
            if not autoBuySeedThread or coroutine.status(autoBuySeedThread) == "dead" then
                autoBuySeedThread = task.spawn(AutoBuySeedLoop)
            end
            Library:Notify({ Title = "Auto Buy", Description = "Seed buying started", Time = 2 })
        else
            Library:Notify({ Title = "Auto Buy", Description = "Seed buying stopped", Time = 2 })
        end
    end,
})

seedBuyDropdown = AutoBuySeedGroup:AddDropdown("SeedBuySelect", {
    Values   = seedNames,
    Default  = nil,
    Text     = "Seeds to Buy",
    Multi    = true,
    Tooltip  = "Select seeds to auto-purchase",
    Callback = function(v)
        -- reset all false first
        for k in pairs(seedSelected) do seedSelected[k] = false end
        if type(v) == "table" then
            for k2, state in pairs(v) do
                if type(k2) == "string" and state == true then seedSelected[k2] = true
                elseif type(k2) == "number" and type(state) == "string" then seedSelected[state] = true end
            end
        elseif type(v) == "string" then
            seedSelected[v] = true
        end
    end,
})

AutoBuySeedGroup:AddButton({
    Text    = "Refresh Seed List",
    Func    = function()
        local names = listItems("SeedShop")
        if #names == 0 then names = { "— shop empty —" } end
        seedBuyDropdown:SetValues(names)
        Library:Notify({ Title = "Auto Buy", Description = "Seed list refreshed", Time = 2 })
    end,
    Tooltip = "Reload available seeds from the shop stock",
})

-- ── Auto Buy Gears ─────────────────────────────────────────────────────────
local AutoBuyGearGroup = Tabs.Shop:AddRightGroupbox("Auto Buy Gears", "wrench")

local gearNames = listItems("GearShop")
if #gearNames == 0 then gearNames = { "— shop empty —" } end
local gearSelected    = {}
local autoBuyGear     = false
local autoBuyGearThread = nil
local gearBuyDropdown = nil

for _, n in ipairs(gearNames) do gearSelected[n] = false end

local function AutoBuyGearLoop()
    while autoBuyGear do
        local f = stockFolder("GearShop")
        if f and Net then
            for _, v in ipairs(f:GetChildren()) do
                if not autoBuyGear then break end
                if v:IsA("ValueBase") and v.Value > 0 and gearSelected[v.Name] then
                    local n = math.min(v.Value, 50)
                    for _ = 1, n do
                        if not autoBuyGear then break end
                        pcall(function() Net.GearShop.PurchaseGear:Fire(v.Name) end)
                        task.wait(0.06)
                    end
                end
            end
        end
        task.wait(1.5)
    end
end

AutoBuyGearGroup:AddToggle("AutoBuyGear", {
    Text     = "Auto Buy Gears",
    Default  = false,
    Tooltip  = "Automatically purchase selected gears when in stock",
    Callback = function(v)
        autoBuyGear = v
        if v then
            if not autoBuyGearThread or coroutine.status(autoBuyGearThread) == "dead" then
                autoBuyGearThread = task.spawn(AutoBuyGearLoop)
            end
            Library:Notify({ Title = "Auto Buy", Description = "Gear buying started", Time = 2 })
        else
            Library:Notify({ Title = "Auto Buy", Description = "Gear buying stopped", Time = 2 })
        end
    end,
})

gearBuyDropdown = AutoBuyGearGroup:AddDropdown("GearBuySelect", {
    Values   = gearNames,
    Default  = nil,
    Text     = "Gears to Buy",
    Multi    = true,
    Tooltip  = "Select gears to auto-purchase",
    Callback = function(v)
        for k in pairs(gearSelected) do gearSelected[k] = false end
        if type(v) == "table" then
            for k2, state in pairs(v) do
                if type(k2) == "string" and state == true then gearSelected[k2] = true
                elseif type(k2) == "number" and type(state) == "string" then gearSelected[state] = true end
            end
        elseif type(v) == "string" then
            gearSelected[v] = true
        end
    end,
})

AutoBuyGearGroup:AddButton({
    Text    = "Refresh Gear List",
    Func    = function()
        local names = listItems("GearShop")
        if #names == 0 then names = { "— shop empty —" } end
        gearBuyDropdown:SetValues(names)
        Library:Notify({ Title = "Auto Buy", Description = "Gear list refreshed", Time = 2 })
    end,
    Tooltip = "Reload available gears from the shop stock",
})

----------------------------------------------------------------
-- EVENT TAB
----------------------------------------------------------------

local SeedGroup = Tabs.Event:AddLeftGroupbox("Seed Collection", "sprout")
local ItemGroup = Tabs.Event:AddRightGroupbox("Item Collection", "package")

-- ── Auto Collect Seed ──────────────────────────────────────────────────────
local autoSeedEnabled    = false
local seedTimer          = 0
local seedBeingCollected = {}   -- [seed] = true, guards against double-spawning the same seed

local function TeleportToSeed(seed)
    if seedBeingCollected[seed] then return end
    seedBeingCollected[seed] = true

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then seedBeingCollected[seed] = nil return end

    local target = seed:IsA("BasePart") and seed or seed:FindFirstChildWhichIsA("BasePart", true)
    if not target then seedBeingCollected[seed] = nil return end

    hrp.CFrame = target.CFrame

    hrp.Anchored = true

    while autoSeedEnabled and seed.Parent do
        firePP(seed)
        task.wait(_G.CollectSeedInterval)
    end

    hrp.Anchored = false
    seedBeingCollected[seed] = nil
end

local SeedFolder = workspace:WaitForChild("Map"):WaitForChild("SeedPackSpawnServerLocations")

SeedGroup:AddToggle("AutoCollectSeed", {
    Text     = "Auto Collect Seed",
    Default  = false,
    Tooltip  = "Teleport to and freeze on seeds, firing the prompt until each seed is collected",
    Callback = function(v) autoSeedEnabled = v end
})

local seedScanInterval = 0.2

SeedGroup:AddSlider("SeedScanInterval", {
    Text     = "Scan Interval (s)",
    Default  = 0.2,
    Min      = 0.1,
    Max      = 0.5,
    Rounding = 1,
    Tooltip  = "How often to scan for newly spawned seeds",
    Callback = function(v) seedScanInterval = v end,
})

-- Throttled loop: scan every seedScanInterval seconds instead of every frame
RunService.Heartbeat:Connect(function(dt)
    if not autoSeedEnabled then return end
    seedTimer += dt
    if seedTimer < seedScanInterval then return end
    seedTimer = 0
    for _, seed in ipairs(SeedFolder:GetChildren()) do
        task.spawn(TeleportToSeed, seed)
    end
end)

SeedFolder.ChildAdded:Connect(function(seed)
    if not autoSeedEnabled then return end
    task.spawn(TeleportToSeed, seed)
end)

-- ── Auto Collect Item ──────────────────────────────────────────────────────
local autoItemEnabled = false
local itemTimer       = 0

local DroppedItemsFolder = workspace:WaitForChild("DroppedItems")

local function CollectDroppedItem(item)
    if item and item.Parent then firePP(item) end
end

ItemGroup:AddToggle("AutoCollectItem", {
    Text     = "Auto Collect Item",
    Default  = false,
    Tooltip  = "Fire the pickup prompt on items in workspace.DroppedItems",
    Callback = function(v)
        autoItemEnabled = v
        if v then
            for _, item in ipairs(DroppedItemsFolder:GetChildren()) do
                CollectDroppedItem(item)
            end
        end
    end
})

local itemScanInterval = 0.3

ItemGroup:AddSlider("ItemScanInterval", {
    Text     = "Scan Interval (s)",
    Default  = 0.3,
    Min      = 0.1,
    Max      = 0.5,
    Rounding = 1,
    Tooltip  = "How often to scan for newly dropped items",
    Callback = function(v) itemScanInterval = v end,
})

-- Throttled loop: scan every itemScanInterval seconds
RunService.Heartbeat:Connect(function(dt)
    if not autoItemEnabled then return end
    itemTimer += dt
    if itemTimer < itemScanInterval then return end
    itemTimer = 0
    for _, item in ipairs(DroppedItemsFolder:GetChildren()) do
        CollectDroppedItem(item)
    end
end)

DroppedItemsFolder.ChildAdded:Connect(function(item)
    if not autoItemEnabled then return end
    CollectDroppedItem(item)
end)

local function _setupPlayerAndSettings()
----------------------------------------------------------------
-- PLAYER TAB
----------------------------------------------------------------

local PlayerGroup    = Tabs.Player:AddLeftGroupbox("Character",   "user")
local PlayerESPGroup = Tabs.Player:AddRightGroupbox("Player ESP", "users")

local loopWalkSpeed    = false
local loopJumpPower    = false
local currentWalkSpeed = 16
local currentJumpPower = 50
local antiAfk          = true
local antiAfkConnection = nil

local function ApplyWalkSpeed()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = currentWalkSpeed end
end

local function ApplyJumpPower()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true hum.JumpPower = currentJumpPower end
end

local function startAntiAfk()
    if antiAfkConnection then return end
    antiAfkConnection = LocalPlayer.Idled:Connect(function()
        while antiAfk do
            VirtualUser:CaptureController()
            VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
        end
        antiAfkConnection = nil
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    if loopWalkSpeed then hum.WalkSpeed = currentWalkSpeed end
    if loopJumpPower then hum.UseJumpPower = true hum.JumpPower = currentJumpPower end
end)

local loopTimer = 0
RunService.Heartbeat:Connect(function(dt)
    loopTimer += dt
    if loopTimer < 0.2 then return end
    loopTimer = 0
    if loopWalkSpeed then ApplyWalkSpeed() end
    if loopJumpPower  then ApplyJumpPower()  end
end)

PlayerGroup:AddSlider("WalkSpeed", {
    Text = "WalkSpeed", Default = 16, Min = 16, Max = 200, Rounding = 0,
    Callback = function(v) currentWalkSpeed = v ApplyWalkSpeed() end
})
PlayerGroup:AddToggle("LoopWalkSpeed", {
    Text = "Loop WalkSpeed", Default = false,
    Tooltip = "Keep WalkSpeed applied every 0.2s and on respawn",
    Callback = function(v) loopWalkSpeed = v if v then ApplyWalkSpeed() end end
})
PlayerGroup:AddSlider("JumpPower", {
    Text = "JumpPower", Default = 50, Min = 50, Max = 300, Rounding = 0,
    Callback = function(v) currentJumpPower = v ApplyJumpPower() end
})
PlayerGroup:AddToggle("LoopJumpPower", {
    Text = "Loop JumpPower", Default = false,
    Tooltip = "Keep JumpPower applied every 0.2s and on respawn",
    Callback = function(v) loopJumpPower = v if v then ApplyJumpPower() end end
})
PlayerGroup:AddToggle("AntiAfk", {
    Text = "Anti AFK", Default = true, Tooltip = "Prevent AFK kick",
    Callback = function(v)
        antiAfk = v
        if v then startAntiAfk() else antiAfkConnection = nil end
    end
})

-- ── Player ESP ────────────────────────────────────────────────────────────
local playerESPEnabled = false
local PlayerESPObjects = {}
local espDistTimer     = 0

local function GetDistanceStr(player)
    local myHRP    = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local theirHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not getHRP() or not theirHRP then return "? m" end
    return math.floor((getHRP().Position - theirHRP.Position).Magnitude) .. " m"
end

local function CreatePlayerESP(player)
    if player == LocalPlayer then return end
    if PlayerESPObjects[player] and PlayerESPObjects[player].connection then return end

    local function Apply(char)
        local prev = PlayerESPObjects[player]
        if prev then
            if prev.highlight then pcall(function() prev.highlight:Destroy() end) end
            if prev.billboard then pcall(function() prev.billboard:Destroy() end) end
        end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end

        local hl = Instance.new("Highlight")
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor           = Color3.fromRGB(220, 60, 60)
        hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency    = 0.4
        hl.OutlineTransparency = 0
        hl.Adornee             = char
        hl.Parent              = char

        local billboard = Instance.new("BillboardGui")
        billboard.Size        = UDim2.new(0, 160, 0, 56)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.Adornee     = hrp
        billboard.AlwaysOnTop = true
        billboard.Parent      = hrp

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundTransparency = 1
        frame.Parent = billboard

        local function makeLabel(pos, size, color, font, text)
            local l = Instance.new("TextLabel")
            l.Size = size l.Position = pos
            l.BackgroundTransparency = 1
            l.TextColor3 = color
            l.TextStrokeTransparency = 0
            l.TextStrokeColor3 = Color3.fromRGB(0,0,0)
            l.Font = font l.TextScaled = true l.Text = text
            l.Parent = frame
            return l
        end

        makeLabel(UDim2.new(0,0,0,0),       UDim2.new(1,0,0.42,0), Color3.fromRGB(255,255,80),  Enum.Font.GothamBold, player.DisplayName)
        makeLabel(UDim2.new(0,0,0.42,0),    UDim2.new(1,0,0.33,0), Color3.fromRGB(200,200,200), Enum.Font.Gotham,     "@"..player.Name)
        local distLabel =
        makeLabel(UDim2.new(0,0,0.75,0),    UDim2.new(1,0,0.25,0), Color3.fromRGB(120,210,255), Enum.Font.GothamBold, GetDistanceStr(player))

        local conn = PlayerESPObjects[player] and PlayerESPObjects[player].connection
        PlayerESPObjects[player] = { highlight = hl, billboard = billboard, distLabel = distLabel, connection = conn }
    end

    if player.Character then task.spawn(Apply, player.Character) end

    local conn = player.CharacterAdded:Connect(function(char) task.spawn(Apply, char) end)
    if PlayerESPObjects[player] then
        PlayerESPObjects[player].connection = conn
    else
        PlayerESPObjects[player] = { connection = conn }
    end
end

local function RemovePlayerESP(player)
    local data = PlayerESPObjects[player]
    if not data then return end
    if data.highlight  then pcall(function() data.highlight:Destroy()  end) end
    if data.billboard  then pcall(function() data.billboard:Destroy()  end) end
    if data.connection then data.connection:Disconnect() end
    PlayerESPObjects[player] = nil
end

-- Distance update: throttled 0.15s
RunService.Heartbeat:Connect(function(dt)
    if not playerESPEnabled then return end
    espDistTimer += dt
    if espDistTimer < 0.15 then return end
    espDistTimer = 0
    for player, data in pairs(PlayerESPObjects) do
        if data.distLabel then
            pcall(function() data.distLabel.Text = GetDistanceStr(player) end)
        end
    end
end)

PlayerESPGroup:AddToggle("PlayerESP", {
    Text     = "Player ESP",
    Default  = false,
    Tooltip  = "Show highlight + display name / username / distance above all players",
    Callback = function(v)
        playerESPEnabled = v
        if v then
            for _, player in ipairs(Players:GetPlayers()) do CreatePlayerESP(player) end
        else
            for player in pairs(PlayerESPObjects) do RemovePlayerESP(player) end
        end
    end,
})

Players.PlayerAdded:Connect(function(player)
    if playerESPEnabled then CreatePlayerESP(player) end
end)
Players.PlayerRemoving:Connect(function(player)
    RemovePlayerESP(player)
end)

-- ── Lighting ──────────────────────────────────────────────────────────────
local LightGroup = Tabs.Player:AddRightGroupbox("Lighting", "sun")

local originalFogEnd               = Lighting.FogEnd
local originalFogStart             = Lighting.FogStart
local originalGlobalShadows        = Lighting.GlobalShadows
local originalExposureCompensation = Lighting.ExposureCompensation

LightGroup:AddToggle("GlobalShadows", {
    Text = "Global Shadows", Default = true, Tooltip = "Toggle global shadows",
    Callback = function(v) Lighting.GlobalShadows = v end
})
LightGroup:AddToggle("FogEnabled", {
    Text = "Fog", Default = true, Tooltip = "Toggle atmospheric fog",
    Callback = function(v)
        if v then Lighting.FogEnd = originalFogEnd Lighting.FogStart = originalFogStart
        else Lighting.FogEnd = 1e9 Lighting.FogStart = 1e9 end
    end
})
LightGroup:AddSlider("ExposureComp", {
    Text = "Exposure", Default = 0, Min = -5, Max = 5, Rounding = 1,
    Tooltip = "Adjust ExposureCompensation (0 = original)",
    Callback = function(v) Lighting.ExposureCompensation = v end
})
LightGroup:AddButton({
    Text = "Reset Lighting",
    Func = function()
        Lighting.FogEnd = originalFogEnd Lighting.FogStart = originalFogStart
        Lighting.GlobalShadows = originalGlobalShadows
        Lighting.ExposureCompensation = originalExposureCompensation
        Library:Notify({ Title = "Lighting", Description = "Restored to original", Time = 2 })
    end,
    Tooltip = "Restore all lighting values to original"
})

----------------------------------------------------------------
-- SETTINGS TAB
----------------------------------------------------------------

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor", Default = true,
    Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side",
    Callback = function(v) Library:SetNotifySide(v) end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "LeftControl", NoUI = true, Text = "Menu keybind",
})
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("GardenRobot2")
SaveManager:SetFolder("GardenRobot2")

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

----------------------------------------------------------------
-- ACTIVE PHASE NOTIFICATION
----------------------------------------------------------------

local lastPhase = workspace:GetAttribute("ActivePhase")

workspace:GetAttributeChangedSignal("ActivePhase"):Connect(function()
    local phase = workspace:GetAttribute("ActivePhase")
    if phase ~= lastPhase then
        lastPhase = phase
        Library:Notify({
            Title       = "Phase Changed",
            Description = "Current Phase: " .. tostring(phase) .. "!",
            Time        = 5,
        })
    end
end)
end
_setupPlayerAndSettings()