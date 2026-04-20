return function()
	-- Headers use LF only; content lines carry \r because the source file is CRLF.
	-- Blank context lines are " \r" (space + CR) to match the source file's blank lines.
	-- This exactly mirrors the reference patch in packages/example/patches/.
	local lines = {
		"diff --git a/src/init.luau b/src/init.luau",
		"index 1eaba03..94a8070 100644",
		"--- a/src/init.luau",
		"+++ b/src/init.luau",
		"@@ -1,10 +1,10 @@",
		'-local Poll = require("./Poll")\r',
		'+local Poll = require("@self/Poll")\r',
		" export type Poll<E, U...> = Poll.Poll<E, U...>\r",
		" \r",
		'-local Result = require("./Result")\r',
		'+local Result = require("@self/Result")\r',
		" export type Result<E, U...> = Result.Result<E, U...>\r",
		" \r",
		'-local Future = require("./Future") :: any\r',
		'+local Future = require("@self/Future") :: any\r',
		" \r",
		" -- FUTURE: FutureLike<E, U...> = Future<E, U...> for backwards compatibility\r",
		" -- This type should be used to typecheck function parameters,\\\r",
	}

	return table.concat(lines, "\n") .. "\n"
end
