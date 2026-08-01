local RESOURCE_CORE = "qb-core"

local ACCOUNTS = {
	money = "cash",
	cash = "cash",
	bank = "bank",
	black_money = "crypto",
	crypto = "crypto",
}

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:GetCoreObject()
end

---@param account string
---@return string
local function moneyType(account)
	return ACCOUNTS[account] or account
end

---@param grade table
---@param gradeKey string
---@return BridgeLib.Grade
local function normalizeGrade(grade, gradeKey)
	return {
		grade = tonumber(gradeKey) or 0,
		name = grade.name or grade.label or gradeKey,
		label = grade.label or grade.name or gradeKey,
		salary = tonumber(grade.payment or grade.salary) or 0,
	}
end

---@param job table
---@param jobName string
---@return BridgeLib.Job
local function normalizeJob(job, jobName)
	local grades = {}
	for gradeKey, grade in pairs(job.grades or {}) do
		grades[tostring(gradeKey)] = normalizeGrade(grade, tostring(gradeKey))
	end

	return {
		name = jobName,
		label = job.label or jobName,
		grades = grades,
	}
end

---@param job table?
---@return BridgeLib.LiveJob?
local function normalizePlayerJob(job)
	if type(job) ~= "table" then
		return nil
	end

	local grade = job.grade or {}

	return {
		name = job.name or "",
		label = job.label or job.name or "",
		grade = tonumber(grade.level) or 0,
		gradeName = grade.name or tostring(grade.level or 0),
		gradeSalary = tonumber(job.payment) or 0,
		onDuty = job.onduty or false,
	}
end

---@param playerData table
---@return string
local function playerName(playerData)
	local charinfo = playerData.charinfo or {}
	local name = ((charinfo.firstname or "") .. " " .. (charinfo.lastname or "")):gsub("^%s*(.-)%s*$", "%1")
	if name ~= "" then
		return name
	end

	return playerData.name or "Unknown"
end

---@param player table
---@return BridgeLib.Player
local function wrapPlayer(player)
	local playerData = player.PlayerData or {}
	local job = playerData.job or {}
	local grade = job.grade or {}

	return {
		UniqueId = playerData.citizenid or "",
		Source = playerData.source,
		Name = playerName(playerData),
		JobName = job.name or "",
		JobLabel = job.label or job.name or "",
		JobGrade = tonumber(grade.level) or 0,
		JobGradeName = grade.name or tostring(grade.level or 0),
		JobGradeSalary = tonumber(job.payment) or 0,
		JobOnDuty = job.onduty or false,
		SetOnDuty = function(onDuty)
			player.Functions.SetJobDuty(onDuty)
		end,
		SetJob = function(jobName, jobGrade, onDuty)
			player.Functions.SetJob(jobName, jobGrade)
			if onDuty ~= nil then
				player.Functions.SetJobDuty(onDuty)
			end
		end,
		GetAccountMoney = function(account)
			return player.Functions.GetMoney(moneyType(account)) or 0
		end,
		AddAccountMoney = function(account, amount, reason)
			player.Functions.AddMoney(moneyType(account), amount, reason)
		end,
		RemoveAccountMoney = function(account, amount, reason)
			player.Functions.RemoveMoney(moneyType(account), amount, reason)
		end,
	}
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Server
return function(bridge)
	return {
		InitNetworkEvents = function()
			RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
				bridge:Emit("playerLoaded", source)
			end)

			RegisterNetEvent("QBCore:Server:OnPlayerUnload", function()
				bridge:Emit("playerUnloaded", source)
			end)

			AddEventHandler("QBCore:Server:OnJobUpdate", function(playerId, job)
				bridge:Emit("jobUpdated", playerId, normalizePlayerJob(job))
			end)
		end,

		GetPlayer = function(src)
			local QBCore = GetCoreObject()
			local player = QBCore.Functions.GetPlayer(src)
			if not player then
				bridge:Debug("QBCore GetPlayer returned nil for source: " .. tostring(src))
				return nil
			end

			return wrapPlayer(player)
		end,

		GetPlayerByIdentifier = function(identifier)
			local QBCore = GetCoreObject()
			local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
			if not player then
				return nil
			end

			return wrapPlayer(player)
		end,

		GetPlayers = function()
			local QBCore = GetCoreObject()
			local players = {}

			for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
				if player then
					players[#players + 1] = wrapPlayer(player)
				end
			end

			return players
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

		GetItemDisplayName = function(item)
			local QBCore = GetCoreObject()
			return (QBCore.Shared.Items[item:lower()] or { label = item }).label
		end,

		GetJobs = function()
			local QBCore = GetCoreObject()
			local jobs = {}

			for jobName, job in pairs(QBCore.Shared.Jobs or {}) do
				jobs[jobName] = normalizeJob(job, jobName)
			end

			return jobs
		end,

		RefreshJobs = function() end,

		GetOfflinePlayerName = function(identifier)
			local QBCore = GetCoreObject()
			local player = QBCore.Functions.GetOfflinePlayerByCitizenId(identifier)
			if player then
				return playerName(player.PlayerData or {})
			end

			if not MySQL then
				bridge:Fatal("GetOfflinePlayerName needs oxmysql loaded by the consuming resource")
				return "Unknown"
			end

			local charinfo = MySQL.scalar.await("SELECT `charinfo` FROM `players` WHERE `citizenid` = ?", { identifier })
			if not charinfo then
				return "Unknown"
			end

			return playerName({ charinfo = json.decode(charinfo) })
		end,

		SetOfflinePlayerJob = function(identifier, jobName, grade)
			if not MySQL then
				bridge:Fatal("SetOfflinePlayerJob needs oxmysql loaded by the consuming resource")
				return false
			end

			local storedJob = MySQL.scalar.await("SELECT `job` FROM `players` WHERE `citizenid` = ?", { identifier })
			if not storedJob then
				return false
			end

			local job = json.decode(storedJob) or {}
			local jobs = GetCoreObject().Shared.Jobs or {}
			local jobData = jobs[jobName] or {}
			local gradeData = (jobData.grades or {})[tostring(grade)] or (jobData.grades or {})[grade] or {}

			job.name = jobName
			job.label = jobData.label or jobName
			job.payment = tonumber(gradeData.payment) or 0
			job.onduty = jobData.defaultDuty or false
			job.grade = {
				name = gradeData.name or tostring(grade),
				level = tonumber(grade) or 0,
			}

			local affectedRows = MySQL.update.await("UPDATE `players` SET `job` = ? WHERE `citizenid` = ?", { json.encode(job), identifier })
			return (affectedRows or 0) > 0
		end,
	}
end
