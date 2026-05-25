--[=[
	@class Commands.Cooldown

	Pure utility functions for cooldown and concurrency state management.
]=]

local classes = require("../luau_packages/classes")

local command = require("./command")

local function resolveInteractionUserId(interaction: classes.TypesCommand): string
	if interaction.user then
		return interaction.user.id
	elseif interaction.member then
		local memberUser = interaction.member.user

		return if memberUser then memberUser.id else "unknown"
	end

	return "unknown"
end

local function buildCooldownKey(commandName: string, per: string, interaction: classes.TypesCommand): string
	if per == "user" then
		return `{commandName}:user:{resolveInteractionUserId(interaction)}`
	elseif per == "guild" then
		return `{commandName}:guild:{interaction.guildId or "dm"}`
	elseif per == "channel" then
		return `{commandName}:channel:{interaction.channelId or "unknown"}`
	elseif per == "member" then
		return `{commandName}:member:{interaction.guildId or "dm"}:{resolveInteractionUserId(interaction)}`
	end

	return `{commandName}:global`
end

local function buildConcurrencyKey(commandName: string, per: string, interaction: classes.TypesCommand): string
	if per == "user" then
		return `{commandName}:conc:user:{resolveInteractionUserId(interaction)}`
	elseif per == "guild" then
		return `{commandName}:conc:guild:{interaction.guildId or "dm"}`
	elseif per == "channel" then
		return `{commandName}:conc:channel:{interaction.channelId or "unknown"}`
	elseif per == "member" then
		return `{commandName}:conc:member:{interaction.guildId or "dm"}:{resolveInteractionUserId(interaction)}`
	end

	return `{commandName}:conc:global`
end

--[=[
	@within Commands.Cooldown

	Returns the maximum remaining cooldown in seconds across all rules, or nil if no cooldown is active.
]=]
local function checkCooldown(
	cooldowns: { [string]: number },
	commandName: string,
	rules: { command.CooldownRule },
	interaction: classes.TypesCommand
): number?
	local now = os.time()
	local maxRemaining: number? = nil

	for _, rule in rules do
		local key = buildCooldownKey(commandName, rule.per, interaction)
		local expiry = cooldowns[key]

		if expiry and now < expiry then
			local remaining = math.ceil(expiry - now)

			if maxRemaining == nil or remaining > maxRemaining then
				maxRemaining = remaining
			end
		end
	end

	return maxRemaining
end

--[=[
	@within Commands.Cooldown

	Records a cooldown expiry for each rule, keyed by the rule's `per` scope.
]=]
local function applyCooldown(
	cooldowns: { [string]: number },
	commandName: string,
	rules: { command.CooldownRule },
	interaction: classes.TypesCommand
)
	local now = os.time()

	for _, rule in rules do
		local key = buildCooldownKey(commandName, rule.per, interaction)

		cooldowns[key] = now + rule.seconds
	end
end

--[=[
	@within Commands.Cooldown

	Attempts to acquire a concurrency slot. Returns false if the limit for the scope is already reached.
]=]
local function acquireConcurrency(
	concurrency: { [string]: number },
	commandName: string,
	rule: { limit: number, per: "user" | "guild" | "channel" | "member" | "global" },
	interaction: classes.TypesCommand
): boolean
	local key = buildConcurrencyKey(commandName, rule.per, interaction)
	local current = concurrency[key] or 0

	if current >= rule.limit then
		return false
	end

	concurrency[key] = current + 1

	return true
end

--[=[
	@within Commands.Cooldown

	Releases a previously acquired concurrency slot.
]=]
local function releaseConcurrency(
	concurrency: { [string]: number },
	commandName: string,
	rule: { limit: number, per: "user" | "guild" | "channel" | "member" | "global" },
	interaction: classes.TypesCommand
)
	local key = buildConcurrencyKey(commandName, rule.per, interaction)
	local current = concurrency[key] or 0

	if current <= 1 then
		concurrency[key] = nil
	else
		concurrency[key] = current - 1
	end
end

return {
	checkCooldown = checkCooldown,
	applyCooldown = applyCooldown,
	acquireConcurrency = acquireConcurrency,
	releaseConcurrency = releaseConcurrency,
}
