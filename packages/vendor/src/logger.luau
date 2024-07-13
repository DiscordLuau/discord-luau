--[=[
	@class Vendor.Logger
]=]

--[=[
	@prop logUuid string
	@within Vendor.Logger
]=]

local vendorTypes = require("@api-types/vendorTypes")

local Logger = {}

Logger.IsVerbose = true

Logger.Prototype = {}
Logger.Interface = {}

--[=[
	Outputs a message to the console.
	
	@method _out
	@private
	@param message string
	@within Vendor.Logger
]=]
function Logger.Prototype._out(self: vendorTypes.Logger, message: string)
	local logLevel = debug.info(2, "n")

	print(`[{string.upper(self.logUuid)}][{string.upper(logLevel)}]: {message}`)
end

--[=[
	Trace.
	
	@method trace
	@param message string
	@within Vendor.Logger
]=]
function Logger.Prototype.trace(self: vendorTypes.Logger, message: string)
	if not Logger.IsVerbose then
		return
	end

	self:_out(message)
end

--[=[
	Info.
	
	@method info
	@param message string
	@within Vendor.Logger
]=]
function Logger.Prototype.info(self: vendorTypes.Logger, message: string)
	if not Logger.IsVerbose then
		return
	end

	self:_out(message)
end

--[=[
	Warn.
	
	@method warn
	@param message string
	@within Vendor.Logger
]=]
function Logger.Prototype.warn(self: vendorTypes.Logger, message: string)
	if not Logger.IsVerbose then
		return
	end

	self:_out(message)
end

--[=[
	Error.
	
	@method error
	@param message string
	@within Vendor.Logger
]=]
function Logger.Prototype.error(self: vendorTypes.Logger, message: string)
	self:_out(message)

	coroutine.close(coroutine.running())
end

--[=[
	Critical.
	
	@method critical
	@param message string
	@within Vendor.Logger
]=]
function Logger.Prototype.critical(self: vendorTypes.Logger, message: string)
	self:_out(message)

	coroutine.close(coroutine.running())
end

--[=[
	Create a new Logger.
	
	@function new
	@param disconnectHandler () -> ()
	@within Vendor.Logger
	@return Vendor.Logger
]=]
function Logger.Interface.new(logUuid: string): vendorTypes.Logger
	return setmetatable(
		{
			logUuid = logUuid,
		} :: vendorTypes.Logger,
		{
			__index = Logger.Prototype,
		}
	)
end

--[=[
	Sets the verbose flag.
	
	@function setVerbose
	@param isVerbose boolean
	@within Vendor.Logger
]=]
function Logger.Interface.setVerbose(isVerbose: boolean)
	Logger.IsVerbose = isVerbose
end

return Logger.Interface
