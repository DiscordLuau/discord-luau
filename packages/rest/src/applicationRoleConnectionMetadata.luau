local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application-role-connection-metadata
]]
local ApplicationRoleConnectionMetadata = {}

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
function ApplicationRoleConnectionMetadata.getApplicationRoleConnectionMetadataRecords(instance: request.Request): future.Future<
	restTypes.GetCurrentApplicationResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.GetApplicationRoleConnectionMetadataRecords)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
function ApplicationRoleConnectionMetadata.updateApplicationRoleConnectionMetadataRecords(instance: request.Request): future.Future<
	restTypes.UpdateApplicationRoleConnectionMetadataRecordsResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(restEndpoints.UpdateApplicationRoleConnectionMetadataRecords)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

return ApplicationRoleConnectionMetadata
