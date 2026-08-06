---Translations, pulled from the monstor-versions API and cached in the resource.
---
---A resource ships `locales/en.json`, so a server with no internet and nothing downloaded still has
---every string. Every language is then fetched from the API and written to `locales/<language>.json`,
---English included: the API is the source of truth for wording, and the shipped file is the floor
---under it. A key the download is missing keeps the string the resource shipped rather than nothing.
---
---For a language other than English the download is an overlay merged over the shipped English, so an
---untranslated key still reads in English. For English itself the download lands in the shipped file
---directly, which is the one case where a fetch rewrites a file that came with the resource.
---
---On top of both sits `locales/<language>.local.json`, which the API never writes and a fetch never
---replaces. It is the server owner's file: any key put in it wins over the shipped and downloaded
---strings for that language, and a key left out of it changes nothing. Renaming a notification or
---rewording one line is a two-key file rather than a fork of the whole locale.
---
---Files are i18next shaped - nested objects, keys as dot paths once flattened - which is the shape
---the API serves and the shape `ox_lib` reads, so the cache file is a normal locale file that can
---also be edited by hand.
---
---The server owns the fetch. A file written at runtime is not in the resource's manifest for this
---session, so clients cannot download it until the next restart; instead the server hands its
---merged strings to each client that asks, and pushes them again when a fetch changes them. Clients
---render what they have on file until that lands, which is the same second the bridge comes up.

---@class BridgeLib.Locales.Settings
---@field enabled boolean? Set to false to never contact the API, using only the files on disk.
---@field language string? Language to render in, defaulting to the shipped English.
---@field apiUrl string? Overrides the hosted API.
---@field delay number? Milliseconds to wait after startup before fetching.

local Locales = {}

Locales.ApiUrl = "https://versions.monstorscripts.com"

Locales.Delay = 5000

---The language every resource ships, the fallback for a key an overlay does not translate, and the
---one language whose download is written straight back into the shipped file.
Locales.SourceLanguage = "en"

---Net event a client raises to ask for the strings the server ended up with, since it cannot read a
---file written after the resource started. Carries the resource name: event names are global to the
---server, so every resource's handler sees every request and answers only for its own.
Locales.RequestEvent = "BridgeLib:locales:request"

---Net event carrying one resource's strings back to a client.
Locales.DeliverEvent = "BridgeLib:locales:deliver"

---GlobalState key naming the language the server renders in. `config.lua` is never shipped to
---clients, so a client cannot read the setting itself and learns it from here instead.
Locales.LanguageKey = "bridgeLibLocalesLanguage"

---Seconds a client must wait between requests, so the event cannot be used to make the server
---serialize a string table on a loop.
Locales.RequestCooldown = 5

---Milliseconds a client waits before reading the language, since a bridge built while the player is
---still connecting can run before the server's `GlobalState` has replicated.
Locales.ReplicationDelay = 2000

---Flat strings per resource, keyed by the runtime's own resource name. One Lua runtime is one
---resource, so this only ever holds one entry - it is keyed anyway so a mismatched delivery is
---dropped rather than overwriting the wrong table.
---@type table<string, table<string, string>>
Locales.strings = {}

---The owner's `locales/<language>.local.json` overrides per resource, kept apart from the merged
---strings so a fetch landing later can be layered under them again rather than over them.
---@type table<string, table<string, string>>
Locales.overrides = {}

---The shipped English strings per resource, kept unmerged so a fetch can rebuild the whole table
---from the bottom up. Merging a download over the already-merged table would leave a key the API has
---since dropped sitting there with its stale cached translation.
---@type table<string, table<string, string>>
Locales.source = {}

---Resources already registered from this Lua runtime, so a resource building both a client and a
---server bridge only sets itself up once per context.
---@type table<string, boolean>
Locales.registered = {}

---Last request time per player, for `RequestCooldown`.
---@type table<number, number>
Locales.lastRequest = {}

---Nested locale table to flat dot paths. A value that is neither a string nor a table is dropped:
---the API only ever stores strings, so anything else is a hand-edited file gone wrong.
---@param node table
---@param prefix string?
---@param out table<string, string>?
---@return table<string, string>
function Locales.Flatten(node, prefix, out)
	out = out or {}

	for key, value in pairs(node) do
		local path = prefix and ("%s.%s"):format(prefix, key) or tostring(key)

		if type(value) == "string" then
			out[path] = value
		elseif type(value) == "table" then
			Locales.Flatten(value, path, out)
		end
	end

	return out
end

---Reads one locale file out of the resource and flattens it. A missing or malformed file resolves
---to nothing, so a resource that ships no translations simply has none.
---@param resourceName string
---@param path string
---@return table<string, string>?
function Locales.ReadFile(resourceName, path)
	local contents = LoadResourceFile(resourceName, path)
	if not contents then
		return nil
	end

	local success, decoded = pcall(json.decode, contents)
	if not success or type(decoded) ~= "table" then
		return nil
	end

	return Locales.Flatten(decoded)
end

---Path of the file a language is downloaded and cached into.
---@param language string
---@return string
function Locales.CachePath(language)
	return ("locales/%s.json"):format(language)
end

---Path of the owner's override file for a language, which nothing but the owner ever writes.
---@param language string
---@return string
function Locales.OverridePath(language)
	return ("locales/%s.local.json"):format(language)
end

---Counts the entries in a flat string table.
---@param strings table<string, string>?
---@return number
function Locales.Count(strings)
	local total = 0

	for _ in pairs(strings or {}) do
		total = total + 1
	end

	return total
end

---A shallow copy of a flat string table, so a layer can be merged into without losing the original.
---@param strings table<string, string>
---@return table<string, string>
function Locales.Copy(strings)
	local copy = {}

	for key, value in pairs(strings) do
		copy[key] = value
	end

	return copy
end

---The keys an overlay actually replaces in a base, sorted so two runs of the same files log the same
---lines. A key the overlay introduces that the base never had is not a replacement and is left out.
---@param base table<string, string>
---@param overlay table<string, string>?
---@return string[]
function Locales.ReplacedKeys(base, overlay)
	local keys = {}

	for key in pairs(overlay or {}) do
		if base[key] ~= nil then
			keys[#keys + 1] = key
		end
	end

	table.sort(keys)

	return keys
end

---The keys an overlay holds that the base never had, sorted. In an override file these are almost
---always a typo in the key path: nothing asks for them, so nothing renders them.
---@param base table<string, string>
---@param overlay table<string, string>?
---@return string[]
function Locales.AddedKeys(base, overlay)
	local keys = {}

	for key in pairs(overlay or {}) do
		if base[key] == nil then
			keys[#keys + 1] = key
		end
	end

	table.sort(keys)

	return keys
end

---The keys whose rendered string differs between two builds of a table, sorted. A key present in one
---side only counts as a difference, which is how a translation the API has dropped shows up.
---@param previous table<string, string>
---@param current table<string, string>
---@return string[]
function Locales.ChangedKeys(previous, current)
	local seen = {}
	local keys = {}

	for key, value in pairs(current) do
		seen[key] = true

		if previous[key] ~= value then
			keys[#keys + 1] = key
		end
	end

	for key in pairs(previous) do
		if not seen[key] then
			keys[#keys + 1] = key
		end
	end

	table.sort(keys)

	return keys
end

---Prints a count under a `Report` line and then every key behind it, with the string that key ends up
---rendering, so the console shows exactly which layer set what without turning anything on.
---@param keys string[]
---@param message string
---@param values table<string, string>? Renders each key's resulting string beside it.
function Locales.ReportKeys(keys, message, values)
	if #keys == 0 then
		return
	end

	print(("^7  %s^0"):format(message:format(#keys)))

	for index = 1, #keys do
		local key = keys[index]
		local value = values and values[key]

		if value ~= nil then
			print(("^7    %s = %s^0"):format(key, value))
		else
			print(("^7    %s^0"):format(key))
		end
	end
end

---Copies an overlay over a base, keeping the base's value for any key the overlay leaves out.
---@param base table<string, string>
---@param overlay table<string, string>?
function Locales.Merge(base, overlay)
	for key, value in pairs(overlay or {}) do
		base[key] = value
	end
end

---Renders one key. Substitutions replace `%{name}` placeholders. An unknown key renders as itself
---so a missing translation shows up as the key rather than as an empty notification.
---@param resourceName string
---@param key string
---@param substitutions table<string, any>?
---@return string
function Locales.Get(resourceName, key, substitutions)
	local value = Locales.strings[resourceName] and Locales.strings[resourceName][key]
	if type(value) ~= "string" then
		return key
	end

	if not substitutions then
		return value
	end

	return (value:gsub("%%{(.-)}", function(name)
		local substitution = substitutions[name]
		return substitution ~= nil and tostring(substitution) or ("%%{%s}"):format(name)
	end))
end

---Installs `Locale` on the bridge, so consuming resources call `Bridge.Locale('shop.tooFar')`.
---@param bridge BridgeLib.Bridge
---@param resourceName string
function Locales.Install(bridge, resourceName)
	bridge.exports.Locale = function(key, substitutions)
		return Locales.Get(resourceName, key, substitutions)
	end

	bridge:MarkImplemented({ "Locale" })
end

---Loads the shipped English file, whatever of the configured language has already been cached, and
---the owner's override file, in that order of precedence.
---@param resourceName string
---@param language string
---@return boolean shipsStrings Whether the resource ships an English file at all.
---@return number cached How many strings came out of the cached file, before any fetch.
---@return number overridden How many strings the owner's override file replaces.
function Locales.LoadFiles(resourceName, language)
	local source = Locales.ReadFile(resourceName, Locales.CachePath(Locales.SourceLanguage))
	if not source then
		return false, 0, 0
	end

	Locales.source[resourceName] = Locales.Copy(source)

	local cached = Locales.Count(source)

	if language ~= Locales.SourceLanguage then
		local overlay = Locales.ReadFile(resourceName, Locales.CachePath(language))
		cached = Locales.Count(overlay)

		Locales.Merge(source, overlay)
	end

	local overrides = Locales.ReadFile(resourceName, Locales.OverridePath(language)) or {}
	Locales.overrides[resourceName] = overrides
	Locales.Merge(source, overrides)

	Locales.strings[resourceName] = source
	return true, cached, Locales.Count(overrides)
end

---Prints the outcome of a fetch. A server that asked for a language wants to know whether it
---arrived, so unlike the update check this reports its failures too: silence would be
---indistinguishable from a resource quietly running in English.
---@param resourceName string
---@param language string
---@param message string
---@param isError boolean?
function Locales.Report(resourceName, language, message, isError)
	print(("%s[%s] %s: %s^0"):format(isError and "^3" or "^2", resourceName, language, message))
end

---Fetches one language from the API, caches it for the next start and merges it in for this one.
---@param bridge BridgeLib.Bridge
---@param settings BridgeLib.Locales.Settings
---@param resourceName string
---@param language string
function Locales.Fetch(bridge, settings, resourceName, language)
	local url = ("%s/v1/scripts/%s/locales/%s?shape=nested"):format(
		settings.apiUrl or Locales.ApiUrl,
		resourceName:lower(),
		language
	)

	bridge:Verbose(("Requesting translations from %s"):format(url))

	PerformHttpRequest(url, function(status, body)
		if status ~= 200 or type(body) ~= "string" then
			Locales.Report(resourceName, language, ("no translations downloaded, the API returned status %s"):format(status), true)
			return
		end

		local success, response = pcall(json.decode, body)
		if not success or type(response) ~= "table" or type(response.strings) ~= "table" then
			Locales.Report(resourceName, language, "no translations downloaded, the API returned nothing usable", true)
			return
		end

		local overlay = Locales.Flatten(response.strings)
		local downloaded = Locales.Count(overlay)

		if downloaded == 0 then
			Locales.Report(resourceName, language, "the API holds no translations for this resource yet", true)
			return
		end

		local shipped = 0
		local translated = 0
		for key in pairs(Locales.source[resourceName]) do
			shipped = shipped + 1
			if overlay[key] then
				translated = translated + 1
			end
		end

		SaveResourceFile(resourceName, Locales.CachePath(language), json.encode(response.strings), -1)

		local previous = Locales.strings[resourceName]

		local rebuilt = Locales.Copy(Locales.source[resourceName])
		Locales.Merge(rebuilt, overlay)
		Locales.Merge(rebuilt, Locales.overrides[resourceName])

		Locales.strings[resourceName] = rebuilt

		Locales.Report(
			resourceName,
			language,
			("downloaded %d strings, %d of %d keys translated, cached in locales/%s.json"):format(
				downloaded,
				translated,
				shipped,
				language
			)
		)

		Locales.ReportKeys(
			Locales.ChangedKeys(previous, rebuilt),
			"%d strings now read differently than they did before the download.",
			rebuilt
		)

		Locales.ReportKeys(
			Locales.ReplacedKeys(overlay, Locales.overrides[resourceName]),
			("%%d downloaded strings stay replaced by locales/%s.local.json."):format(language),
			Locales.overrides[resourceName]
		)

		if translated < shipped then
			print(
				("^7  %d keys are not in the download and keep the string the resource shipped.^0"):format(
					shipped - translated
				)
			)
		end

		TriggerClientEvent(Locales.DeliverEvent, -1, resourceName, Locales.strings[resourceName])
	end, "GET")
end

---Answers clients asking for this resource's strings.
---@param resourceName string
function Locales.Serve(resourceName)
	RegisterNetEvent(Locales.RequestEvent, function(requested)
		if requested ~= resourceName then
			return
		end

		local playerId = source
		local now = os.time()

		if Locales.lastRequest[playerId] and now - Locales.lastRequest[playerId] < Locales.RequestCooldown then
			return
		end
		Locales.lastRequest[playerId] = now

		TriggerClientEvent(Locales.DeliverEvent, playerId, resourceName, Locales.strings[resourceName])
	end)

	AddEventHandler("playerDropped", function()
		Locales.lastRequest[source] = nil
	end)
end

---Takes the strings the server settled on, whether they came from a file this client never
---downloaded or from a fetch that landed after it connected. Asked for unconditionally, since even
---an English server can be rendering strings the API changed after the client's files were built.
---@param resourceName string
function Locales.Receive(resourceName)
	RegisterNetEvent(Locales.DeliverEvent, function(delivered, strings)
		if delivered ~= resourceName or type(strings) ~= "table" then
			return
		end

		Locales.strings[resourceName] = strings
	end)

	CreateThread(function()
		Wait(Locales.ReplicationDelay)

		TriggerServerEvent(Locales.RequestEvent, resourceName)
	end)
end

---Sets the current resource up for translation. Called by `BridgeLib.New` for every bridge; calling
---it again for the same resource and context is a no-op.
---@param bridge BridgeLib.Bridge
function Locales.Register(bridge)
	local resourceName = GetCurrentResourceName()
	local registration = ("%s:%s"):format(resourceName, bridge.context)

	if Locales.registered[registration] then
		return
	end
	Locales.registered[registration] = true

	---@type BridgeLib.Locales.Settings
	local settings = bridge.context == "server" and bridge:GetModuleConfig("locales") or {}
	local language = settings.language or GlobalState[Locales.LanguageKey] or Locales.SourceLanguage

	local shipsStrings, cached, overridden = Locales.LoadFiles(resourceName, language)

	if not shipsStrings then
		Locales.strings[resourceName] = {}
		Locales.overrides[resourceName] = {}
		Locales.source[resourceName] = {}
		Locales.Install(bridge, resourceName)
		return
	end

	Locales.Install(bridge, resourceName)

	if bridge.context == "client" then
		Locales.Receive(resourceName)
		return
	end

	if bridge.context ~= "server" then
		return
	end

	if overridden > 0 then
		Locales.Report(
			resourceName,
			language,
			("%d strings replaced from locales/%s.local.json"):format(overridden, language)
		)

		local overrides = Locales.overrides[resourceName]

		Locales.ReportKeys(
			Locales.ReplacedKeys(Locales.source[resourceName], overrides),
			"%d of them replace a shipped string.",
			overrides
		)

		Locales.ReportKeys(
			Locales.AddedKeys(Locales.source[resourceName], overrides),
			"%d of them are keys no shipped file has, so nothing renders them.",
			overrides
		)
	end

	GlobalState[Locales.LanguageKey] = language

	Locales.Serve(resourceName)

	if settings.enabled == false then
		Locales.Report(resourceName, language, ("using %d cached strings, the API is disabled"):format(cached), cached == 0)
		return
	end

	Locales.Report(
		resourceName,
		language,
		cached > 0 and ("using %d strings from file, checking the API for changes"):format(cached)
			or "nothing on file yet, asking the API"
	)

	CreateThread(function()
		Wait(settings.delay or Locales.Delay)

		Locales.Fetch(bridge, settings, resourceName, language)
	end)
end

return Locales
