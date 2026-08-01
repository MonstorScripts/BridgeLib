local RESOURCE_CORE = "es_extended"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:getSharedObject()
end

---@param grade table
---@param gradeKey string
---@return BridgeLib.Grade
local function normalizeGrade(grade, gradeKey)
	return {
		grade = tonumber(gradeKey) or 0,
		name = grade.name or grade.label or gradeKey,
		label = grade.label or grade.name or gradeKey,
		salary = tonumber(grade.salary) or 0,
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
		name = job.name or jobName,
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

	return {
		name = job.name or "",
		label = job.label or job.name or "",
		grade = tonumber(job.grade) or 0,
		gradeName = job.grade_label or job.grade_name or tostring(job.grade or 0),
		gradeSalary = tonumber(job.grade_salary) or 0,
		onDuty = job.onDuty or false,
	}
end

---@param xPlayer table
---@return string
local function playerName(xPlayer)
	if xPlayer.getName then
		local name = xPlayer.getName()
		if name and name ~= "" then
			return name
		end
	end

	local firstName = xPlayer.variables and xPlayer.variables.firstName or xPlayer.firstname
	local lastName = xPlayer.variables and xPlayer.variables.lastName or xPlayer.lastname
	if firstName or lastName then
		return ((firstName or "") .. " " .. (lastName or "")):gsub("^%s*(.-)%s*$", "%1")
	end

	return GetPlayerName(xPlayer.source) or "Unknown"
end

---@param src number
---@param xPlayer table
---@return BridgeLib.Player
local function wrapPlayer(src, xPlayer)
	local job = (xPlayer.getJob and xPlayer.getJob()) or xPlayer.job or {}

	return {
		UniqueId = xPlayer.identifier or "",
		Source = xPlayer.source or src,
		Name = playerName(xPlayer),
		JobName = job.name or "",
		JobLabel = job.label or job.name or "",
		JobGrade = tonumber(job.grade) or 0,
		JobGradeName = job.grade_label or job.grade_name or tostring(job.grade or 0),
		JobGradeSalary = tonumber(job.grade_salary) or 0,
		JobOnDuty = job.onDuty or false,
		SetOnDuty = function(onDuty)
			if xPlayer.job then
				xPlayer.job.onDuty = onDuty
				TriggerClientEvent("esx:setJob", xPlayer.source, xPlayer.job)
			end
		end,
		SetJob = function(jobName, grade, onDuty)
			xPlayer.setJob(jobName, grade, onDuty)
		end,
		GetAccountMoney = function(account)
			local playerAccount = xPlayer.getAccount(account)
			return playerAccount and playerAccount.money or 0
		end,
		AddAccountMoney = function(account, amount, reason)
			xPlayer.addAccountMoney(account, amount, reason)
		end,
		RemoveAccountMoney = function(account, amount, reason)
			xPlayer.removeAccountMoney(account, amount, reason)
		end,
	}
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Framework.Server
return function(bridge)
	return {
		InitNetworkEvents = function()
			AddEventHandler("esx:playerLoaded", function(playerId, xPlayer, isNew)
				bridge:Emit("playerLoaded", playerId)
			end)

			AddEventHandler("esx:playerLogout", function(playerId)
				bridge:Emit("playerUnloaded", playerId)
			end)

			AddEventHandler("esx:setJob", function(playerId, job, lastJob)
				bridge:Emit("jobUpdated", playerId, normalizePlayerJob(job), normalizePlayerJob(lastJob))
			end)
		end,

		GetPlayer = function(src)
			local ESX = GetCoreObject()
			local xPlayer = ESX.GetPlayerFromId(src)
			if not xPlayer then
				bridge:Debug("ESX GetPlayer returned nil for source: " .. tostring(src))
				return nil
			end

			return wrapPlayer(src, xPlayer)
		end,

		GetPlayerByIdentifier = function(identifier)
			local ESX = GetCoreObject()
			local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
			if not xPlayer then
				return nil
			end

			return wrapPlayer(xPlayer.source, xPlayer)
		end,

		GetPlayers = function()
			local ESX = GetCoreObject()
			local players = {}

			for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
				if xPlayer then
					players[#players + 1] = wrapPlayer(xPlayer.source, xPlayer)
				end
			end

			return players
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

		GetItemDisplayName = function(item)
			local ESX = GetCoreObject()
			return ESX.GetItemLabel and ESX.GetItemLabel(item) or item
		end,

		GetJobs = function()
			local ESX = GetCoreObject()
			local jobs = {}

			for jobName, job in pairs(ESX.GetJobs() or {}) do
				jobs[jobName] = normalizeJob(job, jobName)
			end

			return jobs
		end,

		RefreshJobs = function()
			local ESX = GetCoreObject()
			if ESX.RefreshJobs then
				ESX.RefreshJobs()
			end
		end,

		GetOfflinePlayerName = function(identifier)
			if not MySQL then
				bridge:Fatal("GetOfflinePlayerName needs oxmysql loaded by the consuming resource")
				return "Unknown"
			end

			local user = MySQL.single.await("SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?", { identifier })
			if not user then
				return "Unknown"
			end

			return ((user.firstname or "") .. " " .. (user.lastname or "")):gsub("^%s*(.-)%s*$", "%1")
		end,

		SetOfflinePlayerJob = function(identifier, jobName, grade)
			if not MySQL then
				bridge:Fatal("SetOfflinePlayerJob needs oxmysql loaded by the consuming resource")
				return false
			end

			local affectedRows = MySQL.update.await("UPDATE `users` SET `job` = ?, `job_grade` = ? WHERE `identifier` = ?", { jobName, grade, identifier })
			return (affectedRows or 0) > 0
		end,

		LogFields = function(category, title, colour, fields)
			local ESX = GetCoreObject()
			if not ESX.DiscordLogFields then
				return bridge:Debug(("%s: %s"):format(category, title))
			end

			return ESX.DiscordLogFields(category, title, colour, fields)
		end,
	}
end
