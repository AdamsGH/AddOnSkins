-- AtlasLootClassic skin for AddOnSkins
-- Targets the sliccer fork (AtlasLootClassic) used on TBC Anniversary servers.
-- GUI frames and BiS footer are created lazily, so skinning is deferred and hooked.

local AS = unpack(AddOnSkins)

local skinned = false
local footerSkinned = false

local ddHooked = {}

local function SkinALDropDownPopup()
	local i = 1
	while true do
		local f = _G['AtlasLoot-DropDown-CatFrame'..i]
		if not f then break end
		if f:IsShown() then
			-- Re-apply template (frame is reused from cache, backdrop gets reset by AtlasLoot)
			AS:SetTemplate(f)
			-- Hook SetBackdropColor once per frame object
			if not ddHooked[f] then
				ddHooked[f] = true
				hooksecurefunc(f, 'SetBackdropColor', function(self, r, g, b, a)
					local br, bg, bb, ba = unpack(AS.BackdropColor)
					if r ~= br or g ~= bg or b ~= bb then
						self:SetBackdropColor(br, bg, bb, ba)
					end
				end)
			end
			if f.buttons then
				for _, btn in ipairs(f.buttons) do
					if not btn._asSkinned then
						btn._asSkinned = true
						btn:SetHighlightTexture(AS.NormTex or [[Interface\Buttons\UI-Listbox-Highlight]])
						local hl = btn:GetHighlightTexture()
						if hl then
							hl:SetVertexColor(unpack(AS.Color))
							hl:SetAlpha(0.35)
						end
					end
				end
			end
		end
		i = i + 1
	end
end

local function SkinALDropDown(widget)
	if not widget or not widget.frame then return end
	local f = widget.frame
	AS:StripTextures(f)
	AS:SetTemplate(f)
	-- Lock backdrop color - AtlasLoot resets it on every SetSelected
	hooksecurefunc(f, 'SetBackdropColor', function(self, r, g, b, a)
		local br, bg, bb, ba = unpack(AS.BackdropColor)
		if r ~= br or g ~= bg or b ~= bb then
			self:SetBackdropColor(br, bg, bb, ba)
		end
	end)

	if f.button then
		local btn = f.button
		-- Hide original button state textures directly - SetNormalTexture('') does not
		-- clear textures set via C-code on TBC client
		for _, getter in ipairs({'GetNormalTexture','GetPushedTexture','GetHighlightTexture','GetDisabledTexture'}) do
			local tex = btn[getter] and btn[getter](btn)
			if tex then tex:SetTexture(nil) tex:Hide() end
		end
		for i = 1, btn:GetNumRegions() do
			local r = select(i, btn:GetRegions())
			if r and r.SetTexture then r:SetTexture(nil) r:Hide() end
		end
		-- Draw arrow as texture on main frame so hover logic mirrors Atlas dropdowns
		local arrow = f:CreateTexture(nil, 'OVERLAY')
		arrow:SetTexture([[Interface\AddOns\AddOnSkins\Media\Textures\Arrow]])
		arrow:SetRotation(3.14)
		arrow:SetVertexColor(1, 1, 1)
		arrow:SetPoint('RIGHT', f, 'RIGHT', -4, 0)
		arrow:SetSize(12, 12)
		f._arrow = arrow
		local function onEnter()
			arrow:SetVertexColor(unpack(AS.Color))
			f:SetBackdropBorderColor(unpack(AS.Color))
		end
		local function onLeave()
			arrow:SetVertexColor(1, 1, 1)
			f:SetBackdropBorderColor(unpack(AS.BorderColor))
		end
		f:HookScript('OnEnter', onEnter)
		f:HookScript('OnLeave', onLeave)
		-- btn sits on top of f and blocks its OnEnter - hook btn too
		btn:HookScript('OnEnter', onEnter)
		btn:HookScript('OnLeave', onLeave)
		-- Skin popup on open
		btn:HookScript('OnClick', function()
			C_Timer.After(0, SkinALDropDownPopup)
		end)
	end
end

local function SkinALSelect(widget)
	if not widget or not widget.frame then return end
	AS:StripTextures(widget.frame)
	AS:SetTemplate(widget.frame)
end

local function SkinCheckBoxElvUI(cb)
	if not cb or cb._asSkinned then return end
	cb._asSkinned = true  -- own guard; do NOT set isSkinned here - AS:SkinCheckBox checks it
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

local function SkinCheckButtonsInFrame(parent)
	if not parent then return end
	for _, child in ipairs({parent:GetChildren()}) do
		if child.GetObjectType and child:GetObjectType() == 'CheckButton' then
			-- Reset scale before skinning - AtlasLoot BiS footer uses SetScale(1.5)
			-- which causes the skinned checkbox to overflow the footer bounds
			if child:GetScale() ~= 1 then child:SetScale(1) end
			SkinCheckBoxElvUI(child)
		end
		SkinCheckButtonsInFrame(child)
	end
end

local function SkinFooter()
	if footerSkinned then return end
	local footer = _G['AtlasLoot_BiS_Footer']
	if not footer then return end
	footerSkinned = true
	AS:StripTextures(footer)
	-- No full border on footer - it sits directly under the main frame whose
	-- bottom border already acts as the separator.
	footer:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8X8]],
		tileSize = 8,
		tile = true,
	})
	footer:SetBackdropColor(unpack(AS.BackdropColor))
	SkinCheckButtonsInFrame(footer)

	-- centerGroup is 44px tall designed for scale(1.5) children inside a 24px footer.
	-- After resetting child scale to 1, expand footer and re-center the group.
	footer:SetHeight(52)
	local cg = ({footer:GetChildren()})[1]
	if cg and cg:GetNumPoints() > 0 then
		local _, rel = cg:GetPoint()
		cg:SetHeight(34)
		cg:ClearAllPoints()
		cg:SetPoint('CENTER', rel or footer, 'CENTER', 0, -2)
	end
	-- Move footer 1px below main frame so its top border sits just under the main frame's border.
	local parentFrame = _G['AtlasLoot_GUI-Frame']
	if parentFrame then
		footer:ClearAllPoints()
		footer:SetPoint('TOPLEFT', parentFrame, 'BOTTOMLEFT', 0, -1)
		footer:SetPoint('TOPRIGHT', parentFrame, 'BOTTOMRIGHT', 0, -1)
	end
end

-- Skin the class filter selection popup (created on first right-click)
local function SkinClassFilterPopup(clasFilterButton)
	if not clasFilterButton then return end
	local origOnClick = clasFilterButton:GetScript('OnClick')
	if not origOnClick then return end
	clasFilterButton:HookScript('OnClick', function(self, mouseButton)
		if mouseButton ~= 'RightButton' then return end
		local sf = self.selectionFrame
		if not sf or sf._asSkinned then return end
		sf._asSkinned = true
		AS:StripTextures(sf)
		AS:SetTemplate(sf)
		if sf.buttons then
			for _, btn in ipairs(sf.buttons) do
				AS:StripTextures(btn)
				AS:SetTemplate(btn)
				if btn.icon then AS:SkinTexture(btn.icon) end
				btn:SetHighlightTexture(AS.NormTex or [[Interface\Buttons\UI-Listbox-Highlight]])
				local hl = btn:GetHighlightTexture()
				if hl then
					hl:SetVertexColor(unpack(AS.Color))
					hl:SetAlpha(0.35)
				end
			end
		end
	end)
end

-- Skin the game version selection popup (created on first click)
local function SkinGameVersionPopup(gvButton)
	if not gvButton then return end
	gvButton:HookScript('OnClick', function(self)
		local sf = self.selectionFrame
		if not sf or sf._asSkinned then return end
		sf._asSkinned = true
		AS:StripTextures(sf)
		AS:SetTemplate(sf)
	end)
end

local function SkinAtlasLoot()
	if skinned then return end
	local ALFrame = _G['AtlasLoot_GUI-Frame']
	if not ALFrame then return end
	skinned = true

	local AL = AtlasLoot
	local GUI = AL and AL.GUI

	AS:SkinFrame(ALFrame)
	if ALFrame.titleFrame then AS:StripTextures(ALFrame.titleFrame) end
	local closeBtn = _G['AtlasLoot_GUI-Frame-CloseButton']
	if closeBtn then AS:SkinCloseButton(closeBtn) end

	-- Info button
	if ALFrame.titleFrame and ALFrame.titleFrame.infoButton then
		AS:SkinButton(ALFrame.titleFrame.infoButton)
	end

	if GUI and GUI.frame then
		SkinALDropDown(GUI.frame.moduleSelect)
		SkinALDropDown(GUI.frame.subCatSelect)
		SkinALSelect(GUI.frame.difficulty)
		SkinALSelect(GUI.frame.boss)
		SkinALSelect(GUI.frame.extra)

		-- Game version button
		local gvBtn = GUI.frame.gameVersionButton
		if gvBtn then
			-- Hide the box lines, apply a proper template
			if gvBtn.Box then
				for _, line in ipairs(gvBtn.Box) do
					line:Hide()
				end
			end
			AS:CreateBackdrop(gvBtn)
			if gvBtn.texture or GUI.frame.gameVersionLogo then
				local tex = gvBtn.texture or GUI.frame.gameVersionLogo
				AS:SetInside(tex, gvBtn.Backdrop or gvBtn)
			end
			SkinGameVersionPopup(gvBtn)
		end
	end

	local contentFrame = _G['AtlasLoot_GUI-ItemFrame']
	if contentFrame then
		AS:CreateBackdrop(contentFrame)

		-- Hide the AtlasLoot background textures; the backdrop replaces them.
		-- Also hook SetAlpha/SetColorTexture to prevent RefreshContentBackGround from restoring them.
		for _, key in ipairs({'topBG', 'downBG', 'itemBG'}) do
			local tex = contentFrame[key]
			if tex then
				tex:SetAlpha(0)
				tex:Hide()
				hooksecurefunc(tex, 'SetAlpha', function(self) if self:GetAlpha() > 0 then self:Hide() end end)
				hooksecurefunc(tex, 'SetColorTexture', function(self) self:Hide() end)
			end
		end

		if contentFrame.nextPageButton   then AS:SkinArrowButton(contentFrame.nextPageButton) end
		if contentFrame.prevPageButton   then AS:SkinArrowButton(contentFrame.prevPageButton) end
		if contentFrame.modelButton      then AS:SkinButton(contentFrame.modelButton) end
		if contentFrame.soundsButton     then AS:SkinButton(contentFrame.soundsButton) end
		if contentFrame.itemsButton      then AS:SkinButton(contentFrame.itemsButton) end

		-- Class filter button (icon button)
		if contentFrame.clasFilterButton then
			AS:CreateBackdrop(contentFrame.clasFilterButton)
			if contentFrame.clasFilterButton.texture then
				AS:SkinTexture(contentFrame.clasFilterButton.texture)
				AS:SetInside(contentFrame.clasFilterButton.texture, contentFrame.clasFilterButton.Backdrop or contentFrame.clasFilterButton)
			end
			SkinClassFilterPopup(contentFrame.clasFilterButton)
		end

		-- Content phase button (icon button)
		if contentFrame.contentPhaseButton then
			AS:CreateBackdrop(contentFrame.contentPhaseButton)
			if contentFrame.contentPhaseButton.texture then
				AS:SkinTexture(contentFrame.contentPhaseButton.texture)
				AS:SetInside(contentFrame.contentPhaseButton.texture, contentFrame.contentPhaseButton.Backdrop or contentFrame.contentPhaseButton)
			end
		end

		-- Map button
		if contentFrame.mapButton then
			AS:SkinButton(contentFrame.mapButton)
			if contentFrame.mapButton.texture then
				AS:SetInside(contentFrame.mapButton.texture, contentFrame.mapButton.Backdrop or contentFrame.mapButton)
			end
		end

		if contentFrame.searchBox then
			AS:SkinEditBox(contentFrame.searchBox)
			contentFrame.searchBox:SetHeight(20)
			contentFrame.searchBox:SetWidth(160)
		end
	end

	if GUI and GUI.Create then
		hooksecurefunc(GUI, 'Create', function()
			C_Timer.After(0, SkinFooter)
		end)
	end

	SkinFooter()
end

function AS:AtlasLoot(event, addon)
	local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('AtlasLootClassic'))
		or (_G.IsAddOnLoaded and _G.IsAddOnLoaded('AtlasLootClassic'))
	if not loaded then return end

	C_Timer.After(0, function()
		SkinAtlasLoot()

		if not skinned and AtlasLoot and AtlasLoot.GUI and AtlasLoot.GUI.Toggle then
			local orig = AtlasLoot.GUI.Toggle
			AtlasLoot.GUI.Toggle = function(...)
				orig(...)
				SkinAtlasLoot()
				C_Timer.After(0, SkinFooter)
			end
		end
	end)
end

AS:RegisterSkin('AtlasLootClassic', AS.AtlasLoot)