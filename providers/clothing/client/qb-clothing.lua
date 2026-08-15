---@type BridgeLib.Clothing.Client
local provider = {
	SetUniform = function(uniform)
		local outfitData = {}

		local function addPart(name, item, texture)
			if item ~= nil then
				outfitData[name] = { item = item, texture = texture or 0 }
			end
		end

		addPart("arms", uniform.arms, nil)
		addPart("pants", uniform.pants_1, uniform.pants_2)
		addPart("shoes", uniform.shoes_1, uniform.shoes_2)
		addPart("t-shirt", uniform.tshirt_1, uniform.tshirt_2)
		addPart("torso2", uniform.torso_1, uniform.torso_2)
		addPart("glass", uniform.glasses_1, uniform.glasses_2)
		addPart("ear", uniform.ears_1, uniform.ears_2)
		addPart("mask", uniform.mask_1, uniform.mask_2)
		addPart("hat", uniform.helmet_1, uniform.helmet_2)

		TriggerEvent("qb-clothing:client:loadOutfit", {
			outfitData = outfitData,
		})
	end,

	---qb-clothing stores the player's own skin, so the server reloads it rather than a snapshot.
	RevertUniform = function()
		TriggerServerEvent("qb-clothes:loadPlayerSkin")
	end,
}

return provider
