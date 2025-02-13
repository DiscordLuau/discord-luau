--[[
	Implementation of the Discord ThreadMetadata class in Luau

	https://discord.com/developers/docs/resources/channel#thread-metadata-object
]]

local apiTypes = require("../../lune_packages/api_types")
local stdPolyfills = require("../../lune_packages/std_polyfills")

local ThreadMetadata = {}

ThreadMetadata.Interface = {}
ThreadMetadata.Prototype = {}

function ThreadMetadata.Prototype.sync(self: ThreadMetadata, threadMetadataData: apiTypes.ThreadMetadataObject)
	self.archiveTimestamp = stdPolyfills.datetime.fromIsoDate(threadMetadataData.archive_timestamp)
	self.createTimestamp = threadMetadataData.create_timestamp
		and stdPolyfills.datetime.fromIsoDate(threadMetadataData.create_timestamp)

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
	archiveTimestamp: stdPolyfills.DateTime,
	locked: boolean,
	invitable: boolean?,
	createTimestamp: stdPolyfills.DateTime?,
}

return ThreadMetadata.Interface
