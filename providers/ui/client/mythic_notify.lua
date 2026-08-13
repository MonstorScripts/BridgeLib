local RESOURCE_UI = "mythic_notify"

---@type BridgeLib.UI.Client
local provider = {
	Notify = function(message, type)
		exports[RESOURCE_UI]:SendAlert(type or "inform", message, 5000)
	end,
}

return provider
