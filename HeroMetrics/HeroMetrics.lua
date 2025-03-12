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

local customXPText = xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
customXPText:SetFont(customXPText:GetFont(), 14)
customXPText:SetPoint("BOTTOM", uptimeText, "BOTTOM", 0, -30)
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

-- Global saved variable for all characters
HeroMetricsDB = HeroMetricsDB or {}

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

local lastLevelTime = lastLevelTime or 0
local iterationsPassedCurrent = 0
local iterationsPassedLast = 0

local trackingXP = false
local customXPStart = 0
HeroMetricsDB.userInteract = HeroMetricsDB.userInteract or false

local customXPStartTime = 0
local customXPTimer = nil

local goldNotified = false

local lowHealthThreshold = 0.5  -- 50%
local criticalHealthThreshold = 0.3  -- 30%
local deadThreshold = 0.01 -- 1%

local function IsMaxLevel()
	return UnitLevel("player") == GetMaxPlayerLevel()
end

local function AdjustFrameSize()
	local textWidth = math.max(
		xpText:GetStringWidth(),
		iterationText:GetStringWidth(),
		xpProgressText:GetStringWidth(),
		uptimeText:GetStringWidth(),
		(customXPText:IsShown() and customXPText:GetStringWidth() or 0),
		(customXPTimerText:IsShown() and customXPTimerText:GetStringWidth() or 0)
	)

	local textHeight = xpText:GetStringHeight() +
		iterationText:GetStringHeight() +
		xpProgressText:GetStringHeight() +
		uptimeText:GetStringHeight()

	if customXPText:IsShown() then
		textHeight = textHeight + customXPText:GetStringHeight() + 5
	end

	if customXPTimerText:IsShown() then
		textHeight = textHeight + customXPTimerText:GetStringHeight() + 5
	end

	textHeight = textHeight + 60
	xpFrame:SetSize(textWidth + 2 * sideSpacing, textHeight)
end

AdjustFrameSize()

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
		notificationText:SetTextColor(1, 1, 0) -- Yellow
		PlaySound(SOUNDKIT.PVP_THROUGH_QUEUE, "Master")
	end
end

local function CheckUptimeNotification()
	local uptime = GetTime() - addonStartTime

	if uptime >= lastNotificationTime + 3600 then
		lastNotificationTime = uptime
		ShowNotificationMessage("Uptime Alert: " .. FormatTime(uptime), 5, 48, 0, 200)
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

local function GetCharacterKey()
	return UnitName("player") .. "-" .. GetRealmName()
end

local function SaveProgress()
	local characterKey = GetCharacterKey()
	HeroMetricsDB[characterKey] = HeroMetricsDB[characterKey] or {}
	HeroMetricsDB[characterKey].lastXPChange = lastXPChange
	HeroMetricsDB[characterKey].previousXPChange = previousXPChange
	HeroMetricsDB[characterKey].iterationsNeeded = iterationsNeeded
	HeroMetricsDB[characterKey].lastKnownXP = lastKnownXP

	-- Save custom XP tracking state
	HeroMetricsDB[characterKey].customXPAccumulated = customXPAccumulated
	HeroMetricsDB[characterKey].userInteract = userInteract
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
	else
		lastXPChange = 0
		previousXPChange = 0
		iterationsNeeded = 0
		lastKnownXP = lastKnownXP

		customXPAccumulated = 0
		userInteract = false
	end
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

	if currentXP > lastKnownXP then
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
	C_Timer.After(6, function()
		local message = ""
		if timeSpent > 0 then
			message = string.format("|cff00ff00Time Spent:|r |cffffff00%d min %d sec|r", timeSpent, timeSpentSeconds)
		else
			message = string.format("|cff00ff00Time Spent:|r |cffffff00%d sec|r", timeSpentSeconds)
		end

		RaidNotice_AddMessage(RaidBossEmoteFrame, message, ChatTypeInfo["RAID_WARNING"])
	end)
    C_Timer.After(9, function()
        RaidNotice_AddMessage(RaidBossEmoteFrame, string.format("|cff00ffffTime Difference:|r |cffffff00%d%%|r", timeDifferencePercent), ChatTypeInfo["RAID_WARNING"])
    end)
    C_Timer.After(12, function()
        RaidNotice_AddMessage(RaidBossEmoteFrame, string.format("|cff00ff00Iterations Passed:|r |cffffff00%d|r", iterationsPassedLast), ChatTypeInfo["RAID_WARNING"])
    end)
    C_Timer.After(15, function()
        RaidNotice_AddMessage(RaidBossEmoteFrame, string.format("|cff00ffffIteration Difference:|r |cffffff00%d|r", iterationDifference), ChatTypeInfo["RAID_WARNING"])
    end)

	C_Timer.After(18, function()
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

local function UpdateTooltip(tooltip)
	-- to set tooltip frame on mouse cursor: ANCHOR_CURSOR
	tooltip:SetOwner(xpFrame, "ANCHOR_RIGHT")
	tooltip:ClearLines()

	tooltip:AddLine(AddRaceClassAndSpecToTooltip(tooltip), 1, 1, 1)

	tooltip:AddLine(" ")
	tooltip:AddLine(GetRealmNameText(), 1, 1, 1)

	tooltip:AddLine(GetZoneNameText(), 1, 1, 1)

	AddItemLevelToTooltip(tooltip)

	AddCurrencyToTooltip(tooltip)

	AddDurabilityToTooltip(tooltip)

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
		ResetSession()
		LoadProgress()
		UpdateXP()
		GetPVPStatus()
		if not xpFrame.uptimeTicker then
			xpFrame.uptimeTicker = C_Timer.NewTicker(1, CheckUptimeNotification)
		end
	elseif event == "PLAYER_XP_UPDATE" then
		UpdateXP()
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
		end)
	elseif event == "PLAYER_LOGOUT" then
		SaveProgress()
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

local function UpdateUptime()
	local uptime = GetTime() - addonStartTime
	uptimeText:SetText("Uptime: " .. FormatTime(uptime))
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
end)
xpFrame:SetScript("OnMouseUp", function(self, button)
	self:StopMovingOrSizing()
end)
