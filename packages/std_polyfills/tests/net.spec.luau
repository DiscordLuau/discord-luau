local frktest = require("../../../luau_packages/frktest")

local stdPolyfills = require("../src")

local BINARY_FRAME = "{\0\25binary"
local TEXT_FRAME = '{"op":8}'
local NORMAL_CLOSE_CODE = 1000

local test = frktest.test
local check = frktest.assert.check

if stdPolyfills.runtime.getRuntime() ~= "Zune" then
	return function()
		test.skip.suite("Zune WebSocket adapter", function() end)
	end
end

return function()
	test.suite("Zune WebSocket adapter", function()
		test.case("closing a socket after its waiting thread was closed raises nothing", function()
			local result =
				stdPolyfills.process.run("zune", { "run", "packages/std_polyfills/tests/socketTeardown.luau" })
			local output = `{result.stdout}\n{result.stderr}`
			local finishedAt = string.find(output, "socket teardown finished", 1, true)
			local resumeErrorAt = string.find(output, "cannot resume", 1, true)

			check.not_nil(finishedAt)
			check.equal(resumeErrorAt, nil)
		end)

		test.case("a waiting thread closed after a message woke it, but before the wake ran, is not resumed", function()
			local server = zune.net.http.serve({
				port = 0,
				address = "127.0.0.1",
				request = function()
					return { status_code = 404, body = "" }
				end,
				websocket = {
					upgrade = function()
						return true
					end,
					message = function(socket)
						socket:send(TEXT_FRAME)
					end,
				},
			})
			local result = stdPolyfills.process.run(
				"zune",
				{ "run", "packages/std_polyfills/tests/socketWakeRace.luau", tostring(server:getPort()) }
			)
			local output = `{result.stdout}\n{result.stderr}`

			server:stop()

			check.not_nil((string.find(output, "race staged: true", 1, true)))
			check.not_nil((string.find(output, "socket wake race finished", 1, true)))
			check.equal(string.find(output, "cannot resume", 1, true), nil)
		end)

		test.case("nextMessage says which frames were binary, and next still returns only the text", function()
			local server = zune.net.http.serve({
				port = 0,
				address = "127.0.0.1",
				request = function()
					return { status_code = 404, body = "" }
				end,
				websocket = {
					upgrade = function()
						return true
					end,
					open = function(socket)
						socket:send(buffer.fromstring(BINARY_FRAME))
						socket:send(TEXT_FRAME)
						socket:send(TEXT_FRAME)
					end,
				},
			})
			local socket = stdPolyfills.net.tcpSocket(`ws://127.0.0.1:{server:getPort()}`)
			local read, binaryText, binaryFlag, textText, textFlag, plainText = pcall(function()
				local firstText, firstFlag = socket.nextMessage()
				local secondText, secondFlag = socket.nextMessage()

				return firstText, firstFlag, secondText, secondFlag, socket.next()
			end)

			socket.close(NORMAL_CLOSE_CODE)
			server:stop()
			assert(read, binaryText)

			check.equal(binaryText, BINARY_FRAME)
			check.equal(binaryFlag, true)
			check.equal(textText, TEXT_FRAME)
			check.equal(textFlag, false)
			check.equal(plainText, TEXT_FRAME)
		end)
	end)
end
