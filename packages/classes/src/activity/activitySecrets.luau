--[[
	Implementation of the Discord ActivitySecrets class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-secrets
]]

local ActivitySecrets = {}

ActivitySecrets.Interface = {}
ActivitySecrets.Prototype = {}

function ActivitySecrets.Interface.new(join: string?, spectate: string?, match: string?): ActivitySecrets
	local self = setmetatable(
		{
			join = join,
			spectate = spectate,
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
