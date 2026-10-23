local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local discordStub = require("../src/init")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.suite("discord_stub testing helpers", function()
		test.case("runScenario returns the scenario's error first, runs the teardown and stops the world", function()
			local originalTask = stdPolyfills.task
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local tornDown = false

			table.insert(ws.handlerErrors, "a handler error")

			local result = stub:runScenario(function()
				error("the scenario failed", 0)
			end, function()
				tornDown = true

				error("the teardown failed", 0)
			end)
			local cleanResult = discordStub.new():runScenario(function() end)

			check.equal(result, "the scenario failed")
			check.is_true(tornDown)
			check.equal(ws.server, nil)
			check.equal(stdPolyfills.task, originalTask)
			check.equal(cleanResult, nil)
		end)

		test.case("runScenario runs the teardown before stop, stops when it throws and returns its error", function()
			local originalTask = stdPolyfills.task
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local serverInTeardown: any

			table.insert(ws.handlerErrors, "a handler error")

			local result = stub:runScenario(function() end, function()
				serverInTeardown = stub.webSocketServer

				error("the teardown failed", 0)
			end)

			check.equal(result, "the teardown failed")
			check.equal(serverInTeardown, ws)
			check.equal(ws.server, nil)
			check.equal(stub.webSocketServer, nil)
			check.equal(stdPolyfills.task, originalTask)
		end)

		test.case("runScenario returns a voice server error after handler errors, then a UDP server error", function()
			local originalTask = stdPolyfills.task
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local voice = stub:createVoiceServer()

			table.insert(voice.errors, "a voice error")
			table.insert(voice.udpServer.errors, "a udp error")

			check.equal(stub:runScenario(function() end), "a voice error")
			check.equal(#ws.handlerErrors, 0)
			check.equal(stub.voiceServer, nil)

			local udpOnlyStub = discordStub.new({ clock = "virtual" })
			local udpOnlyVoice = udpOnlyStub:createVoiceServer()

			table.insert(udpOnlyVoice.udpServer.errors, "the only udp error")

			check.equal(udpOnlyStub:runScenario(function() end), "the only udp error")
			check.equal(udpOnlyStub.udpServer, nil)
			check.equal(stdPolyfills.task, originalTask)
		end)

		test.case("recordEmits records each invoke's arguments in order", function()
			local listeners: { (...any) -> () } = {}
			local emitter = {
				listen = function(_, callback: (...any) -> ())
					table.insert(listeners, callback)
				end,
				invoke = function(_, ...: any)
					for _, listener in listeners do
						listener(...)
					end
				end,
			}
			local emits = discordStub.recordEmits(emitter)

			emitter:invoke(4000, false)
			emitter:invoke(nil, "second")

			check.equal(#emits, 2)
			check.equal(emits[1][1], 4000)
			check.equal(emits[1][2], false)
			check.equal(emits[2][1], nil)
			check.equal(emits[2][2], "second")
		end)
	end)
end
