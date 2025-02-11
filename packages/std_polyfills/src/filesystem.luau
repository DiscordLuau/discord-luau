--[=[
    @class Std.FileSystem
]=]

local FileSystem = {}

setmetatable(FileSystem, { __index = require("@lune/fs") })

return FileSystem
