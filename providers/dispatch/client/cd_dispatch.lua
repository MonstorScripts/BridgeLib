local RESOURCE_DISPATCH = "cd_dispatch"

---@return BridgeLib.Dispatch.PlayerInfo
local function getPlayerInfo()
	local info = exports[RESOURCE_DISPATCH]:GetPlayerInfo()
	return {
		coords = info.coords,
		street = info.street,
		sex = info.sex,
		uniqueId = info.unique_id,
	}
end

---@type BridgeLib.Dispatch.Client
local provider = {
	GetAlertPlayerInfo = getPlayerInfo,

	SendPoliceAlert = function(data)
		local info = getPlayerInfo()
		TriggerServerEvent("cd_dispatch:AddNotification", {
			job_table = data.jobs or { "police" },
			coords = info.coords,
			title = data.title,
			message = data.message,
			flash = 0,
			unique_id = info.uniqueId,
			sound = 1,
			blip = {
				sprite = data.sprite or 431,
				scale = 1.2,
				colour = 3,
				flashes = false,
				text = data.blipText or data.title,
				time = 5,
				radius = 0,
			},
		})
	end,
}

return provider
