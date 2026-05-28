-- @eryx/_ffi wraps loadLibrary+getFunction rather than Zune's dlopen-with-definition model.
-- struct, closure, and raw memory ops (alloc/create/free/dupe/ptr) have no equivalent in
-- Eryx's FFI and will error if called.
-- selene: allow(undefined_variable)
local erxFfi = require("@eryx/_ffi")
local erxOs = require("@eryx/os")

local ffi = {}

-- Map Zune type names to Eryx type objects
local TYPES = {
	void    = erxFfi.void,
	i8      = erxFfi.i8,
	u8      = erxFfi.u8,
	i16     = erxFfi.i16,
	u16     = erxFfi.u16,
	i32     = erxFfi.i32,
	u32     = erxFfi.u32,
	i64     = erxFfi.i64,
	u64     = erxFfi.u64,
	pointer = erxFfi.u64:pointer(),
}

function ffi.getTypes()
	return TYPES
end

function ffi.getNull()
	return erxFfi.u64(0):pointer()
end

function ffi.getPrefix(): string
	local platform = erxOs.platform()
	return if platform == "windows" then "" else "lib"
end

function ffi.getSuffix(): string
	local platform = erxOs.platform()
	if platform == "windows" then
		return ".dll"
	elseif platform == "macos" then
		return ".dylib"
	else
		return ".so"
	end
end

-- Bridges Zune's dlopen({ symbolName = { returns, args } }) to Eryx's loadLibrary+getFunction.
function ffi.dlopen(path: string, functions: { [string]: { returns: any, args: { any } } })
	local lib = erxFfi.loadLibrary(path)
	local result = {}
	for name, def in functions do
		local fn = lib:getFunction(name, def.returns, def.args)
		result[name] = fn
	end
	return result
end

function ffi.struct(_fields: any)
	error("ffi.struct is not supported on Eryx")
end

function ffi.closure(_definition: any, _handler: any)
	error("ffi.closure is not supported on Eryx")
end

function ffi.fn(_definition: any, _srcPtr: any)
	error("ffi.fn is not supported on Eryx")
end

function ffi.alloc(_size: number, _alignment: number?)
	error("ffi.alloc is not supported on Eryx")
end

function ffi.create(_dataType: any)
	error("ffi.create is not supported on Eryx")
end

function ffi.free(_src: any)
	error("ffi.free is not supported on Eryx")
end

function ffi.dupe(_src: any)
	error("ffi.dupe is not supported on Eryx")
end

function ffi.ptr(_src: any)
	error("ffi.ptr is not supported on Eryx")
end

function ffi.ptrFromAddress(_src: buffer)
	error("ffi.ptrFromAddress is not supported on Eryx")
end

function ffi.tagName(_tag: number)
	error("ffi.tagName is not supported on Eryx")
end

function ffi.getLuaState(_mainthread: boolean?)
	error("ffi.getLuaState is not supported on Eryx")
end

return ffi
