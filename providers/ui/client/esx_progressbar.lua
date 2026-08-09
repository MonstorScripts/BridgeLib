local RESOURCE_PROGRESS = "esx_progressbar"

---@type BridgeLib.UI.Client
local provider = {
	---esx_progressbar cannot be cancelled, so this always reports the action as completed.
	ProgressBar = function(label, duration)
		local finished = promise.new()

		exports[RESOURCE_PROGRESS]:Progressbar(label, duration, {
			FreezePlayer = true,
			onFinish = function()
				finished:resolve(true)
			end,
		})

		return Citizen.Await(finished)
	end,
}

return provider
