-- selene: allow(undefined_variable)
local erxFfi = require("@eryx/_ffi")
local erxOs = require("@eryx/os")

local ffi = {}

local TYPES = {
	void = erxFfi.void,
	i8 = erxFfi.i8,
	u8 = erxFfi.u8,
	i16 = erxFfi.i16,
	u16 = erxFfi.u16,
	i32 = erxFfi.i32,
	u32 = erxFfi.u32,
	i64 = erxFfi.i64,
	u64 = erxFfi.u64,
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

function ffi.dlopen(path: string, functions: { [string]: { returns: any, args: { any } } })
	local lib = erxFfi.loadLibrary(path)
	local result = {}

	for name, definition in functions do
		local fn = lib:getFunction(name, definition.returns, definition.args)
		result[name] = fn
	end

	return result
end

function ffi.struct(_fields: any): any
	error("ffi.struct is not supported on Eryx")
end

function ffi.closure(_definition: any, _handler: any): any
	error("ffi.closure is not supported on Eryx")
end

function ffi.fn(_definition: any, _srcPtr: any): any
	error("ffi.fn is not supported on Eryx")
end

function ffi.alloc(_size: number, _alignment: number?): any
	error("ffi.alloc is not supported on Eryx")
end

function ffi.create(_dataType: any): any
	error("ffi.create is not supported on Eryx")
end

function ffi.free(_src: any): any
	error("ffi.free is not supported on Eryx")
end

function ffi.dupe(_src: any): any
	error("ffi.dupe is not supported on Eryx")
end

function ffi.ptr(_src: any): any
	error("ffi.ptr is not supported on Eryx")
end

function ffi.ptrFromAddress(_src: buffer): any
	error("ffi.ptrFromAddress is not supported on Eryx")
end

function ffi.tagName(_tag: number): any
	error("ffi.tagName is not supported on Eryx")
end

function ffi.getLuaState(_mainthread: boolean?): any
	error("ffi.getLuaState is not supported on Eryx")
end

return ffi
