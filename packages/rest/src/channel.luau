local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/channel
]]
local Channel = {}

-- https://discord.com/developers/docs/resources/channel#get-channel
function Channel.getChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.GetChannelResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetChannel, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#modify-channel
function Channel.modifyChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyChannelRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyChannelResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyChannel, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#deleteclose-channel
function Channel.deleteOrCloseChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.DeleteCloseChannelResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteOrCloseChannel, channelId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#edit-channel-permissions
function Channel.editChannelPermissionsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	overwriteId: apiTypes.Snowflake,
	jsonParams: restTypes.EditChannelPermissionsRequest,
	auditLogReason: string?
): future.Future<restTypes.EditChannelPermissionsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.EditChannelPermissions, channelId, overwriteId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#get-channel-invites
function Channel.getChannelInvitesAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.GetChannelInvitesResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetChannelInvites, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#create-channel-invite
function Channel.createChannelInviteAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateChannelInviteRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateChannelInviteResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateChannelInvite, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#delete-channel-permission
function Channel.deleteChannelPermissionAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	overwriteId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.CreateChannelInviteResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.DeleteChannelPermission, channelId, overwriteId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#follow-announcement-channel
function Channel.followAnnouncementChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: restTypes.FollowAnnouncementChannelRequest,
	auditLogReason: string?
): future.Future<restTypes.FollowAnnouncementChannelResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.FollowAnnouncementChannel, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
function Channel.triggerTypingIndicatorAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.TriggerTypingIndicatorResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.TriggerTypingChannel, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#get-pinned-messages
function Channel.getPinnedMessagesAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.TriggerTypingIndicatorResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetPinnedMessages, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#pin-message
function Channel.pinMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.PinMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.PinMessage, channelId, messageId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#unpin-message
function Channel.unpinMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.UnpinMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.UnpinMessage, channelId, messageId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#group-dm-add-recipient
function Channel.groupDMAddRecipientAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: restTypes.GroupDMAddRecipientRequest
): future.Future<restTypes.GroupDMAddRecipientResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.GroupDMAddRecipient, channelId, userId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#group-dm-remove-recipient
function Channel.groupDMRemoveRecipientAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<restTypes.GroupDMRemoveRecipientResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.GroupDMRemoveRecipient, channelId, userId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#start-thread-from-message
function Channel.startThreadFromMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	jsonParams: restTypes.StartThreadFromMessageRequest,
	auditLogReason: string?
): future.Future<restTypes.StartThreadFromMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.StartThreadFromMessage, channelId, messageId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#start-thread-without-message
function Channel.startThreadWithoutMessageAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: restTypes.StartThreadWithoutMessageRequest,
	auditLogReason: string?
): future.Future<restTypes.StartThreadWithoutMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.StartThreadWithoutMessage, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
function Channel.startThreadInForumOrMediaChannelAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: restTypes.StartThreadInForumOrMediaChannelRequest,
	auditLogReason: string?
): future.Future<
	restTypes.StartThreadInForumOrMediaChannelResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.StartThreadInForumOrMediaChannel, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#join-thread
function Channel.joinThreadAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.JoinThreadResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.JoinThread, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#add-thread-member
function Channel.addThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<restTypes.AddThreadMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.AddThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#leave-thread
function Channel.leaveThreadAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.LeaveThreadResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.LeaveThread, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#remove-thread-member
function Channel.removeThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<restTypes.RemoveThreadMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.RemoveThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#get-thread-member
function Channel.getThreadMemberAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	urlParams: {
		withMember: boolean?,
	}
): future.Future<restTypes.GetThreadMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_member", urlParams.withMember and tostring(urlParams.withMember) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetThreadMember, channelId, userId))

		local response = instance:executeAsync():await()

		return response.body
	end)
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
): future.Future<restTypes.ListThreadMembersResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_member", urlParams.withMember and tostring(urlParams.withMember) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListThreadMembers, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#list-public-archived-threads
function Channel.listPublicArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
): future.Future<restTypes.ListPublicArchivedThreadsResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListPublicArchivedThreads, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#list-private-archived-threads
function Channel.listPrivateArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
): future.Future<restTypes.ListPrivateArchivedThreadsResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListPrivateArchivedThreads, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
function Channel.listJoinedPrivateArchivedThreadsAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	urlParams: {
		before: string?,
		limit: number?,
	}
): future.Future<restTypes.ListPrivateArchivedThreadsResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListJoinedPrivateArchivedThreads, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

return Channel
