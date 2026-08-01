---BridgeLib configuration.
---
---One section per module. A section left at its defaults means the module falls back to whatever it
---does with no configuration, so an untouched file is a valid one.
---
---Editing this file is the usual way to configure the library. A server that would rather keep its
---secrets out of the repository can call `BridgeLib.SetConfig(table)` before building a bridge, and
---the table passed in replaces this file entirely.

return {
	---Discord logging. Consuming resources pick the category name they log under; the ones the
	---monstor scripts use are listed below. `default` catches every category without its own URL,
	---and a category that resolves to no URL at all is dropped rather than erroring.
	logging = {
		webhooks = {
			default = "",

			BossMenu = "",
			Shop = "",
			clothingjob = "",
			hunting = "",
		},

		---Overrides the name and picture Discord shows for the webhook. Left empty, Discord uses
		---whatever the webhook itself is configured with.
		username = "",
		avatarUrl = "",

		---Appended to the bottom of every embed when set.
		footer = "",
	},

	---Phone. A server running lb-phone needs nothing here; its provider is picked up automatically.
	---
	---Any other phone is described below instead of being coded against, so long as it stores threads
	---in one of the two supported layouts. Leaving `database` unset means the phone module falls back
	---to its stubs and features that read messages report themselves as unavailable.
	phone = {
		database = nil,

		---Example for a phone with one row per participant, the layout lb-phone and its relatives use:
		---
		---database = {
		---	layout = "members",
		---	membersTable = "phone_message_members",
		---	conversationColumn = "channel_id",
		---	numberColumn = "phone_number",
		---
		---	messagesTable = "phone_message_messages",
		---	senderColumn = "sender",
		---	contentColumn = "content",
		---	timestampColumn = "timestamp",
		---
		---	---Optional, only when the messages table names the conversation differently.
		---	messagesConversationColumn = "channel_id",
		---
		---	---Optional. Mirrors whatever event the phone fires when a message is sent, so live
		---	---features work. Values are the field names on that event's payload table.
		---	messageEvent = {
		---		name = "some-phone:messageSent",
		---		conversationId = "channelId",
		---		sender = "sender",
		---		recipient = "recipient",
		---		content = "message",
		---	},
		---}
		---
		---Example for a phone holding both numbers on the conversation row itself:
		---
		---database = {
		---	layout = "pair",
		---	conversationsTable = "phone_conversations",
		---	conversationColumn = "id",
		---	firstNumberColumn = "sender",
		---	secondNumberColumn = "receiver",
		---
		---	messagesTable = "phone_messages",
		---	messagesConversationColumn = "conversation_id",
		---	senderColumn = "sender",
		---	contentColumn = "message",
		---	timestampColumn = "created_at",
		---}
	},
}
