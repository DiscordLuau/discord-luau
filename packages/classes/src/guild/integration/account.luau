--[[
	Implementation of the Discord Integration Account class in Luau

	https://discord.com/developers/docs/resources/guild#integration-account-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local Account = {}

Account.Interface = {}
Account.Prototype = {}

function Account.Prototype.sync(self: Account, accountData: apiTypes.IntegrationAccountObject)
	self.id = accountData.id
	self.name = accountData.name
end

function Account.Interface.new(accountData: apiTypes.IntegrationAccountObject): Account
	local self = setmetatable({} :: Account, { __index = Account.Prototype })

	self:sync(accountData)

	return self
end

export type Account = typeof(Account.Prototype) & {
	id: string,
	name: string,
}

return Account.Interface
