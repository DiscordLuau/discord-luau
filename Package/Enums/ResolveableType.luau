-- Types of Resolveables, only used internally to convey the data

local ResolveableType = {
	JSON = "JSON",
	FORMDATA = "FORMDATA",
}

export type ResolveableType = "JSON" | "FORMDATA"

return ResolveableType
