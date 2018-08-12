local atonementTargets = {}
local atonementBuffs = {}
--local icon = LibStub("LibDBIcon-1.0")

local spellTimer = CreateFrame("Frame")
local buffTimer = CreateFrame("Frame")
local updateInterval = 0.1

local buffListFrame = CreateFrame("Frame", nil, UIParent)
buffListFrame:SetPoint("CENTER")
buffListFrame:SetHeight(225)
buffListFrame:SetWidth(225)
buffListFrame:SetFrameStrata("BACKGROUND")
buffListFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, 
	tileSize = 16, 
	edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
buffListFrame:SetBackdropColor(0, 0, 0, 1)
buffListFrame:Show()

function SpellTimerUpdateHandler(self, elapsed)
	if UnitCanAssist("player", "target") then
		for i = 1, 40 do
			local name, _, _, _, duration, expiration, unitCaster = UnitBuff("target", i)

			if (name == nil) then 
				return 
			end

			if (unitCaster == "player" and name == "Atonement") then
				table.insert(atonementTargets, { 
					targetName = UnitName("target"), 
					duration = duration, 
					expiration = expiration, 
					duration = duration 
				})
				buffTimer:Show()
				spellTimer:Hide()
				return
			end
		end
	else
		spellTimer:Hide()
	end
end

function BuffTimerUpdateHandler(self, elapsed)
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate or 0
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 	

	if (self.TimeSinceLastUpdate > updateInterval) then
		local atonementTargetsLength = table.getn(atonementTargets)

		if (not atonementTargetsLength) then
			buffTimer:Hide()
			return 
		end
	
		for i = 1, atonementTargetsLength do
			if (atonementTargets[i]) then
				local remaining = math.floor((atonementTargets[i].expiration - GetTime()) * 10) / 10

				UpdateButton(i, atonementTargets[i].targetName, remaining, atonementTargets[i].duration)						
			end
		end

		self.TimeSinceLastUpdate = 0;
	end
end

function ButtonClicked(self, button)
	local spaceLocation = string.find(self:GetText(), "%s")
	local targetName = string.sub(self:GetText(), 1, spaceLocation - 1)

	self:SetAttribute("macrotext", "/targetexact " .. targetName)
end

function AddBuffedPlayer(name, remaining)
	local frameParent = buffListFrame

	if (buffListFrame:GetNumChildren() > 0) then
		local kids = { buffListFrame:GetChildren() };

		for _, child in ipairs(kids) do
			frameParent = child
		end
	end

	local button = CreateFrame("Button", name, buffListFrame, "ButtonTrackerSecureActionButtonTemplate");
	button:SetPoint("TOP", frameParent, "TOP", 0, -25)
	button:SetWidth(200)
	button:SetHeight(20)
	button:SetFrameStrata("HIGH")

	local texture = button:CreateTexture(nil, "BACKGROUND")
	texture:SetAllPoints()
	texture:SetColorTexture(0, 0, 0, 0)

	local backgroundFrame = CreateFrame("Frame", nil, button)
	backgroundFrame:SetPoint("LEFT")
	backgroundFrame:SetHeight(20)
	backgroundFrame:SetWidth(200)
	backgroundFrame:SetFrameStrata("BACKGROUND")
	backgroundFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
	backgroundFrame:SetBackdropColor(0, .5, 1, 1)
	backgroundFrame:Show()

	button:Show()

	atonementBuffs[name] = {
		button = button,
		backgroundFrame = backgroundFrame
	}

end

function UpdateButton(index, name, expiration, duration) 	
	if (atonementBuffs[name]) then
		if (expiration < 0) then
			table.remove(atonementBuffs, index)
			table.remove(atonementTargets, index)
		else
			atonementBuffs[name].button:SetNormalFontObject("GameFontNormal")
			local font = atonementBuffs[name].button:GetNormalFontObject();
			atonementBuffs[name].button:SetText(name .. " " .. expiration)
			atonementBuffs[name].button:SetNormalFontObject(font);

			local remainingPercent = expiration/duration
			local newWidth = 200 * remainingPercent
			atonementBuffs[name].backgroundFrame:SetWidth(newWidth)
		end 
	else
		AddBuffedPlayer(name, expiration)
	end
end

local function eventHandler(self, event, ...)
	if (event == "UNIT_SPELLCAST_SUCCEEDED") then
		spellTimer:Show()
	end
end

buffListFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
buffListFrame:SetScript("OnEvent", eventHandler);

spellTimer:SetScript("OnUpdate", SpellTimerUpdateHandler)
spellTimer:Hide()

buffTimer:SetScript("OnUpdate", BuffTimerUpdateHandler)
buffTimer:Hide()