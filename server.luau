-- ROPE SWINGING PROJECT FOR SCRIPTER ROLE
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Counter = 0
local StarterPart = workspace:WaitForChild("StartingPart")
local LastPartPosition = Vector3.new(-492, 20, 17)
local Event = ReplicatedStorage.Remotes.SwingEvent
local TimeStore = DataStoreService:GetDataStore("TimeStore")
local Players = game:GetService("Players")
local StartTime = 0
local RemoteFunction = ReplicatedStorage.Remotes.UIFunction

Players.PlayerAdded:Connect(function(Player: Player)
	local Time = TimeStore:GetAsync(Player.UserId)
	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"
	Leaderstats.Parent = Player
	
	local TimeStat = Instance.new("IntValue")
	TimeStat.Name = "Time"
	TimeStat.Value = Time or 0
	TimeStat.Parent = Leaderstats

end)

RemoteFunction.OnServerInvoke = function(Player)
	local TimeStat = Player:WaitForChild("leaderstats").Time
	local Time = TimeStat.Value
	if Time == 0 then
		return 0
	end
	local RoundedTime = math.round(Time)
	return RoundedTime
end

-- Randomize map with semi-random spawns for swinging parts
while Counter < 20 do
	Counter = Counter + 1
	local SwingingPart = Instance.new("Part")
	SwingingPart.Parent = workspace.SwingingParts
	SwingingPart.Name = "SwingingPart" .. Counter
	SwingingPart:SetAttribute("Counter", Counter)
	if Counter % 2 == 0 then -- checks if it is even to ensure that parts spawn left-right-left-right
		SwingingPart.Position = LastPartPosition + Vector3.new(math.random(250, 350), 0, 25) -- generate semi-random position
	else
		SwingingPart.Position = LastPartPosition + Vector3.new(math.random(250, 350), 0, -25) -- generate semi-random position
	end
	LastPartPosition = SwingingPart.Position -- set the new last part position
	SwingingPart.Anchored = true
	SwingingPart.Size = Vector3.new(40, 40, 40) -- big blocks to make aiming easier
	SwingingPart.Color = Color3.fromRGB(154, 142, 142)
	SwingingPart.Material = Enum.Material.SmoothPlastic
	
	local Attachment = Instance.new("Attachment")
	Attachment.Name = "SwingAttachment" .. Counter
	Attachment.Parent = SwingingPart
	Attachment.Position = Vector3.new(0, 2, 0) -- place attachment at the top of the part
	Attachment.Orientation = Vector3.new(0, 0, 0) -- ensure the attachment is not rotated
end

-- Create finish line
local LastSwingingPart: Part = workspace.SwingingParts:WaitForChild("SwingingPart" .. 20)
local FinishPlatform = Instance.new("Part")
FinishPlatform.Name = "FinishPlatform"
FinishPlatform.Size = Vector3.new(100, 3, 100)
FinishPlatform.Position = LastSwingingPart.Position + Vector3.new(75, -250, -12.5)
FinishPlatform.Parent = workspace
FinishPlatform.Anchored = true

local Debounce = false

FinishPlatform.Touched:Connect(function(Hit) -- teleport player back to start and calculate their time when they touch the end
	if Debounce then return end
	local Character: Model = Hit.Parent
	if not Character then return end
	local Player = Players:GetPlayerFromCharacter(Character)

	if Player then
		task.spawn(function()
			Debounce = true
			task.wait(5)
			Debounce = false
		end)
		Player:LoadCharacterAsync()

		local FinishTime = tick() -- get time finished
		local Time: number = FinishTime - StartTime -- calculate time taken for whole course
		Time = math.round(Time)
		if Time < (TimeStore:GetAsync(Player.UserId) or 0) then -- Update player time if its a new personal best
			TimeStore:SetAsync(Player.UserId, Time)
			Player.leaderstats.Time.Value = Time
		end
		Event:FireClient(Player, TimeStore:GetAsync(Player.UserId))
	end
end)

Event.OnServerEvent:Connect(function(Player, IsSwinging, SwingCount)
	if SwingCount == 1 then
		StartTime = tick() -- start a timer to track how long the player takes
	end
	local Character = Player.Character or Player.CharacterAdded:Wait() -- get the player's character
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid") -- get the player's humanoid
	local HumanoidRootPart: BasePart = Character:WaitForChild("HumanoidRootPart") -- get the player's humanoid root part
	
	local PlayerAttachment = HumanoidRootPart:FindFirstChild("PlayerAttachment")
	
	PlayerAttachment = Instance.new("Attachment")
	PlayerAttachment.Parent = HumanoidRootPart
	PlayerAttachment.Name = "PlayerAttachment"
	
	if IsSwinging == false then
		local Rope = Instance.new("RopeConstraint")
		Rope.Attachment0 = PlayerAttachment
		Rope.Attachment1 = workspace.SwingingParts:WaitForChild("SwingingPart" .. SwingCount):WaitForChild("SwingAttachment" .. SwingCount) -- attach the rope to the first swing attachment
		Rope.Parent = HumanoidRootPart
		Rope.Visible = true
		Rope.Length = 100
		Rope.Restitution = 0.8
	elseif IsSwinging then
		local Rope = HumanoidRootPart:FindFirstChild("RopeConstraint") -- destroy the rope
		if Rope then
			Rope:Destroy()
		end
	end
end)
