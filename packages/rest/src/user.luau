local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/user
]]
local User = {}

-- https://discord.com/developers/docs/resources/user#get-current-user
function User.getCurrentUserAsync(instance: request.Request): future.Future<restTypes.GetCurrentUserResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.GetCurrentUser)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-user
function User.getUserAsync(
	instance: request.Request,
	userId: apiTypes.Snowflake
): future.Future<restTypes.GetUserResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetUser, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#modify-current-user
function User.modifyCurrentUserAsync(
	instance: request.Request,
	jsonParams: restTypes.ModifyCurrentUserRequest
): future.Future<restTypes.ModifyCurrentUserResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(restEndpoints.ModifyCurrentUser)
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#modify-current-user
function User.modifyCurrentUserAsync(
	instance: request.Request,
	jsonParams: restTypes.ModifyCurrentUserRequest
): future.Future<restTypes.ModifyCurrentUserResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(restEndpoints.ModifyCurrentUser)
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-current-user-guilds
function User.getCurrentUserGuildsAsync(
	instance: request.Request,
	urlParams: {
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
		limit: number?,
		withCounts: boolean?,
	}
): future.Future<restTypes.GetCurrentUserGuildsResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.GetCurrentUserGuilds)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-current-user-guild-member
function User.getCurrentUserGuildMember(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetCurrentUserGuildMemberResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetCurrentUserGuilds, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#leave-guild
function User.leaveGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.LeaveGuildResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.GetCurrentUserGuilds, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#create-dm
function User.createDMAsync(
	instance: request.Request,
	jsonParams: restTypes.CreateDMRequest
): future.Future<restTypes.CreateDMResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(restEndpoints.CreateDM)
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#create-group-dm
function User.createGroupDMAsync(
	instance: request.Request,
	jsonParams: restTypes.CreateGroupDMRequest
): future.Future<restTypes.CreateGroupDMResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(restEndpoints.CreateGroupDM)
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-current-user-connections
function User.getCurrentUserConnectionsAsync(
	instance: request.Request
): future.Future<restTypes.GetCurrentUserConnectionResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.GetCurrentUserConnections)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-current-user-application-role-connection
function User.getCurrentUserApplicationRoleConnectionAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): future.Future<
	restTypes.GetCurrentUserApplicationRoleConnectionResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetCurrentUserApplicationRolConnections, applicationId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
function User.updateCurrentUserApplicationRoleConnectionAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: restTypes.UpdateCurrentUserApplicationRoleConnectionRequest
): future.Future<
	restTypes.UpdateCurrentUserApplicationRoleConnectionResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.UpdateCurrentUserApplicationRoleConnection, applicationId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return User
