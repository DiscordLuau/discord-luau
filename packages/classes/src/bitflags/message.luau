--[=[
	@class Classes.MessageBitflag
	@__index MessageBitflag.Prototype
	
	Implementation of the Discord Message Bitflags in Luau.
	Represents various flags that can be applied to Discord messages.
	
	https://discord.com/developers/docs/resources/message#message-object-message-flags
]=]

local bit = require("../../luau_packages/bit")

local MessageBitflag = {}

MessageBitflag.Interface = {}
MessageBitflag.Prototype = {}

--[=[
	@within Classes.MessageBitflag
	Checks if this message has been published to subscribed channels (via Channel Following).
]=]
function MessageBitflag.Prototype.crossposted(self: MessageBitflag)
	local targetBit = bit.lshift(1, 0)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message originated from a message in another channel (via Channel Following).
]=]
function MessageBitflag.Prototype.isCrossposted(self: MessageBitflag)
	local targetBit = bit.lshift(1, 1)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if embeds should be suppressed when serializing this message.
]=]
function MessageBitflag.Prototype.suppressEmbeds(self: MessageBitflag)
	local targetBit = bit.lshift(1, 2)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if the source message for this crosspost has been deleted (via Channel Following).
]=]
function MessageBitflag.Prototype.sourceMessageDeleted(self: MessageBitflag)
	local targetBit = bit.lshift(1, 3)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message came from the urgent message system.
]=]
function MessageBitflag.Prototype.urgent(self: MessageBitflag)
	local targetBit = bit.lshift(1, 4)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message has an associated thread, with the same id as the message.
]=]
function MessageBitflag.Prototype.hasThread(self: MessageBitflag)
	local targetBit = bit.lshift(1, 5)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message is only visible to the user who invoked the Interaction.
]=]
function MessageBitflag.Prototype.ephemeral(self: MessageBitflag)
	local targetBit = bit.lshift(1, 6)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message is an Interaction Response and the bot is "thinking".
]=]
function MessageBitflag.Prototype.loading(self: MessageBitflag)
	local targetBit = bit.lshift(1, 7)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message failed to mention some roles and add their members to the thread.
]=]
function MessageBitflag.Prototype.failedToMentionSomeRolesInThread(self: MessageBitflag)
	local targetBit = bit.lshift(1, 8)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message will not trigger push and desktop notifications.
]=]
function MessageBitflag.Prototype.suppressNotifications(self: MessageBitflag)
	local targetBit = bit.lshift(1, 12)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.MessageBitflag
	Checks if this message is a voice message.
]=]
function MessageBitflag.Prototype.isVouceMessage(self: MessageBitflag)
	local targetBit = bit.lshift(1, 13)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@private
	@within Classes.MessageBitflag
	Creates a new MessageBitflag instance with the specified flag value.
]=]
function MessageBitflag.Interface.new(flag: number): MessageBitflag
	local self = setmetatable(
		{
			--[=[
				@prop flag number
				The raw bitflag value for the message.
			]=]
			flag = flag,
		} :: MessageBitflag,
		{ __index = MessageBitflag.Prototype }
	)

	return self
end

export type MessageBitflag = typeof(MessageBitflag.Prototype) & {
	flag: number,
}

return MessageBitflag.Interface
