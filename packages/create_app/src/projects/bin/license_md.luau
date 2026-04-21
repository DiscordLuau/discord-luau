local StdPolyfills = require("../../../luau_packages/std_polyfills")

return function(license: string, projectName: string)
	local scope = string.match(projectName, "^[^/]+") or projectName
	local currentYear = string.sub(StdPolyfills.datetime.now():toIsoDate(), 1, 4)

	local response = StdPolyfills.net.request({
		url = `https://api.github.com/licenses/{string.lower(license)}`,
		method = "GET",
		headers = {
			["Accept"] = "application/vnd.github+json",
			["X-GitHub-Api-Version"] = "2022-11-28",
			["User-Agent"] = "DiscordLuau/create_app",
		},
	})

	if not response.ok then
		return `# LICENSE\n\n{license}\n\nSee https://choosealicense.com for the full license text.\n`
	end

	local data = StdPolyfills.serde.decode("json", response.body)
	local body = data.body or `# LICENSE\n\n{license}\n\nSee https://choosealicense.com for the full license text.\n`

	body = string.gsub(body, "%[year%]", currentYear)
	body = string.gsub(body, "%[fullname%]", scope)

	return body :: string
end
