---Generic adapter for any phone the library does not ship a provider for. Everything it needs comes
---out of `phone.database` in the config, so a new phone is a configuration change rather than a code
---change. Returning nothing when that section is absent leaves the module on its fallback stubs.
---
---Two conversation layouts are supported:
---  `members`  a join table with one row per participant, the shape lb-phone and its relatives use.
---  `pair`     one conversation row holding both numbers in two columns.
---
---A phone that stores threads any other way needs a provider file of its own.

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
		database.conversationColumn, database.membersTable,
		database.membersTable, database.conversationColumn, database.conversationColumn,
		database.numberColumn, database.numberColumn,
		database.numberColumn, placeholders(candidatesA),
		database.numberColumn, placeholders(candidatesB)
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
		database.conversationColumn, database.conversationsTable,
		database.firstNumberColumn, placeholders(candidatesA),
		database.secondNumberColumn, placeholders(candidatesB),
		database.firstNumberColumn, placeholders(candidatesB),
		database.secondNumberColumn, placeholders(candidatesA)
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
				database.senderColumn, database.contentColumn, database.timestampColumn,
				database.messagesTable, database.messagesConversationColumn or database.conversationColumn,
				database.timestampColumn
			)

			return MySQL.query.await(query, { conversationId }) or {}
		end,
	}

	return provider
end
