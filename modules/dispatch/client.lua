---@class BridgeLib.Dispatch.Alert
---@field title string
---@field message string Body text, already composed by the caller.
---@field jobs string[]? Jobs to alert, defaulting to police.
---@field blipText string? Blip label, defaulting to `title`.
---@field sprite number? Blip sprite, defaulting to the provider's own.

---Caller details the dispatch resource attaches to an alert.
---@class BridgeLib.Dispatch.PlayerInfo
---@field coords vector3
---@field street string
---@field sex string
---@field uniqueId any Whatever the dispatch resource uses to deduplicate alerts.

---Optional module: with no dispatch resource running, `SendPoliceAlert` is a no-op and
---`GetAlertPlayerInfo` falls back to the local player's coordinates and street.
---@class BridgeLib.Dispatch.Client
local schema = {
	---Sends an alert from the local player's position.
	---@param data BridgeLib.Dispatch.Alert
	SendPoliceAlert = function(data) end,

	---Caller details, for building the alert message.
	---@return BridgeLib.Dispatch.PlayerInfo
	GetAlertPlayerInfo = function()
		local coords = GetEntityCoords(PlayerPedId())
		return {
			coords = coords,
			street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)),
			sex = "person",
			uniqueId = nil,
		}
	end,
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
