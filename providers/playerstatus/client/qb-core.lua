local RESOURCE_CORE = "qb-core"

---@type BridgeLib.PlayerStatus.Client
local provider = {
	GetPlayerStatus = function()
		local playerData = exports[RESOURCE_CORE]:GetCoreObject().Functions.GetPlayerData()
		local metadata = playerData and playerData.metadata

		if type(metadata) ~= "table" then
			return 0, 0
		end

		return metadata.hunger or 0, metadata.thirst or 0
	end,
}

return provider
