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
		HeroMetrics.uptimeText:SetTextColor(1, 0.3, 0.3, 1) --Red
	else
		HeroMetrics.uptimeText:SetTextColor(1, 0.82, 0.0, 1) --Yellow
	end
end

function HeroMetrics.ResetSession()
	startGold = GetMoney()
	goldGained = 0
end

function HeroMetrics.StoreInitialItemLevels()
	for i = 1, 19 do
		local itemLink = GetInventoryItemLink("player", i)
		local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
		local itemLevel = C_Item.DoesItemExist(itemLoc) and C_Item.GetCurrentItemLevel(itemLoc) or 0

		if itemLink then
			local itemName, _, itemQuality, _, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(itemLink)
			local itemColor = itemQuality and ITEM_QUALITY_COLORS[itemQuality] and ITEM_QUALITY_COLORS[itemQuality].hex or "|cffffffff"
			HeroMetrics.initialItemLevels[i] = {level = itemLevel, name = itemName, slot = itemEquipLoc, color = itemColor}
			HeroMetrics.previousItemLevels[i] = {level = itemLevel, name = itemName, slot = itemEquipLoc, color = itemColor}
		else
			HeroMetrics.initialItemLevels[i] = {level = 0, name = nil, slot = nil, color = "|cffffffff"}
			HeroMetrics.previousItemLevels[i] = {level = 0, name = nil, slot = nil, color = "|cffffffff"}
		end
	end
	sessionStarted = true
end

function HeroMetrics.CalculateItemLevelDifference()
	local totalDifference = 0
	local numItems = 0
	local itemChangesDetected = false

	for i = 1, 19 do
		local itemLink = GetInventoryItemLink("player", i)
		local itemLoc = ItemLocation:CreateFromEquipmentSlot(i)
		local currentItemLevel = C_Item.DoesItemExist(itemLoc) and C_Item.GetCurrentItemLevel(itemLoc) or 0

		if itemLink then
			local itemName, _, itemQuality, _, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(itemLink)
			local itemColor = itemQuality and ITEM_QUALITY_COLORS[itemQuality] and ITEM_QUALITY_COLORS[itemQuality].hex or "|cffffffff"

			local initialItemLevel = HeroMetrics.initialItemLevels[i] and HeroMetrics.initialItemLevels[i].level or 0
			local previousItemLevel = HeroMetrics.previousItemLevels[i] and HeroMetrics.previousItemLevels[i].level or 0
			local previousItemName = HeroMetrics.previousItemLevels[i] and HeroMetrics.previousItemLevels[i].name or "Unknown"
			local previousItemColor = HeroMetrics.previousItemLevels[i] and HeroMetrics.previousItemLevels[i].color or "|cffffffff"

			local difference = currentItemLevel - initialItemLevel

			if currentItemLevel ~= previousItemLevel or itemName ~= previousItemName then
				table.insert(HeroMetrics.upgradedItems, {
					slot = itemEquipLoc,
					initialName = previousItemName,
					initialLevel = previousItemLevel,
					initialColor = previousItemColor,
					currentName = itemName,
					currentLevel = currentItemLevel,
					currentColor = itemColor,
					difference = currentItemLevel - previousItemLevel
				})
				HeroMetrics.previousItemLevels[i] = {
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