--[=[
	@class Vendor.Connection
]=]

--[=[
	@prop Connected boolean
	@within Vendor.Connection
]=]

--[=[
	@prop _disconnectHandler () -> ()
	@within Vendor.Connection
]=]

local vendorTypes = require("@api-types/vendorTypes")

local Connection = {}

Connection.Prototype = {}
Connection.Interface = {}

--[=[
	Create a new signal Connection.
	
	@method Disconnect
	@within Vendor.Connection
	@return Vendor.Connection
]=]
function Connection.Prototype.Disconnect(self: vendorTypes.Connection)
	if not self.Connected then
		return
	end

	self._disconnectHandler()

	self.Connected = false
end

--[=[
	Create a new signal Connection.
	
	@function new
	@param disconnectHandler () -> ()
	@within Vendor.Connection
	@return Vendor.Connection
]=]
function Connection.Interface.new(disconnectHandler: () -> ()): vendorTypes.Connection
	return setmetatable(
		{
			Connected = true,

			_disconnectHandler = disconnectHandler,
		} :: vendorTypes.Connection,
		{
			__index = Connection.Prototype,
		}
	)
end

return Connection.Interface
