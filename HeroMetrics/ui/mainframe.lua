local _, HeroMetrics = ...

HeroMetrics.xpFrame = CreateFrame("Frame", "HeroMetrics", UIParent, "BackdropTemplate")

HeroMetrics.xpFrame:SetSize(200, 100)
HeroMetrics.xpFrame:SetPoint("TOPLEFT")
HeroMetrics.xpFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
HeroMetrics.xpFrame:SetBackdropColor(0, 0, 0, 1)

HeroMetrics.xpText = HeroMetrics.xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.xpText:SetFont(HeroMetrics.xpText:GetFont(), 12)
HeroMetrics.xpText:SetPoint("TOP", HeroMetrics.xpFrame, "TOP", 0, -10)

HeroMetrics.iterationText = HeroMetrics.xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.iterationText:SetFont(HeroMetrics.iterationText:GetFont(), 18)
HeroMetrics.iterationText:SetPoint("TOP", HeroMetrics.xpText, "BOTTOM", 0, -10)

HeroMetrics.xpProgressText = HeroMetrics.xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.xpProgressText:SetFont(HeroMetrics.xpProgressText:GetFont(), 18)
HeroMetrics.xpProgressText:SetPoint("TOP", HeroMetrics.iterationText, "BOTTOM", 0, -10)

HeroMetrics.uptimeText = HeroMetrics.xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.uptimeText:SetFont(HeroMetrics.uptimeText:GetFont(), 12)
HeroMetrics.uptimeText:SetPoint("BOTTOM", HeroMetrics.xpProgressText, "BOTTOM", 0, -20)

HeroMetrics.playtimeText = HeroMetrics.xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.playtimeText:SetFont(HeroMetrics.playtimeText:GetFont(), 12)
HeroMetrics.playtimeText:SetTextColor(0.5, 0.5, 1, 0.8) -- Light blue with lower alpha to differentiate from uptime
HeroMetrics.playtimeText:SetPoint("TOP", HeroMetrics.uptimeText, "BOTTOM", 0, -5)

HeroMetrics.customXPText = HeroMetrics.xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.customXPText:SetFont(HeroMetrics.customXPText:GetFont(), 14)
HeroMetrics.customXPText:SetPoint("BOTTOM", HeroMetrics.playtimeText, "BOTTOM", 0, -30)
HeroMetrics.customXPText:Hide()

HeroMetrics.customXPTimerText = HeroMetrics.xpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.customXPTimerText:SetFont(HeroMetrics.customXPTimerText:GetFont(), 12)
HeroMetrics.customXPTimerText:SetPoint("TOP", HeroMetrics.customXPText, "BOTTOM", 0, -5)
HeroMetrics.customXPTimerText:Hide()

HeroMetrics.notificationText = UIParent:CreateFontString(nil, "OVERLAY")
HeroMetrics.notificationText:SetFont("Interface\\AddOns\\HeroMetrics\\fonts\\MagistralTTBold.TTF", 24, "OUTLINE")
HeroMetrics.notificationText:SetPoint("CENTER", 0, 0)
HeroMetrics.notificationText:SetTextColor(1, 1, 0)  --yellow
HeroMetrics.notificationText:Hide()

-- XP Progress Bar
HeroMetrics.xpProgressBar = CreateFrame("Frame", "HeroMetricsXPBar", UIParent, "BackdropTemplate")

HeroMetrics.xpProgressBar:SetSize(200, 20)
HeroMetrics.xpProgressBar:SetPoint("TOP", HeroMetrics.xpFrame, "BOTTOM", 0, -10)
HeroMetrics.xpProgressBar:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
HeroMetrics.xpProgressBar:SetBackdropColor(0, 0, 0, 0.8)

HeroMetrics.xpFill = HeroMetrics.xpProgressBar:CreateTexture(nil, "OVERLAY")
HeroMetrics.xpFill:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
HeroMetrics.xpFill:SetPoint("LEFT", HeroMetrics.xpProgressBar, "LEFT", 3, 0)
HeroMetrics.xpFill:SetHeight(14)
HeroMetrics.xpFill:SetVertexColor(38/255, 100/255, 245/255, 1) -- HEX #2664F5 converted to RGB

HeroMetrics.xpPredictFill = HeroMetrics.xpProgressBar:CreateTexture(nil, "OVERLAY")
HeroMetrics.xpPredictFill:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
HeroMetrics.xpPredictFill:SetPoint("LEFT", HeroMetrics.xpFill, "RIGHT", 0, 0)
HeroMetrics.xpPredictFill:SetHeight(14)
HeroMetrics.xpPredictFill:SetVertexColor(245/255, 183/255, 38/255, 1) -- Solid orange for predicted XP

HeroMetrics.xpOverflowIndicator = HeroMetrics.xpProgressBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
HeroMetrics.xpOverflowIndicator:SetPoint("RIGHT", HeroMetrics.xpProgressBar, "RIGHT", 10, 0)
HeroMetrics.xpOverflowIndicator:SetText("+")
HeroMetrics.xpOverflowIndicator:SetTextColor(245/255, 183/255, 38/255, 1) -- Orange color like prediction XP
HeroMetrics.xpOverflowIndicator:Hide()

HeroMetrics.timeGoalFrame = CreateFrame("Frame", "HeroMetricsTimeGoal", UIParent, "BackdropTemplate")
HeroMetrics.timeGoalFrame:SetSize(200, 20)
HeroMetrics.timeGoalFrame:SetPoint("TOP", HeroMetrics.xpProgressBar, "BOTTOM", 0, -10)
HeroMetrics.timeGoalFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
HeroMetrics.timeGoalFrame:SetBackdropColor(0, 0, 0, 0.8)
HeroMetrics.timeGoalFrame:Hide()

HeroMetrics.timeGoalFill = HeroMetrics.timeGoalFrame:CreateTexture(nil, "OVERLAY")
HeroMetrics.timeGoalFill:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
HeroMetrics.timeGoalFill:SetPoint("LEFT", HeroMetrics.timeGoalFrame, "LEFT", 3, 0)
HeroMetrics.timeGoalFill:SetHeight(14)
HeroMetrics.timeGoalFill:SetVertexColor(0, 1, 0, 1) -- Start with green

HeroMetrics.timeGoalText = HeroMetrics.timeGoalFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HeroMetrics.timeGoalText:SetPoint("CENTER", HeroMetrics.timeGoalFrame, "CENTER", 0, 0)
HeroMetrics.timeGoalText:SetText("Time Goal: Loading ...")

function HeroMetrics.AdjustFrameSize()
	local textWidth = math.max(
		HeroMetrics.xpText:GetStringWidth(),
		HeroMetrics.iterationText:GetStringWidth(),
		HeroMetrics.xpProgressText:GetStringWidth(),
		HeroMetrics.uptimeText:GetStringWidth(),
		HeroMetrics.playtimeText:GetStringWidth(),
		(HeroMetrics.customXPText:IsShown() and HeroMetrics.customXPText:GetStringWidth() or 0),
		(HeroMetrics.customXPTimerText:IsShown() and HeroMetrics.customXPTimerText:GetStringWidth() or 0)
	)

	local textHeight = HeroMetrics.xpText:GetStringHeight() +
		HeroMetrics.iterationText:GetStringHeight() +
		HeroMetrics.xpProgressText:GetStringHeight() +
		HeroMetrics.uptimeText:GetStringHeight() +
		HeroMetrics.playtimeText:GetStringHeight()

	if HeroMetrics.customXPText:IsShown() then
		textHeight = textHeight + HeroMetrics.customXPText:GetStringHeight() + 5
	end

	if HeroMetrics.customXPTimerText:IsShown() then
		textHeight = textHeight + HeroMetrics.customXPTimerText:GetStringHeight() + 5
	end

	if HeroMetrics.xpProgressBar:IsShown() then
		HeroMetrics.xpProgressBar:SetWidth(textWidth)
	end

	textHeight = textHeight + 60
	HeroMetrics.xpFrame:SetSize(textWidth + 2 * HeroMetrics.sideSpacing, textHeight)
end

HeroMetrics.AdjustFrameSize()

function HeroMetrics.AdjustTimeGoalFrameSize()
	local barWidth = HeroMetrics.xpProgressBar:GetWidth()
	local textWidth = HeroMetrics.timeGoalText:GetWidth()

	if textWidth > barWidth then
		local textWidth = HeroMetrics.timeGoalText:GetWidth()
		HeroMetrics.timeGoalFrame:SetWidth(textWidth + 20)
	else
		local barWidth = HeroMetrics.xpProgressBar:GetWidth()
		HeroMetrics.timeGoalFrame:SetWidth(barWidth)
	end
end

function HeroMetrics.AddFactionWatermark()
	local faction = UnitFactionGroup("player")

	local bgIcon = HeroMetrics.xpFrame:CreateTexture(nil, "BACKGROUND")
	bgIcon:SetPoint("CENTER", HeroMetrics.xpFrame, "CENTER")
	bgIcon:SetAlpha(0.2)
	bgIcon:SetBlendMode("ADD")
	bgIcon:SetTexture(faction == "Alliance"
		and "Interface\\FriendsFrame\\PlusManz-Alliance"
		or  "Interface\\FriendsFrame\\PlusManz-Horde")

	local function ResizeWatermark()
		local w, h = HeroMetrics.xpFrame:GetSize()
		-- pick the smaller dimension so it always stays inside
		local side = math.min(w, h) * 0.8	-- 80 % of frame for a nice margin
		bgIcon:SetSize(side, side)
	end

	HeroMetrics.xpFrame:HookScript("OnSizeChanged", ResizeWatermark)
	ResizeWatermark()
end

function HeroMetrics.CreateCharacterListFrame()
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

function HeroMetrics.SortCharacters()
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

function HeroMetrics.GetColorForCharacter(class)
	if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
		return "|c" .. RAID_CLASS_COLORS[class].colorStr
	else
		return "|cffffffff" -- fallback white
	end
end

function HeroMetrics.ShowCharacterList()
	HeroMetrics.CreateCharacterListFrame()

	local MAX_LEVEL = GetMaxPlayerLevel()

	local content = HeroMetricsFrame.content
	for i, child in ipairs({content:GetChildren()}) do
		child:Hide()
	end

	local list = HeroMetrics.SortCharacters()
	local classCount = {}
	local classStats = {}
	local sortedClasses = {}

	local offsetY = -10
	for i, data in ipairs(list) do
		local color = HeroMetrics.GetColorForCharacter(data.class)

		local line = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		line:SetPoint("TOPLEFT", 0, offsetY)
		line:SetText(string.format("%d. %s%s|r - Level: %d - iLvl: %d", i, color, data.key, data.level, data.ilevel))
		offsetY = offsetY - 20

		classCount[data.class] = (classCount[data.class] or 0) + 1

		-- Build stats
		classStats[data.class] = classStats[data.class] or {
			count = 0,
			sum = 0,
			min = data.ilevel,
			max = data.ilevel,
			levelmax = data.level,
		}

		local stats = classStats[data.class]
		stats.count = stats.count + 1
		stats.sum = stats.sum + data.ilevel
		stats.min = math.min(stats.min, data.ilevel)
		stats.max = math.max(stats.max, data.ilevel)
		stats.levelmax = math.max(stats.levelmax, data.level)

		stats.levelMaxCount = (stats.levelMaxCount or 0) + (data.level == MAX_LEVEL and 1 or 0)
	end

	-- Add spacing before class breakdown
	offsetY = offsetY - 10

	local header = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	header:SetPoint("TOPLEFT", 0, offsetY)
	header:SetText("|cFFFFFF00Class Breakdown:|r")
	offsetY = offsetY - 20

	for classToken, count in pairs(classCount) do
		table.insert(sortedClasses, { class = classToken, count = count, stats = classStats[classToken] })
	end

	table.sort(sortedClasses, function(a, b)
		if a.count == b.count then
			return a.class < b.class
		end
		return a.count > b.count
	end)

	for _, entry in ipairs(sortedClasses) do
		local classToken = entry.class
		local count = entry.count
		local stats = entry.stats
		local color = HeroMetrics.GetColorForCharacter(classToken)
		local className = LOCALIZED_CLASS_NAMES_MALE[classToken] or classToken
		--local avg = stats.sum / stats.count

		local line = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		line:SetPoint("TOPLEFT", 0, offsetY)

		local capped = stats.levelMaxCount or 0
		local cappedColor = (capped == count) and "|cff00ff00" or "|cffffa500"
		line:SetText(string.format(
			"• %s%s|r: |cFFFFFFFF%d|r  |cff87CEFA(Max: %d)|r  %sCapped: %d/%d",
			color, className,
			count,
			stats.levelmax,
			cappedColor, capped, count
		))
		offsetY = offsetY - 16
	end

	content:SetHeight(-offsetY + 20)
end

function HeroMetrics.CreateMinimapButton()
	if HeroMetricsMinimapButton then
		return
	end

	local button = CreateFrame("Button", "HeroMetricsMinimapButton", Minimap)
	button:SetSize(32, 32)
	button:SetFrameStrata("MEDIUM")
	button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, 5)

	button:SetNormalTexture("Interface\\Icons\\Ability_Hunter_MasterMarksman")
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
		HeroMetrics.ShowCharacterList()
	end)
end


function HeroMetrics.UpdatePlaytimeTextAndSize()
    local playtimeString, fontSize, r, g, b = HeroMetrics.UpdatePlaytimeDisplay()
    
    HeroMetrics.playtimeText:SetFont(HeroMetrics.playtimeText:GetFont(), fontSize)
    HeroMetrics.playtimeText:SetTextColor(r, g, b, 1)
    HeroMetrics.playtimeText:SetText(playtimeString)

    HeroMetrics.AdjustFrameSize()
end

function UpdateDurabilityVisual()
	local durabilityPercentage = HeroMetrics.GetDurabilityPercentage()

	if durabilityPercentage then
		if durabilityPercentage >= 90 then
			HeroMetrics.xpFrame:SetBackdropBorderColor(1, 1, 1, 1) -- White
		elseif durabilityPercentage >= 60 then
			HeroMetrics.xpFrame:SetBackdropBorderColor(1, 1, 0, 1) -- Yellow
		else
			HeroMetrics.xpFrame:SetBackdropBorderColor(1, 0.5, 0, 1) -- Orange
		end
	end
end

UpdateDurabilityVisual()

C_Timer.NewTicker(5, UpdateDurabilityVisual)