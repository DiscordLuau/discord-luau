local future = require("packages/discord_luau/luau_packages/future")
local task = require("@lune/task")

for i = 0, 2 do
	task.spawn(function()
		local r = future.Future
			.new(function()
				task.wait(math.random())
			end)
			:await()

		if r:isOk() then
			print(1)
		else
			warn(r:unwrapErr())
		end

		task.wait(math.random())

		local r = future.Future
			.new(function()
				task.wait(math.random())
			end)
			:await()

		if r:isOk() then
			print(1)
		else
			warn(r:unwrapErr())
		end
	end)
end
