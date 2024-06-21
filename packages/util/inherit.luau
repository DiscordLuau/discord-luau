--!nocheck

--[[
	Inherit the prototype of another class, into an already constructed discord-luau class.
]]

local function failCall(object: any, callType: string)
	error(`Invoked unsupported metamethod '{callType}' on object '{tostring(object)}'`, 3)
end

return function<S, M>(source: S, class: M): S & M
	local object

	object = setmetatable({}, {
		__index = function(_, index)
			return source[index] or class[index]
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
		__type = class.type or "GenericClass",

		-- __eq = ...
		-- __gc = ...

		__tostring = function()
			return `DiscordLuau<'{class.type or "GenericClass"}'>`
		end,
	})

	return object
end
