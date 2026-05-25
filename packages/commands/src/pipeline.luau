--[=[
	@class Commands.Pipeline

	Utility functions for the command dispatch pipeline - error responses, guards, permissionission
	checks, option transforms, middleware, and post-execute hooks.
]=]

local apiTypes = require("../luau_packages/api_types")
local classes = require("../luau_packages/classes")
local logger = require("../luau_packages/logger")

local command = require("./command")

--[=[
	@within Commands.Pipeline

	Sends a generic error reply to the interaction, or delegates to `override` if provided.
]=]
local function sendErrorResponse(
	interaction: classes.TypesCommand | classes.Component | classes.Modal,
	errorMessage: string,
	override: ((classes.TypesCommand | classes.Component | classes.Modal, string) -> ())?
)
	if override then
		override(interaction, errorMessage)
		return
	end

	if interaction.isReplied then
		interaction
			:createFollowupResponseAsync({ content = "An error occurred while running this command.", flags = 64 })
			:poll()
	elseif interaction.isDeferred then
		interaction:messageAsync({ content = "An error occurred while running this command." }):poll()
	else
		interaction:messageAsync({ content = "An error occurred while running this command.", flags = 64 }):poll()
	end
end

--[=[
	@within Commands.Pipeline

	Evaluates all guard entries against the interaction. AND guards must all pass; within an OR
	group at least one must pass. Returns false and fires the guard-failed handler on first failure.
]=]
local function runGuards(
	guardEntries: { command.GuardEntry },
	interaction: classes.TypesCommand,
	log: logger.Logger,
	name: string,
	onGuardFailed: ((classes.TypesCommand) -> ())?,
	onError: ((classes.TypesCommand | classes.Component | classes.Modal, string) -> ())?
): boolean
	local function denyGuard()
		if onGuardFailed then
			onGuardFailed(interaction)
		elseif not interaction.isReplied then
			interaction
				:messageAsync({ content = "You don't have permissionission to use this command.", flags = 64 })
				:poll()
		end
	end

	for _, entry in guardEntries do
		if type(entry) == "function" then
			local guard = entry :: (classes.TypesCommand) -> boolean

			local passed = false

			local success, errorMessage = pcall(function()
				passed = guard(interaction)
			end)

			if not success then
				log:warn(`guard threw for '{name}': {errorMessage}`)
				sendErrorResponse(interaction, tostring(errorMessage), onError)
				return false
			end

			if not passed then
				denyGuard()
				return false
			end
		else
			local orGroup = entry :: { (classes.TypesCommand) -> boolean }

			local anyPassed = false

			for _, guard in orGroup do
				local passed = false

				local success, errorMessage = pcall(function()
					passed = guard(interaction)
				end)

				if not success then
					log:warn(`guard threw for '{name}': {errorMessage}`)
					sendErrorResponse(interaction, tostring(errorMessage), onError)
					return false
				end

				if passed then
					anyPassed = true
					break
				end
			end

			if not anyPassed then
				denyGuard()
				return false
			end
		end
	end

	return true
end

--[=[
	@within Commands.Pipeline

	Returns permissionissions from `required` that are absent from `permissionObject`.
]=]
local function getMissingPermissions(
	permissionObject: classes.Permission,
	required: { apiTypes.Permissions }
): { apiTypes.Permissions }
	local missing: { apiTypes.Permissions } = {}

	for _, permission in required do
		if not permissionObject:hasPermission(permission :: apiTypes.Permissions) then
			table.insert(missing, permission :: apiTypes.Permissions)
		end
	end

	return missing
end

--[=[
	@within Commands.Pipeline

	Runs each named transform over its option value. Returns nil and fires the error handler
	if any transform throws; otherwise returns the full map of transformed values.
]=]
local function runTransforms(
	transforms: { [string]: command.TransformFunction },
	interaction: classes.TypesCommand,
	log: logger.Logger,
	name: string,
	onError: ((classes.TypesCommand | classes.Component | classes.Modal, string) -> ())?
): { [string]: any }?
	local results: { [string]: any } = {}

	for optionName, transformFunction in transforms do
		local option: any = interaction:getOption(optionName)

		local rawValue: any = if option then option.value else nil
		local success, result = pcall(transformFunction :: (any, any) -> any, rawValue, interaction)

		if not success then
			log:warn(`transform '{optionName}' threw for '{name}': {result}`)
			sendErrorResponse(interaction, tostring(result), onError)
			return
		end

		results[optionName] = result
	end

	return results
end

--[=[
	@within Commands.Pipeline

	Injects a `getTransformed(name)` method onto the interaction for retrieving transformed option values.
]=]
local function injectGetTransformed(interaction: classes.TypesCommand, transformed: { [string]: any })
	(interaction :: any).getTransformed = function(_: any, name: string): any
		return transformed[name]
	end
end

--[=[
	@within Commands.Pipeline

	Runs the per-command `afterExecute` hook followed by all global after-hooks.
	Errors in individual hooks are logged but do not propagate.
]=]
local function runAfterHooks(
	afterHooks: { (classes.TypesCommand) -> () },
	perCommand: ((classes.TypesCommand) -> ())?,
	interaction: classes.TypesCommand,
	log: logger.Logger
)
	if perCommand then
		local success, errorMessage = pcall(perCommand :: (any) -> any, interaction)

		if not success then
			log:warn(`afterExecute threw: {errorMessage}`)
		end
	end

	for _, hook in afterHooks do
		local success, errorMessage = pcall(hook :: (any) -> any, interaction)

		if not success then
			log:warn(`after hook threw: {errorMessage}`)
		end
	end
end

--[=[
	@within Commands.Pipeline

	Recursively runs each middleware in order, calling `final` when the chain is exhausted.
]=]
local function runMiddleware(
	middlewares: { (any, () -> ()) -> () },
	index: number,
	interaction: any,
	final: () -> (),
	log: logger.Logger
)
	if index > #middlewares then
		final()
		return
	end

	local function callNext()
		runMiddleware(middlewares, index + 1, interaction, final, log)
	end

	local success, errorMessage = pcall(middlewares[index] :: (any, any) -> any, interaction, callNext)

	if not success then
		log:warn(`middleware[{index}] threw: {errorMessage}`)
	end
end

return {
	sendErrorResponse = sendErrorResponse,
	runGuards = runGuards,
	getMissingPermissions = getMissingPermissions,
	runTransforms = runTransforms,
	injectGetTransformed = injectGetTransformed,
	runAfterHooks = runAfterHooks,
	runMiddleware = runMiddleware,
}
