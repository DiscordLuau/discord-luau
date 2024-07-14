--> Logger utilized by lune task scripts

local stdio = require("@lune/stdio")

local Logger = {}

type StdioWrapperBaseFn<T> = (T) -> string
type StdioWrapper<T> = {
	-- FIXME: We need to somehow expand T from a union into table keys
	[any]: StdioWrapperBaseFn<string>,
}

local function createStdioWrapper<T>(base: StdioWrapperBaseFn<T>)
	return setmetatable({
		apply = base,
	}, {
		__index = function(self, color: stdio.Color)
			return function(s: string)
				return self.apply(color) .. s .. self.apply("reset")
			end
		end,
	})
end

local color: StdioWrapper<stdio.Color> = createStdioWrapper(stdio.color) :: any
local style: StdioWrapper<stdio.Style> = createStdioWrapper(stdio.style) :: any

function Logger.error(...)
	stdio.ewrite(stdio.format(`[{style.bold(color.red("error"))}]`, ...) .. "\n")
end

function Logger.info(...)
	stdio.write(stdio.format(`[{style.bold(color.green("info"))}]`, ...) .. "\n")
end

return Logger
