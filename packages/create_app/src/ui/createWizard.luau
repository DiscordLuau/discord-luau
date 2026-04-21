-- selene: allow(undefined_variable)
local tui = require("../../luau_packages/cli_tui")

local block = tui.block
local paragraph = tui.paragraph
local popup = tui.popup
local gauge = tui.gauge
local input = tui.input
local layout = tui.layout
local constraint = tui.constraint
local step = tui.step

local GRAY = 245
local WHITE = 255
local DARK_GRAY = 238
local BLUE = 33
local BLURPLE = 63
local GREEN = 35
local RED = 160

local SIDEBAR_WIDTH = 22
local MIN_WIDTH = 80
local MIN_HEIGHT = 17

local VALID_IDES = { vscode = true, nvim = true, zed = true }

type Information = {
	ProjectName: string,
	IDE: string,
	UseGit: string,
	License: string,
	DiscordToken: string,
}

type Field = {
	key: string,
	label: string,
	question: string,
	mask: string?,
	placeholder: string,
	default: string,
	validate: ((value: string) -> string?)?,
	normalise: ((value: string) -> string)?,
}

local FIELDS: { Field } = {
	{
		key = "ProjectName",
		label = "Project Name",
		question = "What should this project be called?  (scope/project-name)",
		mask = nil,
		placeholder = "myusername/my-discord-bot",
		default = "",
		validate = function(value)
			if #value == 0 then
				return "Project name cannot be empty."
			end
			if not string.match(value, "^[a-z0-9][a-z0-9%-]*/[a-z0-9][a-z0-9%-]*$") then
				return "Project name must be in scope/project-name format using only lowercase letters, numbers, and hyphens."
			end
			return nil
		end,
	},
	{
		key = "IDE",
		label = "IDE",
		question = "Which IDE will you be using?  (vscode / nvim / zed)",
		mask = nil,
		placeholder = "vscode",
		default = "vscode",
		normalise = function(value)
			return string.lower(value)
		end,
		validate = function(value)
			if not VALID_IDES[value] then
				return "Invalid IDE. Expected one of: vscode, nvim, zed"
			end
			return nil
		end,
	},
	{
		key = "UseGit",
		label = "Use Git",
		question = "Should this project use Git?  (Yes / No)",
		mask = nil,
		placeholder = "Yes",
		default = "Yes",
		normalise = function(value)
			local lowercaseValue = string.lower(value)
			if lowercaseValue == "y" then
				return "Yes"
			elseif lowercaseValue == "n" then
				return "No"
			end
			return value
		end,
	},
	{
		key = "License",
		label = "License",
		question = "What license should this project use?",
		mask = nil,
		placeholder = "MIT",
		default = "MIT",
	},
	{
		key = "DiscordToken",
		label = "Discord Token",
		question = "What is the Discord bot token?",
		mask = "●",
		placeholder = "Bot.XXXX…",
		default = "",
		validate = function(value)
			if not string.match(value, "^[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+$") then
				return "Discord token is invalid. Expected format: XXXXX.XXXXX.XXXXX"
			end
			return nil
		end,
	},
}

local PREREQUISITES = {
	{ name = "rokit", url = "https://github.com/rojo-rbx/rokit" },
	{ name = "pesde", url = "https://pesde.dev" },
}

local function buildSidebarText(activeIndex: number, allDone: boolean): string
	local lines = {}

	for i, field in FIELDS do
		local prefix
		if allDone or i < activeIndex then
			prefix = "✓ "
		elseif i == activeIndex then
			prefix = "▶ "
		else
			prefix = "  "
		end
		table.insert(lines, prefix .. field.label)
	end

	return table.concat(lines, "\n")
end

return function(onBuild: (
	info: Information,
	setStatus: (msg: string, progress: number) -> (),
	setWarning: (msg: string) -> ()
) -> string)
	local io = zune.io
	local task = zune.task

	local toolStatus: { [string]: boolean } = {}
	local allPrerequisitesMet = true

	for _, tool in PREREQUISITES do
		local result = zune.process.run(tool.name, { "--version" })

		toolStatus[tool.name] = result.ok

		if not result.ok then
			allPrerequisitesMet = false
		end
	end

	io.terminal.enableRawMode()
	io.stdout:writeSync("\27[?1049h\27[?25l")

	local fieldIndex = 1
	local texts: { string } = {}
	local cursors: { number } = {}

	for _, field in FIELDS do
		table.insert(texts, field.default)
		table.insert(cursors, #field.default + 1)
	end

	local state = "prereqs"
	local running = true

	local information: Information? = nil

	local buildProgress = 0.0
	local progressTarget = 0.0
	local statusMessage = "Setting up…"
	local buildDone = false
	local buildPath = ""
	local buildError: string?
	local buildWarning: string?
	local loadingFrames = 0

	local validationError: string?

	local function setStatus(msg: string, progress: number)
		statusMessage = msg
		progressTarget = progress
	end

	local function setWarning(msg: string)
		buildWarning = msg
	end

	local function advanceField()
		local field = FIELDS[fieldIndex]

		if field.normalise then
			local normalisedValue = field.normalise(texts[fieldIndex])
			texts[fieldIndex] = normalisedValue
			cursors[fieldIndex] = #normalisedValue + 1
		end

		if #texts[fieldIndex] == 0 then
			return
		end

		if field.validate then
			local exception = field.validate(texts[fieldIndex])
			if exception then
				validationError = exception
				return
			end
		end

		if fieldIndex < #FIELDS then
			fieldIndex += 1
		else
			local result: { [string]: string } = {}
			for i, currentField in FIELDS do
				result[currentField.key] = texts[i]
			end
			information = result :: Information

			state = "confirm"
		end
	end

	task.spawn(function()
		while running do
			local character = io.stdin:read(1)
			if not character or #character == 0 then
				continue
			end

			if character == "\3" then
				running = false
				continue
			end

			if state == "done" or state == "error" then
				running = false
				continue
			end

			if state == "prereqs" then
				state = "wizard"
				continue
			end

			if validationError ~= nil then
				if character ~= "\27" then
					validationError = nil
				end
				continue
			end

			if character == "\27" then
				local nextEscapeCharacter = io.stdin:read(1)

				if nextEscapeCharacter == "[" then
					local escapeCode = io.stdin:read(1)

					if state == "wizard" then
						if escapeCode == "C" then
							if cursors[fieldIndex] <= #texts[fieldIndex] then
								cursors[fieldIndex] += 1
							end
						elseif escapeCode == "D" then
							if cursors[fieldIndex] > 1 then
								cursors[fieldIndex] -= 1
							end
						elseif escapeCode == "A" then
							if fieldIndex > 1 then
								fieldIndex -= 1
								cursors[fieldIndex] = #texts[fieldIndex] + 1
							end
						elseif escapeCode == "B" then
							advanceField()
						end
					elseif state == "confirm" and escapeCode == "A" then
						state = "wizard"
						fieldIndex = #FIELDS
					end
				end

				continue
			end

			if state == "confirm" then
				local lowercaseCharacter = string.lower(character)

				if lowercaseCharacter == "y" then
					state = "loading"

					task.spawn(function()
						local buildSucceeded, buildResult =
							pcall(onBuild, information :: Information, setStatus, setWarning)

						if buildSucceeded then
							buildPath = buildResult :: string
						else
							buildError = tostring(buildResult)
						end

						buildDone = true
					end)
				elseif lowercaseCharacter == "n" then
					state = "wizard"
					fieldIndex = #FIELDS
				end

				continue
			end

			if state ~= "wizard" then
				continue
			end

			if character == "\r" or character == "\n" then
				advanceField()

				continue
			end

			if character == "\127" or character == "\8" then
				local currentText = texts[fieldIndex]
				local currentCursor = cursors[fieldIndex]

				if currentCursor > 1 then
					texts[fieldIndex] = string.sub(currentText, 1, currentCursor - 2)
						.. string.sub(currentText, currentCursor)
					cursors[fieldIndex] = currentCursor - 1
				end

				continue
			end

			local characterByte = string.byte(character)

			if characterByte >= 32 and characterByte < 127 then
				local currentText = texts[fieldIndex]
				local currentCursor = cursors[fieldIndex]

				texts[fieldIndex] = string.sub(currentText, 1, currentCursor - 1)
					.. character
					.. string.sub(currentText, currentCursor)
				cursors[fieldIndex] = currentCursor + 1
			end
		end
	end)

	while running do
		if state == "loading" then
			local target = if buildDone then 1.0 else progressTarget

			loadingFrames += 1
			buildProgress = buildProgress + (target - buildProgress) * 0.12

			if buildDone and loadingFrames >= 10 and buildProgress >= 0.98 then
				buildProgress = 1.0

				state = if buildError then "error" else "done"
			end
		end

		local terminalWidth, terminalHeight = io.terminal.getSize()
		local renderContext = { width = terminalWidth or 80, height = terminalHeight or 24 }

		if (terminalWidth or 0) < MIN_WIDTH or (terminalHeight or 0) < MIN_HEIGHT then
			io.stdout:writeSync(step(renderContext, function(fullArea)
				local tooSmallText = paragraph
					.new()
					:setText(
						`window size must be at least {MIN_WIDTH}x{MIN_HEIGHT}, currently {terminalWidth or 0}x{terminalHeight or 0}`
					)
					:setAlignment("center")
					:setStyle(RED)
				return { { widget = tooSmallText, area = fullArea } }
			end))
			task.wait(0.05)
			continue
		end

		io.stdout:writeSync(step(renderContext, function(fullArea)
			local outerLayout = layout
				.new()
				:setDirection("vertical")
				:setConstraints({ constraint.length(3), constraint.fill(1), constraint.length(3) })
				:split(fullArea)

			local headerArea = outerLayout[1]
			local bodyArea = outerLayout[2]
			local footerArea = outerLayout[3]

			local headerBlock = block
				.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded")
				:setBorderForegroundColor(BLURPLE)

			local headerText = paragraph
				.new()
				:setText("✦  discord-luau  ·  create a new project  ✦")
				:setAlignment("center")
				:setStyle(WHITE)

			local footerBlock = block
				.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded")
				:setBorderForegroundColor(GRAY)

			local footerHint = if state == "prereqs"
				then "Press any key to continue  ·  Ctrl+C  cancel"
				elseif
					state == "wizard"
				then "↑ ↓  navigate  ·  Enter  advance  ·  ← →  move cursor  ·  Backspace  delete  ·  Ctrl+C  cancel"
				elseif state == "confirm" then '"y"  confirm  ·  "n"  go back  ·  Ctrl+C  cancel'
				elseif state == "loading" then "Building your project, please wait…"
				else "Press any key to exit"

			local footerText = paragraph.new():setText(footerHint):setAlignment("center"):setStyle(GRAY)

			local widgets: { any } = {
				{ widget = headerBlock, area = headerArea },
				{ widget = headerText, area = headerBlock:inner(headerArea) },
				{ widget = footerBlock, area = footerArea },
				{ widget = footerText, area = footerBlock:inner(footerArea) },
			}

			if state == "prereqs" then
				local borderColor = if allPrerequisitesMet then GREEN else RED

				local prerequisitesBlock = block
					.new()
					:setBorders({ top = true, bottom = true, left = true, right = true })
					:setBorderSet("rounded")
					:setBorderForegroundColor(borderColor)
					:addTitle({ text = " Prerequisites ", alignment = "center" })
					:setPadding({ left = 3, right = 3, top = 1, bottom = 1 })

				local lines = {}
				for _, tool in PREREQUISITES do
					local isInstalled = toolStatus[tool.name]
					local prefix = if isInstalled then "✓  " else "✗  "
					local status = if isInstalled then "installed" else `not found  —  install from: {tool.url}`
					table.insert(lines, prefix .. tool.name .. string.rep(" ", math.max(1, 10 - #tool.name)) .. status)
				end
				table.insert(lines, "")
				if allPrerequisitesMet then
					table.insert(lines, "All prerequisites met.  Press any key to begin.")
				else
					table.insert(lines, "One or more required tools are missing.")
					table.insert(lines, "Install them and re-run, or press any key to continue anyway.")
				end

				local prerequisitesText = paragraph
					.new()
					:setText(table.concat(lines, "\n"))
					:setStyle(if allPrerequisitesMet then WHITE else RED)
					:setWrap(true)

				table.insert(widgets, { widget = prerequisitesBlock, area = bodyArea })
				table.insert(widgets, { widget = prerequisitesText, area = prerequisitesBlock:inner(bodyArea) })
			elseif state == "wizard" or state == "confirm" then
				local isConfirmStep = state == "confirm"

				local bodyLayout = layout
					.new()
					:setDirection("horizontal")
					:setConstraints({ constraint.length(SIDEBAR_WIDTH), constraint.fill(1) })
					:split(bodyArea)

				local sidebarArea = bodyLayout[1]
				local mainArea = bodyLayout[2]

				local sidebarBlock = block
					.new()
					:setBorders({ top = true, bottom = true, left = true, right = true })
					:setBorderSet("rounded")
					:setBorderForegroundColor(GRAY)
					:addTitle({ text = " Steps ", alignment = "center" })

				local sidebarText = paragraph.new():setText(buildSidebarText(fieldIndex, isConfirmStep)):setStyle(GRAY)

				table.insert(widgets, { widget = sidebarBlock, area = sidebarArea })
				table.insert(widgets, { widget = sidebarText, area = sidebarBlock:inner(sidebarArea) })

				local displayFieldIndex = if isConfirmStep then #FIELDS else fieldIndex
				local panelBlock = block
					.new()
					:setBorders({ top = true, bottom = true, left = true, right = true })
					:setBorderSet("rounded")
					:setBorderForegroundColor(BLUE)
					:addTitle({
						text = ` Step {displayFieldIndex} of {#FIELDS} · {FIELDS[displayFieldIndex].label} `,
						alignment = "left",
					})
					:setPadding({ left = 3, right = 3, top = 1, bottom = 1 })

				local panelInnerArea = panelBlock:inner(mainArea)
				local panelInnerLayout = layout
					.new()
					:setDirection("vertical")
					:setConstraints({ constraint.fill(1), constraint.length(3) })
					:split(panelInnerArea)

				local questionText =
					paragraph.new():setText(FIELDS[displayFieldIndex].question):setStyle(WHITE):setWrap(true)

				local fieldInput = input
					.new()
					:setText(texts[displayFieldIndex])
					:setCursor(cursors[displayFieldIndex])
					:setStyle(WHITE, DARK_GRAY)
					:setCursorStyle(DARK_GRAY, WHITE)
					:setPlaceholder(FIELDS[displayFieldIndex].placeholder)
					:setPlaceholderStyle(GRAY)
					:setBlock(
						block
							.new()
							:setBorders({ top = true, bottom = true, left = true, right = true })
							:setBorderSet("rounded")
							:setBorderForegroundColor(BLUE)
					)

				if FIELDS[displayFieldIndex].mask then
					fieldInput:setMask(FIELDS[displayFieldIndex].mask :: string)
				end

				table.insert(widgets, { widget = panelBlock, area = mainArea })
				table.insert(widgets, { widget = questionText, area = panelInnerLayout[1] })
				table.insert(widgets, { widget = fieldInput, area = panelInnerLayout[2] })

				if isConfirmStep then
					local confirmPopup = popup
						.new()
						:setWidth(58)
						:setHeight(12)
						:setBorderSet("rounded")
						:setBorderForegroundColor(BLURPLE)
						:addTitle({ text = " Confirm Details ", alignment = "center" })
						:setPadding({ left = 2, right = 2, top = 1, bottom = 1 })

					local confirmPopupArea = confirmPopup:area(bodyArea)

					local lines = {}
					for i, field in FIELDS do
						local value = texts[i]
						if field.mask then
							value = string.rep("●", #value)
						end
						local pad = string.rep(" ", math.max(1, 16 - #field.label))
						table.insert(lines, field.label .. pad .. value)
					end
					table.insert(lines, "")
					table.insert(lines, `  "y"  confirm    "n"  go back`)

					local confirmText = paragraph.new():setText(table.concat(lines, "\n")):setStyle(WHITE)

					table.insert(widgets, { widget = confirmPopup, area = confirmPopupArea })
					table.insert(widgets, { widget = confirmText, area = confirmPopup:inner(confirmPopupArea) })
				end

				if validationError ~= nil then
					local validationErrorPopup = popup
						.new()
						:setWidth(60)
						:setHeight(7)
						:setBorderSet("rounded")
						:setBorderForegroundColor(RED)
						:addTitle({ text = " Invalid Input ", alignment = "center" })
						:setPadding({ left = 2, right = 2, top = 1, bottom = 1 })

					local validationErrorArea = validationErrorPopup:area(bodyArea)

					local validationErrorText = paragraph
						.new()
						:setText(validationError .. "\n\nPress any key to continue.")
						:setStyle(RED)
						:setWrap(true)

					table.insert(widgets, { widget = validationErrorPopup, area = validationErrorArea })
					table.insert(
						widgets,
						{ widget = validationErrorText, area = validationErrorPopup:inner(validationErrorArea) }
					)
				end
			elseif state == "loading" then
				local loadingBlock = block
					.new()
					:setBorders({ top = true, bottom = true, left = true, right = true })
					:setBorderSet("rounded")
					:setBorderForegroundColor(BLUE)
					:addTitle({ text = " Building Project ", alignment = "center" })
					:setPadding({ left = 3, right = 3, top = 1, bottom = 1 })

				local loadingInnerArea = loadingBlock:inner(bodyArea)
				local loadingLayout = layout
					.new()
					:setDirection("vertical")
					:setConstraints({
						constraint.fill(1),
						constraint.length(3),
						constraint.length(1),
						constraint.fill(1),
					})
					:split(loadingInnerArea)

				local percent = math.floor(buildProgress * 100)
				local loadingGauge = gauge
					.new()
					:setRatio(buildProgress)
					:setLabel(`{percent}%`)
					:setStyle(GRAY)
					:setFilledStyle(WHITE, BLUE)
					:setBlock(
						block
							.new()
							:setBorders({ top = true, bottom = true, left = true, right = true })
							:setBorderSet("rounded")
							:setBorderForegroundColor(BLUE)
					)

				local statusText = paragraph
					.new()
					:setText(if buildDone then "Finalising…" else statusMessage)
					:setAlignment("center")
					:setStyle(GRAY)

				table.insert(widgets, { widget = loadingBlock, area = bodyArea })
				table.insert(widgets, { widget = loadingGauge, area = loadingLayout[2] })
				table.insert(widgets, { widget = statusText, area = loadingLayout[3] })
			else
				local isErrorState = state == "error"
				local borderColor = if isErrorState then RED else GREEN

				local completionBlock = block
					.new()
					:setBorders({ top = true, bottom = true, left = true, right = true })
					:setBorderSet("rounded")
					:setBorderForegroundColor(borderColor)
					:addTitle({ text = if isErrorState then " Error " else " Done! ", alignment = "center" })
					:setPadding({ left = 3, right = 3, top = 1, bottom = 1 })

				local completionContent = if isErrorState
					then `✗  An error occurred:\n\n{buildError or "unknown error"}`
					else `✓  Project created successfully!\n\n`
						.. `Location    {buildPath}\n\n`
						.. `Documentation and guides:\n`
						.. `https://discordluau.devcomp.xyz/`

				local completionText = paragraph
					.new()
					:setText(completionContent)
					:setStyle(if isErrorState then RED else WHITE)
					:setWrap(true)

				table.insert(widgets, { widget = completionBlock, area = bodyArea })
				table.insert(widgets, { widget = completionText, area = completionBlock:inner(bodyArea) })
			end

			return widgets
		end))

		task.wait(0.05)
	end

	io.stdout:writeSync("\27[?1049l\27[?25h")
	io.terminal.restoreMode()

	if buildError then
		io.stderr:writeSync(
			"\n\27[1;31m── Build Error ──────────────────────────────────────\27[0m\n"
		)
		io.stderr:writeSync(buildError .. "\n")
		io.stderr:writeSync(
			"\27[1;31m─────────────────────────────────────────────────────\27[0m\n\n"
		)
	end
	if buildWarning then
		io.stderr:writeSync(
			"\n\27[1;33m── Warning ──────────────────────────────────────────\27[0m\n"
		)
		io.stderr:writeSync(buildWarning .. "\n")
		io.stderr:writeSync(
			"\27[1;33m─────────────────────────────────────────────────────\27[0m\n\n"
		)
	end
end
