--[=[
	@class Classes.VoiceRegion
	@__index Prototype

	Implementation of the Discord VoiceRegion class in Luau

	https://discord.com/developers/docs/resources/voice#voice-region-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local VoiceRegion = {}

VoiceRegion.Interface = {}
VoiceRegion.Prototype = {}

--[=[
	@within Classes.VoiceRegion
	@private

	Responsible for syncing data to this voice region object. This is typically called by the API when this object is
	created or updated.
]=]
function VoiceRegion.Prototype.sync(self: VoiceRegion, voiceRegionData: apiTypes.VoiceRegionObject)
	--[=[
		@prop id string
		@within Classes.VoiceRegion

		Unique ID for the voice region
	]=]
	self.id = voiceRegionData.id

	--[=[
		@prop name string
		@within Classes.VoiceRegion

		Name of the voice region
	]=]
	self.name = voiceRegionData.name

	--[=[
		@prop optimal boolean
		@within Classes.VoiceRegion

		True if this is an optimal voice region for the current user
	]=]
	self.optimal = voiceRegionData.optimal

	--[=[
		@prop deprecated boolean
		@within Classes.VoiceRegion

		Whether this is a deprecated voice region
	]=]
	self.deprecated = voiceRegionData.deprecated

	--[=[
		@prop custom boolean
		@within Classes.VoiceRegion

		Whether this is a custom voice region (used for events/etc)
	]=]
	self.custom = voiceRegionData.custom
end

--[=[
	@within Classes.VoiceRegion
	@private

	Responsible for constructing this class.
]=]
function VoiceRegion.Interface.new(voiceRegionData: apiTypes.VoiceRegionObject): VoiceRegion
	local self = setmetatable({} :: VoiceRegion, { __index = VoiceRegion.Prototype })

	self:sync(voiceRegionData)

	return self
end

export type VoiceRegion = typeof(VoiceRegion.Prototype) & {
	id: string,
	name: string,
	optimal: boolean,
	deprecated: boolean,
	custom: boolean,
}

return VoiceRegion.Interface
