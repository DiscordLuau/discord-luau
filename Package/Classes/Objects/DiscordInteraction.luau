local DiscordEndpoints = require("@Data/DiscordEndpoints")

local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local ModalBuilder = require("@Builders/ModalBuilder")
local PermissionsBuilder = require("@Builders/PermissionsBuilder")
local MessageBuilder = require("@Builders/MessageBuilder")

local DiscordGuildMember = require("@Objects/DiscordGuildMember")

local DiscordChannel = require("@Objects/DiscordChannel")
local DiscordUser = require("@Objects/DiscordUser")
local DiscordGuild = require("@Objects/DiscordGuild")

local Resolvable = require("@Network/Resolvable")
local ResolvableType = require("@Enums/ResolvableType")

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
	@return Vendor.Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.editMessageAsync(
	self: DiscordInteraction,
	messageBuilder: MessageBuilder.MessageBuilder
)
	return Future.new(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(
					DiscordEndpoints.EditOriginalInteractionResponse,
					self.discordClient.discordApplication.id,
					self.token
				),
				messageBuilder:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Sends a modal in response to the interaction asynchronously.

	@method sendModalAsync
	@param modalObject ModalBuilder -- The modal builder object.
	@return Vendor.Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.sendModalAsync(self: DiscordInteraction, modalObject: ModalBuilder.ModalBuilder)
	return Future.new(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.CreateInteractionResponse, self.id, self.token),
				Resolvable.new(ResolvableType.JSON, {
					type = 9,
					data = modalObject:toPayloadObject():resolve(),
				})
			)
			:await()
	end)
end

--[=[
	Sends a message in response to the interaction asynchronously.

	:::caution
	MessageBuilder cannot support Attachments UNLESS deffered, so if you're wanting to send attachments, please call `deferAsync` first!
	:::

	@method sendMessageAsync
	@param messageBuilder MessageBuilder -- The message builder object.
	@return Vendor.Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.sendMessageAsync(
	self: DiscordInteraction,
	messageBuilder: MessageBuilder.MessageBuilder
)
	if self.defered then
		return self:editMessageAsync(messageBuilder)
	else
		return Future.new(function()
			local payloadObject = messageBuilder:toPayloadObject()

			return self.discordClient.discordGateway
				:postAsync(
					string.format(DiscordEndpoints.CreateInteractionResponse, self.id, self.token),
					payloadObject:update(function(data)
						return {
							type = 4,
							data = data,
						}
					end)
				)
				:await()
		end)
	end
end

--[=[
	Defers the interaction response asynchronously.

	@method deferAsync
	@return Vendor.Future
	@within Objects.DiscordInteraction
]=]
function DiscordInteraction.Prototype.deferAsync(self: DiscordInteraction)
	return Future.try(function()
		self.defered = true

		self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.CreateInteractionResponse, self.id, self.token),
				Resolvable.new(ResolvableType.JSON, {
					type = 5,
					data = {},
				})
			)
			:await()
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
	--[=[
		@prop channel Objects.DiscordChannel
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop guild objects.DiscordGuild
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop user objects.DiscordUser
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop token string
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop applicationId string
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop id string
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop data { [any]: any }
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop channelId string
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop guilldId string
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop version number
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop appPermissions Builders.PermissionsBuilder
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop guildLocale string
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop locale string
		@within Objects.DiscordInteraction
	]=]

	--[=[
		@prop defered boolean
		@within Objects.DiscordInteraction
	]=]

	local interactionStruct = {
		discordClient = discordClient,

		defered = false,
	}

	if jsonData.channel then
		jsonData.channel = DiscordChannel.from(discordClient, jsonData.channel)
	end

	if jsonData.guild then
		jsonData.guild = DiscordGuild.new(discordClient, jsonData.guild)
	end

	if jsonData.user then
		jsonData.user = DiscordUser.new(discordClient, jsonData.user)
	end

	if jsonData.member then
		jsonData.member =
			DiscordGuildMember.new(discordClient, jsonData.member.user.id, jsonData.guild.id, jsonData.member)

		jsonData.member.user = nil
	end

	if jsonData.appPermissions then
		jsonData.appPermissions = PermissionsBuilder.from(jsonData.appPermissions)
	end

	for index, value in jsonData do
		interactionStruct[index] = value
	end

	return Construct(interactionStruct, DiscordInteraction.Prototype)
end

export type DiscordInteraction = typeof(DiscordInteraction.Prototype) & {
	discordClient: any,

	channel: DiscordChannel.DiscordChannel,
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
	appPermissions: PermissionsBuilder.PermissionsBuilder, -- todo: implement discord permission
	guildLocale: string,
	locale: string,
	-- entitlements: { unknown }, -- todo: support interaction entitlements
	-- entitlementSkuIds: { unknown }, -- todo: support interaction entitlements

	defered: boolean,
}

return DiscordInteraction.Interface
