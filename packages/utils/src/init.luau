local construct = require("@utils/utilities/construct")
local enumerate = require("@utils/utilities/enumerate")
local extend = require("@utils/utilities/extend")
local inherit = require("@utils/utilities/inherit")
local fetchKeys = require("@utils/utilities/fetchKeys")
local isUnique = require("@utils/utilities/isUnique")

--[=[
    @class Utilities

    A collection of utility modules.
]=]

local Utilities = {}

Utilities.Construct = construct
Utilities.Enumerate = enumerate
Utilities.Extend = extend
Utilities.Inherit = inherit
Utilities.FetchKeys = fetchKeys
Utilities.IsUnique = isUnique

return Utilities
