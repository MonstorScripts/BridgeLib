local RESOURCE_CORE = "qb-core"

---@type BridgeLib.UI.Client
local provider = {
	Notify = function(message, type)
		exports[RESOURCE_CORE]:GetCoreObject().Functions.Notify(message, type or "primary")
	end,

	ShowTextUI = function(text, options)
		exports[RESOURCE_CORE]:DrawText(text, options and options.position or "left")
	end,

	HideTextUI = function()
		exports[RESOURCE_CORE]:HideText()
	end,
}

return provider
