--[=[
	@class Classes.Guild.Ban
	@__index Prototype

	Implementation of the Discord Ban class in Luau

	https://discord.com/developers/docs/resources/guild#ban-object
]=]

--[=[
	@prop reason string?
	@within Classes.Guild.Ban
	
	The reason provided when banning the user. This field may be null if no reason was provided when creating
	the ban.
]=]

--[=[
	@prop user Classes.User
	@within Classes.Guild.Ban
	
	The banned user object containing information about the user who was banned from the guild.
]=]

--[=[
	@prop state lune.State
	@within Classes.Guild.Ban
]=]

--[=[
	@prop guildId string
	@within Classes.Guild.Ban
]=]

local apiTypes = require("../../luau_packages/api_types")
local state = require("../../luau_packages/state")
local future = require("../../luau_packages/future")
local rest = require("../../luau_packages/rest")

local user = require("../user")

local Ban = {}

Ban.Interface = {}
Ban.Prototype = {}

--[=[
	@within Classes.Guild.Ban
	Remove the ban for a user. Requires the BAN_MEMBERS permissions.
]=]
function Ban.Prototype.removeAsync(self: Ban): future.FutureLike<string, nil>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.removeGuildBanAsync(request, self.guildId, self.user.id):await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Guild.Ban
	@private

	Responsible for syncing data to this ban object. This is typically called by the API when this object is
	created or updated.
]=]
function Ban.Prototype.sync(self: Ban, banData: apiTypes.BanObject): nil
	self.reason = banData.reason

	self.user = user.new(banData.user)
end

--[=[
	@within Classes.Guild.Ban
	@private

	Responsible for constructing this class.
]=]
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
