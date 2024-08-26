--[[
	Wrapper around the Discord interaction framework, allowing developers to create interactions with ease
	instead of worrying about builders/objects & data.
]]

local bot = require("@core/bot")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

function Interaction.Interface.new(bot: bot.Bot)
	return setmetatable({} :: Interaction, { __index = Interaction.Prototype })
end

export type Interaction = typeof(Interaction.Prototype) & {}

return Interaction
