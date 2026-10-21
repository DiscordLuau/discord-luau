--[=[
	@class DiscordStub.Testing

	Test helpers that need nothing from the library under test.
]=]

local Testing = {}

--[=[
	@within DiscordStub.Testing

	Listens on a discord-luau emitter and returns a list that gains each call's packed arguments, oldest first.
]=]
function Testing.recordEmits(emitter: any): { { any } }
	local emits: { { any } } = {}

	emitter:listen(function(...)
		table.insert(emits, table.pack(...))
	end)

	return emits
end

return Testing
