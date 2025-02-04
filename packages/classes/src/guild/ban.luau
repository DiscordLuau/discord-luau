--[[
	Implementation of the Discord Ban class in Luau

	https://discord.com/developers/docs/resources/guild#ban-object
]]

local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")
local future = require("../../luau_packages/future")
local rest = require("../../lune_packages/rest")

local user = require("../user")

local Ban = {}

Ban.Interface = {}
Ban.Prototype = {}

--[[
	Remove the ban for a user. Requires the BAN_MEMBERS permissions.
]]
function Ban.Prototype.removeAsync(self: Ban)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.removeGuildBanAsync(request, self.guildId, self.user.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return
	end) :: future.FutureLike<string, nil>
end

function Ban.Prototype.sync(self: Ban, banData: apiTypes.BanObject)
	self.reason = banData.reason
	self.user = user.new(banData.user)
end

function Ban.Interface.new(state: state.State, guildId: string, banData: apiTypes.BanObject): Ban
	local self = setmetatable(
		{
			state = state,
			guildId = guildId,
		} :: Ban,
		{ __index = Ban.Prototype }
	)

	self:sync(banData)

	return self
end

export type Ban = typeof(Ban.Prototype) & {
	state: state.State,
	guildId: string,

	user: user.User,
	reason: string?,
}

return Ban.Interface
