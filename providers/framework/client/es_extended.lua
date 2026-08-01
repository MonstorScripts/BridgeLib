local RESOURCE_CORE = "es_extended"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:getSharedObject()
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Client
return function(bridge)
	return {
		InitNetworkEvents = function()
			RegisterNetEvent("esx:playerLoaded", function(xPlayer)
				bridge:Emit("playerLoaded", xPlayer)
			end)

			RegisterNetEvent("esx:setJob", function(job)
				bridge:Emit("jobUpdated", job)
			end)

			RegisterNetEvent("esx:setPlayerData", function(PlayerData)
				bridge:Emit("jobUpdated", PlayerData.job)
				bridge:Emit("playerDataUpdated", PlayerData)
			end)

			RegisterNetEvent("esx:onPlayerLogout", function()
				bridge:Emit("playerUnloaded")
			end)
		end,

		GetLocalPlayerData = function()
			local ESX = GetCoreObject()
			local PlayerData = ESX.GetPlayerData()
			return {
				job = PlayerData.job,
				grade = PlayerData.job and PlayerData.job.grade or nil,
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
	}
end
