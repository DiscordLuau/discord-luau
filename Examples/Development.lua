local DotEnv = require("../.env")
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new(DotEnv.DISCORD_BOT_TOKEN)

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

DiscordClient:SetVerboseLogging(true)

local function uiNameSelectionRow()
	return DiscordLuaU.UI.ActionRowComponent.new()
		:AddComponent(
			DiscordLuaU.UI.TextInputComponent.new(`selection-test-0`)
				:SetStyle(DiscordLuaU.UI.TextInputComponent.Style.Short)
				:SetLabel("NAME")
				:SetPlaceholder("discord-user#0000")
				:SetMinLength(1)
				:SetRequired(true)
			)
end

local function uiContentSelectionRow()
	return DiscordLuaU.UI.ActionRowComponent.new()
		:AddComponent(
			DiscordLuaU.UI.TextInputComponent.new(`selection-test-1`)
				:SetStyle(DiscordLuaU.UI.TextInputComponent.Style.Paragraph)
				:SetLabel("MESSAGE")
				:SetPlaceholder("This won't actually send a message, just testing modal functioinality! :D")
				:SetMinLength(20)
				:SetRequired(true)
			)
end

DiscordClient:Subscribe("OnInteraction", function(interactionObject)
	local modalObject = DiscordLuaU.DiscordModal.new(`modal-test-0`)
		:SetTitle("This is a modal test!")
		:AddComponent(uiNameSelectionRow())
		:AddComponent(uiContentSelectionRow())

	interactionObject:SendModalAsync(modalObject)
end)

DiscordClient:Subscribe("OnReady", function()
	local applicationCommand = DiscordLuaU.ApplicationCommand.new()
		:SetType(DiscordLuaU.ApplicationCommand.Type.UserInput)
		:SetName("popup-demo-modal")

	DiscordClient.Application:CreateGlobalCommandAsync(applicationCommand):andThen(function()
		print("Discord Command Added!")
	end)
end)

DiscordClient:ConnectAsync():catch(print)
