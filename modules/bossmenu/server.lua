---One employee row, as the boss menu presents it.
---@class BridgeLib.BossMenu.Employee
---@field empSource string Persistent identifier of the employee.
---@field name string
---@field grade { level: number, name: string }

---Optional module: with no boss menu resource running, `CanManageJob` is false, the reads come back
---empty and the writes are no-ops.
---@class BridgeLib.BossMenu.Server
local schema = {
	---Whether the player holds the job and outranks its configured boss grade.
	---@param src number
	---@param jobName string
	---@return boolean
	CanManageJob = function(src, jobName)
		return false
	end,

	---@param jobName string
	---@return BridgeLib.BossMenu.Employee[]
	GetEmployees = function(jobName)
		return {}
	end,

	---Grades of a job, keyed by grade level as a string.
	---@param jobName string
	---@return table<string, BridgeLib.Grade>
	GetJobGrades = function(jobName)
		return {}
	end,

	---@param jobName string
	---@return number
	GetSocietyBalance = function(jobName)
		return 0
	end,

	---Puts a player on the payroll at grade 0. `target` may be a server id or an identifier.
	---@param src number Manager performing the action, checked with `CanManageJob`.
	---@param jobName string
	---@param target string|number
	---@return boolean hired
	HireEmployee = function(src, jobName, target)
		return false
	end,

	---@param src number Manager performing the action, checked with `CanManageJob`.
	---@param jobName string
	---@param identifier string
	---@return boolean fired
	FireEmployee = function(src, jobName, identifier)
		return false
	end,

	---Promotes or demotes, whichever the new grade implies.
	---@param src number Manager performing the action, checked with `CanManageJob`.
	---@param jobName string
	---@param identifier string
	---@param grade number
	---@return boolean changed
	SetEmployeeGrade = function(src, jobName, identifier, grade)
		return false
	end,
}

---@type BridgeLib.Module
return {
	name = "bossmenu",
	context = "server",
	providers = {
		"monstor-bossmenu",
	},
	required = {
		"CanManageJob",
		"GetEmployees",
		"GetJobGrades",
		"GetSocietyBalance",
		"HireEmployee",
		"FireEmployee",
		"SetEmployeeGrade",
	},
	schema = schema,
}
