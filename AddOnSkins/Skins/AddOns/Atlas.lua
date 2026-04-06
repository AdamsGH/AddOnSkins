-- Atlas skin for AddOnSkins
-- Supports the Retail-engine Atlas fork used on TBC Anniversary servers.
-- WowStyle1DropdownTemplate dropdowns are skinned manually since SkinDropDownBox
-- targets the legacy UIDropDownMenuTemplate structure.

local AS = unpack(AddOnSkins)

local ARROW_TEX = [[Interface\AddOns\AddOnSkins\Media\Textures\Arrow]]

local function Safe(func, name)
	local f = type(name) == "string" and _G[name] or name
	if f then func(AS, f) end
end

local ARROW_ROTATION_DOWN = 3.14

local function SkinWowStyleDropdown(name)
	local f = _G[name]
	if not f or f._atlasSkinned then return end
	f._atlasSkinned = true

	-- NineSlice border pieces are child frames, not texture regions - hide them all
	for _, child in ipairs({f:GetChildren()}) do
		child:Hide()
	end

	-- Clear texture regions except Arrow, Text, Label
	for i = 1, f:GetNumRegions() do
		local r = select(i, f:GetRegions())
		if r and r ~= f.Arrow and r ~= f.Text and r ~= f.Label then
			if r.SetTexture then r:SetTexture(nil) end
			if r.SetAtlas then pcall(r.SetAtlas, r, '') end
			r:SetAlpha(0)
		end
	end

	AS:SetTemplate(f)

	if f.Arrow then
		if f.Arrow.SetAtlas then pcall(f.Arrow.SetAtlas, f.Arrow, nil) end
		f.Arrow:SetTexture(ARROW_TEX, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
		f.Arrow:SetRotation(ARROW_ROTATION_DOWN)
		f.Arrow:SetVertexColor(1, 1, 1)
		f.Arrow:SetAlpha(1)

		if f.Arrow.SetAtlas then
			hooksecurefunc(f.Arrow, 'SetAtlas', function(self)
				self:SetTexture(ARROW_TEX, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
				self:SetRotation(ARROW_ROTATION_DOWN)
				self:SetVertexColor(1, 1, 1)
			end)
		end

		f:HookScript('OnEnter', function()
			f.Arrow:SetVertexColor(unpack(AS.Color))
			if f.SetBackdropBorderColor then f:SetBackdropBorderColor(unpack(AS.Color)) end
		end)
		f:HookScript('OnLeave', function()
			f.Arrow:SetVertexColor(1, 1, 1)
			if f.SetBackdropBorderColor then f:SetBackdropBorderColor(unpack(AS.BorderColor)) end
		end)
		f:HookScript('OnMouseDown', function()
			f.Arrow:SetVertexColor(unpack(AS.Color))
		end)
		f:HookScript('OnMouseUp', function()
			f.Arrow:SetVertexColor(1, 1, 1)
		end)
	end
end

function AS:Atlas(event, addon)
	local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Atlas'))
		or (_G.IsAddOnLoaded and _G.IsAddOnLoaded('Atlas'))
	if not loaded then return end

	local AtlasFrame = _G['AtlasFrame']
	local AtlasFrameSmall = _G['AtlasFrameSmall']

	if AtlasFrame then
		AS:StripTextures(AtlasFrame)
		AS:SetTemplate(AtlasFrame)
		AS:CreateShadow(AtlasFrame)
		if AtlasFrame.Portrait then AtlasFrame.Portrait:Hide() end
		if AtlasFrame.PortraitContainer then AtlasFrame.PortraitContainer:Hide() end
	end

	if AtlasFrameSmall then
		AS:StripTextures(AtlasFrameSmall)
		AS:SetTemplate(AtlasFrameSmall)
		AS:CreateShadow(AtlasFrameSmall)
		if AtlasFrameSmall.Portrait then AtlasFrameSmall.Portrait:Hide() end
	end

	Safe(AS.CreateBackdrop, 'AtlasFrameTopInset')
	Safe(AS.CreateBackdrop, 'AtlasFrameBottomInset')

	Safe(AS.SkinCloseButton, 'AtlasFrameCloseButton')
	Safe(AS.SkinCloseButton, 'AtlasFrameSmallCloseButton')

	-- Switch buttons (UIPanelButtonTemplate) - shown under the map when only one map variant exists
	-- (SwitchDropdown is handled separately by SkinWowStyleDropdown)
	Safe(AS.SkinButton, 'AtlasFrameSwitchButton')
	Safe(AS.SkinButton, 'AtlasFrameSmallSwitchButton')

	local closeBtn = _G['AtlasFrameCloseButton']
	local lockBtn = _G['AtlasFrameLockButton']
	if lockBtn and closeBtn then
		lockBtn:SetSize(18, 18)
		AS:SkinButton(lockBtn)
		lockBtn:ClearAllPoints()
		lockBtn:SetPoint('RIGHT', closeBtn, 'LEFT', -6, 0)
	end

	local optsBtn = _G['AtlasFrameOptionsButton']
	if optsBtn and lockBtn then
		AS:SkinButton(optsBtn)
		optsBtn:ClearAllPoints()
		optsBtn:SetPoint('RIGHT', lockBtn, 'LEFT', -4, 0)
	end

	-- Collapse / Expand buttons
	local collapseBtn = _G['AtlasFrameCollapseButton']
	if collapseBtn then
		collapseBtn:SetSize(20, 20)
		AS:SkinButton(collapseBtn)
	end
	local expandBtn = _G['AtlasFrameSmallExpandButton']
	if expandBtn then
		expandBtn:SetSize(20, 20)
		AS:SkinButton(expandBtn)
	end

	-- Navigation arrows - PrevMap/NextMap live in PrevNextContainer, not directly on the parent frame
	for _, containerName in ipairs({'AtlasFramePrevNextContainer', 'AtlasFrameSmallPrevNextContainer'}) do
		local container = _G[containerName]
		if container then
			if container.PrevMap then AS:SkinArrowButton(container.PrevMap, 'left') end
			if container.NextMap then AS:SkinArrowButton(container.NextMap, 'right') end
		end
	end

	-- Icon buttons with .Icon parentKey (AdventureJournalMap, AdventureJournal, AtlasLoot)
	-- SkinIconButton saves the texture BEFORE stripping, then restores it
	for _, parent in ipairs({AtlasFrame, AtlasFrameSmall}) do
		if parent then
			local aj  = parent.AdventureJournalMap or _G[parent:GetName()..'AdventureJournalMapButton']
			local ej  = parent.AdventureJournal    or _G[parent:GetName()..'AdventureJournalButton']
			local al  = parent.AtlasLoot            or _G[parent:GetName()..'AtlasLootButton']
			if aj then AS:SkinIconButton(aj) end
			if ej then AS:SkinIconButton(ej) end
			if al then AS:SkinIconButton(al) end

			-- LFG button uses a named Texture ($parentTexture), not parentKey="Icon"
			-- Use Strip=false so the eye texture is never cleared by StripTextures;
			-- SkinButton still clears NormalTexture/HighlightTexture via SetNormalTexture('').
			local lfg = _G[parent:GetName()..'LFGButton']
			if lfg then
				AS:SkinButton(lfg)  -- no strip: preserve the ARTWORK-layer eye texture
				local eyeTex = lfg:GetName() and _G[lfg:GetName()..'Texture']
				if eyeTex then
					eyeTex:SetAlpha(1)
					AS:SetInside(eyeTex, lfg)
				end
			end
		end
	end

	local search = _G['AtlasSearchEditBox']
	if search and AtlasFrame then
		AS:SkinEditBox(search)
		search:ClearAllPoints()
		search:SetPoint('BOTTOMRIGHT', AtlasFrame, 'BOTTOMRIGHT', -10, 8)
		search:SetSize(180, 20)
	end

	C_Timer.After(0, function()
		SkinWowStyleDropdown('AtlasFrameDropDownType')
		SkinWowStyleDropdown('AtlasFrameDropDown')
		SkinWowStyleDropdown('AtlasFrameSmallDropDownType')
		SkinWowStyleDropdown('AtlasFrameSmallDropDown')

		if AtlasFrame then
			for _, child in ipairs({AtlasFrame:GetChildren()}) do
				local n = child.GetName and child:GetName()
				if n and n:find('SwitchDropdown') then
					SkinWowStyleDropdown(n)
				end
			end
		end
	end)

	-- Boss/NPC map buttons are created lazily on each map refresh.
	-- Hook Atlas_MapRefresh to skin new buttons as they appear.
	local function SkinBossButtons()
		-- AS:SkinButton doesn't set isSkinned, so use a custom flag to avoid
		-- re-skinning (and accumulating hooks) on every Atlas_MapRefresh call.
		local i, btn = 1
		btn = _G['AtlasMapBossButton'..i]
		while btn do
			if not btn._asSkinned then btn._asSkinned = true AS:SkinButton(btn) end
			i = i + 1
			btn = _G['AtlasMapBossButton'..i]
		end
		i = 1
		btn = _G['AtlasMapBossButtonS'..i]
		while btn do
			if not btn._asSkinned then btn._asSkinned = true AS:SkinButton(btn) end
			i = i + 1
			btn = _G['AtlasMapBossButtonS'..i]
		end
	end

	if _G['Atlas_MapRefresh'] then
		hooksecurefunc('Atlas_MapRefresh', function() C_Timer.After(0, SkinBossButtons) end)
	end
end

AS:RegisterSkin('Atlas', AS.Atlas)
