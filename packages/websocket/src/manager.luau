local task = require("@std-polyfills/task")

local emitter = require("@vendor/emitter")
local future = require("@vendor/future")
local logger = require("@vendor/logger")

local gatewayTypes = require("@api-types/gateway/types")
local restTypes = require("@api-types/rest/types")

local receiveEvents = require("@api-types/gateway/receiveEvents")

local shard = require("@websocket/shard")

local CONCURRENT_IDENTIFY_YIELD = 5

local Manager = {}

Manager.Interface = {}
Manager.Prototype = {}

function Manager.Prototype.connectAsync(self: Manager, gatewayInformation: restTypes.GetGatewayBotResponse)
	return future.new(function()
		local maxConcurrency = gatewayInformation.session_start_limit.max_concurrency

		local websocketUrl = gatewayInformation.url
		local shardCount = gatewayInformation.shards

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

					shardId = shardId,
					shardCount = shardCount,
				})
			)
		end

		self.logger:debug(`Connecting all Shards to the Discord Gateway..`)

		for shardIndex, shardInstance in next, self.shards do
			if shardIndex ~= 1 and shardIndex % maxConcurrency == 0 then
				task.wait(CONCURRENT_IDENTIFY_YIELD)
			end

			self.logger:debug(`Connecting Shard '{shardIndex - 1}' to Discord Gateway`)

			shardInstance:connectAsync(websocketUrl, self.webSocketVersion):await()
			shardInstance.onSocketDispatch:listen(function(event)
				self.onDispatch:invoke({
					shardId = shardIndex - 1,
					event = event.t,
					payload = event,
				})
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

function Manager.Prototype.send() end

function Manager.Interface.new(settings: {
	token: string,
	intents: number,
	largeThreshold: number?,

	webSocketVersion: number,
}): Manager
	return setmetatable(
		{
			token = settings.token,
			intents = settings.intents,
			webSocketVersion = settings.webSocketVersion,
			largeThreshold = settings.largeThreshold,

			shardIds = {},
			shards = {},

			logger = logger.new("Manager"),

			onDisconnected = emitter.new(),
			onReconnected = emitter.new(),
			onConnected = emitter.new(),
			onHeartbeat = emitter.new(),
			onDispatch = emitter.new(),
		} :: Manager,
		{ __index = Manager.Prototype }
	)
end

export type ShardId = number
export type ShardPayload<DATA> = { shardId: number } & DATA

export type Manager = typeof(Manager.Prototype) & {
	token: string,
	intents: number,
	webSocketVersion: number,
	largeThreshold: number?,

	shardIds: { ShardId },
	shards: { [ShardId]: shard.Shard },

	logger: logger.Logger,

	onDisconnected: emitter.Emitter<ShardPayload<{ errorCode: number? }>>,
	onReconnected: emitter.Emitter<ShardPayload<{}>>,
	onConnected: emitter.Emitter<ShardPayload<{}>>,
	onHeartbeat: emitter.Emitter<ShardPayload<{ latency: number }>>,
	onDispatch: emitter.Emitter<ShardPayload<{
		event: receiveEvents.ReceiveEvent,
		payload: gatewayTypes.Payload<unknown>,
	}>>,
}

return Manager.Interface
