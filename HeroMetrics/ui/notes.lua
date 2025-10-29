local _, HeroMetrics = ...

local noteEditorFrame
local editBox
local currentCharKey

function ShowHeroNoteEditor()
	if noteEditorFrame then
		noteEditorFrame:Show()
		return
	end

	HeroMetricsDB = HeroMetricsDB or {}
	currentCharKey = UnitName("player") .. "-" .. GetRealmName()

	noteEditorFrame = CreateFrame("Frame", "HeroNoteEditorFrame", UIParent, "BackdropTemplate")
	noteEditorFrame:SetSize(360, 240)
	noteEditorFrame:SetPoint("CENTER")
	noteEditorFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	noteEditorFrame:SetMovable(true)
	noteEditorFrame:EnableMouse(true)
	noteEditorFrame:RegisterForDrag("LeftButton")
	noteEditorFrame:SetScript("OnDragStart", noteEditorFrame.StartMoving)
	noteEditorFrame:SetScript("OnDragStop", noteEditorFrame.StopMovingOrSizing)

	local dropdown = CreateFrame("Frame", "HeroNoteDropdown", noteEditorFrame, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", 10, -10)
	UIDropDownMenu_SetWidth(dropdown, 200)
	UIDropDownMenu_SetText(dropdown, currentCharKey)

	local function OnSelectChar(_, selectedKey)
		currentCharKey = selectedKey
		UIDropDownMenu_SetText(dropdown, currentCharKey)

		local charData = HeroMetricsDB[currentCharKey]
		editBox:SetText((charData and charData.note) or "")
	end

	UIDropDownMenu_Initialize(dropdown, function(self, level)
		for key, data in pairs(HeroMetricsDB) do
			if type(data) == "table" and data.note then
				local info = UIDropDownMenu_CreateInfo()
				info.text = key
				info.func = OnSelectChar
				info.arg1 = key
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end)

	local scrollFrame = CreateFrame("ScrollFrame", nil, noteEditorFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 20, -50)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

	local editBoxBackground = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
	editBoxBackground:SetAllPoints()
	editBoxBackground:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		--edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	editBoxBackground:SetBackdropColor(0, 0, 0, 0.4)
	editBoxBackground:SetBackdropBorderColor(0.5, 0.5, 0.5)

	editBox = CreateFrame("EditBox", nil, editBoxBackground)
	editBox:SetMultiLine(true)
	editBox:SetFontObject("GameFontHighlight")
	editBox:SetWidth(280)
	editBox:SetAutoFocus(true)
	editBox:SetPoint("TOPLEFT", 8, -8)
	editBox:SetPoint("BOTTOMRIGHT", -8, 8)
	editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
	editBox:SetScript("OnTabPressed", function() editBox:Insert("	") end) -- insert 4 spaces

	scrollFrame:SetScrollChild(editBox)
	--end of edit box

	local currentData = HeroMetricsDB[currentCharKey]
	editBox:SetText((currentData and currentData.note) or "")

	local saveButton = CreateFrame("Button", nil, noteEditorFrame, "UIPanelButtonTemplate")
	saveButton:SetSize(80, 24)
	saveButton:SetPoint("BOTTOMRIGHT", -40, 10)
	saveButton:SetText("Save")

	saveButton:SetScript("OnClick", function()
		HeroMetricsDB[currentCharKey] = HeroMetricsDB[currentCharKey] or {}
		HeroMetricsDB[currentCharKey].note = editBox:GetText()
		print("|cFF33FF99Note saved for " .. currentCharKey .. ".|r")
		noteEditorFrame:Hide()
	end)

	local deleteButton = CreateFrame("Button", nil, noteEditorFrame, "UIPanelButtonTemplate")
	deleteButton:SetSize(80, 24)
	deleteButton:SetPoint("BOTTOMLEFT", 20, 10)
	deleteButton:SetText("Delete")

	deleteButton:SetScript("OnClick", function()
		local data = HeroMetricsDB[currentCharKey]
		if data and data.note then
			data.note = nil
			print("|cffff4444Note deleted for " .. currentCharKey .. ".|r")
			editBox:SetText("")

			UIDropDownMenu_Initialize(dropdown, function(self, level)
				for key, data in pairs(HeroMetricsDB) do
					if type(data) == "table" and data.note then
						local info = UIDropDownMenu_CreateInfo()
						info.text = key
						info.func = OnSelectChar
						info.arg1 = key
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end)
		else
			print("|cffffff00No note to delete for this character.|r")
		end
	end)

	local closeButton = CreateFrame("Button", nil, noteEditorFrame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", 0, 0)

	noteEditorFrame:Show()
end