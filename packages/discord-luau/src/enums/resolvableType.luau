-- Types of Resolveables, only used internally to convey the data

local ResolvableType = {
	JSON = "JSON",
	FORMDATA = "FORMDATA",
}

export type ResolvableType = "JSON" | "FORMDATA"

return ResolvableType
