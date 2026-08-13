local SAFE_NAME_PATTERN = "^[%w_]+$"

---Names are interpolated rather than bound, so anything but a bare identifier is refused.
---@param name any
---@return boolean
local function isSafeName(name)
	return type(name) == "string" and name:match(SAFE_NAME_PATTERN) ~= nil
end

---@param database table
---@param layout string
---@return string? key The first name the queries interpolate that is missing or not a bare identifier.
local function unusableName(database, layout)
	local keys = layout == "pair" and { "conversationsTable", "conversationColumn", "firstNumberColumn", "secondNumberColumn" } or { "membersTable", "conversationColumn", "numberColumn" }

	keys[#keys + 1] = "messagesTable"
	keys[#keys + 1] = "senderColumn"
	keys[#keys + 1] = "contentColumn"
	keys[#keys + 1] = "timestampColumn"

	for _, key in ipairs(keys) do
		if not isSafeName(database[key]) then
			return key
		end
	end

	if database.messagesConversationColumn ~= nil and not isSafeName(database.messagesConversationColumn) then
		return "messagesConversationColumn"
	end

	return nil
end

---@param number string|number
---@return string[]
local function lookupCandidates(number)
	local rawNumber = (tostring(number or ""):gsub("^%s*(.-)%s*$", "%1"))
	local digits = (rawNumber:gsub("%D", ""))

	if digits == "" then
		return {}
	end

	if digits == rawNumber then
		return { rawNumber }
	end

	return { rawNumber, digits }
end

---@param candidates string[]
---@return string
local function placeholders(candidates)
	return string.rep("?", #candidates, ",")
end

---@param target string[]
---@param values string[]
local function appendAll(target, values)
	for _, value in ipairs(values) do
		target[#target + 1] = value
	end
end

---@param database table
---@param candidatesA string[]
---@param candidatesB string[]
---@return string query, string[] params
local function buildMembersQuery(database, candidatesA, candidatesB)
	local params = {}
	appendAll(params, candidatesA)
	appendAll(params, candidatesB)

	local query = ([[
		SELECT a.%s AS conversationId FROM %s a
		JOIN %s b ON a.%s = b.%s AND a.%s != b.%s
		WHERE a.%s IN (%s) AND b.%s IN (%s)
		LIMIT 1
	]]):format(
		database.conversationColumn,
		database.membersTable,
		database.membersTable,
		database.conversationColumn,
		database.conversationColumn,
		database.numberColumn,
		database.numberColumn,
		database.numberColumn,
		placeholders(candidatesA),
		database.numberColumn,
		placeholders(candidatesB)
	)

	return query, params
end

---@param database table
---@param candidatesA string[]
---@param candidatesB string[]
---@return string query, string[] params
local function buildPairQuery(database, candidatesA, candidatesB)
	local params = {}
	appendAll(params, candidatesA)
	appendAll(params, candidatesB)
	appendAll(params, candidatesB)
	appendAll(params, candidatesA)

	local query = ([[
		SELECT %s AS conversationId FROM %s
		WHERE (%s IN (%s) AND %s IN (%s)) OR (%s IN (%s) AND %s IN (%s))
		LIMIT 1
	]]):format(
		database.conversationColumn,
		database.conversationsTable,
		database.firstNumberColumn,
		placeholders(candidatesA),
		database.secondNumberColumn,
		placeholders(candidatesB),
		database.firstNumberColumn,
		placeholders(candidatesB),
		database.secondNumberColumn,
		placeholders(candidatesA)
	)

	return query, params
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Phone.Server?
return function(bridge)
	local database = bridge:GetModuleConfig("phone").database

	if type(database) ~= "table" or not database.messagesTable then
		return nil
	end

	local layout = database.layout or "members"

	local unusable = unusableName(database, layout)
	if unusable then
		bridge:Debug(("The phone database config's '%s' is missing or is not a bare table or column name, so the '%s' layout cannot be queried"):format(unusable, layout))
		return nil
	end

	local ownerLookupReady = isSafeName(database.phonesTable) and isSafeName(database.phoneNumberColumn) and isSafeName(database.ownerColumn)

	if not ownerLookupReady and (database.phonesTable or database.phoneNumberColumn or database.ownerColumn) then
		bridge:Debug("The phone database config names a phone table only partly, so numbers cannot be resolved to their owner")
	end

	local messageEvent = database.messageEvent
	if type(messageEvent) == "table" and messageEvent.name then
		AddEventHandler(messageEvent.name, function(payload)
			if type(payload) ~= "table" then
				return
			end

			bridge:Emit("messageSent", {
				conversationId = messageEvent.conversationId and payload[messageEvent.conversationId] or nil,
				sender = payload[messageEvent.sender or "sender"],
				recipient = payload[messageEvent.recipient or "recipient"],
				content = payload[messageEvent.content or "message"],
				timestamp = os.date("%Y-%m-%d %H:%M:%S"),
			})
		end)
	end

	---@type BridgeLib.Phone.Server
	local provider = {
		HasPhone = function()
			return true
		end,

		FormatNumber = function(number)
			return tostring(number)
		end,

		---Only available when the owner lookup keys are configured; the thread queries do not need them.
		FindNumberOwner = function(number)
			if not ownerLookupReady then
				return nil
			end

			local candidates = lookupCandidates(number)
			if #candidates == 0 then
				return nil
			end

			local query = ("SELECT %s AS ownerIdentifier FROM %s WHERE %s IN (%s) LIMIT 1"):format(database.ownerColumn, database.phonesTable, database.phoneNumberColumn, placeholders(candidates))

			local phone = MySQL.single.await(query, candidates)
			return phone and phone.ownerIdentifier or nil
		end,

		FindConversation = function(numberA, numberB)
			local candidatesA = lookupCandidates(numberA)
			local candidatesB = lookupCandidates(numberB)

			if #candidatesA == 0 or #candidatesB == 0 then
				return nil
			end

			local query, params
			if layout == "pair" then
				query, params = buildPairQuery(database, candidatesA, candidatesB)
			else
				query, params = buildMembersQuery(database, candidatesA, candidatesB)
			end

			local conversation = MySQL.single.await(query, params)
			return conversation and conversation.conversationId or nil
		end,

		GetConversationMessages = function(conversationId)
			local query = ([[
				SELECT %s AS sender, %s AS content, %s AS timestamp FROM %s
				WHERE %s = ? ORDER BY %s ASC
			]]):format(
				database.senderColumn,
				database.contentColumn,
				database.timestampColumn,
				database.messagesTable,
				database.messagesConversationColumn or database.conversationColumn,
				database.timestampColumn
			)

			return MySQL.query.await(query, { conversationId }) or {}
		end,
	}

	return provider
end
