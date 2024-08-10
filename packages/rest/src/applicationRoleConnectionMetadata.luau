local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application-role-connection-metadata
]]
local ApplicationRoleConnectionMetadata = {}

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
function ApplicationRoleConnectionMetadata.getApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): future.Future<
	restTypes.GetCurrentApplicationResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetApplicationRoleConnectionMetadataRecords, applicationId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
function ApplicationRoleConnectionMetadata.updateApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): future.Future<
	restTypes.UpdateApplicationRoleConnectionMetadataRecordsResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.UpdateApplicationRoleConnectionMetadataRecords, applicationId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

return ApplicationRoleConnectionMetadata
