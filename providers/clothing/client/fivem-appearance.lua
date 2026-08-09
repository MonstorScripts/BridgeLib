local RESOURCE_CLOTHING = "fivem-appearance"

---@type table?
local saved = nil

---@param uniform BridgeLib.Clothing.Uniform
---@return table
local function components(uniform)
	return {
		{ component_id = 3, drawable = uniform.arms, texture = 0 },
		{ component_id = 4, drawable = uniform.pants_1, texture = uniform.pants_2 },
		{ component_id = 6, drawable = uniform.shoes_1, texture = uniform.shoes_2 },
		{ component_id = 7, drawable = uniform.chain_1, texture = uniform.chain_2 },
		{ component_id = 8, drawable = uniform.tshirt_1, texture = uniform.tshirt_2 },
		{ component_id = 11, drawable = uniform.torso_1, texture = uniform.torso_2 },
		{
			props = {
				{ prop_id = 1, drawable = uniform.glasses_1 or 0, texture = uniform.glasses_2 or 0 },
				{ prop_id = 2, drawable = uniform.ears_1 or 0, texture = uniform.ears_2 or 0 },
			},
		},
	}
end

---@type BridgeLib.Clothing.Client
local provider = {
	SetUniform = function(uniform)
		local ped = PlayerPedId()
		saved = saved or exports[RESOURCE_CLOTHING]:getPedAppearance(ped)
		exports[RESOURCE_CLOTHING]:setPedComponents(ped, components(uniform))
	end,

	RevertUniform = function()
		if not saved then
			return
		end

		exports[RESOURCE_CLOTHING]:setPedAppearance(PlayerPedId(), saved)
		saved = nil
	end,
}

return provider
