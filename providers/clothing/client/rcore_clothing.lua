local RESOURCE_CLOTHING = "rcore_clothing"

local COMPONENTS = {
	{ "tshirt_1", "tshirt_1", 8 }, { "tshirt_2", "tshirt_2", 8, false, true },
	{ "torso_1", "torso_1", 11 }, { "torso_2", "torso_2", 11, false, true },
	{ "decals_1", "decals_1", 10 }, { "decals_2", "decals_2", 10, false, true },
	{ "arms", "arms", 3 },
	{ "pants_1", "pants_1", 4 }, { "pants_2", "pants_2", 4, false, true },
	{ "shoes_1", "shoes_1", 6 }, { "shoes_2", "shoes_2", 6, false, true },
	{ "helmet_1", "helmet_1", 0, true }, { "helmet_2", "helmet_2", 0, true, true },
	{ "chain_1", "chain_1", 7 }, { "chain_2", "chain_2", 7, false, true },
	{ "ears_1", "ears_1", 2, true }, { "ears_2", "ears_2", 2, true, true },
	{ "mask_1", "mask_1", 1 }, { "mask_2", "mask_2", 1, false, true },
	{ "glasses_1", "glasses_1", 1, true }, { "glasses_2", "glasses_2", 1, true, true },
	{ "bags_1", nil, 5 }, { "bags_2", nil, 5, false, true },
	{ "watches_1", nil, 6, true }, { "watches_2", nil, 6, true, true },
	{ "bracelets_1", nil, 7, true }, { "bracelets_2", nil, 7, true, true },
	{ "bproof_1", nil, 9 }, { "bproof_2", nil, 9, false, true },
}

local function currentValue(ped, component)
	local id, prop, texture = component[3], component[4], component[5]
	if prop then
		return texture and GetPedPropTextureIndex(ped, id) or GetPedPropIndex(ped, id)
	end
	return texture and GetPedTextureVariation(ped, id) or GetPedDrawableVariation(ped, id)
end

---@type BridgeLib.Clothing.Client
local provider = {
	SetUniform = function(uniform)
		local ped = PlayerPedId()
		local skin = {}
		for index, component in ipairs(COMPONENTS) do
			local field = component[2]
			skin[index] = { name = component[1], val = (field and uniform[field]) or currentValue(ped, component) }
		end

		exports[RESOURCE_CLOTHING]:setPedSkin(ped, skin)
	end,

	---rcore_clothing stores the player's own skin, so the server reloads it rather than a snapshot.
	RevertUniform = function()
		TriggerServerEvent("rcore_clothing:reloadSkin")
	end,
}

return provider
