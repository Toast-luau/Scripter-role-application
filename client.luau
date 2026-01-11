local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Event = ReplicatedStorage.Remotes:WaitForChild("SwingEvent")
local RemoteFunction = ReplicatedStorage.Remotes:WaitForChild("UIFunction")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local IsSwinging = false
local CurrentTarget = nil

local MAX_DISTANCE = 500

local Highlight = Instance.new("Highlight")
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false
Highlight.Parent = workspace

local function GetMouseSwingPart() -- returns the swing part that the player is hovering their mouse over
	local MousePos = UserInputService:GetMouseLocation()
	local Ray = Camera:ViewportPointToRay(MousePos.X, MousePos.Y)

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {Player.Character}
	Params.FilterType = Enum.RaycastFilterType.Exclude

	local Result = workspace:Raycast(Ray.Origin, Ray.Direction * MAX_DISTANCE, Params)
	if Result then
		local Part = Result.Instance
		if Part and Part:GetAttribute("Counter") then
			return Part
		end
	end
	return nil
end

local function UpdateGUI(BestTime) -- updates the screen gui
	local PlayerGUI = Player.PlayerGui
	local UI = PlayerGUI:WaitForChild("ScreenGui")
	local Frame = UI:WaitForChild("Frame")
	local TextLabel: TextLabel = Frame:WaitForChild("TextLabel")
	local RoundedTime = math.round(BestTime)
	TextLabel.Text = "Your best time is: " .. RoundedTime
end

local function GetBestTime()
	local BestTime = RemoteFunction:InvokeServer()
	UpdateGUI(BestTime)
end

Player.CharacterAdded:Connect(function()
	GetBestTime()
end)

RunService.RenderStepped:Connect(function()
	local Part = GetMouseSwingPart()

	if Part ~= CurrentTarget then
		CurrentTarget = Part

		if CurrentTarget then
			Highlight.Adornee = CurrentTarget
			Highlight.Enabled = true
		else
			Highlight.Enabled = false
		end
	end
end)

UserInputService.InputBegan:Connect(function(Input, GP)
	if GP then return end

	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not IsSwinging then
			if CurrentTarget then
				IsSwinging = true
				Event:FireServer(false, CurrentTarget:GetAttribute("Counter"))
			end
		else
			IsSwinging = false
			Event:FireServer(true)
		end
	end
end)
