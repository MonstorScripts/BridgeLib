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

---npwd stores whatever its framework handed it, so a lookup carries both raw and digits only forms.
---@param number string|number
---@return string[]
local function lookupCandidates(number)
	local rawNumber = trimmed(number)
	local digits = digitsOnly(rawNumber)

	if digits == "" then
		return {}
	end

	if digits == rawNumber then
		return { rawNumber }
	end

	return { rawNumber, digits }
end

---Compares raw first, then digits only, since npwd stores whatever format it was handed.
---@param a string|number
---@param b string|number
---@return boolean
local function sameNumber(a, b)
	local rawA, rawB = trimmed(a), trimmed(b)

	if rawA ~= "" and rawA == rawB then
		return true
	end

	local digitsA = digitsOnly(rawA)

	return digitsA ~= "" and digitsA == digitsOnly(rawB)
end

---@param bridge BridgeLib.Bridge
---@param src number
---@return string? number nil when the framework module is absent or the caller has no number.
local function callerNumber(bridge, src)
	if type(bridge.exports.GetPlayer) ~= "function" then
		return nil
	end

	local player = bridge.exports.GetPlayer(src)
	local identifier = player and player.UniqueId

	if type(identifier) ~= "string" or identifier == "" then
		return nil
	end

	return MySQL.scalar.await(
		"SELECT phone_number FROM npwd_phone_numbers WHERE identifier = ? LIMIT 1",
		{ identifier }
	)
end

---@param conversationList string
---@return string[]
local function participantsOf(conversationList)
	local participants = {}

	for participant in tostring(conversationList or ""):gmatch("[^+]+") do
		participants[#participants + 1] = trimmed(participant)
	end

	return participants
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Phone.Server
return function(bridge)
	---npwd has no server side hook, so this rides its net event. The payload comes from a client, so
	---the sender it claims is checked against the number the caller actually owns before it is emitted.
	RegisterNetEvent("npwd:sendMessage", function(_, messageData)
		local src = source

		if type(messageData) ~= "table" then
			return
		end

		local participants = participantsOf(messageData.conversationList)
		if #participants ~= 2 then
			return
		end

		local sender = trimmed(messageData.sourcePhoneNumber)
		if sender == "" or (participants[1] ~= sender and participants[2] ~= sender) then
			return
		end

		local recipient
		for _, participant in ipairs(participants) do
			if participant ~= sender then
				recipient = participant
			end
		end

		if not recipient then
			return
		end

		local owned = callerNumber(bridge, src)
		if not owned or not sameNumber(owned, sender) then
			bridge:Debug(("Dropped a message %d claimed to send as '%s'"):format(src, sender))
			return
		end

		bridge:Emit("messageSent", {
			conversationId = messageData.conversationId,
			sender = sender,
			recipient = recipient,
			content = messageData.message,
			timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		})
	end)

	---@type BridgeLib.Phone.Server
	local provider = {
		HasPhone = function()
			return true
		end,

		FormatNumber = function(number)
			return tostring(number)
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
				SELECT a.conversation_id FROM npwd_messages_participants a
				JOIN npwd_messages_participants b ON a.conversation_id = b.conversation_id AND a.participant != b.participant
				JOIN npwd_messages_conversations c ON c.id = a.conversation_id
				WHERE a.participant IN (%s) AND b.participant IN (%s) AND c.is_group_chat = 0
				ORDER BY c.updatedAt DESC
				LIMIT 1
			]]):format(string.rep("?", #candidatesA, ","), string.rep("?", #candidatesB, ","))

			local conversation = MySQL.single.await(query, queryParams)
			return conversation and conversation.conversation_id or nil
		end,

		GetConversationMessages = function(conversationId)
			local messages = MySQL.query.await("SELECT author AS sender, message AS content, createdAt AS timestamp FROM npwd_messages WHERE conversation_id = ? ORDER BY createdAt ASC", { conversationId })

			return messages or {}
		end,
	}

	return provider
end
