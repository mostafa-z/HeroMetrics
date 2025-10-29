local _, HeroMetrics = ...

function HeroMetrics.GetDateKey()
	return date("%Y-%m-%d")
end

function HeroMetrics.IsMaxLevel()
	return UnitLevel("player") == GetMaxPlayerLevel()
end

function HeroMetrics.GetCharacterKey()
	return UnitName("player") .. "-" .. GetRealmName()
end

function HeroMetrics.GetRealmNameText()
	return "Realm: " .. GetRealmName()
end

function HeroMetrics.GetZoneNameText()
	return "Current Zone: " .. GetZoneText()
end

function HeroMetrics.FormatTime(uptime)
	local hours = math.floor(uptime / 3600)
	local minutes = math.floor((uptime % 3600) / 60)
	local secs = math.floor(uptime % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function HeroMetrics.FormatPlaytime(seconds)
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

function HeroMetrics.FormatGold(copper)
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	copper = copper % 100
	return string.format("%d gold, %d silver, %d copper", gold, silver, copper)
end

function HeroMetrics.perXPiteration(xpChange, xpRemaining)
	return xpChange > 0 and math.ceil(xpRemaining / xpChange) or 0
end

function HeroMetrics.GetDurabilityPercentage()
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

function HeroMetrics.GetPVPStatus()
	if C_PvP.IsWarModeDesired() then
		HeroMetrics.xpFrame:SetBackdropBorderColor(1, 0, 0, 1) --Red
	else
		HeroMetrics.xpFrame:SetBackdropBorderColor(1, 1, 1, 1) --White
	end
end

function HeroMetrics.ResetSession()
	startGold = GetMoney()
	goldGained = 0
end