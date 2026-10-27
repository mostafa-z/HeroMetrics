-- Core initialization and global table
-- /console scriptErrors 1
local addonName, HeroMetrics = ...
_G.HeroMetrics = HeroMetrics

local function DBinit()
	HeroMetricsDB.xpBarEnabled = HeroMetricsDB.xpBarEnabled or false
	HeroMetricsDB.userInteract = HeroMetricsDB.userInteract or false

	if not HeroMetrics.xpProgressBar then return end

	if HeroMetrics.IsMaxLevel() then
		HeroMetrics.xpProgressBar:Hide()
		return
	end

	if HeroMetricsDB.xpBarEnabled then
		HeroMetrics.xpProgressBar:Show()
	else
		HeroMetrics.xpProgressBar:Hide()
	end
end

local function CachedILevel()
	local _, avgItemLevel = GetAverageItemLevel()
	cachedItemLevel = math.floor(avgItemLevel or 0)
end

function HeroMetrics.GetSessionGoldGained()
	local goldGained = GetMoney() - startGold
	return "• Session: " .. HeroMetrics.FormatGold(goldGained)
end

function HeroMetrics.GetWarbandGold()
	local WBGold = GetMoneyString(C_Bank.FetchDepositedMoney(Enum.BankType.Account), true)
	return "• WarBand: " .. WBGold
end

function HeroMetrics.SaveProgress()
	local characterKey = HeroMetrics.GetCharacterKey()
	local currentLevel = UnitLevel("player")
	HeroMetricsDB[characterKey] = HeroMetricsDB[characterKey] or {}


	if HeroMetricsDB[characterKey].level ~= currentLevel then
		print("Level mismatch detected. Updating level from:", HeroMetricsDB[characterKey].level or "nil", "to:", currentLevel)
		HeroMetricsDB[characterKey].level = nil
		HeroMetricsDB[characterKey].level = currentLevel
	end

	HeroMetricsDB[characterKey].class = select(2, UnitClass("player"))
	HeroMetricsDB[characterKey].ilevel = cachedItemLevel

	HeroMetricsDB[characterKey].lastXPChange = lastXPChange
	HeroMetricsDB[characterKey].previousXPChange = previousXPChange
	HeroMetricsDB[characterKey].iterationsNeeded = iterationsNeeded
	HeroMetricsDB[characterKey].lastKnownXP = lastKnownXP

	HeroMetricsDB[characterKey].customXPAccumulated = customXPAccumulated
	HeroMetricsDB[characterKey].userInteract = userInteract

	HeroMetricsDB[characterKey].xpBarEnabled = xpBarEnabled

	local cx, cy = HeroMetrics.xpFrame:GetCenter()
	HeroMetricsDB[characterKey].frameX = cx
	HeroMetricsDB[characterKey].frameY = cy
end

local function LoadProgress()
	local characterKey = HeroMetrics.GetCharacterKey()
	local data = HeroMetricsDB[characterKey]
	if data then
		lastXPChange = data.lastXPChange or 0
		previousXPChange = data.previousXPChange or 0
		iterationsNeeded = data.iterationsNeeded or 0
		lastKnownXP = data.lastKnownXP

		customXPAccumulated = data.customXPAccumulated or 0
		userInteract = data and data.userInteract or false

		xpBarEnabled = data and data.xpBarEnabled or false

		local fx = data.frameX
		local fy = data.frameY

		if fx and fy then
			HeroMetrics.xpFrame:ClearAllPoints()
			HeroMetrics.xpFrame:SetPoint(
				"CENTER",
				UIParent,
				"BOTTOMLEFT",
				fx,
				fy
			)
		end

	else
		HeroMetrics.lastXPChange = 0
		HeroMetrics.previousXPChange = 0
		HeroMetrics.iterationsNeeded = 0
		HeroMetrics.lastKnownXP = lastKnownXP

		customXPAccumulated = 0
		userInteract = false

		xpBarEnabled = false
	end
end

local function StartItemLevelTracking()
	if not sessionStarted then
		HeroMetrics.StoreInitialItemLevels()
		sessionStarted = true
	end

	HeroMetrics.upgradedItems = HeroMetrics.upgradedItems or {}
end

HeroMetrics.xpFrame:SetScript("OnEvent", OnEvent)
HeroMetrics.xpFrame:RegisterEvent("PLAYER_LOGIN")
HeroMetrics.xpFrame:RegisterEvent("PLAYER_XP_UPDATE")
HeroMetrics.xpFrame:RegisterEvent("PLAYER_LEVEL_UP")
HeroMetrics.xpFrame:RegisterEvent("PLAYER_LOGOUT")
HeroMetrics.xpFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
HeroMetrics.xpFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

HeroMetrics.xpFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		DBinit()

		HeroMetrics.StartSessionTracking()
		HeroMetrics.UpdatePlaytimeDisplay()

		HeroMetrics.LoadTimeGoalProgress()
		HeroMetrics.sessionStart = GetTime()

		HeroMetrics.CreateMinimapButton()

		CachedILevel()

		HeroMetrics.ResetSession()
		LoadProgress()
		HeroMetrics.UpdateXP()
		HeroMetrics.GetPVPStatus()
		HeroMetrics.AddFactionWatermark()
		if not HeroMetrics.xpFrame.uptimeTicker then
			HeroMetrics.xpFrame.uptimeTicker = C_Timer.NewTicker(1, HeroMetrics.CheckUptimeNotification)
		end
	elseif event == "PLAYER_XP_UPDATE" then
		HeroMetrics.UpdateXP()
		HeroMetrics.UpdateXPBar()
		HeroMetrics.UpdateCustomXPTracking()
	elseif event == "PLAYER_LEVEL_UP" then
		HeroMetrics.ShowLevelUpStats()

		if HeroMetrics.IsMaxLevel() and trackingXP then
			HeroMetrics.customXPText:Hide()
			HeroMetrics.customXPTimerText:Show()
			HeroMetrics.AdjustFrameSize()

			if delayTimer then
				delayTimer:Cancel()
			end

			delayTimer = C_Timer.NewTimer(0.1, function()
				if not HeroMetrics.IsMaxLevel() then
					HeroMetrics.UpdateCustomXPTracking()
				end
			end)
		end
	elseif event == "PLAYER_FLAGS_CHANGED" then
		HeroMetrics.GetPVPStatus()
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		if delayTimer then
			delayTimer:Cancel()
		end

		delayTimer = C_Timer.NewTimer(0.5, function()
			HeroMetrics.UpdateXP()
			CachedILevel()

			if sessionStarted then
				HeroMetrics.CalculateItemLevelDifference()
			end
		end)
	elseif event == "PLAYER_LOGOUT" then
		HeroMetrics.SaveProgress()
		HeroMetrics.SaveSessionTime()
		HeroMetrics.SaveTimeGoalProgress()
		if uptimeTicker then
			uptimeTicker:Cancel()
		end
	end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterUnitEvent("UNIT_HEALTH", "player")

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
	if event == "UPDATE_PENDING_MAIL" or event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(1, HeroMetrics.NotifyNewMail)
		C_Timer.After(1, HeroMetrics.CheckGoldNotification)
		C_Timer.After(1, StartItemLevelTracking)
	elseif event == "UNIT_HEALTH" and arg1 == "player" then
		--HeroMetrics.UpdateHealthAlert()
	end
end)

HeroMetrics.xpFrame:SetScript("OnEnter", function()
	GameTooltip:Hide()
	HeroMetrics.UpdateTooltip(GameTooltip)
end)

HeroMetrics.xpFrame:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

SLASH_HEROMETRICSTG1 = "/hmtg"
SlashCmdList["HEROMETRICSTG"] = function(msg)
	local goal, over = msg:match("^(%d+)%s*(%d*)$")
	goal = tonumber(goal)
	over = tonumber(over) or 0

	if msg:lower() == "cancel" then
		HeroMetrics.CancelTimeGoal()
		print("Time Goal tracking canceled.")
	elseif goal then
		HeroMetrics.StartTimeGoal(goal, over)
		print("Time Goal set to " .. tostring(goal) .. " minutes. Allowing " .. tostring(over) .. " minutes over.")
	else
		print("Usage: /hmtg <minutes> [over time]")
	end
end

SLASH_HEROMETRICSNOTEUI1 = "/hmnoteui"
SlashCmdList["HEROMETRICSNOTEUI"] = function()
	ShowHeroNoteEditor()
end

SLASH_HEROMETRICSWIPE1 = "/hmwipe"
SlashCmdList["HEROMETRICSWIPE"] = function(msg)
	msg = msg:lower():gsub("^%s+", "") -- trim leading space

	if msg == "all" then
		HeroMetricsDB = {}
		print("|cffff5555HeroMetrics: All character data wiped.|r")
		return
	end

	local charKey

	if msg ~= "" then
		-- Accept both "name - realm" and "name-realm"
		local name, realm = msg:match("^([^%-%s]+)[%s%-]+(.+)$")
		if name and realm then
			-- Trim spaces and normalize capitalization
			name = name:sub(1, 1):upper() .. name:sub(2):lower()
			realm = realm:gsub("^%s*(.-)%s*$", "%1") -- trim
			realm = realm:gsub("(%l)(%w*)", function(a, b) return a:upper() .. b:lower() end)

			charKey = name .. "-" .. realm
		else
			print("|cffff0000HeroMetrics: Invalid format. Use `/hmwipe Name - Realm` or `/hmwipe all`.|r")
			return
		end
	else
		-- Use current player
		local name, realm = UnitName("player"), GetRealmName()
		if name and realm then
			charKey = name .. "-" .. realm
		end
	end

	if charKey and HeroMetricsDB and HeroMetricsDB[charKey] then
		HeroMetricsDB[charKey] = nil
		print("|cffff5555HeroMetrics: Data for |r" .. charKey .. "|cffff5555 wiped.|r")
	else
		print("|cffffff00HeroMetrics: No data found for:|r " .. (charKey or "unknown character"))
	end
end

local function UpdateUptime()
	local uptime = GetTime() - HeroMetrics.addonStartTime
	HeroMetrics.uptimeText:SetText(HeroMetrics.FormatTime(uptime))

	if GetTime() - HeroMetrics.lastPlaytimeUpdate >= 300 then
		HeroMetrics.UpdatePlaytimeTextAndSize()
		HeroMetrics.lastPlaytimeUpdate = GetTime()
	end
end

local uptimeTicker = C_Timer.NewTicker(1, UpdateUptime)

HeroMetrics.xpFrame:SetMovable(true)
HeroMetrics.xpFrame:EnableMouse(true)
HeroMetrics.xpFrame:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		self:StartMoving()
	elseif button == "MiddleButton" then
		HeroMetrics.ToggleCustomXPTracking()
	elseif button == "RightButton" then
		HeroMetrics.ResetCustomXPTracking()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT")
	end

	if button == "LeftButton" and IsControlKeyDown() then
		HeroMetrics.ToggleXPBar()
	else
		self:StartMoving()
	end
end)
HeroMetrics.xpFrame:SetScript("OnMouseUp", function(self, button)
	self:StopMovingOrSizing()

	local characterKey = HeroMetrics.GetCharacterKey()
	HeroMetricsDB[characterKey] = HeroMetricsDB[characterKey] or {}

	local cx, cy = self:GetCenter()
	HeroMetricsDB[characterKey].frameX = cx
	HeroMetricsDB[characterKey].frameY = cy
end)