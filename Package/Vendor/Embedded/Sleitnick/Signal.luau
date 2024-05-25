--!strict

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(Signal, Callback)
	return setmetatable({
		Signal = Signal,
		Callback = Callback,
	}, Connection)
end

function Connection.disconnect(self)
	self.Signal[self] = nil
end

function Signal.new()
	return setmetatable({} :: any, Signal)
end

function Signal.connect(self, Callback)
	local CN = Connection.new(self, Callback)
	self[CN] = true
	return CN
end

function Signal.once(self, Callback)
	local CN
	CN = Connection.new(self, function(...)
		CN:disconnect()
		Callback(...)
	end)
	self[CN] = true
	return CN
end

function Signal.wait(self)
	local waitingCoroutine = coroutine.running()
	local cn
	cn = self:connect(function(...)
		cn:disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

function Signal.disconnectAll(self)
	table.clear(self)
end

function Signal.fire(self, ...)
	if next(self) then
		for CN in pairs(self) do
			CN.Callback(...)
		end
	end
end

export type Connection = {
	disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	fire: (self: Signal<T...>, T...) -> (),
	connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	wait: (self: Signal<T...>) -> T...,
	disconnectAll: (self: Signal<T...>) -> (),
}

return Signal :: { new: () -> Signal<...any> }
