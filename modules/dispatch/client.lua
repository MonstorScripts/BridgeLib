---@class BridgeLib.Dispatch.Alert
---@field title string
---@field message string Body text, already composed by the caller.
---@field jobs string[]? Jobs to alert, defaulting to police.
---@field blipText string? Blip label, defaulting to `title`.
---@field sprite number? Blip sprite, defaulting to the provider's own.
---@field scale number? Blip scale, for the providers that size their own blip.
---@field colour number? Blip colour, for the providers that colour their own blip.
---@field code string? Short call code, e.g. "10-31".
---@field codeName string? Internal name of the call, for the providers that key alerts by one.
---@field description string? One line describing the call, shown next to `code`.
---@field priority number? Call priority, where the provider ranks its calls.

---Caller details the dispatch resource attaches to an alert.
---@class BridgeLib.Dispatch.PlayerInfo
---@field coords vector3
---@field street string
---@field sex string
---@field uniqueId any Whatever the dispatch resource uses to deduplicate alerts.

---Optional module: with no dispatch resource running, alerts are dropped and caller details are local.
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
		"linden_outlawalert",
		"fd_dispatch",
		"ps-dispatch",
		"qs-dispatch",
		"core_dispatch",
		"origen_police",
		"codem-dispatch",
		"tk_dispatch",
	},
	schema = schema,
}
