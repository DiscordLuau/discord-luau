local StdPolyfills = require("../../luau_packages/std_polyfills")

local diagnostics = {}

export type DiagnosticsInfo = {
	runtime: string,
	version: string,
	os: string,
	arch: string,
	capabilities: { [string]: boolean },
}

function diagnostics.gather(): DiagnosticsInfo
	local platformOk, platform = pcall(StdPolyfills.process.getPlatform)
	local archOk, arch = pcall(StdPolyfills.process.getArch)

	return {
		runtime = StdPolyfills.runtime.getRuntime(),
		version = _VERSION,
		os = if platformOk then tostring(platform) else "unknown",
		arch = if archOk then tostring(arch) else "unavailable",
		capabilities = StdPolyfills.runtime.capabilities() :: { [string]: boolean },
	}
end

return diagnostics
