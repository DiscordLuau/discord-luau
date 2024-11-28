local frktest = require("../../../lune_packages/frktest")

local emitter = require("../src")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("is able to construct an event emitter instance", function()
		local object = emitter.new()

		check.not_nil(object)
	end)

	test.suite("listening to the event emitter", function()
		test.case("listener is invoked", function()
			local object = emitter.new()
			local variable = 0

			object:listenOnce(function()
				variable += 1
			end)

			object:invoke()

			check.equal(variable, 1)
		end)

		test.case("listener handles multiple invocations", function()
			local object = emitter.new()
			local variable = 0

			local disconnect = object:listen(function()
				variable += 1
			end)

			for _ = 1, 1000 do
				object:invoke()
			end

			disconnect()

			check.equal(variable, 1000)
		end)

		test.case("listener can be disconnected", function()
			local object = emitter.new()
			local variable = 0

			local disconnect = object:listen(function()
				variable += 1
			end)

			object:invoke()

			check.equal(variable, 1)

			disconnect()

			object:invoke()

			check.equal(variable, 1)
		end)

		test.case("listenOnce only stays connected for one invocation", function()
			local object = emitter.new()
			local variable = 0

			object:listenOnce(function()
				variable += 1
			end)

			object:invoke()

			check.equal(variable, 1)

			object:invoke()

			check.equal(variable, 1)
		end)

		test.case("premature disconnection for listenOnce is accepted", function()
			local object = emitter.new()
			local variable = 0

			local disconnect = object:listenOnce(function()
				variable += 1
			end)

			disconnect()

			object:invoke()

			check.equal(variable, 0)
		end)
	end)

	test.case("is able to wait for an event emitter to be invoked", function()
		local object = emitter.new()

		local variable

		coroutine.wrap(function()
			variable = object:wait()
		end)()

		object:invoke("Hello, World!")

		check.equal(variable, "Hello, World!")
	end)

	test.case("is able to invoke an emitter with varadics", function()
		local object = emitter.new()

		local variable

		object:listenOnce(function(a)
			variable = a
		end)

		object:invoke("Hello, World!")

		check.equal(variable, "Hello, World!")
	end)
end
