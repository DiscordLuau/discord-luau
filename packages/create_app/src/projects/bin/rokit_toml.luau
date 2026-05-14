local StdPolyfills = require("../../../luau_packages/std_polyfills")

local RUNTIME_TOOLS = {
	zune = "Scythe-Technology/zune@0.5.5",
	lune = "lune-org/lune@0.10.4",
}

return function(runtime: string)
	local tools = {
		lune = RUNTIME_TOOLS.lune,
	}

	if runtime ~= "lune" then
		tools[runtime] = RUNTIME_TOOLS[runtime]
	end

	return StdPolyfills.serde.encode("toml", { tools = tools }, true)
end
