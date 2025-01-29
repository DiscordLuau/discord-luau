local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/channel
]]
local Channel = {}

-- https://discord.com/developers/docs/resources/channel#get-channel
function Channel.getChannelAsync(instance: request.Request, channelId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannel, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelResponse>
end

-- https://discord.com/developers/docs/resources/channel#modify-channel
function Channel.modifyChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyChannelRequest,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#deleteclose-channel
function Channel.deleteOrCloseChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#edit-channel-permissions
function Channel.editChannelPermissionsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	overwriteId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditChannelPermissionsRequest,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#get-channel-invites
function Channel.getChannelInvitesAsync(instance: request.Request, channelId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelInvites, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelInvitesResponse>
end

-- https://discord.com/developers/docs/resources/channel#create-channel-invite
function Channel.createChannelInviteAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateChannelInviteRequest,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#delete-channel-permission
function Channel.deleteChannelPermissionAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	overwriteId: apiTypes.Snowflake,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#follow-announcement-channel
function Channel.followAnnouncementChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.FollowAnnouncementChannelRequest,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
function Channel.triggerTypingIndicatorAsync(instance: request.Request, channelId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.TriggerTypingChannel, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.TriggerTypingIndicatorResponse>
end

-- https://discord.com/developers/docs/resources/channel#get-pinned-messages
function Channel.getPinnedMessagesAsync(instance: request.Request, channelId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetPinnedMessages, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetPinnedMessagesResponse>
end

-- https://discord.com/developers/docs/resources/channel#pin-message
function Channel.pinMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#unpin-message
function Channel.unpinMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
function Channel.groupDMAddRecipientAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.GroupDMAddRecipientRequest
)
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

-- https://discord.com/developers/docs/resources/channel#group-dm-remove-recipient
function Channel.groupDMRemoveRecipientAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GroupDMRemoveRecipient, channelId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GroupDMRemoveRecipientResponse>
end

-- https://discord.com/developers/docs/resources/channel#start-thread-from-message
function Channel.startThreadFromMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.StartThreadFromMessageRequest,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#start-thread-without-message
function Channel.startThreadWithoutMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.StartThreadWithoutMessageRequest_,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
function Channel.startThreadInForumOrMediaChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.StartThreadInForumOrMediaChannelRequest,
	auditLogReason: string?
)
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

-- https://discord.com/developers/docs/resources/channel#join-thread
function Channel.joinThreadAsync(instance: request.Request, channelId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.JoinThread, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.JoinThreadResponse>
end

-- https://discord.com/developers/docs/resources/channel#add-thread-member
function Channel.addThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.AddThreadMemberResponse>
end

-- https://discord.com/developers/docs/resources/channel#leave-thread
function Channel.leaveThreadAsync(instance: request.Request, channelId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.LeaveThread, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.LeaveThreadResponse>
end

-- https://discord.com/developers/docs/resources/channel#remove-thread-member
function Channel.removeThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.RemoveThreadMemberResponse>
end

-- https://discord.com/developers/docs/resources/channel#get-thread-member
function Channel.getThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	urlParams: {
		withMember: boolean?,
	}
)
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

-- https://discord.com/developers/docs/resources/channel#list-thread-members
function Channel.listThreadMembersAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		withMember: boolean?,
		after: apiTypes.Snowflake?,
		limit: number?,
	}
)
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

-- https://discord.com/developers/docs/resources/channel#list-public-archived-threads
function Channel.listPublicArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
)
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

-- https://discord.com/developers/docs/resources/channel#list-private-archived-threads
function Channel.listPrivateArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
)
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

-- https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
function Channel.listJoinedPrivateArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
)
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

return Channel
