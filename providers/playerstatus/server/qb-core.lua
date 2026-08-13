local RESOURCE_CORE = "qb-core"

---@type BridgeLib.PlayerStatus.Server
local provider = {
	AddPlayerStatus = function(src, hunger, thirst)
		local player = exports[RESOURCE_CORE]:GetCoreObject().Functions.GetPlayer(src)
		if not player then
			return
		end

		local metadata = player.PlayerData.metadata or {}
		local newHunger = math.min(100, (metadata.hunger or 0) + (hunger or 0))
		local newThirst = math.min(100, (metadata.thirst or 0) + (thirst or 0))

		player.Functions.SetMetaData("hunger", newHunger)
		player.Functions.SetMetaData("thirst", newThirst)
		TriggerClientEvent("hud:client:UpdateNeeds", src, newHunger, newThirst)
	end,
}

return provider
