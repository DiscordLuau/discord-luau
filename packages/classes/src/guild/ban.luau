--[=[
	@class Classes.Ban
	@__index Prototype

	Implementation of the Discord Ban class in Luau

	https://discord.com/developers/docs/resources/guild#ban-object
]=]

local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")
local future = require("../../luau_packages/future")
local rest = require("../../lune_packages/rest")

local user = require("../user")

local Ban = {}

Ban.Interface = {}
Ban.Prototype = {}

--[=[
	@within Classes.Ban
	Remove the ban for a user. Requires the BAN_MEMBERS permissions.
]=]
function Ban.Prototype.removeAsync(self: Ban)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.removeGuildBanAsync(request, self.guildId, self.user.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Ban
	@private

	Responsible for syncing data to this ban object. This is typically called by the API when this object is
	created or updated.
]=]
function Ban.Prototype.sync(self: Ban, banData: apiTypes.BanObject)
	--[=[
		@prop reason string?
		@within Classes.Ban
		
		The reason provided when banning the user. This field may be null if no reason was provided when creating
		the ban.
	]=]
	self.reason = banData.reason

	--[=[
		@prop user Classes.User
		@within Classes.Ban
		
		The banned user object containing information about the user who was banned from the guild.
	]=]
	self.user = user.new(banData.user)
end

--[=[
	@within Classes.Ban
	@private

	Responsible for constructing this class.
]=]
function Ban.Interface.new(state: state.State, guildId: string, banData: apiTypes.BanObject): Ban
	local self = setmetatable(
		{
			--[=[
				@prop state lune.State
				@within Classes.Ban
			]=]
			state = state,

			--[=[
				@prop guildId string
				@within Classes.Ban
			]=]
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
