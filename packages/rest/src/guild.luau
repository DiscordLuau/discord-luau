local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
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
): async.Async<apiTypes.CreateGuildResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateGuild)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild
function Guild.getGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withCounts: boolean?,
	}
): async.Async<apiTypes.GetGuildResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuild, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-preview
function Guild.getGuildPreviewAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildPreviewResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildPreview, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild
function Guild.modifyGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuild, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild
function Guild.deleteGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.DeleteGuildResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuild, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-channels
function Guild.getGuildChannelsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildChannelsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildChannels, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-channel
function Guild.createGuildChannelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildChannelRequest,
	auditLogReason: string?
): async.Async<apiTypes.CreateGuildChannelResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildChannel, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
function Guild.modifyGuildChannelPositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildChannelPositionsRequest
): async.Async<apiTypes.ModifyGuildChannelPositionsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildChannelPositions, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#list-active-guild-threads
function Guild.listActiveGuildThreadsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.ListActiveGuildThreadsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListActiveGuildThreads, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-member
function Guild.getGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildMemberResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildMember, guildId, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
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
): async.Async<apiTypes.ListGuildMembersResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildMembers, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
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
): async.Async<apiTypes.SearchGuildMembersResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("query", urlParams.query)
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.SearchGuildMembers, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#add-guild-member
function Guild.addGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.AddGuildMemberRequest
): async.Async<apiTypes.AddGuildMemberResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddGuildMember, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-member
function Guild.modifyGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildMemberRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildMemberResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildMember, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-current-member
function Guild.modifyCurrentMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyCurrentMemberRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyCurrentMemberResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyCurrentMember, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#add-guild-member-role
function Guild.addGuildMemberRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.AddGuildMemberRoleResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.AddGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-member-role
function Guild.removeGuildMemberRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.RemoveGuildMemberRoleResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-member
function Guild.removeGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.RemoveGuildMemberResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildMember, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
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
): async.Async<apiTypes.GetGuildBansResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildBans, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-ban
function Guild.getGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildBanResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildBan, guildId, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-ban
function Guild.createGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildBanRequest,
	auditLogReason: string?
): async.Async<apiTypes.CreateGuildBanResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildBan, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-ban
function Guild.removeGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.RemoveGuildBanResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.RemoveGuildBan, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#bulk-guild-ban
function Guild.bulkGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkGuildBanRequest,
	auditLogReason: string?
): async.Async<apiTypes.BulkGuildBanResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BulkGuildBan, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-roles
function Guild.getGuildRolesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildRolesResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildRoles, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-role
function Guild.getGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildRoleResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildRole, guildId, roleId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-role
function Guild.createGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildRoleRequest,
	auditLogReason: string?
): async.Async<apiTypes.CreateGuildRoleResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildRole, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
function Guild.modifyGuildRolePositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRolePositionsRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildRolePositionsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildRolePositions, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-role
function Guild.modifyGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildRoleRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildRoleResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildRole, guildId, roleId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
function Guild.modifyGuildMFALevelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildMFALevelRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildMFALevelResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildMFALevel, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild-role
function Guild.deleteGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.DeleteGuildRoleResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildRole, guildId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
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
): async.Async<apiTypes.GetGuildPruneCountResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("days", tostring(urlParams.days))
		instance:addUrlParam("include_roles", tostring(urlParams.includeRoles))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildPruneCount, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#begin-guild-prune
function Guild.beginGuildPruneAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BeginGuildPruneRequest,
	auditLogReason: string?
): async.Async<apiTypes.BeginGuildPruneResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BeginGuildPrune, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
function Guild.getGuildVoiceRegionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildVoiceRegionsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildVoiceRegions, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-invites
function Guild.getGuildInvitesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildInvitesResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildInvites, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-integrations
function Guild.getGuildIntegrationsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildIntegrationsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildIntegrations, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild-integration
function Guild.deleteGuildIntegrationAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	integrationId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.DeleteGuildIntegrationResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildIntegration, guildId, integrationId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
function Guild.getGuildWidgetSettingsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildWidgetSettingsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetSettings, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-widget
function Guild.modifyGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildWidgetRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildWidgetResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetSettings, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget
function Guild.getGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildWidgetResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidget, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
function Guild.getGuildVanityURLAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildVanityUrlResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildVanityURL, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-image
function Guild.getGuildWidgetImageAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		style: ("shield" | "banner1" | "banner2" | "banner3" | "banner4")?,
	}
): async.Async<apiTypes.GetGuildWidgetImageResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("style", urlParams.style :: any)

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWidgetImage, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
function Guild.getGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildWelcomeScreenResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWelcomeScreen, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
function Guild.modifyGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildWelcomeScreenRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildWelcomeScreenResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildWelcomeScreen, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-onboarding
function Guild.getGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildOnboardingResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildOnboarding, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
function Guild.modifyGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildOnboardingRequest,
	auditLogReason: string?
): async.Async<apiTypes.GetGuildOnboardingResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildOnboarding, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Guild
