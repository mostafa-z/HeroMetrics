local _, HeroMetrics = ...

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

local function GetCurrencyText()
	local currentGold = GetMoney()
	local gold = math.floor(currentGold / 10000)
	local silver = math.floor((currentGold % 10000) / 100)
	local copper = currentGold % 100

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

local function AddCurrencyToTooltip(tooltip)
	tooltip:AddLine(" ")
	tooltip:AddLine("Currency:", 1, 1, 1)
	tooltip:AddLine(GetCurrencyText(), 1, 1, 1)
	tooltip:AddLine(HeroMetrics.GetSessionGoldGained(), 1, 1, 1)
	if IsAltKeyDown() then
		tooltip:AddLine(" ")
		tooltip:AddLine(HeroMetrics.GetWarbandGold(), 1, 1, 1)
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

local function AddDurabilityToTooltip(tooltip)
	durabilityPercentage = HeroMetrics.GetDurabilityPercentage()
	if durabilityPercentage and durabilityPercentage < 90 then
		tooltip:AddLine(" ")
		tooltip:AddLine("Durability:", 1, 1, 1)
		tooltip:AddLine(string.format("• %.2f%%", durabilityPercentage), 1, 1, 1)
	end
end

local function AddMinMaxPlaytimeToTooltip(tooltip)
	if IsControlKeyDown() then return end

	local minTime, maxTime, minDay, maxDay = HeroMetrics.GetMinMaxPlaytime()

	tooltip:AddLine(" ")
	tooltip:AddLine("Playtime Records:", 1, 1, 1)
	tooltip:AddLine("• Min Playtime: " .. minTime .. " (" .. (minDay or "N/A") .. ")", 0, 1, 0)
	tooltip:AddLine("• Max Playtime: " .. maxTime .. " (" .. (maxDay or "N/A") .. ")", 1, 0.5, 0)
end

local function AddGetWeeklyAveragePlaytimeToTooltip(tooltip)
	if IsControlKeyDown() then return end

	tooltip:AddLine(" ")
	tooltip:AddLine("• Weekly Avg: " .. HeroMetrics.GetWeeklyAveragePlaytime(), 0.5, 0.5, 1)
end

local function GetPlaytimeRank()
	local dateKey = HeroMetrics.GetDateKey()
	local todayTime = HeroMetricsDB.sessionTimes and HeroMetricsDB.sessionTimes[dateKey] and HeroMetricsDB.sessionTimes[dateKey].total or 0
	local playtimes = {}

	if HeroMetricsDB.sessionTimes then
		for _, data in pairs(HeroMetricsDB.sessionTimes) do
			if data.total then table.insert(playtimes, data.total) end
		end
	end

	table.sort(playtimes, function(a, b) return a > b end)
	for rank, time in ipairs(playtimes) do
		if time == todayTime then
			return rank, #playtimes
		end
	end
	return "N/A", #playtimes
end

local function AddGetPlaytimeRankToTooltip(tooltip)
	if IsControlKeyDown() then return end

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
		tooltip:AddLine(string.format("%d: %d items", itemLevel, count), 0.5, 0.5, 1.0)
		for _, item in ipairs(items) do
			tooltip:AddLine(string.format("  %s: %s", item.slot, item.link), 0.7, 0.7, 1.0)
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

	local totalDiff, numItemsDiff, changed = HeroMetrics.CalculateItemLevelDifference()
	local avgDiff = numItemsDiff > 0 and (totalDiff / numItemsDiff) or 0

	if totalDiff ~= 0 or changed then
		tooltip:AddLine(" ")
		tooltip:AddLine("Session Upgrade Difference:", 1, 1, 1)
		tooltip:AddLine(string.format("• Total iLvl Increase: %.2f", totalDiff), 1, 1, 1)
		tooltip:AddLine(string.format("• Average iLvl Increase: %.2f", avgDiff), 1, 1, 1)

		tooltip:AddLine(" ")
		tooltip:AddLine("Upgraded Items:", 1, 1, 1)

		local displayItems = {}
		for _, item in ipairs(HeroMetrics.upgradedItems) do
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

local function AddNoteToTooltip(tooltip)
	if IsControlKeyDown() then return end

	local charKey = HeroMetrics.GetCharacterKey()
	local data = HeroMetricsDB and HeroMetricsDB[charKey]
	local note = data and data.note

	if note and type(note) == "string" then
		tooltip:AddLine(" ")
		tooltip:AddLine("|cFFCCCC00Note:|r")

		local formattedNote = note:gsub("#(%w+)", function(tag)
			if tag:lower() == "important" then
				return "|cffff5555#" .. tag .. "|r"
			elseif tag:lower() == "todo" then
				return "|cff00ffff#" .. tag .. "|r"
			elseif tag:lower() == "alts" then
				return "|cffaaaaff#" .. tag .. "|r"
			else
				return "|cffffff00#" .. tag .. "|r"
			end
		end)

		tooltip:AddLine(formattedNote, 1, 1, 1, true)
	end
end

local function AddHelpToTooltip(tooltip)
	if IsControlKeyDown() then return end

	tooltip:AddLine(" ")
	tooltip:AddLine("|cFFFFFF00HeroMetrics|r - Hold |cFFFFA500Shift|r for Help")
	tooltip:AddLine("|cFFFFFF00HeroMetrics|r - Hold |cFFFFA500Alt|r for Warband")
	tooltip:AddLine("|cFFFFFF00HeroMetrics|r - Hold |cFFFFA500Ctrl|r for Item Level Details")

	if IsShiftKeyDown() then
		tooltip:AddLine(" ")
		tooltip:AddLine("|cFFFFFF00HeroMetrics Controls:|r")

		tooltip:AddLine("• |cFFFFFFFFReset Pos/Frame:|r |cFFFFA500RClick|r")

		tooltip:AddLine(" ")
		tooltip:AddLine("|cFF00FF00XP Tracking:|r")
		tooltip:AddLine("• |cFFFFFFFFToggle Custom XP Tracking:|r |cFFFFA500MClick|r")
		tooltip:AddLine("• |cFFFFFFFFReset Custom XP Tracking:|r |cFFFFA500RClick|r")
		tooltip:AddLine("• |cFFFFFFFFToggle XP Bar:|r |cFFFFA500CTRL + LClick|r")

		tooltip:AddLine(" ")
		tooltip:AddLine("|cFF00FF00Time Goals:|r")
		tooltip:AddLine("• |cFFFFFFFFSet Time Goal:|r |cFFFFA500/hmtg minute over|r")
		tooltip:AddLine("• |cFFFFFFFFCancel Time Goal:|r |cFFFFA500/hmtg cancel|r")

		tooltip:AddLine(" ")
		tooltip:AddLine("|cFF00FF00Misc Features:|r")
		tooltip:AddLine("• |cFFFFFFFFWipe Char Data:|r |cFFFFA500/hmwipe [char/all]|r")
		tooltip:AddLine("• |cFFFFFFFFAdd Char Note:|r |cFFFFA500/hmnoteui|r")

		tooltip:AddLine(" ")
		tooltip:AddLine("|cFF00FF00Other Features:|r")
		tooltip:AddLine("• |cFFFFFFFFCheck Mail & Gold Notifications:|r |cFFFFA500Auto|r")

		tooltip:AddLine(" ")
	end
end

function HeroMetrics.UpdateTooltip(tooltip)
	tooltip:SetOwner(HeroMetrics.xpFrame, "ANCHOR_RIGHT")
	tooltip:ClearLines()

	tooltip:AddLine(AddRaceClassAndSpecToTooltip(tooltip), 1, 1, 1)

	tooltip:AddLine(" ")
	tooltip:AddLine(HeroMetrics.GetRealmNameText(), 1, 1, 1)

	tooltip:AddLine(HeroMetrics.GetZoneNameText(), 1, 1, 1)

	AddCurrencyToTooltip(tooltip)

	AddLevelCountsToTooltip(tooltip)

	AddItemLevelToTooltip(tooltip)

	AddMinMaxPlaytimeToTooltip(tooltip)

	AddGetWeeklyAveragePlaytimeToTooltip(tooltip)

	AddGetPlaytimeRankToTooltip(tooltip)

	AddDurabilityToTooltip(tooltip)

	AddHelpToTooltip(tooltip)

	AddNoteToTooltip(tooltip)

	tooltip:Show()
end