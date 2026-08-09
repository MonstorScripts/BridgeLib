local RESOURCE_UI = "lation_ui"

---@type BridgeLib.UI.Client
local provider = {
	Notify = function(message, type)
		exports[RESOURCE_UI]:notify({
			message = message,
			type = type or "info",
		})
	end,

	ProgressBar = function(label, duration, canCancel)
		return exports[RESOURCE_UI]:progressBar({
			label = label,
			duration = duration,
			canCancel = canCancel ~= false,
			useWhileDead = false,
			allowSwimming = true,
			disable = { move = true },
		}) and true or false
	end,

	ShowTextUI = function(text, options)
		exports[RESOURCE_UI]:showText({
			description = text,
			icon = options and options.icon,
			position = options and options.position,
		})
	end,

	HideTextUI = function()
		exports[RESOURCE_UI]:hideText()
	end,
}

return provider
