local RESOURCE_CLOTHING = "tgiann-clothing"

---Every component the resource takes, in the order it expects them. A uniform that names none of a
---pair still has to send one, or the piece it replaces stays on the ped.
local COMPONENTS = {
	{ "tshirt_1", "tshirt_1" },
	{ "tshirt_2", "tshirt_2" },
	{ "torso_1", "torso_1" },
	{ "torso_2", "torso_2" },
	{ "decals_1", "decals_1" },
	{ "decals_2", "decals_2" },
	{ "arms_1", "arms" },
	{ "arms_2", nil },
	{ "pants_1", "pants_1" },
	{ "pants_2", "pants_2" },
	{ "shoes_1", "shoes_1" },
	{ "shoes_2", "shoes_2" },
	{ "helmet_1", "helmet_1" },
	{ "helmet_2", "helmet_2" },
	{ "chain_1", "chain_1" },
	{ "chain_2", "chain_2" },
	{ "ears_1", "ears_1" },
	{ "ears_2", "ears_2" },
	{ "mask_1", "mask_1" },
	{ "mask_2", "mask_2" },
	{ "glasses_1", "glasses_1" },
	{ "glasses_2", "glasses_2" },
	{ "bags_1", nil },
	{ "bags_2", nil },
	{ "watches_1", nil },
	{ "watches_2", nil },
	{ "bracelets_1", nil },
	{ "bracelets_2", nil },
	{ "bproof_1", nil },
	{ "bproof_2", nil },
}

---@type BridgeLib.Clothing.Client
local provider = {
	SetUniform = function(uniform)
		local clothes = {}
		for index, component in ipairs(COMPONENTS) do
			local field = component[2]
			clothes[index] = { name = component[1], val = (field and uniform[field]) or 0 }
		end
		exports[RESOURCE_CLOTHING]:ChangeScriptClothe(clothes)
	end,

	---The resource restores the stored outfit when it is handed nothing.
	RevertUniform = function()
		exports[RESOURCE_CLOTHING]:ChangeScriptClothe()
	end,
}

return provider
