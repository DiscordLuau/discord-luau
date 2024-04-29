return setmetatable({ }, {
	__index = require("@lune/task")
})