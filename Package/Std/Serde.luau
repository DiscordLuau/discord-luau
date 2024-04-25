return setmetatable({ }, {
	__index = require("@lune/serde")
})