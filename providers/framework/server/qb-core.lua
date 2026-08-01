local RESOURCE_CORE = "qb-core"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:GetCoreObject()
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Server
return function(bridge)
	return {
		InitNetworkEvents = function()
			RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
				bridge:Emit("playerLoaded", source)
			end)
		end,

		GetPlayer = function(src)
			local QBCore = GetCoreObject()
			local player = QBCore.Functions.GetPlayer(src)
			local playerData = player and player.PlayerData
			return {
				UniqueId = playerData.citizenid,
				JobName = playerData.job?.name,
				JobOnDuty = playerData.job?.onduty,
				SetOnDuty = function(onDuty)
					player.Functions.SetJobDuty(onDuty)
				end,
			}
		end,

		Notify = function(src, ...)
			local QBCore = GetCoreObject()
			return QBCore.Functions.Notify(src, ...)
		end,

		AddItems = function(items)
			local QBCore = GetCoreObject()
			return QBCore.Functions.AddItems(items)
		end,

		CreateUseableItem = function(...)
			local QBCore = GetCoreObject()
			return QBCore.Functions.CreateUseableItem(...)
		end,
	}
end
