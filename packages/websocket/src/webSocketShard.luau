local net = require("@std-polyfills/net")
local task = require("@std-polyfills/task")
local serde = require("@std-polyfills/serde")

local logger = require("@vendor/logger")
local future = require("@vendor/future")
local buffer = require("@vendor/buffer")
local emitter = require("@vendor/emitter")

local gatewayTypes = require("@api-types/gateway/types")

local ZLIB_HEADER = "\x00\x00\xff\xff"

local WebSocketShard = {}

WebSocketShard.Interface = {}
WebSocketShard.Prototype = {}

function WebSocketShard.Prototype._handleMessage(self: WebSocketShard, message: string)
	self.zlibBuffer:write(message)

	if string.len(message) < 4 or string.sub(message, 1, 4) ~= ZLIB_HEADER then
		self.logger:debug(`Received partial message: #{string.len(message)}`)

		return
	end

	self.logger:debug(`Received complete message: #{string.len(message)}, decompressing...`)

	local compressedData: string = self.zlibBuffer:flush()
	local success0, response0 = pcall(serde.decompress, "zlib" :: any, compressedData)

	if success0 then
		self.logger:debug(`Decompressed WebSocketShard message: #{string.len(response0)}`)

		local success1, response1 = pcall(serde.decode, "json" :: any, response0)

		if success1 then
			self.onSocketMessage:invoke(response1)
		else
			self.logger:error(`Failed to decode WebSocketShard JSON message: {response1}`)
		end
	else
		self.logger:error(`Failed to decompress WebSocketShard ZLIB message: {response0}`)
	end
end

function WebSocketShard.Prototype.disconnectAsync(self: WebSocketShard, code: number?)
	return future.new(function()
		assert(self.socketActive and self.socketInstance, `expected socket to be connected.`)
		assert(self.socketThread, `expected socket thread to be set.`)

		self.logger:debug(`WebSocketShard requesting disconnect: {code or 0}`)

		self.socketInstance.close(code)

		task.cancel(self.socketThread)

		self.socketActive = false
		self.socketInstance = nil

		self.logger:debug(`WebSocketShard disconnected.`)
	end)
end

function WebSocketShard.Prototype.connectAsync(self: WebSocketShard, socketUrl: string)
	return future.new(function()
		assert(not self.socketActive, `WebSocketShard already connected to a socket.`)

		self.logger:debug(`WebSocketShard connecting to: {socketUrl}`)

		local success0, response0 = pcall(net.socket, socketUrl)

		assert(success0, response0)

		self.socketUrl = socketUrl
		self.socketInstance = response0
		self.socketActive = true

		self.logger:debug(`WebSocketShard has connected to: {socketUrl}, starting receive thread.`)

		self.socketThread = task.defer(function()
			self.logger:debug(`Receive thread started, awaiting messages.`)

			while self.socketActive do
				assert(self.socketInstance, `Socket instance is nil.`)

				if self.socketInstance.closeCode then
					self.socketActive = false
					self.socketInstance = nil

					self.logger:warn(`WebSocketShard closed from server: {self.socketInstance.closeCode}`)

					self.onSocketClose:invoke(self.socketInstance.closeCode)
				else
					local success, response = pcall(self.socketInstance.next)

					if success then
						self:_handleMessage(response :: string)
					else
						self.socketActive = false
						self.socketInstance = nil

						self.logger:warn(`WebSocketShard error during receive: {response}`)

						self.onSocketClose:invoke(self.socketInstance.closeCode)
					end
				end
			end

			self.logger:debug(`Socket has disconnected, receive thread stopped.`)
		end)
	end)
end

function WebSocketShard.Prototype.sendAsync(self: WebSocketShard, data: string)
	local debugTraceback = debug.traceback()

	return future.new(function()
		assert(self.socketActive and self.socketInstance, `WebSocketShard not connected to a socket.`)

		self.logger:warn(`Sending WebSocketShard message of length: {string.len(data)}`)

		local success, response: string? = pcall(self.socketInstance.send, data, false)

		if not success then
			self.socketActive = false
			self.socketInstance = nil

			self.logger:warn(`WebSocketShard error during send: {response}\nTraceback: {debugTraceback}`)

			self.onSocketClose:invoke(self.socketInstance.closeCode)
		end
	end)
end

function WebSocketShard.Interface.new(): WebSocketShard
	return setmetatable(
		{
			zlibBuffer = buffer.new(),

			onSocketMessage = emitter.new(),
			onSocketClose = emitter.new(),

			logger = logger.new("WebSocketShard"),

			socketActive = false,
		} :: WebSocketShard,
		{ __index = WebSocketShard.Prototype }
	)
end

export type WebSocketShard = typeof(WebSocketShard.Prototype) & {
	zlibBuffer: buffer.Buffer,

	onSocketMessage: emitter.Emitter<gatewayTypes.Payload<unknown>>,
	onSocketClose: emitter.Emitter<number>,

	logger: logger.Logger,

	socketActive: boolean,

	socketUrl: string?,
	socketInstance: net.WebSocket?,
	socketThread: thread?,
}

return WebSocketShard.Interface
