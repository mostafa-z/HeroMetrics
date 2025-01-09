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

local uptimeText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
uptimeText:SetFont(uptimeText:GetFont(), 12)
uptimeText:SetPoint("BOTTOM", xpFrame, "BOTTOM", 0, 10)

-- Initialize variables
local lastXP = UnitXP("player")
local startTime = GetTime()
local soundInterval = 25
local soundPlayed = false
local sideSpacing = 10  -- Adjustable side spacing

-- Function to adjust frame size based on text content
local function AdjustFrameSize()
	local textWidth = math.max(xpText:GetStringWidth())
	local textHeight = xpText:GetStringHeight()

	textHeight = textHeight + 40  -- Adjust padding as needed

	xpFrame:SetSize(textWidth + 2 * sideSpacing, textHeight)
end

AdjustFrameSize()

-- Function to calculate uptime
local function CalculateUptime()
	local uptime = GetTime() - startTime
	local hours = math.floor(uptime / 3600)
	local minutes = math.floor((uptime % 3600) / 60)
	local secs = math.floor(uptime % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Function to update the XP text
local function UpdateXP()
	local maxLevel = GetMaxPlayerLevel()
	local level = UnitLevel("player")
	local currentXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	local xpPercent = math.floor((currentXP / maxXP) * 100)
	local xpChange = currentXP - lastXP
	local xpRemaining = maxXP - currentXP

	-- Calculate iterations needed
	local iterationsNeeded = xpChange > 0 and math.ceil(xpRemaining / xpChange) or 0

	-- Update the displayed XP text
	if level < maxLevel then
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s\nItem Level: %.2f\n\nTo achieve level: %d\nXP Remaining: %d\nXP Percent: %d%%\nLast XP Change: %d\nIterations Remaining: %d",
			UnitName("player"), itemLevel, level + 1, xpRemaining, xpPercent, xpChange, iterationsNeeded
		))
	else
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s - Level: %d\nItem Level: %.2f",
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

	-- Update lastXP for next calculation
	lastXP = currentXP
	
	AdjustFrameSize()
end

-- Event handler for XP updates and login
xpFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" or event == "PLAYER_XP_UPDATE" then
		UpdateXP()
	end
end)
xpFrame:RegisterEvent("PLAYER_XP_UPDATE")
xpFrame:RegisterEvent("PLAYER_LOGIN")

-- Periodic updates for uptime only
xpFrame:SetScript("OnUpdate", function(self, elapsed)
	uptimeText:SetText("Uptime: " .. CalculateUptime())
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
