local RESOURCE_DOORLOCK = "ox_doorlock"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Doorlock.Server
return function(bridge)
	return {
		SetDoorState = function(data)
			local door = exports[RESOURCE_DOORLOCK]:getDoorFromName(data.id)
			if not door then
				bridge:Debug(("ox_doorlock knows no door named '%s'"):format(tostring(data.id)))
				return
			end

			TriggerEvent("ox_doorlock:setState", door.id, data.locked and 1 or 0)
		end,
	}
end
