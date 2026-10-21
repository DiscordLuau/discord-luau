local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local discordStub = require("../src/init")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.suite("discord_stub http", function()
		test.case("custom routes answer and unknown routes fall through to 404", function()
			local stub = discordStub.new()
			local http = stub:createHttpServer(function(request)
				if request.method == "GET" and request.path == "/api/v10/ping" then
					return {
						status_code = 200,
						headers = { ["content-type"] = "application/json" },
						body = '{"pong":true}',
					}
				end

				return
			end)
			local response = zune.net.http.request(`{http.url}/api/v10/ping`)

			check.equal(response.status_code, 200)
			check.equal(stdPolyfills.serde.decode("json", response.body).pong, true)

			local missing = zune.net.http.request(`{http.url}/api/v10/missing`)

			check.equal(missing.status_code, 404)

			stub:stop()
		end)

		test.case("gateway/bot is 503 until a websocket server exists", function()
			local stub = discordStub.new()
			local http = stub:createHttpServer()
			local response = zune.net.http.request(`{http.url}/api/v10/gateway/bot`)

			check.equal(response.status_code, 503)

			stub:stop()
		end)

		test.case("a string handler return is the raw body", function()
			local stub = discordStub.new()
			local http = stub:createHttpServer(function()
				return "e"
			end)
			local response = zune.net.http.request(http.url)

			check.equal(response.status_code, 200)
			check.equal(response.body, "e")

			stub:stop()
		end)

		test.case("stopping the handle detaches it from the world", function()
			local stub = discordStub.new()
			local http = stub:createHttpServer()

			http:stop()

			check.equal(stub.httpServer, nil)
			check.equal(stub.restUrl, nil)

			stub:createHttpServer()

			stub:stop()
		end)
	end)
end
