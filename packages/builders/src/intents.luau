--[[
	Implementation of discord intents as a luau builder.	

	https://discord.com/developers/docs/topics/gateway#list-of-intents
]]

local intents = require("@api-types/gateway/intents")

local bit = require("@vendor/bit")

local Intents = {}

Intents.Prototype = {}
Intents.Interface = {}

--[[
	Sets either the id of a guilds custom emoji, or a unicode character of an emoji.
]]
function Intents.Prototype.addIntent(self: Intents, intent: intents.Intent): Intents
	assert(intents[intent], `Invalid intent: {intent}`)
	assert(table.find(self.intents, intent) == nil, `Intent {intent} already set`)

	table.insert(self.intents, intent)

	return self
end

--[[
	Responsible for building all intent permissions into an integer that the Discord API can parse
]]
function Intents.Prototype.build(self: Intents): number
	local intentsValue = 0

	for _, intentEnum in self.intents do
		local intentDisposition = intents[intentEnum]

		assert(intentDisposition, `Unexpected intent '{intentEnum}'`)

		intentsValue += bit.lshift(1, intentDisposition) :: number
	end

	return intentsValue
end

--[[
	Constructs a new intents builder.

	```lua
	Intents.new()
		:addIntent("GuildMembers")
		:addIntent("GuildMessages")
		:build()
	```
]]
function Intents.Interface.new(intents: {}?): Intents
	local self = setmetatable(
		{
			intents = intents or {},
		} :: Intents,
		{ __index = Intents.Prototype }
	)

	return self
end

export type Intents = typeof(Intents.Prototype) & {
	intents: { intents.Intent },
}

return Intents.Interface
