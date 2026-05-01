--[=[
	@class Classes.Sound
	@__index Prototype

	Implementation of the Discord SoundboardSound class in Luau

	https://discord.com/developers/docs/resources/soundboard#soundboard-sound-object
]=]

--[=[
	@prop soundId string
	@within Classes.Sound
	The unique identifier for this sound.
]=]

--[=[
	@prop name string
	@within Classes.Sound
	The name of this sound.
]=]

--[=[
	@prop volume number
	@within Classes.Sound
	The volume of this sound, from 0 to 1.
]=]

--[=[
	@prop emojiId string?
	@within Classes.Sound
	The ID of this sound's custom emoji.
]=]

--[=[
	@prop emojiName string?
	@within Classes.Sound
	The unicode character of this sound's standard emoji.
]=]

--[=[
	@prop guildId string?
	@within Classes.Sound
	The ID of the guild this sound is in. Absent for default sounds.
]=]

--[=[
	@prop available boolean
	@within Classes.Sound
	Whether this sound can be used.
]=]

--[=[
	@prop user Classes.User?
	@within Classes.Sound
	The user who created this sound. Not included in list endpoints.
]=]

local apiTypes = require("../../luau_packages/api_types")

local user = require("../user")

local Sound = {}

Sound.Interface = {}
Sound.Prototype = {}

--[=[
	@within Classes.Sound
	@private

	Responsible for syncing data to this sound object.
]=]
function Sound.Prototype.sync(self: Sound, soundData: apiTypes.SoundboardSoundObject)
	self.soundId = soundData.sound_id

	self.name = soundData.name

	self.volume = soundData.volume

	self.emojiId = soundData.emoji_id

	self.emojiName = soundData.emoji_name

	self.guildId = soundData.guild_id

	self.available = soundData.available

	self.user = soundData.user and user.new(soundData.user)
end

--[=[
	@within Classes.Sound
	@private

	Responsible for constructing this class.
]=]
function Sound.Interface.new(soundData: apiTypes.SoundboardSoundObject): Sound
	local self = setmetatable({} :: Sound, { __index = Sound.Prototype })

	self:sync(soundData)

	return self
end

export type Sound = typeof(Sound.Prototype) & {
	soundId: apiTypes.Snowflake,
	name: string,
	volume: number,
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
	guildId: apiTypes.Snowflake?,
	available: boolean,
	user: user.User?,
}

return Sound.Interface
