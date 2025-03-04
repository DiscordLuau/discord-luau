local stdPolyfills = require("../lune_packages/std_polyfills")

local emitter = require("../luau_packages/emitter")
local future = require("../luau_packages/future")
local logger = require("../lune_packages/logger")

local apiTypes = require("../lune_packages/api_types")
local secret = require("../luau_packages/secret")

local shard = require("./shard")

local CONCURRENT_IDENTIFY_YIELD = 5

--[=[
	@class Manager
	@__index Prototype

	@external future https://xyz.com/docs

	EXAMPLE MANAGER DOCUMENTATION
]=]

local Manager = {}

Manager.Interface = {}
Manager.Prototype = {}

--[=[
	@within Manager

	EXAMPLE CONNECT ASYNC DOCUMENTATION
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
					token = self.token.value,
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
			if shardIndex ~= 1 and shardIndex % maxConcurrency == 0 then
				stdPolyfills.task.wait(CONCURRENT_IDENTIFY_YIELD)
			end

			self.logger:debug(`Connecting Shard '{shardIndex - 1}' to Discord Gateway`)

			shardInstance:connectAsync(websocketUrl, self.webSocketVersion):await()
			shardInstance.onSocketDispatch:listen(function(event)
				self.onDispatch:invoke({
					shardId = shardIndex - 1,
					event = event.t,
					payload = event,
				})

				if event.t == apiTypes.gateway.receiveEvents.Ready then
					table.insert(readyShards, shardIndex - 1)

					if #readyShards == shardCount then
						self.onAllShardsReady:invoke({
							shardId = shardIndex - 1,
							payload = event,
						})

						self.ready = true
					end
				end
			end)

			shardInstance.onSocketHeartbeat:listen(function(ping: number?)
				self.onHeartbeat:invoke({
					shardId = shardIndex - 1,
					latency = ping,
				})
			end)

			shardInstance.onSocketConnected:listen(function()
				self.onConnected:invoke({
					shardId = shardIndex - 1,
				})
			end)

			shardInstance.onSocketReconnected:listen(function()
				self.onReconnected:invoke({
					shardId = shardIndex - 1,
				})
			end)

			shardInstance.onSocketDisconnected:listen(function(code: number?)
				self.onDisconnected:invoke({
					shardId = shardIndex - 1,
					errorCode = code,
				})
			end)
		end
	end)
end

--[=[
	@within Manager

	EXAMPLE SEND ASYNC DOCUMENTATION
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

			table.insert(requests,  future.Future.new(function()
				while not shardObject.socketIdentified do
					stdPolyfills.task.wait(0.5)
				end
		
				shardObject:sendAsync(stdPolyfills.serde.encode("json", {
					["op"] = operation,
					["d"] = data,
				}, false)):await()
			end))
		end

		for _, request in requests do
			request:poll()
		end

		for _, request in requests do
			request:await()
		end
	end)
end

--[=[
	@within Manager

	EXAMPLE CONNECT ASYNC DOCUMENTATION
]=]
function Manager.Interface.new(settings: {
	token: secret.Secret<string>,
	intents: number,
	largeThreshold: number?,
	webSocketVersion: number,
	reconnect: boolean,
}): Manager
	return setmetatable(
		{
			token = settings.token,
			intents = settings.intents,
			webSocketVersion = settings.webSocketVersion,
			largeThreshold = settings.largeThreshold,
			shouldReconnect = settings.reconnect,
			ready = false,

			shardIds = {},
			shards = {},

			logger = logger.new("Manager"),

			onDisconnected = emitter.new(),
			onReconnected = emitter.new(),
			onConnected = emitter.new(),
			onHeartbeat = emitter.new(),
			onDispatch = emitter.new(),

			onAllShardsReady = emitter.new(),
		} :: Manager,
		{ __index = Manager.Prototype }
	)
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

	onAllShardsReady: emitter.Emitter<ShardPayload<{
		shardId: number,
		payload: apiTypes.ReadyPayload,
	}>>,
}

return Manager.Interface
