local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local Construct = require("../../Utils/Construct")

local ModalBuilder = require("../Builders/ModalBuilder")
local PermissionsBuilder = require("../Builders/PermissionsBuilder")
local MessageBuilder = require("../Builders/MessageBuilder")

local DiscordGuildMember = require("DiscordGuildMember")

local DiscordTextChannel = require("DiscordTextChannel")
local DiscordUser = require("DiscordUser")
local DiscordGuild = require("DiscordGuild")

local DiscordMessage = require("DiscordMessage")

--[=[
	@class Objects.DiscordInteraction

	The `DiscordInteraction` class represents an interaction with the Discord API, such as a message interaction, a command, or a modal submission.
]=]
local DiscordInteraction = {}

DiscordInteraction.Interface = {}
DiscordInteraction.Prototype = {}

--[=[
	@prop type string
	@within Objects.DiscordInteraction
	@readonly

	The type of the DiscordInteraction. Default is "DiscordInteraction".
]=]
DiscordInteraction.Prototype.type = "DiscordInteraction"

--[=[
	Edits the original interaction response message asynchronously.

	@method editMessageAsync
	@param messageBuilder MessageBuilder -- The message builder object.
	@return Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.editMessageAsync(self: DiscordInteraction, messageBuilder: MessageBuilder.MessageBuilder)
	return Future.new(function()
		return self.discordClient.discordGateway:patchAsync(string.format(
			DiscordEndpoints.EditOriginalInteractionResponse,
			self.discordClient.discordApplication.id,
			self.token
		), messageBuilder:toJSONObject()):await()
	end)
end

--[=[
	Sends a modal in response to the interaction asynchronously.

	@method sendModalAsync
	@param modalObject ModalBuilder -- The modal builder object.
	@return Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.sendModalAsync(self: DiscordInteraction, modalObject: ModalBuilder.ModalBuilder)
	return Future.new(function()
		return self.discordClient.discordGateway:postAsync(string.format(
			DiscordEndpoints.CreateInteractionResponse,
			self.id,
			self.token
		), {
			type = 9,
			data = modalObject:toJSONObject()
		}):await()
	end)
end

--[=[
	Sends a message in response to the interaction asynchronously.

	@method sendMessageAsync
	@param messageBuilder MessageBuilder -- The message builder object.
	@return Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.sendMessageAsync(self: DiscordInteraction, messageBuilder: MessageBuilder.MessageBuilder)
	if self.defered then
		return self:editMessageAsync(messageBuilder)
	else
		return Future.new(function()
			return self.discordClient.discordGateway:postAsync(string.format(
				DiscordEndpoints.CreateInteractionResponse,
				self.id,
				self.token
			), {
				type = 4,
				data = messageBuilder:toJSONObject()
			}):await()
		end)
	end
end

--[=[
	Defers the interaction response asynchronously.

	@method deferAsync
	@return Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.deferAsync(self: DiscordInteraction)
	return Future.try(function()
		self.defered = true

		self.discordClient.discordGateway:postAsync(string.format(
			DiscordEndpoints.CreateInteractionResponse,
			self.id,
			self.token
		), {
			type = 5,
			data = { }
		}):await()
	end)
end

--[=[
	Creates a new DiscordInteraction instance.

	@function new
	@param discordClient any -- The Discord client instance.
	@param jsonData table -- The raw data for the interaction.
	@return DiscordInteraction -- The newly created DiscordInteraction instance.
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Interface.new(discordClient: any, jsonData: { [any]: any })
	local interactionStruct = {
		discordClient = discordClient,

		defered = false
	}

	jsonData.channel = DiscordTextChannel.new(discordClient, jsonData.channel)
	jsonData.guild = DiscordGuild.new(discordClient, jsonData.guild)
	jsonData.user = DiscordUser.new(discordClient, jsonData.member.user)
	jsonData.member = DiscordGuildMember.new(discordClient, jsonData.member.user.id, jsonData.guild.id, jsonData.member)
	jsonData.appPermissions = PermissionsBuilder.from(jsonData.appPermissions)

	jsonData.member.user = nil

	for index, value in jsonData do
		interactionStruct[index] = value
	end

	return Construct(interactionStruct, DiscordInteraction.Prototype)
end

export type DiscordInteraction = typeof(DiscordInteraction.Prototype) & {
	discordClient: any,

	channel: DiscordTextChannel.DiscordTextChannel,
	guild: DiscordGuild.DiscordGuild,
	user: DiscordUser.DiscordUser,

	token: string,
	applicationId: string,
	id: string,
	data: {
		name: string,
		types: number,
		id: string,
	},
	channelId: string,
	guilldId: string,
	version: number,
	appPermissions: PermissionsBuilder.PermissionsBuilder,
	guildLocale: string,
	locale: string,
	entitlements: { unknown },
	entitlementSkuIds: { unknown },

	defered: boolean,
}

return DiscordInteraction.Interface
