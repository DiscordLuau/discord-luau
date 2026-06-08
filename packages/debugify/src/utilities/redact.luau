local sensitiveSubstrings: { string } = {
	"token",
	"secret",
	"password",
	"authorization",
	"bearer",
	"credential",
	"api_key",
	"apikey",
}

local function isSensitiveKeyword(keyword: string): boolean
	local lowercaseKeyword = string.lower(keyword)

	for _, substring in sensitiveSubstrings do
		if string.find(lowercaseKeyword, substring, 1, true) then
			return true
		end
	end

	return false
end

local function sanitizeDiscordToken(text: string): string
	return (
		string.gsub(text, "[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+", function(match: string): string
			local firstDotPosition = string.find(match, ".", 1, true)

			if not firstDotPosition then
				return match
			end

			local secondDotPosition = string.find(match, ".", firstDotPosition + 1, true)

			if not secondDotPosition then
				return match
			end

			local partOne = string.sub(match, 1, firstDotPosition - 1)
			local partTwo = string.sub(match, firstDotPosition + 1, secondDotPosition - 1)
			local partThree = string.sub(match, secondDotPosition + 1)

			if #partOne >= 24 and #partTwo >= 6 and #partThree >= 27 then
				return string.rep("*", #partOne)
					.. "."
					.. string.rep("*", #partTwo)
					.. "."
					.. string.rep("*", #partThree)
			end

			return match
		end)
	)
end

local function sanitizeWebhookUrl(text: string): string
	return (
		string.gsub(text, "https?://[%S]-/webhooks/%d+/[A-Za-z0-9_%-]+", function(match: string): string
			local webhooksMarker = "/webhooks/"
			local webhooksPosition = string.find(match, webhooksMarker, 1, true)

			if not webhooksPosition then
				return match
			end

			local idStart = webhooksPosition + #webhooksMarker
			local slashPosition = string.find(match, "/", idStart, true)

			if not slashPosition then
				return match
			end

			local baseUrl = string.sub(match, 1, slashPosition)
			local token = string.sub(match, slashPosition + 1)

			return baseUrl .. string.rep("*", #token)
		end)
	)
end

local function sanitizeKeywordValues(text: string): string
	local withQuotedValues = (
		string.gsub(text, '[%a][%a%d_]*%s*[=:]%s*"[^"]+"', function(match: string): string
			local quotePosition = string.find(match, '"', 1, true)

			if not quotePosition then
				return match
			end

			local keyword = string.match(match, "^[%a][%a%d_]*")

			if not keyword or not isSensitiveKeyword(keyword) then
				return match
			end

			local prefix = string.sub(match, 1, quotePosition)
			local value = string.sub(match, quotePosition + 1, #match - 1)

			return prefix .. string.rep("*", #value) .. '"'
		end)
	)

	return (
		string.gsub(withQuotedValues, "[%a][%a%d_]*%s*[=:]%s*[^%s\"',;{}%[%]%(%)]+", function(match: string): string
			local keyword = string.match(match, "^[%a][%a%d_]*")

			if not keyword or not isSensitiveKeyword(keyword) then
				return match
			end

			local value = string.match(match, "[^%s\"',;{}%[%]%(%)]+$")

			if not value or #value < 8 then
				return match
			end

			local valueStart = #match - #value + 1

			return string.sub(match, 1, valueStart - 1) .. string.rep("*", #value)
		end)
	)
end

local function sanitize(text: string): string
	local result = sanitizeDiscordToken(text)

	result = sanitizeWebhookUrl(result)
	result = sanitizeKeywordValues(result)

	return result
end

return { sanitize = sanitize }
