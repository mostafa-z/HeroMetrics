local addonName, HeroMetrics = ...
local xpFrame = CreateFrame("Frame", "HeroMetrics", UIParent, "BackdropTemplate")

-- Set up frame appearance and position
xpFrame:SetSize(200, 100)
xpFrame:SetPoint("TOPLEFT")
xpFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
xpFrame:SetBackdropColor(0, 0, 0, 1)

-- Create font strings for XP and uptime
local xpText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
xpText:SetFont(xpText:GetFont(), 12)
xpText:SetPoint("TOP", xpFrame, "TOP", 0, -10)

local iterationText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
iterationText:SetFont(iterationText:GetFont(), 18)
iterationText:SetPoint("TOP", xpText, "BOTTOM", 0, -10)

local xpProgressText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
xpProgressText:SetFont(xpProgressText:GetFont(), 18)
xpProgressText:SetPoint("TOP", iterationText, "BOTTOM", 0, -10)

local uptimeText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
uptimeText:SetFont(uptimeText:GetFont(), 12)
uptimeText:SetPoint("BOTTOM", xpProgressText, "BOTTOM", 0, -20)

-- Create a standalone FontString for text-only notifications
local notificationText = UIParent:CreateFontString(nil, "OVERLAY")
notificationText:SetFont("Interface\\AddOns\\HeroMetrics\\fonts\\MagistralTTBold.TTF", 24, "OUTLINE")  -- Default font and size
notificationText:SetPoint("CENTER", 0, 0)  -- Default position (center of screen)
notificationText:SetTextColor(1, 1, 0)  -- Default text color (yellow)
notificationText:Hide()  -- Hide initially

-- Global saved variable for all characters
HeroMetricsDB = HeroMetricsDB or {}

-- Initialize variables
local lastXP = 0
local startTime = GetTime()
local lastXPChange = 0
local previousXPChange = 0
local iterationsNeeded = 0
local lastKnownXP = 0
local soundInterval = 25
local soundPlayed = false
local sideSpacing = 10  -- Adjustable side spacing

local addonStartTime = GetTime()
local lastNotificationTime = 0  -- Tracks the last notification time

-- Function to adjust frame size based on text content
local function AdjustFrameSize()
	local textWidth = math.max(xpText:GetStringWidth(), iterationText:GetStringWidth(), xpProgressText:GetStringWidth(), uptimeText:GetStringWidth())
	local textHeight = xpText:GetStringHeight() + iterationText:GetStringHeight() + xpProgressText:GetStringHeight() + uptimeText:GetStringHeight()

	textHeight = textHeight + 60  -- Adjust padding as needed

	xpFrame:SetSize(textWidth + 2 * sideSpacing, textHeight)
end

AdjustFrameSize()

-- Function to calculate uptime
local function FormatTime(uptime)
	local hours = math.floor(uptime / 3600)
	local minutes = math.floor((uptime % 3600) / 60)
	local secs = math.floor(uptime % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Function to display a text notification with customizable options
local function ShowNotificationMessage(message, duration, fontSize, xOffset, yOffset)
	notificationText:SetText(message)
	notificationText:SetFont("Interface\\AddOns\\HeroMetrics\\fonts\\MagistralTTBold.TTF", fontSize or 24, "OUTLINE")

	-- Adjust position based on provided offsets
	notificationText:ClearAllPoints()
	notificationText:SetPoint("CENTER", UIParent, "CENTER", xOffset or 0, yOffset or 0)

	-- Show the text and hide it after the specified duration
	notificationText:Show()
	C_Timer.After(duration or 3, function()
		notificationText:Hide()
	end)
end

-- Example usage for hourly uptime notification
local function CheckUptimeNotification()
	local uptime = GetTime() - addonStartTime

	if uptime >= lastNotificationTime + 3600 then
		lastNotificationTime = uptime
		ShowNotificationMessage("Uptime Alert: " .. FormatTime(uptime), 5, 48, 0, 200)
		PlaySound(SOUNDKIT.READY_CHECK, "Master")
	end
end

local function GetCharacterKey()
	return UnitName("player") .. "-" .. GetRealmName()
end

-- Function to save progress data
local function SaveProgress()
	local characterKey = GetCharacterKey()
	HeroMetricsDB[characterKey] = HeroMetricsDB[characterKey] or {}
	HeroMetricsDB[characterKey].lastXPChange = lastXPChange
	HeroMetricsDB[characterKey].previousXPChange = previousXPChange
	HeroMetricsDB[characterKey].iterationsNeeded = iterationsNeeded
	HeroMetricsDB[characterKey].lastKnownXP = lastKnownXP
end

-- Function to load progress data
local function LoadProgress()
	local characterKey = GetCharacterKey()
	local data = HeroMetricsDB[characterKey]
	if data then
		lastXPChange = data.lastXPChange or 0
		previousXPChange = data.previousXPChange or 0
		iterationsNeeded = data.iterationsNeeded or 0
		lastKnownXP = data.lastKnownXP
	else
		lastXPChange = 0
		previousXPChange = 0
		iterationsNeeded = 0
		lastKnownXP = lastKnownXP
	end
end

-- Function to calculate iterations needed per XP gain
local function perXPiteration(xpChange, xpRemaining)
	return xpChange > 0 and math.ceil(xpRemaining / xpChange) or 0
end

-- Function to update the XP text
local function UpdateXP()
	local maxLevel = GetMaxPlayerLevel()
	local level = UnitLevel("player")
	local currentXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	local xpPercent = maxXP > 0 and math.floor((currentXP / maxXP) * 100) or 0
	local xpRemaining = maxXP - currentXP

	-- Update XP change only if XP has increased
	if currentXP > lastKnownXP then
		if lastKnownXP == 0 then
			lastKnownXP = currentXP
		end
		previousXPChange = lastXPChange
		lastXPChange = currentXP - lastKnownXP
		iterationsNeeded = perXPiteration(lastXPChange, xpRemaining)

		-- Save progress data
		SaveProgress()
	end

	-- Calculate iterations for previous and last XP changes
	local previousIterations = perXPiteration(previousXPChange, xpRemaining)
	local lastIterations = perXPiteration(lastXPChange, xpRemaining)

	-- Update the displayed XP text
	if level < maxLevel then
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s\n\niLevel: %.2f\n\nTo level: %d\nXP Remaining: %d\nPrev XP: %d - %d\nLast XP: %d - %d",
			UnitName("player"), itemLevel, level + 1, xpRemaining,
			previousXPChange, previousIterations, lastXPChange, lastIterations
		))
		iterationText:SetText("Iterations: " .. iterationsNeeded)
		xpProgressText:SetText("XP Progress: " .. xpPercent .. "%")
	else
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s - %d\n\niLevel: %.2f",
			UnitName("player"), level, itemLevel
		))
		iterationText:SetText("")
		xpProgressText:SetText("")
	end

	-- Handle sound notification
	if iterationsNeeded > 0 and iterationsNeeded % soundInterval == 0 and not soundPlayed then
		PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3)
		soundPlayed = true
	elseif iterationsNeeded % soundInterval ~= 0 then
		soundPlayed = false
	end

	-- Update last known XP for the next calculation
	lastKnownXP = currentXP
	
	AdjustFrameSize()
end

local function GetPVPStatus()
	if C_PvP.IsWarModeDesired() then
		xpFrame:SetBackdropBorderColor(1, 0, 0, 1) --Red
	else
		xpFrame:SetBackdropBorderColor(1, 1, 1, 1) --White
	end
end

-- Function to get player's race, class, and specialization
local function GetPlayerRaceClassAndSpec()
	local _, playerClass = UnitClass("player")
	local playerRace = UnitRace("player")
	local classColor = RAID_CLASS_COLORS[playerClass].colorStr

	local specIndex = GetSpecialization()
	local specID, specName = GetSpecializationInfo(specIndex)

	return playerRace, playerClass, classColor, specName
end

-- Function to add race, class, and specialization to the tooltip
local function AddRaceClassAndSpecToTooltip(tooltip)
	local race, class, classColor, spec = GetPlayerRaceClassAndSpec()
	tooltip:AddLine("Character Statistics:", 1, 1, 1)
	tooltip:AddLine(string.format("|c%s%s %s %s|r", classColor, race, spec, class), 1, 1, 1)
end

-- Get realm name
local function GetRealmNameText()
	return "Realm: " .. GetRealmName()
end

-- Get zone name
local function GetZoneNameText()
	return "Current Zone: " .. GetZoneText()
end

-- Function to format gold
local function FormatGold(copper)
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	copper = copper % 100
	return string.format("%d gold, %d silver, %d copper", gold, silver, copper)
end

-- Currency information
local function GetCurrencyText()
	local gold = math.floor(GetMoney() / 10000)
	local silver = math.floor((GetMoney() % 10000) / 100)
	local copper = GetMoney() % 100
	return string.format("• Gold: %d, Silver: %d, Copper: %d", gold, silver, copper)
end

-- Gold gained in session
local function GetSessionGoldGained()
	local goldGained = GetMoney() - startGold
	return "• Session: " .. FormatGold(goldGained)
end

local function AddCurrencyToTooltip(tooltip)
	tooltip:AddLine(" ")
	tooltip:AddLine("Currency:", 1, 1, 1)
	tooltip:AddLine(GetCurrencyText(), 1, 1, 1)
	tooltip:AddLine(GetSessionGoldGained(), 1, 1, 1)
end

local function GetItemLevelDetails()
	local itemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
	return {
		itemLevel = itemLevel and string.format("%.2f", itemLevel) or "0.00",
		avgItemLevelEquipped = avgItemLevelEquipped and string.format("%.2f", avgItemLevelEquipped) or "0.00",
		avgItemLevelPvp = avgItemLevelPvp and string.format("%.2f", avgItemLevelPvp) or "0.00",
	}
end

local function AddItemLevelToTooltip(tooltip)
	local itemLevelDetails = GetItemLevelDetails()

	tooltip:AddLine(" ")
	tooltip:AddLine(string.format("Current Item Level (Eqp): • %s", itemLevelDetails.avgItemLevelEquipped), 1, 1, 1)
	tooltip:AddLine(string.format("Current Item Level (PvE): • %s", itemLevelDetails.itemLevel), 1, 1, 1)
	tooltip:AddLine(string.format("Current Item Level (PvP): • %s", itemLevelDetails.avgItemLevelPvp), 1, 1, 1)
end

-- Function to calculate durability percentage
local function GetDurabilityPercentage()
	local totalDurability = 0
	local totalMaxDurability = 0
	for i = 1, 19 do
		local current, max = GetInventoryItemDurability(i)
		if current and max and max > 0 then
			totalDurability = totalDurability + current
			totalMaxDurability = totalMaxDurability + max
		end
	end
	if totalMaxDurability > 0 then
		return (totalDurability / totalMaxDurability) * 100
	else
		return nil
	end
end

local function AddDurabilityToTooltip(tooltip)
	durabilityPercentage = GetDurabilityPercentage()
	if durabilityPercentage and durabilityPercentage < 90 then
		tooltip:AddLine(" ")
		tooltip:AddLine("Durability:", 1, 1, 1)
		tooltip:AddLine(string.format("• %.2f%%", durabilityPercentage), 1, 1, 1)
	end
end

-- Function to update the tooltip
local function UpdateTooltip(tooltip)
	-- to set tooltip frame on mouse cursor: ANCHOR_CURSOR
	tooltip:SetOwner(xpFrame, "ANCHOR_RIGHT")
	tooltip:ClearLines()
	--RequestTimePlayed()

	tooltip:AddLine(AddRaceClassAndSpecToTooltip(tooltip), 1, 1, 1)

	-- Realm name
	tooltip:AddLine(" ")
	tooltip:AddLine(GetRealmNameText(), 1, 1, 1)

	-- Zone
	tooltip:AddLine(GetZoneNameText(), 1, 1, 1)

	-- Add item level details
	AddItemLevelToTooltip(tooltip)

	-- Add currency details
	AddCurrencyToTooltip(tooltip)

	-- Add durability details
	AddDurabilityToTooltip(tooltip)

	tooltip:Show()
end

-- Function to reset the session
local function ResetSession()
	startGold = GetMoney()
	goldGained = 0
end

xpFrame:SetScript("OnEvent", OnEvent)

-- Mouse event handlers for tooltip
xpFrame:SetScript("OnEnter", function()
	GameTooltip:Hide() -- Hide the default tooltip
	UpdateTooltip(GameTooltip)
end)

xpFrame:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

-- Event handler for XP updates and login, ticker once
xpFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		ResetSession()
		LoadProgress()
		UpdateXP()
		GetPVPStatus()
		if not xpFrame.uptimeTicker then
			xpFrame.uptimeTicker = C_Timer.NewTicker(1, CheckUptimeNotification)
		end
	elseif event == "PLAYER_XP_UPDATE" then
		UpdateXP()
	elseif event == "PLAYER_FLAGS_CHANGED" then
		GetPVPStatus()
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		if delayTimer then
			delayTimer:Cancel()
		end

		delayTimer = C_Timer.NewTimer(0.5, function()
			UpdateXP()
		end)
	elseif event == "PLAYER_LOGOUT" then
		SaveProgress()
	end
end)
xpFrame:RegisterEvent("PLAYER_LOGIN")
xpFrame:RegisterEvent("PLAYER_XP_UPDATE")
xpFrame:RegisterEvent("PLAYER_LOGOUT")
xpFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
xpFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

-- Periodic updates for uptime only
xpFrame:SetScript("OnUpdate", function(self, elapsed)
	local uptime = GetTime() - addonStartTime
	uptimeText:SetText("Uptime: " .. FormatTime(uptime))
end)

-- Enable the frame to be moved by dragging
xpFrame:SetMovable(true)
xpFrame:EnableMouse(true)
xpFrame:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		self:StartMoving()
	elseif button == "RightButton" then
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT")
	end
end)
xpFrame:SetScript("OnMouseUp", function(self, button)
	self:StopMovingOrSizing()
end)
