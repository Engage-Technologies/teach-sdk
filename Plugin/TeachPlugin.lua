-- Create a new toolbar section titled "Custom Script Tools"
local Selection = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")
local StudioService = game:GetService("StudioService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local versionNum = "1.1.4"

local toolbar = plugin:CreateToolbar("Teach " .. versionNum)

local newWidgetButton = toolbar:CreateButton("Teach", "Launch Roblox Teach Plugin", "rbxassetid://9415737981")
newWidgetButton.ClickableWhenViewportHidden = true

-- Create new "DockWidgetPluginGuiInfo" object
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Widget will be initialized in floating panel
	false,   -- Widget will be initially enabled
	true,  -- Don't override the previous enabled state
	200,    -- Default width of the floating window
	300,    -- Default height of the floating window
	150,    -- Minimum width of the floating window
	150     -- Minimum height of the floating window
)

local TeachWidget = plugin:CreateDockWidgetPluginGui("Teach " .. versionNum, widgetInfo)
TeachWidget.Title = "Teach " .. versionNum

local function onWidgetLaunch()
	TeachWidget.Enabled = true	
end
newWidgetButton.Click:Connect(onWidgetLaunch)

local apiKey

local apiKeyFrame = Instance.new("Frame", TeachWidget)
local questionFrame = Instance.new("Frame", TeachWidget)
local surfacePlacementFrame = Instance.new("Frame", TeachWidget)
local settingsFrame = Instance.new("Frame", TeachWidget)
local installFrame = Instance.new("Frame", TeachWidget)
apiKeyFrame.Visible = false
questionFrame.Visible = false
surfacePlacementFrame.Visible = false
settingsFrame.Visible = false
installFrame.Visible = false


local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TeachSDK

local backendScript = ServerScriptService:FindFirstChild("TeachBackendScript")

-- Question Zone attributes
local zoneBox
local surfaceEditObject
local visibleFrame

local function setVisibleFrame(frame)
	apiKeyFrame.Visible = false
	questionFrame.Visible = false
	surfacePlacementFrame.Visible = false
	settingsFrame.Visible = false
	installFrame.Visible = false

	if frame == "api" then
		apiKeyFrame.Visible = true
		visibleFrame = "api"		
	elseif frame == "surface" then
		surfacePlacementFrame.Visible = true
		visibleFrame = "surface"
	elseif frame == "settings" then
		settingsFrame.Visible = true
		visibleFrame = "settings"
	else
		questionFrame.Visible = true
		visibleFrame = "question"
	end
end

local function attemptBackendConnect(code)
	-- Remove whitespace from code
	code = code:gsub("%s+","")

	-- Register game
	local loggedInUserId = StudioService:GetUserId()
	local loggedInUserName = Players:GetNameFromUserIdAsync(loggedInUserId)

	return TeachSDK.registerGame(code, loggedInUserId, loggedInUserName)
end

local function updateAPIKey(newApiKey)

	apiKey = newApiKey

	-- Attempt to update the API Key in the code
	local success, message = pcall(function()
		local apiWrapper = ServerStorage.TeachSDK.TeachAPIWrapper
		apiWrapper:SetAttribute("apiKey", apiKey) -- subpar way to store the API Key
	end)
	if not success then
		print("[ERROR] Unable to update API Key. Add attribute 'apiKey' to TeachSDK/TeachAPIWrapper.lua")
	end
end

local function decideAvailableFrames()
	-- Decides which frames are available to run next

	if apiKey == nil then
		setVisibleFrame("api")
	else
		-- Always update the API Key
		local success = attemptBackendConnect(apiKey)
		if not success then
			print("API Key verification failed.")
		end
		
		updateAPIKey(apiKey)

		setVisibleFrame("question")
	end
end

local function getCurrentZoneNumber()
	return tonumber(zoneBox.Text)
end

local function setCurrentZoneNumber(zoneNumber)
	zoneBox.Text = tostring(zoneNumber)
end

local function initializeTeachZones()
	local zoneNum = 1
	backendScript:SetAttribute("TeachZones", zoneNum)
	return zoneNum
end

local function getMaxZoneNumber()
	local maxZones

	local success, message = pcall(function()
		maxZones = backendScript:GetAttribute("TeachZones")
	end)

	-- Initialize
	if maxZones == nil then
		return initializeTeachZones()
	else
		return maxZones
	end
end

local function incrementMaxZoneNumber()	
	local numZones = getMaxZoneNumber()
	local newNumZones = numZones + 1
	backendScript:SetAttribute("TeachZones", newNumZones)
	setCurrentZoneNumber(newNumZones)
	return newNumZones
end

local function buildApiKeyFrame()
	apiKeyFrame.Size = UDim2.new(1, 0, 1, 0)

	local websiteFrame = Instance.new("Frame", apiKeyFrame)
	websiteFrame.BorderSizePixel = 0
	websiteFrame.Position = UDim2.new(0, 0, 0.15, 0)
	websiteFrame.Size = UDim2.new(1, 0, 0.25, 0)
	websiteFrame.Visible = true

	-- Website Label
	local websiteLabel = Instance.new("TextLabel", websiteFrame)
	websiteLabel.BorderSizePixel = 0
	websiteLabel.Size = UDim2.new(1, 0, 0.6, 0)
	websiteLabel.Visible = true
	websiteLabel.TextScaled = true
	websiteLabel.Text = "RobloxTeach.com"

	-- Website Logo
	local motoLabel = Instance.new("TextLabel", websiteFrame)
	motoLabel.BorderSizePixel = 0
	motoLabel.Position = UDim2.new(0, 0, 0.6, 0)
	motoLabel.Size = UDim2.new(1, 0, 0.4, 0)
	motoLabel.Visible = true
	motoLabel.TextScaled = true
	motoLabel.Text = "Educational Rails for the Metaverse"

	-- API Key Box
	local apiKeyBox = Instance.new("TextBox", apiKeyFrame)
	apiKeyBox.AnchorPoint = Vector2.new(0.5, 0)
	apiKeyBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	apiKeyBox.Size = UDim2.new(0.75, 0, 0.2, 0)
	apiKeyBox.PlaceholderText = "API Key"
	apiKeyBox.TextScaled = true
	apiKeyBox.Text = "API Key"

	apiKeyBox.FocusLost:Connect(function(enterPressed)

		-- Remove whitespace
		local code = apiKeyBox.Text

		if code ~= "" then
			print("Registering game with backend...")
			local success = attemptBackendConnect(code)

			if success then
				print("API Key Accepted.")
				updateAPIKey(code)
				decideAvailableFrames()
			end
		else
			apiKeyBox.Text = "API Key"
		end
	end)
end

local function buildQuestionFrame()
	questionFrame.Size = UDim2.new(1, 0, 1, 0)

	local logoLabel = Instance.new("TextLabel", questionFrame)
	logoLabel.BorderSizePixel = 0
	logoLabel.Size = UDim2.new(1, 0, 0.15, 0)
	logoLabel.Text = "Roblox Teach"
	logoLabel.TextScaled = true

	local settingsButton = Instance.new("ImageButton", questionFrame)
	settingsButton.BorderSizePixel = 0
	settingsButton.Position = UDim2.new(0.9, 0, 0, 0)
	settingsButton.Size = UDim2.new(0.1, 0, 0.15, 0)
	settingsButton.SizeConstraint = Enum.SizeConstraint.RelativeXY
	settingsButton.Image = "rbxassetid://9017073939"
	settingsButton.ScaleType = Enum.ScaleType.Fit
	settingsButton.MouseButton1Click:Connect(function()
		setVisibleFrame("settings")
	end)

	local function buildZoneFrame()
		local zoneFrame = Instance.new("Frame", questionFrame)
		zoneFrame.Position = UDim2.new(0,0,0.15, 0)
		zoneFrame.Size = UDim2.new(1,0,0.25, 0)
		zoneFrame.BorderSizePixel = 0

		local zoneLabel = Instance.new("TextLabel", zoneFrame)
		zoneLabel.AnchorPoint = Vector2.new(0.5 ,0)
		zoneLabel.BorderSizePixel = 0
		zoneLabel.Position = UDim2.new(0.15, 0, 0, 0)
		zoneLabel.Size = UDim2.new(0.2, 0, 1, 0)
		zoneLabel.Text = "Zone"
		zoneLabel.TextScaled = true


		local function adjustSurfaceGuiZone(newZone)
			-- Adjusts all selected objects to be a part of the new zone number
			-- Let's just label every object with the new zone number?
			
			local selection = Selection:Get()
			for _, selected in ipairs(selection) do
				
				-- Search through descendants and the root object
				local allSearch = selected:GetDescendants()
				table.insert(allSearch, selected)
				
				for _, child in pairs(allSearch) do
					
					if child:GetAttribute("TeachType") ~= nil then
						
						local allTags = CollectionService:GetTags(child)
						
						for _, tag in ipairs(allTags) do
							
							-- Remove all QuestionZone tags
							if tag:match("QuestionZone") then
								CollectionService:RemoveTag(child, tag)
								
								local oldZone, _ = tag:gsub("QuestionZone", "")
								
								-- Update the textlabel
								local textLabel = child:FindFirstChildWhichIsA("TextLabel")
								if textLabel ~= nil then									
									local newText, replaced = textLabel.Text:gsub("z" .. oldZone, "z"..tostring(newZone))
									textLabel.Text = newText
								end
								
							end
						end
						
						-- Add correct QuestionZone tag
						CollectionService:AddTag(child, "QuestionZone" .. tostring(newZone))
						
					end
					
				end
			end
		end

		zoneBox = Instance.new("TextBox", zoneFrame)
		zoneBox.AnchorPoint = Vector2.new(0.5 ,0)
		zoneBox.BorderSizePixel = 0
		zoneBox.Position = UDim2.new(0.35, 0, 0, 0)
		zoneBox.Size = UDim2.new(0.2, 0, 1, 0)
		zoneBox.Text = tostring(getMaxZoneNumber())
		zoneBox.PlaceholderText = "#"
		zoneBox.TextScaled = true

		zoneBox.FocusLost:Connect(function(enterPressed)

			local newNum
			local success, errorMsg = pcall(function()
				newNum = tonumber(zoneBox.Text)
			end)
			
			if newNum == nil then
				zoneBox.Text = tostring(getMaxZoneNumber())
				return
			end

			if newNum > getMaxZoneNumber() then
				newNum = incrementMaxZoneNumber()
			end

			if newNum then
				adjustSurfaceGuiZone(newNum)
			else
				setCurrentZoneNumber(newNum)
				print("[ERROR] Unable to convert input to a number")
			end

		end)

		local upZoneButton = Instance.new("ImageButton", zoneFrame)
		upZoneButton.AnchorPoint = Vector2.new(0.5, 0)
		upZoneButton.BorderSizePixel = 0
		upZoneButton.Position = UDim2.new(0.55, 0, 0, 0)
		upZoneButton.Size = UDim2.new(0.15, 0, 0.5, 0)
		upZoneButton.Image = "rbxassetid://29563813"

		upZoneButton.MouseButton1Click:Connect(function()
			-- Get the new zone number
			-- Check if it's less than the maxZoneNumber and increment
			local newZoneNum = getCurrentZoneNumber() + 1
			if newZoneNum > getMaxZoneNumber() then
				incrementMaxZoneNumber()
			end
			setCurrentZoneNumber(newZoneNum)
			adjustSurfaceGuiZone(newZoneNum)
		end)

		local downZoneButton = Instance.new("ImageButton", zoneFrame)
		downZoneButton.AnchorPoint = Vector2.new(0.5, 0)
		downZoneButton.BorderSizePixel = 0
		downZoneButton.Position = UDim2.new(0.55, 0, 0.5, 0)
		downZoneButton.Rotation = 180
		downZoneButton.Size = UDim2.new(0.15, 0, 0.5, 0)
		downZoneButton.Image = "rbxassetid://29563813"

		downZoneButton.MouseButton1Click:Connect(function()
			local newZoneNum = math.max( getCurrentZoneNumber() - 1, 1)
			setCurrentZoneNumber(newZoneNum)
			adjustSurfaceGuiZone(newZoneNum)
		end)

		local checkButton = Instance.new("TextButton", zoneFrame)
		checkButton.AnchorPoint = Vector2.new(0.5, 0)
		checkButton.BorderSizePixel = 0
		checkButton.Position = UDim2.new(0.85, 0, 0, 0)
		checkButton.Size = UDim2.new(0.25, 0, 1, 0)
		checkButton.Text = "Check"
		checkButton.TextScaled = true
		checkButton.MouseButton1Click:Connect(function()
			local missing = false
			for i = 1, getMaxZoneNumber() do
				local missingComponents = {}

				local components = TeachSDK.findZoneComponents(i, {"question", "response", "option"})

				if not components["question"] then
					table.insert(missingComponents, "question")
				end
				if not components["option1"] then
					table.insert(missingComponents, "option1")
				end
				if not components["option2"] then
					table.insert(missingComponents, "option2")
				end
				if not components["option3"] then
					table.insert(missingComponents, "option3")
				end
				if not components["response1"] then
					table.insert(missingComponents, "response1")
				end
				if not components["response2"] then
					table.insert(missingComponents, "response2")
				end
				if not components["response3"] then
					table.insert(missingComponents, "response3")
				end

				if #missingComponents > 0 then
					print("Zone " .. i .. " missing: " .. table.concat(missingComponents, ', ') )
					missing = true
				end
			end
			if not missing then
				print("No components missing.")
			end
		end)
	end
	buildZoneFrame()

	local function buildOptionsFrame()
		local optionsFrame = Instance.new("Frame", questionFrame)
		optionsFrame.AnchorPoint = Vector2.new(0.5, 0)
		optionsFrame.Position = UDim2.new(0.5, 0, 0.48, 0)
		optionsFrame.Size = UDim2.new(1, 0, 0.5, 0)
		optionsFrame.BorderSizePixel = 0

		local uiGridLayout = Instance.new("UIGridLayout", optionsFrame)
		uiGridLayout.CellPadding = UDim2.new(0.018, 0,0.1, 0)
		uiGridLayout.CellSize = UDim2.new(0.179, 0,0.45, 0)
		uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
		uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uiGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local questionButton = Instance.new("TextButton", optionsFrame)
		questionButton.Text = "Question"
		questionButton.TextScaled = true

		local option1Button = Instance.new("TextButton", optionsFrame)
		option1Button.Text = "Option 1"
		option1Button.TextScaled = true

		local option2Button = Instance.new("TextButton", optionsFrame)
		option2Button.Text = "Option 2"
		option2Button.TextScaled = true

		local option3Button = Instance.new("TextButton", optionsFrame)
		option3Button.Text = "Option 3"
		option3Button.TextScaled = true

		local allButton = Instance.new("TextButton", optionsFrame)
		allButton.Text = "All"
		allButton.TextScaled = true

		local leftSpace = Instance.new("TextLabel", optionsFrame)
		leftSpace.BorderSizePixel = 0
		leftSpace.Text = ""

		local response1Button = Instance.new("TextButton", optionsFrame)
		response1Button.Text = "Response 1"
		response1Button.TextScaled = true

		local response2Button = Instance.new("TextButton", optionsFrame)
		response2Button.Text = "Response 2"
		response2Button.TextScaled = true

		local response3Button = Instance.new("TextButton", optionsFrame)
		response3Button.Text = "Response 3"
		response3Button.TextScaled = true

		--local function redrawButtons()
		--	local zoneComponents = TeachSDK.findZoneComponents(getCurrentZoneNumber(), {"question", "option","response"})

		--	local alreadyPlacedColor = Color3.fromRGB(0, 0, 0)
		--	local notPlacedColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)

		--	-- Question Button
		--	if zoneComponents["question"] then
		--		questionButton.BackgroundColor3 = alreadyPlacedColor
		--	else
		--		questionButton.BackgroundColor3 = notPlacedColor
		--	end

		--	-- Option1 Button
		--	if zoneComponents["option1"] then
		--		option1Button.BackgroundColor3 = alreadyPlacedColor
		--	else
		--		option1Button.BackgroundColor3 = notPlacedColor
		--	end

		--	-- Option2 Button
		--	if zoneComponents["option2"] then
		--		option2Button.BackgroundColor3 = alreadyPlacedColor
		--	else
		--		option2Button.BackgroundColor3 = notPlacedColor
		--	end

		--	-- Option3 Button
		--	if zoneComponents["option3"] then
		--		option3Button.BackgroundColor3 = alreadyPlacedColor
		--	else
		--		option3Button.BackgroundColor3 = notPlacedColor
		--	end

		--	-- Response1 Button
		--	if zoneComponents["response1"] then
		--		response1Button.BackgroundColor3 = alreadyPlacedColor
		--	else
		--		response1Button.BackgroundColor3 = notPlacedColor
		--	end

		--	-- Response2 Button
		--	if zoneComponents["response2"] then
		--		response2Button.BackgroundColor3 = alreadyPlacedColor
		--	else
		--		response2Button.BackgroundColor3 = notPlacedColor
		--	end

		--	-- Response3 Button
		--	if zoneComponents["response3"] then
		--		response3Button.BackgroundColor3 = alreadyPlacedColor
		--	else
		--		response3Button.BackgroundColor3 = notPlacedColor
		--	end
		--end
		--redrawButtons()

		local function createNewFrame(parent, componentType)
			local componentFrame = Instance.new("Frame", parent)
			componentFrame:SetAttribute("TeachType", componentType:lower())
			componentFrame.Size = UDim2.new(1,0,1,0)
			componentFrame.Name = componentType .. "Frame"
			componentFrame.BackgroundTransparency = 1
			CollectionService:AddTag(componentFrame, "QuestionZone" .. tostring(getCurrentZoneNumber()))
			
			local imageLabel = Instance.new("ImageLabel", componentFrame)
			imageLabel.Size = UDim2.new(1,0,1,0)
			imageLabel.ScaleType = Enum.ScaleType.Stretch
			imageLabel.Visible = false
			imageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			imageLabel.BackgroundTransparency = 1
			imageLabel.AnchorPoint = Vector2.new(0.5,0.5)
			imageLabel.Position = UDim2.new(0.5,0,0.5,0)
			local textLabel = Instance.new("TextLabel", componentFrame)
			textLabel.Size = UDim2.new(1,0,1,0)
			textLabel.TextScaled = true
			textLabel.Text = "z" .. tostring(getCurrentZoneNumber()) .. " " .. componentType:gsub("Option", "o")
			textLabel.Visible = true
			textLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.BackgroundTransparency = 1
			return componentFrame
		end

		local function handleNewComponent(component, onlyAdd)
			onlyAdd = onlyAdd or false

			-- Check correct selection
			local selection = Selection:Get()
			if #selection > 1 then
				print("[ERROR] Only select one object to place the question/option on.")
				return
			elseif #selection == 0 then
				print("[ERROR] Must select an object to place " .. component)
				return
			end
			local componentObj = selection[1]

			-- Check if we have a surface GUI
			local surfaceGUI = componentObj:FindFirstChildWhichIsA("SurfaceGui")
			if not surfaceGUI then
				surfaceGUI = Instance.new("SurfaceGui", componentObj)
				surfaceGUI.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				setVisibleFrame("surface")
			end
			surfaceEditObject = surfaceGUI

			local zoneComponents = TeachSDK.findZoneComponents(getCurrentZoneNumber(), {"question", "option"})

			-- All components on our surface
			local allComponents = {}
			for key, value in pairs(zoneComponents) do
				if value.Parent == surfaceGUI then
					allComponents[key] = value
				end
			end

			-- Check if component is already present to remove it
			if not allComponents[component:lower()] and zoneComponents[component:lower()] then
				print("[ERROR] Zone " .. tostring(getCurrentZoneNumber()) .. " " .. component .. " already placed.")
				return
			end

			if allComponents[component:lower()] and not onlyAdd then
				allComponents[component:lower()]:Destroy()
				allComponents[component:lower()] = nil
			elseif allComponents[component:lower()] then
				-- Do nothing..
			else
				allComponents[component:lower()] = createNewFrame(surfaceGUI, component)
			end

			local numComponents = 0
			for key, value in pairs(allComponents) do
				numComponents += 1
			end

			local optionsHeight = 1.0
			local numOptions = numComponents
			if allComponents["question"] ~= nil and numComponents > 1 then
				optionsHeight = 0.5
				numOptions = numComponents - 1
				allComponents["question"].Size = UDim2.new(1,0,0.5,0)
			elseif allComponents["question"] then
				-- Just a question
				allComponents["question"].Size = UDim2.new(1,0,1,0)
			end

			local count = 0
			local sizeIncrement = 1 / numOptions
			for i, option in ipairs({"option1", "option2", "option3"}) do
				if allComponents[option] then
					allComponents[option].Size = UDim2.new(sizeIncrement, 0, optionsHeight, 0)
					allComponents[option].Position = UDim2.new(sizeIncrement * count, 0, 1 - optionsHeight, 0)
					count += 1
				end
			end

			-- Update button colors
			--redrawButtons()
		end

		local function addResponse(responseType)
			-- Check correct selection
			local selection = Selection:Get()
			if #selection > 1 then
				print("[ERROR] Only select one object to place the question/option on.")
				return
			end
			local componentObj = selection[1]

			-- Check we have tagged this object
			local tagName = "QuestionZone" .. tostring(getCurrentZoneNumber())
			CollectionService:AddTag(componentObj, tagName)
			componentObj.Anchored = true

			if componentObj:GetAttribute("TeachType") ~= nil then
				componentObj:SetAttribute("TeachType", nil)
			else
				componentObj:SetAttribute("TeachType", responseType)
			end
		end

		-- Callbacks
		questionButton.MouseButton1Click:Connect(function()			
			handleNewComponent("Question")
		end)
		option1Button.MouseButton1Click:Connect(function()
			handleNewComponent("Option1")
		end)
		option2Button.MouseButton1Click:Connect(function()
			handleNewComponent("Option2")
		end)
		option3Button.MouseButton1Click:Connect(function()
			handleNewComponent("Option3")
		end)
		allButton.MouseButton1Click:Connect(function()
			handleNewComponent("Question", true)
			handleNewComponent("Option1", true)
			handleNewComponent("Option2", true)
			handleNewComponent("Option3", true)
		end)
		response1Button.MouseButton1Click:Connect(function()
			addResponse("response1")
		end)
		response2Button.MouseButton1Click:Connect(function()
			addResponse("response2")
		end)
		response3Button.MouseButton1Click:Connect(function()
			addResponse("response3")
		end)

	end
	buildOptionsFrame()

end

local function buildSurfacePlacementFrame()
	surfacePlacementFrame.BorderSizePixel = 0
	surfacePlacementFrame.Size = UDim2.new(1,0,1,0)

	local bannerLabel = Instance.new("TextLabel", surfacePlacementFrame)
	bannerLabel.Size = UDim2.new(1,0,0.2,0)
	bannerLabel.Text = "Select Surface Side"
	bannerLabel.TextScaled = true

	local frame = Instance.new("Frame", surfacePlacementFrame)
	frame.Position = UDim2.new(0,0,0.2,0)
	frame.Size = UDim2.new(1,0,0.6, 0)

	local function buildFrame()
		local uiGridLayout = Instance.new("UIGridLayout", frame)
		uiGridLayout.CellPadding = UDim2.new(0.03, 0, 0.05, 0)
		uiGridLayout.CellSize = UDim2.new(0.25, 0, 0.35, 0)
		uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
		uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uiGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center

		local function surfaceSideCallback(surfaceSide)
			surfaceEditObject.Face = surfaceSide
		end

		local backButton = Instance.new("TextButton", frame)
		backButton.Text = "Back"
		backButton.TextScaled = true
		backButton.MouseButton1Click:Connect(function()
			surfaceSideCallback(Enum.NormalId.Back)
		end)

		local bottomButton = Instance.new("TextButton", frame)
		bottomButton.Text = "Bottom"
		bottomButton.TextScaled = true
		bottomButton.MouseButton1Click:Connect(function()
			surfaceSideCallback(Enum.NormalId.Bottom)
		end)

		local frontButton = Instance.new("TextButton", frame)
		frontButton.Text = "Front"
		frontButton.TextScaled = true
		frontButton.MouseButton1Click:Connect(function()
			surfaceSideCallback(Enum.NormalId.Front)
		end)

		local leftButton = Instance.new("TextButton", frame)
		leftButton.Text = "Left"
		leftButton.TextScaled = true
		leftButton.MouseButton1Click:Connect(function()
			surfaceSideCallback(Enum.NormalId.Left)
		end)

		local rightButton = Instance.new("TextButton", frame)
		rightButton.Text = "Right"
		rightButton.TextScaled = true
		rightButton.MouseButton1Click:Connect(function()
			surfaceSideCallback(Enum.NormalId.Right)
		end)

		local topButton = Instance.new("TextButton", frame)
		topButton.Text = "Top"
		topButton.TextScaled = true
		topButton.MouseButton1Click:Connect(function()
			surfaceSideCallback(Enum.NormalId.Top)
		end)
	end
	buildFrame()

	local doneButton = Instance.new("TextButton", surfacePlacementFrame)
	doneButton.Position = UDim2.new(0,0,0.8,0)
	doneButton.Size = UDim2.new(1,0,0.2,0)
	doneButton.Text = "Done"
	doneButton.TextScaled = true
	doneButton.MouseButton1Click:Connect(function()
		setVisibleFrame("question")
	end)

end

local function buildSettingsFrame()
	settingsFrame.Size = UDim2.new(1, 0, 1, 0)

	local logoLabel = Instance.new("TextLabel", settingsFrame)
	logoLabel.BorderSizePixel = 0
	logoLabel.Size = UDim2.new(1, 0, 0.15, 0)
	logoLabel.Text = "Settings"
	logoLabel.TextScaled = true

	local backButton = Instance.new("ImageButton", settingsFrame)
	backButton.BorderSizePixel = 0
	backButton.Size = UDim2.new(0.1,0,0.15, 0)
	backButton.SizeConstraint = Enum.SizeConstraint.RelativeXY
	backButton.ZIndex = 2
	backButton.Image = "rbxassetid://6807196325"
	backButton.ScaleType = Enum.ScaleType.Stretch
	backButton.MouseButton1Click:Connect(function()
		setVisibleFrame("question")
	end)

	local scrollingFrame = Instance.new("ScrollingFrame", settingsFrame)
	scrollingFrame.Position = UDim2.new(0,0,0.2,0)
	scrollingFrame.Size = UDim2.new(1,0,0.8,0)

	local uiListLayout = Instance.new("UIListLayout", scrollingFrame)

	-- API Settings
	local function buildAPIKey()
		local settingsApiFrame = Instance.new("Frame", scrollingFrame)
		settingsApiFrame.Size = UDim2.new(1,0,0.1,0)

		local textlabel = Instance.new("TextLabel", settingsApiFrame)
		textlabel.BorderSizePixel = 0
		textlabel.Size = UDim2.new(0.5,0,1,0)
		textlabel.Text = "API Key"
		textlabel.TextScaled = true

		local textbox = Instance.new("TextBox", settingsApiFrame)
		textbox.Position = UDim2.new(0.5,0,0,0)
		textbox.Size = UDim2.new(0.5, 0, 1, 0)
		textbox.PlaceholderText = ""
		if apiKey ~= nil then
			textbox.Text = apiKey
		else
			textbox.Text = ""
		end
		textbox.TextScaled = true
		textbox.FocusLost:Connect(function(enterPressed)
			local code = textbox.Text
			if code ~= "" then
				local success = attemptBackendConnect(code)
				if success then
					print("API Key Accepted.")
					updateAPIKey(code)
					decideAvailableFrames()
				end
			else
				textbox.Text = apiKey
			end
		end)
	end
	buildAPIKey()


end

Selection.SelectionChanged:Connect(function()

	if visibleFrame == "surface" then
		setVisibleFrame("question")
	end

	for i, selection in ipairs(Selection:Get()) do
		
		local descendants = selection:GetDescendants()
		table.insert(descendants, selection)
		
		for _, child in ipairs(descendants) do
			
			local tags = CollectionService:GetTags(child)

			for j, tag in ipairs(tags) do

				if tag:match("QuestionZone") then

					local newZoneNum, replaced = tag:gsub("QuestionZone", "")
					setCurrentZoneNumber(tonumber(newZoneNum))
					return
				end

			end
			
		end
		
	end	
end)


local function syncGuiColors(objects)
	local function setColors()
		for _, guiObject in pairs(objects) do

			-- Attempt to sync text color
			local _, _ = pcall(function()
				guiObject.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
				guiObject.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
				guiObject.BorderColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
			end)

		end
	end
	-- Run 'setColors()' function to initially sync colors
	setColors()
	-- Connect 'ThemeChanged' event to the 'setColors()' function
	settings().Studio.ThemeChanged:Connect(setColors)
end

local function checkInstallation()
	if ServerStorage:FindFirstChild("TeachSDK") == nil or ServerScriptService:FindFirstChild("TeachScripts") == nil then
		return false
	end
	return true
end

local function loadFiles()
	local teachScriptFolder = ServerScriptService:FindFirstChild("TeachScripts")
	teachScriptFolder.Parent = ServerScriptService

	-- Backend Script
	backendScript = teachScriptFolder:FindFirstChild("TeachBackendScript")
	
	TeachSDK = require( ServerStorage:FindFirstChild("TeachSDK"):FindFirstChild("TeachSDKModule"):Clone() )
	
	-- Get Engage Number of Zones
	local zoneNum = 1
	while true do
		
		local tagName = "QuestionZone" .. tostring(zoneNum)

		local zoneObjects = CollectionService:GetTagged(tagName)
		
		if #zoneObjects < 1 then
			break
		end
		zoneNum += 1
		
	end
	
	backendScript:SetAttribute("TeachZones", zoneNum - 1)
end

local function installFiles()
	
	-- Teach Scripts
	if ServerScriptService:FindFirstChild("TeachScripts") == nil then
		local teachScriptFolder = script.TeachScripts:Clone()
		teachScriptFolder.Parent = ServerScriptService
		
		-- Backend Script
		backendScript = teachScriptFolder:FindFirstChild("TeachBackendScript")
		backendScript.Disabled = false
		backendScript:SetAttribute("TeachZones", 1)
		
		-- GetFirstQuestionScript
		local file = teachScriptFolder:FindFirstChild("GetFirstQuestionScript")
		file.Disabled = false
	end
	
	-- Install ServerScriptService
	--if not ServerScriptService:FindFirstChild("TeachBackendScript") then
	--	local file = script.ServerScriptService.TeachBackendScript:Clone()
	--	file.Parent = ServerScriptService
	--	file.Disabled = false
	--	file:SetAttribute("TeachZones", 0)
	--	backendScript = file
	--else
	--	backendScript = ServerScriptService:FindFirstChild("TeachBackendScript")
	--end
	---- Install GetFirstQuestionScript
	--if not ServerScriptService:FindFirstChild("GetFirstQuestionScript") then
	--	local file = script.ServerScriptService.GetFirstQuestionScript:Clone()
	--	file.Parent = ServerScriptService
	--	file.Disabled = false
	--end
	
	-- TeachSDK
	if ServerStorage:FindFirstChild("TeachSDK") == nil then
		local folder = script.TeachSDK:Clone()
		folder.Parent = ServerStorage
		TeachSDK = require( ServerStorage:FindFirstChild("TeachSDK"):FindFirstChild("TeachSDKModule"):Clone() )
	else
		TeachSDK = require( ServerStorage:FindFirstChild("TeachSDK"):FindFirstChild("TeachSDKModule"):Clone() )
	end
end

local function waitForInstallAccept()
	installFrame.Size = UDim2.new(1, 0, 1, 0)
	installFrame.Visible = true

	local memoLabel = Instance.new("TextLabel", installFrame)
	memoLabel.BorderSizePixel = 0
	memoLabel.Size = UDim2.new(1, 0, 0.3, 0)
	memoLabel.Text = "Teach Plugin would like to insert the following scripts:"
	memoLabel.TextScaled = true

	local filesLabel = Instance.new("TextLabel", installFrame)
	filesLabel.BorderSizePixel = 0
	filesLabel.Size = UDim2.new(1,0,0.4, 0)
	filesLabel.Text = "ServerStorage/TeachSDK ServerScriptService/TeachScripts"
	filesLabel.TextScaled = true
	filesLabel.Position = UDim2.new(0,0,0.3,0)

	local okButton = Instance.new("TextButton", installFrame)
	okButton.BorderSizePixel = 1
	okButton.Size = UDim2.new(1,0,0.3,0)
	okButton.Position = UDim2.new(0,0,0.7,0)
	okButton.TextScaled = true
	okButton.Text = "OK"

	okButton.MouseButton1Click:Connect(function()
		installFiles()
	end)

	syncGuiColors(TeachWidget:GetDescendants())

	while wait() do
		if checkInstallation() then
			break
		end
	end

end

local function attemptToGrabApiKey()
	local apiWrapper = ServerStorage:FindFirstChild("TeachSDK"):FindFirstChild("TeachAPIWrapper")
	apiKey = apiWrapper:GetAttribute("apiKey")
end

if RunService:IsEdit() then
	
	if not checkInstallation() then
		waitForInstallAccept()
	end
	loadFiles()
	
	attemptToGrabApiKey()
	
	buildApiKeyFrame()
	buildSurfacePlacementFrame()
	buildQuestionFrame()
	buildSettingsFrame()

	decideAvailableFrames()

	syncGuiColors(TeachWidget:GetDescendants())
end