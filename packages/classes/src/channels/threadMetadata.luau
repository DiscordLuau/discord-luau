--[=[
	@class Classes.ThreadMetadata
	@__index Prototype

	Implementation of the Discord ThreadMetadata class in Luau

	https://discord.com/developers/docs/resources/channel#thread-metadata-object
]=]

local apiTypes = require("../../lune_packages/api_types")
local stdPolyfills = require("../../lune_packages/std_polyfills")

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
	--[=[
		@prop archiveTimestamp std_polyfills.DateTime
		@within Classes.ThreadMetadata
		
		Timestamp for when the thread's archive status was last changed, used for calculating recent activity
	]=]
	self.archiveTimestamp = stdPolyfills.datetime.fromIsoDate(threadMetadataData.archive_timestamp)

	--[=[
		@prop createTimestamp std_polyfills.DateTime?
		@within Classes.ThreadMetadata
		
		Timestamp for when the thread was created, null if thread was created before October 2021
	]=]
	self.createTimestamp = threadMetadataData.create_timestamp
		and stdPolyfills.datetime.fromIsoDate(threadMetadataData.create_timestamp)

	--[=[
		@prop archived boolean
		@within Classes.ThreadMetadata
		
		Whether the thread is archived or not
	]=]
	self.archived = threadMetadataData.archived

	--[=[
		@prop autoArchiveDuration number
		@within Classes.ThreadMetadata
		
		Duration in minutes to automatically archive the thread after recent activity
	]=]
	self.autoArchiveDuration = threadMetadataData.auto_archive_duration

	--[=[
		@prop locked boolean
		@within Classes.ThreadMetadata
		
		Whether the thread is locked or not
	]=]
	self.locked = threadMetadataData.locked

	--[=[
		@prop invitable boolean?
		@within Classes.ThreadMetadata
		
		Whether non-moderators can add other non-moderators to a private thread
	]=]
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
