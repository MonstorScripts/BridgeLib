---Discord's own documented ceilings. Counted in bytes here, which is never more permissive than
---the characters Discord counts, so a payload that fits these fits Discord's.
local LIMIT_TITLE = 256
local LIMIT_DESCRIPTION = 4096
local LIMIT_FIELD_NAME = 256
local LIMIT_FIELD_VALUE = 1024
local LIMIT_FIELDS = 25

local MAX_ATTEMPTS = 3
local FALLBACK_RETRY_SECONDS = 1.0

---Discord reports `retry_after` in seconds, but older payloads used milliseconds. Anything above
---this is read as milliseconds, since no webhook bucket is ever throttled for a minute.
local SECONDS_CEILING = 60

---@type table<string, string>
local overrides = {}

---One queue per URL, so a burst against one webhook cannot delay another. Entries are already
---encoded, so a payload the caller mutates after logging cannot change what gets sent.
---@type table<string, { pending: string[], running: boolean }>
local queues = {}

---@param value any
---@param limit number
---@return string
local function truncate(value, limit)
	local text = tostring(value)
	if #text <= limit then
		return text
	end
	return text:sub(1, limit - 3) .. "..."
end

---@param name string
---@return string?
local function convar(name)
	local value = GetConvar(name, "")
	if value == "" then
		return nil
	end
	return value
end

---Convar names take a restricted alphabet, so a category is folded into one before lookup.
---@param category string
---@return string
local function convarSuffix(category)
	return (tostring(category):lower():gsub("[^%w_]", "_"))
end

---@param category string
---@return string?
local function resolveUrl(category)
	if category and overrides[category] then
		return overrides[category]
	end

	if category then
		local scoped = convar(("bridgelib_webhook_%s"):format(convarSuffix(category)))
		if scoped then
			return scoped
		end
	end

	return convar("bridgelib_webhook_default")
end

---@param payload table
---@return table
local function decorate(payload)
	payload.username = payload.username or convar("bridgelib_webhook_username")
	payload.avatar_url = payload.avatar_url or convar("bridgelib_webhook_avatar")

	local footer = convar("bridgelib_webhook_footer")
	if footer then
		for _, embed in ipairs(payload.embeds or {}) do
			embed.footer = embed.footer or { text = truncate(footer, LIMIT_TITLE) }
		end
	end

	return payload
end

---@param fields BridgeLib.Logging.Field[]?
---@return table[]
local function buildFields(fields)
	local built = {}

	for _, field in ipairs(fields or {}) do
		if #built >= LIMIT_FIELDS then
			break
		end

		if type(field) == "table" and field.name ~= nil then
			local value = truncate(field.value == nil and "-" or field.value, LIMIT_FIELD_VALUE)

			built[#built + 1] = {
				name = truncate(field.name, LIMIT_FIELD_NAME),
				---Discord rejects an empty field value outright.
				value = value ~= "" and value or "-",
				inline = field.inline or false,
			}
		end
	end

	return built
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Logging.Server
return function(bridge)
	---Posts one payload and reports whether it should be retried, blocking the queue thread until
	---Discord answers.
	---@param url string
	---@param body string
	---@param attempt number
	local function post(url, body, attempt)
		local request = promise.new()

		PerformHttpRequest(url, function(status, text)
			request:resolve({ status = status, text = text })
		end, "POST", body, { ["Content-Type"] = "application/json" })

		local response = Citizen.Await(request)
		local status = response.status or 0

		if status >= 200 and status < 300 then
			return
		end

		if attempt >= MAX_ATTEMPTS then
			bridge:Debug(("Webhook gave up after %d attempts with status %d"):format(attempt, status))
			return
		end

		if status == 429 then
			local retryAfter = FALLBACK_RETRY_SECONDS
			local decodedOk, decoded = pcall(json.decode, response.text or "")

			if decodedOk and type(decoded) == "table" and tonumber(decoded.retry_after) then
				retryAfter = tonumber(decoded.retry_after)
				if retryAfter > SECONDS_CEILING then
					retryAfter = retryAfter / 1000
				end
			end

			Wait(math.ceil(retryAfter * 1000) + 100)
			return post(url, body, attempt + 1)
		end

		---Anything 5xx is Discord's problem and worth another go. A 4xx that is not a rate limit is
		---the payload's, and retrying it would only repeat the rejection.
		if status >= 500 then
			Wait(math.ceil(FALLBACK_RETRY_SECONDS * 1000) * attempt)
			return post(url, body, attempt + 1)
		end

		bridge:Debug(("Webhook rejected with status %d: %s"):format(status, tostring(response.text)))
	end

	---@param url string
	local function drain(url)
		local queue = queues[url]
		if queue.running then
			return
		end

		queue.running = true

		CreateThread(function()
			while true do
				local body = table.remove(queue.pending, 1)
				if not body then
					break
				end

				post(url, body, 1)
				Wait(50)
			end

			queue.running = false
			queues[url] = nil
		end)
	end

	---@param category string
	---@param payload table
	local function enqueue(category, payload)
		local url = resolveUrl(category)
		if not url then
			bridge:Verbose(("No webhook configured for category '%s'"):format(tostring(category)))
			return
		end

		queues[url] = queues[url] or { pending = {}, running = false }
		queues[url].pending[#queues[url].pending + 1] = json.encode(decorate(payload))

		drain(url)
	end

	return {
		SetWebhookUrl = function(category, url)
			overrides[category] = url
		end,

		GetWebhookUrl = function(category)
			return resolveUrl(category)
		end,

		LogFields = function(category, title, colour, fields)
			local embed = {
				title = truncate(title or "", LIMIT_TITLE),
				color = tonumber(colour) or 0,
				timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			}

			local built = buildFields(fields)
			---An empty Lua table encodes as an object, which Discord rejects where it wants an array.
			if #built > 0 then
				embed.fields = built
			end

			enqueue(category, { embeds = { embed } })
		end,

		LogMessage = function(category, message, title, colour)
			local embed = {
				description = truncate(message or "", LIMIT_DESCRIPTION),
				color = tonumber(colour) or 0,
				timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			}

			if title then
				embed.title = truncate(title, LIMIT_TITLE)
			end

			enqueue(category, { embeds = { embed } })
		end,

		SendWebhook = function(category, payload)
			if type(payload) ~= "table" then
				return
			end

			enqueue(category, payload)
		end,
	}
end
