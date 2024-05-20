local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local Construct = require("../../Utils/Construct")

local DiscordModal = require("../Builders/DiscordModal")
local DiscordPermissions = require("../Builders/DiscordPermissions")

local DiscordGuildMember = require("DiscordGuildMember")

local DiscordTextChannel = require("DiscordTextChannel")
local DiscordUser = require("DiscordUser")
local DiscordGuild = require("DiscordGuild")

local DiscordMessage = require("DiscordMessage")

--[=[
	@class Objects.DiscordInteraction

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordInteraction = {}

DiscordInteraction.Interface = {}
DiscordInteraction.Prototype = {}

DiscordInteraction.Prototype.type = "DiscordInteraction"

function DiscordInteraction.Prototype.editMessageAsync(self: DiscordInteraction, messageData: DiscordMessage.DiscordMessageSchema)
	return Future.new(function()
		return self.discordClient.discordGateway:patchAsync(string.format(
			DiscordEndpoints.EditOriginalInteractionResponse,
			self.discordClient.discordApplication.id,
			self.token
		), DiscordMessage.intoJson(messageData)):await()
	end)
end

function DiscordInteraction.Prototype.sendModalAsync(self: DiscordInteraction, modalObject: DiscordModal.DiscordModal)
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

function DiscordInteraction.Prototype.sendMessageAsync(self: DiscordInteraction, messageData: DiscordMessage.DiscordMessageSchema)
	if self.defered then
		return self:editMessageAsync(messageData)
	else
		return Future.new(function()
			return self.discordClient.discordGateway:postAsync(string.format(
				DiscordEndpoints.CreateInteractionResponse,
				self.id,
				self.token
			), {
				type = 4,
				data = DiscordMessage.intoJson(messageData)
			}):await()
		end)
	end
end

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

function DiscordInteraction.Interface.new(discordClient: any, jsonData: { [any]: any })
	local interactionStruct = {
		discordClient = discordClient,

		defered = false
	}

	jsonData.channel = DiscordTextChannel.new(discordClient, jsonData.channel)
	jsonData.guild = DiscordGuild.new(discordClient, jsonData.guild)
	jsonData.user = DiscordUser.new(discordClient, jsonData.member.user)
	jsonData.member = DiscordGuildMember.new(discordClient, jsonData.member.user.id, jsonData.guild.id, jsonData.member)
	jsonData.appPermissions = DiscordPermissions.from(jsonData.appPermissions)

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
	appPermissions: DiscordPermissions.DiscordPermissions,
	guildLocale: string,
	locale: string,
	entitlements: { unknown },
	entitlementSkuIds: { unknown },

	defered: boolean,
}

return DiscordInteraction.Interface