local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/user
]]
local User = {}

-- https://discord.com/developers/docs/resources/user#get-current-user
function User.getCurrentUserAsync(instance: request.Request)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUser)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserResponse>
end

-- https://discord.com/developers/docs/resources/user#get-user
function User.getUserAsync(instance: request.Request, userId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetUser, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetUserResponse>
end

-- https://discord.com/developers/docs/resources/user#modify-current-user
function User.modifyCurrentUserAsync(instance: request.Request, jsonParams: apiTypes.ModifyCurrentUserRequest)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(apiTypes.rest.endpoints.ModifyCurrentUser)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyCurrentUserResponse>
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
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUserGuilds)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserGuildsResponse>
end

-- https://discord.com/developers/docs/resources/user#get-current-user-guild-member
function User.getCurrentUserGuildMember(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserGuilds, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserGuildMemberResponse>
end

-- https://discord.com/developers/docs/resources/user#leave-guild
function User.leaveGuildAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserGuilds, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.LeaveGuildResponse>
end

-- https://discord.com/developers/docs/resources/user#create-dm
function User.createDMAsync(instance: request.Request, jsonParams: apiTypes.CreateDMRequest)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateDM)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateDMResponse>
end

-- https://discord.com/developers/docs/resources/user#create-group-dm
function User.createGroupDMAsync(instance: request.Request, jsonParams: apiTypes.CreateGroupDMRequest)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateGroupDM)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGroupDMResponse>
end

-- https://discord.com/developers/docs/resources/user#get-current-user-connections
function User.getCurrentUserConnectionsAsync(instance: request.Request)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUserConnections)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserConnectionResponse>
end

-- https://discord.com/developers/docs/resources/user#get-current-user-application-role-connection
function User.getCurrentUserApplicationRoleConnectionAsync(instance: request.Request, applicationId: apiTypes.Snowflake)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("GET")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.GetCurrentUserApplicationRolConnections, applicationId)
				)

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.GetCurrentUserApplicationRoleConnectionResponse>
end

-- https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
function User.updateCurrentUserApplicationRoleConnectionAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.UpdateCurrentUserApplicationRoleConnectionRequest
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("PUT")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.UpdateCurrentUserApplicationRoleConnection, applicationId)
				)
				instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.UpdateCurrentUserApplicationRoleConnectionResponse>
end

return User
