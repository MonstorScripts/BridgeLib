---esx_status keeps its values on a 0 to 1,000,000 scale.
local SCALE = 10000

---@type BridgeLib.PlayerStatus.Server
local provider = {
	AddPlayerStatus = function(src, hunger, thirst)
		if hunger and hunger > 0 then
			TriggerClientEvent("esx_status:add", src, "food", hunger * SCALE)
		end

		if thirst and thirst > 0 then
			TriggerClientEvent("esx_status:add", src, "water", thirst * SCALE)
		end
	end,
}

return provider
