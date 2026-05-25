--[=[
	@class Commands
	@__index Prototype

	Main entry point for the discord-luau commands framework. Routes slash commands, context
	menus, components, modals, and autocomplete interactions to their registered handlers.

	Supports middleware, per-command guards (AND and OR logic), cooldowns, concurrency limits,
	option transforms, subcommands, interaction collectors, hot-reloading, and plugins.
]=]

--[=[
	@prop bot DiscordLuau.Bot
	@within Commands
]=]

--[=[
	@prop logger logger.Logger
	@within Commands
]=]

--[=[
	@prop registry registry.Registry
	@within Commands
]=]

--[=[
	@prop loader loader.Loader
	@within Commands
]=]

--[=[
	@prop context any
	@within Commands
]=]

--[=[
	@prop middleware { Middleware }
	@within Commands
]=]

--[=[
	@prop afterHooks { (classes.TypesCommand) -> () }
	@within Commands
]=]

--[=[
	@prop cooldowns { [string]: number }
	@within Commands
]=]

--[=[
	@prop concurrency { [string]: number }
	@within Commands
]=]

--[=[
	@prop componentCollectors { ComponentCollector }
	@within Commands
]=]

--[=[
	@prop modalCollectors { ModalCollector }
	@within Commands
]=]

--[=[
	@prop plugins { [string]: () -> () }
	@within Commands
]=]

--[=[
	@prop watchEnabled boolean
	@within Commands
]=]

--[=[
	@prop watchers { () -> () }
	@within Commands
]=]

--[=[
	@prop onError ErrorHandler
	@within Commands
]=]

--[=[
	@prop onGuardFailed GuardFailedHandler
	@within Commands
]=]

--[=[
	@prop onConcurrencyLimited ConcurrencyLimitedHandler
	@within Commands
]=]

local builders = require("./luau_packages/builders")
local classes = require("./luau_packages/classes")
local future = require("./luau_packages/future")
local logger = require("./luau_packages/logger")
local stdPolyfills = require("./luau_packages/std_polyfills")

local command = require("@self/command")
local cooldown = require("@self/cooldown")
local guards = require("@self/guards")
local loader = require("@self/loader")
local pipeline = require("@self/pipeline")
local registry = require("@self/registry")

local helpCommand = require("@self/defaults/help")

local Commands = {}

Commands.Interface = {}
Commands.Prototype = {}

local function splitId(id: string): { string }
	local segments = {}

	for segment in string.gmatch(id, "[^:]+") do
		table.insert(segments, segment)
	end

	return segments
end

local function matchSegments(pattern: { string }, id: { string }, patternIndex: number, currentIndex: number): boolean
	if patternIndex > #pattern and currentIndex > #id then
		return true
	end

	if patternIndex > #pattern or currentIndex > #id then
		return false
	end

	local segment = pattern[patternIndex]

	if segment == "**" then
		for consumed = 1, #id - currentIndex + 1 do
			if matchSegments(pattern, id, patternIndex + 1, currentIndex + consumed) then
				return true
			end
		end

		return false
	elseif segment == "*" then
		return matchSegments(pattern, id, patternIndex + 1, currentIndex + 1)
	end

	if segment ~= id[currentIndex] then
		return false
	end

	return matchSegments(pattern, id, patternIndex + 1, currentIndex + 1)
end

local function matchCustomId(pattern: string, customId: string): boolean
	if pattern == customId then
		return true
	end

	return matchSegments(splitId(pattern), splitId(customId), 1, 1)
end

local function resolveSubcommand(
	subcommands: {
		[string]: command.SubcommandDefinition | { [string]: command.SubcommandDefinition },
	},
	data: classes.InteractionData
): command.SubcommandDefinition?
	if #data.options == 0 then
		return
	end

	local firstOption = data.options[1]

	local optionType = (firstOption.type :: any) :: string

	if optionType == "SubCommand" then
		local entry = subcommands[firstOption.name]

		if entry and type((entry :: any).execute) == "function" then
			return (entry :: any) :: command.SubcommandDefinition
		end
	elseif optionType == "SubCommandGroup" then
		local group = subcommands[firstOption.name]

		if group and type((group :: any).execute) ~= "function" then
			local nestedOptions = firstOption.options

			if nestedOptions and #nestedOptions > 0 then
				local nested = (group :: any)[nestedOptions[1].name]

				if nested then
					return (nested :: any) :: command.SubcommandDefinition
				end
			end
		end
	end

	return
end

local function waitForInteraction<T>(
	collectorList: { { filter: (T) -> boolean, resolve: (T) -> () } },
	filter: ((T) -> boolean)?,
	timeout: number?
): T
	local thread = coroutine.running()
	local settled = false
	local timeoutThread: thread? = nil
	local collector = {
		filter = filter or function()
			return true
		end,
		resolve = function(interaction: T)
			if settled then
				return
			end

			settled = true

			if timeoutThread then
				stdPolyfills.task.cancel(timeoutThread)
			end

			coroutine.resume(thread, interaction)
		end,
	}

	table.insert(collectorList :: any, collector)

	timeoutThread = stdPolyfills.task.delay(timeout or 30, function()
		if settled then
			return
		end

		settled = true

		for index, entry in collectorList do
			if entry == collector then
				table.remove(collectorList :: any, index)
				break
			end
		end

		coroutine.resume(thread, nil, "timeout")
	end)

	local interaction, errorMessage = coroutine.yield()

	if errorMessage then
		error(errorMessage :: string, 0)
	end

	return interaction :: T
end

--[=[
	@within Commands

	Recursively loads all .luau command modules found under `directoryPath`. If `watchEnabled`
	is true, also begins watching the directory for changes.
]=]
function Commands.Prototype.load(self: Commands, directoryPath: string)
	self.loader:load(directoryPath)

	if self.watchEnabled then
		local stop = self.loader:watch(directoryPath)

		table.insert(self.watchers, stop)
	end
end

--[=[
	@within Commands

	Begins watching `directoryPath` for command file changes. Returns a stop function.
]=]
function Commands.Prototype.watch(self: Commands, directoryPath: string): () -> ()
	local stop = self.loader:watch(directoryPath)

	table.insert(self.watchers, stop)

	return stop
end

--[=[
	@within Commands

	Returns the shared context object passed at construction.
]=]
function Commands.Prototype.getContext(self: Commands): any
	return self.context
end

--[=[
	@within Commands

	Installs a plugin by calling its `setup` function. Skips silently if the plugin is already loaded.
]=]
function Commands.Prototype.usePlugin(self: Commands, plugin: PluginDefinition)
	if self.plugins[plugin.name] then
		self.logger:warn(`plugin '{plugin.name}' is already loaded - skipping`)
		return
	end

	local success, result = pcall(plugin.setup :: (any) -> any, self)

	if not success then
		self.logger:warn(`plugin '{plugin.name}' setup threw: {result}`)
		return
	end

	self.plugins[plugin.name] = if type(result) == "function" then result :: () -> () else function() end

	self.logger:info(`loaded plugin '{plugin.name}'`)
end

--[=[
	@within Commands

	Unloads a plugin by name, calling its teardown function if one was returned by `setup`.
]=]
function Commands.Prototype.unloadPlugin(self: Commands, name: string)
	local teardown = self.plugins[name]

	if not teardown then
		self.logger:warn(`plugin '{name}' is not loaded`)
		return
	end

	local success, errorMessage = pcall(teardown :: (any) -> any)

	if not success then
		self.logger:warn(`plugin '{name}' teardown threw: {errorMessage}`)
	end

	self.plugins[name] = nil

	self.logger:info(`unloaded plugin '{name}'`)
end

--[=[
	@within Commands

	Registers a command definition directly, without loading from disk.
]=]
function Commands.Prototype.add(self: Commands, commandDefinition: command.CommandDefinition)
	self.registry:set(commandDefinition)
end

--[=[
	@within Commands

	Unregisters a command by name.
]=]
function Commands.Prototype.remove(self: Commands, name: string)
	self.registry:remove(name)
end

--[=[
	@within Commands

	Stops all active file watchers started via `watch`.
]=]
function Commands.Prototype.destroy(self: Commands)
	for _, stop in self.watchers do
		stop()
	end

	self.watchers = {}
end

--[=[
	@within Commands

	Appends a middleware function to the dispatch pipeline.
]=]
function Commands.Prototype.use(self: Commands, middleware: Middleware)
	table.insert(self.middleware, middleware)
end

--[=[
	@within Commands

	Registers a global hook that fires after every command execution, regardless of success or error.
]=]
function Commands.Prototype.after(self: Commands, hook: (interaction: classes.TypesCommand) -> ())
	table.insert(self.afterHooks, hook)
end

--[=[
	@within Commands

	Wait for a single component interaction that satisfies `filter`, then resolve
	with it. If no matching interaction arrives within `timeout` seconds (default
	30), the Future errors with `"timeout"`.

	Only the first matching interaction is captured; it is not forwarded to any
	static component handler.
]=]
function Commands.Prototype.waitForComponent(
	self: Commands,
	options: {
		filter: ((interaction: classes.Component) -> boolean)?,
		timeout: number?,
	}
): future.FutureLike<classes.Component, string>
	return future.Future.new(function()
		return waitForInteraction(self.componentCollectors, options.filter, options.timeout)
	end) :: future.FutureLike<classes.Component, string>
end

--[=[
	@within Commands

	Wait for a single modal submission that satisfies `filter`, then resolve with it.
	If no matching submission arrives within `timeout` seconds (default 30), the
	Future errors with `"timeout"`.

	Only the first matching submission is captured; it is not forwarded to any
	static modal handler.
]=]
function Commands.Prototype.waitForModal(
	self: Commands,
	options: {
		filter: ((interaction: classes.Modal) -> boolean)?,
		timeout: number?,
	}
): future.FutureLike<classes.Modal, string>
	return future.Future.new(function()
		return waitForInteraction(self.modalCollectors, options.filter, options.timeout)
	end) :: future.FutureLike<classes.Modal, string>
end

--[=[
	@within Commands

	Routes a slash command interaction through middleware, guards, cooldowns, concurrency checks,
	and transforms before invoking the registered command execute handler.
]=]
function Commands.Prototype.dispatchCommand(self: Commands, interaction: classes.TypesCommand)
	if not interaction.data then
		self.logger:warn("dispatch called with an interaction missing .data - interaction ignored")
		return
	end

	local data = interaction.data

	pipeline.runMiddleware(self.middleware, 1, interaction, function()
		local registeredCommand = self.registry:get(data.name)

		if not registeredCommand then
			self.logger:debug(`no handler registered for command '{data.name}'`)
			return
		end

		local effectiveOnError: ErrorHandler = registeredCommand.onError or self.onError
		local effectiveOnGuardFailed: GuardFailedHandler = registeredCommand.onGuardFailed or self.onGuardFailed
		local effectiveOnConcurrencyLimited: ConcurrencyLimitedHandler = registeredCommand.onConcurrencyLimited
			or self.onConcurrencyLimited

		if registeredCommand.userPermissions and interaction.guildId then
			local member = interaction.member
			local memberPermissions = member and member.permissions

			if memberPermissions then
				local missing = pipeline.getMissingPermissions(
					classes.permission.new(memberPermissions),
					registeredCommand.userPermissions
				)

				if #missing > 0 then
					if registeredCommand.onUserPermissionDenied then
						registeredCommand.onUserPermissionDenied(interaction, missing)
					else
						interaction
							:messageAsync({
								content = "You lack the required permissions to use this command.",
								flags = 64,
							})
							:poll()
					end

					return
				end
			end
		end

		if registeredCommand.clientPermissions and interaction.guildId then
			local missing =
				pipeline.getMissingPermissions(interaction.appPermissions, registeredCommand.clientPermissions)

			if #missing > 0 then
				if registeredCommand.onClientPermissionDenied then
					registeredCommand.onClientPermissionDenied(interaction, missing)
				else
					interaction
						:messageAsync({
							content = "I lack the required permissions to execute this command.",
							flags = 64,
						})
						:poll()
				end

				return
			end
		end

		if
			registeredCommand.guards
			and not pipeline.runGuards(
				registeredCommand.guards,
				interaction,
				self.logger,
				data.name,
				effectiveOnGuardFailed,
				effectiveOnError
			)
		then
			return
		end

		if registeredCommand.cooldown then
			local cooldownRules: { command.CooldownRule }? = nil

			if type(registeredCommand.cooldown) == "function" then
				local success, result = pcall(registeredCommand.cooldown :: (any) -> any, interaction)

				if not success then
					self.logger:warn(`cooldown function threw for '{data.name}': {result}`)
				else
					cooldownRules = result
				end
			else
				cooldownRules = registeredCommand.cooldown :: { command.CooldownRule }
			end

			if cooldownRules then
				local remaining = cooldown.checkCooldown(self.cooldowns, data.name, cooldownRules, interaction)

				if remaining then
					if registeredCommand.onCooldown then
						registeredCommand.onCooldown(interaction, remaining)
					else
						interaction
							:messageAsync({
								content = `This command is on cooldown. Try again in **{remaining}** second{remaining == 1 and "" or "s"}.`,
								flags = 64,
							})
							:poll()
					end

					return
				end

				cooldown.applyCooldown(self.cooldowns, data.name, cooldownRules, interaction)
			end
		end

		local releaseConcurrencySlot: () -> () = function() end

		if registeredCommand.maxConcurrency then
			local acquired =
				cooldown.acquireConcurrency(self.concurrency, data.name, registeredCommand.maxConcurrency, interaction)

			if not acquired then
				if effectiveOnConcurrencyLimited then
					effectiveOnConcurrencyLimited(interaction)
				else
					interaction
						:messageAsync({
							content = "This command is already running. Please wait for it to finish.",
							flags = 64,
						})
						:poll()
				end

				return
			end

			local rule = registeredCommand.maxConcurrency

			releaseConcurrencySlot = function()
				cooldown.releaseConcurrency(self.concurrency, data.name, rule, interaction)
			end
		end

		if registeredCommand.subcommands then
			local subcommandDefinition = resolveSubcommand(registeredCommand.subcommands, data)

			if subcommandDefinition then
				if
					subcommandDefinition.guards
					and not pipeline.runGuards(
						subcommandDefinition.guards,
						interaction,
						self.logger,
						data.name,
						effectiveOnGuardFailed,
						effectiveOnError
					)
				then
					return
				end

				local subTransformed: { [string]: any } = {}

				if subcommandDefinition.transforms then
					local result = pipeline.runTransforms(
						subcommandDefinition.transforms,
						interaction,
						self.logger,
						data.name,
						effectiveOnError
					)

					if not result then
						return
					end

					subTransformed = result
				end

				pipeline.injectGetTransformed(interaction, subTransformed)

				local success, errorMessage = pcall(subcommandDefinition.execute :: (any) -> any, interaction)

				releaseConcurrencySlot()

				if not success then
					self.logger:warn(`error in '{data.name}' subcommand execute: {errorMessage}`)
					pipeline.sendErrorResponse(interaction, tostring(errorMessage), effectiveOnError)
				end

				pipeline.runAfterHooks(self.afterHooks, registeredCommand.afterExecute, interaction, self.logger)

				return
			end

			self.logger:warn(`no subcommand handler matched for '{data.name}'`)
		end

		if data.targetId then
			local resolved = data.resolved

			if resolved then
				local targetUser: classes.User? = (resolved.users :: any)[data.targetId]

				if targetUser and registeredCommand.userExecute then
					local success, errorMessage =
						pcall(registeredCommand.userExecute :: (any, any) -> any, interaction, targetUser)

					releaseConcurrencySlot()

					if not success then
						self.logger:warn(`error in '{data.name}' userExecute: {errorMessage}`)
						pipeline.sendErrorResponse(interaction, tostring(errorMessage), effectiveOnError)
					end

					pipeline.runAfterHooks(self.afterHooks, registeredCommand.afterExecute, interaction, self.logger)

					return
				end

				local targetMessage: classes.Message? = (resolved.messages :: any)[data.targetId]

				if targetMessage and registeredCommand.messageExecute then
					local success, errorMessage =
						pcall(registeredCommand.messageExecute :: (any, any) -> any, interaction, targetMessage)

					releaseConcurrencySlot()

					if not success then
						self.logger:warn(`error in '{data.name}' messageExecute: {errorMessage}`)
						pipeline.sendErrorResponse(interaction, tostring(errorMessage), effectiveOnError)
					end

					pipeline.runAfterHooks(self.afterHooks, registeredCommand.afterExecute, interaction, self.logger)

					return
				end
			end
		end

		local transformed: { [string]: any } = {}

		if registeredCommand.transforms then
			local result = pipeline.runTransforms(
				registeredCommand.transforms,
				interaction,
				self.logger,
				data.name,
				effectiveOnError
			)

			if not result then
				return
			end

			transformed = result
		end

		pipeline.injectGetTransformed(interaction, transformed)

		local success, errorMessage = pcall(registeredCommand.execute :: (any) -> any, interaction)

		releaseConcurrencySlot()

		if not success then
			self.logger:warn(`error in '{data.name}' execute: {errorMessage}`)
			pipeline.sendErrorResponse(interaction, tostring(errorMessage), effectiveOnError)
		end

		pipeline.runAfterHooks(self.afterHooks, registeredCommand.afterExecute, interaction, self.logger)
	end, self.logger)
end

--[=[
	@within Commands

	Routes a component interaction to a pending collector, or to the static handler registered
	under a matching custom ID pattern.
]=]
function Commands.Prototype.dispatchComponent(self: Commands, interaction: classes.Component)
	if not interaction.data then
		self.logger:warn("dispatchComponent called with an interaction missing .data - interaction ignored")
		return
	end

	local customId = interaction.data.customId

	if not customId then
		self.logger:warn("dispatchComponent called with an interaction missing .data.customId - interaction ignored")
		return
	end

	pipeline.runMiddleware(self.middleware, 1, interaction, function()
		local matchedCollectorIndex: number? = nil

		for index, collector in self.componentCollectors do
			if collector.filter(interaction) then
				matchedCollectorIndex = index
				break
			end
		end

		if matchedCollectorIndex then
			local collector = table.remove(self.componentCollectors, matchedCollectorIndex) :: ComponentCollector

			collector.resolve(interaction)

			return
		end

		for _, registeredCommand in self.registry:getAll() do
			if registeredCommand.components then
				for pattern, handler in registeredCommand.components do
					if matchCustomId(pattern, customId) then
						local success, errorMessage = pcall(handler :: (any) -> any, interaction)

						if not success then
							self.logger:warn(`error in component '{customId}' handler: {errorMessage}`)
							pipeline.sendErrorResponse(
								interaction,
								tostring(errorMessage),
								registeredCommand.onError or self.onError
							)
						end

						return
					end
				end
			end
		end

		self.logger:debug(`no component handler registered for customId '{customId}'`)
	end, self.logger)
end

--[=[
	@within Commands

	Routes a modal submission to a pending collector, or to the static handler registered
	under a matching custom ID pattern.
]=]
function Commands.Prototype.dispatchModal(self: Commands, interaction: classes.Modal)
	if not interaction.data then
		self.logger:warn("dispatchModal called with an interaction missing .data - interaction ignored")
		return
	end

	local customId = interaction.data.customId

	if not customId then
		self.logger:warn("dispatchModal called with an interaction missing .data.customId - interaction ignored")
		return
	end

	pipeline.runMiddleware(self.middleware, 1, interaction, function()
		local matchedCollectorIndex: number? = nil

		for index, collector in self.modalCollectors do
			if collector.filter(interaction) then
				matchedCollectorIndex = index
				break
			end
		end

		if matchedCollectorIndex then
			local collector = table.remove(self.modalCollectors, matchedCollectorIndex) :: ModalCollector

			collector.resolve(interaction)

			return
		end

		for _, registeredCommand in self.registry:getAll() do
			if registeredCommand.modals then
				for pattern, handler in registeredCommand.modals do
					if matchCustomId(pattern, customId) then
						local success, errorMessage = pcall(handler :: (any) -> any, interaction)

						if not success then
							self.logger:warn(`error in modal '{customId}' handler: {errorMessage}`)

							pipeline.sendErrorResponse(
								interaction,
								tostring(errorMessage),
								registeredCommand.onError or self.onError
							)
						end

						return
					end
				end
			end
		end

		self.logger:debug(`no modal handler registered for customId '{customId}'`)
	end, self.logger)
end

--[=[
	@within Commands

	Routes an autocomplete interaction to the handler registered for the focused command or subcommand.
]=]
function Commands.Prototype.dispatchAutocomplete(self: Commands, interaction: classes.Autocomplete)
	if not interaction.data then
		self.logger:warn("dispatchAutocomplete called with an interaction missing .data - interaction ignored")
		return
	end

	local data = interaction.data

	pipeline.runMiddleware(self.middleware, 1, interaction, function()
		local registeredCommand = self.registry:get(data.name)

		if not registeredCommand then
			self.logger:debug(`no autocomplete handler registered for command '{data.name}'`)
			return
		end

		if registeredCommand.subcommands then
			local subcommandDefinition = resolveSubcommand(registeredCommand.subcommands, data)

			if subcommandDefinition and subcommandDefinition.autocomplete then
				local success, errorMessage = pcall(subcommandDefinition.autocomplete :: (any) -> any, interaction)

				if not success then
					self.logger:warn(`error in '{data.name}' subcommand autocomplete: {errorMessage}`)
				end

				return
			end
		end

		if not registeredCommand.autocomplete then
			self.logger:debug(`no autocomplete handler registered for command '{data.name}'`)
			return
		end

		local success, errorMessage = pcall(registeredCommand.autocomplete :: (any) -> any, interaction)

		if not success then
			self.logger:warn(`error in '{data.name}' autocomplete: {errorMessage}`)
		end
	end, self.logger)
end

--[=[
	@within Commands

	Uploads all registered commands globally to Discord, overwriting any previously registered commands.
]=]
function Commands.Prototype.registerAsync(self: Commands): future.FutureLike<string, nil>
	return future.Future.new(function()
		assert(self.bot.application, "Commands:registerAsync() called before bot is ready - bot.application is nil")

		local payload = {}

		for _, registeredCommand in self.registry:getAll() do
			local entry = registeredCommand.command

			if
				(entry.default_member_permissions == nil and registeredCommand.userPermissions)
				or (entry.nsfw == nil and registeredCommand.nsfw ~= nil)
			then
				entry = table.clone(entry)

				if entry.default_member_permissions == nil and registeredCommand.userPermissions then
					entry.default_member_permissions =
						builders.permission.fromPermissions(registeredCommand.userPermissions):build()
				end

				if entry.nsfw == nil and registeredCommand.nsfw ~= nil then
					entry.nsfw = registeredCommand.nsfw
				end
			end

			table.insert(payload, entry)
		end

		self.bot.application:overwriteSlashCommandsAsync(payload):await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Commands

	Uploads all registered commands to a specific guild, overwriting that guild's commands.
]=]
function Commands.Prototype.registerGuildAsync(self: Commands, guildId: string): future.FutureLike<string, nil>
	return future.Future.new(function()
		local guildResult = self.bot:getGuildAsync(guildId):await()
		assert(guildResult:isOk(), `failed to fetch guild: {guildResult:unwrapErr()}`)
		local guild = guildResult:unwrapOk()

		local payload = {}

		for _, registeredCommand in self.registry:getAll() do
			local entry = registeredCommand.command

			if
				(entry.default_member_permissions == nil and registeredCommand.userPermissions)
				or (entry.nsfw == nil and registeredCommand.nsfw ~= nil)
			then
				entry = table.clone(entry)

				if entry.default_member_permissions == nil and registeredCommand.userPermissions then
					entry.default_member_permissions =
						builders.permission.fromPermissions(registeredCommand.userPermissions):build()
				end

				if entry.nsfw == nil and registeredCommand.nsfw ~= nil then
					entry.nsfw = registeredCommand.nsfw
				end
			end

			table.insert(payload, entry)
		end

		self.logger:info(`sending {#payload} command(s) to guild '{guildId}'`)
		local overwriteResult = guild:overwriteSlashCommandsAsync(payload):await()
		assert(overwriteResult:isOk(), `failed to register commands: {overwriteResult:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Commands

	Clears all globally registered commands on Discord.
]=]
function Commands.Prototype.unregisterAsync(self: Commands): future.FutureLike<string, nil>
	return future.Future.new(function()
		assert(self.bot.application, "Commands:unregisterAsync() called before bot is ready - bot.application is nil")

		self.bot.application:overwriteSlashCommandsAsync({}):await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Commands

	Clears all commands registered to a specific guild on Discord.
]=]
function Commands.Prototype.unregisterGuildAsync(self: Commands, guildId: string): future.FutureLike<string, nil>
	return future.Future.new(function()
		local guildResult = self.bot:getGuildAsync(guildId):await()
		assert(guildResult:isOk(), `failed to fetch guild: {guildResult:unwrapErr()}`)
		local guild = guildResult:unwrapOk()

		local overwriteResult = guild:overwriteSlashCommandsAsync({}):await()
		assert(overwriteResult:isOk(), `failed to clear commands: {overwriteResult:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Commands

	Constructs a Commands instance, wires it to the bot's interaction events, and optionally
	registers the built-in /help command (enabled by default; set `options.help = false` to disable).
	File watching on load is enabled by default; set `options.watch = false` to disable.
]=]
function Commands.Interface.new(
	bot: any,
	options: {
		help: boolean?,
		watch: boolean?,
		context: any?,
		onError: ErrorHandler,
		onGuardFailed: GuardFailedHandler,
	}?
): Commands
	local self = setmetatable(
		{
			bot = bot,
			logger = logger.new("Commands", bot.logger:getLogLevel()),
			registry = registry.new(),
			watchEnabled = not options or options.watch ~= false,
			watchers = {} :: { () -> () },
			middleware = {} :: { Middleware },
			afterHooks = {} :: { (classes.TypesCommand) -> () },
			cooldowns = {} :: { [string]: number },
			concurrency = {} :: { [string]: number },
			componentCollectors = {} :: { ComponentCollector },
			modalCollectors = {} :: { ModalCollector },
			context = options and options.context,
			plugins = {} :: { [string]: () -> () },
			onError = options and options.onError,
			onGuardFailed = options and options.onGuardFailed,
			onConcurrencyLimited = nil :: ConcurrencyLimitedHandler,
		} :: Commands,
		{ __index = Commands.Prototype }
	)

	self.loader = loader.new(self.registry, self.logger, self.context)

	if not options or options.help ~= false then
		self.registry:set(helpCommand(self.registry))
	end

	bot.onPingInteraction:listen(function(interaction)
		interaction:pongAsync():poll()
	end)

	bot.onCommandInteraction:listen(function(interaction)
		self:dispatchCommand(interaction)
	end)

	bot.onComponentInteraction:listen(function(interaction)
		self:dispatchComponent(interaction)
	end)

	bot.onAutocompleteInteraction:listen(function(interaction)
		self:dispatchAutocomplete(interaction)
	end)

	bot.onModalInteraction:listen(function(interaction)
		self:dispatchModal(interaction)
	end)

	return self
end

Commands.Interface.Guards = guards

type ErrorHandler = (
	(interaction: classes.TypesCommand | classes.Component | classes.Modal, errorMessage: string) -> ()
)?
type GuardFailedHandler = ((interaction: classes.TypesCommand) -> ())?
type ConcurrencyLimitedHandler = ((interaction: classes.TypesCommand) -> ())?
type ComponentCollector = {
	filter: (interaction: classes.Component) -> boolean,
	resolve: (interaction: classes.Component) -> (),
}
type ModalCollector = {
	filter: (interaction: classes.Modal) -> boolean,
	resolve: (interaction: classes.Modal) -> (),
}

export type Middleware = (interaction: any, next: () -> ()) -> ()
export type PluginDefinition = {
	name: string,
	setup: (commands: Commands) -> (() -> ())?,
}

export type Commands = typeof(Commands.Prototype) & {
	bot: any,
	logger: logger.Logger,
	registry: registry.Registry,
	loader: loader.Loader,
	watchEnabled: boolean,
	watchers: { () -> () },
	middleware: { Middleware },
	afterHooks: { (classes.TypesCommand) -> () },
	cooldowns: { [string]: number },
	concurrency: { [string]: number },
	componentCollectors: { ComponentCollector },
	modalCollectors: { ModalCollector },
	context: any,
	plugins: { [string]: () -> () },
	onError: ErrorHandler,
	onGuardFailed: GuardFailedHandler,
	onConcurrencyLimited: ConcurrencyLimitedHandler,
}

export type CommandDefinition = command.CommandDefinition
export type SubcommandDefinition = command.SubcommandDefinition
export type CooldownRule = command.CooldownRule
export type CooldownFunction = command.CooldownFunction
export type TransformFunction = command.TransformFunction
export type Guard = guards.Guard
export type GuardFunction = command.GuardFunction
export type GuardEntry = command.GuardEntry

return Commands.Interface
