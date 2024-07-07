export type MoonwaveProperty = {
	name: string,
	desc: string,
	lua_type: string,
	source: {
		line: number,
		path: string,
	},
}

export type MoonwaveFunction = {
	name: string,
	desc: string,
	since: string?,
	unreleased: boolean?,
	source: {
		path: string,
		line: number,
	},
	function_type: "method" | "static",
	returns: {
		{
			desc: string,
			lua_type: string,
		}
	}?,
	params: {
		{
			name: string,
			desc: string,
			lua_type: string,
		}
	}?,
}

export type MoonwaveData = {
	name: string,
	functions: { MoonwaveFunction }?,
	source: { path: string, line: number },
	properties: { MoonwaveProperty }?,
	desc: string,
	types: unknown,
	tags: { string }?,
}

export type MoonwaveDataExportArray = { MoonwaveData }

return "Moonwave"
