--[=[
	@class Builders.GuildScheduledEventRecurrenceRule
	@__index Prototype

	Implementation of Discord's Guild Scheduled Event Recurrence Rule object as a Luau builder.

	https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-recurrence-rule-object
]=]

local apiTypes = require("../../luau_packages/api_types")

local GuildScheduledEventRecurrenceRule = {}

GuildScheduledEventRecurrenceRule.Prototype = {}
GuildScheduledEventRecurrenceRule.Interface = {}

function GuildScheduledEventRecurrenceRule.Prototype.setStart(
	self: GuildScheduledEventRecurrenceRule,
	startTime: string
): GuildScheduledEventRecurrenceRule
	self.start = startTime
	return self
end

function GuildScheduledEventRecurrenceRule.Prototype.setFrequency(
	self: GuildScheduledEventRecurrenceRule,
	frequency: apiTypes.RecurrenceRuleFrequency
): GuildScheduledEventRecurrenceRule
	assert(apiTypes.guild.RecurrenceRuleFrequency[frequency], "Invalid recurrence rule frequency")
	self.frequency = frequency
	return self
end

function GuildScheduledEventRecurrenceRule.Prototype.setInterval(
	self: GuildScheduledEventRecurrenceRule,
	interval: number
): GuildScheduledEventRecurrenceRule
	assert(interval >= 1, "Interval must be at least 1")
	self.interval = interval
	return self
end

function GuildScheduledEventRecurrenceRule.Prototype.setByWeekday(
	self: GuildScheduledEventRecurrenceRule,
	weekdays: { apiTypes.RecurrenceRuleWeekday }
): GuildScheduledEventRecurrenceRule
	self.byWeekday = weekdays
	return self
end

function GuildScheduledEventRecurrenceRule.Prototype.setByNWeekday(
	self: GuildScheduledEventRecurrenceRule,
	nWeekdays: {
		{
			n: number,
			day: apiTypes.RecurrenceRuleWeekday,
		}
	}
): GuildScheduledEventRecurrenceRule
	self.byNWeekday = nWeekdays
	return self
end

function GuildScheduledEventRecurrenceRule.Prototype.setByMonth(
	self: GuildScheduledEventRecurrenceRule,
	months: { apiTypes.RecurrenceRuleMonth }
): GuildScheduledEventRecurrenceRule
	self.byMonth = months
	return self
end

function GuildScheduledEventRecurrenceRule.Prototype.setByMonthDay(
	self: GuildScheduledEventRecurrenceRule,
	days: { number }
): GuildScheduledEventRecurrenceRule
	for _, day in days do
		assert(day >= 1 and day <= 31, "Month day must be between 1 and 31")
	end
	self.byMonthDay = days
	return self
end

function GuildScheduledEventRecurrenceRule.Prototype.build(self: GuildScheduledEventRecurrenceRule): JSON
	assert(self.start, "Recurrence rule is missing a start time")
	assert(self.frequency, "Recurrence rule is missing a frequency")
	assert(self.interval, "Recurrence rule is missing an interval")

	local byWeekday: { number }? = nil
	if self.byWeekday then
		local arr: { number } = {}
		for _, day in self.byWeekday do
			table.insert(arr, apiTypes.guild.RecurrenceRuleWeekday[day])
		end
		byWeekday = arr
	end

	local byNWeekday: { { n: number, day: number } }? = nil
	if self.byNWeekday then
		local arr: { { n: number, day: number } } = {}
		for _, entry in self.byNWeekday do
			table.insert(arr, { n = entry.n, day = apiTypes.guild.RecurrenceRuleWeekday[entry.day] })
		end
		byNWeekday = arr
	end

	local byMonth: { number }? = nil
	if self.byMonth then
		local arr: { number } = {}
		for _, month in self.byMonth do
			table.insert(arr, apiTypes.guild.RecurrenceRuleMonth[month])
		end
		byMonth = arr
	end

	return {
		start = self.start,
		frequency = apiTypes.guild.RecurrenceRuleFrequency[self.frequency],
		interval = self.interval,
		by_weekday = byWeekday,
		by_n_weekday = byNWeekday,
		by_month = byMonth,
		by_month_day = self.byMonthDay,
	}
end

function GuildScheduledEventRecurrenceRule.Interface.new(resource: {
	start: string?,
	frequency: apiTypes.RecurrenceRuleFrequency?,
	interval: number?,
	byWeekday: { apiTypes.RecurrenceRuleWeekday }?,
	byNWeekday: { { n: number, day: apiTypes.RecurrenceRuleWeekday } }?,
	byMonth: { apiTypes.RecurrenceRuleMonth }?,
	byMonthDay: { number }?,
}?): GuildScheduledEventRecurrenceRule
	local self =
		setmetatable({} :: GuildScheduledEventRecurrenceRule, { __index = GuildScheduledEventRecurrenceRule.Prototype })

	if resource then
		if resource.start then
			self:setStart(resource.start)
		end
		if resource.frequency then
			self:setFrequency(resource.frequency)
		end
		if resource.interval then
			self:setInterval(resource.interval)
		end
		if resource.byWeekday then
			self:setByWeekday(resource.byWeekday)
		end
		if resource.byNWeekday then
			self:setByNWeekday(resource.byNWeekday)
		end
		if resource.byMonth then
			self:setByMonth(resource.byMonth)
		end
		if resource.byMonthDay then
			self:setByMonthDay(resource.byMonthDay)
		end
	end

	return self
end

export type GuildScheduledEventRecurrenceRule = typeof(GuildScheduledEventRecurrenceRule.Prototype) & {
	start: string?,
	frequency: apiTypes.RecurrenceRuleFrequency?,
	interval: number?,
	byWeekday: { apiTypes.RecurrenceRuleWeekday }?,
	byNWeekday: { { n: number, day: apiTypes.RecurrenceRuleWeekday } }?,
	byMonth: { apiTypes.RecurrenceRuleMonth }?,
	byMonthDay: { number }?,
}

export type JSON = typeof(GuildScheduledEventRecurrenceRule.Prototype.build(nil :: any))

return GuildScheduledEventRecurrenceRule.Interface
