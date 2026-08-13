local RESOURCE_LOGGING = "fm-logs"

---@param fields BridgeLib.Logging.Field[]?
---@return string
local function flatten(fields)
	local lines = {}

	for _, field in ipairs(fields or {}) do
		if type(field) == "table" and field.name ~= nil then
			lines[#lines + 1] = ("%s: %s"):format(tostring(field.name), tostring(field.value))
		end
	end

	return table.concat(lines, "\n")
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Logging.Server?
return function(bridge)
	local config = bridge:GetModuleConfig("logging")

	if config.service ~= "fivemerr" then
		return nil
	end

	local screenshots = config.screenshots == true

	---@param message string
	local function send(message)
		exports[RESOURCE_LOGGING]:createLog({
			LogType = "Generic",
			Message = message,
			Resource = GetCurrentResourceName(),
		}, { Screenshot = screenshots })
	end

	return {
		LogFields = function(_, title, _, fields)
			send(("%s\n%s"):format(tostring(title), flatten(fields)))
		end,

		LogMessage = function(_, message, title)
			send(title and ("%s\n%s"):format(title, message) or message)
		end,
	}
end
