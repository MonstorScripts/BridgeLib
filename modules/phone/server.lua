---One message as every provider reports it, whatever the phone stores underneath.
---@class BridgeLib.Phone.Message
---@field sender string
---@field recipient string?
---@field content string
---@field timestamp string|number
---@field conversationId (string|number)?

---@class BridgeLib.Phone.Server
local schema = {
	---True when a phone resource actually backs this module.
	---@return boolean
	HasPhone = function()
		return false
	end,

	---@param number string|number
	---@return string
	FormatNumber = function(number)
		return tostring(number)
	end,

	---The character identifier a number is registered to, whether or not they are connected.
	---@param number string|number
	---@return string? identifier
	FindNumberOwner = function(number)
		return nil
	end,

	---Resolves the one to one conversation two numbers share, in whatever identifier the phone uses.
	---@param numberA string|number
	---@param numberB string|number
	---@return (string|number)? conversationId
	FindConversation = function(numberA, numberB)
		return nil
	end,

	---Every stored message in a conversation, oldest first.
	---@param conversationId string|number
	---@return BridgeLib.Phone.Message[]
	GetConversationMessages = function(conversationId)
		return {}
	end,
}

---@type BridgeLib.Module
return {
	name = "phone",
	context = "server",
	providers = {
		"lb-phone",
		"npwd",
		---Last resort: always matches, and resolves to nothing unless `phone.database` is configured.
		{ adapter = "sql" },
	},
	schema = schema,
	events = { "messageSent" },
}
