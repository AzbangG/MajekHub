-- Steal An Egg Hub | Rayfield Gen2

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- === ANTI-CHEAT SAFE HELPERS (Impact + ObbyAntiTP) ===
local function isObbyArmed()
    if Workspace:GetAttribute("ClientObbyAntiTp") == false then return false end
    if Workspace:GetAttribute("AnticheatSuspendedRegion") ~= nil then return true end
    return Workspace:FindFirstChild("MonsterEventMap") ~= nil
end
local function getSafeWalkSpeed()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then return math.clamp(hum.WalkSpeed, 16, 24) end
    return 16
end
local function safeStepDelay(dist, speed)
    local safeSpeed = math.min(speed, getSafeWalkSpeed()*1.6 + 12)
    return math.clamp(dist / math.max(safeSpeed, 14), 0.08, 1.2)
end

local EggState = require(ReplicatedStorage.Client.EggState)
local PlotState = require(ReplicatedStorage.Client.PlotState)
local Assets = require(ReplicatedStorage.Data.Assets)
local AreaEggSlotIdentity = require(ReplicatedStorage.Shared.Util.AreaEggSlotIdentity)
local EggPlacementRaycast = require(ReplicatedStorage.Shared.Eggs.EggPlacementRaycast)
local EggToolDisplay = require(ReplicatedStorage.Shared.Eggs.EggToolDisplay)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

if STATE.window then
	pcall(function()
		STATE.window:Unload()
	end)
	STATE.window = nil
end

local cfg = STATE.cfg
if not cfg then
	cfg = {
		autoFarm = false,
		autoPlace = true,
		autoHatch = false,
		autoTreadmill = false,
		antiAfk = false,
		infJump = false,
		noclipFarm = false,
		eggEsp = false,
		prioritizeRare = true,
		skipFirstArea = false,
		mutationOnly = false,
		parasiteOnly = false,
		tweenSpeed = 32,
		loopWait = 0.9,
		walkSpeed = 16, -- LOCK 16, >22 flag Impact:93 + PushBack:15
		rarityFilter = "All",
		areaFilter = "All",
		minRarity = "Common",
	}
	STATE.cfg = cfg
end

if STATE.stolen == nil then
	STATE.stolen = 0
end

local RARITY_RANK = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Cosmic = 7,
	Secret = 8,
	Eternal = 9,
	Divine = 10,
}

local RARITY_OPTIONS = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
local AREA_OPTIONS = { "All", "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Cherry Blossom", "Prehistoric", "Abyss Ocean", "Cosmic", "Titan Temple" }
local MIN_RARITY_OPTIONS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }

local carrying = false
local carryUid = nil
local tweenToken = 0
local farmBusy = false
local espFolder = nil

local function dropdownValue(v, fallback)
	if type(v) == "table" then
		return v[1] or fallback
	end
	if type(v) == "string" then
		return v
	end
	return fallback
end

local function notify(title, content, duration)
	if STATE.window then
		pcall(function()
			STATE.window:Notify({
				title = title,
				content = content,
				duration = duration or 3,
			})
		end)
	else
		print("[" .. title .. "] " .. tostring(content))
	end
end

local function hrp()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function humanoid()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function isTrapped()
	local char = LocalPlayer.Character
	return char ~= nil and char:GetAttribute("IsTrapped") == true
end

local function rarityOf(category)
	local spec = Assets.Directory[category]
	local rar = spec and spec.Rarity
	local name = (rar and (rar.DisplayName or rar._id)) or "Unknown"
	local rank = RARITY_RANK[name] or 0
	local color = (rar and rar.Color) or Color3.fromRGB(200, 200, 200)
	return name, rank, color
end

local function currentToolUid()
	local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }
	for _, container in ipairs(containers) do
		if container then
			for _, inst in ipairs(container:GetChildren()) do
				if inst:IsA("Tool") then
					local ok, uid = pcall(EggToolDisplay.GetToolUid, inst)
					if ok and type(uid) == "string" then
						return uid
					end
				end
			end
		end
	end
	return carryUid
end

local function setNoclip(on)
	local char = LocalPlayer.Character
	if not char then
		return
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not on
		end
	end
end

local function tweenTo(worldPos)
    local root = hrp()
    local char = LocalPlayer.Character
    local hum = humanoid()
    if not root or not char or not hum then return false end
    if isTrapped() then return false end
    tweenToken += 1
    local my = tweenToken
    local goal = worldPos + Vector3.new(0, 4, 0)
    local distTotal = (root.Position - goal).Magnitude
    local armed = isObbyArmed()
    if distTotal < 12 then
        local t = math.clamp(distTotal / math.max(cfg.tweenSpeed, 14), 0.12, 0.8)
        local wasAnchored = root.Anchored
        root.Anchored = true
        local tw = TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(goal)})
        tw:Play()
        local done=false; local c=tw.Completed:Connect(function() done=true end)
        local deadline=os.clock()+t+0.5
        while STATE.alive() and my==tweenToken and not done and os.clock()<deadline do task.wait() end
        c:Disconnect(); tw:Cancel()
        if root.Parent then root.Anchored = wasAnchored end
        return my==tweenToken and (root.Position-goal).Magnitude < 12
    end
    local waypoints = {}
    if not armed and distTotal < 400 then
        local ok, path = pcall(function() return PathfindingService:CreatePath({AgentRadius=2, AgentCanJump=true}) end)
        if ok and path then
            pcall(function() path:ComputeAsync(root.Position, goal) end)
            if path.Status == Enum.PathStatus.Success then
                for _, wp in ipairs(path:GetWaypoints()) do table.insert(waypoints, wp.Position + Vector3.new(0,2,0)) end
            end
        end
    end
    if #waypoints == 0 then
        local steps = math.ceil(distTotal/24)
        for i=1, steps do
            local alpha = i/steps
            local jitter = Vector3.new(math.random(-2,2),0,math.random(-2,2))
            table.insert(waypoints, root.Position:Lerp(goal, alpha)+jitter)
        end
    end
    if (waypoints[#waypoints]-goal).Magnitude > 4 then table.insert(waypoints, goal) end
    local useNoclip = cfg.noclipFarm == true
    local colState = {}
    if useNoclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then colState[part]=part.CanCollide; part.CanCollide=false end
        end
    end
    hum.AutoRotate = true
    local lastPos = root.Position
    for _, wp in ipairs(waypoints) do
        if not STATE.alive() or my ~= tweenToken or not root.Parent then break end
        if hum.Health <=0 then break end
        if hum.Sit or hum.PlatformStand then task.wait(0.6) end
        local d = (root.Position - wp).Magnitude
        local delay = safeStepDelay(d, cfg.tweenSpeed)
        hum:MoveTo(wp)
        local t0=os.clock()
        repeat task.wait(0.05) until not STATE.alive() or my~=tweenToken or (root.Position-wp).Magnitude < 7 or os.clock()-t0 > delay+0.9 or hum.Health<=0
        if (root.Position-wp).Magnitude >= 7 and (root.Position-lastPos).Magnitude < 2 then
            local step = (wp - root.Position)
            if step.Magnitude > 10 then step = step.Unit*10 end
            pcall(function() root.AssemblyLinearVelocity = step.Unit * math.min(cfg.tweenSpeed*0.6, getSafeWalkSpeed()*1.5) end)
            task.wait(0.12)
        end
        lastPos = root.Position
        task.wait(math.random(80,150)/1000)
        if isObbyArmed() then task.wait(0.25) end
    end
    if useNoclip then
        for part, was in pairs(colState) do if part and part.Parent then part.CanCollide = was end end
    end
    return my==tweenToken and root.Parent~=nil and hum.Health>0 and (root.Position-goal).Magnitude < 14
end

local function goHome()
	local plot = PlotState.ResolvePlot()
	if not plot or not plot.PetArea then
		return false
	end
	return tweenTo(plot.PetArea.Position)
end

local function plantHere(uid)
	local plot = PlotState.ResolvePlot()
	if not plot or not plot.CenterPoint or not plot.PetArea then
		return false, "plot missing"
	end
	local worldPos = plot.PetArea.Position + Vector3.new(math.random(-6, 6), 1.5, math.random(-6, 6))
	local hit = EggPlacementRaycast.Raycast(plot.PetArea, LocalPlayer.UserId)
	if hit and hit.Position then
		worldPos = hit.Position
	end
	local localCf = plot.CenterPoint.CFrame:ToObjectSpace(CFrame.new(worldPos))
	return EggState.PlantEgg(uid, localCf)
end

local function passesFilter(rec)
	if rec.State == "Carried" or rec.State == "Claimed" or rec.State == "GuardCarried" then
		return false
	end
	if cfg.skipFirstArea and AreaEggSlotIdentity.LooksLikeFirstAreaUid(rec.Uid) then
		return false
	end
	if cfg.areaFilter ~= "All" and rec.AreaId ~= cfg.areaFilter then
		return false
	end
	local name, rank = rarityOf(rec.AssetCategory)
	if cfg.rarityFilter ~= "All" and name ~= cfg.rarityFilter then
		return false
	end
	local minRank = RARITY_RANK[cfg.minRarity] or 1
	if rank < minRank then
		return false
	end
	if cfg.mutationOnly and rec.BaseMutation == nil then
		return false
	end
	if cfg.parasiteOnly and rec.HasParasite ~= true then
		return false
	end
	return true
end

local function pickEgg()
	local snap = EggState.ReadFieldEggs()
	local records = snap and snap.Records
	if type(records) ~= "table" or #records == 0 then
		pcall(function()
			EggState.SyncFieldEggs()
		end)
		snap = EggState.ReadFieldEggs()
		records = (snap and snap.Records) or {}
	end
	local root = hrp()
	local origin = root and root.Position or Vector3.zero
	local best, bestScore = nil, -1e9
	for _, rec in ipairs(records) do
		if passesFilter(rec) then
			local _, rank = rarityOf(rec.AssetCategory)
			local pos = rec.BottomCFrame.Position
			local dist = (pos - origin).Magnitude
			local score
			if cfg.prioritizeRare then
				score = rank * 5000 - dist
			else
				score = -dist + rank
			end
			if rec.HasParasite then
				score += 800
			end
			if rec.BaseMutation then
				score += 400
			end
			if rec.State == "Dropped" then
				score += 250
			end
			if score > bestScore then
				bestScore = score
				best = rec
			end
		end
	end
	return best
end

local function stealEgg(rec)
	local slotKey = nil
	if AreaEggSlotIdentity.LooksLikeFirstAreaUid(rec.Uid) then
		slotKey = AreaEggSlotIdentity.SlotKey(rec.AreaId, rec.NestId)
	end
	return EggState.CarryFieldEgg(rec.Uid, slotKey)
end

local function farmOnce()
	if farmBusy or not STATE.alive() then
		return
	end
	farmBusy = true
	local ok, err = pcall(function()
		if isTrapped() then
			task.wait(1)
			return
		end
		local uid = currentToolUid()
		if carrying or uid then
			if cfg.autoPlace then
				goHome()
				local plantUid = uid or carryUid
				if plantUid then
					local placed, why = plantHere(plantUid)
					if placed then
						STATE.stolen += 1
						notify("Placed", "Egg planted at base (" .. STATE.stolen .. ")", 2)
					else
						notify("Place failed", tostring(why), 2)
					end
				end
			end
			return
		end
		local rec = pickEgg()
		if not rec then
			task.wait(1)
			return
		end
		if not tweenTo(rec.BottomCFrame.Position) then
			return
		end
		local stole, why = stealEgg(rec)
		if stole then
			local name = rarityOf(rec.AssetCategory)
			local prefix = rec.BaseMutation and (rec.BaseMutation .. " ") or ""
			notify("Stolen", prefix .. name .. " " .. rec.AssetCategory, 2)
			if cfg.autoPlace then
				task.wait(0.15)
				goHome()
				local plantUid = currentToolUid() or rec.Uid
				local placed, placeWhy = plantHere(plantUid)
				if placed then
					STATE.stolen += 1
				else
					notify("Place failed", tostring(placeWhy), 2)
				end
			end
		elseif why and why ~= "" then
			warn("[Steal] " .. tostring(why))
		end
	end)
	farmBusy = false
	if not ok then
		warn("[Farm] " .. tostring(err))
	end
end

local function hatchReady()
	local rows = EggState.ReadOwnerEggs(LocalPlayer.UserId)
	for uid in pairs(rows) do
		if EggState.IsReadyToHatch(uid) then
			local ok1 = EggState.BeginHatch(uid)
			if ok1 then
				task.wait(0.35)
				EggState.FinishHatch(uid)
			end
		end
	end
end

local function treadmillTick()
	local plot = PlotState.ResolvePlot()
	local folder = plot and plot.PlotFolder
	local belt = folder and folder:FindFirstChild("TreadmillBottom", true)
	if belt and belt:IsA("BasePart") then
		local root = hrp()
		if root and (root.Position - belt.Position).Magnitude > 10 then
			tweenTo(belt.Position + Vector3.new(0,3,0))
			task.wait(0.6)
		end
		pcall(function() Remotes.Treadmill.AskWearStill:InvokeServer() end)
	end
end

local function clearEsp()
	if espFolder then
		espFolder:Destroy()
		espFolder = nil
	end
end

local function refreshEsp()
	clearEsp()
	if not cfg.eggEsp then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SAE_ESP"
	folder.Parent = Workspace
	espFolder = folder
	local snap = EggState.ReadFieldEggs()
	for _, rec in ipairs((snap and snap.Records) or {}) do
		if rec.State == "Slot" or rec.State == "Dropped" then
			local name, _, color = rarityOf(rec.AssetCategory)
			local part = Instance.new("Part")
			part.Name = rec.Uid
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.Transparency = 1
			part.Size = Vector3.new(1, 1, 1)
			part.CFrame = rec.BoundsCFrame
			part.Parent = folder
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(160, 42)
			gui.AlwaysOnTop = true
			gui.StudsOffset = Vector3.new(0, 3, 0)
			gui.Parent = part
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.TextColor3 = color
			local mut = rec.BaseMutation and (rec.BaseMutation .. " ") or ""
			label.Text = mut .. name .. "\n" .. rec.AssetCategory
			label.Parent = gui
		end
	end
end

STATE.connect(EggState.CarryChanged, function(st)
	carrying = st and st.IsCarrying == true
	carryUid = st and st.Uid or nil
end)

STATE.connect(LocalPlayer.Idled, function()
	if not cfg.antiAfk then
		return
	end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

STATE.connect(UserInputService.JumpRequest, function()
	if not cfg.infJump then return end
	if isObbyArmed() then return end -- vertical Impact:139 flag
	local hum = humanoid()
	if hum and hum.FloorMaterial ~= Enum.Material.Air then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

local function applyWalkSpeed()
	if cfg.walkSpeed ~= 16 then
		warn("[AntiCheat] WalkSpeed "..tostring(cfg.walkSpeed).." diblokir, reset 16 - pakai AutoTreadmill")
		cfg.walkSpeed = 16
	end
end

STATE.connect(LocalPlayer.CharacterAdded, function()
	task.wait(0.4)
	applyWalkSpeed()
end)

task.spawn(function()
	while STATE.alive() do
		if cfg.autoFarm then
			farmOnce()
		end
		task.wait(cfg.loopWait)
	end
end)

task.spawn(function()
	while STATE.alive() do
		if cfg.autoHatch then
			pcall(hatchReady)
		end
		if cfg.autoTreadmill then
			pcall(treadmillTick)
		end
		task.wait(8)
	end
end)

task.spawn(function()
	while STATE.alive() do
		if cfg.eggEsp then
			pcall(refreshEsp)
		end
		task.wait(2.5)
	end
end)

-- Don't InvokeServer snapshot on load: client already has field/owned state.
-- Extra sync right after inject looks like a probe and is unnecessary.

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local window = Rayfield:CreateWindow({
	name = "Steal An Egg",
	subtitle = "Azbang Hub · Rayfield Gen2",
	theme = "amethyst",
	configuration = {
		autoSave = true,
		autoLoad = true,
		fileName = "StealAnEggHub",
	},
})
STATE.window = window

STATE.onCleanup(function()
	tweenToken += 1
	cfg.autoFarm = false
	clearEsp()
	setNoclip(false)
	pcall(function()
		window:Unload()
	end)
	STATE.window = nil
end)

local Farm = window:CreateTab({ name = "Farm", icon = 93364949241311 })
local Filter = window:CreateTab({ name = "Filter", icon = 6031280882 })
local Misc = window:CreateTab({ name = "Misc", icon = 6031280882 })
local Visual = window:CreateTab({ name = "Visual", icon = 6031280882 })

Farm:CreateSection({ name = "Auto Farm" })
Farm:CreateToggle({
	name = "Auto Farm Egg",
	description = "Tween ke egg, steal, lalu pulang ke plot.",
	value = cfg.autoFarm,
	flag = "AutoFarmEgg",
	callback = function(v)
		cfg.autoFarm = v
		if v then
			notify("Farm", "Auto farm started", 2)
		end
	end,
})
Farm:CreateToggle({
	name = "Auto Place at Base",
	description = "Setelah steal, plant egg di PetArea plot kamu.",
	value = cfg.autoPlace,
	flag = "AutoPlace",
	callback = function(v)
		cfg.autoPlace = v
	end,
})
Farm:CreateToggle({
	name = "Prioritize Highest Rarity",
	description = "Ambil egg paling langka dulu, bukan yang terdekat.",
	value = cfg.prioritizeRare,
	flag = "PrioRare",
	callback = function(v)
		cfg.prioritizeRare = v
	end,
})
Farm:CreateToggle({
	name = "Noclip saat Tween",
	description = "Hanya CanCollide=false stepwise, bukan bypass Obby.",
	value = cfg.noclipFarm,
	flag = "NoclipFarm",
	callback = function(v)
		cfg.noclipFarm = v
	end,
})
Farm:CreateSlider({
	name = "Tween Speed",
	description = "MAX 45 aman (Impact:93). >50 = flag HardTeleport.",
	range = { 14, 45 },
	increment = 5,
	value = cfg.tweenSpeed,
	suffix = " studs/s",
	flag = "TweenSpeed",
	callback = function(v)
		cfg.tweenSpeed = v
	end,
})
Farm:CreateSlider({
	name = "Loop Delay",
	description = "Jangan <0.7 - spam remote kena rate limit.",
	range = { 0.7, 2 },
	increment = 0.05,
	value = cfg.loopWait,
	suffix = "s",
	flag = "LoopDelay",
	callback = function(v)
		cfg.loopWait = v
	end,
})
Farm:CreateButton({
	name = "Teleport to Base",
	callback = function()
		goHome()
	end,
})
Farm:CreateButton({
	name = "Steal Nearest Once",
	callback = function()
		local rec = pickEgg()
		if not rec then
			notify("Farm", "Tidak ada egg yang lolos filter", 3)
			return
		end
		task.spawn(function()
			tweenTo(rec.BottomCFrame.Position)
			local ok, why = stealEgg(rec)
			notify(ok and "Stolen" or "Denied", ok and rec.AssetCategory or tostring(why), 3)
		end)
	end,
})

Filter:CreateSection({ name = "Egg Filter" })
Filter:CreateDropdown({
	name = "Rarity",
	options = RARITY_OPTIONS,
	value = cfg.rarityFilter,
	flag = "RarityFilter",
	callback = function(v)
		cfg.rarityFilter = dropdownValue(v, "All")
	end,
})
Filter:CreateDropdown({
	name = "Minimum Rarity",
	description = "Abaikan egg di bawah rarity ini.",
	options = MIN_RARITY_OPTIONS,
	value = cfg.minRarity,
	flag = "MinRarity",
	callback = function(v)
		cfg.minRarity = dropdownValue(v, "Common")
	end,
})
Filter:CreateDropdown({
	name = "Area",
	options = AREA_OPTIONS,
	value = cfg.areaFilter,
	flag = "AreaFilter",
	callback = function(v)
		cfg.areaFilter = dropdownValue(v, "All")
	end,
})
Filter:CreateToggle({
	name = "Mutation Only",
	description = "Hanya Golden / Silver / Rainbow / dll.",
	value = cfg.mutationOnly,
	flag = "MutOnly",
	callback = function(v)
		cfg.mutationOnly = v
	end,
})
Filter:CreateToggle({
	name = "Parasite Only",
	value = cfg.parasiteOnly,
	flag = "ParaOnly",
	callback = function(v)
		cfg.parasiteOnly = v
	end,
})
Filter:CreateToggle({
	name = "Skip First-Area Eggs",
	description = "Lewati nest tutorial Forest.",
	value = cfg.skipFirstArea,
	flag = "SkipFirst",
	callback = function(v)
		cfg.skipFirstArea = v
	end,
})
Filter:CreateButton({
	name = "Refresh Egg Snapshot",
	callback = function()
		local snap = EggState.SyncFieldEggs()
		local n = snap and snap.Records and #snap.Records or 0
		notify("Snapshot", tostring(n) .. " field eggs", 3)
	end,
})

Misc:CreateSection({ name = "Utility" })
Misc:CreateToggle({
	name = "Anti AFK",
	description = "Hanya VirtualUser saat Roblox Idled. Jangan loncat (itu yang nendang di treadmill).",
	value = cfg.antiAfk,
		flag = "AntiAfkV2",
	callback = function(v)
		cfg.antiAfk = v
	end,
})
Misc:CreateToggle({
	name = "Auto Hatch",
	description = "Hatch egg di plot yang sudah grown.",
	value = cfg.autoHatch,
	flag = "AutoHatch",
	callback = function(v)
		cfg.autoHatch = v
	end,
})
Misc:CreateToggle({
	name = "Auto Treadmill",
	description = "Tween ke treadmill plot lalu AskWearStill.",
	value = cfg.autoTreadmill,
	flag = "AutoTread",
	callback = function(v)
		cfg.autoTreadmill = v
	end,
})
Misc:CreateToggle({
	name = "Infinite Jump [RISIKO VERTICAL]",
	description = "Auto-disable saat MonsterEventMap aktif (ObbyAntiTP vertical check).",
	value = cfg.infJump,
	flag = "InfJump",
	callback = function(v)
		cfg.infJump = v
	end,
})
Misc:CreateSlider({
	name = "Walk Speed [BLOCKED - AntiCheat]",
	description = "DIKUNCI 16. >22 = Playback flag + PushBack:15. Speed legal via Treadmill.",
	range = { 16, 16 },
	increment = 1,
	value = cfg.walkSpeed,
	flag = "WalkSpeed",
	callback = function(v)
		cfg.walkSpeed = v
		applyWalkSpeed()
	end,
})
Misc:CreateButton({
	name = "Claim Group Perk",
	callback = function()
		local ok, err = pcall(function()
			return Remotes.GroupPerk.RedeemPerk:InvokeServer()
		end)
		notify("Group Perk", ok and "Sent" or tostring(err), 3)
	end,
})
Misc:CreateButton({
	name = "Sell All Pets",
	callback = function()
		pcall(function()
			Remotes.PetSatchel.SellEveryPet:FireServer()
		end)
		pcall(function()
			Remotes.Haul.OfferFullSatchelSale:InvokeServer()
		end)
		notify("Sell", "Sell remotes fired", 3)
	end,
})
Misc:CreateButton({
	name = "Unload Hub",
	callback = function()
		window:Unload()
	end,
})

Visual:CreateSection({ name = "ESP" })
Visual:CreateToggle({
	name = "Egg ESP",
	description = "Billboard rarity + nama pet di setiap field egg.",
	value = cfg.eggEsp,
	flag = "EggESP",
	callback = function(v)
		cfg.eggEsp = v
		if v then
			refreshEsp()
		else
			clearEsp()
		end
	end,
})

window:Notify({
	title = "Steal An Egg Hub",
	content = "Auto farm, filter, tween speed, anti AFK, hatch, treadmill, ESP siap.",
	duration = 6,
})
