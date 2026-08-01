local RESOURCE_CORE = "qb-core"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:GetCoreObject()
end

---@param job table?
---@return BridgeLib.LiveJob?
local function normalizeJob(job)
	if type(job) ~= "table" then
		return nil
	end

	local grade = job.grade or {}

	return {
		name = job.name or "",
		label = job.label or job.name or "",
		grade = tonumber(grade.level) or 0,
		gradeName = grade.name or tostring(grade.level or 0),
		onDuty = job.onduty or false,
	}
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Client
return function(bridge)
	return {
		InitNetworkEvents = function()
			RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
				local QBCore = GetCoreObject()
				local PlayerData = QBCore.Functions.GetPlayerData()
				bridge:Emit("playerLoaded", PlayerData)
				bridge:Emit("jobUpdated", normalizeJob(PlayerData and PlayerData.job))
			end)

			RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo)
				bridge:Emit("jobUpdated", normalizeJob(JobInfo))
			end)

			RegisterNetEvent("QBCore:Player:SetPlayerData", function(PlayerData)
				bridge:Emit("jobUpdated", normalizeJob(PlayerData.job))
				bridge:Emit("playerDataUpdated", PlayerData)
			end)

			RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
				bridge:Emit("playerUnloaded")
			end)
		end,

		GetLocalPlayerData = function()
			local QBCore = GetCoreObject()
			local PlayerData = QBCore.Functions.GetPlayerData()
			local job = normalizeJob(PlayerData and PlayerData.job)
			return {
				job = job,
				grade = job and job.grade or nil,
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

		GetClosestVehicle = function(coords)
			local QBCore = GetCoreObject()
			return QBCore.Functions.GetClosestVehicle(coords)
		end,
	}
end
