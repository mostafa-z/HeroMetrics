local _, HeroMetrics = ...

function HeroMetrics.GetMinMaxPlaytime()
	local minTime, maxTime = math.huge, 0
	local minDay, maxDay = nil, nil

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

	local minFormatted = (minDay and HeroMetrics.FormatPlaytime(minTime)) or "N/A"
	local maxFormatted = (maxDay and HeroMetrics.FormatPlaytime(maxTime)) or "N/A"

	return minFormatted, maxFormatted, minDay, maxDay
end

function HeroMetrics.GetWeeklyAveragePlaytime()
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
		return HeroMetrics.FormatPlaytime(totalPlaytime / daysCounted)
	else
		return "N/A"
	end
end

function HeroMetrics.UpdatePlaytimeDisplay()
	local totalTime = HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[HeroMetrics.GetDateKey()] and HeroMetricsDB.sessionTimes[HeroMetrics.GetDateKey()].total or 0
	local sessionStartKey = "sessionStart"
	if HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[HeroMetrics.GetDateKey()] and HeroMetricsDB.sessionTimes[HeroMetrics.GetDateKey()][sessionStartKey] then
		HeroMetrics.sessionStart = HeroMetricsDB.sessionTimes[HeroMetrics.GetDateKey()][sessionStartKey]
		totalTime = totalTime + (GetTime() - HeroMetrics.sessionStart)
	end

	local hours = totalTime / 3600

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

	return HeroMetrics.FormatTime(totalTime), fontSize, r, g, b
end

function HeroMetrics.StartSessionTracking()
	local dateKey = HeroMetrics.GetDateKey()
	local sessionStartKey = "sessionStart"

	HeroMetricsDB.sessionTimes = HeroMetricsDB.sessionTimes or {}
	HeroMetricsDB.sessionTimes[dateKey] = HeroMetricsDB.sessionTimes[dateKey] or {}
	HeroMetricsDB.sessionTimes[dateKey][sessionStartKey] = GetTime()
end

function HeroMetrics.SaveSessionTime()
	local dateKey = HeroMetrics.GetDateKey()
	local sessionStartKey = "sessionStart"

	if HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[dateKey] and HeroMetricsDB.sessionTimes[dateKey][sessionStartKey] then
		HeroMetrics.sessionStart = HeroMetricsDB.sessionTimes[dateKey][sessionStartKey]
		local sessionDuration = GetTime() - HeroMetrics.sessionStart
		HeroMetricsDB.sessionTimes[dateKey].total = (HeroMetricsDB.sessionTimes[dateKey].total or 0) + sessionDuration
	end
end