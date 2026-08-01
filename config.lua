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
}
