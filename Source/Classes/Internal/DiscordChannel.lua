local DiscordChannel = {}

DiscordChannel.Type = "DiscordChannel"

DiscordChannel.Internal = {}
DiscordChannel.Interface = {}
DiscordChannel.Prototype = {
	Internal = DiscordChannel.Internal,
}

function DiscordChannel.Prototype:ToString()
	return `{DiscordChannel.Type}<{self.Id}>`
end

function DiscordChannel.Interface.from()
	return setmetatable({ }, {
		__index = DiscordChannel.Prototype,
		__type = DiscordChannel.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordChannel.Interface
