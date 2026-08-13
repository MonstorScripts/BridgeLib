local RESOURCE_LOGGING = "fmsdk"

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

	if config.service ~= "fivemanage" then
		return nil
	end

	local dataset = config.dataset ~= "" and config.dataset or "default"

	---@param category string
	---@param message string
	local function send(category, message)
		exports[RESOURCE_LOGGING]:Log(dataset, "info", message, { category = category })
	end

	return {
		LogFields = function(category, title, _, fields)
			send(category, ("%s\n%s"):format(tostring(title), flatten(fields)))
		end,

		LogMessage = function(category, message, title)
			send(category, title and ("%s\n%s"):format(title, message) or message)
		end,
	}
end
