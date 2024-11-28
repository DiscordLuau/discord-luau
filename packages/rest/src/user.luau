local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/user
]]
local User = {}

-- https://discord.com/developers/docs/resources/user#get-current-user
function User.getCurrentUserAsync(instance: request.Request): async.Async<apiTypes.GetCurrentUserResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUser)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-user
function User.getUserAsync(instance: request.Request, userId: apiTypes.Snowflake): async.Async<apiTypes.GetUserResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetUser, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#modify-current-user
function User.modifyCurrentUserAsync(
	instance: request.Request,
	jsonParams: apiTypes.ModifyCurrentUserRequest
): async.Async<apiTypes.ModifyCurrentUserResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(apiTypes.rest.endpoints.ModifyCurrentUser)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#modify-current-user
function User.modifyCurrentUserAsync(
	instance: request.Request,
	jsonParams: apiTypes.ModifyCurrentUserRequest
): async.Async<apiTypes.ModifyCurrentUserResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(apiTypes.rest.endpoints.ModifyCurrentUser)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

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
): async.Async<apiTypes.GetCurrentUserGuildsResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUserGuilds)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-current-user-guild-member
function User.getCurrentUserGuildMember(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetCurrentUserGuildMemberResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserGuilds, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#leave-guild
function User.leaveGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.LeaveGuildResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserGuilds, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#create-dm
function User.createDMAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateDMRequest
): async.Async<apiTypes.CreateDMResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateDM)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#create-group-dm
function User.createGroupDMAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateGroupDMRequest
): async.Async<apiTypes.CreateGroupDMResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateGroupDM)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-current-user-connections
function User.getCurrentUserConnectionsAsync(
	instance: request.Request
): async.Async<apiTypes.GetCurrentUserConnectionResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUserConnections)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#get-current-user-application-role-connection
function User.getCurrentUserApplicationRoleConnectionAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): async.Async<
	apiTypes.GetCurrentUserApplicationRoleConnectionResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserApplicationRolConnections, applicationId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
function User.updateCurrentUserApplicationRoleConnectionAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.UpdateCurrentUserApplicationRoleConnectionRequest
): async.Async<
	apiTypes.UpdateCurrentUserApplicationRoleConnectionResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.UpdateCurrentUserApplicationRoleConnection, applicationId)
		)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return User
