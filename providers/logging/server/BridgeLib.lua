---Discord's documented ceilings, counted in bytes, which is never more permissive than characters.
local LIMIT_TITLE = 256
local LIMIT_DESCRIPTION = 4096
local LIMIT_FIELD_NAME = 256
local LIMIT_FIELD_VALUE = 1024
local LIMIT_FIELDS = 25

local MAX_ATTEMPTS = 3
local FALLBACK_RETRY_SECONDS = 1.0

---A `retry_after` above this is read as milliseconds, since no bucket is throttled for a minute.
local SECONDS_CEILING = 60

---@type table<string, string>
local overrides = {}

---One queue per URL, holding already-encoded entries so a later mutation cannot change what is sent.
---@type table<string, { pending: string[], running: boolean }>
local queues = {}

---@param byte number?
---@return boolean
local function isContinuationByte(byte)
	return byte ~= nil and byte >= 0x80 and byte < 0xC0
end

---Backs the cut off a split codepoint, since Discord rejects a body that is not valid UTF-8.
---@param value any
---@param limit number
---@return string
local function truncate(value, limit)
	local text = tostring(value)
	if #text <= limit then
		return text
	end

	local cut = limit - 3

	while cut > 0 and isContinuationByte(text:byte(cut + 1)) do
		cut = cut - 1
	end

	return text:sub(1, cut) .. "..."
end

---An empty string reads the same as an absent one, so a shipped template of `""` is untouched.
---@param value any
---@return string?
local function setting(value)
	if type(value) ~= "string" or value == "" then
		return nil
	end
	return value
end

---Matched as written first, then case-insensitively, so `BossMenu` still finds a `bossmenu` entry.
---@param webhooks table
---@param category string
---@return string?
local function lookup(webhooks, category)
	local exact = setting(webhooks[category])
	if exact then
		return exact
	end

	local wanted = tostring(category):lower()

	for key, url in pairs(webhooks) do
		if type(key) == "string" and key:lower() == wanted then
			return setting(url)
		end
	end

	return nil
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
	---@param category string
	---@return string?
	local function resolveUrl(category)
		if category and overrides[category] then
			return overrides[category]
		end

		local config = bridge:GetModuleConfig("logging")
		local webhooks = type(config.webhooks) == "table" and config.webhooks or {}

		if category then
			local scoped = lookup(webhooks, category)
			if scoped then
				return scoped
			end
		end

		return setting(webhooks.default)
	end

	---@param payload table
	---@return table
	local function decorate(payload)
		local config = bridge:GetModuleConfig("logging")

		payload.username = payload.username or setting(config.username)
		payload.avatar_url = payload.avatar_url or setting(config.avatarUrl)

		local footer = setting(config.footer)
		if footer then
			for _, embed in ipairs(payload.embeds or {}) do
				embed.footer = embed.footer or { text = truncate(footer, LIMIT_TITLE) }
			end
		end

		return payload
	end

	---Posts one payload and reports whether to retry, blocking the queue thread until Discord answers.
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

		bridge:Debug(("Webhook POST returned status %d"):format(status))

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

		---5xx is worth another go; a 4xx that is not a rate limit would only repeat the rejection.
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
			bridge:Debug(("No webhook configured for category '%s', dropping the payload"):format(tostring(category)))
			return
		end

		bridge:Debug(("Queued a payload for category '%s'"):format(tostring(category)))

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
