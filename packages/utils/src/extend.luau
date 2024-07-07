--!nocheck

--[[
	Extends class0 with class1
]]

local function failCall(object: any, callType: string)
	error(`Invoked unsupported metamethod '{callType}' on object '{tostring(object)}'`, 3)
end

return function<S, M>(class0: S, class1: M): S & M & { super: M }
	local object

	class0.super = class1

	object = setmetatable({}, {
		__index = function(_, index)
			if class0[index] then
				return class0[index]
			end

			local indexOf = class1[index]

			if type(indexOf) == "function" then
				return function(...)
					local args = { ... }

					if select(1, ...) == object then
						args[1] = class1
					end

					return indexOf(table.unpack(args))
				end
			else
				return indexOf
			end
		end,
		-- __newindex = source,

		__metatable = "This metatable is locked",

		__call = function(self)
			return failCall(self, "Call")
		end,
		__concat = function(self)
			return failCall(self, "Concat")
		end,
		__iter = function(self)
			return failCall(self, "Iter")
		end,

		__unm = function(self)
			return failCall(self, "-.")
		end,
		__add = function(self)
			return failCall(self, "+")
		end,
		__sub = function(self)
			return failCall(self, "-")
		end,
		__mul = function(self)
			return failCall(self, "*")
		end,
		__div = function(self)
			return failCall(self, "/")
		end,
		__idiv = function(self)
			return failCall(self, "//")
		end,
		__mod = function(self)
			return failCall(self, "%")
		end,
		__pow = function(self)
			return failCall(self, "^")
		end,
		__lt = function(self)
			return failCall(self, "<")
		end,
		__le = function(self)
			return failCall(self, "<=")
		end,
		__len = function(self)
			return failCall(self, "#")
		end,

		__mode = "",
		__type = `{class0.type} ({class1.type})`,

		-- __eq = ...
		-- __gc = ...

		__tostring = function()
			return `DiscordLuau<'{`{class0.type} ({class1.type})` or "GenericClass"}'>`
		end,
	})

	return object
end
