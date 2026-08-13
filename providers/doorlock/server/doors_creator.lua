local RESOURCE_DOORLOCK = "doors_creator"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Doorlock.Server
return function(bridge)
	return {
		---doors_creator keys its doors by a numeric id, so the label the caller names is looked up first.
		SetDoorState = function(data)
			local doorId = MySQL.scalar.await("SELECT `id` FROM `doorscreator_doors` WHERE `label` = ?", { data.id })
			if not doorId then
				bridge:Debug(("doors_creator knows no door labelled '%s'"):format(tostring(data.id)))
				return
			end

			exports[RESOURCE_DOORLOCK]:setDoorState(doorId, data.locked and 1 or 0)
		end,
	}
end
