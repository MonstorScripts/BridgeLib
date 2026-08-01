---@class BridgeLib.Dispatch.Alert
---@field title string
---@field message string Body text. Providers may append the caller's street.
---@field jobs string[]? Jobs to alert, defaulting to police.
---@field blipText string? Blip label, defaulting to `message`.

---Optional module: with no dispatch resource running, the stub is a no-op.
---@class BridgeLib.Dispatch.Client
local schema = {
	---Sends an alert from the local player's position.
	---@param data BridgeLib.Dispatch.Alert
	SendPoliceAlert = function(data) end,
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
