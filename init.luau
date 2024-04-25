local DiscordLuau = require("Package")

do
    local net = require("@lune/net")
    local fs = require("@lune/fs")
    local process = require("@lune/process")
    local serde = require("@lune/serde")

    local homeDir: string

    if process.os == "windows" then
        homeDir = process.env["USERPROFILE"]
    else
        home = process.env["HOME"]
    end

    if homeDir == nil then
        error("ENGINE_DOWNLOAD_ERROR: Unrecognized platform " .. process.os)
    end

    local downloadDir = homeDir .. "/.discord-luau"
    local enginePath = downloadDir .. "/crypto-engine"

    if not fs.isDir(downloadDir) then
        fs.writeDir(downloadDir)
    end

    if not fs.isFile(enginePath) then
        local url = `https://github.com/4x8matrix/discord-luau-crypto-engine/releases/download/{DiscordLuau._VERSION}/crypto-engine-{process.os}-{process.arch}.gz`
        local resp = net.request(url)
        assert(resp.ok, "ENGINE_DOWNLOAD_ERROR: Failed to download engine, got status code " .. resp.statusCode)

        local decompressed = serde.decompress("gzip", resp.body)
        fs.writeFile(enginePath, decompressed)
        
        if process.os ~= "windows" then
            local chmod = process.spawn("chmod", { "+x", enginePath })
            assert(chmod.ok, "ENGINE_DOWNLOAD_ERROR: Failed to set executable permission on engine")
        end
    end
end

export type DiscordMessage = DiscordLuau.DiscordMessage
export type DiscordGuild = DiscordLuau.DiscordGuild
export type DiscordInteraction = DiscordLuau.DiscordInteraction



return DiscordLuau