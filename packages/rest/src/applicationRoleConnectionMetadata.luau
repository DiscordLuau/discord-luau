local future = require("../luau_packages/future")
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
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("GET")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.GetApplicationRoleConnectionMetadataRecords, applicationId)
				)

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.GetApplicationRoleConnectionMetadataRecordsResponse>
end

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
function ApplicationRoleConnectionMetadata.updateApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("PUT")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.UpdateApplicationRoleConnectionMetadataRecords, applicationId)
				)

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.UpdateApplicationRoleConnectionMetadataRecordsResponse>
end

return ApplicationRoleConnectionMetadata
