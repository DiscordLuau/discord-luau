local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.channel

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/channel
]=]
local channel = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#get-channel
]=]
function channel.getChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetChannelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannel, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#modify-channel
]=]
function channel.modifyChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyChannelRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyChannelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyChannel, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyChannelResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#deleteclose-channel
]=]
function channel.deleteOrCloseChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteCloseChannelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteOrCloseChannel, channelId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteCloseChannelResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#edit-channel-permissions
]=]
function channel.editChannelPermissionsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	overwriteId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditChannelPermissionsRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.EditChannelPermissionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditChannelPermissions, channelId, overwriteId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EditChannelPermissionsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#get-channel-invites
]=]
function channel.getChannelInvitesAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetChannelInvitesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelInvites, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelInvitesResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#create-channel-invite
]=]
function channel.createChannelInviteAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateChannelInviteRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.CreateChannelInviteResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateChannelInvite, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateChannelInviteResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#delete-channel-permission
]=]
function channel.deleteChannelPermissionAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	overwriteId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteChannelPermissionResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteChannelPermission, channelId, overwriteId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteChannelPermissionResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#follow-announcement-channel
]=]
function channel.followAnnouncementChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.FollowAnnouncementChannelRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.FollowAnnouncementChannelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.FollowAnnouncementChannel, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.FollowAnnouncementChannelResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
]=]
function channel.triggerTypingIndicatorAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.TriggerTypingIndicatorResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.TriggerTypingChannel, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.TriggerTypingIndicatorResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#get-pinned-messages
]=]
function channel.getPinnedMessagesAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetPinnedMessagesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetPinnedMessages, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetPinnedMessagesResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#pin-message
]=]
function channel.pinMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.PinMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.PinMessage, channelId, messageId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.PinMessageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#unpin-message
]=]
function channel.unpinMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.UnpinMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.UnpinMessage, channelId, messageId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.UnpinMessageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
]=]
function channel.groupDMAddRecipientAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.GroupDMAddRecipientRequest
): future.FutureLike<string, apiTypes.GroupDMAddRecipientResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GroupDMAddRecipient, channelId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GroupDMAddRecipientResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#group-dm-remove-recipient
]=]
function channel.groupDMRemoveRecipientAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GroupDMRemoveRecipientResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GroupDMRemoveRecipient, channelId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GroupDMRemoveRecipientResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#start-thread-from-message
]=]
function channel.startThreadFromMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.StartThreadFromMessageRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.StartThreadFromMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.StartThreadFromMessage, channelId, messageId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.StartThreadFromMessageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#start-thread-without-message
]=]
function channel.startThreadWithoutMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.StartThreadWithoutMessageRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.StartThreadWithoutMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.StartThreadWithoutMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.StartThreadWithoutMessageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
]=]
function channel.startThreadInForumOrMediaChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.StartThreadInForumOrMediaChannelRequest,
	auditLogReason: string?
): future.FutureLike<
	string,
	apiTypes.StartThreadInForumOrMediaChannelResponse
>
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("POST")
				instance:setUrl(string.format(apiTypes.rest.endpoints.StartThreadInForumOrMediaChannel, channelId))
				instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
				instance:addHeader("x-audit-log-reason", auditLogReason :: string)

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.StartThreadInForumOrMediaChannelResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#join-thread
]=]
function channel.joinThreadAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.JoinThreadResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.JoinThread, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.JoinThreadResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#add-thread-member
]=]
function channel.addThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.AddThreadMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.AddThreadMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#leave-thread
]=]
function channel.leaveThreadAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.LeaveThreadResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.LeaveThread, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.LeaveThreadResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#remove-thread-member
]=]
function channel.removeThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.RemoveThreadMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.RemoveThreadMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#get-thread-member
]=]
function channel.getThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	urlParams: {
		withMember: boolean?,
	}
): future.FutureLike<string, apiTypes.GetThreadMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_member", urlParams.withMember and tostring(urlParams.withMember) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetThreadMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#list-thread-members
]=]
function channel.listThreadMembersAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		withMember: boolean?,
		after: apiTypes.Snowflake?,
		limit: number?,
	}
): future.FutureLike<string, apiTypes.ListThreadMembersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_member", urlParams.withMember and tostring(urlParams.withMember) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListThreadMembers, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListThreadMembersResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#list-public-archived-threads
]=]
function channel.listPublicArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
): future.FutureLike<string, apiTypes.ListPublicArchivedThreadsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListPublicArchivedThreads, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListPublicArchivedThreadsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#list-private-archived-threads
]=]
function channel.listPrivateArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
): future.FutureLike<string, apiTypes.ListPrivateArchivedThreadsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListPrivateArchivedThreads, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListPrivateArchivedThreadsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
]=]
function channel.listJoinedPrivateArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
): future.FutureLike<
	string,
	apiTypes.ListJoinedPrivateArchivedThreadsResponse
>
	return future.Future.new(
			function()
				instance:assertToken()

				instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
				instance:addUrlParam("before", urlParams.before or (nil :: any))

				instance:setMethod("GET")
				instance:setUrl(string.format(apiTypes.rest.endpoints.ListJoinedPrivateArchivedThreads, channelId))

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.ListJoinedPrivateArchivedThreadsResponse>
end

return channel
