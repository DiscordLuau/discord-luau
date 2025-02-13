--[[
	Implementation of the Discord VoiceRegion class in Luau

	https://discord.com/developers/docs/resources/voice#voice-region-object
]]

local apiTypes = require("../../lune_packages/api_types")

local VoiceRegion = {}

VoiceRegion.Interface = {}
VoiceRegion.Prototype = {}

function VoiceRegion.Prototype.sync(self: VoiceRegion, voiceRegionData: apiTypes.VoiceRegionObject)
	self.id = voiceRegionData.id
	self.name = voiceRegionData.name
	self.optimal = voiceRegionData.optimal
	self.deprecated = voiceRegionData.deprecated
	self.custom = voiceRegionData.custom
end

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
