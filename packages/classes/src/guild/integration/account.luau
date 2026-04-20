--[=[
	@class Classes.Account
	@__index Prototype

	Implementation of the Discord Integration Account class in Luau

	https://discord.com/developers/docs/resources/guild#integration-account-object
]=]

--[=[
	@prop id string
	@within Classes.Account

	The unique identifier for this integration account
]=]

--[=[
	@prop name string
	@within Classes.Account

	The name of the integration account
]=]

local apiTypes = require("../../../luau_packages/api_types")

local Account = {}

Account.Interface = {}
Account.Prototype = {}

--[=[
	@within Classes.Account
	@private

	Responsible for syncing data to this account object. This is typically called by the API when this object is
	created or updated.
]=]
function Account.Prototype.sync(self: Account, accountData: apiTypes.IntegrationAccountObject)
	self.id = accountData.id

	self.name = accountData.name
end

--[=[
	@within Classes.Account
	@private

	Responsible for constructing this class.
]=]
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
