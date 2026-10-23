--[=[
	@class DiscordStub.Connection
	@__index Prototype

	One accepted websocket, on the gateway or the voice gateway: where it was dialled, which session it is bound to,
	and every message the client sent on it.
]=]

--[=[
	@prop index number
	@within DiscordStub.Connection
	The connection's place in its server's open order, from 1.
]=]

--[=[
	@prop sessionId string?
	@within DiscordStub.Connection
	The session the server bound this connection to by answering it with READY or RESUMED, or the voice Ready or
	Resumed.
]=]

--[=[
	@prop path string
	@within DiscordStub.Connection
	The upgrade path with one trailing `/` removed: a resume dial records `/resume`, a fresh dial `/`.
]=]

--[=[
	@prop socket HttpWebSocket
	@within DiscordStub.Connection
	The Zune server socket.
]=]

--[=[
	@prop open boolean
	@within DiscordStub.Connection
	False once the server's close callback has run for this connection.
]=]

--[=[
	@prop closeCode number?
	@within DiscordStub.Connection
	The code the server's close callback reported, nil while open.
]=]

--[=[
	@prop received { Received }
	@within DiscordStub.Connection
	Every message the client sent: its opcode, the decoded payload, the raw text or binary buffer, and the world
	clock's time it arrived.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local Connection = {}

Connection.Interface = {}
Connection.Prototype = {}

--[=[
	@within DiscordStub.Connection

	Sends one message as it is, a string as a text frame and a buffer as a binary frame, and returns whether it went.
	Zune throws once the socket is closing, before the server's close callback clears `open`, so a send to a closing
	socket returns false.
]=]
function Connection.Prototype.sendRaw(self: Connection, message: string | buffer): boolean
	local sent = pcall(function()
		self.socket:send(message)
	end)

	return sent
end

--[=[
	@within DiscordStub.Connection

	Sends one payload as JSON text and returns whether it went, as `sendRaw` does.
]=]
function Connection.Prototype.send(self: Connection, payload: Payload): boolean
	return self:sendRaw(stdPolyfills.serde.encode("json", payload))
end

--[=[
	@within DiscordStub.Connection

	Closes the connection with `code` (1000 by default). Closing a socket that is already closing does nothing.
]=]
function Connection.Prototype.close(self: Connection, code: number?)
	pcall(function()
		self.socket:close(code or 1000)
	end)
end

--[=[
	@within DiscordStub.Connection

	Returns the records of every received payload with `opcode`, oldest first.
]=]
function Connection.Prototype.receivedOps(self: Connection, opcode: number): { Received }
	local found = {}

	for _, record in self.received do
		if record.opcode == opcode then
			table.insert(found, record)
		end
	end

	return found
end

--[=[
	@within DiscordStub.Connection

	Returns the connection in `connections` that wraps `socket`, nil when none does.
]=]
function Connection.Interface.find(connections: { Connection }, socket: ZuneSocket): Connection?
	for _, connection in connections do
		if connection.socket == socket then
			return connection
		end
	end

	return
end

--[=[
	@within DiscordStub.Connection

	Wraps a server socket the moment it opens.
]=]
function Connection.Interface.new(settings: { index: number, path: string, socket: ZuneSocket }): Connection
	return setmetatable(
		{
			index = settings.index,
			path = settings.path,
			socket = settings.socket,
			open = true,
			received = {},
		} :: Connection,
		{ __index = Connection.Prototype }
	)
end

type ZuneSocket = HttpWebSocket

export type Payload = {
	op: number,
	t: string?,
	s: number?,
	seq: number?,
	d: any?,
}

export type Received = {
	opcode: number,
	payload: Payload,
	raw: string | buffer,
	at: number,
}

export type Connection = typeof(Connection.Prototype) & {
	index: number,
	sessionId: string?,
	path: string,
	socket: ZuneSocket,
	open: boolean,
	closeCode: number?,
	received: { Received },
}

return Connection.Interface
