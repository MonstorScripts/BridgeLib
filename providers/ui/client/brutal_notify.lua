local RESOURCE_UI = "brutal_notify"

---The resource draws a title next to the message, which this module's contract has no room for, so
---each style supplies its own.
local KINDS = {
	success = { "success", "Success" },
	error = { "error", "Error" },
	inform = { "info", "Info" },
}

---@type BridgeLib.UI.Client
local provider = {
	Notify = function(message, type)
		local kind = KINDS[type] or KINDS.inform
		exports[RESOURCE_UI]:SendAlert(kind[2], message, 5000, kind[1], false)
	end,
}

return provider
