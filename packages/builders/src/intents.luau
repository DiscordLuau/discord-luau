--[=[
	@class Builders.Intents
	@__index Prototype

	Implementation of discord intents as a luau builder.	

	https://discord.com/developers/docs/topics/gateway#list-of-intents
]=]

local apiTypes = require("../lune_packages/api_types")

local bit = require("../luau_packages/bit")

local Intents = {}

Intents.Prototype = {}
Intents.Interface = {}

--[=[
	@within Builders.Intents

	Sets either the id of a guilds custom emoji, or a unicode character of an emoji.
]=]
function Intents.Prototype.addIntent(self: Intents, intent: apiTypes.Intent): Intents
	assert(apiTypes.gateway.intents[intent], `Invalid intent: {intent}`)
	assert(table.find(self.intents, intent) == nil, `Intent {intent} already set`)

	table.insert(self.intents, intent)

	return self
end

--[=[
	@within Builders.Intents

	Responsible for building all intent permissions into an integer that the Discord API can parse
]=]
function Intents.Prototype.build(self: Intents): number
	local intentsValue = 0

	for _, intentEnum in self.intents do
		local intentDisposition = apiTypes.gateway.intents[intentEnum]

		assert(intentDisposition, `Unexpected intent '{intentEnum}'`)

		intentsValue += bit.lshift(1, intentDisposition) :: number
	end

	return intentsValue
end

--[=[
	@within Builders.Intents

	Constructs a new intents builder.

	```luau
	Intents.new()
		:addIntent("GuildMembers")
		:addIntent("GuildMessages")
		:build()
	```
]=]
function Intents.Interface.new(intents: {}?): Intents
	local self = setmetatable(
		{
			--[=[
				@prop intents { apiTypes.Intent }
				@within Builders.Intents
				An array of intent flags that determine which gateway events your client will receive.
			]=]
			intents = intents or {},
		} :: Intents,
		{ __index = Intents.Prototype }
	)

	return self
end

export type Intents = typeof(Intents.Prototype) & {
	intents: { apiTypes.Intent },
}

return Intents.Interface
