local RESOURCE_BOSSMENU = "monstor-bossmenu"

---@type BridgeLib.BossMenu.Server
local provider = {
	CanManageJob = function(src, jobName)
		return exports[RESOURCE_BOSSMENU]:CanManageJob(src, jobName) and true or false
	end,

	GetEmployees = function(jobName)
		return exports[RESOURCE_BOSSMENU]:GetEmployees(jobName) or {}
	end,

	GetJobGrades = function(jobName)
		return exports[RESOURCE_BOSSMENU]:GetJobGrades(jobName) or {}
	end,

	GetSocietyBalance = function(jobName)
		return exports[RESOURCE_BOSSMENU]:GetSocietyBalance(jobName) or 0
	end,

	HireEmployee = function(src, jobName, target)
		return exports[RESOURCE_BOSSMENU]:HireEmployee(src, jobName, target) and true or false
	end,

	FireEmployee = function(src, jobName, identifier)
		return exports[RESOURCE_BOSSMENU]:FireEmployee(src, jobName, identifier) and true or false
	end,

	SetEmployeeGrade = function(src, jobName, identifier, grade)
		return exports[RESOURCE_BOSSMENU]:SetEmployeeGrade(src, jobName, identifier, grade) and true or false
	end,
}

return provider
