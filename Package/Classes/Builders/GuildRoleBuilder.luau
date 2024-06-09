local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local PermissionsBuilder = require("@Builders/PermissionsBuilder")

local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Builders.GuildRoleBuilder

	Allows a developer to build a Guild Role

	```lua
	local DiscordGuild = GuildRoleBuilder.new()
		:setName("my-discord-role")
		:setColor(0xFF0000)
		:setHoisted(true)
		:setMentionable(false)
	```
]=]
local GuildRoleBuilder = {}

GuildRoleBuilder.Interface = {}
GuildRoleBuilder.Prototype = {}

GuildRoleBuilder.Prototype.type = "GuildRoleBuilder"

--[=[
	Sets the name of the Role
	
	@method setName
	@param name string
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setName(self: GuildRoleBuilder, name: string)
	self.name = name

	return self
end

--[=[
	Sets the color of the Role.
	
	@method setColor
	@param color number
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setColor(self: GuildRoleBuilder, color: number)
	self.color = color

	return self
end

--[=[
	Sets weather this role will split users in the roles hierarchy in the guild.
	
	@method setHoisted
	@param hoisted boolean
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setHoisted(self: GuildRoleBuilder, hoisted: boolean)
	self.hoist = hoisted

	return self
end

--[=[
	Sets the Icon for this role, the imageData should be a base64 encoded, 128x128 jpg file.
	
	@method setIcon
	@param imageData string
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setIcon(self: GuildRoleBuilder, imageData: string)
	self.icon = imageData

	return self
end

--[=[
	Sets the Emoji for this Role
	
	@method setUnicodeEmoji
	@param unicodeEmoji string
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setUnicodeEmoji(self: GuildRoleBuilder, unicodeEmoji: string)
	self.unicodeEmoji = unicodeEmoji

	return self
end

--[=[
	Set the position of this Role, this will update the roles hierarchy in the guild.
	
	@method setPosition
	@param position number
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setPosition(self: GuildRoleBuilder, position: number)
	self.position = position

	return self
end

--[=[
	Set if discord members can mention this Role.
	
	@method setMentionable
	@param mentionable boolean
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setMentionable(self: GuildRoleBuilder, mentionable: boolean)
	self.mentionable = mentionable

	return self
end

--[=[
	Set the flags for the Guild
	
	@method setFlags
	@param flags number
	@within Builders.GuildRoleBuilder
	@return Objects.GuildRoleBuilder
]=]
function GuildRoleBuilder.Prototype.setFlags(self: GuildRoleBuilder, flags: number)
	self.flags = flags

	return self
end

--[=[
	Converts the role to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.GuildRoleBuilder
	@return Network.Resolvable
]=]
function GuildRoleBuilder.Prototype.toPayloadObject(self: GuildRoleBuilder)
	return Resolvable.new(ResolvableType.JSON, {
		name = self.name,
		color = self.color,
		hoist = self.hoist,
		icon = self.icon,
		unicode_emoji = self.unicodeEmoji,
		position = self.position,
		permission = self.permissions:getValue(),
		mentionable = self.mentionable,
		flags = self.flags,
	})
end

--[=[
	Creates a new instance of GuildRoleBuilder.
	
	@function new
	@within Builders.GuildRoleBuilder
	@return Builders.GuildRoleBuilder -- A new instance of GuildRoleBuilder.
]=]
function GuildRoleBuilder.Interface.new()
	return (Construct({}, GuildRoleBuilder.Prototype) :: unknown) :: GuildRoleBuilder
end

export type GuildRoleBuilder = typeof(GuildRoleBuilder.Prototype) & {
	name: string,
	color: number,
	hoist: boolean,
	icon: string,
	unicodeEmoji: string,
	position: number,
	permissions: PermissionsBuilder.PermissionsBuilder,
	mentionable: boolean,
	flags: number,
}

return GuildRoleBuilder.Interface
