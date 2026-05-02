--!strict

--[=[
	@class StdPolyfills.ffi

	FFI polyfill for loading and calling native shared libraries. Only available on Zune;
	calling any function from an unsupported runtime will raise an error.

	Use `dlopen` to load a shared library and bind its exported C functions. Use `struct` to
	describe C struct layouts, `closure` to expose Luau callbacks as C function pointers, and
	`alloc`/`create`/`free` to manage raw memory for out-parameters and byte buffers.
]=]

local runtime = require("./runtime")

local ffi = {}

--[=[
	@within StdPolyfills.ffi

	Returns the primitive FFI type descriptors. Use the returned table's fields as `returns`
	and `args` values in `dlopen`, `closure`, and `fn` definitions. Available types: `void`,
	`i8`, `u8`, `i16`, `u16`, `i32`, `u32`, `i64`, `u64`, `float`, `double`, `pointer`.
]=]
function ffi.getTypes(): _zune_ffi_types
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").types
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Returns a null (`0x0`) FFI pointer. Pass this wherever a C function expects a NULL pointer argument.
]=]
function ffi.getNull(): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").null
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Returns the platform-specific shared library filename prefix, e.g. `"lib"` on Linux and
	macOS, `""` on Windows.
]=]
function ffi.getPrefix(): string
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").prefix
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Returns the platform-specific shared library filename suffix, e.g. `".so"` on Linux,
	`".dylib"` on macOS, `".dll"` on Windows.
]=]
function ffi.getSuffix(): string
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").suffix
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Opens a native shared library at `path` and binds the listed exported C functions.
	Each entry in `functions` maps a symbol name to its return type and argument types.
	Returns an `FFILibrary` whose fields are callable bound functions.

	```lua
	local lib = ffi.dlopen("/usr/lib/libfoo.so", {
	    fooInit = { returns = ffi.getTypes().void, args = {} },
	    fooAdd  = { returns = ffi.getTypes().i32, args = { ffi.getTypes().i32, ffi.getTypes().i32 } },
	})
	lib.fooInit()
	print(lib.fooAdd(1, 2))
	```
]=]
function ffi.dlopen(path: string, functions: { [string]: FFIFunctionDefintion }): FFILibrary
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").dlopen(path, functions)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Defines a C struct layout from an ordered list of named fields. Each entry is a
	single-key table mapping the field name to its `FFIAnyDataType`. Returns an
	`FFIStructureType` you can pass to `create` or use with `:new()` to allocate an
	initialised buffer.

	```lua
	local Vec2 = ffi.struct({ { x = ffi.getTypes().f32 }, { y = ffi.getTypes().f32 } })
	local v = Vec2:new({ x = 1, y = 2 })
	```
]=]
function ffi.struct(fields: { { [string]: FFIAnyDataType } }): FFIStructureType
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").struct(fields)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Wraps a Luau function as a C-callable function pointer. The `definition` describes the C
	signature the native side will use to call back into Luau. Returns an `FFIPointer` that
	remains valid until garbage-collected; retain it for the lifetime of any native code that
	may invoke it.

	```lua
	local cb = ffi.closure(
	    { returns = ffi.getTypes().void, args = { ffi.getTypes().pointer, ffi.getTypes().u64 } },
	    function(dataPtr, length) ... end
	)
	```
]=]
function ffi.closure(definition: FFIFunctionDefintion, handler: (...any) -> any): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").closure(definition, handler)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Wraps a raw `FFIPointer` to a C function as a callable Luau function according to
	`definition`. Useful when a library hands you a function pointer at runtime.
]=]
function ffi.fn(definition: FFIFunctionDefintion, srcPtr: FFIPointer): (...any) -> any
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").fn(definition, srcPtr)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Allocates `size` bytes of native memory aligned to `alignment` bytes (defaults to 1).
	Returns an `FFIPointer` to the allocation. Must be freed with `ffi.free` when no
	longer needed.
]=]
function ffi.alloc(size: number, alignment: number?): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").alloc(size, alignment)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Allocates native memory large enough for a value of `dataType` and returns a pointer to
	it. Useful for allocating out-parameter slots (`size_t*`, `uint8_t**`, etc.).
]=]
function ffi.create(dataType: FFIAnyDataType): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").create(dataType)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Frees native memory previously allocated with `alloc` or `create`.
]=]
function ffi.free(src: FFIPointer): ()
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").free(src)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Copies a Luau `buffer`, `FFIPointer`, or `vector` into a freshly allocated native memory
	region and returns a pointer to the copy.
]=]
function ffi.dupe(src: buffer | FFIPointer | vector): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").dupe(src)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Returns a pointer to the memory backing `src`. Use `dupe` instead if you need an owned copy.
]=]
function ffi.ptr(src: FFIPointer): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").ptr(src)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Constructs an `FFIPointer` from a raw address stored in an 8-byte `buffer` (little-endian
	`uint64`). Use this to materialise a pointer returned as a `buffer` by `readu64`.
]=]
function ffi.ptrFromAddress(src: buffer): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").ptrFromAddress(src)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Returns the tag name string associated with `tag`, or `nil` if the tag was never
	registered. Useful for debugging tagged pointer types created with `pointer:newTag`.
]=]
function ffi.tagName(tag: number): string?
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").tagName(tag)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.ffi

	Returns an `FFIPointer` to the current Lua state. When `mainthread` is `true`, returns
	the main thread's state rather than the current coroutine's. Required for some C APIs
	that expect a `lua_State*`.
]=]
function ffi.getLuaState(mainthread: boolean?): FFIPointer
	local target = runtime.assertRuntime()

	if target == "Zune" then
		return require("./zune/ffi").getLuaState(mainthread)
	elseif target == "Lune" then
		error(`The Lune runtime does not support FFI`)
	end

	error(`Out of reach`)
end

return ffi
