--[[
	REST represents an interface to manipulate the Discord REST API.

	When making any sort of REST request, it is important that this class is used so that we accurately
	track the rate limits, as well as adding token into each request object.
]]

local secret = require("../luau_packages/secret")
local rest = require("../lune_packages/rest")

local REST = {}

REST.Interface = {}
REST.Prototype = {}

--[[
	Responsible for creating a new request object, this object can be used with any of the
	@rest/* api endpoints.
]]
function REST.Prototype.newRequest(self: REST): rest.Request
	local newRequest = rest.request.new({
		token = self.token.value,
		restApiVersion = self.version,
	})

	return newRequest
end

--[[
	Constructor for the REST class.
]]
function REST.Interface.new(token: secret.Secret<string>, intents: number, version: number): REST
	local self = setmetatable(
		{
			token = token,

			intents = intents,
			version = version,
		} :: REST,
		{
			__index = REST.Prototype,
		}
	)

	return self
end

export type REST = typeof(REST.Prototype) & {
	token: secret.Secret<string>,

	intents: number,
	version: number,
}

return REST.Interface
