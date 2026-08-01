local RESOURCE_CORE = "qb-core"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:GetCoreObject()
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Client
return function(bridge)
	return {
		InitNetworkEvents = function()
			RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
				bridge:Emit("playerLoaded")
			end)

			RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo)
				bridge:Emit("jobUpdated", JobInfo)
			end)

			RegisterNetEvent("QBCore:Player:SetPlayerData", function(PlayerData)
				bridge:Emit("jobUpdated", PlayerData.job)
				bridge:Emit("playerDataUpdated", PlayerData)
			end)

			RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
				bridge:Emit("playerUnloaded")
			end)
		end,

		GetLocalPlayerData = function()
			local QBCore = GetCoreObject()
			local PlayerData = QBCore.Functions.GetPlayerData()
			return {
				job = PlayerData.job,
				grade = PlayerData.job and PlayerData.job.grade and PlayerData.job.grade.level or nil,
			}
		end,

		LocalNotify = function(...)
			local QBCore = GetCoreObject()
			return QBCore.Functions.Notify(...)
		end,

		Progressbar = function(...)
			local QBCore = GetCoreObject()
			return QBCore.Functions.Progressbar(...)
		end,
	}
end
