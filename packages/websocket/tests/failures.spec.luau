local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local apiTypes = require("../luau_packages/api_types")

local websocket = require("../src")

local SOCKET_VERSION = 10
local REFUSED_UPGRADES = 1000

local test = frktest.test
local check = frktest.assert.check
local opcodes = apiTypes.gateway.opcodes

local function newShard(): websocket.Shard
	return websocket.shard.new({
		token = secret.new("stub-token"),
		intents = 0,
		shardId = 0,
		shardCount = 1,
		shouldReconnect = false,
		logLevel = "Warn",
	})
end

return function()
	test.suite("Gateway failures are surfaced", function()
		test.case("a message handler that raises does not stop the receive loop", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local shard = newShard()
			local handled = 0
			local original = shard.handleMessage

			shard.handleMessage = function(self: websocket.Shard, message: string)
				handled += 1

				if handled == 1 then
					error("handler exploded")
				end

				original(self, message)
			end

			local function scenario()
				shard:connectAsync(server.url, SOCKET_VERSION):await()

				check.is_true(stub.clock:waitFor(function()
					return handled >= 1
				end, 30))
				local connection = server:latestConnection()

				assert(connection, "the stub holds no connection")

				connection:send({ op = opcodes.Dispatch, t = "STUB_EVENT", s = 7, d = {} })

				check.is_true(stub.clock:waitFor(function()
					return shard.lastSequence == 7
				end, 30))
				check.is_true(shard.socketActive)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("a heartbeat that cannot be sent resolves Err", function()
			local shard = newShard()
			local outcome = shard:heartbeatAsync(true):await()

			check.is_true(outcome:isErr())
		end)

		test.case("a Hello on a socket that cannot send marks the socket inactive and sends no heartbeat", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local shard = newShard()
			local sent = 0

			shard.heartbeatJitter = function()
				return 0
			end
			shard.socketActive = true
			shard.sessionId = "stub-session"
			shard.socketInstance = {
				send = function()
					sent += 1

					error("socket is closed")
				end,
				close = function() end,
			}

			local function scenario()
				shard.onSocketRawMessage:invoke({ op = opcodes.Hello, d = { heartbeat_interval = 41250 } } :: any)

				stub.clock:wait(1)

				check.equal(sent, 1)
				check.is_false(shard.socketActive)
			end

			check.equal(
				stub:runScenario(scenario, function()
					shard:forceClose()
				end),
				nil
			)
		end)

		test.case("an identify that cannot be sent resolves Err", function()
			local shard = newShard()
			local outcome = shard:identifyAsync():await()

			check.is_true(outcome:isErr())
		end)

		test.case("a manager whose shards all fail to connect resolves Err", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local manager = websocket.manager.new({
				token = secret.new("stub-token"),
				intents = 0,
				webSocketVersion = SOCKET_VERSION,
				reconnect = false,
			})

			manager.logger:setLogLevel("Warn")
			server.refuseUpgrades = REFUSED_UPGRADES

			local function scenario()
				local resolved = false
				local failed = false

				stdPolyfills.task.spawn(function()
					failed = manager
						:connectAsync({
							url = server.url,
							shards = 1,
							session_start_limit = {
								total = 1000,
								remaining = 1000,
								reset_after = 0,
								max_concurrency = 1,
							},
						})
						:await()
						:isErr()
					resolved = true
				end)

				check.is_true(stub.clock:waitFor(function()
					return resolved
				end, 30))
				check.is_true(failed)
				check.equal(#server:receivedOps(opcodes.Identify), 0)
			end

			check.equal(stub:runScenario(scenario), nil)
		end)
	end)
end
