return setmetatable({ }, {
	__index = require("@lune/net")
})