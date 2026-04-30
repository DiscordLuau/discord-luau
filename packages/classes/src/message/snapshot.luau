--[=[
	@class Classes.Message.Snapshot
	@__index Prototype

	Implementation of the Discord Message Snapshot class in Luau

	https://discord.com/developers/docs/resources/message#message-snapshot-object

	Note: `content` will be empty if the bot does not have the `MESSAGE_CONTENT` intent enabled.
	Discord returns error 160014 if you attempt to forward a message without this intent.
]=]

--[=[
	@prop type string
	@within Classes.Message.Snapshot
	Type of the forwarded message
]=]

--[=[
	@prop content string
	@within Classes.Message.Snapshot
	Contents of the forwarded message
]=]

--[=[
	@prop embeds { Classes.Embed }
	@within Classes.Message.Snapshot
	Any embedded content in the forwarded message
]=]

--[=[
	@prop attachments { Classes.Attachment }
	@within Classes.Message.Snapshot
	Any attached files in the forwarded message
]=]

--[=[
	@prop timestamp DateTime
	@within Classes.Message.Snapshot
	When the forwarded message was sent
]=]

--[=[
	@prop editedTimestamp DateTime?
	@within Classes.Message.Snapshot
	When the forwarded message was last edited
]=]

--[=[
	@prop flags number?
	@within Classes.Message.Snapshot
	Message flags combined as a bitfield
]=]

--[=[
	@prop mentions { Classes.User }
	@within Classes.Message.Snapshot
	Users specifically mentioned in the forwarded message
]=]

--[=[
	@prop mentionRoles { string }
	@within Classes.Message.Snapshot
	Role IDs specifically mentioned in the forwarded message
]=]

--[=[
	@prop stickerItems { Classes.Message.StickerItem }
	@within Classes.Message.Snapshot
	Stickers sent with the forwarded message
]=]

--[=[
	@prop components { Classes.Message.Components }
	@within Classes.Message.Snapshot
	Components in the forwarded message
]=]

local stdPolyfills = require("../../luau_packages/std_polyfills")
local apiTypes = require("../../luau_packages/api_types")

local user = require("../user")
local embed = require("../embed/embed")
local attachment = require("../attachment")
local stickerItem = require("./stickerItem")
local textInputComponent = require("./components/textInput")
local selectMenuComponent = require("./components/selectMenu/selectMenu")
local actionRowComponent = require("./components/actionRow")
local buttonComponent = require("./components/button")

local Snapshot = {}

Snapshot.Interface = {}
Snapshot.Prototype = {}

--[=[
	@within Classes.Message.Snapshot
	@private

	Responsible for syncing data to this snapshot object. This is typically called by the API when this object is
	created or updated.
]=]
function Snapshot.Prototype.sync(self: Snapshot, snapshotData: apiTypes.MessageSnapshotObject): nil
	local content = snapshotData.message

	local mentionArray = {}
	local embedArray = {}
	local attachmentArray = {}
	local stickerItemArray = {}
	local componentArray: {
		textInputComponent.TextInput
		| selectMenuComponent.SelectMenu
		| actionRowComponent.ActionRow
		| buttonComponent.Button
	} = {}

	for _, userData in next, content.mentions do
		table.insert(mentionArray, user.new(userData))
	end

	for _, embedData in next, content.embeds do
		table.insert(embedArray, embed.new(embedData))
	end

	for _, attachmentData in next, content.attachments do
		table.insert(attachmentArray, attachment.new(attachmentData))
	end

	for _, stickerData in next, content.sticker_items or {} do
		table.insert(stickerItemArray, stickerItem.new(stickerData))
	end

	for _, componentData in next, content.components or {} do
		if componentData.type == 1 then
			local data = componentData :: apiTypes.ActionRowComponentObject
			table.insert(componentArray, actionRowComponent.new(data))
		elseif componentData.type == 2 then
			local data = componentData :: apiTypes.ButtonComponentObject
			table.insert(componentArray, buttonComponent.new(data))
		elseif componentData.type == 4 then
			local data = componentData :: apiTypes.TextInputComponentObject
			table.insert(componentArray, textInputComponent.new(data))
		elseif
			componentData.type == 3
			or componentData.type == 5
			or componentData.type == 6
			or componentData.type == 7
			or componentData.type == 8
		then
			local data = componentData :: apiTypes.SelectMenuComponentObject
			table.insert(componentArray, selectMenuComponent.new(data))
		end
	end

	self.type = apiTypes.message.MessageType[content.type]
	self.content = content.content
	self.embeds = embedArray
	self.attachments = attachmentArray
	self.timestamp = stdPolyfills.datetime.fromIsoDate(content.timestamp)
	self.editedTimestamp = content.edited_timestamp
		and stdPolyfills.datetime.fromIsoDate(content.edited_timestamp)
	self.flags = content.flags
	self.mentions = mentionArray
	self.mentionRoles = content.mention_roles
	self.stickerItems = stickerItemArray
	self.components = componentArray

	return nil
end

--[=[
	@within Classes.Message.Snapshot
	@private

	Responsible for constructing this class.
]=]
function Snapshot.Interface.new(snapshotData: apiTypes.MessageSnapshotObject): Snapshot
	local self = setmetatable({} :: Snapshot, { __index = Snapshot.Prototype })

	self:sync(snapshotData)

	return self
end

export type Snapshot = typeof(Snapshot.Prototype) & {
	type: apiTypes.MessageType,
	content: string,
	embeds: { embed.Embed },
	attachments: { attachment.Attachment },
	timestamp: stdPolyfills.DateTime,
	editedTimestamp: stdPolyfills.DateTime?,
	flags: number?,
	mentions: { user.User },
	mentionRoles: { apiTypes.Snowflake },
	stickerItems: { stickerItem.StickerItem },
	components: {
		textInputComponent.TextInput
		| selectMenuComponent.SelectMenu
		| actionRowComponent.ActionRow
		| buttonComponent.Button
	},
}

return Snapshot.Interface
