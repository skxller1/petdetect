-- sorry for leaking the entire script, too bad 

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
	Title = "Pet Detector",
	SubTitle = "SkillyBetaHub Script",
	TabWidth = 160,
	Size = UDim2.fromOffset(500, 300),
	Acrylic = false,
	Theme = "VSC Dark High Contrast",
	MinimizeKey = Enum.KeyCode.RightControl
})

local Tab = Window:AddTab({ Title = "Main", Icon = "home" })

local replicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

local eggModels = {}
local eggPets = {}
pcall(function()
	local hatchFunc = getupvalue(getupvalue(getconnections(replicatedStorage.GameEvents.PetEggService.OnClientEvent)[1].Function, 1), 2)
	eggModels = getupvalue(hatchFunc, 1) or {}
	eggPets = getupvalue(hatchFunc, 2) or {}
end)

local espEnabled = false
local espCache = {}
local activeEggs = {}
local addedConn, removedConn

local function getObjectFromId(objectId)
	for _, eggModel in pairs(eggModels) do
		if eggModel:GetAttribute("OBJECT_UUID") == objectId then
			return eggModel
		end
	end
end

local function CreateEspGui(object, text)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PetEggDetectorFuck"
	billboard.Adornee = object:FindFirstChildWhichIsA("BasePart") or object.PrimaryPart or object
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Parent = billboard
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold

	billboard.Parent = object
	return billboard
end

local function UpdateEsp(objectId, petName)
	local object = getObjectFromId(objectId)
	if not object or not espCache[objectId] then return end

	local eggName = object:GetAttribute("EggName") or "Unknown"
	local labelGui = espCache[objectId]
	if labelGui and labelGui:FindFirstChildOfClass("TextLabel") then
		labelGui.TextLabel.Text = eggName .. " | " .. (petName or "?")
	end
end

local function AddEsp(object)
	if object:GetAttribute("OWNER") ~= localPlayer.Name then return end
	local eggName = object:GetAttribute("EggName") or "Unknown"
	local petName = eggPets[object:GetAttribute("OBJECT_UUID")]
	local objectId = object:GetAttribute("OBJECT_UUID")
	if not objectId then return end

	local text = eggName .. " | " .. (petName or "?")
	local esp = CreateEspGui(object, text)
	espCache[objectId] = esp
	activeEggs[objectId] = object
end

local function RemoveEsp(object)
	if object:GetAttribute("OWNER") ~= localPlayer.Name then return end
	local objectId = object:GetAttribute("OBJECT_UUID")
	if espCache[objectId] then
		espCache[objectId]:Destroy()
		espCache[objectId] = nil
	end
	activeEggs[objectId] = nil
end

if Tab and Tab.AddToggle then
	Tab:AddToggle("PetEggDetectESP", {
		Title = "Pet Hatch Detector",
		Description = "eggs need to be ready, then server hop until you got the pet you want.",
		Default = false
	}):OnChanged(function(state)
		espEnabled = state

		if espEnabled then
			for _, object in collectionService:GetTagged("PetEggServer") do
				task.spawn(AddEsp, object)
			end

			addedConn = collectionService:GetInstanceAddedSignal("PetEggServer"):Connect(AddEsp)
			removedConn = collectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(RemoveEsp)

			pcall(function()
				local conn = getconnections(replicatedStorage.GameEvents.EggReadyToHatch_RE.OnClientEvent)[1]
				if conn and typeof(conn.Function) == "function" then
					hookfunction(conn.Function, newcclosure(function(objectId, petName)
						UpdateEsp(objectId, petName)
					end))
				end
			end)
		else
			for _, gui in pairs(espCache) do
				gui:Destroy()
			end
			espCache = {}
			activeEggs = {}

			if addedConn then addedConn:Disconnect() addedConn = nil end
			if removedConn then removedConn:Disconnect() removedConn = nil end
		end
	end)
else
	warn("nigger are you using xeno")
end
