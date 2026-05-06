local stdPolyfills = require("../luau_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../luau_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.applicationRoleConnectionMetadata

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application-role-connection-metadata
]=]
local applicationRoleConnectionMetadata = {}

--[=[
	@within Rest.applicationRoleConnectionMetadata

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

				assert(response:isOk(), `{response:unwrapErr()}`)

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.GetApplicationRoleConnectionMetadataRecordsResponse>
end

--[=[
	@within Rest.applicationRoleConnectionMetadata

	https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
]=]
function applicationRoleConnectionMetadata.updateApplicationRoleConnectionMetadataRecordsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.UpdateApplicationRoleConnectionMetadataRecordsRequest
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
				instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

				local response = instance:executeAsync():await()

				assert(response:isOk(), `{response:unwrapErr()}`)

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.UpdateApplicationRoleConnectionMetadataRecordsResponse>
end

return applicationRoleConnectionMetadata
