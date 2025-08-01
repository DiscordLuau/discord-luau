local net = setmetatable({}, { __index = require("@lune/net") })

net.socket = function(...)
	local socket = require("@lune/net").socket(...)
	local value = setmetatable({}, {
		__index = socket,
	})

	function value.next(...: any)
		return socket:next(...)
	end

	function value.close(...: any)
		return socket:close(...)
	end

	function value.send(...: any)
		return socket:send(...)
	end

	return value
end

return net
