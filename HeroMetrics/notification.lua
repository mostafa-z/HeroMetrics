local _, HeroMetrics = ...

local function ShowNotificationMessage(message, duration, fontSize, xOffset, yOffset)
	HeroMetrics.notificationText:SetText(message)
	HeroMetrics.notificationText:SetFont("Interface\\AddOns\\HeroMetrics\\fonts\\MagistralTTBold.TTF", fontSize or 24, "OUTLINE")

	HeroMetrics.notificationText:ClearAllPoints()
	HeroMetrics.notificationText:SetPoint("CENTER", UIParent, "CENTER", xOffset or 0, yOffset or 0)

	HeroMetrics.notificationText:SetScript("OnMouseDown", function()
		HeroMetrics.notificationText:Hide()
	end)

	HeroMetrics.notificationText:Show()
	C_Timer.After(duration or 3, function()
		HeroMetrics.notificationText:Hide()
	end)
end

function HeroMetrics.NotifyNewMail()
	if HasNewMail() then
		ShowNotificationMessage("You Have New Mail!", 10, 36, 0, 200) -- message, duration, font size, xOffset, yOffset
		print("|TInterface\\Minimap\\Tracking\\Mailbox:16:16|t |cffffff00[HeroMetrics]|r |cff00ff00You have new mail!|r")
		HeroMetrics.notificationText:SetTextColor(1, 1, 0) -- Yellow
		PlaySound(SOUNDKIT.PVP_THROUGH_QUEUE, "Master")
	end
end

function HeroMetrics.CheckUptimeNotification()
	local uptime = GetTime() - HeroMetrics.addonStartTime

	if uptime >= HeroMetrics.lastNotificationTime + 3600 then
		HeroMetrics.lastNotificationTime = uptime
		ShowNotificationMessage("Uptime Alert: " .. HeroMetrics.FormatTime(uptime), 5, 48, 0, 200)
		print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16|t |cffffff00[HeroMetrics]|r |cff00ffffUptime Alert!|r |cffffffaaYou've been online for:|r |cff88ff88 " .. HeroMetrics.FormatTime(uptime) .. " |r")
		HeroMetrics.notificationText:SetTextColor(1, 1, 0) -- Yellow
		PlaySound(SOUNDKIT.READY_CHECK, "Master")
	end
end

function HeroMetrics.CheckGoldNotification()
	if goldNotified then return end

	local goldThreshold = 5000
	local gold = GetMoney() / 10000

	if gold > goldThreshold then
		local goldMessage = string.format("|cffffd700[RICH ALERT]|r |cff00ff00You have %d gold!|r", gold)

		print(goldMessage)

		RaidNotice_AddMessage(RaidWarningFrame, goldMessage, ChatTypeInfo["RAID_WARNING"])

		goldNotified = true
	end
end

function HeroMetrics.UpdateHealthAlert()
	local health = UnitHealth("player")
	local maxHealth = UnitHealthMax("player")
	local healthPercent = health / maxHealth

	if healthPercent <= HeroMetrics.deadThreshold then
		HeroMetrics.notificationText:Hide()
	elseif healthPercent <= HeroMetrics.criticalHealthThreshold then
		ShowNotificationMessage("Critical Health!", 3, 24, 0, 0)
		HeroMetrics.notificationText:SetTextColor(1, 0, 0)  -- Red for critical
	elseif healthPercent <= HeroMetrics.lowHealthThreshold then
		ShowNotificationMessage("Low Health!", 3, 24, 0, 0)
		HeroMetrics.notificationText:SetTextColor(1, 0.5, 0)  -- Orange for low health
	else
		HeroMetrics.notificationText:Hide()
	end
end