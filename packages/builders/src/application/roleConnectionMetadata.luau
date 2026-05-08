--[=[
	@class Builders.ApplicationRoleConnectionMetadata
	@__index Prototype

	Implementation of Discord's Application Role Connection Metadata object as a Luau builder.

	https://discord.com/developers/docs/resources/application-role-connection-metadata#application-role-connection-metadata-object
]=]

local apiTypes = require("../../luau_packages/api_types")

local ApplicationRoleConnectionMetadata = {}

ApplicationRoleConnectionMetadata.Prototype = {}
ApplicationRoleConnectionMetadata.Interface = {}

function ApplicationRoleConnectionMetadata.Prototype.setType(
	self: ApplicationRoleConnectionMetadata,
	metadataType: apiTypes.ApplicationRoleConnectionMetadataType
): ApplicationRoleConnectionMetadata
	assert(apiTypes.application.ApplicationRoleConnectionMetadataType[metadataType], "Invalid metadata type")
	self.metadataType = metadataType
	return self
end

function ApplicationRoleConnectionMetadata.Prototype.setKey(
	self: ApplicationRoleConnectionMetadata,
	key: string
): ApplicationRoleConnectionMetadata
	assert(#key >= 1 and #key <= 50, "Key must be between 1 and 50 characters")
	assert(string.match(key, "^[a-z0-9_]+$"), "Key must only contain lowercase letters, numbers, and underscores")
	self.key = key
	return self
end

function ApplicationRoleConnectionMetadata.Prototype.setName(
	self: ApplicationRoleConnectionMetadata,
	name: string
): ApplicationRoleConnectionMetadata
	assert(#name >= 1 and #name <= 100, "Name must be between 1 and 100 characters")
	self.name = name
	return self
end

function ApplicationRoleConnectionMetadata.Prototype.setDescription(
	self: ApplicationRoleConnectionMetadata,
	description: string
): ApplicationRoleConnectionMetadata
	assert(#description >= 1 and #description <= 200, "Description must be between 1 and 200 characters")
	self.description = description
	return self
end

function ApplicationRoleConnectionMetadata.Prototype.setNameLocalizations(
	self: ApplicationRoleConnectionMetadata,
	localizations: { [string]: string }
): ApplicationRoleConnectionMetadata
	self.nameLocalizations = localizations
	return self
end

function ApplicationRoleConnectionMetadata.Prototype.setDescriptionLocalizations(
	self: ApplicationRoleConnectionMetadata,
	localizations: { [string]: string }
): ApplicationRoleConnectionMetadata
	self.descriptionLocalizations = localizations
	return self
end

function ApplicationRoleConnectionMetadata.Prototype.build(self: ApplicationRoleConnectionMetadata): JSON
	assert(self.metadataType, "ApplicationRoleConnectionMetadata is missing a type")
	assert(self.key, "ApplicationRoleConnectionMetadata is missing a key")
	assert(self.name, "ApplicationRoleConnectionMetadata is missing a name")
	assert(self.description, "ApplicationRoleConnectionMetadata is missing a description")

	return {
		type = apiTypes.application.ApplicationRoleConnectionMetadataType[self.metadataType],
		key = self.key,
		name = self.name,
		description = self.description,
		name_localizations = self.nameLocalizations,
		description_localizations = self.descriptionLocalizations,
	}
end

function ApplicationRoleConnectionMetadata.Interface.new(resource: {
	metadataType: apiTypes.ApplicationRoleConnectionMetadataType?,
	key: string?,
	name: string?,
	description: string?,
	nameLocalizations: { [string]: string }?,
	descriptionLocalizations: { [string]: string }?,
}?): ApplicationRoleConnectionMetadata
	local self = setmetatable(
		{} :: ApplicationRoleConnectionMetadata,
		{ __index = ApplicationRoleConnectionMetadata.Prototype }
	)

	if resource then
		if resource.metadataType then
			self:setType(resource.metadataType)
		end
		if resource.key then
			self:setKey(resource.key)
		end
		if resource.name then
			self:setName(resource.name)
		end
		if resource.description then
			self:setDescription(resource.description)
		end
		if resource.nameLocalizations then
			self:setNameLocalizations(resource.nameLocalizations)
		end
		if resource.descriptionLocalizations then
			self:setDescriptionLocalizations(resource.descriptionLocalizations)
		end
	end

	return self
end

export type ApplicationRoleConnectionMetadata = typeof(ApplicationRoleConnectionMetadata.Prototype) & {
	metadataType: apiTypes.ApplicationRoleConnectionMetadataType?,
	key: string?,
	name: string?,
	description: string?,
	nameLocalizations: { [string]: string }?,
	descriptionLocalizations: { [string]: string }?,
}

export type JSON = typeof(ApplicationRoleConnectionMetadata.Prototype.build(nil :: any))

return ApplicationRoleConnectionMetadata.Interface
