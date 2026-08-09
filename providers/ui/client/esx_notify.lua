local RESOURCE_UI = "esx_notify"

local KINDS = {
	success = "success",
	error = "error",
	inform = "info",
}

---@type BridgeLib.UI.Client
local provider = {
	Notify = function(message, type)
		exports[RESOURCE_UI]:Notify(KINDS[type] or "info", 4000, message)
	end,
}

return provider
