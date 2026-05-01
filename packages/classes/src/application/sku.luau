--[=[
	@class Classes.Application.Sku
	@__index Prototype

	Implementation of the Discord SKU class in Luau.

	https://discord.com/developers/docs/monetization/skus#sku-object
]=]

--[=[
	@prop id string
	@within Classes.Application.Sku
]=]

--[=[
	@prop type number
	@within Classes.Application.Sku
]=]

--[=[
	@prop applicationId string
	@within Classes.Application.Sku
]=]

--[=[
	@prop name string
	@within Classes.Application.Sku
]=]

--[=[
	@prop slug string
	@within Classes.Application.Sku
]=]

--[=[
	@prop flags number
	@within Classes.Application.Sku
]=]

local apiTypes = require("../../luau_packages/api_types")

local Sku = {}

Sku.Interface = {}
Sku.Prototype = {}

--[=[
	@within Classes.Application.Sku
	@private
]=]
function Sku.Prototype.sync(self: Sku, skuData: apiTypes.SkuObject)
	self.id = skuData.id
	self.type = skuData.type
	self.applicationId = skuData.application_id
	self.name = skuData.name
	self.slug = skuData.slug
	self.flags = skuData.flags
end

--[=[
	@within Classes.Application.Sku
	@private
]=]
function Sku.Interface.new(skuData: apiTypes.SkuObject): Sku
	local self = setmetatable({} :: Sku, { __index = Sku.Prototype })

	self:sync(skuData)

	return self
end

export type Sku = typeof(Sku.Prototype) & {
	id: apiTypes.Snowflake,
	type: number,
	applicationId: apiTypes.Snowflake,
	name: string,
	slug: string,
	flags: number,
}

return Sku.Interface
