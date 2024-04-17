export type DiscordMessage = {
	mentionRoles: { string },
	attachments: { unknown }, -- fixme: add Attachment support!
	embeds: { unknown }, -- fixme: add Embed support!
	tts: boolean,
	mentionEveryone: boolean,
	nonce: string,
	id: string,
	author: {
		username: string,
		globalName: string,
		avatar: string,
		id: string,
		publicFlags: number,
		discriminator: string,
	},
	content: string,
	mentions: { string },
	flags: number,
	timestamp: string,
	type: number,
	pinned: boolean,
	guildId: boolean,
	channelId: boolean,
	components: { unknown }, -- fixme: implement Component support!
	member: {
		flags: number,
		deaf: boolean,
		roles: { [string]: string },
		pending: boolean,
		mute: boolean,
		joinedAt: string
	}
}

return "DiscordMessage"