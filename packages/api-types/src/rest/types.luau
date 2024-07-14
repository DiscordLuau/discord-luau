--[[
	Mapping out all discord responses that we can get from the Discord v10 REST/HTTP API.
]]

local objects = require("@api-types/objects")

-- [[ Base ]] --

export type Response<DATA> = DATA
export type Request<DATA> = DATA

-- [[ Requests ]] --

-- https://discord.com/developers/docs/resources/application#edit-current-application
export type EditCurrentApplicationRequest = Request<{
	custom_install_url: string, -- Default custom authorization URL for the app, if enabled
	description: string, -- Description of the app
	role_connections_verification_url: string, -- Role connection verification URL for the app
	install_params: objects.InstallParamsObject, -- Settings for the app's default in-app authorization link, if enabled
	integration_types_config: { [objects.IntegrationType]: unknown }, -- In preview. Default scopes and permissions for each supported installation context. Value for each key is an integration type configuration object
	flags: number, -- App's public flags
	icon: string?, -- Icon for the app
	cover_image: string?, -- Default rich presence invite cover image for the app
	interactions_endpoint_url: string, -- Interactions endpoint URL for the app
	tags: { string }, -- List of tags describing the content and functionality of the app (max of 20 characters per tag). Max of 5 tags.
}>

-- [[ Responses ]] --

-- https://discord.com/developers/docs/resources/application#get-current-application
export type GetCurrentApplicationResponse = Response<objects.ApplicationObject>

-- https://discord.com/developers/docs/resources/application#edit-current-application
export type EditCurrentApplicationResponse = Response<objects.ApplicationObject>

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
export type GetApplicationRoleConnectionMetadataRecordsResponse = Response<
	objects.ApplicationRoleConnectionMetadataObject
>

-- https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
export type UpdateApplicationRoleConnectionMetadataRecordsResponse = Response<
	objects.ApplicationRoleConnectionMetadataObject
>

-- https://discord.com/developers/docs/resources/audit-log#get-guild-audit-log
export type GetGuildAuditLogResponse = Response<objects.AuditLogObject>

return "DISCORD_V10_PAYLOAD_TYPES"
