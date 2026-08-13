local RESOURCE_CORE = "es_extended"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:getSharedObject()
end

---@param job table?
---@return BridgeLib.LiveJob?
local function normalizeJob(job)
	if type(job) ~= "table" then
		return nil
	end

	return {
		name = job.name or "",
		label = job.label or job.name or "",
		grade = tonumber(job.grade) or 0,
		gradeName = job.grade_label or job.grade_name or tostring(job.grade or 0),
		onDuty = job.onDuty or false,
	}
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Client
return function(bridge)
	return {
		InitNetworkEvents = function()
			RegisterNetEvent("esx:playerLoaded", function(xPlayer)
				bridge:Emit("playerLoaded", xPlayer)
				bridge:Emit("jobUpdated", normalizeJob(xPlayer and xPlayer.job))
			end)

			RegisterNetEvent("esx:setJob", function(job)
				bridge:Emit("jobUpdated", normalizeJob(job))
			end)

			RegisterNetEvent("esx:setPlayerData", function(PlayerData)
				bridge:Emit("jobUpdated", normalizeJob(PlayerData.job))
				bridge:Emit("playerDataUpdated", PlayerData)
			end)

			RegisterNetEvent("esx:onPlayerLogout", function()
				bridge:Emit("playerUnloaded")
			end)
		end,

		GetLocalPlayerData = function()
			local ESX = GetCoreObject()
			local PlayerData = ESX.GetPlayerData()
			local job = normalizeJob(PlayerData and PlayerData.job)
			return {
				job = job,
				grade = job and job.grade or nil,
				position = PlayerData and (PlayerData.position or PlayerData.coords) or nil,
			}
		end,

		LocalNotify = function(message, type, length)
			local ESX = GetCoreObject()
			return ESX.ShowNotification(message, type, length)
		end,

		Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
			if exports["ox_lib"] then
				return exports["ox_lib"]:progressBar({
					name = name,
					label = label,
					duration = duration,
					useWhileDead = useWhileDead,
					canCancel = canCancel,
					disable = disableControls,
					anim = animation,
					prop = prop,
				})
			elseif exports["progressbar"] then
				return exports["progressbar"]:Progress({
					name = name,
					duration = duration,
					label = label,
					useWhileDead = useWhileDead,
					canCancel = canCancel,
					controlDisables = disableControls,
					animation = animation,
					prop = prop,
				}, onFinish)
			else
				FreezeEntityPosition(PlayerPedId(), true)
				Wait(duration)
				FreezeEntityPosition(PlayerPedId(), false)
				if onFinish then
					onFinish()
				end
			end
		end,

		GetClosestVehicle = function(coords)
			local ESX = GetCoreObject()
			return ESX.Game.GetClosestVehicle(coords)
		end,
	}
end
