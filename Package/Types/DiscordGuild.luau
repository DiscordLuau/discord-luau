export type DiscordGuild = {
	id: string,
	name: string,
	icon: string,
	iconHash: string?,
	description: string?,
	splash: string,
	discoverySplash: string?,
	approximateMemberCount: number,
	approximatePresenceCount: number,
	features: { string },
	emojis: { unknown }, -- fixme: implement DiscordEmoji type!
	banner: string,
	ownerId: string,
	owner: boolean,
	permissions: string,
	region: string,

	[any]: any -- sorry, I got lazy here - types can be found here lol 
	-- https://discord.com/developers/docs/resources/guild#guild-object
}

return "DiscordGuild"