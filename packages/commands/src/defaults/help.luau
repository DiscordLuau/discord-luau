--[=[
	@class Commands.Help

	Built-in /help command factory - paginates registered commands by category using Components V2.
	Navigation is handled through the framework's own component routing.
]=]

local builders = require("../../luau_packages/builders")
local classes = require("../../luau_packages/classes")

local command = require("../command")
local registry = require("../registry")

local HELP_NAVIGATE_ID = "help:navigate"
local FLAG_COMPONENTS_V2 = 32768
local FLAG_EPHEMERAL = 64
local COMMANDS_PER_PAGE = 10

local messageComponents = builders.message.components

local function buildCommandLines(commandDefinition: command.CommandDefinition): { string }
	local lines = {}
	local options = commandDefinition.command.options

	if not options then
		table.insert(lines, `**/{commandDefinition.command.name}** - {commandDefinition.command.description or ""}`)
		return lines
	end

	local hasSubcommands = false

	for _, option in options do
		if option.type == 1 or option.type == 2 then
			hasSubcommands = true
			break
		end
	end

	if hasSubcommands then
		for _, option in options do
			if option.type == 1 then
				table.insert(lines, `**/{commandDefinition.command.name} {option.name}** - {option.description or ""}`)
			elseif option.type == 2 then
				local subOptions = option.options

				if subOptions then
					for _, subOption in subOptions do
						table.insert(
							lines,
							`**/{commandDefinition.command.name} {option.name} {subOption.name}** - {subOption.description or ""}`
						)
					end
				end
			end
		end
	else
		table.insert(lines, `**/{commandDefinition.command.name}** - {commandDefinition.command.description or ""}`)
	end

	return lines
end

local function buildPages(commands: { command.CommandDefinition }): { { title: string, lines: { string } } }
	table.sort(commands, function(commandA, commandB)
		return commandA.command.name < commandB.command.name
	end)

	local hasCategories = false

	for _, commandDefinition in commands do
		if commandDefinition.category then
			hasCategories = true
			break
		end
	end

	local pages: { { title: string, lines: { string } } } = {}

	if hasCategories then
		local groups: { [string]: { string } } = {}
		local categoryOrder: { string } = {}
		local uncategorized: { string } = {}

		for _, commandDefinition in commands do
			if commandDefinition.command.name == "help" then
				continue
			end

			local lines = buildCommandLines(commandDefinition)

			local category = commandDefinition.category

			if category then
				if not groups[category] then
					groups[category] = {}
					table.insert(categoryOrder, category)
				end

				for _, line in lines do
					table.insert(groups[category], line)
				end
			else
				for _, line in lines do
					table.insert(uncategorized, line)
				end
			end
		end

		table.sort(categoryOrder)

		for _, category in categoryOrder do
			table.insert(pages, { title = category, lines = groups[category] })
		end

		if #uncategorized > 0 then
			table.insert(pages, { title = "Other", lines = uncategorized })
		end
	else
		local allLines: { string } = {}

		for _, commandDefinition in commands do
			if commandDefinition.command.name == "help" then
				continue
			end

			for _, line in buildCommandLines(commandDefinition) do
				table.insert(allLines, line)
			end
		end

		local chunk: { string } = {}

		for _, line in allLines do
			table.insert(chunk, line)

			if #chunk >= COMMANDS_PER_PAGE then
				table.insert(pages, { title = "Commands", lines = chunk })
				chunk = {}
			end
		end

		if #chunk > 0 then
			table.insert(pages, { title = "Commands", lines = chunk })
		end
	end

	if #pages == 0 then
		table.insert(pages, { title = "Commands", lines = { "No commands available." } })
	end

	return pages
end

local function buildMessage(pageIndex: number, pages: { { title: string, lines: { string } } }): any
	local page = pages[pageIndex]

	local header = messageComponents.textDisplay.new({ content = `## {page.title}` })
	local divider = messageComponents.separator.new({ divider = true, spacing = 1 })
	local commandList = messageComponents.textDisplay.new({ content = table.concat(page.lines, "\n") })
	local spacer = messageComponents.separator.new({ divider = false, spacing = 1 })

	local prevButton = messageComponents.button.new()
	prevButton:setStyle("Blurple")
	prevButton:setLabel("← Previous")
	prevButton:setCustomId(`{HELP_NAVIGATE_ID}:prev:{pageIndex}`)
	prevButton:setDisabled(pageIndex <= 1)

	local nextButton = messageComponents.button.new()
	nextButton:setStyle("Blurple")
	nextButton:setLabel("Next →")
	nextButton:setCustomId(`{HELP_NAVIGATE_ID}:next:{pageIndex}`)
	nextButton:setDisabled(pageIndex >= #pages)

	local pageIndicator = messageComponents.button.new()
	pageIndicator:setStyle("Grey")
	pageIndicator:setLabel(`Page {pageIndex} of {#pages}`)
	pageIndicator:setCustomId(`{HELP_NAVIGATE_ID}:page:{pageIndex}`)
	pageIndicator:setDisabled(true)

	local actionRow = messageComponents.actionRow.new()
	actionRow:addComponent(prevButton:build())
	actionRow:addComponent(pageIndicator:build())
	actionRow:addComponent(nextButton:build())

	local container = messageComponents.container.new()
	container:addComponent(header:build())
	container:addComponent(divider:build())
	container:addComponent(commandList:build())
	container:addComponent(spacer:build())
	container:addComponent(actionRow:build())

	return {
		flags = FLAG_COMPONENTS_V2 + FLAG_EPHEMERAL,
		components = { container:build() },
	}
end

return function(registryInstance: registry.Registry): command.CommandDefinition
	return {
		command = builders.interaction.interaction
			.new()
			:setName("help")
			:setDescription("List all available commands")
			:setType("ChatInput")
			:addIntegrationType("UserInstall")
			:addContext("Guild")
			:addContext("BotDm")
			:addContext("PrivateChannel")
			:build(),

		execute = function(interaction)
			local pages = buildPages(registryInstance:getAll())

			interaction:messageAsync(buildMessage(1, pages)):await()
		end,

		components = {
			[HELP_NAVIGATE_ID .. ":**"] = function(interaction: classes.Component)
				local anyInteraction = interaction :: any

				local parts: { string } = {}

				for part in string.gmatch(anyInteraction.data.customId, "[^:]+") do
					table.insert(parts, part)
				end

				local action = parts[3]

				local pages = buildPages(registryInstance:getAll())

				local pageIndex = math.clamp(tonumber(parts[4]) or 1, 1, #pages)

				if action == "prev" then
					pageIndex = math.max(1, pageIndex - 1)
				elseif action == "next" then
					pageIndex = math.min(#pages, pageIndex + 1)
				end

				anyInteraction:acknowledgeAsync():await()
				anyInteraction:editResponseAsync(buildMessage(pageIndex, pages)):await()
			end,
		},
	}
end
