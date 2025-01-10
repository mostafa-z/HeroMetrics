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

local xpProgressText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
xpProgressText:SetFont(xpProgressText:GetFont(), 18)
xpProgressText:SetPoint("TOP", xpText, "BOTTOM", 0, -10)

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
	local textWidth = math.max(xpText:GetStringWidth(), xpProgressText:GetStringWidth(), uptimeText:GetStringWidth())
	local textHeight = xpText:GetStringHeight() + xpProgressText:GetStringHeight() + uptimeText:GetStringHeight()

	textHeight = textHeight + 50  -- Adjust padding as needed

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
		previousXPChange = lastXPChange
		lastXPChange = currentXP - lastKnownXP
		iterationsNeeded = lastXPChange > 0 and math.ceil(xpRemaining / lastXPChange) or 0

		-- Save progress data
		SaveProgress()
	end

	-- Update the displayed XP text
	if level < maxLevel then
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s\n\niLevel: %.2f\n\nTo level: %d\nXP Remaining: %d\nPrev XP: %d\nLast XP: %d\nIterations: %d",
			UnitName("player"), itemLevel, level + 1, xpRemaining, previousXPChange, lastXPChange, iterationsNeeded
		))
		xpProgressText:SetText("XP Progress: " .. xpPercent .. "%")
	else
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s - %d\n\niLevel: %.2f",
			UnitName("player"), level, itemLevel
		))
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

-- Event handler for XP updates and login, ticker once
xpFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		LoadProgress()
		UpdateXP()
		if not xpFrame.uptimeTicker then
			xpFrame.uptimeTicker = C_Timer.NewTicker(1, CheckUptimeNotification)
		end
	elseif event == "PLAYER_XP_UPDATE" then
		UpdateXP()
	elseif event == "PLAYER_LOGOUT" then
		SaveProgress()
	end
end)
xpFrame:RegisterEvent("PLAYER_LOGIN")
xpFrame:RegisterEvent("PLAYER_XP_UPDATE")
xpFrame:RegisterEvent("PLAYER_LOGOUT")

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
	end
end)
xpFrame:SetScript("OnMouseUp", function(self, button)
	self:StopMovingOrSizing()
end)
