---@type BridgeLib.Clothing.Client
local provider = {
	SetUniform = function(uniform)
		TriggerEvent("qb-clothing:client:loadOutfit", {
			outfitData = {
				["arms"] = { item = uniform.arms, texture = 0 },
				["pants"] = { item = uniform.pants_1, texture = uniform.pants_2 },
				["shoes"] = { item = uniform.shoes_1, texture = uniform.shoes_2 },
				["t-shirt"] = { item = uniform.tshirt_1, texture = uniform.tshirt_2 },
				["torso2"] = { item = uniform.torso_1, texture = uniform.torso_2 },
				["glass"] = { item = uniform.glasses_1, texture = uniform.glasses_2 },
				["ear"] = { item = uniform.ears_1, texture = uniform.ears_2 },
				["mask"] = { item = uniform.mask_1, texture = uniform.mask_2 },
				["hat"] = { item = uniform.helmet_1, texture = uniform.helmet_2 },
			},
		})
	end,

	---qb-clothing stores the player's own skin, so the server reloads it rather than a snapshot.
	RevertUniform = function()
		TriggerServerEvent("qb-clothes:loadPlayerSkin")
	end,
}

return provider
