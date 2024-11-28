local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application-role-connection-metadata
]]
local ApplicationRoleConnectionMetadata = {}

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
function ApplicationRoleConnectionMetadata.getApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): async.Async<
	apiTypes.GetCurrentApplicationResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetApplicationRoleConnectionMetadataRecords, applicationId)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
function ApplicationRoleConnectionMetadata.updateApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): async.Async<
	apiTypes.UpdateApplicationRoleConnectionMetadataRecordsResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.UpdateApplicationRoleConnectionMetadataRecords, applicationId)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return ApplicationRoleConnectionMetadata
