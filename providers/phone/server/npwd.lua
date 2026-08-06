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

---npwd stores whatever number its framework integration handed it, so a lookup carries both the raw
---input and its digits only form rather than guessing which one the rows hold.
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
	---npwd exposes no server side hook for a sent message, so the live feed rides the same net event
	---its own interface sends on. That payload comes from a client, so it is only ever reported after
	---it checks out as a one to one thread the claimed sender is part of, and nothing that reads
	---stored history goes through it.
	RegisterNetEvent("npwd:sendMessage", function(_, messageData)
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
