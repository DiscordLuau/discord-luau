return setmetatable({ }, {
	__index = require("@lune/datetime")
})