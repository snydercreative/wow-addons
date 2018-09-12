HeyWowGreat = LibStub("AceAddon-3.0"):NewAddon("HeyWowGreat", "AceConsole-3.0", "AceEvent-3.0")
AceGUI = LibStub("AceGUI-3.0")

insultArray = {
	"Hey, |name|, that's super. You're sooo great.",
	"Look everyone, |name| thinks they're special.",
	"*sigh* Yeah, |name|, we get it. Enough already.",
	"|name|'s mother was a hamster, and their father smells of elderberries.",
	"OK, |name|, remember the movie Die Hard? You'd be the hostage that got shot.",
	"Just /gquit already, |name|. We've had enough of your shenanigans.",
	"|name| thinks they're too cool for school."
}

function GetRandomInsult(guildMemberName) 
	local insult = insultArray[math.random(#insultArray)]

	return string.gsub(insult, "|name|", guildMemberName)
end

function HeyWowGreat:OnEnable()
	--HeyWowGreat:Print("Type /hwg to access settings.")
	channelId, name = GetChannelName("Guild");
end

function HeyWowGreat:OnDisable()
end

function HeyWowGreat:OnInitialize()
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")

	self.db = LibStub("AceDB-3.0"):New("HeyWowGreatDB", {
		profile = {
			minimap = {
				hide = false,
			},
			isEnabled = true,
		},
	})

	HeyWowGreat:Print(1)
end

function HeyWowGreat:CHAT_MSG_GUILD_ACHIEVEMENT(eventName, achievementMessage, _, _, _, guildMemberName)
	local insult = GetRandomInsult(guildMemberName)

	SendChatMessage(insult .. " Oh yeah, grats too. [HeyWowGreat v0.1]", "GUILD", nil, channelId);
end

SLASH_HeyWowGreat1 = "/hwg"

SlashCmdList.HeyWowGreat = function(input)
	local insult = GetRandomInsult(input)
	SendChatMessage(insult, "GUILD", nil, channelId);

	--InterfaceOptionsFrame_OpenToCategory("HeyWowGreat")
	--InterfaceOptionsFrame_OpenToCategory("HeyWowGreat")
	--InterfaceOptionsFrame_OpenToCategory("HeyWowGreat")
end