local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.guild

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild
]=]
local guild = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#create-guild
]=]
function guild.createGuildAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateGuildRequest
): future.FutureLike<string, apiTypes.CreateGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateGuild)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild
]=]
function guild.getGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withCounts: boolean?,
	}
): future.FutureLike<string, apiTypes.GetGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuild, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-preview
]=]
function guild.getGuildPreviewAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildPreviewResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildPreview, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildPreviewResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild
]=]
function guild.modifyGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuild, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#delete-guild
]=]
function guild.deleteGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.DeleteGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuild, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-channels
]=]
function guild.getGuildChannelsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildChannelsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildChannels, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildChannelsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#create-guild-channel
]=]
function guild.createGuildChannelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildChannelRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.CreateGuildChannelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildChannel, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildChannelResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
]=]
function guild.modifyGuildChannelPositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildChannelPositionsRequest
): future.FutureLike<string, apiTypes.ModifyGuildChannelPositionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildChannelPositions, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildChannelPositionsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#list-active-guild-threads
]=]
function guild.listActiveGuildThreadsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.ListActiveGuildThreadsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListActiveGuildThreads, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListActiveGuildThreadsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-member
]=]
function guild.getGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildMember, guildId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#list-guild-members
]=]
function guild.listGuildMembersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		limit: number?,
		after: string?,
	}
): future.FutureLike<string, apiTypes.ListGuildMembersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildMembers, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListGuildMembersResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#search-guild-members
]=]
function guild.searchGuildMembersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		query: string,
		limit: number?,
	}
): future.FutureLike<string, apiTypes.SearchGuildMembersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("query", urlParams.query)
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.SearchGuildMembers, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.SearchGuildMembersResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#add-guild-member
]=]
function guild.addGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.AddGuildMemberRequest
): future.FutureLike<string, apiTypes.AddGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddGuildMember, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.AddGuildMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-member
]=]
function guild.modifyGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildMemberRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildMember, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-current-member
]=]
function guild.modifyCurrentMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyCurrentMemberRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyCurrentMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyCurrentMember, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyCurrentMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#add-guild-member-role
]=]
function guild.addGuildMemberRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.AddGuildMemberRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.AddGuildMemberRoleResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#remove-guild-member-role
]=]
function guild.removeGuildMemberRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.RemoveGuildMemberRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.RemoveGuildMemberRoleResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#remove-guild-member
]=]
function guild.removeGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.RemoveGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildMember, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.RemoveGuildMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-bans
]=]
function guild.getGuildBansAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		limit: number?,
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.GetGuildBansResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildBans, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildBansResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-ban
]=]
function guild.getGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildBan, guildId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildBanResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#create-guild-ban
]=]
function guild.createGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildBanRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.CreateGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildBan, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildBanResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#remove-guild-ban
]=]
function guild.removeGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.RemoveGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildBan, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.RemoveGuildBanResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#bulk-guild-ban
]=]
function guild.bulkGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkGuildBanRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.BulkGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BulkGuildBan, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.BulkGuildBanResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-roles
]=]
function guild.getGuildRolesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildRolesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildRoles, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildRolesResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-role
]=]
function guild.getGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildRole, guildId, roleId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildRoleResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#create-guild-role
]=]
function guild.createGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildRoleRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.CreateGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildRole, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildRoleResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
]=]
function guild.modifyGuildRolePositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRolePositionsRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildRolePositionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildRolePositions, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildRolePositionsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-role
]=]
function guild.modifyGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRoleRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildRole, guildId, roleId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildRoleResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
]=]
function guild.modifyGuildMFALevelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildMFALevelRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildMFALevelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildMFALevel, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildMFALevelResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#delete-guild-role
]=]
function guild.deleteGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildRole, guildId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildRoleResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-prune-count
]=]
function guild.getGuildPruneCountAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		days: number,
		includeRoles: string,
	}
): future.FutureLike<string, apiTypes.GetGuildPruneCountResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("days", tostring(urlParams.days))
		instance:addUrlParam("include_roles", tostring(urlParams.includeRoles))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildPruneCount, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildPruneCountResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#begin-guild-prune
]=]
function guild.beginGuildPruneAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BeginGuildPruneRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.BeginGuildPruneResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BeginGuildPrune, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.BeginGuildPruneResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
]=]
function guild.getGuildVoiceRegionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildVoiceRegionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildVoiceRegions, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildVoiceRegionsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-invites
]=]
function guild.getGuildInvitesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildInvitesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildInvites, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildInvitesResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-integrations
]=]
function guild.getGuildIntegrationsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildIntegrationsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildIntegrations, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildIntegrationsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#delete-guild-integration
]=]
function guild.deleteGuildIntegrationAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	integrationId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteGuildIntegrationResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildIntegration, guildId, integrationId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildIntegrationResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
]=]
function guild.getGuildWidgetSettingsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildWidgetSettingsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetSettings, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildWidgetSettingsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-widget
]=]
function guild.modifyGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildWidgetRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildWidgetResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetSettings, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildWidgetResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-widget
]=]
function guild.getGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildWidgetResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidget, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildWidgetResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
]=]
function guild.getGuildVanityURLAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildVanityUrlResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildVanityURL, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildVanityUrlResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-widget-image
]=]
function guild.getGuildWidgetImageAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		style: ("shield" | "banner1" | "banner2" | "banner3" | "banner4")?,
	}
): future.FutureLike<string, apiTypes.GetGuildWidgetImageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("style", urlParams.style :: any)

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetImage, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildWidgetImageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
]=]
function guild.getGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildWelcomeScreenResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWelcomeScreen, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildWelcomeScreenResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
]=]
function guild.modifyGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildWelcomeScreenRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildWelcomeScreenResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildWelcomeScreen, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildWelcomeScreenResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#get-guild-onboarding
]=]
function guild.getGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildOnboardingResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildOnboarding, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildOnboardingResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
]=]
function guild.modifyGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildOnboardingRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildOnboardingResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildOnboarding, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildOnboardingResponse>
end

return guild
