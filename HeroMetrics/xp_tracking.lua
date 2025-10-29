local _, HeroMetrics = ...

function HeroMetrics.ToggleCustomXPTracking()
	local characterKey = HeroMetrics.GetCharacterKey()

	if not HeroMetrics.trackingXP then
		customXPStart = UnitXP("player")
		customXPAccumulated = 0
		customXPStartTime = GetTime()
		HeroMetrics.trackingXP = true

		if not HeroMetricsDB[characterKey] then
			HeroMetricsDB[characterKey] = {}
		end

		customXPAccumulated = HeroMetricsDB[characterKey].customXPAccumulated or 0

		if HeroMetrics.IsMaxLevel() then
			HeroMetrics.customXPText:SetText("Timer Start")
			HeroMetrics.customXPText:Show()

			HeroMetrics.customXPTimerText:SetText("00:00:00")
			HeroMetrics.customXPTimerText:Show()
		else
			if HeroMetricsDB[characterKey].userInteract then
				HeroMetrics.customXPText:SetText("Tracking XP: 0")
				HeroMetricsDB[characterKey].userInteract = false
			else
				HeroMetrics.customXPText:SetText("Tracking XP: " .. customXPAccumulated)
			end
			HeroMetrics.customXPText:Show()

			HeroMetrics.customXPTimerText:SetText("Time: 00:00:00")
			HeroMetrics.customXPTimerText:Show()
		end

		if HeroMetrics.customXPTimer then
			HeroMetrics.customXPTimer:Cancel()
		end
		HeroMetrics.customXPTimer = C_Timer.NewTicker(1, function()
			local elapsed = GetTime() - customXPStartTime
			if HeroMetrics.IsMaxLevel() then
				HeroMetrics.customXPTimerText:SetText(HeroMetrics.FormatTime(elapsed))
			else
				HeroMetrics.customXPTimerText:SetText("Time: " .. HeroMetrics.FormatTime(elapsed))
			end
		end)

		HeroMetrics.AdjustFrameSize()
	else
		HeroMetrics.trackingXP = false

		local currentXP = UnitXP("player")
		local maxXP = UnitXPMax("player")
		local xpRemaining = maxXP - currentXP

		-- Stop timer
		if HeroMetrics.customXPTimer then
			HeroMetrics.customXPTimer:Cancel()
			HeroMetrics.customXPTimer = nil
		end

		if HeroMetrics.IsMaxLevel() then
			HeroMetrics.customXPText:SetText("Timer Stop")
			HeroMetrics.customXPText:Show()
		elseif customXPAccumulated > 0 then
			HeroMetrics.customXPText:SetText(string.format("XP Gained: %d - |cff00ffff%d|r", customXPAccumulated, math.ceil(xpRemaining / customXPAccumulated)))
		else
			HeroMetrics.customXPText:SetText("No XP Gained")
		end

		if customXPAccumulated > 0 then
			HeroMetricsDB[characterKey].customXPAccumulated = 0
		end

		HeroMetricsDB[characterKey].userInteract = true

		HeroMetrics.AdjustFrameSize()
	end
end

function HeroMetrics.UpdateCustomXPTracking()
	if HeroMetrics.trackingXP and not HeroMetrics.IsMaxLevel() then
		local currentXP = UnitXP("player")

		local gainedXP = currentXP - HeroMetrics.customXPStart
		if gainedXP < 0 then
			local maxXP = UnitXPMax("player")
			gainedXP = (maxXP - HeroMetrics.customXPStart) + currentXP
		end

		customXPAccumulated = customXPAccumulated + gainedXP
		HeroMetrics.customXPStart = currentXP

		HeroMetrics.customXPText:SetText("XP Gaining: " .. customXPAccumulated)
	elseif HeroMetrics.trackingXP and HeroMetrics.IsMaxLevel() then
		HeroMetrics.trackingXP = false

		HeroMetrics.customXPText:Hide()
		HeroMetrics.customXPTimerText:Show()
		HeroMetrics.AdjustFrameSize()
	end
end

function HeroMetrics.ResetCustomXPTracking()
	HeroMetrics.customXPText:Hide()
	HeroMetrics.customXPTimerText:Hide()
	HeroMetrics.trackingXP = false
	customXPAccumulated = 0

	local characterKey = HeroMetrics.GetCharacterKey()
	if HeroMetricsDB[characterKey] then
		HeroMetricsDB[characterKey].customXPAccumulated = 0
		HeroMetricsDB[characterKey].trackingXP = false
	end

	if HeroMetrics.customXPTimer then
		HeroMetrics.customXPTimer:Cancel()
		HeroMetrics.customXPTimer = nil
	end

	HeroMetrics.AdjustFrameSize()
end

function HeroMetrics.UpdateXPBar()
	local currentXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	local xpPercent = currentXP / maxXP
	local predictedXP = HeroMetrics.lastXPChange > 0 and (HeroMetrics.lastXPChange / maxXP) or 0

	local barWidth = HeroMetrics.xpProgressBar:GetWidth() - 7

	local xpFillWidth = barWidth * xpPercent
	local remainingWidth = barWidth - xpFillWidth
	local xpPredictWidth = math.min(barWidth * predictedXP, remainingWidth)

	HeroMetrics.xpFill:SetWidth(xpFillWidth)
	HeroMetrics.xpPredictFill:SetWidth(xpPredictWidth)
	HeroMetrics.xpPredictFill:SetShown(predictedXP > 0)

	if (barWidth * predictedXP) > remainingWidth then
		HeroMetrics.xpOverflowIndicator:Show()
	else
		HeroMetrics.xpOverflowIndicator:Hide()
	end
end

function HeroMetrics.ToggleXPBar()
	if HeroMetrics.IsMaxLevel() then
		HeroMetrics.xpProgressBar:Hide()
		HeroMetricsDB.xpBarEnabled = false
		return
	end

	if HeroMetrics.xpProgressBar:IsShown() then
		HeroMetrics.xpProgressBar:Hide()
		HeroMetricsDB.xpBarEnabled = false
	else
		HeroMetrics.xpProgressBar:Show()
		HeroMetricsDB.xpBarEnabled = true
		HeroMetrics.UpdateXPBar()
	end
end

function HeroMetrics.UpdateXP()
	local maxLevel = GetMaxPlayerLevel()
	local level = UnitLevel("player")
	local currentXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	local xpPercent = maxXP > 0 and math.floor((currentXP / maxXP) * 100) or 0
	local xpRemaining = maxXP - currentXP
	local restedXP = GetXPExhaustion() or 0

	if HeroMetrics.lastKnownXP and currentXP > HeroMetrics.lastKnownXP then
		if HeroMetrics.lastKnownXP == 0 then
			HeroMetrics.lastKnownXP = currentXP
		end
		HeroMetrics.previousXPChange = HeroMetrics.lastXPChange
		HeroMetrics.lastXPChange = currentXP - HeroMetrics.lastKnownXP
		HeroMetrics.iterationsNeeded = HeroMetrics.perXPiteration(HeroMetrics.lastXPChange, xpRemaining)

		HeroMetrics.iterationsPassedCurrent = HeroMetrics.iterationsPassedCurrent + 1

		HeroMetrics.SaveProgress()
	end

	local previousIterations = HeroMetrics.perXPiteration(HeroMetrics.previousXPChange, xpRemaining)
	local lastIterations = HeroMetrics.perXPiteration(HeroMetrics.lastXPChange, xpRemaining)

	if level < maxLevel then
		local _, itemLevel = GetAverageItemLevel()
		HeroMetrics.xpText:SetText(string.format(
			"%s\n\n" ..
			"|cffffcc00iLevel: %.2f|r\n\n" ..
			"|cffff9900To Level: %d|r\n" ..
			"|cffffcc00XP Remaining: %d|r\n" ..
			"|cff00ffffRested XP: %d (%.1f%%)|r\n\n" ..
			"|cffffcc00Prev XP: %d - %d|r\n" ..
			"|cffff9900Last XP: %d - %d|r",
			UnitName("player"), itemLevel, level + 1, xpRemaining,
			restedXP, (restedXP / maxXP) * 100,
			HeroMetrics.previousXPChange, previousIterations, HeroMetrics.lastXPChange, lastIterations
		))
		HeroMetrics.iterationText:SetText("|cff00ffffIterations: " .. HeroMetrics.iterationsNeeded .. "|r")
		HeroMetrics.xpProgressText:SetText("|cffffcc00XP Progress: " .. xpPercent .. "%|r")
	else
		local _, itemLevel = GetAverageItemLevel()
		HeroMetrics.xpText:SetText(string.format(
			"%s - %d\n\n" ..
			"|cffffcc00iLevel: %.2f|r",
			UnitName("player"), level, itemLevel
		))
		HeroMetrics.iterationText:SetText("")
		HeroMetrics.xpProgressText:SetText("")
	end

	HeroMetrics.lastKnownXP = currentXP
	
	HeroMetrics.AdjustFrameSize()

	HeroMetrics.UpdateXPBar()
end

local function SaveLevelUpData(level, timeSpent, zone)
	local characterKey = HeroMetrics.GetCharacterKey()
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

	for char, data in pairs(HeroMetricsDB) do
		if type(data) == "table" and data[level] and type(data[level]) == "table" and data[level].time_to_level then
			table.insert(times, data[level].time_to_level)
		end
	end

	-- Sort times (fastest first)
	table.sort(times)

	local rank = 1
	local nextTime = nil

	for i, t in ipairs(times) do
		if timeSpent > t then
			rank = i + 1
			nextTime = t
		else
			break
		end
	end

	local rankTimeDifference = nil
	if nextTime then
		rankTimeDifference = nextTime - timeSpent
	end

	local total = #times
	return rank, total, rankTimeDifference
end

function HeroMetrics.ShowLevelUpStats()
	local level = UnitLevel("player")
	local zone = GetZoneText()

	lastLevelTimeSpent = GetTime() - HeroMetrics.startTime
	HeroMetrics.startTime = GetTime() -- Reset for next level

	SaveLevelUpData(level, lastLevelTimeSpent, zone)

	HeroMetrics.iterationsPassedLast = HeroMetrics.iterationsPassedLast or 0  -- Ensure it's not nil
	local iterationDifference = HeroMetrics.iterationsPassedCurrent - HeroMetrics.iterationsPassedLast

	HeroMetrics.iterationsPassedLast = HeroMetrics.iterationsPassedCurrent
	HeroMetrics.iterationsPassedCurrent = 0  -- Reset for next level

	local timeSpent = math.floor(lastLevelTimeSpent / 60)
	local timeSpentSeconds = lastLevelTimeSpent % 60
	local timeDifferencePercent = HeroMetrics.lastLevelTime > 0 and math.floor(((lastLevelTimeSpent - HeroMetrics.lastLevelTime) / HeroMetrics.lastLevelTime) * 100) or 0

	local rankText, rankTotal, rankTimeDifference = GetLevelUpRank(level, lastLevelTimeSpent)

	print("|cffffd700=== Level Up Report! ===|r")
	print(string.format("|cff00ff00Level:|r |cffffff00%d|r", level + 1))

	if timeSpent > 0 then
		print(string.format("|cff00ff00Time Spent:|r |cffffff00%d min %d sec|r", timeSpent, timeSpentSeconds))
	else
		print(string.format("|cff00ff00Time Spent:|r |cffffff00%d sec|r", timeSpentSeconds))
	end

	print(string.format("|cff00ffffTime Difference:|r |cffffff00%d%%|r", timeDifferencePercent))
	print(string.format("|cff00ffffIterations Passed:|r |cffffff00%d|r", HeroMetrics.iterationsPassedLast))
	print(string.format("|cff00ffffIteration Difference:|r |cffffff00%d|r", iterationDifference))

	local rankMessage = string.format("|cff00ffffRank:|r |cffffff00%d/%d|r", rankText, rankTotal)

	if rankTimeDifference then
		rankMessage = rankMessage .. string.format(" (Need to improve by |cffff0000%.2f|r seconds)", rankTimeDifference)
	end

	print(rankMessage)

	RaidWarningFrame:ClearAllPoints()
	RaidWarningFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)

	C_Timer.After(5, function()
		local message = ""
		if timeSpent > 0 then
			message = string.format("|cff00ff00Time Spent:|r |cffffff00%d min %d sec|r", timeSpent, timeSpentSeconds)
		else
			message = string.format("|cff00ff00Time Spent:|r |cffffff00%d sec|r", timeSpentSeconds)
		end

		RaidNotice_AddMessage(RaidBossEmoteFrame, message, ChatTypeInfo["RAID_WARNING"])
	end)

	C_Timer.After(8, function()
		local raidWarningMessage = string.format("|cff00ff00Rank:|r |cffffff00%d/%d|r", rankText, rankTotal)
		if rankTimeDifference then
			raidWarningMessage = raidWarningMessage .. string.format(" (Need to improve by |cffff0000%.2f|r seconds)", rankTimeDifference)
		end

		RaidNotice_AddMessage(RaidBossEmoteFrame, raidWarningMessage, ChatTypeInfo["RAID_WARNING"])
	end)

	HeroMetrics.lastLevelTime = lastLevelTimeSpent
end

local function UpdateTimeGoal()
	if not HeroMetrics.trackingTimeGoal then return end

	local totalElapsed = HeroMetrics.elapsedTime + (HeroMetrics.sessionStart and (GetTime() - HeroMetrics.sessionStart) or 0)
	local goalTime = HeroMetrics.timeGoal * 60
	local maxTime = (HeroMetrics.timeGoal + HeroMetrics.timeOver) * 60

	if totalElapsed > goalTime then
		HeroMetrics.timeGoalText:SetText(string.format("Time Goal: %d min - %d min over", HeroMetrics.timeGoal, math.floor((totalElapsed - goalTime) / 60)))
	else
		HeroMetrics.timeGoalText:SetText(string.format("Time Goal: %d:%02d / %d", math.floor(totalElapsed / 60), totalElapsed % 60, HeroMetrics.timeGoal))
	end

	-- Update progress bar
	local barWidth = HeroMetrics.timeGoalFrame:GetWidth() - 6
	local percent = totalElapsed / maxTime
	HeroMetrics.timeGoalFill:SetWidth(math.min(barWidth * percent, barWidth))

	if percent < 0.5 then
		HeroMetrics.timeGoalFill:SetVertexColor(0, 1, 0, 1) -- Green
	elseif percent < 0.8 then
		HeroMetrics.timeGoalFill:SetVertexColor(1, 1, 0, 1) -- Yellow
	elseif percent < 0.95 then
		HeroMetrics.timeGoalFill:SetVertexColor(1, 0.5, 0, 1) -- Orange
	else
		HeroMetrics.timeGoalFill:SetVertexColor(1, 0, 0, 1) -- Red
	end

	if totalElapsed >= goalTime and totalElapsed < (goalTime + 1) then
		PlaySound(SOUNDKIT.RAID_WARNING)
		RaidNotice_AddMessage(RaidBossEmoteFrame, "Time Goal Reached!", ChatTypeInfo["RAID_WARNING"])
	end

	HeroMetrics.SaveTimeGoalProgress()
	HeroMetrics.AdjustTimeGoalFrameSize()
end

function HeroMetrics.StartTimeGoal(goal, over, loadedElapsed)
	HeroMetrics.timeGoal = tonumber(goal) or 0
	HeroMetrics.timeOver = tonumber(over) or 0
	HeroMetrics.elapsedTime = loadedElapsed or 0
	HeroMetrics.sessionStart = GetTime()
	HeroMetrics.trackingTimeGoal = true
	HeroMetrics.timeGoalFrame:Show()

	if timeGoalTicker then
		timeGoalTicker:Cancel()
	end
	timeGoalTicker = C_Timer.NewTicker(60, HeroMetrics.SaveTimeGoalProgress)
	C_Timer.NewTicker(1, UpdateTimeGoal)
	HeroMetrics.SaveTimeGoalProgress()
end

function HeroMetrics.LoadTimeGoalProgress()
	local characterKey = UnitName("player") .. "-" .. GetRealmName()
	local data = HeroMetricsDB[characterKey]
	if data and data.trackingTimeGoal then
		HeroMetrics.StartTimeGoal(data.timeGoal or 0, data.timeOver or 0, data.elapsedTime or 0)
	end
end

function HeroMetrics.CancelTimeGoal()
	HeroMetrics.trackingTimeGoal = false
	elapsedTime = HeroMetrics.elapsedTime + (HeroMetrics.sessionStart and (GetTime() - HeroMetrics.sessionStart) or 0)
	HeroMetrics.sessionStart = nil
	HeroMetrics.timeGoalFrame:Hide()
	if timeGoalTicker then
		timeGoalTicker:Cancel()
		timeGoalTicker = nil
	end
	HeroMetrics.SaveTimeGoalProgress()
end

function HeroMetrics.SaveTimeGoalProgress()
	local characterKey = UnitName("player") .. "-" .. GetRealmName()
	HeroMetricsDB[characterKey] = HeroMetricsDB[characterKey] or {}
	HeroMetricsDB[characterKey].timeGoal = timeGoal
	HeroMetricsDB[characterKey].timeOver = timeOver
	HeroMetricsDB[characterKey].elapsedTime = HeroMetrics.elapsedTime + (HeroMetrics.sessionStart and (GetTime() - HeroMetrics.sessionStart) or 0)
	HeroMetricsDB[characterKey].trackingTimeGoal = trackingTimeGoal
end