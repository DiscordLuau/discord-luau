--[=[
	@class Classes.GroupDMBehaviour
	@__index Prototype

	Behaviour class that implements the properties and methods specific to Group DM channels in Discord.
	This behaviour is inherited by the GroupDM class to provide group DM specific functionality.

	Group DM behaviours include:
	- Managing recipients (adding/removing users)
	- Modifying group DM properties (name, icon)
	- Handling group DM specific data (recipients, icon, owner, etc.)
]=]

local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")

local user = require("../../user")

local GroupDMBehaviour = {}

GroupDMBehaviour.Interface = {}
GroupDMBehaviour.Prototype = {}

--[=[
	@within Classes.GroupDMBehaviour
	Adds a recipient to a Group DM using their access token.
]=]
function GroupDMBehaviour.Prototype.addRecipient<T>(
	self: Channel<T>,
	accessToken: string,
	userId: string,
	nickname: string
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.groupDMAddRecipientAsync(request, self.id, userId, {
				access_token = accessToken,
				nick = nickname,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.GroupDMBehaviour
	Removes a recipient from a Group DM.
]=]
function GroupDMBehaviour.Prototype.removeRecipient<T>(self: Channel<T>, userId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.groupDMRemoveRecipientAsync(request, self.id, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.GroupDMBehaviour
	Sets the name of the Group DM channel.
]=]
function GroupDMBehaviour.Prototype.setNameAsync<T>(self: Channel<T>, groupName: string)
	return self:modifyAsync({
		name = groupName,
	}) :: future.FutureLike<string, Channel<T>>
end

--[=[
	@within Classes.GroupDMBehaviour
	Sets the icon of the Group DM channel using base64 encoded image data.
]=]
function GroupDMBehaviour.Prototype.setIconAsync<T>(self: Channel<T>, iconData: string)
	return self:modifyAsync({
		name = self.name,
		icon = iconData,
	}) :: future.FutureLike<string, Channel<T>>
end

--[=[
	@within Classes.GroupDMBehaviour
	@private

	Inherits properties from the channel data into the class instance.
	This is typically called during object creation or updates.
]=]
function GroupDMBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local recipientArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, recipient in next, channelData.recipients or {} do
		table.insert(recipientArray, user.new(recipient))
	end

	--[=[
		@within Classes.GroupDMBehaviour
		@prop recipients { Classes.User }
		The users in the Group DM channel.
	]=]
	class.recipients = recipientArray

	--[=[
		@within Classes.GroupDMBehaviour
		@prop icon string?
		The icon hash of the Group DM channel.
	]=]
	class.icon = channelData.icon

	--[=[
		@within Classes.GroupDMBehaviour
		@prop ownerId string?
		The ID of the user who created the Group DM channel.
	]=]
	class.ownerId = channelData.owner_id

	--[=[
		@within Classes.GroupDMBehaviour
		@prop applicationId string?
		The ID of the application that created the Group DM channel, if it was created by an application.
	]=]
	class.applicationId = channelData.application_id

	--[=[
		@within Classes.GroupDMBehaviour
		@prop managed boolean
		Whether the Group DM channel is managed by an application.
	]=]
	class.managed = channelData.managed
end

--[=[
	@within Classes.GroupDMBehaviour
	@private

	Inherits methods from the GroupDMBehaviour prototype into the class instance.
	This is typically called during object creation or updates.
]=]
function GroupDMBehaviour.Interface.inheritMethods(class: any)
	for key, value in GroupDMBehaviour.Prototype do
		class[key] = value
	end
end

type Channel<T> = T & GroupDMBehaviour & {
	state: state.State,
	id: string,
	name: string,

	modifyAsync: any,

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
