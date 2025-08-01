local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.applicationRoleConnectionMetadata

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application-role-connection-metadata
]=]
local applicationRoleConnectionMetadata = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
]=]
function applicationRoleConnectionMetadata.getApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetApplicationRoleConnectionMetadataRecordsResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
]=]
function applicationRoleConnectionMetadata.updateApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.UpdateApplicationRoleConnectionMetadataRecordsResponse
>
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

return applicationRoleConnectionMetadata
