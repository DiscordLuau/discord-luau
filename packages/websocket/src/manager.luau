--[=[
	@class WebSocket.Manager
	@__index Prototype

	Manages the connection and communication with the Discord Gateway using multiple shards.

	This serves as the primary class for developers wanting to interact with the Discord Gateway, this class is
	responsible for creating the required shards sending messages asynchronously through each shard.
	
	@external future https://yetanotherclown.github.io/luau-futures/
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local emitter = require("../luau_packages/emitter")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")

local apiTypes = require("../luau_packages/api_types")
local secret = require("../luau_packages/secret")

local shard = require("./shard")

local CONCURRENT_IDENTIFY_YIELD = 5

--[=[
	@prop token Secret 
	@within WebSocket.Manager
]=]

--[=[
	@prop intents number
	@within WebSocket.Manager
]=]

--[=[
	@prop webSocketVersion number
	@within WebSocket.Manager
]=]

--[=[
	@prop largeThreshold number?
	@within WebSocket.Manager
]=]

--[=[
	@prop shouldReconnect boolean
	@within WebSocket.Manager
]=]

--[=[
	@prop ready boolean
	@within WebSocket.Manager
]=]

--[=[
	@prop shardIds { ShardId }
	@within WebSocket.Manager
]=]

--[=[
	@prop shards { [ShardId]: WebSocket.Shard }
	@within WebSocket.Manager
]=]

--[=[
	@prop logger Logger.Logger
	@within WebSocket.Manager
]=]

--[=[
	@prop onDisconnected Emitter<ShardPayload<{ errorCode: number? }>>
	@within WebSocket.Manager
]=]

--[=[
	@prop onReconnected Emitter<ShardPayload<{}>>,
	@within WebSocket.Manager
]=]

--[=[
	@prop onConnected Emitter<ShardPayload<{}>>,
	@within WebSocket.Manager
]=]

--[=[
	@prop onHeartbeat Emitter<ShardPayload<{ latency: number }>>,
	@within WebSocket.Manager
]=]

--[=[
	@prop onDispatch Emitter<ShardPayload<{ shardId: number, event: apiTypes.ReceiveEvent, payload: apiTypes.Payload<unknown> }>>
	@within WebSocket.Manager
]=]

--[=[
	@prop onAllShardsReady Emitter<ShardPayload<{ shardId: number, payload: apiTypes.ReadyPayload }>>
	@within WebSocket.Manager
]=]

--[=[
	@prop onRateLimited Emitter<ShardPayload<{ opcode: number, retryAfter: number, guildId: string? }>>
	@within WebSocket.Manager
]=]

local Manager = {}

Manager.Interface = {}
Manager.Prototype = {}

--[=[
	@within WebSocket.Manager

	Will create, as well as connect all of the shards this application requires in order to communicate
	back and fourth between discords WebSocket
]=]
function Manager.Prototype.connectAsync(
	self: Manager,
	gatewayInformation: apiTypes.GetGatewayBotResponse
): future.FutureLike<string, nil>
	return future.Future.new(function()
		local maxConcurrency = gatewayInformation.session_start_limit.max_concurrency

		local websocketUrl = gatewayInformation.url
		local shardCount = gatewayInformation.shards

		local readyShards = {}

		self.logger:debug(`Creating all Shards required for Manager..`)

		for shardId = 0, shardCount - 1 do
			self.logger:debug(`Creating new Shard '{shardId}'`)

			table.insert(self.shardIds, shardId)
			table.insert(
				self.shards,
				shard.new({
					token = self.token,
					intents = self.intents,
					largeThreshold = self.largeThreshold,
					shouldReconnect = self.shouldReconnect,

					logLevel = self.logger:getLogLevel(),

					shardId = shardId,
					shardCount = shardCount,
				})
			)
		end

		self.logger:debug(`Connecting all Shards to the Discord Gateway..`)

		for shardIndex, shardInstance in next, self.shards do
			local shardId = shardIndex - 1
			if shardId > 0 and shardId % maxConcurrency == 0 then
				stdPolyfills.task.wait(CONCURRENT_IDENTIFY_YIELD)
			end

			shardInstance.onSocketDispatch:listen(function(event)
				self.onDispatch:invoke({
					shardId = shardId,
					event = event.t :: apiTypes.ReceiveEvent,
					payload = event,
				})

				if event.t == apiTypes.gateway.receiveEvents.Ready then
					if not table.find(readyShards, shardId) then
						table.insert(readyShards, shardId)
					end

					if #readyShards == shardCount then
						self.onAllShardsReady:invoke({
							shardId = shardId,
							payload = event :: apiTypes.ReadyPayload,
						})

						self.ready = true
					end
				end
			end)

			shardInstance.onSocketHeartbeat:listen(function(ping: number?)
				self.onHeartbeat:invoke({
					shardId = shardId,
					latency = ping :: number,
				})
			end)

			shardInstance.onSocketConnected:listen(function()
				self.onConnected:invoke({
					shardId = shardId,
				})
			end)

			shardInstance.onSocketReconnected:listen(function()
				self.onReconnected:invoke({
					shardId = shardId,
				})
			end)

			shardInstance.onSocketDisconnected:listen(function(code: number?, closedBySelf: boolean?)
				if closedBySelf then
					return
				end

				self.onDisconnected:invoke({
					shardId = shardId,
					errorCode = code,
				})
			end)

			shardInstance.onSocketRateLimited:listen(function(data)
				self.onRateLimited:invoke({
					shardId = shardId,
					opcode = data.opcode,
					retryAfter = data.retryAfter,
					guildId = data.guildId,
				})
			end)

			self.logger:debug(`Connecting Shard '{shardId}' to Discord Gateway`)

			shardInstance
				:connectAsync(websocketUrl, self.webSocketVersion)
				:after(function(result)
					if result:isErr() then
						self.logger:warn(`shard has run into an error during gateway connection: {result:unwrapErr()}`)
					end
				end)
				:await()
		end
	end)
end

--[=[
	@within WebSocket.Manager

	Will send a message through all shards this Manager is currently responsible for. This message is sent to the
	discord WebSocket.
]=]
function Manager.Prototype.sendAsync<T>(self: Manager, operation: apiTypes.Opcode, data: T)
	return future.Future.new(function()
		local requests = {}

		while not self.ready do
			stdPolyfills.task.wait(0.5)
		end

		for _, shard in self.shards do
			-- fixme: should type this as shard!
			local shardObject = shard :: any

			table.insert(
				requests,
				future.Future.new(function()
					while not shardObject.socketIdentified do
						stdPolyfills.task.wait(0.5)
					end

					local sendResult = shardObject
						:sendAsync(stdPolyfills.serde.encode("json", {
							["op"] = operation,
							["d"] = data,
						}, false))
						:await()
					if sendResult:isErr() then
						self.logger:warn(
							`shard has run into an error during message dispatch: {sendResult:unwrapErr()}`
						)
					end
				end)
			)
		end

		for _, request in requests do
			request:poll()
		end

		for _, request in requests do
			local result = request:await()
			if result:isErr() then
				self.logger:warn(`shard has run into an error during send request: {result:unwrapErr()}`)
			end
		end
	end)
end

--[=[
	@within WebSocket.Manager

	Will instantiate a new Manager class.
]=]
function Manager.Interface.new(settings: {
	token: secret.Secret<string>,
	intents: number,
	largeThreshold: number?,
	webSocketVersion: number,
	reconnect: boolean,
}): Manager
	local self: Manager = setmetatable(
		{
			token = settings.token,
			intents = settings.intents,
			webSocketVersion = settings.webSocketVersion,
			largeThreshold = settings.largeThreshold,
			shouldReconnect = settings.reconnect,
			ready = false,

			shardIds = {} :: { ShardId },
			shards = {} :: { [ShardId]: shard.Shard },

			logger = logger.new("Manager"),

			onDisconnected = emitter.new(),
			onReconnected = emitter.new(),
			onConnected = emitter.new(),
			onHeartbeat = emitter.new(),
			onDispatch = emitter.new(),
			onRateLimited = emitter.new(),

			onAllShardsReady = emitter.new(),
		} :: any,
		{ __index = Manager.Prototype }
	)

	return self
end

export type ShardId = number
export type ShardPayload<DATA> = { shardId: number } & DATA

export type Manager = typeof(Manager.Prototype) & {
	token: secret.Secret<string>,
	intents: number,
	webSocketVersion: number,
	largeThreshold: number?,
	shouldReconnect: boolean,
	ready: boolean,
	shardIds: { ShardId },
	shards: { [ShardId]: shard.Shard },
	logger: logger.Logger,
	onDisconnected: emitter.Emitter<ShardPayload<{ errorCode: number? }>>,
	onReconnected: emitter.Emitter<ShardPayload<{}>>,
	onConnected: emitter.Emitter<ShardPayload<{}>>,
	onHeartbeat: emitter.Emitter<ShardPayload<{ latency: number }>>,
	onDispatch: emitter.Emitter<ShardPayload<{
		shardId: number,
		event: apiTypes.ReceiveEvent,
		payload: apiTypes.Payload<unknown>,
	}>>,
	onRateLimited: emitter.Emitter<ShardPayload<{ opcode: number, retryAfter: number, guildId: string? }>>,
	onAllShardsReady: emitter.Emitter<ShardPayload<{
		shardId: number,
		payload: apiTypes.ReadyPayload,
	}>>,
}

return Manager.Interface
