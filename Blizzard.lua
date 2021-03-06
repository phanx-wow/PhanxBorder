--[[--------------------------------------------------------------------
	PhanxBorder
	Adds shiny borders to things.
	Copyright 2008-2018 Phanx <addons@phanx.net>. All rights reserved.
	https://github.com/Phanx/PhanxBorder
----------------------------------------------------------------------]]

local isPhanx = select(5, GetAddOnInfo("PhanxMedia")) ~= "MISSING"
local FONT = oUFPhanxConfig and oUFPhanxConfig.font or isPhanx
	and [[Interface\AddOns\PhanxMedia\font\Asap.ttf]]
	or [[Fonts\FRIZQT__.ttf]]

local BACKDROP = {
	bgFile = [[Interface\BUTTONS\WHITE8X8]], tile = true, tileSize = 8,
	edgeFile = [[Interface\BUTTONS\WHITE8X8]], edgeSize = 2,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

------------------------------------------------------------------------

local ADDON, Addon = ...
local Masque = IsAddOnLoaded("Masque")

local AddBorder = Addon.AddBorder
local noop = Addon.noop

------------------------------------------------------------------------

local _, PLAYER_CLASS = UnitClass("player")

local function AddBorderOverlay(frame)
	AddBorder(frame)

	local overlay = CreateFrame("Frame", "$parentPhanxBorderOverlay", frame)
	overlay:SetAllPoints()
	frame:SetBorderParent(overlay)
	frame.PhanxBorderOverlay = overlay
end

local function ColorByClass(frame, class)
	if not frame.PhanxBorder then
		AddBorder(frame)
	end
	local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class and class ~= true or PLAYER_CLASS]
	frame:SetBorderColor(color.r, color.g, color.b)
end
Addon.ColorByClass = ColorByClass

local function ColorByQuality(frame, quality, link)
	if not frame.PhanxBorder then
		AddBorder(frame)
	end
	if link and not quality then
		link, link, quality = GetItemInfo(link)
	end
	if quality and quality > 1 then
		local color = ITEM_QUALITY_COLORS[quality]
		frame:SetBorderColor(color.r, color.g, color.b)
		return true
	else
		frame:SetBorderColor()
	end
end
Addon.ColorByQuality = ColorByQuality

------------------------------------------------------------------------

local AddBorderToItemButton
do
	local function IconBorder_Hide(self)
		self:GetParent():SetBorderColor()
	end
	local function IconBorder_SetVertexColor(self, r, g, b)
		self:GetParent():SetBorderColor(r, g, b)
	end
	local function Button_OnLeave(self)
		if self.IconBorder:IsShown() then
			self:SetBorderColor(self.IconBorder:GetVertexColor())
		else
			self:SetBorderColor()
		end
	end
	function AddBorderToItemButton(button)
		if button.PhanxBorder then return end

		AddBorderOverlay(button)
		if button:GetNormalTexture() then
			button:GetNormalTexture():SetTexture("") -- useless extra icon border
		end

		button.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

		button.IconBorder:SetTexture("")
		hooksecurefunc(button.IconBorder, "Hide", IconBorder_Hide)
		hooksecurefunc(button.IconBorder, "SetVertexColor", IconBorder_SetVertexColor)

		button:GetHighlightTexture():SetTexture("")
		button:HookScript("OnEnter", ColorByClass)
		button:HookScript("OnLeave", Button_OnLeave)

		if button:IsMouseOver() then
			ColorByClass(button)
		end
	end
end

------------------------------------------------------------------------

local applyFuncs = { }

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
	for i, func in pairs(applyFuncs) do
		if not func() then -- return true to keep trying
			applyFuncs[i] = nil
		end
	end
	if #applyFuncs == 0 then
		self:UnregisterAllEvents()
		self:SetScript("OnEvent", nil)
		applyFuncs = nil
	elseif event == "PLAYER_LOGIN" then
		self:RegisterEvent("ADDON_LOADED")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end)

------------------------------------------------------------------------
--	Bordered tooltips
------------------------------------------------------------------------

local borderedTooltipRegions = {
	"Background",
	"BorderBottom",
	"BorderBottomLeft",
	"BorderBottomRight",
	"BorderLeft",
	"BorderRight",
	"BorderTop",
	"BorderTopLeft",
	"BorderTopRight",
}

function Addon.ProcessBorderedTooltip(f)
	--print("Adding border to", f:GetName())
	for _, region in pairs(borderedTooltipRegions) do
		f[region]:SetTexture("")
	end
	f:SetBackdrop(BACKDROP)
	f:SetBackdropColor(0, 0, 0, 0.8)
	AddBorder(f)
end

local borderedTooltips = {
	"BattlePetTooltip",
	"FloatingBattlePetTooltip",
	"FloatingGarrisonFollowerTooltip",
	"LFDSearchStatus",
	"PetBattlePrimaryAbilityTooltip",
	"PetBattlePrimaryUnitTooltip",
	"PetJournalPrimaryAbilityTooltip",
	"PetJournalSecondaryAbilityTooltip",
	"QueueStatusFrame",
}

tinsert(applyFuncs, function()
	for i = #borderedTooltips, 1, -1 do
		local name = borderedTooltips[i]
		local f = _G[name]
		if f then
			Addon.ProcessBorderedTooltip(f)
			tremove(borderedTooltips, i)
		end
	end
	if #borderedTooltips > 0 then
		return true
	end
	borderedTooltips = nil
end)

------------------------------------------------------------------------
--	FrameXML
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	for frame, offset in pairs({
		["GhostFrame"] = 2,
		["HelpFrameCharacterStuckHearthstone"] = false,
		["TicketStatusFrame"] = false,

		["DropDownList1MenuBackdrop"] = false,
		["DropDownList2MenuBackdrop"] = false,

		["FriendsTooltip"] = false,
		["GameTooltip"] = false,
		["ItemRefShoppingTooltip1"] = false,
		["ItemRefShoppingTooltip2"] = false,
		["ItemRefTooltip"] = false,
		["PartyMemberBuffTooltip"] = false,
		["ShoppingTooltip1"] = false,
		["ShoppingTooltip2"] = false,
		["SmallTextTooltip"] = false,
		["VideoOptionsTooltip"] = false,
		["WorldMapCompareTooltip1"] = false,
		["WorldMapCompareTooltip2"] = false,
		["WorldMapTooltip"] = false,

		["MerchantRepairItemButton"] = 3,
		["MerchantRepairAllButton"] = 3,
		["MerchantBuyBackItemItemButton"] = 1,

		["PrimaryProfession1SpellButtonBottom"]  = 3,
		["PrimaryProfession1SpellButtonTop"]     = 3,
		["PrimaryProfession2SpellButtonBottom"]  = 3,
		["PrimaryProfession2SpellButtonTop"]     = 3,
		["SecondaryProfession1SpellButtonLeft"]  = 3,
		["SecondaryProfession1SpellButtonRight"] = 3,
		["SecondaryProfession2SpellButtonLeft"]  = 3,
		["SecondaryProfession2SpellButtonRight"] = 3,
		["SecondaryProfession3SpellButtonLeft"]  = 3,
		["SecondaryProfession3SpellButtonRight"] = 3,
		["SecondaryProfession4SpellButtonLeft"]  = 3,
		["SecondaryProfession4SpellButtonRight"] = 3,
	}) do
		--print("Adding border to", frame)
		AddBorder(_G[frame], nil, offset)
		if _G[frame.."NameFrame"] then
			_G[frame.."NameFrame"]:SetTexture("")
		end
	end

	if type(GetMinimapShape) == "function" and GetMinimapShape() == "SQUARE" then
		AddBorder(Minimap)
	end

	GhostFrame:SetWidth(140)
	GhostFrame:SetBackdrop(BACKDROP)
	GhostFrame:SetBackdropColor(0, 0, 0, 0.8)
	GhostFrameLeft:SetTexture("")
	GhostFrameRight:SetTexture("")
	GhostFrameMiddle:SetTexture("")
	GhostFrameContentsFrameIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	---------------------------------------------------------------------
	-- Bags
	---------------------------------------------------------------------
	-- TODO: test
	hooksecurefunc("ContainerFrame_Update", function(self)
		local bag = self:GetID()
		local name = self:GetName()
		for slot = 1, self.size do
			local button = _G[name.."Item"..slot]
			AddBorderToItemButton(button)
		end
	end)

	---------------------------------------------------------------------
	--	Bank
	---------------------------------------------------------------------
	-- TODO: use a better function?
	hooksecurefunc("BankFrameItemButton_Update", function(button)
		AddBorderToItemButton(button)
	end)

	---------------------------------------------------------------------
	--	Character frame
	---------------------------------------------------------------------

	for _, slot in pairs({
		"CharacterHeadSlot",
		"CharacterNeckSlot",
		"CharacterShoulderSlot",
		"CharacterBackSlot",
		"CharacterChestSlot",
		"CharacterShirtSlot",
		"CharacterTabardSlot",
		"CharacterWristSlot",
		"CharacterHandsSlot",
		"CharacterWaistSlot",
		"CharacterLegsSlot",
		"CharacterFeetSlot",
		"CharacterFinger0Slot",
		"CharacterFinger1Slot",
		"CharacterTrinket0Slot",
		"CharacterTrinket1Slot",
		"CharacterMainHandSlot",
		"CharacterSecondaryHandSlot",
	}) do
		local f = _G[slot]
		AddBorderToItemButton(f)
		f:SetBorderInsets(2) -- not enough spacing between buttons for just 1
		_G[slot.."Frame"]:SetTexture("")
	end

	select(11, CharacterMainHandSlot:GetRegions()):SetTexture("")
	select(11, CharacterSecondaryHandSlot:GetRegions()):SetTexture("")

	hooksecurefunc("PaperDollItemSlotButton_Update", function(self)
		-- Despite these buttons having an IconBorder the default UI does not use it;
		-- fix that oversight so PhanxBorder colors will also work.
		-- This function doesn't depend on PhanxBorder and will work in any addon.
		local item = GetInventoryItemLink("player", self:GetID())
		if not item then return end
		local _, _, quality = GetItemInfo(item)
		if quality and quality > 1 then
			local color = ITEM_QUALITY_COLORS[quality]
			self.IconBorder:SetVertexColor(color.r, color.g, color.b)
			self.IconBorder:Show()
		else
			self.IconBorder:Hide()
		end
	end)

	-- Equipment flyouts

	hooksecurefunc("EquipmentFlyout_Show", function(parent)
		local f = EquipmentFlyoutFrame.buttonFrame
		for i = 1, f.numBGs do
			f["bg"..i]:SetTexture("")
		end
	end)

	hooksecurefunc("EquipmentFlyout_DisplayButton", AddBorderToItemButton)

	-- Equipment manager

	hooksecurefunc("PaperDollEquipmentManagerPane_Update", function()
		local buttons = PaperDollEquipmentManagerPane.buttons
		for i = 1, #buttons do
			local button = buttons[i]
			if not button.PhanxBorder then
				AddBorderOverlay(button)
				button:SetBorderInsets(3, 129, 4, 4)
				button.BgTop:SetTexture("")
				button.BgMiddle:SetTexture("")
				button.BgBottom:SetTexture("")
			end
			button:SetBorderAlpha(button.name and 1 or 0)
			if button.Check:IsShown() then
				button:SetBorderColor(1, 0.82, 0)
			else
				button:SetBorderColor()
			end
		end
	end)

	---------------------------------------------------------------------
	-- Loot
	---------------------------------------------------------------------
	-- TODO: test
	hooksecurefunc("LootFrame_UpdateButton", function(index)
		local button = _G["LootButton"..index]
		AddBorderToItemButton(button)
		--ColorByQuality(button, button:IsEnabled() and button.quality)
	end)

	---------------------------------------------------------------------
	-- Mailbox
	---------------------------------------------------------------------

	for i = 1, INBOXITEMS_TO_DISPLAY do
		local button = _G["MailItem"..i.."Button"]
		local slot, icon = button:GetRegions()
		slot:SetTexture("")
		icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
		AddBorder(button, nil, 1)
		button:SetBorderLayer("OVERLAY")
	end

	hooksecurefunc("InboxFrame_Update", function()
		local numItems = GetInboxNumItems()
		local index = ((InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY) + 1
		for i = 1, INBOXITEMS_TO_DISPLAY do
			local best = 0
			if index <= numItems then
				for j = 1, ATTACHMENTS_MAX_RECEIVE do
					-- GetInboxItem is bugged since 2.3.3 (lol) and always returns quality -1
					-- local _, _, _, quality = GetInboxItem(index, j)
					local link = GetInboxItemLink(index, j)
					if link then
						local _, _, quality = GetItemInfo(link)
						best = quality and quality > best and quality or best
					end
				end
			end
			ColorByQuality(_G["MailItem"..i.."Button"], best)
			index = index + 1
		end
	end)

	-------------------
	-- Received mail
	-------------------

	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		local button = _G["OpenMailAttachmentButton"..i]
		_G["OpenMailAttachmentButton"..i.."NormalTexture"]:SetTexture("") -- ugly border thing
		AddBorderToItemButton(button)
	end

	AddBorder(OpenMailLetterButton, nil, 2)

	------------------
	-- Sending mail
	------------------

	local function SendMailAttachment_OnLeave(self)
		local link = GetSendMailItemLink(self:GetID())
		ColorByQuality(self, nil, link)
	end

	for i = 1, ATTACHMENTS_MAX_SEND do
		local button = _G["SendMailAttachment"..i]
		AddBorder(button, nil, 1)
		button:GetRegions():SetTexCoord(0, 0.62, 0, 0.61) -- empty slot texture
		button:HookScript("OnEnter", ColorByClass)
		button:HookScript("OnLeave", SendMailAttachment_OnLeave)
	end

	hooksecurefunc("SendMailFrame_Update", function()
		if not SendMailFrame:IsShown() then return end
		for i = 1, ATTACHMENTS_MAX_SEND do
			-- GetSendMailItem is bugged since 2.3.3 (lol) and always returns quality -1
			-- local _, _, quality = GetSendMailItem(i)
			local button = _G["SendMailAttachment"..i]
			local link = GetSendMailItemLink(i)
			ColorByQuality(button, nil, link)
			local icon = button:GetNormalTexture()
			if icon then
				icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
			end
		end
	end)

	---------------------------------------------------------------------
	-- Merchant frame
	---------------------------------------------------------------------

	MerchantBuyBackItemNameFrame:SetTexture("")

	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		AddBorderToItemButton(_G["MerchantItem"..i.."ItemButton"])
	end

	for i = 1, BUYBACK_ITEMS_PER_PAGE do
		AddBorderToItemButton(_G["MerchantItem"..i.."ItemButton"])
	end

	--[[
	hooksecurefunc("MerchantFrame_Update", function()
		if not MerchantFrame:IsShown() then return end
		if MerchantFrame.selectedTab == 1 then
			for i = 1, MERCHANT_ITEMS_PER_PAGE do
				local index = i + ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE)
				local link = GetMerchantItemLink(index)
				ColorByQuality(_G["MerchantItem"..i.."ItemButton"], nil, link)
			end

			local link = GetBuybackItemLink(GetNumBuybackItems())
			ColorByQuality(MerchantBuyBackItemItemButton, nil, link)
		else
			for i = 1, BUYBACK_ITEMS_PER_PAGE do
				local link = GetBuybackItemLink(i)
				ColorByQuality(_G["MerchantItem"..i.."ItemButton"], nil, link)
			end
		end
	end)
	]]

	---------------------------------------------------------------------
	-- Pet stable
	---------------------------------------------------------------------

	for i = 1, 10 do
		AddBorder(_G["PetStableStabledPet"..i])
	end

	---------------------------------------------------------------------
	-- Quest frames
	---------------------------------------------------------------------
--[[
	local function AddItemBorder(f)
		AddBorder(f)
		local icon = f.icon or f.Icon or _G[f:GetName().."IconTexture"]
		local name = f.name or f.Name or _G[f:GetName().."Name"]
		if icon then
			icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		end
		if name then
			name:SetFontObject("QuestFontNormalSmall")
			_G[f:GetName().."NameFrame"]:SetTexture("")
		end
	end

	AddItemBorder(QuestInfoRewardSpell)
	QuestInfoRewardSpellSpellBorder:SetTexture("")

	AddItemBorder(QuestInfoSkillPointFrame)

	for i = 1, MAX_NUM_ITEMS do
		AddBorder(_G["QuestInfoItem"..i])
		if isPhanx then
			_G["QuestInfoItem"..i.."Name"]:SetFontObject(QuestFontNormalSmall)
			_G["QuestInfoItem"..i.."NameFrame"]:SetTexture("")
		end
	end

	hooksecurefunc("QuestInfo_Display", function()
		-- Have to set border sizes here because scale is weird at PLAYER_LOGIN
		QuestInfoRewardSpell:SetBorderInsets(10, 108, 2, 14) -- still 4px bigger (2px each inset) than skillpoints and items
		QuestInfoSkillPointFrame:SetBorderInsets(-1, 112, 2, 3)
		for i = 1, MAX_NUM_ITEMS do
			local f = _G["QuestInfoItem"..i]
			local link = f.type and (QuestInfoFrame.questLog and GetQuestLogItemLink or GetQuestItemLink)(f.type, f:GetID())
			ColorByQuality(f, nil, link)
			f:SetBorderInsets(2, 109, 2, 3)
		end
	end)

	for i = 1, MAX_REQUIRED_ITEMS do
		local f = _G["QuestProgressItem"..i]
		AddItemBorder(f)
		f:SetBorderInsets(2, 107, 1, 2)
	end

	hooksecurefunc("QuestFrameProgressItems_Update", function()
		--print("QuestFrameProgressItems_Update")
		for i = 1, MAX_REQUIRED_ITEMS do
			local f = _G["QuestProgressItem"..i]
			local link = f.type and GetQuestItemLink(f.type, f:GetID())
			ColorByQuality(f, nil, link)
		end
	end)
]]
	---------------------------------------------------------------------
	-- Spellbook
	---------------------------------------------------------------------

	local function SkinTab(tab)
		if tab.PhanxBorder then return end
		AddBorder(tab)

		tab:GetNormalTexture():SetTexCoord(0.06, 0.94, 0.06, 0.94)
		tab:GetNormalTexture():SetDrawLayer("BORDER", 0)

		tab:GetCheckedTexture():SetDrawLayer("BORDER", 1)
		tab:GetCheckedTexture():SetPoint("TOPLEFT", -2, 2)
		tab:GetCheckedTexture():SetPoint("BOTTOMRIGHT", 2, -2)

		tab:GetHighlightTexture():SetPoint("TOPLEFT", -3, 3)
		tab:GetHighlightTexture():SetPoint("BOTTOMRIGHT", 3, -3)
	end

	local function Button_OnDisable(self)
		self:SetAlpha(0)
	end
	local function Button_OnEnable(self)
		self:SetAlpha(1)
	end
	local function Button_OnEnter(self)
		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[PLAYER_CLASS]
		self:SetBorderColor(color.r, color.g, color.b)
	end
	local function Button_OnLeave(self)
		self:SetBorderColor()
	end

	for i = 1, SPELLS_PER_PAGE do
		local button = _G["SpellButton" .. i]
		AddBorder(button, nil, nil, false)
		button.EmptySlot:SetTexture("")
		button.UnlearnedFrame:SetTexture("")
		button.SpellHighlightTexture:SetTexture("") -- not on action bar
		_G["SpellButton" .. i .. "SlotFrame"]:SetTexture("") -- swirly thing
		_G["SpellButton" .. i .. "IconTexture"]:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		button:HookScript("OnDisable", Button_OnDisable)
		button:HookScript("OnEnable",  Button_OnEnable)
		button:HookScript("OnEnter",   Button_OnEnter)
		button:HookScript("OnLeave",   Button_OnLeave)
		if isPhanx then
			button.SpellName:SetFont(FONT, 16)
		end
	end

	for i = 1, 5 do
		SkinTab(_G["SpellBookSkillLineTab"..i])
	end

	---------------------------------------------------------------------
	-- Static popups
	---------------------------------------------------------------------

	AddBorder(StaticPopup1ItemFrame)

	---------------------------------------------------------------------
	-- Trade window
	---------------------------------------------------------------------

	for i = 1, 7 do
		AddBorderToItemButton(_G["TradePlayerItem"..i.."ItemButton"])
		AddBorderToItemButton(_G["TradeRecipientItem"..i.."ItemButton"])
	end

	--[[
	hooksecurefunc("TradeFrame_UpdatePlayerItem", function(i)
		local link = GetTradePlayerItemLink(i)
		ColorByQuality(_G["TradePlayerItem"..i.."ItemButton"], nil, link)
	end)

	hooksecurefunc("TradeFrame_UpdateTargetItem", function(i)
		local _, _, _, quality = GetTradeTargetItemInfo(i)
		ColorByQuality(_G["TradeRecipientItem"..i.."ItemButton"], quality)
	end)
	]]

	---------------------------------------------------------------------
	-- Done!
	---------------------------------------------------------------------
end)

------------------------------------------------------------------------
--	Blizzard_DebugTools
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not EventTraceTooltip then return true end
	AddBorder(EventTraceTooltip)
	AddBorder(FrameStackTooltip)
end)

------------------------------------------------------------------------
--	Blizzard_GuildBankUI
------------------------------------------------------------------------
-- TODO: use AddBorderToItemButton ?
tinsert(applyFuncs, function()
	if not GuildBankFrame then return true end

	hooksecurefunc("GuildBankFrame_ShowColumns", function()
		local tab = GetCurrentGuildBankTab()
		for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
			local row = mod(i, NUM_SLOTS_PER_GUILDBANK_GROUP)
			if row == 0 then
				row = NUM_SLOTS_PER_GUILDBANK_GROUP
			end
			local col = ceil((i - 0.5) / NUM_SLOTS_PER_GUILDBANK_GROUP)
			local button = _G["GuildBankColumn"..col.."Button"..row]
			local link = GetGuildBankItemLink(tab, i)
			ColorByQuality(button, nil, link)
		end
	end)
end)

------------------------------------------------------------------------
--	Blizzard_InspectUI
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not InspectPaperDollItemSlotButton_Update then return true end

	hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(button)
		AddBorderToItemButton(button)
	end)
--[[
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(button)
		local item = GetInventoryItemID(InspectFrame.unit, button:GetID())
		ColorByQuality(button, nil, item)
	end)
]]
end)

------------------------------------------------------------------------
--	Blizzard_PetBattleUI
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not PetBattleFrame then return true end

	hooksecurefunc("PetBattleFrame_UpdateAllActionButtons", function(self)
		--print("PetBattleFrame_UpdateAllActionButtons")
		local f = self.BottomFrame
		if f.CatchButton.PhanxBorder then return end

		AddBorder(f.CatchButton, nil, 2)
		AddBorder(f.ForfeitButton, nil, 2)
		AddBorder(f.SwitchPetButton, nil, 2)

		for i = 1, #f.abilityButtons do
			AddBorder(f.abilityButtons[i], nil, 2)
		end
	end)

	-- Fix battle pet ability selection glow not appearing after the first turn
	hooksecurefunc("PetBattleActionButton_UpdateState", function(self)
		if not self.SelectedHighlight then return end
		local actionType, actionIndex = self.actionType, self.actionIndex
		local selectedType, selectedIndex = C_PetBattles.GetSelectedAction()
		self.SelectedHighlight:SetShown(selectedType and selectedType == actionType and (not actionIndex or selectedIndex == actionIndex))
	end)

	-- TODO: Fix checked texture sticking on switch button after use
end)

------------------------------------------------------------------------
--	Blizzard_Collections
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not MountJournalListScrollFrame then return true end

	local function qualityBorder_SetVertexColor(self, r, g, b)
		self:GetParent().dragButton:SetBorderColor(r, g, b)
	end

	---------------------------------------------------------------------
	-- Mount Journal
	---------------------------------------------------------------------

	local function FixTexture(icon, texture)
		if texture == "Interface\\PetBattles\\MountJournalEmptyIcon" then
			icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
			icon:GetParent():Hide()
		else
			icon:SetTexCoord(0, 1, 0, 1)
			icon:GetParent():Show()
		end
	end
	for i = 1, #MountJournalListScrollFrame.buttons do
		local button = MountJournalListScrollFrame.buttons[i]
		button.favorite:SetParent(button.DragButton)
		button.name:SetWidth(button:GetWidth())
		AddBorder(button.DragButton, nil, 2)
		hooksecurefunc(button.icon, "SetTexture", FixTexture)
	end

	---------------------------------------------------------------------
	-- Pet Journal
	---------------------------------------------------------------------

	AddBorder(PetJournalHealPetButton)
	PetJournalHealPetButtonBorder:SetTexture("")
	PetJournalHealPetButton.texture:SetDrawLayer("BACKGROUND")
	PetJournalHealPetButton.BlackCover:SetDrawLayer("ARTWORK")

	do
		local f = PetJournalPetCardPetInfo

		local iconFrame = CreateFrame("Frame", nil, f)
		iconFrame:SetAllPoints(f.icon)
		AddBorder(iconFrame, nil, 2)

		f.favorite:SetParent(iconFrame)
		f.levelBG:SetParent(iconFrame)
		f.level:SetParent(iconFrame)

		f.dragButton = iconFrame
		hooksecurefunc(f.qualityBorder, "SetVertexColor", qualityBorder_SetVertexColor)
	end

	for i = 1, 6 do
		AddBorder(_G["PetJournalPetCardSpell"..i], nil, 2)
	end

	for i = 1, 2 do
		AddBorder(_G["PetJournalSpellSelectSpell"..i], nil, 2)
		select(i, PetJournalSpellSelect:GetRegions()):SetTexture("")
	end

	for i = 1, 3 do
		local f = _G["PetJournalLoadoutPet"..i]
		AddBorder(f.dragButton, nil, 2)
		f.levelBG:SetParent(f.dragButton)
		f.level:SetParent(f.dragButton)
		hooksecurefunc(f.qualityBorder, "SetVertexColor", qualityBorder_SetVertexColor)

		for j = 1, 3 do
			AddBorder(_G["PetJournalLoadoutPet"..i.."Spell"..j])
		end
	end

	local function IconBorder_SetVertexColor(iconBorder, ...)
		return iconBorder:GetParent().dragButton:SetBorderColor(...)
	end

	for i = 1, #PetJournalListScrollFrame.buttons do
		local button = PetJournalListScrollFrame.buttons[i]
		AddBorder(button.dragButton, nil, 2)
		button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		button.iconBorder.SetVertexColor = IconBorder_SetVertexColor
		button.iconBorder.Hide = IconBorder_SetVertexColor
	end

	-------------
	-- Toy Box
	-------------

	for i = 1, 18 do
		local button = ToyBox.iconsFrame["spellButton"..i]
		AddBorder(button)
		button:SetBorderLayer("OVERLAY")
		button:SetBorderInsets(5, 5, 3, 7)
		button.slotFrameCollected:SetTexture("")
		button.slotFrameUncollected:SetTexture("")
		button.slotFrameUncollectedInnerGlow:SetTexture("")
	end

	hooksecurefunc("ToySpellButton_UpdateButton", function(self)
		self.iconTextureUncollected:SetAlpha(0.5)
		if self.itemID then
			ColorByQuality(self, nil, self.itemID)
		end
	end)

	-------------
	-- Heirlooms
	-------------

	hooksecurefunc(HeirloomsJournal, "LayoutCurrentPage", function(self)
		for i = 1, #self.heirloomEntryFrames do
			local button = self.heirloomEntryFrames[i]
			AddBorder(button)
			button:SetBorderLayer("OVERLAY")
			button:SetBorderInsets(5, 5, 3, 7)
			button.iconTextureUncollected:SetAlpha(0.5)
			button.slotFrameCollected:SetTexture("")
			button.slotFrameUncollected:SetTexture("")
			button.slotFrameUncollectedInnerGlow:SetTexture("")
		end
	end)

	hooksecurefunc(HeirloomsJournal, "UpdateButton", function(self, button)
		if C_Heirloom.PlayerHasHeirloom(button.itemID) then
			ColorByQuality(button, LE_ITEM_QUALITY_HEIRLOOM)
			button:SetAlpha(1)
		else
			ColorByQuality(button)
			button:SetAlpha(0.5)
			button.name:SetTextColor(1, 0.82, 0, 1)
			button.name:SetShadowColor(0, 0, 0, 1)
			button.special:SetTextColor(.427, .352, 0, 1)
			button.special:SetShadowColor(0, 0, 0, 1)
		end
	end)
--[[
	-------------
	-- Wardrobe
	-------------
	local WARDROBE_PAGE_SIZE = 18

	for i = 1, WARDROBE_PAGE_SIZE do
    	local model = WardrobeCollectionFrame.ModelsFrame.Models[i]
		model.Border:Hide()
		AddBorder(model, nil, -1)
	end

	hooksecurefunc("WardrobeCollectionFrame_Update", function(button)
		for i = 1, WARDROBE_PAGE_SIZE do
			local index = i + (WardrobeCollectionFrame_GetCurrentPage() - 1) * WARDROBE_PAGE_SIZE
    		local visualInfo = WardrobeCollectionFrame.filteredVisualsList[index]
    		if visualInfo then
				local model = WardrobeCollectionFrame.ModelsFrame.Models[i]
				if not visualInfo.isCollected then
					model:SetBorderColor(0.25, 0.25, 0.25)
				elseif not visualInfo.isUsable then
					model:SetBorderColor(0.7, 0.3, 0.3)
				else
					model:SetBorderColor()
				end
			end
		end
	end)
]]
end)

------------------------------------------------------------------------
--	Blizzard_TalentUI
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not PlayerTalentFrame then return true end

	AddBorder(PlayerTalentFrameSpecializationSpellScrollFrameScrollChildAbility1, nil, 10)
	PlayerTalentFrameSpecializationSpellScrollFrameScrollChildAbility1.ring:Hide()

	hooksecurefunc("PlayerTalentFrame_CreateSpecSpellButton", function(self, index)
		local f = self.spellsScroll.child["abilityButton"..index]
		AddBorder(f, nil, 10)
		f.ring:Hide()
	end)

	hooksecurefunc("PlayerTalentFrame_UpdateSpecFrame", function(self, spec)
		local shownSpec = self.previewSpec
		local bonuses
		if self.isPet then
			bonuses = { GetSpecializationSpells(shownSpec, nil, self.isPet, true) }
		else
			local sex = self.isPet and UnitSex("pet") or UnitSex("player")
			local id = GetSpecializationInfo(shownSpec, nil, self.isPet, nil, sex)
			bonuses = SPEC_SPELLS_DISPLAY[id]
		end
		if bonuses then
			local index = 1
			for i = 1, #bonuses, 2 do
				local frame = self.spellsScroll.child["abilityButton"..index]
				local _, icon = GetSpellTexture(bonuses[i])
				frame.icon:SetTexture(icon)
				index = index + 1
			end
		end
	end)

	for row = 1, 7 do
		for col = 1, 3 do
			local f = _G["PlayerTalentFrameTalentsTalentRow"..row.."Talent"..col]
			AddBorderOverlay(f)
			f:SetBorderInsets(35, 121, 4, 4)
			f.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		end
	end
end)

---------------------------------------------------------------------
-- Blizzard_TradeSkillUI
---------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not TradeSkillFrame then return true end

	AddBorder(TradeSkillSkillIcon, nil, 1)

	hooksecurefunc("TradeSkillFrame_SetSelection", function(i)
		local link = GetTradeSkillItemLink(i)
		ColorByQuality(TradeSkillSkillIcon, nil, link)

		for j = 1, GetTradeSkillNumReagents(i) do
			local button = _G["TradeSkillReagent"..j]
			local link = GetTradeSkillReagentItemLink(i, j)
			ColorByQuality(button, nil, link)
			button:SetBorderInsets(0, 107, 0, 3)
		end
	end)
end)
]]
---------------------------------------------------------------------
-- Blizzard_VoidStorageUI
---------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not VoidStorage_ItemsUpdate then return true end

	local function setup(button)
		AddBorderToItemButton(button)
		button:SetBorderInsets(1)
		button:SetBorderLayer("OVERLAY")
		button.searchOverlay:SetDrawLayer("ARTWORK")
		button:GetPushedTexture():SetTexture("")
	end
	for i = 1, 9 do
		setup(_G["VoidStorageDepositButton"..i])
		setup(_G["VoidStorageWithdrawButton"..i])
	end
	for i = 1, 80 do
		setup(_G["VoidStorageStorageButton"..i])
	end
	setup = nil

	hooksecurefunc("VoidStorage_ItemsUpdate", function(doDeposit, doContents)--[[
		if doDeposit then
			for i = 1, 9 do
				local button = _G["VoidStorageDepositButton"..i]
				local item, _, quality = GetVoidTransferDepositInfo(i)
				ColorByQuality(button, quality)
			end
		end]]
		if doContents then--[[
			for i = 1, 9 do
				local button = _G["VoidStorageWithdrawButton"..i]
				local item, _, quality = GetVoidTransferWithdrawalInfo(i)
				ColorByQuality(button, quality)
			end]]
			for i = 1, 80 do
				local button = _G["VoidStorageStorageButton"..i]
		--		local item, _, _, recent, _, quality = GetVoidItemInfo(VoidStorageFrame.page, i)
				if button.antsFrame then
					button.IconBorder:SetVertexColor(1, 0.82, 0) -- highlight new deposits less obtrusively
					button.antsFrame:Hide()
		--		else
		--			ColorByQuality(button, quality)
				end
			end
		end
	end)
end)
