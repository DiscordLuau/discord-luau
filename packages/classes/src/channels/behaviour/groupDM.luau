--[[
	Group DM Behaviour, responsible for implementing the various properties, and methods for a group DM.
]]

local future = require("@vendor/future")

local apiTypes = require("@api-types/apiTypes")

local channelRest = require("@rest/channel")

local user = require("@classes/user")
local state = require("@classes/state")

local channelBuilder = require("@builders/channel")

local GroupDMBehaviour = {}

GroupDMBehaviour.Interface = {}
GroupDMBehaviour.Prototype = {}

--[[
	Adds a recipient to a Group DM using their access token.
]]
function GroupDMBehaviour.Prototype.addRecipient<T>(
	self: Channel<T>,
	accessToken: string,
	userId: string,
	nickname: string
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest
			.groupDMAddRecipientAsync(request, self.id, userId, {
				access_token = accessToken,
				nick = nickname,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Removes a recipient from a Group DM.
]]
function GroupDMBehaviour.Prototype.removeRecipient<T>(self: Channel<T>, userId: string): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.groupDMRemoveRecipientAsync(request, self.id, userId):await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Sets the name of the Group DM channel.
]]
function GroupDMBehaviour.Prototype.setNameAsync<T>(self: Channel<T>, groupName: string): future.Future<Channel<T>>
	return self:modifyAsync({
		name = groupName,
	})
end

--[[
	Sets the icon of the Group DM channel using base64 encoded image data.
]]
function GroupDMBehaviour.Prototype.setIconAsync<T>(self: Channel<T>, iconData: string): future.Future<Channel<T>>
	return self:modifyAsync({
		name = self.name,
		icon = iconData,
	})
end
function GroupDMBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local recipientArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, recipient in next, channelData.recipients or {} do
		table.insert(recipientArray, user.new(recipient))
	end

	class.recipients = recipientArray
	class.icon = channelData.icon
	class.ownerId = channelData.owner_id
	class.applicationId = channelData.application_id
	class.managed = channelData.managed
end

function GroupDMBehaviour.Interface.inheritMethods(class: any)
	for key, value in GroupDMBehaviour.Prototype do
		class[key] = value
	end
end

type Channel<T> = T & GroupDMBehaviour & {
	state: state.State,
	id: string,
	name: string,

	modifyAsync: (self: Channel<T>, json: channelBuilder.JSON, reason: string?) -> future.Future<Channel<T>>,

	sync: (...any) -> (),
}

export type GroupDMBehaviourMethods = typeof(GroupDMBehaviour.Prototype)
export type GroupDMBehaviourProperties = {
	recipients: { user.User },
	icon: string?,
	ownerId: string?,
	applicationId: string?,
	managed: boolean,
}

export type GroupDMBehaviour = GroupDMBehaviourMethods & GroupDMBehaviourProperties

return GroupDMBehaviour.Interface
