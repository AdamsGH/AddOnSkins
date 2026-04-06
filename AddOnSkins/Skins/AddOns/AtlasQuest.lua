-- AtlasQuest skin for AddOnSkins
-- AtlasQuestFrame inherits BackdropTemplate and is a child of AtlasFrame.
-- AtlasQuestInsideFrame overlays the map area with quest details.

local AS = unpack(AddOnSkins)

local function Safe(func, name)
	local f = type(name) == "string" and _G[name] or name
	if f then func(AS, f) end
end

-- Clears all button-state textures including Atlas variants used by the retail engine,
-- then delegates to AS:SkinCheckBox for the inset child backdrop.
local function SkinCheckBox(cb)
	if not cb or cb._asSkinned then return end
	cb._asSkinned = true

	if cb.SetNormalTexture    then cb:SetNormalTexture('') end
	if cb.SetHighlightTexture then cb:SetHighlightTexture('') end
	if cb.SetPushedTexture    then cb:SetPushedTexture('') end
	if cb.SetDisabledTexture  then cb:SetDisabledTexture('') end

	local function kill(tex)
		if not tex then return end
		if tex.SetTexture then tex:SetTexture(nil) end
		if tex.SetAtlas   then tex:SetAtlas('') end
		tex:SetAlpha(0) tex:Hide()
	end
	kill(cb.GetNormalTexture    and cb:GetNormalTexture())
	kill(cb.GetHighlightTexture and cb:GetHighlightTexture())
	kill(cb.GetPushedTexture    and cb:GetPushedTexture())

	-- Do NOT SetAlpha(0) on GetRegions() results - CheckedTexture lives there on the retail
	-- engine and zeroing its alpha persists after AS:SkinCheckBox restores the texture path.
	for i = 1, cb:GetNumRegions() do
		local r = select(i, cb:GetRegions())
		if r then
			if r.SetTexture then r:SetTexture(nil) end
			if r.SetAtlas   then r:SetAtlas('') end
		end
	end

	if cb.SetBackdrop then cb:SetBackdrop(nil) end

	AS:SkinCheckBox(cb)

	local blankTex = (_G.ElvUI and _G.ElvUI[1].media.blankTex) or [[Interface\Buttons\WHITE8X8]]
	cb:SetCheckedTexture(blankTex)
	local ct = cb.GetCheckedTexture and cb:GetCheckedTexture()
	if ct then
		ct:SetVertexColor(unpack(AS.Color))
		ct:SetAlpha(1)
		if cb.Backdrop then AS:SetInside(ct, cb.Backdrop) end
	end
	if cb.Backdrop then
		cb:HookScript('OnShow', function(f)
			if f:GetChecked() then
				f.Backdrop:SetBackdropBorderColor(unpack(AS.Color))
			else
				f.Backdrop:SetBackdropBorderColor(unpack(AS.BorderColor))
			end
		end)
		hooksecurefunc(cb, 'SetChecked', function(f, checked)
			if f.Backdrop then
				if checked then
					f.Backdrop:SetBackdropBorderColor(unpack(AS.Color))
				else
					f.Backdrop:SetBackdropBorderColor(unpack(AS.BorderColor))
				end
			end
		end)
	end
end

local function SkinQuestItemFrames()
	for i = 1, 6 do
		local item = _G['AQ_QuestItem_'..i]
		if not item or item._asSkinned then break end
		item._asSkinned = true

		if item.icon then
			AS:SkinTexture(item.icon)
			item.icon:SetSize(24, 24)
			local iconBD = CreateFrame('Frame', nil, item)
			iconBD:SetPoint('TOPLEFT', item.icon, -1, 1)
			iconBD:SetPoint('BOTTOMRIGHT', item.icon, 1, -1)
			AS:SetTemplate(iconBD)
			iconBD:SetFrameLevel(item:GetFrameLevel() - 1)
		end

		if item.qualityBorder then
			item.qualityBorder:SetTexture(nil)
			hooksecurefunc(item.qualityBorder, 'SetVertexColor', function(self, r, g, b)
				if item.icon and item.icon:GetParent() then
					-- iconBD uses SetTemplate (inline backdrop), not a child .Backdrop frame
					item.icon:GetParent():SetBackdropBorderColor(r, g, b)
				end
			end)
		end
	end
end

local function SkinQuestListButtons()
	for i = 1, 23 do
		local btn = _G['AQButton_'..i]
		if not btn or btn._asSkinned then break end
		btn._asSkinned = true

		btn:SetHighlightTexture(AS.NormTex or [[Interface\Buttons\UI-Listbox-Highlight]])
		local hl = btn:GetHighlightTexture()
		if hl then
			hl:SetVertexColor(unpack(AS.Color))
			hl:SetAlpha(0.35)
		end
	end
end

function AS:AtlasQuest(event, addon)
	local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('AtlasQuest'))
		or (_G.IsAddOnLoaded and _G.IsAddOnLoaded('AtlasQuest'))
	if not loaded then return end

	Safe(AS.SkinFrame, 'AtlasQuestFrame')
	Safe(AS.SkinCloseButton, 'AQ_SidebarClose')
	Safe(AS.SkinButton, 'AQ_OptionsButton')

	SkinCheckBox(_G['AQ_AllianceCheck'])
	SkinCheckBox(_G['AQ_HordeCheck'])

	local insideFrame = _G['AtlasQuestInsideFrame']
	if insideFrame then
		AS:StripTextures(insideFrame)
		AS:SetTemplate(insideFrame)
	end

	Safe(AS.SkinCloseButton, 'AQ_QuestClose')
	SkinCheckBox(_G['AQ_FinishedQuestCheck'])
	Safe(AS.SkinButton, 'AQ_AtlasToggle')

	-- Quest list buttons and item frames are created in OnEnable, defer skinning
	C_Timer.After(0.1, function()
		SkinQuestListButtons()
		SkinQuestItemFrames()
	end)
end

AS:RegisterSkin('AtlasQuest', AS.AtlasQuest)
