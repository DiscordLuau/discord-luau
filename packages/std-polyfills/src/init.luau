local filesystem = require("./filesystem")
local task = require("./task")
local serde = require("./serde")
local process = require("./process")
local stdio = require("./stdio")
local datetime = require("./datetime")
local net = require("./net")

export type DateTime = datetime.DateTime

export type WebSocket = net.WebSocket
export type FetchResponse = net.FetchResponse
export type FetchParams = net.FetchParams
export type HttpMethod = net.HttpMethod
export type HttpHeaderMap = net.HttpHeaderMap

return {
	filesystem = filesystem,
	task = task,
	serde = serde,
	process = process,
	stdio = stdio,
	datetime = datetime,
	net = net,
}
