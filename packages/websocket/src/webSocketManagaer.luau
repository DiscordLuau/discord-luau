local task = require("@std-polyfills/task")

local emitter = require("@vendor/emitter")
local future = require("@vendor/future")
local logger = require("@vendor/logger")

local gatewayTypes = require("@api-types/gateway/types")
local restTypes = require("@api-types/rest/types")

local opcodes = require("@api-types/gateway/opcodes")

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
			table.insert(self.webSocketShards, webSocketShard.new())
		end

		for bucketIndex = 0, shardCount - 1, maxConcurrently do
			for shardId = bucketIndex, bucketIndex + maxConcurrently do
				local webSocketShardInstance = self.webSocketShards[shardId]

				webSocketShardInstance:connectAsync(websocketUrl):await()
			end

			task.wait(CONCURRENT_IDENTIFY_YIELD)
		end

		for shardId = 0, shardCount - 1 do
			local webSocketShardInstance = self.webSocketShards[shardId]

			webSocketShardInstance.onSocketMessage:listen(function(message)
				if message.op == opcodes.Dispatch then
					local _dispatchEvent = message.t :: string

					self.logger:warn(`Handler for shard {message.op} not implemented.`)
				elseif message.op == opcodes.Hello then
					self.logger:warn(`Handler for shard {message.op} not implemented.`)
				elseif message.op == opcodes.Heartbeat then
					self.logger:warn(`Handler for shard {message.op} not implemented.`)
				elseif message.op == opcodes.HeartbeatACK then
					self.logger:warn(`Handler for shard {message.op} not implemented.`)
				elseif message.op == opcodes.Reconnect then
					self.logger:warn(`Handler for shard {message.op} not implemented.`)
				elseif message.op == opcodes.InvalidSession then
					self.logger:warn(`Handler for shard {message.op} not implemented.`)
				end
			end)
		end
	end)
end

function WebSocketManager.Prototype.disconnectAsync(self: WebSocketManager, code: number?) end

function WebSocketManager.Prototype.send() end

function WebSocketManager.Interface.new(settings: {
	token: string,
	intents: number,

	webSocketShards: { [ShardId]: webSocketShard.WebSocketShard },
}): WebSocketManager
	return setmetatable(
		{
			token = settings.token,
			intents = settings.intents,

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

	shardIds: { ShardId },
	webSocketShards: { [ShardId]: webSocketShard.WebSocketShard },

	logger: logger.Logger,

	onHello: emitter.Emitter<()>,
	onResumed: emitter.Emitter<()>,
	onClosed: emitter.Emitter<string>,
	onError: emitter.Emitter<string>,
	onHeartbeat: emitter.Emitter<{ latency: number }>,
	onReady: emitter.Emitter<gatewayTypes.ReadyPayload>,
	onDispatch: emitter.Emitter<gatewayTypes.Payload<unknown>>,
}

return WebSocketManager
