-- /console scriptErrors 1

local addonName, HeroMetrics = ...
local xpFrame = CreateFrame("Frame", "HeroMetrics", UIParent, "BackdropTemplate")

xpFrame:SetSize(200, 100)
xpFrame:SetPoint("TOPLEFT")
xpFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
xpFrame:SetBackdropColor(0, 0, 0, 1)

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

local playtimeText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
playtimeText:SetFont(playtimeText:GetFont(), 12)
playtimeText:SetTextColor(0.5, 0.5, 1, 0.8) -- Light blue with lower alpha to differentiate from uptime
playtimeText:SetPoint("TOP", uptimeText, "BOTTOM", 0, -5)

local customXPText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
customXPText:SetFont(customXPText:GetFont(), 14)
customXPText:SetPoint("BOTTOM", playtimeText, "BOTTOM", 0, -30)
customXPText:Hide()

local customXPTimerText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
customXPTimerText:SetFont(customXPTimerText:GetFont(), 12)
customXPTimerText:SetPoint("TOP", customXPText, "BOTTOM", 0, -5)
customXPTimerText:Hide()

local notificationText = UIParent:CreateFontString(nil, "OVERLAY")
notificationText:SetFont("Interface\\AddOns\\HeroMetrics\\fonts\\MagistralTTBold.TTF", 24, "OUTLINE")
notificationText:SetPoint("CENTER", 0, 0)
notificationText:SetTextColor(1, 1, 0)  --yellow
notificationText:Hide()

-- XP Progress Bar
local xpProgressBar = CreateFrame("Frame", "HeroMetricsXPBar", UIParent, "BackdropTemplate")

xpProgressBar:SetSize(200, 20)
xpProgressBar:SetPoint("TOP", xpFrame, "BOTTOM", 0, -10)
xpProgressBar:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
xpProgressBar:SetBackdropColor(0, 0, 0, 0.8)

local xpFill = xpProgressBar:CreateTexture(nil, "OVERLAY")
xpFill:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
xpFill:SetPoint("LEFT", xpProgressBar, "LEFT", 3, 0)
xpFill:SetHeight(14)
xpFill:SetVertexColor(38/255, 100/255, 245/255, 1) -- HEX #2664F5 converted to RGB

local xpPredictFill = xpProgressBar:CreateTexture(nil, "OVERLAY")
xpPredictFill:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
xpPredictFill:SetPoint("LEFT", xpFill, "RIGHT", 0, 0)
xpPredictFill:SetHeight(14)
xpPredictFill:SetVertexColor(245/255, 183/255, 38/255, 1) -- Solid orange for predicted XP

local xpOverflowIndicator = xpProgressBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
xpOverflowIndicator:SetPoint("RIGHT", xpProgressBar, "RIGHT", 10, 0)
xpOverflowIndicator:SetText("+")
xpOverflowIndicator:SetTextColor(245/255, 183/255, 38/255, 1) -- Orange color like prediction XP
xpOverflowIndicator:Hide() -- Hidden by default

-- Time Goal Progress Bar
local timeGoalFrame = CreateFrame("Frame", "HeroMetricsTimeGoal", UIParent, "BackdropTemplate")
timeGoalFrame:SetSize(200, 20)
timeGoalFrame:SetPoint("TOP", xpProgressBar, "BOTTOM", 0, -10)
timeGoalFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
timeGoalFrame:SetBackdropColor(0, 0, 0, 0.8)
timeGoalFrame:Hide()

local timeGoalFill = timeGoalFrame:CreateTexture(nil, "OVERLAY")
timeGoalFill:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
timeGoalFill:SetPoint("LEFT", timeGoalFrame, "LEFT", 3, 0)
timeGoalFill:SetHeight(14)
timeGoalFill:SetVertexColor(0, 1, 0, 1) -- Start with green

local timeGoalText = timeGoalFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timeGoalText:SetPoint("CENTER", timeGoalFrame, "CENTER", 0, 0)
timeGoalText:SetText("Time Goal: Loading ...")

local timeGoal, timeOver = 0, 0
local trackingTimeGoal = false
local elapsedTime = 0
local sessionStart = nil
local timeGoalTicker = nil

local lastXP = 0
local startTime = GetTime()
local lastXPChange = 0
local previousXPChange = 0
local iterationsNeeded = 0
local lastKnownXP = 0
local soundInterval = 25
local soundPlayed = false
local sideSpacing = 10

local addonStartTime = GetTime()
local lastNotificationTime = 0
local lastPlaytimeUpdate = 0 -- Track last update time

local lastLevelTime = lastLevelTime or 0
local iterationsPassedCurrent = 0
local iterationsPassedLast = 0

local trackingXP = false
local customXPStart = 0

local customXPStartTime = 0
local customXPTimer = nil

-- Tooltip used Var
local initialItemLevels = {}
local previousItemLevels = {}
local sessionStarted = false
local upgradedItems = {}

local goldNotified = false

local lowHealthThreshold = 0.5  -- 50%
local criticalHealthThreshold = 0.3  -- 30%
local deadThreshold = 0.01 -- 1%

local function IsMaxLevel()
	return UnitLevel("player") == GetMaxPlayerLevel()
end

local function DBinit()
    HeroMetricsDB = HeroMetricsDB or {}  -- Ensure the database exists
    HeroMetricsDB.xpBarEnabled = HeroMetricsDB.xpBarEnabled or false  -- Default to false if not set
    HeroMetricsDB.userInteract = HeroMetricsDB.userInteract or false

    -- Ensure xpProgressBar exists before modifying it
    if not xpProgressBar then return end

    -- Hide XP bar for max-level characters but don't override DB setting
    if IsMaxLevel() then
        xpProgressBar:Hide()
        return
    end

    -- Apply saved XP bar state
    if HeroMetricsDB.xpBarEnabled then
        xpProgressBar:Show()
    else
        xpProgressBar:Hide()
    end
end

local function CreateCharacterListFrame()
    if HeroMetricsFrame then
        HeroMetricsFrame:Show()
        return
    end

    local frame = CreateFrame("Frame", "HeroMetricsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 400)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("HeroMetrics")

    -- ✨ Close Button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    frame.content = content
end

local function SortCharacters()
    local list = {}

    for key, data in pairs(HeroMetricsDB) do
        if type(data) == "table" and data.level and data.ilevel and data.class then
            table.insert(list, {key = key, level = data.level, ilevel = data.ilevel, class = data.class})
        end
    end

    table.sort(list, function(a, b)
        return a.ilevel > b.ilevel -- highest ilevel first
    end)

    return list
end

local function GetColorForCharacter(class)
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        return "|c" .. RAID_CLASS_COLORS[class].colorStr
    else
        return "|cffffffff" -- fallback white
    end
end

local function ShowCharacterList()
    CreateCharacterListFrame()

    local content = HeroMetricsFrame.content
    for i, child in ipairs({content:GetChildren()}) do
        child:Hide()
    end

    local list = SortCharacters()

    local offsetY = -10
	for i, data in ipairs(list) do
		local color = GetColorForCharacter(data.class)

		local line = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		line:SetPoint("TOPLEFT", 0, offsetY)
		line:SetText(string.format("%d. %s%s|r - Level: %d - iLvl: %d", i, color, data.key, data.level, data.ilevel))
		offsetY = offsetY - 20
	end

    content:SetHeight(-offsetY + 20)
end

local function CreateMinimapButton()
    if HeroMetricsMinimapButton then
        return
    end

    local button = CreateFrame("Button", "HeroMetricsMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, 5)

    button:SetNormalTexture("Interface\\Icons\\Ability_Hunter_MasterMarksman") -- TEMP icon
    button:GetNormalTexture():SetAllPoints()

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffffff00HeroMetrics|r")
        GameTooltip:AddLine("Click to open your stats", 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(self, button)
        ShowCharacterList()
    end)
end

local function AdjustFrameSize()
	local textWidth = math.max(
		xpText:GetStringWidth(),
		iterationText:GetStringWidth(),
		xpProgressText:GetStringWidth(),
		uptimeText:GetStringWidth(),
		playtimeText:GetStringWidth(),
		(customXPText:IsShown() and customXPText:GetStringWidth() or 0),
		(customXPTimerText:IsShown() and customXPTimerText:GetStringWidth() or 0)
	)

	local textHeight = xpText:GetStringHeight() +
		iterationText:GetStringHeight() +
		xpProgressText:GetStringHeight() +
		uptimeText:GetStringHeight() +
		playtimeText:GetStringHeight()

	if customXPText:IsShown() then
		textHeight = textHeight + customXPText:GetStringHeight() + 5
	end

	if customXPTimerText:IsShown() then
		textHeight = textHeight + customXPTimerText:GetStringHeight() + 5
	end

	if xpProgressBar:IsShown() then
		xpProgressBar:SetWidth(textWidth)
	end

	textHeight = textHeight + 60
	xpFrame:SetSize(textWidth + 2 * sideSpacing, textHeight)
end

AdjustFrameSize()

local function AdjustTimeGoalFrameSize()
	local barWidth = xpProgressBar:GetWidth()
	local textWidth = timeGoalText:GetWidth()

	if textWidth > barWidth then
		local textWidth = timeGoalText:GetWidth()
		timeGoalFrame:SetWidth(textWidth + 20)
	else
        local barWidth = xpProgressBar:GetWidth()
        timeGoalFrame:SetWidth(barWidth)
	end
end

--AdjustTimeGoalFrameSize()

local function FormatTime(uptime)
	local hours = math.floor(uptime / 3600)
	local minutes = math.floor((uptime % 3600) / 60)
	local secs = math.floor(uptime % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function ShowNotificationMessage(message, duration, fontSize, xOffset, yOffset)
	notificationText:SetText(message)
	notificationText:SetFont("Interface\\AddOns\\HeroMetrics\\fonts\\MagistralTTBold.TTF", fontSize or 24, "OUTLINE")

	notificationText:ClearAllPoints()
	notificationText:SetPoint("CENTER", UIParent, "CENTER", xOffset or 0, yOffset or 0)

	notificationText:SetScript("OnMouseDown", function()
		notificationText:Hide()
	end)

	notificationText:Show()
	C_Timer.After(duration or 3, function()
		notificationText:Hide()
	end)
end

local function NotifyNewMail()
	if HasNewMail() then
		ShowNotificationMessage("You Have New Mail!", 10, 36, 0, 200) -- Customize as needed: message, duration, font size, xOffset, yOffset
		print("|TInterface\\Minimap\\Tracking\\Mailbox:16:16|t |cffffff00[HeroMetrics]|r |cff00ff00You have new mail!|r")
		notificationText:SetTextColor(1, 1, 0) -- Yellow
		PlaySound(SOUNDKIT.PVP_THROUGH_QUEUE, "Master")
	end
end

local function CheckUptimeNotification()
	local uptime = GetTime() - addonStartTime

	if uptime >= lastNotificationTime + 3600 then
		lastNotificationTime = uptime
		ShowNotificationMessage("Uptime Alert: " .. FormatTime(uptime), 5, 48, 0, 200)
		print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16|t |cffffff00[HeroMetrics]|r |cff00ffffUptime Alert!|r |cffffffaaYou've been online for:|r |cff88ff88 " .. FormatTime(uptime) .. " |r")
		notificationText:SetTextColor(1, 1, 0) -- Yellow
		PlaySound(SOUNDKIT.READY_CHECK, "Master")
	end
end

local function CheckGoldNotification()
    if goldNotified then return end  -- Prevent duplicate notifications

    local goldThreshold = 5000
    local gold = GetMoney() / 10000

    if gold > goldThreshold then
        local goldMessage = string.format("|cffffd700[RICH ALERT]|r |cff00ff00You have %d gold!|r", gold)

        print(goldMessage)

        RaidNotice_AddMessage(RaidWarningFrame, goldMessage, ChatTypeInfo["RAID_WARNING"])

        goldNotified = true
    end
end

local function UpdateHealthAlert()
	local health = UnitHealth("player")
	local maxHealth = UnitHealthMax("player")
	local healthPercent = health / maxHealth

	if healthPercent <= deadThreshold then
		notificationText:Hide()
	elseif healthPercent <= criticalHealthThreshold then
		ShowNotificationMessage("Critical Health!", 3, 24, 0, 0)
		notificationText:SetTextColor(1, 0, 0)  -- Red for critical
	elseif healthPercent <= lowHealthThreshold then
		ShowNotificationMessage("Low Health!", 3, 24, 0, 0)
		notificationText:SetTextColor(1, 0.5, 0)  -- Orange for low health
	else
		notificationText:Hide()
	end
end

local function GetDateKey()
    return date("%Y-%m-%d")
end

local function FormatPlaytime(seconds)
    if seconds < 60 then
        return string.format("%d sec", seconds)
    elseif seconds < 3600 then
        return string.format("%d min", math.floor(seconds / 60))
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format("%d hr %d min", hours, minutes)
    end
end

local function GetTodayPlaytime()
    local dateKey = GetDateKey()
    local totalTime = HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[dateKey] and HeroMetricsDB.sessionTimes[dateKey].total or 0

    -- Add real-time session uptime
    local sessionStartKey = "sessionStart"
    if HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[dateKey] and HeroMetricsDB.sessionTimes[dateKey][sessionStartKey] then
        local sessionStart = HeroMetricsDB.sessionTimes[dateKey][sessionStartKey]
        totalTime = totalTime + (GetTime() - sessionStart)
    end

    return FormatPlaytime(totalTime)
end

local function UpdatePlaytimeDisplay()
    local totalTime = HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[GetDateKey()] and HeroMetricsDB.sessionTimes[GetDateKey()].total or 0

    -- Add real-time session uptime
    local sessionStartKey = "sessionStart"
    if HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[GetDateKey()] and HeroMetricsDB.sessionTimes[GetDateKey()][sessionStartKey] then
        local sessionStart = HeroMetricsDB.sessionTimes[GetDateKey()][sessionStartKey]
        totalTime = totalTime + (GetTime() - sessionStart)
    end

    -- Convert to hours
    local hours = totalTime / 3600

    -- Determine font size and color
    local fontSize, r, g, b
    if hours < 1 then
        fontSize, r, g, b = 12, 0.2, 1, 0.2  -- Green
    elseif hours < 3 then
        fontSize, r, g, b = 14, 1, 1, 0  -- Yellow
    elseif hours < 6 then
        fontSize, r, g, b = 16, 1, 0.5, 0  -- Orange
    else
        fontSize, r, g, b = 18, 1, 0, 0  -- Red
    end

    -- Apply changes
    playtimeText:SetFont(playtimeText:GetFont(), fontSize)
    playtimeText:SetTextColor(r, g, b, 1)
    playtimeText:SetText("\nToday:" .. FormatPlaytime(totalTime))

    AdjustFrameSize()
end

local function StartSessionTracking()
    local dateKey = GetDateKey()
    -- Removed character-specific tracking
    local sessionStartKey = "sessionStart"

    HeroMetricsDB.sessionTimes = HeroMetricsDB.sessionTimes or {}
    HeroMetricsDB.sessionTimes[dateKey] = HeroMetricsDB.sessionTimes[dateKey] or {}
    HeroMetricsDB.sessionTimes[dateKey][sessionStartKey] = GetTime()
end

local function SaveSessionTime()
    local dateKey = GetDateKey()
    -- Removed character-specific tracking
    local sessionStartKey = "sessionStart"

    if HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[dateKey] and HeroMetricsDB.sessionTimes[dateKey][sessionStartKey] then
        local sessionStart = HeroMetricsDB.sessionTimes[dateKey][sessionStartKey]
        local sessionDuration = GetTime() - sessionStart
        HeroMetricsDB.sessionTimes[dateKey].total = (HeroMetricsDB.sessionTimes[dateKey].total or 0) + sessionDuration
        -- No need to remove sessionStart, as it applies to all characters
    end
end

local function GetCharacterKey()
	return UnitName("player") .. "-" .. GetRealmName()
end

local function SaveProgress()
	local characterKey = GetCharacterKey()
	local currentLevel = UnitLevel("player")
	HeroMetricsDB[characterKey] = HeroMetricsDB[characterKey] or {}


	-- Save general character info
	if HeroMetricsDB[characterKey].level ~= currentLevel then
		print("Level mismatch detected. Updating level from:", HeroMetricsDB[characterKey].level or "nil", "to:", currentLevel)
		HeroMetricsDB[characterKey].level = nil  -- optional, not strictly needed
		HeroMetricsDB[characterKey].level = currentLevel
	--else
	--	print("Level matches:", currentLevel)
	end

	HeroMetricsDB[characterKey].class = select(2, UnitClass("player"))
	HeroMetricsDB[characterKey].ilevel = cachedItemLevel

	HeroMetricsDB[characterKey].lastXPChange = lastXPChange
	HeroMetricsDB[characterKey].previousXPChange = previousXPChange
	HeroMetricsDB[characterKey].iterationsNeeded = iterationsNeeded
	HeroMetricsDB[characterKey].lastKnownXP = lastKnownXP

	-- Save custom XP tracking state
	HeroMetricsDB[characterKey].customXPAccumulated = customXPAccumulated
	HeroMetricsDB[characterKey].userInteract = userInteract

	HeroMetricsDB[characterKey].xpBarEnabled = xpBarEnabled
end

local function LoadProgress()
	local characterKey = GetCharacterKey()
	local data = HeroMetricsDB[characterKey]
	if data then
		lastXPChange = data.lastXPChange or 0
		previousXPChange = data.previousXPChange or 0
		iterationsNeeded = data.iterationsNeeded or 0
		lastKnownXP = data.lastKnownXP

		-- Load custom XP tracking state
		customXPAccumulated = data.customXPAccumulated or 0
		userInteract = data and data.userInteract or false

		xpBarEnabled = data and data.xpBarEnabled or false
	else
		lastXPChange = 0
		previousXPChange = 0
		iterationsNeeded = 0
		lastKnownXP = lastKnownXP

		customXPAccumulated = 0
		userInteract = false

		xpBarEnabled = false
	end
end

local function CachedILevel()
    local _, avgItemLevel = GetAverageItemLevel()
    cachedItemLevel = math.floor(avgItemLevel or 0)
end

local function ToggleCustomXPTracking()
	local characterKey = GetCharacterKey()

	if not trackingXP then
		customXPStart = UnitXP("player")
		customXPAccumulated = 0
		customXPStartTime = GetTime()
		trackingXP = true

		if not HeroMetricsDB[characterKey] then
			HeroMetricsDB[characterKey] = {}
		end

		-- Restore last saved XP if available
		customXPAccumulated = HeroMetricsDB[characterKey].customXPAccumulated or 0

		if IsMaxLevel() then
			customXPText:SetText("Timer Start")
			customXPText:Show()

			customXPTimerText:SetText("00:00:00")
			customXPTimerText:Show()
		else
			if HeroMetricsDB[characterKey].userInteract then
				customXPText:SetText("Tracking XP: 0")
				HeroMetricsDB[characterKey].userInteract = false
			else
				customXPText:SetText("Tracking XP: " .. customXPAccumulated)
			end
			customXPText:Show()

			customXPTimerText:SetText("Time: 00:00:00")
			customXPTimerText:Show()
		end

		-- Start timer
		if customXPTimer then
			customXPTimer:Cancel()
		end
		customXPTimer = C_Timer.NewTicker(1, function()
			local elapsed = GetTime() - customXPStartTime
			if IsMaxLevel() then
				customXPTimerText:SetText(FormatTime(elapsed))
			else
				customXPTimerText:SetText("Time: " .. FormatTime(elapsed))
			end
		end)

		AdjustFrameSize()
	else
		trackingXP = false

		local currentXP = UnitXP("player")
		local maxXP = UnitXPMax("player")
		local xpRemaining = maxXP - currentXP

		-- Stop timer
		if customXPTimer then
			customXPTimer:Cancel()
			customXPTimer = nil
		end

		if IsMaxLevel() then
			customXPText:SetText("Timer Stop")
			customXPText:Show()
		elseif customXPAccumulated > 0 then
			customXPText:SetText(string.format("XP Gained: %d - |cff00ffff%d|r", customXPAccumulated, math.ceil(xpRemaining / customXPAccumulated)))
		else
			customXPText:SetText("No XP Gained")
		end

		-- Reset customXPAccumulated after displaying the result
		if customXPAccumulated > 0 then
			-- Final progress result displayed, reset after completion
			HeroMetricsDB[characterKey].customXPAccumulated = 0
		end

		HeroMetricsDB[characterKey].userInteract = true

		AdjustFrameSize()
	end
end

local function UpdateCustomXPTracking()
	if trackingXP and not IsMaxLevel() then
		local currentXP = UnitXP("player")

		-- Calculate XP gained considering level-ups
		local gainedXP = currentXP - customXPStart
		if gainedXP < 0 then  -- Level-up detected (XP reset)
			local maxXP = UnitXPMax("player")
			gainedXP = (maxXP - customXPStart) + currentXP  -- Carry over XP gained before reset
		end

		customXPAccumulated = customXPAccumulated + gainedXP
		customXPStart = currentXP  -- Update tracking start to prevent double-counting

		customXPText:SetText("XP Gaining: " .. customXPAccumulated)
	elseif trackingXP and IsMaxLevel() then
		trackingXP = false

		customXPText:Hide()
		customXPTimerText:Show()
		AdjustFrameSize()
	end
end

local function ResetCustomXPTracking()
	customXPText:Hide()
	customXPTimerText:Hide()
	trackingXP = false
	customXPAccumulated = 0

	local characterKey = GetCharacterKey()
	if HeroMetricsDB[characterKey] then
		HeroMetricsDB[characterKey].customXPAccumulated = 0
		HeroMetricsDB[characterKey].trackingXP = false
	end

	if customXPTimer then
		customXPTimer:Cancel()
		customXPTimer = nil
	end

	AdjustFrameSize()
end

local function UpdateXPBar()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local xpPercent = currentXP / maxXP
    local predictedXP = lastXPChange > 0 and (lastXPChange / maxXP) or 0

    local barWidth = xpProgressBar:GetWidth() - 7

    -- Ensure the predicted XP bar does not exceed the remaining width
    local xpFillWidth = barWidth * xpPercent
    local remainingWidth = barWidth - xpFillWidth
    local xpPredictWidth = math.min(barWidth * predictedXP, remainingWidth)

    xpFill:SetWidth(xpFillWidth)
    xpPredictFill:SetWidth(xpPredictWidth)
    xpPredictFill:SetShown(predictedXP > 0)

    -- Show overflow indicator if predicted XP exceeds remaining space
    if (barWidth * predictedXP) > remainingWidth then
        xpOverflowIndicator:Show()
    else
        xpOverflowIndicator:Hide()
    end
end

local function ToggleXPBar()
    if IsMaxLevel() then
        xpProgressBar:Hide()
        HeroMetricsDB.xpBarEnabled = false
        return
    end

    if xpProgressBar:IsShown() then
        xpProgressBar:Hide()
		HeroMetricsDB.xpBarEnabled = false
    else
        xpProgressBar:Show()
		HeroMetricsDB.xpBarEnabled = true
        UpdateXPBar()
    end
end

local function SaveTimeGoalProgress()
    local characterKey = UnitName("player") .. "-" .. GetRealmName()
    HeroMetricsDB[characterKey] = HeroMetricsDB[characterKey] or {}
    HeroMetricsDB[characterKey].timeGoal = timeGoal
    HeroMetricsDB[characterKey].timeOver = timeOver
    HeroMetricsDB[characterKey].elapsedTime = elapsedTime + (sessionStart and (GetTime() - sessionStart) or 0)
    HeroMetricsDB[characterKey].trackingTimeGoal = trackingTimeGoal
end

local function UpdateTimeGoal()
    if not trackingTimeGoal then return end

    local totalElapsed = elapsedTime + (sessionStart and (GetTime() - sessionStart) or 0)
    local goalTime = timeGoal * 60
    local maxTime = (timeGoal + timeOver) * 60

    if totalElapsed > goalTime then
        timeGoalText:SetText(string.format("Time Goal: %d min - %d min over", timeGoal, math.floor((totalElapsed - goalTime) / 60)))
    else
        timeGoalText:SetText(string.format("Time Goal: %d:%02d / %d", math.floor(totalElapsed / 60), totalElapsed % 60, timeGoal))
    end

    -- Update progress bar
    local barWidth = timeGoalFrame:GetWidth() - 6
    local percent = totalElapsed / maxTime
    timeGoalFill:SetWidth(math.min(barWidth * percent, barWidth))

    -- Color change based on progress
    if percent < 0.5 then
        timeGoalFill:SetVertexColor(0, 1, 0, 1) -- Green
    elseif percent < 0.8 then
        timeGoalFill:SetVertexColor(1, 1, 0, 1) -- Yellow
    elseif percent < 0.95 then
        timeGoalFill:SetVertexColor(1, 0.5, 0, 1) -- Orange
    else
        timeGoalFill:SetVertexColor(1, 0, 0, 1) -- Red
    end

    -- Play warning at goal time
    if totalElapsed >= goalTime and totalElapsed < (goalTime + 1) then
        PlaySound(SOUNDKIT.RAID_WARNING)
        RaidNotice_AddMessage(RaidBossEmoteFrame, "Time Goal Reached!", ChatTypeInfo["RAID_WARNING"])
    end

    SaveTimeGoalProgress()
	AdjustTimeGoalFrameSize()
end

local function StartTimeGoal(goal, over, loadedElapsed)
    timeGoal = tonumber(goal) or 0
    timeOver = tonumber(over) or 0
    elapsedTime = loadedElapsed or 0 -- Restore previous elapsed time
    sessionStart = GetTime()
    trackingTimeGoal = true
    timeGoalFrame:Show()

    if timeGoalTicker then
        timeGoalTicker:Cancel()
    end
    timeGoalTicker = C_Timer.NewTicker(60, SaveTimeGoalProgress) -- Save progress every minute
    C_Timer.NewTicker(1, UpdateTimeGoal)
    SaveTimeGoalProgress()
end

local function LoadTimeGoalProgress()
    local characterKey = UnitName("player") .. "-" .. GetRealmName()
    local data = HeroMetricsDB[characterKey]
    if data and data.trackingTimeGoal then
        StartTimeGoal(data.timeGoal or 0, data.timeOver or 0, data.elapsedTime or 0)
    end
end

local function CancelTimeGoal()
    trackingTimeGoal = false
    elapsedTime = elapsedTime + (sessionStart and (GetTime() - sessionStart) or 0)
    sessionStart = nil
    timeGoalFrame:Hide()
    if timeGoalTicker then
        timeGoalTicker:Cancel()
        timeGoalTicker = nil
    end
    SaveTimeGoalProgress()
end

local function perXPiteration(xpChange, xpRemaining)
	return xpChange > 0 and math.ceil(xpRemaining / xpChange) or 0
end

local function UpdateXP()
	local maxLevel = GetMaxPlayerLevel()
	local level = UnitLevel("player")
	local currentXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	local xpPercent = maxXP > 0 and math.floor((currentXP / maxXP) * 100) or 0
	local xpRemaining = maxXP - currentXP
	local restedXP = GetXPExhaustion() or 0

	if lastKnownXP and currentXP > lastKnownXP then
		if lastKnownXP == 0 then
			lastKnownXP = currentXP
		end
		previousXPChange = lastXPChange
		lastXPChange = currentXP - lastKnownXP
		iterationsNeeded = perXPiteration(lastXPChange, xpRemaining)

		iterationsPassedCurrent = iterationsPassedCurrent + 1

		SaveProgress()
	end

	local previousIterations = perXPiteration(previousXPChange, xpRemaining)
	local lastIterations = perXPiteration(lastXPChange, xpRemaining)

	if level < maxLevel then
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s\n\n" ..
			"|cffffcc00iLevel: %.2f|r\n\n" ..
			"|cffff9900To Level: %d|r\n" ..
			"|cffffcc00XP Remaining: %d|r\n" ..
			"|cff00ffffRested XP: %d (%.1f%%)|r\n\n" ..
			"|cffffcc00Prev XP: %d - %d|r\n" ..
			"|cffff9900Last XP: %d - %d|r",
			UnitName("player"), itemLevel, level + 1, xpRemaining,
			restedXP, (restedXP / maxXP) * 100,
			previousXPChange, previousIterations, lastXPChange, lastIterations
		))
		iterationText:SetText("|cff00ffffIterations: " .. iterationsNeeded .. "|r")
		xpProgressText:SetText("|cffffcc00XP Progress: " .. xpPercent .. "%|r")
	else
		local _, itemLevel = GetAverageItemLevel()
		xpText:SetText(string.format(
			"%s - %d\n\n" ..
			"|cffffcc00iLevel: %.2f|r",
			UnitName("player"), level, itemLevel
		))
		iterationText:SetText("")
		xpProgressText:SetText("")
	end

	if iterationsNeeded > 0 and iterationsNeeded % soundInterval == 0 and not soundPlayed then
		PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3)
		soundPlayed = true
	elseif iterationsNeeded % soundInterval ~= 0 then
		soundPlayed = false
	end

	lastKnownXP = currentXP
	
	AdjustFrameSize()

    -- Call UpdateXPBar to update the XP bar with the latest values
    UpdateXPBar()
end

local function SaveLevelUpData(level, timeSpent, zone)
    local characterKey = GetCharacterKey()
    if type(HeroMetricsDB[characterKey]) ~= "table" then
        HeroMetricsDB[characterKey] = {}  -- Ensure it's always a table
    end
    HeroMetricsDB[characterKey][level] = {
        ["time_to_level"] = timeSpent,
        ["zone"] = zone
    }
end

local function GetLevelUpRank(level, timeSpent)
    local times = {}

    -- Collect all times from other characters
	for char, data in pairs(HeroMetricsDB) do
		if type(data) == "table" and data[level] and type(data[level]) == "table" and data[level].time_to_level then
			table.insert(times, data[level].time_to_level)
		end
	end

    -- Sort times (fastest first)
    table.sort(times)

    -- Find the rank of the current time
    local rank = 1
	local nextTime = nil  -- This will hold the next higher time if available

    for i, t in ipairs(times) do
        if timeSpent > t then
            rank = i + 1
			nextTime = t  -- Update nextTime to the current time
        else
            break
        end
    end

    local rankTimeDifference = nil
    if nextTime then
        rankTimeDifference = nextTime - timeSpent
    end

    -- Format rank text
    local total = #times
    return rank, total, rankTimeDifference
end


local function ShowLevelUpStats()
    local level = UnitLevel("player")
	local zone = GetZoneText()

    lastLevelTimeSpent = GetTime() - startTime
    startTime = GetTime() -- Reset for next level

	SaveLevelUpData(level, lastLevelTimeSpent, zone)

    iterationsPassedLast = iterationsPassedLast or 0  -- Ensure it's not nil
    local iterationDifference = iterationsPassedCurrent - iterationsPassedLast

    iterationsPassedLast = iterationsPassedCurrent
    iterationsPassedCurrent = 0  -- Reset for next level

    local timeSpent = math.floor(lastLevelTimeSpent / 60)  -- Convert to minutes
	local timeSpentSeconds = lastLevelTimeSpent % 60  -- Remaining seconds
    local timeDifferencePercent = lastLevelTime > 0 and math.floor(((lastLevelTimeSpent - lastLevelTime) / lastLevelTime) * 100) or 0

	local rankText, rankTotal, rankTimeDifference = GetLevelUpRank(level, lastLevelTimeSpent)

    print("|cffffd700=== Level Up Report! ===|r")
    print(string.format("|cff00ff00Level:|r |cffffff00%d|r", level + 1))

	if timeSpent > 0 then
		print(string.format("|cff00ff00Time Spent:|r |cffffff00%d min %d sec|r", timeSpent, timeSpentSeconds))
	else
		print(string.format("|cff00ff00Time Spent:|r |cffffff00%d sec|r", timeSpentSeconds))
	end

    --print(string.format("|cff00ff00Time Spent:|r |cffffff00%d min|r", timeSpent))
    print(string.format("|cff00ffffTime Difference:|r |cffffff00%d%%|r", timeDifferencePercent))
    print(string.format("|cff00ffffIterations Passed:|r |cffffff00%d|r", iterationsPassedLast))
    print(string.format("|cff00ffffIteration Difference:|r |cffffff00%d|r", iterationDifference))

	-- Prepare the output string for the player's current rank
	local rankMessage = string.format("|cff00ffffRank:|r |cffffff00%d/%d|r", rankText, rankTotal)

	-- Check if rankTimeDifference is valid and append it to the message if it's not nil
	if rankTimeDifference then
		rankMessage = rankMessage .. string.format(" (Need to improve by |cffff0000%.2f|r seconds)", rankTimeDifference)
	end

	-- Print the rank message
	print(rankMessage)

	RaidWarningFrame:ClearAllPoints()
	RaidWarningFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)

    -- Delayed Raid Messages
	C_Timer.After(5, function()
		local message = ""
		if timeSpent > 0 then
			message = string.format("|cff00ff00Time Spent:|r |cffffff00%d min %d sec|r", timeSpent, timeSpentSeconds)
		else
			message = string.format("|cff00ff00Time Spent:|r |cffffff00%d sec|r", timeSpentSeconds)
		end

		RaidNotice_AddMessage(RaidBossEmoteFrame, message, ChatTypeInfo["RAID_WARNING"])
	end)
--[[
    C_Timer.After(9, function()
        RaidNotice_AddMessage(RaidBossEmoteFrame, string.format("|cff00ffffTime Difference:|r |cffffff00%d%%|r", timeDifferencePercent), ChatTypeInfo["RAID_WARNING"])
    end)
    C_Timer.After(12, function()
        RaidNotice_AddMessage(RaidBossEmoteFrame, string.format("|cff00ff00Iterations Passed:|r |cffffff00%d|r", iterationsPassedLast), ChatTypeInfo["RAID_WARNING"])
    end)
    C_Timer.After(15, function()
        RaidNotice_AddMessage(RaidBossEmoteFrame, string.format("|cff00ffffIteration Difference:|r |cffffff00%d|r", iterationDifference), ChatTypeInfo["RAID_WARNING"])
    end)
]]
	C_Timer.After(8, function()
		-- Prepare the message for the raid warning, using the same logic as above
		local raidWarningMessage = string.format("|cff00ff00Rank:|r |cffffff00%d/%d|r", rankText, rankTotal)
		if rankTimeDifference then
			raidWarningMessage = raidWarningMessage .. string.format(" (Need to improve by |cffff0000%.2f|r seconds)", rankTimeDifference)
		end

		RaidNotice_AddMessage(RaidBossEmoteFrame, raidWarningMessage, ChatTypeInfo["RAID_WARNING"])
	end)

    lastLevelTime = lastLevelTimeSpent
end

local function GetPVPStatus()
	if C_PvP.IsWarModeDesired() then
		xpFrame:SetBackdropBorderColor(1, 0, 0, 1) --Red
	else
		xpFrame:SetBackdropBorderColor(1, 1, 1, 1) --White
	end
end

local function GetPlayerRaceClassAndSpec()
	local _, playerClass = UnitClass("player")
	local playerRace = UnitRace("player")
	local classColor = RAID_CLASS_COLORS[playerClass].colorStr

	local specIndex = GetSpecialization()
	local specID, specName = GetSpecializationInfo(specIndex)

	return playerRace, playerClass, classColor, specName, specID
end

local function AddRaceClassAndSpecToTooltip(tooltip)
	local race, class, classColor, spec, specID = GetPlayerRaceClassAndSpec()
	tooltip:AddLine("Character Statistics:", 1, 1, 1)
	tooltip:AddLine(string.format("|c%s%s %s %s - %d|r", classColor, race, spec, class, specID), 1, 1, 1)
end

local function GetRealmNameText()
	return "Realm: " .. GetRealmName()
end

local function GetZoneNameText()
	return "Current Zone: " .. GetZoneText()
end

local function FormatGold(copper)
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	copper = copper % 100
	return string.format("%d gold, %d silver, %d copper", gold, silver, copper)
end

local function GetCurrencyText()
	local currentGold = GetMoney()
	local gold = math.floor(currentGold / 10000)
	local silver = math.floor((currentGold % 10000) / 100)
	local copper = currentGold % 100

	-- Determine color for gold
	local goldChange = currentGold - startGold
	local color
	if goldChange > 0 then
		color = "|cff00ff00"
	elseif goldChange < 0 then
		color = "|cffff0000"
	else
		color = "|cffffffff"
	end

	return string.format("• Gold: %s%d, Silver: %d, Copper: %d|r", color, gold, silver, copper)
end

local function GetSessionGoldGained()
	local goldGained = GetMoney() - startGold
	return "• Session: " .. FormatGold(goldGained)
end

local function GetWarbandGold()
	local WBGold = GetMoneyString(C_Bank.FetchDepositedMoney(Enum.BankType.Account), true)
	return "• WarBand: " .. WBGold
end

local function AddCurrencyToTooltip(tooltip)
	tooltip:AddLine(" ")
	tooltip:AddLine("Currency:", 1, 1, 1)
	tooltip:AddLine(GetCurrencyText(), 1, 1, 1)
	tooltip:AddLine(GetSessionGoldGained(), 1, 1, 1)
	if IsAltKeyDown() then
		tooltip:AddLine(" ")
		tooltip:AddLine(GetWarbandGold(), 1, 1, 1)
	end
end

local function GetItemLevelDetails()
	local itemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
	return {
		itemLevel = itemLevel and string.format("%.2f", itemLevel) or "0.00",
		avgItemLevelEquipped = avgItemLevelEquipped and string.format("%.2f", avgItemLevelEquipped) or "0.00",
		avgItemLevelPvp = avgItemLevelPvp and string.format("%.2f", avgItemLevelPvp) or "0.00",
	}
end

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

local function GetMinMaxPlaytime()
    local minTime, maxTime = math.huge, 0  -- Start with extreme values
    local minDay, maxDay = nil, nil

    -- Loop through recorded days in DB
    if HeroMetricsDB.sessionTimes then
        for dateKey, data in pairs(HeroMetricsDB.sessionTimes) do
            if data.total and data.total > 0 then
                if data.total < minTime then
                    minTime = data.total
                    minDay = dateKey
                end
                if data.total > maxTime then
                    maxTime = data.total
                    maxDay = dateKey
                end
            end
        end
    end

    -- Convert to formatted text
    local minFormatted = (minDay and FormatPlaytime(minTime)) or "N/A"
    local maxFormatted = (maxDay and FormatPlaytime(maxTime)) or "N/A"

    return minFormatted, maxFormatted, minDay, maxDay
end

local function AddMinMaxPlaytimeToTooltip(tooltip)
	local minTime, maxTime, minDay, maxDay = GetMinMaxPlaytime()

	tooltip:AddLine(" ")
	tooltip:AddLine("Playtime Records:", 1, 1, 1)
    tooltip:AddLine("• Min Playtime: " .. minTime .. " (" .. (minDay or "N/A") .. ")", 0, 1, 0)
    tooltip:AddLine("• Max Playtime: " .. maxTime .. " (" .. (maxDay or "N/A") .. ")", 1, 0.5, 0)
end

local function GetWeeklyAveragePlaytime()
    local totalPlaytime, daysCounted = 0, 0
    local currentDate = time()

    if HeroMetricsDB.sessionTimes then
        for dateKey, data in pairs(HeroMetricsDB.sessionTimes) do
            local timestamp = time({year = tonumber(dateKey:sub(1, 4)), month = tonumber(dateKey:sub(6, 7)), day = tonumber(dateKey:sub(9, 10))})
            if currentDate - timestamp <= 7 * 86400 and data.total then
                totalPlaytime = totalPlaytime + data.total
                daysCounted = daysCounted + 1
            end
        end
    end

    if daysCounted > 0 then
        return FormatPlaytime(totalPlaytime / daysCounted)
    else
        return "N/A"
    end
end

local function AddGetWeeklyAveragePlaytimeToTooltip(tooltip)
	tooltip:AddLine(" ")
	tooltip:AddLine("• Weekly Avg: " .. GetWeeklyAveragePlaytime(), 0.5, 0.5, 1)
end

local function GetPlaytimeRank()
    local dateKey = GetDateKey()
    local todayTime = HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[dateKey] and HeroMetricsDB.sessionTimes[dateKey].total or 0
    local playtimes = {}

    if HeroMetricsDB.sessionTimes then
        for _, data in pairs(HeroMetricsDB.sessionTimes) do
            if data.total then table.insert(playtimes, data.total) end
        end
    end

    table.sort(playtimes, function(a, b) return a > b end) -- Sort descending
    for rank, time in ipairs(playtimes) do
        if time == todayTime then
            return rank, #playtimes
        end
    end
    return "N/A", #playtimes
end

local function AddGetPlaytimeRankToTooltip(tooltip)
	local rank, totalDays = GetPlaytimeRank()

	tooltip:AddLine(" ")
	tooltip:AddLine("• Today's Rank: " .. rank .. " / " .. totalDays, 0.8, 0.8, 0.8)
end

local function AddLevelCountsToTooltip(tooltip)
    if not HeroMetricsDB or type(HeroMetricsDB) ~= "table" then return end

    local levelCounts = {}
    local maxLevel = GetMaxLevelForLatestExpansion()
	local totalCharacters = 0
    local highThreshold = maxLevel - 10

    -- Count characters per level
    for _, data in pairs(HeroMetricsDB) do
        if type(data) == "table" and data.level then
            levelCounts[data.level] = (levelCounts[data.level] or 0) + 1
			totalCharacters = totalCharacters + 1
        end
    end

	if IsAltKeyDown() then
		tooltip:AddLine(" ")
		tooltip:AddLine("Characters (" .. totalCharacters .. " total):")
	end

    local sortedLevels = {}
    for level in pairs(levelCounts) do
        table.insert(sortedLevels, level)
    end
    table.sort(sortedLevels, function(a, b) return a > b end)

    for _, level in ipairs(sortedLevels) do
        local count = levelCounts[level]
        local color

        if level >= highThreshold then
            color = "|cff00ff00"
        elseif level >= (maxLevel / 2) then
            color = "|cffffff00"
        else
            color = "|cffff8000"
        end

		if IsAltKeyDown() then
			tooltip:AddLine(color .. "• Level " .. level .. ": " .. count .. "|r")  -- Add colored text
		end
    end
end

local function CountItemsByItemLevel()
    local itemLevelCounts = {}
    for i = 1, 19 do
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
            local itemLevel = C_Item.DoesItemExist(itemLoc) and C_Item.GetCurrentItemLevel(itemLoc) or 0
            local itemSlot = select(9, GetItemInfo(itemLink))
            if itemLevel and itemLevel > 0 then
                if not itemLevelCounts[itemLevel] then
                    itemLevelCounts[itemLevel] = { count = 0, items = {} }
                end
                itemLevelCounts[itemLevel].count = itemLevelCounts[itemLevel].count + 1
                table.insert(itemLevelCounts[itemLevel].items, {
                    link = itemLink,
                    slot = itemSlot and itemSlot:gsub("INVTYPE_", "") or "?"
                })
            end
        end
    end
    return itemLevelCounts
end

local function StoreInitialItemLevels()
    for i = 1, 19 do
        local itemLink = GetInventoryItemLink("player", i)
        local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
        local itemLevel = C_Item.DoesItemExist(itemLoc) and C_Item.GetCurrentItemLevel(itemLoc) or 0

        if itemLink then
            local itemName, _, itemQuality, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
            local itemColor = itemQuality and ITEM_QUALITY_COLORS[itemQuality] and ITEM_QUALITY_COLORS[itemQuality].hex or "|cffffffff"
            initialItemLevels[i] = {level = itemLevel, name = itemName, slot = itemEquipLoc, color = itemColor}
            previousItemLevels[i] = {level = itemLevel, name = itemName, slot = itemEquipLoc, color = itemColor}
        else
            initialItemLevels[i] = {level = 0, name = nil, slot = nil, color = "|cffffffff"}
            previousItemLevels[i] = {level = 0, name = nil, slot = nil, color = "|cffffffff"}
        end
    end
    sessionStarted = true
end

local function CalculateItemLevelDifference()
    local totalDifference = 0
    local numItems = 0
    local itemChangesDetected = false

    for i = 1, 19 do
        local itemLink = GetInventoryItemLink("player", i)
        local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
        local currentItemLevel = C_Item.DoesItemExist(itemLoc) and C_Item.GetCurrentItemLevel(itemLoc) or 0

        if itemLink then
            local itemName, _, itemQuality, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
            local itemColor = itemQuality and ITEM_QUALITY_COLORS[itemQuality] and ITEM_QUALITY_COLORS[itemQuality].hex or "|cffffffff"

            local initialItemLevel = initialItemLevels[i] and initialItemLevels[i].level or 0
            local previousItemLevel = previousItemLevels[i] and previousItemLevels[i].level or 0
            local previousItemName = previousItemLevels[i] and previousItemLevels[i].name or "Unknown"
            local previousItemColor = previousItemLevels[i] and previousItemLevels[i].color or "|cffffffff"

            local difference = currentItemLevel - initialItemLevel

            if currentItemLevel ~= previousItemLevel or itemName ~= previousItemName then
                table.insert(upgradedItems, {
                    slot = itemEquipLoc,
                    initialName = previousItemName,
                    initialLevel = previousItemLevel,
                    initialColor = previousItemColor,
                    currentName = itemName,
                    currentLevel = currentItemLevel,
                    currentColor = itemColor,
                    difference = currentItemLevel - previousItemLevel
                })
                previousItemLevels[i] = {
                    level = currentItemLevel,
                    name = itemName,
                    slot = itemEquipLoc,
                    color = itemColor
                }
                itemChangesDetected = true
            end

            totalDifference = totalDifference + difference
            numItems = numItems + 1
        end
    end

    return totalDifference, numItems, itemChangesDetected
end

local function AddItemLevelToTooltip(tooltip)
	if not IsControlKeyDown() then return end

    local itemLevelDetails = GetItemLevelDetails()

    tooltip:AddLine(" ")
    tooltip:AddLine(string.format("Current Item Level (Eqp): • %s", itemLevelDetails.avgItemLevelEquipped), 1, 1, 1)
    tooltip:AddLine(string.format("Current Item Level (PvE): • %s", itemLevelDetails.itemLevel), 1, 1, 1)
    tooltip:AddLine(string.format("Current Item Level (PvP): • %s", itemLevelDetails.avgItemLevelPvp), 1, 1, 1)

    -- Count and list item levels
    local itemLevelCounts = CountItemsByItemLevel()
    tooltip:AddLine(" ")
    tooltip:AddLine("Item Levels:", 0.0, 1.0, 0.0)

    local sortedItemLevels = {}
    for itemLevel in pairs(itemLevelCounts) do
        table.insert(sortedItemLevels, itemLevel)
    end
    table.sort(sortedItemLevels, function(a, b) return a > b end)

    for _, itemLevel in ipairs(sortedItemLevels) do
        local count = itemLevelCounts[itemLevel].count
        local items = itemLevelCounts[itemLevel].items
        tooltip:AddLine(string.format("  %d: %d items", itemLevel, count), 0.5, 0.5, 1.0)
        for _, item in ipairs(items) do
            tooltip:AddLine(string.format("    %s: %s", item.slot, item.link), 0.7, 0.7, 1.0)
        end
    end

    -- Predict upgrades
    local totalItemLevel, numItems = 0, 0
    local itemDetails, itemsToUpgrade = {}, {}

    for i = 1, 19 do
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            local itemName, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
            local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
			local itemLevel = C_Item.DoesItemExist(itemLoc) and C_Item.GetCurrentItemLevel(itemLoc) or 0
            if itemLevel > 1 and itemEquipLoc ~= "INVTYPE_TABARD" and itemEquipLoc ~= "INVTYPE_BODY" then
                totalItemLevel = totalItemLevel + itemLevel
                numItems = numItems + 1
                table.insert(itemDetails, {level = itemLevel, link = itemLink, slot = itemEquipLoc, name = itemName})
            end
        end
    end

    local avgItemLevel = numItems > 0 and (totalItemLevel / numItems) or nil

    if avgItemLevel then
        local updatedItemLevels = {}
        for _, item in ipairs(itemDetails) do
            if item.level < avgItemLevel then
                table.insert(updatedItemLevels, avgItemLevel)
                table.insert(itemsToUpgrade, item)
            else
                table.insert(updatedItemLevels, item.level)
            end
        end

        if #itemsToUpgrade > 0 then
            local newTotal = 0
            for _, lvl in ipairs(updatedItemLevels) do newTotal = newTotal + lvl end
            local predictedItemLevel = math.max(newTotal / #updatedItemLevels, avgItemLevel)

            tooltip:AddLine(" ")
            tooltip:AddLine("Predicted Item Level if upgraded:", 1, 1, 1)
            tooltip:AddLine(string.format("• %.2f", predictedItemLevel), 1, 1, 1)

            tooltip:AddLine(" ")
            tooltip:AddLine("Details:", 1, 1, 1)
            tooltip:AddLine(string.format("• Target Item Level: %.2f", avgItemLevel), 1, 1, 1)
            tooltip:AddLine(string.format("• Number of Items to Upgrade: %d", #itemsToUpgrade), 1, 1, 1)

            table.sort(itemsToUpgrade, function(a, b) return a.level > b.level end)

            for _, item in ipairs(itemsToUpgrade) do
                local slotName = item.slot:gsub("INVTYPE_", ""):gsub("^%l", string.upper)
                tooltip:AddLine(string.format("  • %s: %s (Current iLvl: %d)", slotName, item.link, item.level), 0.7, 0.7, 1.0)
            end
        else
            tooltip:AddLine(" ")
            tooltip:AddLine("All items are already at the target item level.", 0, 1, 0)
        end
    else
        tooltip:AddLine(" ")
        tooltip:AddLine("No valid items found to calculate average item level.", 1, 0, 0)
    end

    -- Track upgrades since session start
    if not sessionStarted then StoreInitialItemLevels() end
    local totalDiff, numItemsDiff, changed = CalculateItemLevelDifference()
    local avgDiff = numItemsDiff > 0 and (totalDiff / numItemsDiff) or 0

    if totalDiff ~= 0 or changed then
        tooltip:AddLine(" ")
        tooltip:AddLine("Session Upgrade Difference:", 1, 1, 1)
        tooltip:AddLine(string.format("• Total iLvl Increase: %.2f", totalDiff), 1, 1, 1)
        tooltip:AddLine(string.format("• Average iLvl Increase: %.2f", avgDiff), 1, 1, 1)

        tooltip:AddLine(" ")
        tooltip:AddLine("Upgraded Items:", 1, 1, 1)

        local displayItems = {}
        for _, item in ipairs(upgradedItems) do
            local slotName = item.slot and item.slot:gsub("INVTYPE_", ""):gsub("^%l", string.upper) or "Unknown"
            table.insert(displayItems, {
                slot = slotName,
                initialName = item.initialName,
                initialLevel = item.initialLevel,
                initialColor = item.initialColor,
                currentName = item.currentName,
                currentLevel = item.currentLevel,
                currentColor = item.currentColor,
                difference = item.difference
            })
        end

        table.sort(displayItems, function(a, b) return a.currentLevel > b.currentLevel end)

        for _, item in ipairs(displayItems) do
            tooltip:AddLine(string.format("  • %s: %s%s|r (iLvl: %d) -> %s%s|r (iLvl: %d), Diff: %d",
                item.slot,
                item.initialColor, item.initialName or "?", item.initialLevel or 0,
                item.currentColor, item.currentName or "?", item.currentLevel or 0,
                item.difference or 0
            ), 1, 1, 0)
        end
    end
end

local function AddHelpToTooltip(tooltip)
    tooltip:AddLine(" ") -- Spacer
    tooltip:AddLine("|cFFFFFF00HeroMetrics|r - Hold |cFFFFA500Shift|r for Help") -- Minimal mode
    tooltip:AddLine("|cFFFFFF00HeroMetrics|r - Hold |cFFFFA500Alt|r for Warband") -- Minimal mode
    tooltip:AddLine("|cFFFFFF00HeroMetrics|r - Hold |cFFFFA500Ctrl|r for Item Level Details") -- Minimal mode

    -- Check if Shift is being held
    if IsShiftKeyDown() then
        tooltip:AddLine(" ")
        tooltip:AddLine("|cFFFFFF00HeroMetrics Controls:|r") -- Gold title

        tooltip:AddLine("• |cFFFFFFFFReset Pos/Frame:|r |cFFFFA500RClick|r")

        tooltip:AddLine(" ")
        tooltip:AddLine("|cFF00FF00XP Tracking:|r") -- Green subheader
        tooltip:AddLine("• |cFFFFFFFFToggle Custom XP Tracking:|r |cFFFFA500MClick|r")
        tooltip:AddLine("• |cFFFFFFFFReset Custom XP Tracking:|r |cFFFFA500RClick|r")
        tooltip:AddLine("• |cFFFFFFFFToggle XP Bar:|r |cFFFFA500CTRL + LClick|r")

        tooltip:AddLine(" ")
        tooltip:AddLine("|cFF00FF00Time Goals:|r") -- Green subheader
        tooltip:AddLine("• |cFFFFFFFFSet Time Goal:|r |cFFFFA500/hmtg minute over|r")
        tooltip:AddLine("• |cFFFFFFFFCancel Time Goal:|r |cFFFFA500/hmtg cancel|r")

        tooltip:AddLine(" ")
        tooltip:AddLine("|cFF00FF00Other Features:|r") -- Green subheader
        tooltip:AddLine("• |cFFFFFFFFCheck Mail & Gold Notifications:|r |cFFFFA500Auto|r")

        tooltip:AddLine(" ")
    end
end

local function UpdateTooltip(tooltip)
	-- to set tooltip frame on mouse cursor: ANCHOR_CURSOR
	tooltip:SetOwner(xpFrame, "ANCHOR_RIGHT")
	tooltip:ClearLines()

	tooltip:AddLine(AddRaceClassAndSpecToTooltip(tooltip), 1, 1, 1)

	tooltip:AddLine(" ")
	tooltip:AddLine(GetRealmNameText(), 1, 1, 1)

	tooltip:AddLine(GetZoneNameText(), 1, 1, 1)

	AddCurrencyToTooltip(tooltip)

	AddLevelCountsToTooltip(tooltip)

	AddItemLevelToTooltip(tooltip)

	AddMinMaxPlaytimeToTooltip(tooltip)

	AddGetWeeklyAveragePlaytimeToTooltip(tooltip)

	AddGetPlaytimeRankToTooltip(tooltip)

	AddDurabilityToTooltip(tooltip)

	AddHelpToTooltip(tooltip)

	tooltip:Show()
end

local function ResetSession()
	startGold = GetMoney()
	goldGained = 0
end

xpFrame:SetScript("OnEvent", OnEvent)

xpFrame:SetScript("OnEnter", function()
	GameTooltip:Hide()
	UpdateTooltip(GameTooltip)
end)

xpFrame:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

xpFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		DBinit()

        StartSessionTracking()
        UpdatePlaytimeDisplay()

        LoadTimeGoalProgress()
        sessionStart = GetTime()

		CreateMinimapButton()

		CachedILevel()

		ResetSession()
		LoadProgress()
		UpdateXP()
		GetPVPStatus()
		if not xpFrame.uptimeTicker then
			xpFrame.uptimeTicker = C_Timer.NewTicker(1, CheckUptimeNotification)
		end
	elseif event == "PLAYER_XP_UPDATE" then
		UpdateXP()
		UpdateXPBar()
		UpdateCustomXPTracking()
	elseif event == "PLAYER_LEVEL_UP" then
		ShowLevelUpStats()

		if IsMaxLevel() and trackingXP then
			customXPText:Hide()
			customXPTimerText:Show()
			AdjustFrameSize()

			if delayTimer then
				delayTimer:Cancel()
			end

			delayTimer = C_Timer.NewTimer(0.1, function()
				if not IsMaxLevel() then
					UpdateCustomXPTracking()
				end
			end)
		end
	elseif event == "PLAYER_FLAGS_CHANGED" then
		GetPVPStatus()
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		if delayTimer then
			delayTimer:Cancel()
		end

		delayTimer = C_Timer.NewTimer(0.5, function()
			UpdateXP()
			CachedILevel()
		end)
	elseif event == "PLAYER_LOGOUT" then
		SaveProgress()
		SaveSessionTime()
		SaveTimeGoalProgress()
		if uptimeTicker then
			uptimeTicker:Cancel()
		end
	end
end)
xpFrame:RegisterEvent("PLAYER_LOGIN")
xpFrame:RegisterEvent("PLAYER_XP_UPDATE")
xpFrame:RegisterEvent("PLAYER_LEVEL_UP")
xpFrame:RegisterEvent("PLAYER_LOGOUT")
xpFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
xpFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterUnitEvent("UNIT_HEALTH", "player")

eventFrame:SetScript("OnEvent", function(self, event, unit)
	if event == "UPDATE_PENDING_MAIL" or event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(1, NotifyNewMail)
		C_Timer.After(1, CheckGoldNotification)
	elseif event == "UNIT_HEALTH" and unit == "player" then
		UpdateHealthAlert()
	end
end)

SLASH_HEROMETRICSTG1 = "/hmtg"
SlashCmdList["HEROMETRICSTG"] = function(msg)
    local goal, over = msg:match("^(%d+)%s*(%d*)$")
    goal = tonumber(goal)
    over = tonumber(over) or 0

    if msg:lower() == "cancel" then
        CancelTimeGoal()
        print("Time Goal tracking canceled.")
    elseif goal then
        StartTimeGoal(goal, over)
        print("Time Goal set to " .. tostring(goal) .. " minutes. Allowing " .. tostring(over) .. " minutes over.")
    else
        print("Usage: /hmtg <minutes> [over time]")
    end
end

local function UpdateUptime()
	local uptime = GetTime() - addonStartTime
	uptimeText:SetText("Uptime: " .. FormatTime(uptime))

    -- Check if 5 minutes (300 seconds) have passed since the last update
    if GetTime() - lastPlaytimeUpdate >= 300 then
        UpdatePlaytimeDisplay()
        lastPlaytimeUpdate = GetTime() -- Prevent multiple updates
    end
end

local uptimeTicker = C_Timer.NewTicker(1, UpdateUptime)

xpFrame:SetMovable(true)
xpFrame:EnableMouse(true)
xpFrame:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		self:StartMoving()
	elseif button == "MiddleButton" then
		ToggleCustomXPTracking()
	elseif button == "RightButton" then
		ResetCustomXPTracking()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT")
	end

    if button == "LeftButton" and IsControlKeyDown() then
        ToggleXPBar()
    else
        self:StartMoving()
    end
end)
xpFrame:SetScript("OnMouseUp", function(self, button)
	self:StopMovingOrSizing()
end)
