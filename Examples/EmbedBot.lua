local DotEnv = require("../.env")
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new(DotEnv.DISCORD_BOT_TOKEN)

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

DiscordClient:SetVerboseLogging(true)

local function fetchRandomImage()
	local request = Net.request({
		url = "https://dog.ceo/api/breeds/image/random",
		method = "GET"
	})

	if request.statusCode ~= 200 then
		return ""
	end

	local dogImageJSON = Serde.decode("json", request.body)

	if not dogImageJSON.status then
		return ""
	end

	return dogImageJSON.message
end


DiscordClient:Subscribe("OnReady", function()
	local discordEmbed = DiscordLuaU.DiscordEmbed.new()
		:SetTitle("Dog Image Generator")
		:SetColor(0xFF0000)
		-- :SetDescription("Check-out this awesome dog photo we found!")
		:SetImage(fetchRandomImage())
		:SetAuthorName("Powered By dog.ceo!")
		:SetAuthorImage("https://rapidapi.com/cdn/images?url=https://rapidapi-prod-apis.s3.amazonaws.com/1d8ca71c-9ce3-498a-9955-71ad69baa268.png")
		:SetProvider("dog.ceo", "https://dog.ceo/dog-api/")

	DiscordClient:GetChannelAsync("1048686561685946489"):andThen(function(discordChannel)
		local discordMessage = DiscordLuaU.DiscordMessage.new()

		discordMessage:AddEmbed(discordEmbed)
		discordChannel:SendMessageAsync(discordMessage):andThen(function()
			print(`Sent message!`)
		end):catch(function(exception)
			print(`Failed to send message: {exception}`)
		end)
	end)
end)

DiscordClient:ConnectAsync():catch(print)
