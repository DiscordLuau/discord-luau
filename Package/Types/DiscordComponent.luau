local ActionRowComponent = require("../Classes/Interface/ActionRowComponent")
local ButtonComponent = require("../Classes/Interface/ButtonComponent")
local SelectionComponent = require("../Classes/Interface/SelectionComponent")
local TextInputComponent = require("../Classes/Interface/TextInputComponent")

export type DiscordComponent = ActionRowComponent.ActionRowComponent
	| ButtonComponent.ButtonComponent
	| SelectionComponent.SelectionComponent
	| TextInputComponent.TextInputComponent

return "DiscordComponent"