local StdPolyfills = require("../../luau_packages/std_polyfills")

local diagnostics = {}

local function resolveVersion(): string
	local detectedRuntime = StdPolyfills.runtime.getRuntime()

	if detectedRuntime == "Lute" then
		local ok, result = pcall(StdPolyfills.process.run, "lute", { "--version" })
		if ok and result.ok then
			local version = string.match(result.stdout, "^%s*(%S+)") or string.match(result.stderr, "^%s*(%S+)")
			if version then
				return "lute " .. version
			end
		end
	end

	return _VERSION
end

function diagnostics.gather(): DiagnosticsInfo
	local platformOk, platform = pcall(StdPolyfills.process.getPlatform)
	local archOk, arch = pcall(StdPolyfills.process.getArch)

	return {
		runtime = StdPolyfills.runtime.getRuntime(),
		version = resolveVersion(),
		os = if platformOk then tostring(platform) else "unknown",
		arch = if archOk then tostring(arch) else "unavailable",
		capabilities = StdPolyfills.runtime.capabilities() :: { [string]: boolean },
	}
end

export type DiagnosticsInfo = {
	runtime: string,
	version: string,
	os: string,
	arch: string,
	capabilities: { [string]: boolean },
}

return diagnostics
