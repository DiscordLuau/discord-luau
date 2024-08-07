local task = require("@std-polyfills/task")

local emitter = require("@vendor/emitter")
local future = require("@vendor/future")
local logger = require("@vendor/logger")

local gatewayTypes = require("@api-types/gateway/types")
local restTypes = require("@api-types/rest/types")

local opcodes = require("@api-types/gateway/opcodes")
local receiveEvents = require("@api-types/gateway/receiveEvents")

local webSocketShard = require("@websocket/webSocketShard")

local CONCURRENT_IDENTIFY_YIELD = 5

local WebSocketManager = {}

WebSocketManager.Interface = {}
WebSocketManager.Prototype = {}

function WebSocketManager.Prototype.connectAsync(
	self: WebSocketManager,
	gatewayInformation: restTypes.GetGatewayBotResponse
)
	return future.new(function()
		local maxConcurrently = gatewayInformation.session_start_limit.max_concurrently

		local websocketUrl = gatewayInformation.url
		local shardCount = gatewayInformation.shards

		for shardId = 0, shardCount - 1 do
			table.insert(self.shardIds, shardId)
			table.insert(
				self.webSocketShards,
				webSocketShard.new({
					token = self.token,
					intents = self.intents,
					largeThreshold = self.largeThreshold,

					shardId = shardId,
					shardCount = shardCount,
				})
			)
		end

		for bucketIndex = 0, shardCount - 1, maxConcurrently do
			for shardId = bucketIndex, bucketIndex + maxConcurrently do
				local webSocketShardInstance = self.webSocketShards[shardId]

				webSocketShardInstance:connectAsync(websocketUrl, self.webSocketVersion):await()
			end

			task.wait(CONCURRENT_IDENTIFY_YIELD)
		end

		for shardId = 0, shardCount - 1 do
			local webSocketShardInstance = self.webSocketShards[shardId]

			webSocketShardInstance.onSocketDispatch:listen(function(event, message)
				self.logger:warn(event, message)
			end)
		end
	end)
end

function WebSocketManager.Prototype.send() end

function WebSocketManager.Interface.new(settings: {
	token: string,
	intents: number,
	largeThreshold: number?,

	webSocketShards: { [ShardId]: webSocketShard.WebSocketShard },
	webSocketVersion: number,
}): WebSocketManager
	return setmetatable(
		{
			token = settings.token,
			intents = settings.intents,
			webSocketVersion = settings.webSocketVersion,
			largeThreshold = settings.largeThreshold,

			shardIds = {},
			webSocketShards = {},

			logger = logger.new("WebSocketManager"),

			onHello = emitter.new(),
			onResumed = emitter.new(),
			onClosed = emitter.new(),
			onError = emitter.new(),
			onHeartbeat = emitter.new(),
			onReady = emitter.new(),
			onDispatch = emitter.new(),
		} :: WebSocketManager,
		{ __index = WebSocketManager.Prototype }
	)
end

export type ShardId = number
export type WebSocketManager = typeof(WebSocketManager.Prototype) & {
	token: string,
	intents: number,
	webSocketVersion: number,
	largeThreshold: number?,

	shardIds: { ShardId },
	webSocketShards: { [ShardId]: webSocketShard.WebSocketShard },

	logger: logger.Logger,

	onHello: emitter.Emitter<()>,
	onResumed: emitter.Emitter<()>,
	onClosed: emitter.Emitter<string>,
	onError: emitter.Emitter<string>,
	onHeartbeat: emitter.Emitter<{ latency: number }>,
	onReady: emitter.Emitter<gatewayTypes.ReadyPayload>,
	onDispatch: emitter.Emitter<receiveEvents.ReceiveEvent, gatewayTypes.Payload<unknown>>,
}

return WebSocketManager
