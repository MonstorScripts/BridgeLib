local RESOURCE_DISPATCH = "cd_dispatch"

---@type BridgeLib.Dispatch.Client
local provider = {
	SendPoliceAlert = function(data)
		local info = exports[RESOURCE_DISPATCH]:GetPlayerInfo()
		TriggerServerEvent("cd_dispatch:AddNotification", {
			job_table = data.jobs or { "police" },
			coords = info.coords,
			title = data.title,
			message = data.message .. " at " .. info.street,
			flash = 0,
			unique_id = info.unique_id,
			sound = 1,
			blip = {
				sprite = 431,
				scale = 1.2,
				colour = 3,
				flashes = false,
				text = data.blipText or data.message,
				time = 5,
				radius = 0,
			},
		})
	end,
}

return provider
