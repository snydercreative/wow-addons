FindMyBuddy = LibStub("AceAddon-3.0"):NewAddon("FindMyBuddy", "AceConsole-3.0", "AceEvent-3.0")
AceGUI = LibStub("AceGUI-3.0")


local menuOptions = {
	name = "Find My Buddy",
	handler = FindMyBuddy,
	type = "group",
	args = {
		deactivationDistance = {
			name = "Deactivation Distance",
			desc = "Once you're within this distance from your target, the directional arrow will disappear.",
			type = "range",
			min = 5,
			max = 40,
			step = 1,
			get = "GetDeactivationDistance",
			set = "SetDeactivationDistance",
			width = "double",
			order = 1
		},
		arrowColorPicker = {
			name = "Arrow Color",
			desc = "Pick the color and transparency of the directional arrow.",
			type = "color",
			get = "GetArrowColor",
			set = "SetArrowColor",
			hasAlpha = true,
			width = "double",
			order = 2
		}
	}
}

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

local timer = CreateFrame("Frame")
local addon = CreateFrame("Frame", nil, UIParent)
local arrow = addon:CreateTexture(nil, "BACKGROUND", nil, -8)
local arrowShadow = addon:CreateTexture(nil, "BACKGROUND", nil, -8)

local distanceFrame = CreateFrame("Frame")
distanceFrame:SetPoint("CENTER", 0, -150)
distanceFrame:SetHeight(25)
distanceFrame:SetWidth(225)
distanceFrame:SetFrameStrata("BACKGROUND")
distanceFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, 
	tileSize = 16, 
	edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
distanceFrame:SetBackdropColor(0, 0, 0, 1)
distanceFrame:Hide()

local distanceFontString = distanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
distanceFontString:SetPoint("CENTER")
distanceFontString:Show()

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

function FindMyBuddy:ShowDistanceMessage(distance, target)
	local name, realm = UnitName(target)
	distanceFontString:SetText("Distance to " .. name ..": " .. distance)
	local stringWidth = distanceFontString:GetStringWidth() + 30
	distanceFrame:SetWidth(stringWidth)
	distanceFrame:Show()
end

function FindMyBuddy:SetupDisplay(unitName, target_x, target_y) 
	if not C_Map then
		FindMyBuddy:Print("Error loading the new maps API. Disabling addon. ")
		self.db.profile.isEnabled = false
		distanceFrame:Hide()
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
		distanceFrame:Hide()
		DisplayArrows(false)
	else
		FindMyBuddy:ShowDistanceMessage(distance, unitName)
		arrow:SetRotation(angle)	
		arrowShadow:SetRotation(angle)

		DisplayArrows(true)
	end
end

function FindMyBuddy:DisableAddon() 
	-- FindMyBuddy:Print("Error loading the new maps API. Disabling addon. ")
	-- self.db.profile.isEnabled = false
	timer:Hide()
	distanceFrame:Hide()
	DisplayArrows(false)
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

		local test = C_Map.GetPlayerMapPosition(mapId, unitName)

		local mapInfo = C_Map.GetMapInfo(mapId);

		local playerMapPositionTable = C_Map.GetPlayerMapPosition(mapId, unitName)
		
		if playerMapPositionTable then
			local target_x, target_y = playerMapPositionTable:GetXY()
			FindMyBuddy:SetupDisplay(unitName, target_x, target_y)		
		else 
			FindMyBuddy:DisableAddon() 
		end
	else
		FindMyBuddy:DisableAddon() 
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
	if (not self.db.profile.arrowColor) then
		self.db.profile.arrowColor = cfg.arrowColor
	end

	return unpack(self.db.profile.arrowColor)
end

function FindMyBuddy:SetArrowColor(_, r, g, b, a)
	self.db.profile.arrowColor = {r, g, b, a}
	arrow:SetVertexColor(unpack(self.db.profile.arrowColor))
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
			deactivationDistance = 25,
			arrowColor = {1, 0, 0, .5}
		},
	})

	arrow:SetVertexColor(FindMyBuddy:GetArrowColor())

	icon:Register("Find My Buddy", FindMyBuddyLDB, self.db.profile.minimap)
end

function FindMyBuddy:OnEnable()
	FindMyBuddy:Print("Type /fmb to access settings.")
end

function FindMyBuddy:OnDisable()
end

function FindMyBuddy:PLAYER_TARGET_CHANGED()
	-- if not self.db.profile.isEnabled then
	-- 	return
	-- end

	DisplayArrows(false)

	if UnitInRaid("player") or UnitInParty("player") then
		if UnitExists("target") and not UnitIsUnit("target", "player") then
			timer:Show()
			distanceFrame:Hide()
		else
			timer:Hide()
			distanceFrame:Hide()
		end
	end
end

SLASH_FINDMYBUDDY1 = "/fmb"

SlashCmdList.FINDMYBUDDY = function(input)
	InterfaceOptionsFrame_OpenToCategory("FindMyBuddy")
	InterfaceOptionsFrame_OpenToCategory("FindMyBuddy")
	InterfaceOptionsFrame_OpenToCategory("FindMyBuddy")
end