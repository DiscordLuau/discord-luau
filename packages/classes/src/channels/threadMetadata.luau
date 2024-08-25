--[[
	Implementation of the Discord ThreadMetadata class in Luau

	https://discord.com/developers/docs/resources/channel#thread-metadata-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local ThreadMetadata = {}

ThreadMetadata.Interface = {}
ThreadMetadata.Prototype = {}

function ThreadMetadata.Prototype.sync(self: ThreadMetadata, threadMetadataData: apiTypes.ThreadMetadataObject)
	self.archiveTimestamp = datetime.fromIsoDate(threadMetadataData.archive_timestamp)
	self.createTimestamp = threadMetadataData.create_timestamp
		and datetime.fromIsoDate(threadMetadataData.create_timestamp)

	self.archived = threadMetadataData.archived
	self.autoArchiveDuration = threadMetadataData.auto_archive_duration
	self.locked = threadMetadataData.locked
	self.invitable = threadMetadataData.invitable
end

function ThreadMetadata.Interface.new(threadMetadataData: apiTypes.ThreadMetadataObject): ThreadMetadata
	local self = setmetatable({} :: ThreadMetadata, { __index = ThreadMetadata.Prototype })

	self:sync(threadMetadataData)

	return self
end
export type ThreadMetadata = typeof(ThreadMetadata.Prototype) & {
	archived: boolean,
	autoArchiveDuration: number,
	archiveTimestamp: datetime.DateTime,
	locked: boolean,
	invitable: boolean?,
	createTimestamp: datetime.DateTime?,
}

return ThreadMetadata.Interface
