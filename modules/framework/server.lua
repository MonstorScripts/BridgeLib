---Events a framework server adapter emits through `bridge:Emit`.
---@alias BridgeLib.Framework.ServerEvent
---| "playerLoaded" # `(src: number)`, a player finished loading.
---| "playerUnloaded" # `(src: number)`, a player logged out.
---| "jobUpdated" # `(src: number, job: BridgeLib.LiveJob, lastJob: BridgeLib.LiveJob?)`.

---One grade of a job, normalised out of the framework's own grade table.
---@class BridgeLib.Grade
---@field grade number Grade level.
---@field name string Short grade name.
---@field label string Display label, falling back to `name`.
---@field salary number Pay for the grade, 0 when the framework tracks none.

---A job as the framework's catalog describes it.
---@class BridgeLib.Job
---@field name string
---@field label string
---@field grades table<string, BridgeLib.Grade> Keyed by grade level as a string, on either framework.
---@field supportsDuty boolean True on qb-core jobs carrying `defaultDuty`, always false on ESX.

---A player, reduced to the fields that mean the same thing on every framework.
---@class BridgeLib.Player
---@field UniqueId string Persistent identifier: citizenid on qb-core, identifier on ESX.
---@field Source number Server id of the player this snapshot was taken for.
---@field Name string Character name, falling back to the connection name.
---@field JobName string
---@field JobLabel string
---@field JobGrade number Grade level, flattened out of the framework's nesting.
---@field JobGradeName string
---@field JobGradeSalary number
---@field JobOnDuty boolean
---@field SetOnDuty fun(onDuty: boolean)
---@field SetJob fun(jobName: string, grade: number, onDuty: boolean?)
---@field GetAccountMoney fun(account: string): number Account names are ESX's; qb-core maps them.
---@field AddAccountMoney fun(account: string, amount: number, reason: string?)
---@field RemoveAccountMoney fun(account: string, amount: number, reason: string?)

---What a character wipe touched.
---@class BridgeLib.CharacterWipe
---@field columnsVisited number Table columns the wipe walked.
---@field rowsUpdated number Rows rewritten because the identifier sat inside a JSON blob.
---@field rowsDeleted number Rows removed because the column was the identifier outright.

---A map of table name to the column, or columns, holding a character identifier.
---@alias BridgeLib.CharacterTables table<string, string|string[]>

---Where a framework keeps the character row itself, which is what existence is tested against.
---@class BridgeLib.CharacterIdentity
---@field table string
---@field column string

local SAFE_NAME_PATTERN = "^[%w_]+$"

---An empty table encodes as an object, so an array the scrub empties carries this until it is encoded.
local EMPTY_ARRAY_MARKER = "__BridgeLibEmptyArray__"
local EMPTY_ARRAY_PATTERN = '%["__BridgeLibEmptyArray__"%]'

---Names are interpolated rather than bound, so anything but a bare identifier is refused.
---@param name any
---@return boolean
local function isSafeName(name)
	return type(name) == "string" and name:match(SAFE_NAME_PATTERN) ~= nil
end

---@param bridge BridgeLib.Bridge
---@param query string
---@param parameters table
---@return table? result nil when the query raised.
local function safeQuery(bridge, query, parameters)
	local success, result = pcall(function()
		return MySQL.query.await(query, parameters)
	end)

	if not success then
		bridge:Debug(("Character wipe query failed: %s (%s)"):format(query, tostring(result)))
		return nil
	end

	return result
end

---@param result table?
---@return number
local function affectedRows(result)
	return type(result) == "table" and tonumber(result.affectedRows) or 0
end

---@param value any
---@return table? decoded nil unless the value is a JSON object or array.
local function decodeJson(value)
	if type(value) ~= "string" then
		return nil
	end

	local success, decoded = pcall(json.decode, value)
	if not success or type(decoded) ~= "table" then
		return nil
	end

	return decoded
end

---Rebuilds a decoded JSON value without the identifier, arrays in order so they re-encode as arrays.
---@param value any
---@param identifier string
---@return any scrubbed, boolean changed
local function scrubJson(value, identifier)
	if type(value) ~= "table" then
		return value, false
	end

	local changed = false

	if value[1] ~= nil then
		local scrubbedArray = {}

		for _, entry in ipairs(value) do
			if entry == identifier then
				changed = true
			else
				local scrubbedEntry, entryChanged = scrubJson(entry, identifier)
				changed = changed or entryChanged
				scrubbedArray[#scrubbedArray + 1] = scrubbedEntry
			end
		end

		if scrubbedArray[1] == nil then
			scrubbedArray[1] = EMPTY_ARRAY_MARKER
		end

		return scrubbedArray, changed
	end

	local scrubbedObject = {}

	for key, entry in pairs(value) do
		if key == identifier or entry == identifier then
			changed = true
		else
			local scrubbedEntry, entryChanged = scrubJson(entry, identifier)
			changed = changed or entryChanged
			scrubbedObject[key] = scrubbedEntry
		end
	end

	return scrubbedObject, changed
end

---@param scrubbed any
---@return string
local function encodeScrubbed(scrubbed)
	return (json.encode(scrubbed):gsub(EMPTY_ARRAY_PATTERN, "[]"))
end

---@param bridge BridgeLib.Bridge
---@param tableName string
---@param column string
---@param identifier string
---@param wipe BridgeLib.CharacterWipe
local function wipeColumn(bridge, tableName, column, identifier, wipe)
	if not isSafeName(tableName) or not isSafeName(column) then
		bridge:Debug(("Skipping unsafe character table name '%s'.'%s'"):format(tostring(tableName), tostring(column)))
		return
	end

	wipe.columnsVisited = wipe.columnsVisited + 1

	local rows = safeQuery(
		bridge,
		("SELECT `%s` FROM `%s` WHERE `%s` LIKE ?"):format(column, tableName, column),
		{ "%" .. identifier .. "%" }
	)

	if not rows or #rows == 0 then
		return
	end

	local hasExactMatch = false

	for _, row in ipairs(rows) do
		local value = row[column]
		local decoded = decodeJson(value)

		if decoded then
			local scrubbed, changed = scrubJson(decoded, identifier)

			if changed then
				wipe.rowsUpdated = wipe.rowsUpdated + affectedRows(safeQuery(
					bridge,
					("UPDATE `%s` SET `%s` = ? WHERE `%s` = ?"):format(tableName, column, column),
					{ encodeScrubbed(scrubbed), value }
				))
			end
		elseif value == identifier then
			hasExactMatch = true
		end
	end

	if hasExactMatch then
		wipe.rowsDeleted = wipe.rowsDeleted + affectedRows(safeQuery(
			bridge,
			("DELETE FROM `%s` WHERE `%s` = ?"):format(tableName, column),
			{ identifier }
		))
	end
end

---@param ... BridgeLib.CharacterTables?
---@return BridgeLib.CharacterTables
local function mergeCharacterTables(...)
	local merged = {}

	for _, tables in ipairs({ ... }) do
		for tableName, columns in pairs(tables) do
			merged[tableName] = columns
		end
	end

	return merged
end

local DEFAULT_KICK_REASON = "This character has been deleted."
local DROP_TIMEOUT = 10000
local DROP_POLL_INTERVAL = 100
local DROP_SETTLE_TIME = 500

---Waits out the framework's save-on-drop, which would otherwise write the wiped rows straight back.
---@param bridge BridgeLib.Bridge
---@param identifier string
---@param reason string
---@return boolean gone false when the player was still loaded after `DROP_TIMEOUT`.
local function dropCharacterPlayer(bridge, identifier, reason)
	local player = bridge.exports.GetPlayerByIdentifier(identifier)
	if not player then
		return true
	end

	bridge:Debug(("Dropping player %d before wiping character '%s'"):format(player.Source, identifier))
	DropPlayer(player.Source, reason)

	local waited = 0

	while waited < DROP_TIMEOUT do
		Wait(DROP_POLL_INTERVAL)
		waited = waited + DROP_POLL_INTERVAL

		if not bridge.exports.GetPlayerByIdentifier(identifier) then
			Wait(DROP_SETTLE_TIME)
			return true
		end
	end

	return false
end

---Wipes one character everywhere `framework.characterTables` names. Needs oxmysql. No undo.
---@param bridge BridgeLib.Bridge
---@param identity BridgeLib.CharacterIdentity Where the framework keeps the character itself.
---@param frameworkTables BridgeLib.CharacterTables The rest of the framework's own tables.
---@param identifier string
---@param kickReason string? Shown to the player when they are connected.
---@return boolean wiped, BridgeLib.CharacterWipe wipe
local function deleteCharacter(bridge, identity, frameworkTables, identifier, kickReason)
	---@type BridgeLib.CharacterWipe
	local wipe = { columnsVisited = 0, rowsUpdated = 0, rowsDeleted = 0 }

	if not MySQL then
		bridge:Fatal("DeleteCharacter needs oxmysql loaded by the consuming resource")
		return false, wipe
	end

	if type(identifier) ~= "string" or identifier == "" then
		bridge:Debug("DeleteCharacter was given no identifier")
		return false, wipe
	end

	if not isSafeName(identity.table) or not isSafeName(identity.column) then
		bridge:Fatal("DeleteCharacter was given an unusable character table")
		return false, wipe
	end

	local existing = safeQuery(
		bridge,
		("SELECT 1 FROM `%s` WHERE `%s` = ? LIMIT 1"):format(identity.table, identity.column),
		{ identifier }
	)

	if not existing or #existing == 0 then
		bridge:Debug(("No character found for identifier '%s'"):format(identifier))
		return false, wipe
	end

	if not dropCharacterPlayer(bridge, identifier, kickReason or DEFAULT_KICK_REASON) then
		bridge:Debug(("Character '%s' is still loaded after being dropped, wipe abandoned"):format(identifier))
		return false, wipe
	end

	local tables = mergeCharacterTables(
		{ [identity.table] = identity.column },
		frameworkTables or {},
		bridge:GetModuleConfig("framework").characterTables or {}
	)

	for tableName, columns in pairs(tables) do
		if type(columns) == "table" then
			for _, column in ipairs(columns) do
				wipeColumn(bridge, tableName, column, identifier, wipe)
			end
		else
			wipeColumn(bridge, tableName, columns, identifier, wipe)
		end
	end

	bridge:Debug(("Wiped character '%s' across %d columns: %d rows deleted, %d rewritten"):format(
		identifier,
		wipe.columnsVisited,
		wipe.rowsDeleted,
		wipe.rowsUpdated
	))

	return true, wipe
end

---@class BridgeLib.Framework.Server
local schema = {
	---Registers the framework's player lifecycle events and forwards them to `bridge:Emit`.
	InitNetworkEvents = function() end,

	---@param src number
	---@return BridgeLib.Player? player nil when no player is loaded for that source.
	GetPlayer = function(src) end,

	---@param identifier string
	---@return BridgeLib.Player? player nil when that identifier is not currently connected.
	GetPlayerByIdentifier = function(identifier) end,

	---@return BridgeLib.Player[]
	GetPlayers = function() end,

	---@param src number
	---@param message string
	---@param type string? Framework notification style, typically "success", "error" or "primary".
	---@param length number? Milliseconds to display for.
	Notify = function(src, message, type, length) end,

	---Registers item definitions with the framework at runtime.
	---@param items table Item definitions, in the shape the framework expects.
	---@return boolean
	AddItems = function(items) end,

	---@param itemName string
	---@param callback fun(source: number, item: table)
	CreateUseableItem = function(itemName, callback) end,

	---@param item string
	---@return string label Falls back to the item name when the item is unknown.
	GetItemDisplayName = function(item) end,

	---The framework's whole job catalog, keyed by job name.
	---@return table<string, BridgeLib.Job>
	GetJobs = function() end,

	---Rebuilds the framework's job cache. A no-op on frameworks that keep none.
	RefreshJobs = function() end,

	---@param identifier string
	---@return string name "Unknown" when the identifier is not on record.
	GetOfflinePlayerName = function(identifier) end,

	---Writes a job onto an offline player. Needs oxmysql loaded by the consuming resource.
	---@param identifier string
	---@param jobName string
	---@param grade number
	---@return boolean written
	SetOfflinePlayerJob = function(identifier, jobName, grade) end,

	---Wipes a character everywhere `framework.characterTables` names, dropping them first. No undo.
	---@param identifier string
	---@param kickReason string? Shown to the player when they are connected.
	---@return boolean wiped false when the identifier is not on record, or the player would not drop.
	---@return BridgeLib.CharacterWipe wipe What the wipe touched.
	DeleteCharacter = function(identifier, kickReason) end,
}

---@type BridgeLib.Module
return {
	name = "framework",
	context = "server",
	providers = {
		"qb-core",
		"es_extended",
	},
	events = {
		"playerLoaded",
		"playerUnloaded",
		"jobUpdated",
	},
	required = {
		"InitNetworkEvents",
		"GetPlayer",
		"GetPlayerByIdentifier",
		"GetPlayers",
		"Notify",
		"AddItems",
		"CreateUseableItem",
		"GetItemDisplayName",
		"GetJobs",
		"RefreshJobs",
		"GetOfflinePlayerName",
		"SetOfflinePlayerJob",
		"DeleteCharacter",
	},
	schema = schema,

	---The framework agnostic half of `DeleteCharacter`, which a provider calls with its own tables.
	characterData = {
		DeleteCharacter = deleteCharacter,
	},
}
