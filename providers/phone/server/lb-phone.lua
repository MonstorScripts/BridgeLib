local RESOURCE_PHONE = "lb-phone"

---@param number string|number
---@return string
local function digitsOnly(number)
	return (tostring(number or ""):gsub("%D", ""))
end

---@param number string|number
---@return string
local function trimmed(number)
	return (tostring(number or ""):gsub("^%s*(.-)%s*$", "%1"))
end

---Rows hold whatever format the phone was configured with when they were written, and callers pass
---numbers with punctuation, so a lookup carries the phone's own format alongside the raw input and
---the digits only form rather than guessing which one the table uses.
---@param number string|number
---@return string[]
local function lookupCandidates(number)
	local rawNumber = trimmed(number)
	local candidates = {}
	local seen = {}

	local success, formatted = pcall(function()
		return exports[RESOURCE_PHONE]:FormatNumber(rawNumber)
	end)

	local ordered = {}
	if success and type(formatted) == "string" then
		ordered[#ordered + 1] = formatted
	end
	ordered[#ordered + 1] = rawNumber
	ordered[#ordered + 1] = digitsOnly(rawNumber)

	for _, candidate in ipairs(ordered) do
		if candidate ~= "" and not seen[candidate] then
			seen[candidate] = true
			candidates[#candidates + 1] = candidate
		end
	end

	return candidates
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Phone.Server
return function(bridge)
	AddEventHandler("lb-phone:messages:messageSent", function(message)
		if type(message) ~= "table" then
			return
		end

		bridge:Emit("messageSent", {
			conversationId = message.channelId,
			sender = message.sender,
			recipient = message.recipient,
			content = message.message,
			timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		})
	end)

	---@type BridgeLib.Phone.Server
	local provider = {
		HasPhone = function()
			return true
		end,

		FormatNumber = function(number)
			return exports[RESOURCE_PHONE]:FormatNumber(number)
		end,

		FindConversation = function(numberA, numberB)
			local candidatesA = lookupCandidates(numberA)
			local candidatesB = lookupCandidates(numberB)

			if #candidatesA == 0 or #candidatesB == 0 then
				return nil
			end

			local queryParams = {}
			for _, candidate in ipairs(candidatesA) do
				queryParams[#queryParams + 1] = candidate
			end
			for _, candidate in ipairs(candidatesB) do
				queryParams[#queryParams + 1] = candidate
			end

			local query = ([[
				SELECT a.channel_id FROM phone_message_members a
				JOIN phone_message_members b ON a.channel_id = b.channel_id AND a.phone_number != b.phone_number
				JOIN phone_message_channels c ON c.id = a.channel_id
				WHERE a.phone_number IN (%s) AND b.phone_number IN (%s) AND c.is_group = 0
				LIMIT 1
			]]):format(string.rep("?", #candidatesA, ","), string.rep("?", #candidatesB, ","))

			local channel = MySQL.single.await(query, queryParams)
			return channel and channel.channel_id or nil
		end,

		GetConversationMessages = function(conversationId)
			local messages = MySQL.query.await("SELECT sender, content, timestamp FROM phone_message_messages WHERE channel_id = ? ORDER BY timestamp ASC", { conversationId })

			return messages or {}
		end,
	}

	return provider
end
