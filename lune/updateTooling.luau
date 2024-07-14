--> Updates aftman managed tooling -- lune run task updateTooling

local process = require("@lune/process")
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local net = require("@lune/net")
local datetime = require("@lune/datetime")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local shared = require("shared")

type AftmanManifest = {
	tools: {
		[string]: string,
	},
}

type GithubReleases = {
	{
		url: string,
		assets_url: string,
		upload_url: string,
		html_url: string,
		id: number,
		tag_name: string,
		target_commitish: string,
		created_at: string,
		published_at: string,
		assets: {
			{
				url: string,
				id: string,
				name: string,
				content_type: string,
				size: string,
				download_count: string,
				created_at: string,
				updated_at: string,
			}
		},
	}
}

local function updateTooling(args: { string }, task: shared.TaskEnv): number
	local manifest: AftmanManifest = serde.decode("toml", fs.readFile("aftman.toml"))

	for alias, tool in manifest.tools do
		local path, version = string.match(tool, "^(%S+)@(%d+.%d+.%d+)$")

		if path == nil or version == nil then
			task.logger.error("Invalid aftman manifest format")
			return 1
		end

		local ok, ghToken = pcall(process.spawn, "gh", { "auth", "token" })
		local releaseResp = net.request({
			url = `https://api.github.com/repos/{path}/releases`,
			headers = {
				Authorization = `Bearer {string.gsub(ghToken.stdout, "%c", "")}`,
			},
		})
		if not releaseResp.ok then
			task.logger.error("Failed to fetch tags list from GitHub API")
			return 1
		end

		local releasesList: GithubReleases = serde.decode("json", releaseResp.body)
		table.sort(releasesList, function(a, b)
			local aDate = datetime.fromIsoDate(a.published_at)
			local bDate = datetime.fromIsoDate(b.published_at)
			return aDate.unixTimestamp > bDate.unixTimestamp
		end)

		local latestVersion = string.gsub(releasesList[1].tag_name, "v", "")
		if version ~= latestVersion then
			task.logger.info(`Updating {alias} {version}->{latestVersion}`)
			manifest.tools[alias] = `{path}@{latestVersion}`
		end
	end

	stdio.write("\n")

	local toUpdateManifest = stdio.prompt("confirm", "Update aftman.toml?")
	if toUpdateManifest then
		fs.writeFile("aftman.toml", serde.encode("toml", manifest))
	end

	print("Please run `aftman install` to install the updated tooling.")

	return 0
end

return updateTooling
