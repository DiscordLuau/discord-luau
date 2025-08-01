local forumMediaThread = require("../../src/thread/forumMedia")
local frktest = require("../../../../lune_packages/frktest")

local ForumMediaThread = forumMediaThread
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("ForumMediaThread builder builds JSON with provided properties", function()
		local thread = ForumMediaThread.new()
		thread
			:setName("test-thread")
			:setAutoArchiveDuration(1440)
			:setRateLimitPerUser(60)
			:addTag("news")
			:setMessage({ content = "Hello, world!" })
		local json = thread:build()

		check.equal(json.name, "test-thread")
		check.equal(json.auto_archive_duration, 1440)
		check.equal(json.rate_limit_per_user, 60)
		check.equal(json.message.content, "Hello, world!")
	end)

	test.case("ForumMediaThread builder errors on invalid thread name", function()
		local thread = ForumMediaThread.new()
		check.should_error(function()
			thread:setName("")

			return
		end)
		check.should_error(function()
			thread:setName(string.rep("a", 101))

			return
		end)
	end)

	test.case("ForumMediaThread builder errors on invalid auto archive duration", function()
		local thread = ForumMediaThread.new()
		check.should_error(function()
			thread:setAutoArchiveDuration(120)

			return
		end)
	end)

	test.case("ForumMediaThread builder errors on invalid rate limit per user", function()
		local thread = ForumMediaThread.new()
		check.should_error(function()
			thread:setRateLimitPerUser(30000)

			return
		end)
	end)

	test.case("ForumMediaThread builder errors when required fields are missing", function()
		-- Case 1: Missing name
		local thread1 = ForumMediaThread.new()
		thread1:setMessage({ content = "Hi" })
		check.should_error(function()
			thread1:build()

			return
		end)

		-- Case 2: Missing message
		local thread2 = ForumMediaThread.new()
		thread2:setName("valid-thread")
		check.should_error(function()
			thread2:build()

			return
		end)
	end)

	test.case("ForumMediaThread builder allows chaining of methods", function()
		local thread = ForumMediaThread.new()
		check.should_not_error(function()
			thread
				:setName("chain-thread")
				:setAutoArchiveDuration(4320)
				:setRateLimitPerUser(30)
				:addTag("updates")
				:setMessage({ content = "Chained message" })
				:build()
			return thread
		end)
	end)
end
