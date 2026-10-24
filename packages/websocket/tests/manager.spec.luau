local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local apiTypes = require("../luau_packages/api_types")

local websocket = require("../src")

local SOCKET_VERSION = 10

local test = frktest.test
local check = frktest.assert.check
local opcodes = apiTypes.gateway.opcodes

local function newManager(): websocket.Manager
	local manager = websocket.manager.new({
		token = secret.new("stub-token"),
		intents = 0,
		webSocketVersion = SOCKET_VERSION,
		reconnect = true,
	})

	manager.logger:setLogLevel("Warn")

	return manager
end

local function connectManager(stub: discordStub.DiscordStub, manager: websocket.Manager, url: string): boolean
	manager
		:connectAsync({
			url = url,
			shards = 1,
			session_start_limit = { total = 1000, remaining = 1000, reset_after = 0, max_concurrency = 1 },
		})
		:await()

	return stub.clock:waitFor(function()
		return manager.ready
	end, 30)
end

local function sendPresence(manager: websocket.Manager): { resolved: boolean, ok: boolean }
	local request = { resolved = false, ok = false }

	stdPolyfills.task.spawn(function()
		local sent = manager:sendAsync(opcodes.PresenceUpdate, { status = "online" }):await()

		request.ok = sent:isOk()
		request.resolved = true
	end)

	return request
end

local function forceCloseShards(manager: websocket.Manager)
	-- the old type solver mistypes a shard taken by iterating `shards`, so each one is indexed by its id
	for shardId in manager.shards do
		manager.shards[shardId]:forceClose()
	end
end

return function()
	test.suite("Manager sends across a reconnect", function()
		test.case("12a. a send during a reconnect goes out on the new socket after its op 6", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local manager = newManager()

			local function scenario()
				check.is_true(connectManager(stub, manager, server.url))

				local shard = manager.shards[1]
				local firstConnection = server.connections[1]

				-- auth goes out on Hello whatever the jitter; the 5 s upgrade hold keeps socketIdentified false long enough for a poll to see it
				server.upgradeDelaySeconds = 5
				firstConnection:send({ op = opcodes.Reconnect })

				check.is_true(stub.clock:waitFor(function()
					return not shard.socketIdentified
				end, 30))

				local request = sendPresence(manager)

				check.is_true(stub.clock:waitFor(function()
					return request.resolved
				end, 120))
				check.is_true(request.ok)

				local resumeConnection = assert(server.connections[2], "the server saw no second connection")

				check.is_true(stub.clock:waitFor(function()
					return #resumeConnection:receivedOps(opcodes.PresenceUpdate) >= 1
				end, 30))

				local presences = resumeConnection:receivedOps(opcodes.PresenceUpdate)
				local resumes = resumeConnection:receivedOps(opcodes.Resume)

				check.equal(#firstConnection:receivedOps(opcodes.PresenceUpdate), 0)
				check.equal(#presences, 1)
				check.equal(#resumes, 1)

				if presences[1] and resumes[1] then
					check.greater_eq(presences[1].at, resumes[1].at)
				end
			end

			check.equal(
				stub:runScenario(scenario, function()
					forceCloseShards(manager)
				end),
				nil
			)
		end)

		test.case("12b. a send to a shard closed with forceClose resolves without sending", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local manager = newManager()

			local function scenario()
				check.is_true(connectManager(stub, manager, server.url))

				local shard = manager.shards[1]
				local presenceCount = #server:receivedOps(opcodes.PresenceUpdate)

				shard:forceClose()

				local request = sendPresence(manager)

				check.is_true(stub.clock:waitFor(function()
					return request.resolved
				end, 2))

				stub.clock:wait(5)

				check.equal(#server:receivedOps(opcodes.PresenceUpdate), presenceCount)
			end

			check.equal(
				stub:runScenario(scenario, function()
					forceCloseShards(manager)
				end),
				nil
			)
		end)

		test.case("12c. a send to a shard whose connectAsync failed resolves without sending", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local server = stub:createWebsocketServer()
			local manager = newManager()

			local function scenario()
				check.is_true(connectManager(stub, manager, server.url))

				local shard = manager.shards[1]

				shard:forceClose()
				server.refuseUpgrades = 1
				shard:connectAsync(server.url, SOCKET_VERSION):await()

				local request = sendPresence(manager)

				check.is_true(stub.clock:waitFor(function()
					return request.resolved
				end, 2))
				check.is_false(shard.socketActive)
			end

			check.equal(
				stub:runScenario(scenario, function()
					forceCloseShards(manager)
				end),
				nil
			)
		end)
	end)
end
