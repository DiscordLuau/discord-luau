local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild
]]
local Guild = {}

-- https://discord.com/developers/docs/resources/guild#create-guild
function Guild.createGuildAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateGuildRequest
): future.Future<string, apiTypes.CreateGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateGuild)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild
function Guild.getGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withCounts: boolean?,
	}
): future.Future<string, apiTypes.GetGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuild, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-preview
function Guild.getGuildPreviewAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildPreviewResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildPreview, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild
function Guild.modifyGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuild, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild
function Guild.deleteGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.DeleteGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuild, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-channels
function Guild.getGuildChannelsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildChannelsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildChannels, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-channel
function Guild.createGuildChannelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildChannelRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.CreateGuildChannelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildChannel, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
function Guild.modifyGuildChannelPositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildChannelPositionsRequest
): future.Future<string, apiTypes.ModifyGuildChannelPositionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildChannelPositions, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#list-active-guild-threads
function Guild.listActiveGuildThreadsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.ListActiveGuildThreadsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListActiveGuildThreads, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-member
function Guild.getGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildMember, guildId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#list-guild-members
function Guild.listGuildMembersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		limit: number?,
		after: string?,
	}
): future.Future<string, apiTypes.ListGuildMembersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildMembers, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#search-guild-members
function Guild.searchGuildMembersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		query: string,
		limit: number?,
	}
): future.Future<string, apiTypes.SearchGuildMembersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("query", urlParams.query)
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.SearchGuildMembers, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#add-guild-member
function Guild.addGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.AddGuildMemberRequest
): future.Future<string, apiTypes.AddGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddGuildMember, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-member
function Guild.modifyGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildMemberRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildMember, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-current-member
function Guild.modifyCurrentMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyCurrentMemberRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyCurrentMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyCurrentMember, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#add-guild-member-role
function Guild.addGuildMemberRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.AddGuildMemberRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-member-role
function Guild.removeGuildMemberRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.RemoveGuildMemberRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-member
function Guild.removeGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.RemoveGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildMember, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-bans
function Guild.getGuildBansAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		limit: number?,
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
	}
): future.Future<string, apiTypes.GetGuildBansResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildBans, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-ban
function Guild.getGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildBan, guildId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-ban
function Guild.createGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildBanRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.CreateGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildBan, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-ban
function Guild.removeGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.RemoveGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildBan, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#bulk-guild-ban
function Guild.bulkGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkGuildBanRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.BulkGuildBanResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BulkGuildBan, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-roles
function Guild.getGuildRolesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildRolesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildRoles, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-role
function Guild.getGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildRole, guildId, roleId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-role
function Guild.createGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildRoleRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.CreateGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildRole, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
function Guild.modifyGuildRolePositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRolePositionsRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildRolePositionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildRolePositions, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-role
function Guild.modifyGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRoleRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildRole, guildId, roleId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
function Guild.modifyGuildMFALevelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildMFALevelRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildMFALevelResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildMFALevel, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild-role
function Guild.deleteGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.DeleteGuildRoleResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildRole, guildId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-prune-count
function Guild.getGuildPruneCountAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		days: number,
		includeRoles: string,
	}
): future.Future<string, apiTypes.GetGuildPruneCountResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("days", tostring(urlParams.days))
		instance:addUrlParam("include_roles", tostring(urlParams.includeRoles))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildPruneCount, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#begin-guild-prune
function Guild.beginGuildPruneAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BeginGuildPruneRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.BeginGuildPruneResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BeginGuildPrune, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
function Guild.getGuildVoiceRegionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildVoiceRegionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildVoiceRegions, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-invites
function Guild.getGuildInvitesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildInvitesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildInvites, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-integrations
function Guild.getGuildIntegrationsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildIntegrationsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildIntegrations, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild-integration
function Guild.deleteGuildIntegrationAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	integrationId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.DeleteGuildIntegrationResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildIntegration, guildId, integrationId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
function Guild.getGuildWidgetSettingsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildWidgetSettingsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetSettings, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-widget
function Guild.modifyGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildWidgetRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildWidgetResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetSettings, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget
function Guild.getGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildWidgetResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidget, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
function Guild.getGuildVanityURLAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildVanityUrlResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildVanityURL, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-image
function Guild.getGuildWidgetImageAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		style: ("shield" | "banner1" | "banner2" | "banner3" | "banner4")?,
	}
): future.Future<string, apiTypes.GetGuildWidgetImageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("style", urlParams.style :: any)

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetImage, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
function Guild.getGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildWelcomeScreenResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWelcomeScreen, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
function Guild.modifyGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildWelcomeScreenRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildWelcomeScreenResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildWelcomeScreen, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-onboarding
function Guild.getGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildOnboardingResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildOnboarding, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
function Guild.modifyGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildOnboardingRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.GetGuildOnboardingResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildOnboarding, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

return Guild
