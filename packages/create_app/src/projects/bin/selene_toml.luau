return function(runtime: string)
	local std = if string.lower(runtime) == "zune" then "luau+zune" else "luau"
	return `std = "{std}"\n`
		.. [[

[lints]
high_cyclomatic_complexity = "allow"
if_same_then_else = "allow"
shadowing = "allow"
]]
end
