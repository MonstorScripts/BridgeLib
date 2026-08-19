---A zone created through the bridge, wrapping whatever object the provider returned.
---@class BridgeLib.Zones.Zone
---@field id any The provider's own zone object.
---@field resource string Resource that created the zone.
---@field remove fun(self: BridgeLib.Zones.Zone)

---@class BridgeLib.Zones.Options
---@field name string?
---@field debug boolean? Draws the zone's outline.
---@field minZ number? Bottom of the zone. Omitting both bounds leaves it effectively unbounded.
---@field maxZ number? Top of the zone.
---@field onPlayerInOut fun(isPointInside: boolean, point: vector3?)? Fired when the local player enters or leaves.

---@class BridgeLib.Zones.Client
local schema = {
	---@param points vector2[]|vector3[] Outline of the zone, in order.
	---@param options BridgeLib.Zones.Options?
	---@return BridgeLib.Zones.Zone
	AddPolyZone = function(points, options) end,

	---@param coords vector3
	---@param radius number
	---@param options BridgeLib.Zones.Options?
	---@return BridgeLib.Zones.Zone
	AddCircleZone = function(coords, radius, options) end,

	---@param zone BridgeLib.Zones.Zone
	---@param coords vector3
	---@return boolean
	IsPointInZone = function(zone, coords) end,

	---@param zone BridgeLib.Zones.Zone
	DestroyZone = function(zone) end,
}

---@type BridgeLib.Module
return {
	name = "zones",
	context = "client",
	providers = {
		"ox_lib",
		"PolyZone",
	},
	required = {
		"AddPolyZone",
		"AddCircleZone",
		"IsPointInZone",
		"DestroyZone",
	},
	schema = schema,
}
