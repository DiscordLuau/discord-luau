export type DiscordMessage = {
	mentionRoles: { string },
	-- attachments: { unknown },
	-- embeds: { unknown },
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
	-- components: { unknown },
	member: {
		flags: number,
		deaf: boolean,
		roles: { [string]: string },
		pending: boolean,
		mute: boolean,
		joinedAt: string
	},

	replyAsync: (self: DiscordMessage, messageData: MessageSchema) -> ()
}

export type MessageSchema = {
	content: string?,
	nonce: (string | number)?,
	tts: boolean?,
	-- embeds: { unknown },
	-- allowedMentions: { unknown },
	-- messageReference: {  },
	-- components: { unknown },
	stickerIds: { string }?,
	-- files: { unknown },
	-- payloadJson: { unknown }
	-- attachments: { unknown }
	flags: number?,
	enforceNonce: boolean?
}

return "DiscordMessage"