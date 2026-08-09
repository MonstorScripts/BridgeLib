---@type BridgeLib.UI.Client
local provider = {
	Notify = function(message, type)
		lib.notify({
			description = message,
			type = type or "inform",
		})
	end,

	ProgressBar = function(label, duration, canCancel)
		return lib.progressBar({
			label = label,
			duration = duration,
			canCancel = canCancel ~= false,
			useWhileDead = false,
			allowSwimming = true,
			disable = { move = true },
		}) and true or false
	end,

	ShowTextUI = function(text, options)
		lib.showTextUI(text, options)
	end,

	HideTextUI = function()
		lib.hideTextUI()
	end,
}

return provider
