---A set of clothing components, named the way both frameworks' skin tables name them. Every field is
---optional; a provider writes the ones its resource understands and leaves the rest alone.
---@class BridgeLib.Clothing.Uniform
---@field tshirt_1 number?
---@field tshirt_2 number?
---@field torso_1 number?
---@field torso_2 number?
---@field decals_1 number?
---@field decals_2 number?
---@field arms number?
---@field pants_1 number?
---@field pants_2 number?
---@field shoes_1 number?
---@field shoes_2 number?
---@field helmet_1 number?
---@field helmet_2 number?
---@field chain_1 number?
---@field chain_2 number?
---@field ears_1 number?
---@field ears_2 number?
---@field glasses_1 number?
---@field glasses_2 number?
---@field mask_1 number?
---@field mask_2 number?

---Optional module: with no clothing resource running, a uniform is never put on and reverting is a
---no-op, so the player keeps whatever they are already wearing.
---
---Providers snapshot the player before the first uniform goes on and restore that snapshot on
---`RevertUniform`, so a caller never has to keep the original look itself.
---@class BridgeLib.Clothing.Client
local schema = {
	---Dresses the local player, keeping whatever the uniform does not name.
	---@param uniform BridgeLib.Clothing.Uniform
	SetUniform = function(uniform) end,

	---Puts the player back in what they wore before the first `SetUniform`.
	RevertUniform = function() end,
}

---@type BridgeLib.Module
return {
	name = "clothing",
	context = "client",
	providers = {
		"illenium-appearance",
		"fivem-appearance",
		"tgiann-clothing",
		"rcore_clothing",
		"qb-clothing",
		"esx_skin",
	},
	schema = schema,
}
