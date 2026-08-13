---esx_status keeps its values on a 0 to 1,000,000 scale.
local SCALE = 10000

---@type BridgeLib.PlayerStatus.Client
local provider = {
	GetPlayerStatus = function()
		local result = promise.new()

		TriggerEvent("esx_status:getStatuses", function(statuses)
			local hunger, thirst = 0, 0

			for _, status in ipairs(statuses or {}) do
				if status.name == "food" then
					hunger = math.floor(status.val / SCALE)
				elseif status.name == "water" then
					thirst = math.floor(status.val / SCALE)
				end
			end

			result:resolve({ hunger, thirst })
		end)

		local statuses = Citizen.Await(result)
		return statuses[1], statuses[2]
	end,
}

return provider
