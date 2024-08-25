--[[
	Implementation of discord intents as a luau builder.	

	https://discord.com/developers/docs/topics/gateway#list-of-intents
]]

local intents = require("@api-types/gateway/intents")

local IntentsBuilder = {}

IntentsBuilder.Prototype = {}
IntentsBuilder.Interface = {}

--[[
	Sets either the id of a guilds custom emoji, or a unicode character of an emoji.
]]
function IntentsBuilder.Prototype.addIntent(self: IntentsBuilder, intent: intents.Intent): IntentsBuilder
	assert(intents[intent], `Invalid intent: {intent}`)
	assert(table.find(self.intents, intent) == nil, `Intent {intent} already set`)

	table.insert(self.intents, intent)

	return self
end

--[[
	Responsible for building all intent permissions into an integer that the Discord API can parse
]]
function IntentsBuilder.Prototype.build(self: IntentsBuilder): number
	local intentsValue = 0

	for _, intentEnum in self.intents do
		local intentDisposition = intents[intentEnum]

		assert(intentDisposition, `Unexpected intent '{intentEnum}'`)

		intentsValue += bit32.lshift(1, intentDisposition)
	end

	return intentsValue
end

--[[
	Constructs a new intents builder.

	```lua
	IntentsBuilder.new()
		:addIntent("GuildMembers")
		:addIntent("GuildMessages")
		:build()
	```
]]
function IntentsBuilder.Interface.new(intents: {}?): IntentsBuilder
	local self = setmetatable(
		{
			intents = intents or {},
		} :: IntentsBuilder,
		{ __index = IntentsBuilder.Prototype }
	)

	return self
end

export type IntentsBuilder = typeof(IntentsBuilder.Prototype) & {
	intents: { intents.Intent },
}

return IntentsBuilder.Interface
