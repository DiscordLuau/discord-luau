local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild
]]
local Guild = {}

-- https://discord.com/developers/docs/resources/guild#create-guild
function Guild.createGuildAsync(
	instance: request.Request,
	jsonParams: restTypes.CreateGuildRequest
): future.Future<restTypes.CreateGuildResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(restEndpoints.CreateGuild)
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

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
): future.Future<restTypes.GetGuildResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuild, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-preview
function Guild.getGuildPreviewAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildPreviewResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildPreview, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild
function Guild.modifyGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuild, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild
function Guild.deleteGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGuild, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-channels
function Guild.getGuildChannelsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildChannelsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildChannels, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-channel
function Guild.createGuildChannelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildChannelRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateGuildChannelResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGuildChannel, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
function Guild.modifyGuildChannelPositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildChannelPositionsRequest
): future.Future<restTypes.ModifyGuildChannelPositionsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildChannelPositions, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#list-active-guild-threads
function Guild.listActiveGuildThreadsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.ListActiveGuildThreadsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListActiveGuildThreads, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-member
function Guild.getGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildMember, guildId, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#list-guild-members
function Guild.listGuildMembersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		limit: number?,
		after: number?,
	}
): future.Future<restTypes.ListGuildMembersResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListGuildMembers, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

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
): future.Future<restTypes.SearchGuildMembersResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("query", urlParams.query)
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.SearchGuildMembers, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#add-guild-member
function Guild.addGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: restTypes.AddGuildMemberRequest
): future.Future<restTypes.AddGuildMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.AddGuildMember, guildId, userId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-member
function Guild.modifyGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildMemberRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildMember, guildId, userId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-current-member
function Guild.modifyCurrentMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyCurrentMemberRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyCurrentMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyCurrentMember, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

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
): future.Future<restTypes.AddGuildMemberRoleResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.AddGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

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
): future.Future<restTypes.RemoveGuildMemberRoleResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.RemoveGuildMemberRole, guildId, userId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-member
function Guild.removeGuildMemberAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.RemoveGuildMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.RemoveGuildMember, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

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
): future.Future<restTypes.GetGuildBansResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildBans, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-ban
function Guild.getGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildBanResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildBan, guildId, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-ban
function Guild.createGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildBanRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateGuildBanResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.CreateGuildBan, guildId, userId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#remove-guild-ban
function Guild.removeGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.RemoveGuildBanResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.RemoveGuildBan, guildId, userId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#bulk-guild-ban
function Guild.bulkGuildBanAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.BulkGuildBanRequest,
	auditLogReason: string?
): future.Future<restTypes.BulkGuildBanResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.BulkGuildBan, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-roles
function Guild.getGuildRolesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildRolesResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildRoles, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#create-guild-role
function Guild.createGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildRoleRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateGuildRoleResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGuildRole, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
function Guild.modifyGuildRolePositionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildRolePositionsRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildRolePositionsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildRolePositions, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-role
function Guild.modifyGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildRoleRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildRoleResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildRole, guildId, roleId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
function Guild.modifyGuildMFALevelAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildMFALevelRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildMFALevelResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.ModifyGuildMFALevel, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild-role
function Guild.deleteGuildRoleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	roleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.DeleteGuildRoleResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.DeleteGuildRole, guildId, roleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

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
): future.Future<restTypes.GetGuildPruneCountResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("days", tostring(urlParams.days))
		instance:addUrlParam("includeRoles", tostring(urlParams.includeRoles))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildPruneCount, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#begin-guild-prune
function Guild.beginGuildPruneAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.BeginGuildPruneRequest,
	auditLogReason: string?
): future.Future<restTypes.BeginGuildPruneResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.BeginGuildPrune, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
function Guild.getGuildVoiceRegionsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildVoiceRegionsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildVoiceRegions, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-invites
function Guild.getGuildInvitesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildInvitesResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildInvites, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-integrations
function Guild.getGuildIntegrationsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildIntegrationsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildIntegrations, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#delete-guild-integration
function Guild.deleteGuildIntegrationAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	integrationId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.DeleteGuildIntegrationResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGuildIntegration, guildId, integrationId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
function Guild.getGuildWidgetSettingsAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildWidgetSettingsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildWidgetSettings, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-widget
function Guild.modifyGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildWidgetRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildWidgetResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.GetGuildWidgetSettings, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-widget
function Guild.getGuildWidgetAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildWidgetResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildWidget, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
function Guild.getGuildVanityURLAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildVanityUrlResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildVanityURL, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

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
): future.Future<restTypes.GetGuildWidgetImageResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("style", urlParams.style :: any)

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildWidgetImage, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
function Guild.getGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildWidgetImageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildWelcomeScreen, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
function Guild.modifyGuildWelcomeScreenAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildWelcomeScreenRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildWelcomeScreenResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildWelcomeScreen, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#get-guild-onboarding
function Guild.getGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildOnboardingResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.GetGuildOnboarding, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
function Guild.modifyGuildOnboardingAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildOnboardingRequest,
	auditLogReason: string?
): future.Future<restTypes.GetGuildOnboardingResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.ModifyGuildOnboarding, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

return Guild
