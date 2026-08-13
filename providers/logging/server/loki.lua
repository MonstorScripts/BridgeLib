---Milliseconds entries collect for before one push goes out, so a burst of logs is one request.
local FLUSH_DELAY = 500

local BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

---@param data string
---@return string
local function base64(data)
	local bits = data:gsub(".", function(character)
		local encoded, byte = "", character:byte()
		for index = 8, 1, -1 do
			encoded = encoded .. ((byte % 2 ^ index >= 2 ^ (index - 1)) and "1" or "0")
		end
		return encoded
	end)

	local encoded = (bits .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(chunk)
		if #chunk < 6 then
			return ""
		end

		local value = 0
		for index = 1, 6 do
			value = value + (chunk:sub(index, index) == "1" and 2 ^ (6 - index) or 0)
		end

		return BASE64_ALPHABET:sub(value + 1, value + 1)
	end)

	return encoded .. ({ "", "==", "=" })[#data % 3 + 1]
end

---@param value any
---@return string?
local function setting(value)
	if type(value) ~= "string" or value == "" then
		return nil
	end
	return value
end

---@param fields BridgeLib.Logging.Field[]?
---@return table<string, any>
local function asMap(fields)
	local map = {}

	for _, field in ipairs(fields or {}) do
		if type(field) == "table" and field.name ~= nil then
			map[tostring(field.name)] = field.value
		end
	end

	return map
end

---Grafana Cloud speaks the same push API as a self-hosted Loki, so both are configured through the
---one `logging.loki` section and told apart by whether an API key or a user and password are set.
---@param bridge BridgeLib.Bridge
---@return BridgeLib.Logging.Server?
return function(bridge)
	local config = bridge:GetModuleConfig("logging")

	if config.service ~= "loki" and config.service ~= "grafana" then
		return nil
	end

	local loki = type(config.loki) == "table" and config.loki or {}
	local host = setting(loki.endpoint)

	if not host then
		bridge:Debug("Logging is set to Loki, but no 'logging.loki.endpoint' is configured")
		return nil
	end

	if not host:match("^https?://") then
		host = "https://" .. host
	end

	local endpoint = host:gsub("/+$", "") .. "/loki/api/v1/push"

	local headers = { ["Content-Type"] = "application/json" }

	if setting(loki.apiKey) then
		headers["Authorization"] = "Bearer " .. loki.apiKey
	elseif setting(loki.user) and setting(loki.password) then
		headers["Authorization"] = "Basic " .. base64(loki.user .. ":" .. loki.password)
	end

	if setting(loki.tenant) then
		headers["X-Scope-OrgID"] = loki.tenant
	end

	local server = setting(loki.server) or GetConvar("sv_projectName", "fxserver")
	local resource = GetCurrentResourceName()

	---One stream per category, keyed so repeat logs from a category share a stream.
	---@type table<string, table>
	local streams = {}
	local flushing = false

	local function flush()
		if flushing then
			return
		end

		flushing = true

		SetTimeout(FLUSH_DELAY, function()
			local pending = {}
			for _, stream in pairs(streams) do
				pending[#pending + 1] = stream
			end

			streams = {}
			flushing = false

			if #pending == 0 then
				return
			end

			PerformHttpRequest(endpoint, function(status)
				if status < 200 or status >= 300 then
					bridge:Debug(("Loki push failed with status %d"):format(status or 0))
				end
			end, "POST", json.encode({ streams = pending }), headers)
		end)
	end

	---@param category string
	---@param payload table
	local function push(category, payload)
		local stream = streams[category]

		if not stream then
			stream = {
				stream = { server = server, resource = resource, event = category },
				values = {},
			}
			streams[category] = stream
		end

		stream.values[#stream.values + 1] = { tostring(os.time() * 1000000000), json.encode(payload) }

		flush()
	end

	return {
		LogFields = function(category, title, _, fields)
			push(category, { title = title, fields = asMap(fields) })
		end,

		LogMessage = function(category, message, title)
			push(category, { title = title, message = message })
		end,
	}
end
