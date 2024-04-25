return setmetatable({ }, {
	__index = require("@lune/process")
})