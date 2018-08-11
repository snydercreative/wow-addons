FindMyBuddy = LibStub("AceAddon-3.0"):NewAddon("FindMyBuddy", "AceConsole-3.0", "AceEvent-3.0")
AceGUI = LibStub("AceGUI-3.0")

FindMyBuddyLDB = LibStub("LibDataBroker-1.1"):NewDataObject("FindMyBuddyLDB", {
	type = "data source",
	text = "Find My Buddy",
	icon = "Interface\\Icons\\ability_marksmanship",
	label = "asd",
	OnClick = function()
		FindMyBuddy:MinimapButtonClicked()
	end,
	OnTooltipShow = function(tooltip)
		FindMyBuddy:MinimapIconTooltip(tooltip)
	end
})

local icon = LibStub("LibDBIcon-1.0")

local cfg = {
	arrowSize = 256,
	arrowTexture = "pointer",
	arrowColor = {1, 0, 0, .5},
	arrowBlendMode = "ADD"
}

local menuOptions = {
	name = "Find My Buddy",
	handler = FindMyBuddy,
	type = "group",
	args = {
		 deactivationDistance = {
			name = "Deactivation Distance",
			desc = "Once you're within this distance from your target, the directional arrow will disappear.",
			descStyle = "inline",
			type = "range",
			min = 5,
			max = 40,
			step = 1,
			get = "GetDeactivationDistance",
			set = "SetDeactivationDistance"
		},
		arrowColorPicker = {
			name = "Arrow Color",
			desc = "Pick the color and transparency of the directional arrow.",
			descStyle = "inline",
			type = "color",
			get = "GetArrowColor",
			set = "SetArrowColor",
			hasAlpha = true
		}
	}
}

local timer = CreateFrame("Frame")
local addon = CreateFrame("Frame", nil, UIParent)
local arrow = addon:CreateTexture(nil, "BACKGROUND", nil, -8)
local arrowShadow = addon:CreateTexture(nil, "BACKGROUND", nil, -8)
local distanceFontString = addon:CreateFontString(nil, "OVERLAY", "GameFontNormal")

addon:SetSize(32,32)
addon:SetPoint("CENTER")

arrow:SetSize(sqrt(2)*cfg.arrowSize,sqrt(2)*cfg.arrowSize)
arrow:SetPoint("CENTER")
arrow:SetVertexColor(unpack(cfg.arrowColor))
arrow:SetBlendMode(cfg.arrowBlendMode) --"ADD" or "BLEND"
arrow:SetRotation(math.rad(0))
arrow:SetTexture("Interface\\AddOns\\FindMyBuddy\\media\\"..cfg.arrowTexture)
arrow:Hide()

arrowShadow:SetSize(sqrt(2)*cfg.arrowSize,sqrt(2)*cfg.arrowSize)
arrowShadow:SetPoint("CENTER", 2, -2)
arrowShadow:SetVertexColor(unpack({0, 0, 0, .5}))
arrowShadow:SetBlendMode("BLEND") --"ADD" or "BLEND"
arrowShadow:SetRotation(math.rad(0))
arrowShadow:SetTexture("Interface\\AddOns\\FindMyBuddy\\media\\"..cfg.arrowTexture)
arrowShadow:Hide()

distanceFontString:SetPoint("CENTER", 0, -200)

function DisplayArrows(shouldShow) 
	if shouldShow == true then
		arrow:Show()
		arrowShadow:Show()
		return
	end
	
	arrow:Hide()
	arrowShadow:Hide()
end

function GetAngle(dx, dy)
	local degrees = math.deg(math.atan(dx / dy))

    if dx >= 0 and dy >= 0 then
      degrees = degrees * (-1)
    elseif dx >= 0 and dy <= 0 then
      degrees = (-180 - degrees)
    elseif dx <= 0 and dy >= 0 then
      degrees = degrees * (-1)
    elseif dx <= 0 and dy <= 0 then
      degrees = (180 - degrees)
    end

	local playerFacing = GetPlayerFacing()
	local targetRadians = math.rad(0-degrees)
	local rotation = targetRadians - playerFacing

	return rotation
end

function FindMyBuddy:MinimapIconTooltip(tooltip)
	tooltip:AddLine("Find My Buddy");
	
	if self.db.profile.isEnabled then
		tooltip:AddLine("Select a party or raid member to track their location.")
	else
		tooltip:AddLine("Currently disabled. Click the mini-map icon to re-enable.")
	end
end

function FindMyBuddy:MinimapButtonClicked() 
	self.db.profile.isEnabled = not self.db.profile.isEnabled

	if self.db.profile.isEnabled then
		FindMyBuddy:Print("FindMyBuddy enabled! Select a party or raid member to track their location.")
	else
		FindMyBuddy:Print("FindMyBuddy disabled. Click the mini-map icon to re-enable.")
	end
end

function FindMyBuddy:ShowDistanceMessage(distance)
	distanceFontString:Show()
	distanceFontString:SetText("Distance to target: " .. distance)
end

function FindMyBuddy:SetupDisplay(unitName, target_x, target_y) 
	if not C_Map then
		FindMyBuddy:Print("Error loading the new maps API. Disabling addon. ")
		self.db.profile.isEnabled = false
		distanceFontString:Hide()
		DisplayArrows(false)
		timer:Hide()		
		return
	end

	local mapId = C_Map.GetBestMapForUnit("player")
	local player_x, player_y = C_Map.GetPlayerMapPosition(mapId, "player"):GetXY();

	local dx = player_x - target_x
	local dy = player_y - target_y

	local distance, checkedDistance = math.floor(UnitDistanceSquared(unitName)^0.5)
	local angle = GetAngle(dx, dy)
	
	if distance < FindMyBuddy:GetDeactivationDistance() then
		timer:Hide()
		distanceFontString:Hide()
		DisplayArrows(false)
	else
		FindMyBuddy:ShowDistanceMessage(distance)
		arrow:SetRotation(angle)	
		arrowShadow:SetRotation(angle)

		DisplayArrows(true)
	end
end

function FindMyBuddy:FindTarget() 
	local raidUnitIndex = UnitInRaid("target")
	local partyUnitIndex = UnitInParty("target")
	local unitName = ""

	if raidUnitIndex then
	 	unitName = "raid" .. raidUnitIndex
	elseif partyUnitIndex then
		unitName = "target"
	else
		return
	end

	if C_Map then
		local mapId = C_Map.GetBestMapForUnit(unitName)
		local target_x, target_y = C_Map.GetPlayerMapPosition(mapId, unitName):GetXY()

		FindMyBuddy:SetupDisplay(unitName, target_x, target_y)		
	else
		FindMyBuddy:Print("Error loading the new maps API. Disabling addon. ")
		self.db.profile.isEnabled = false
		timer:Hide()
		distanceFontString:Hide()
		DisplayArrows(false)
	end
end

function TimerUpdateHandler(self, elapsed)
	FindMyBuddy:FindTarget() 
end

timer:SetScript("OnUpdate", TimerUpdateHandler)
timer:Hide()

-- Event Handlers

function FindMyBuddy:GetDeactivationDistance(info) 
	if (not self.deactivationDistance) then
		self.deactivationDistance = self.db.profile.deactivationDistance
	end

	return self.deactivationDistance
end

function FindMyBuddy:SetDeactivationDistance(info, newValue)
	self.db.profile.deactivationDistance = newValue
	self.deactivationDistance = newValue
end

function FindMyBuddy:GetArrowColor()
	if (not self.arrowColor) then
		self.arrowColor = cfg.arrowColor
	end

	return unpack(self.arrowColor)
end

function FindMyBuddy:SetArrowColor(r, g, b, a)
	self.arrowColor = {r, g, b, a}
	arrow:SetVertexColor(unpack(self.arrowColor))
end

function FindMyBuddy:OnInitialize()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")

    LibStub("AceConfig-3.0"):RegisterOptionsTable("FindMyBuddy", menuOptions)

	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FindMyBuddy", "FindMyBuddy")

	self.db = LibStub("AceDB-3.0"):New("FindMyBuddyDB", {
		profile = {
			minimap = {
				hide = false,
			},
			isEnabled = true,
			deactivationDistance = 25
		},
	})

	arrow:SetVertexColor(unpack(FindMyBuddy:GetArrowColor()))

	icon:Register("Find My Buddy", FindMyBuddyLDB, self.db.profile.minimap)
end

function FindMyBuddy:OnEnable()
end

function FindMyBuddy:OnDisable()
end

function FindMyBuddy:PLAYER_TARGET_CHANGED()
	if not self.db.profile.isEnabled then
		return
	end

	DisplayArrows(false)

	if UnitInRaid("player") or UnitInParty("player") then
		if UnitExists("target") and not UnitIsUnit("target", "player") then
			timer:Show()
			distanceFontString:Hide()
		else
			timer:Hide()
			distanceFontString:Hide()
		end
	end
end