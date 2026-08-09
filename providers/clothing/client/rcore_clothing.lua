local RESOURCE_CLOTHING = "rcore_clothing"

---A prop the uniform does not name is taken off with -1; a component with 0.
local COMPONENTS = {
	{ "tshirt_1", "tshirt_1", 0 },
	{ "tshirt_2", "tshirt_2", 0 },
	{ "torso_1", "torso_1", 0 },
	{ "torso_2", "torso_2", 0 },
	{ "decals_1", "decals_1", 0 },
	{ "decals_2", "decals_2", 0 },
	{ "arms", "arms", 0 },
	{ "pants_1", "pants_1", 0 },
	{ "pants_2", "pants_2", 0 },
	{ "shoes_1", "shoes_1", 0 },
	{ "shoes_2", "shoes_2", 0 },
	{ "helmet_1", "helmet_1", -1 },
	{ "helmet_2", "helmet_2", 0 },
	{ "chain_1", "chain_1", 0 },
	{ "chain_2", "chain_2", 0 },
	{ "ears_1", "ears_1", -1 },
	{ "ears_2", "ears_2", 0 },
	{ "mask_1", "mask_1", 0 },
	{ "mask_2", "mask_2", 0 },
	{ "glasses_1", "glasses_1", -1 },
	{ "glasses_2", "glasses_2", 0 },
	{ "bags_1", nil, 0 },
	{ "bags_2", nil, 0 },
	{ "watches_1", nil, -1 },
	{ "watches_2", nil, 0 },
	{ "bracelets_1", nil, -1 },
	{ "bracelets_2", nil, 0 },
	{ "bproof_1", nil, 0 },
	{ "bproof_2", nil, 0 },
}

---@type BridgeLib.Clothing.Client
local provider = {
	SetUniform = function(uniform)
		local skin = {}
		for index, component in ipairs(COMPONENTS) do
			local field = component[2]
			skin[index] = { name = component[1], val = (field and uniform[field]) or component[3] }
		end

		exports[RESOURCE_CLOTHING]:setPedSkin(PlayerPedId(), skin)
	end,

	---rcore_clothing stores the player's own skin, so the server reloads it rather than a snapshot.
	RevertUniform = function()
		TriggerServerEvent("rcore_clothing:reloadSkin")
	end,
}

return provider
