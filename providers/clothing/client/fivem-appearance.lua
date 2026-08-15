local RESOURCE_CLOTHING = "fivem-appearance"

---@type table?
local saved = nil

---@param uniform BridgeLib.Clothing.Uniform
---@return table
local function components(uniform)
	local result = {}
	local props = {}

	local function addComponent(componentId, drawable, texture)
		if drawable ~= nil then
			result[#result + 1] = { component_id = componentId, drawable = drawable, texture = texture or 0 }
		end
	end

	local function addProp(propId, drawable, texture)
		if drawable ~= nil then
			props[#props + 1] = { prop_id = propId, drawable = drawable, texture = texture or 0 }
		end
	end

	addComponent(3, uniform.arms, nil)
	addComponent(4, uniform.pants_1, uniform.pants_2)
	addComponent(6, uniform.shoes_1, uniform.shoes_2)
	addComponent(7, uniform.chain_1, uniform.chain_2)
	addComponent(8, uniform.tshirt_1, uniform.tshirt_2)
	addComponent(11, uniform.torso_1, uniform.torso_2)
	addProp(1, uniform.glasses_1, uniform.glasses_2)
	addProp(2, uniform.ears_1, uniform.ears_2)

	if #props > 0 then
		result[#result + 1] = { props = props }
	end

	return result
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
