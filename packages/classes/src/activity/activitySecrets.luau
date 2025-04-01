--[=[
	@class Classes.ActivitySecrets
	@__index Prototype

	Implementation of the Discord ActivitySecrets class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-secrets
]=]

local ActivitySecrets = {}

ActivitySecrets.Interface = {}
ActivitySecrets.Prototype = {}

--[=[
	@within Classes.ActivitySecrets
	@private

	Responsible for constructing this class.
]=]
function ActivitySecrets.Interface.new(join: string?, spectate: string?, match: string?): ActivitySecrets
	local self = setmetatable(
		{
			--[=[
				@prop join string?
				@within Classes.ActivitySecrets

				The secret for joining a party
			]=]
			join = join,

			--[=[
				@prop spectate string?
				@within Classes.ActivitySecrets

				The secret for spectating a game
			]=]
			spectate = spectate,

			--[=[
				@prop match string?
				@within Classes.ActivitySecrets

				The secret for a specific instanced match
			]=]
			match = match,
		} :: ActivitySecrets,
		{ __index = ActivitySecrets.Prototype }
	)

	return self
end

export type ActivitySecrets = typeof(ActivitySecrets.Prototype) & {
	join: string?,
	spectate: string?,
	match: string?,
}

return ActivitySecrets.Interface
