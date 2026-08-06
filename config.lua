---BridgeLib configuration.
---
---One section per module. A section left at its defaults means the module falls back to whatever it
---does with no configuration, so an untouched file is a valid one.
---
---Editing this file is the usual way to configure the library. A server that would rather keep its
---secrets out of the repository can call `BridgeLib.SetConfig(table)` before building a bridge, and
---the table passed in replaces this file entirely.
---
---This file is deliberately absent from the manifest's `files()`, so it is never downloaded to a
---client. Only server contexts can read it, which is what makes it safe to keep webhook URLs in
---here. Listing it in `files()` would hand every secret in it to every player who connects.

return {
	---Startup update check. Every server bridge enlists the resource that built it, using the resource
	---name lowercased as the slug and the `version` from its `fxmanifest.lua`. One resource then asks
	---the API about all of them in a single request. Nothing about the server is sent, only the slugs
	---and versions.
	versions = {
		enabled = true,

		---Point this at your own deployment of monstor-versions to check against that instead.
		apiUrl = "https://versions.monstorscripts.com",

		---Milliseconds to wait after startup, both to keep the check out of the boot log and to give
		---every resource time to enlist before the one request goes out.
		delay = 5000,
	},

	---Translations. Every resource ships `locales/en.json`, so a server with no internet still reads
	---correctly. Whatever `language` is set to is pulled from the API once per start and written to
	---`locales/<language>.json` in the resource, English included, so wording fixes arrive without a
	---resource update. A language other than English is merged over the English one, leaving a key it
	---has not translated yet reading in English.
	---
	---Any key you put in `locales/<language>.local.json` wins over both and is never overwritten by a
	---download, which is the place to reword a string for your server.
	locales = {
		enabled = true,

		---Language code as the API stores it: `fr`, `de`, `pt-BR`.
		language = "en",

		---Point this at your own deployment of monstor-versions to pull translations from that instead.
		apiUrl = "https://versions.monstorscripts.com",

		---Milliseconds to wait after startup before fetching. The cached file is already loaded by
		---then, so this only delays picking up strings that changed since the last start.
		delay = 5000,
	},

	---Framework. Every table outside the framework's own that holds a character identifier, so
	---`DeleteCharacter` can wipe a character out of all of them.
	---
	---The framework's own tables are already covered by its provider - `users`, `owned_vehicles` and
	---friends on ESX, `players` and `player_vehicles` on qb-core. What goes here is everything else:
	---the third party resources a particular server happens to run.
	---
	---A value is either one column name or a list of them. Names are interpolated into the statement,
	---so anything that is not a bare identifier is refused. A table that does not exist is logged and
	---skipped, which makes an over-long list harmless.
	framework = {
		characterTables = {
			-- ["okokbanking_accounts"] = "account_holder",
			-- ["okokbanking_transactions"] = { "receiver_identifier", "sender_identifier" },
			-- ["mdt_cases"] = { "citizens", "officers", "author", "edited_by" },
			-- ["properties_owners"] = "identifier",
		},
	},

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

	---Phone. A server running lb-phone or npwd needs nothing here; their providers are picked up
	---automatically.
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
