local Task = require("@lune/task")
local Serde = require("@lune/serde")

local DotEnv = require("../.env")
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new(DotEnv.DISCORD_BOT_TOKEN)

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

DiscordClient:SetVerboseLogging(true)

local function uiButtonRow()
	return DiscordLuaU.UI.ActionRowComponent.new()
		:AddComponent(
			DiscordLuaU.UI.ButtonComponent.new(`btn-test-0`)
				:SetStyle(DiscordLuaU.UI.ButtonComponent.Style.Blurple)
				:SetLabel(`Button One!`)
			)
		:AddComponent(
			DiscordLuaU.UI.ButtonComponent.new(`btn-test-1`)
				:SetStyle(DiscordLuaU.UI.ButtonComponent.Style.Green)
				:SetLabel(`Button Two!`)
			)
		:AddComponent(
			DiscordLuaU.UI.ButtonComponent.new(`btn-test-2`)
				:SetStyle(DiscordLuaU.UI.ButtonComponent.Style.Grey)
				:SetLabel(`Button Three!`)
			)
		:AddComponent(
			DiscordLuaU.UI.ButtonComponent.new(`btn-test-3`)
				:SetStyle(DiscordLuaU.UI.ButtonComponent.Style.Red)
				:SetLabel(`Button Four!`)
			)
		:AddComponent(
			DiscordLuaU.UI.ButtonComponent.new(`btn-test-4`)
				:SetStyle(DiscordLuaU.UI.ButtonComponent.Style.Link)
				:SetLabel(`Button Five!`)
				:SetLinkUrl("https://discord.com/users/685566749516628033")
			)
end

local function uiSelectionRow()
	return DiscordLuaU.UI.ActionRowComponent.new()
		:AddComponent(
			DiscordLuaU.UI.SelectionComponent.new(`selection-test-0`)
				:SetType(DiscordLuaU.UI.SelectionComponent.Type.ChannelSelection)
				:SetChannelTypes(
					DiscordLuaU.UI.SelectionComponent.ChannelType.GuildText
				)
				:SetMinValues(1)
			)
end

DiscordClient:Subscribe("OnMessage", function(discordMessage)
	local returnDiscordMessage = DiscordLuaU.DiscordMessage.new()

	if discordMessage.Author.Bot then
		return
	end

	returnDiscordMessage:AddEmbed(DiscordLuaU.DiscordEmbed.new()
		:SetTitle("Cool Components Embed!")
		:SetColor(0xFF0000)
		:SetDescription("Check-out this awesome embed with some cool discord components!"))

	returnDiscordMessage:AddComponent(uiButtonRow())
	returnDiscordMessage:AddComponent(uiSelectionRow())

	discordMessage:ReplyAsync(returnDiscordMessage)
end)

DiscordClient:Subscribe("OnReady", function()
	
end)

DiscordClient:ConnectAsync():catch(print)
