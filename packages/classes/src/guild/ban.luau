--[[
	Implementation of the Discord Ban class in Luau

	https://discord.com/developers/docs/resources/guild#ban-object
]]

local apiTypes = require("../../lune_packages/api_types")

local user = require("../user")

local Ban = {}

Ban.Interface = {}
Ban.Prototype = {}

-- https://discord.com/developers/docs/resources/guild#remove-guild-ban

function Ban.Prototype.sync(self: Ban, banData: apiTypes.BanObject)
	self.reason = banData.reason
	self.user = user.new(banData.user)
end

function Ban.Interface.new(banData: apiTypes.BanObject): Ban
	local self = setmetatable({} :: Ban, { __index = Ban.Prototype })

	self:sync(banData)

	return self
end

export type Ban = typeof(Ban.Prototype) & {
	user: user.User,
	reason: string?,
}

return Ban.Interface
