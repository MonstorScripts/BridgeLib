local RESOURCE_CORE = "es_extended"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:getSharedObject()
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Server
return function(bridge)
	return {
		InitNetworkEvents = function()
			AddEventHandler("esx:playerLoaded", function(playerId, xPlayer, isNew)
				bridge:Emit("playerLoaded", playerId)
			end)
		end,

		---@param src number
		---@return BridgeLib.Player?
		GetPlayer = function(src)
			local ESX = GetCoreObject()
			local xPlayer = ESX.GetPlayerFromId(src)
			if not xPlayer then
				bridge:Debug("ESX GetPlayer returned nil for source: " .. tostring(src))
				return nil
			end

			return {
				UniqueId = xPlayer.identifier or "",
				JobName = xPlayer.job and xPlayer.job.name or "",
				JobOnDuty = (xPlayer.job and xPlayer.job.onDuty) or false,
				SetOnDuty = function(onDuty)
					if xPlayer and xPlayer.job then
						xPlayer.job.onDuty = onDuty
						TriggerClientEvent("esx:setJob", src, xPlayer.job)
					end
				end,
			}
		end,

		Notify = function(src, message, type, length)
			local ESX = GetCoreObject()
			local xPlayer = ESX.GetPlayerFromId(src)
			if xPlayer then
				xPlayer.showNotification(message, type, length)
			end
		end,

		AddItems = function(items)
			local ESX = GetCoreObject()
			if type(items) ~= "table" then
				return false
			end

			local ok = true
			for _, entry in pairs(items) do
				local src = entry.src or entry.source
				local name = entry.name or entry.item
				local count = entry.count or entry.amount or 1
				local xPlayer = src and ESX.GetPlayerFromId(src)
				if xPlayer and name then
					xPlayer.addInventoryItem(name, count, entry.metadata)
				else
					ok = false
				end
			end
			return ok
		end,

		CreateUseableItem = function(itemName, callback)
			local ESX = GetCoreObject()
			return ESX.RegisterUsableItem(itemName, callback)
		end,
	}
end
