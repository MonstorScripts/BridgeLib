---One job a player holds, as the multijob resource stores it.
---@class BridgeLib.Multijob.Entry
---@field name string
---@field label string
---@field grade number
---@field grade_name string
---@field grade_salary number
---@field onDuty boolean Whether this is the job the framework currently has applied.

---@class BridgeLib.Multijob.Holder
---@field citizenid string
---@field data BridgeLib.Multijob.Entry

---Optional module: with no multijob resource running, players are treated as holding only the job
---the framework itself reports, so `IsPlayerInJob` is false and the writes are no-ops.
---@class BridgeLib.Multijob.Server
local schema = {
	---Everyone who holds a job, online or not, as far as the multijob resource has cached.
	---@param jobName string
	---@return BridgeLib.Multijob.Holder[]
	GetPlayersInJob = function(jobName)
		return {}
	end,

	---@param identifier string
	---@param jobName string
	---@return BridgeLib.Multijob.Entry|false entry false when the player does not hold the job.
	IsPlayerInJob = function(identifier, jobName)
		return false
	end,

	---Grants a job and makes it the active one, applying it to the player when they are online and
	---writing it through to storage when they are not.
	---@param identifier string
	---@param jobData { name: string, grade: number?, label: string?, gradeName: string?, gradeSalary: number? }
	---@return boolean granted false when the job is not grantable, e.g. the player is at their cap.
	SetPlayerJob = function(identifier, jobData)
		return false
	end,

	---@param identifier string
	---@param jobName string
	---@return boolean removed, BridgeLib.Multijob.Entry|string result The fallback job when removal
	---switched them off it, otherwise a reason: "invalid", "permanent" or "missing".
	RemovePlayerJob = function(identifier, jobName)
		return false, "missing"
	end,
}

---@type BridgeLib.Module
return {
	name = "multijob",
	context = "server",
	providers = {
		"al-multijob",
	},
	required = {
		"GetPlayersInJob",
		"IsPlayerInJob",
		"SetPlayerJob",
		"RemovePlayerJob",
	},
	schema = schema,
}
