-- Load the event this script listens for
local ServerStorage = game:GetService("ServerStorage")
local EngageEvents = ServerStorage.EngageSDK.Events
local question_type = script:GetAttribute("type")
local zone = script:GetAttribute("zone")
local myEventName = "EngageEventZone_" .. zone
local myEvent = EngageEvents:FindFirstChild(myEventName)

local frame = script.Parent
local textLabel = frame.TextLabel
local imageLabel = frame.ImageLabel

local function toggleDispaly(showText)
	if showText then
		textLabel.Visible = true
		imageLabel.Visible = false
	else
		textLabel.Visible = false
		imageLabel.Visible = true
	end
end

toggleDispaly(true)

-- I should hollow out this script as much as I can...
-- Load as much of it as possible in a module script

myEvent.Event:Connect(function(message)
	--print(myEventName .. " Received!")
	--print(message)
	
	local relevantTable
	if question_type == "option" then
		local option_num = script:GetAttribute("option_num")
		relevantTable = message["options"][option_num]
	else
		relevantTable = message[question_type]
	end
	
	if relevantTable["text"] then
		textLabel.Text = relevantTable["text"]
		toggleDispaly(true)
	end
	if relevantTable["audio"] then
		print("There's audio")
	end
	if relevantTable["image"] then
		print("There's an image")
		imageLabel.Image = "rbxassetid://" .. tostring(relevantTable["image"])
		imageLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
		toggleDispaly(false)
	end
end)