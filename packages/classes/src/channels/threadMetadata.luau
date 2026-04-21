--[=[
	@class Classes.ThreadMetadata
	@__index Prototype

	Implementation of the Discord ThreadMetadata class in Luau

	https://discord.com/developers/docs/resources/channel#thread-metadata-object
]=]

--[=[
	@prop archiveTimestamp std_polyfills.DateTime
	@within Classes.ThreadMetadata
	
	Timestamp for when the thread's archive status was last changed, used for calculating recent activity
]=]

--[=[
	@prop createTimestamp std_polyfills.DateTime?
	@within Classes.ThreadMetadata
	
	Timestamp for when the thread was created, null if thread was created before October 2021
]=]

--[=[
	@prop archived boolean
	@within Classes.ThreadMetadata
	
	Whether the thread is archived or not
]=]

--[=[
	@prop autoArchiveDuration number
	@within Classes.ThreadMetadata
	
	Duration in minutes to automatically archive the thread after recent activity
]=]

--[=[
	@prop locked boolean
	@within Classes.ThreadMetadata
	
	Whether the thread is locked or not
]=]

--[=[
	@prop invitable boolean?
	@within Classes.ThreadMetadata
	
	Whether non-moderators can add other non-moderators to a private thread
]=]

local apiTypes = require("../../luau_packages/api_types")
local stdPolyfills = require("../../luau_packages/std_polyfills")

local ThreadMetadata = {}

ThreadMetadata.Interface = {}
ThreadMetadata.Prototype = {}

--[=[
	@within Classes.ThreadMetadata
	@private

	Responsible for syncing data to this thread metadata object. This is typically called by the API when this object is
	created or updated.
]=]
function ThreadMetadata.Prototype.sync(self: ThreadMetadata, threadMetadataData: apiTypes.ThreadMetadataObject)
	self.archiveTimestamp = stdPolyfills.datetime.fromIsoDate(threadMetadataData.archive_timestamp)

	self.createTimestamp = threadMetadataData.create_timestamp
		and stdPolyfills.datetime.fromIsoDate(threadMetadataData.create_timestamp)

	self.archived = threadMetadataData.archived

	self.autoArchiveDuration = threadMetadataData.auto_archive_duration

	self.locked = threadMetadataData.locked

	self.invitable = threadMetadataData.invitable
end

--[=[
	@within Classes.ThreadMetadata
	@private

	Responsible for constructing this class.
]=]
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
