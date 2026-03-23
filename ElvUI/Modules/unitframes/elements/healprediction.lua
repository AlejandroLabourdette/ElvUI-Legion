local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');

--Cache global variables
--WoW API / Variables
local CreateFrame = CreateFrame

function UF:Construct_HealComm(frame)
	local mhpb = CreateFrame('StatusBar', nil, frame.Health)
	mhpb:SetStatusBarTexture(E["media"].blankTex)
	mhpb:Hide()

	local ohpb = CreateFrame('StatusBar', nil, frame.Health)
	ohpb:SetStatusBarTexture(E["media"].blankTex)
	ohpb:Hide()

	local absorbBar = CreateFrame('StatusBar', nil, frame.Health)
	absorbBar:SetStatusBarTexture(E["media"].blankTex)
	absorbBar:Hide()

	local healAbsorbBar = CreateFrame('StatusBar', nil, frame.Health)
	healAbsorbBar:SetStatusBarTexture(E["media"].blankTex)
	healAbsorbBar:SetReverseFill(true)
	healAbsorbBar:Hide()

	local HealthPrediction = {
		myBar = mhpb,
		otherBar = ohpb,
		absorbBar = absorbBar,
		healAbsorbBar = healAbsorbBar,
		maxOverflow = 1,
		PostUpdate = UF.UpdateHealComm
	}
	HealthPrediction.parent = frame

	return HealthPrediction
end

function UF:Configure_HealComm(frame)
	local healPrediction = frame.HealthPrediction
	local c = self.db.colors.healPrediction

	if frame.db.healPrediction then
		if not frame:IsElementEnabled('HealthPrediction') then
			frame:EnableElement('HealthPrediction')
		end

		if not frame.USE_PORTRAIT_OVERLAY then
			healPrediction.myBar:SetParent(frame.Health)
			healPrediction.otherBar:SetParent(frame.Health)
			healPrediction.absorbBar:SetParent(frame.Health)
			healPrediction.healAbsorbBar:SetParent(frame.Health)
		else
			healPrediction.myBar:SetParent(frame.Portrait.overlay)
			healPrediction.otherBar:SetParent(frame.Portrait.overlay)
			healPrediction.absorbBar:SetParent(frame.Portrait.overlay)
			healPrediction.healAbsorbBar:SetParent(frame.Portrait.overlay)
		end

		local orientation = frame.db.health and frame.db.health.orientation
		if orientation then
			healPrediction.myBar:SetOrientation(orientation)
			healPrediction.otherBar:SetOrientation(orientation)
			healPrediction.absorbBar:SetOrientation(orientation)
			healPrediction.healAbsorbBar:SetOrientation(orientation)
		end

		healPrediction.myBar:SetStatusBarColor(c.personal.r, c.personal.g, c.personal.b, c.personal.a)
		healPrediction.otherBar:SetStatusBarColor(c.others.r, c.others.g, c.others.b, c.others.a)
		healPrediction.absorbBar:SetStatusBarColor(c.absorbs.r, c.absorbs.g, c.absorbs.b, c.absorbs.a)
		healPrediction.healAbsorbBar:SetStatusBarColor(c.healAbsorbs.r, c.healAbsorbs.g, c.healAbsorbs.b, c.healAbsorbs.a)

		local hp = self.db.healPrediction
		healPrediction.absorbBar:SetReverseFill(hp and (hp.absorbStyle == 'ABSORBS_FIXED_RIGHT' or hp.absorbOnTop))

		local parent = frame.USE_PORTRAIT_OVERLAY and frame.Portrait.overlay or frame.Health
		if hp and hp.absorbOnTop then
			healPrediction.absorbBar:SetFrameLevel(parent:GetFrameLevel() + 10)
		else
			healPrediction.absorbBar:SetFrameLevel(parent:GetFrameLevel() + 1)
		end

		healPrediction.maxOverflow = (1 + (c.maxOverflow or 0))
	else
		if frame:IsElementEnabled('HealthPrediction') then
			frame:DisableElement('HealthPrediction')
		end
	end
end

function UF:UpdateFillBar(frame, previousTexture, bar, amount, inverted)
	if ( amount == 0 ) then
		bar:Hide();
		return previousTexture;
	end

	local orientation = frame.Health:GetOrientation()
	bar:ClearAllPoints()
	if orientation == 'HORIZONTAL' then
		if (inverted) then
			bar:Point("TOPRIGHT", previousTexture, "TOPRIGHT");
			bar:Point("BOTTOMRIGHT", previousTexture, "BOTTOMRIGHT");
		else
			bar:Point("TOPLEFT", previousTexture, "TOPRIGHT");
			bar:Point("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT");
		end
	else
		if (inverted) then
			bar:Point("TOPRIGHT", previousTexture, "TOPRIGHT");
			bar:Point("TOPLEFT", previousTexture, "TOPLEFT");
		else
			bar:Point("BOTTOMRIGHT", previousTexture, "TOPRIGHT");
			bar:Point("BOTTOMLEFT", previousTexture, "TOPLEFT");
		end
	end

	local totalWidth, totalHeight = frame.Health:GetSize();
	if orientation == 'HORIZONTAL' then
		bar:Width(totalWidth);
	else
		bar:Height(totalHeight);
	end

	return bar:GetStatusBarTexture();
end

function UF:UpdateAbsorbBar(frame, previousTexture, bar, amount)
	if amount == 0 then bar:Hide(); return end

	local db           = UF.db.healPrediction
	local absorbOnTop  = db and db.absorbOnTop
	local absorbFixed  = absorbOnTop or (db and db.absorbStyle == 'ABSORBS_FIXED_RIGHT')
	local customHeight = db and (db.absorbHeight  or 0)
	local position     = db and (db.absorbPosition or 'BOTTOM')
	local yOffset      = db and (db.absorbYOffset  or 0)
	local orientation  = frame.Health:GetOrientation()
	local totalWidth, totalHeight = frame.Health:GetSize()
	if customHeight > 0 then
		customHeight = math.floor(totalHeight * customHeight / 100)
	end

	bar:ClearAllPoints()

	if orientation == 'HORIZONTAL' then
		if customHeight > 0 then
			if absorbFixed then
				local anchor = position == 'TOP' and 'TOPRIGHT' or position == 'CENTER' and 'RIGHT' or 'BOTTOMRIGHT'
				bar:Point(anchor, frame.Health, anchor, 0, yOffset)
			else
				local selfAnchor   = position == 'TOP' and 'TOPLEFT'   or position == 'CENTER' and 'LEFT'  or 'BOTTOMLEFT'
				local parentAnchor = position == 'TOP' and 'TOPRIGHT'  or position == 'CENTER' and 'RIGHT' or 'BOTTOMRIGHT'
				bar:Point(selfAnchor, previousTexture, parentAnchor, 0, yOffset)
			end
			bar:Width(totalWidth)
			bar:Height(customHeight)
		else
			if absorbFixed then
				bar:Point('TOPRIGHT',    frame.Health, 'TOPRIGHT',    0, yOffset)
				bar:Point('BOTTOMRIGHT', frame.Health, 'BOTTOMRIGHT', 0, yOffset)
			else
				bar:Point('TOPLEFT',    previousTexture, 'TOPRIGHT',    0, yOffset)
				bar:Point('BOTTOMLEFT', previousTexture, 'BOTTOMRIGHT', 0, yOffset)
			end
			bar:Width(totalWidth)
		end
	else -- VERTICAL
		if customHeight > 0 then
			if absorbFixed then
				local anchor = position == 'TOP' and 'TOPRIGHT' or position == 'CENTER' and 'RIGHT' or 'BOTTOMRIGHT'
				bar:Point(anchor, frame.Health, anchor, yOffset, 0)
			else
				local selfAnchor   = position == 'TOP' and 'TOPRIGHT'    or position == 'CENTER' and 'RIGHT' or 'BOTTOMRIGHT'
				local parentAnchor = position == 'TOP' and 'TOPLEFT'     or position == 'CENTER' and 'LEFT'  or 'BOTTOMLEFT'
				bar:Point(selfAnchor, previousTexture, parentAnchor, yOffset, 0)
			end
			bar:Height(totalHeight)
			bar:Width(customHeight)
		else
			if absorbFixed then
				bar:Point('TOPRIGHT', frame.Health, 'TOPRIGHT', yOffset, 0)
				bar:Point('TOPLEFT',  frame.Health, 'TOPLEFT',  yOffset, 0)
			else
				bar:Point('TOPRIGHT',    previousTexture, 'TOPLEFT',    yOffset, 0)
				bar:Point('BOTTOMRIGHT', previousTexture, 'BOTTOMLEFT', yOffset, 0)
			end
			bar:Height(totalHeight)
		end
	end

	bar:Show()
end

function UF:UpdateHealComm(_, myIncomingHeal, allIncomingHeal, totalAbsorb, healAbsorb, hasOverAbsorb)
	local frame = self.parent
	local previousTexture = frame.Health:GetStatusBarTexture()

	UF:UpdateFillBar(frame, previousTexture, self.healAbsorbBar, healAbsorb, true)
	previousTexture = UF:UpdateFillBar(frame, previousTexture, self.myBar, myIncomingHeal)
	previousTexture = UF:UpdateFillBar(frame, previousTexture, self.otherBar, allIncomingHeal)

	local db = UF.db.healPrediction
	if db and db.absorbOnTop and hasOverAbsorb then
		local realAbsorb = UnitGetTotalAbsorbs(frame.unit) or 0
		self.absorbBar:SetMinMaxValues(0, UnitHealthMax(frame.unit))
		self.absorbBar:SetValue(realAbsorb)
		UF:UpdateAbsorbBar(frame, previousTexture, self.absorbBar, realAbsorb)
	else
		UF:UpdateAbsorbBar(frame, previousTexture, self.absorbBar, totalAbsorb)
	end
end