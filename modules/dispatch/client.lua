---@class BridgeLib.Dispatch.Alert
---@field title string
---@field message string
---@field jobs string[]?
---@field blipText string?

---@class BridgeLib.Dispatch.Client
local schema = {
	---@param data BridgeLib.Dispatch.Alert
	SendPoliceAlert = function() end,
}

---@type BridgeLib.Module
return {
	name = "dispatch",
	context = "client",
	providers = {
		"cd_dispatch",
	},
	schema = schema,
}
