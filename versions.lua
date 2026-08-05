---Startup update check against the monstor-versions API.
---
---Every server bridge enlists the resource that built it: the slug is the resource name lowercased
---and the version comes out of `fxmanifest.lua`, so a resource opts in by having a server bridge and
---declaring a `version`. A resource without one is skipped rather than reported.
---
---Enlisting writes one `GlobalState` key per resource, which every resource on the server can read.
---One bridge claims the job, waits out the startup delay, gathers every enlisted resource and checks
---them in one request, so a server running fifteen resources still makes a single call. Each result
---is then handed back over a server event to the resource it belongs to, which prints its own line.

---@class BridgeLib.Versions.Change
---@field version string
---@field type string
---@field body string

---@class BridgeLib.Versions.Result
---@field slug string
---@field current string
---@field latest string?
---@field update_available boolean
---@field breaking_change boolean
---@field breaking_since string?
---@field released_at string?
---@field changes BridgeLib.Versions.Change[]?
---@field error string?

---@class BridgeLib.Versions.Settings
---@field enabled boolean? Set to false to never contact the API.
---@field apiUrl string? Overrides the hosted API.
---@field delay number? Milliseconds to wait after startup before checking.

local Versions = {}

Versions.ApiUrl = "https://versions.monstorscripts.com"

Versions.Delay = 5000

---GlobalState key prefix. Each resource writes its own `<prefix>:<slug>` key holding its version,
---never a shared table: a state bag write only lands on the next tick, so resources reading a shared
---table and writing it back all read the same empty one and the last write would win.
Versions.StateKey = "bridgeLibVersions"

---GlobalState key naming the resource that will make the request.
Versions.LeaderKey = "bridgeLibVersionsLeader"

---Server event the checking resource hands each result back on, so every resource prints its own
---line from its own runtime and the console attributes it to the right script. Deliberately not a
---net event: nothing outside the server can raise it.
Versions.ResultEvent = "BridgeLib:versions:result"

---Slugs already enlisted from this Lua runtime, so a resource building more than one server bridge
---still enlists once.
---@type table<string, boolean>
Versions.registered = {}

---@param result BridgeLib.Versions.Result
function Versions.Report(result)
	if result.error then
		return
	end

	if not result.update_available then
		print(("^2[%s] %s, no update needed.^0"):format(result.slug, result.current))
		return
	end

	print(("^3[%s] Update available: %s -> %s^0"):format(result.slug, result.current, result.latest))

	for _, change in ipairs(result.changes or {}) do
		print(("^7  %s  %s: %s^0"):format(change.version, change.type, change.body))
	end

	if result.breaking_change then
		print(("^1[%s] %s is a breaking release, read the changelog before updating.^0"):format(result.slug, result.breaking_since))
	end
end

---@param slug string
---@return string
function Versions.StateKeyFor(slug)
	return ("%s:%s"):format(Versions.StateKey, slug)
end

---Marks one resource as wanting an update check, on a key of its own.
---@param slug string
---@param version string
function Versions.Enlist(slug, version)
	GlobalState[Versions.StateKeyFor(slug)] = version
end

---Every resource running on this server that enlisted itself, as `slug@version`. State bags cannot
---be enumerated, so the resource list is walked and each name tested for its own key.
---@return string[]
function Versions.Enlisted()
	local entries = {}

	for index = 0, GetNumResources() - 1 do
		local resourceName = GetResourceByFindIndex(index)
		local slug = resourceName and resourceName:lower()
		local version = slug and GlobalState[Versions.StateKeyFor(slug)]

		if version and GetResourceState(resourceName) == "started" then
			entries[#entries + 1] = ("%s@%s"):format(slug, version)
		end
	end

	table.sort(entries)
	return entries
end

---Checks every enlisted resource in one request and hands each result to the resource it belongs to.
---@param bridge BridgeLib.Bridge
---@param settings BridgeLib.Versions.Settings
function Versions.Check(bridge, settings)
	local entries = Versions.Enlisted()

	if #entries == 0 then
		return
	end

	bridge:Verbose(("Checking %d resources for updates"):format(#entries))

	local url = ("%s/v1/scripts/check?scripts=%s"):format(settings.apiUrl or Versions.ApiUrl, table.concat(entries, ","))

	PerformHttpRequest(url, function(status, body)
		if status ~= 200 or type(body) ~= "string" then
			bridge:Verbose(("Update check returned status %s"):format(status))
			return
		end

		local success, response = pcall(json.decode, body)
		if not success or type(response) ~= "table" or type(response.results) ~= "table" then
			bridge:Verbose("Update check returned nothing usable")
			return
		end

		for _, result in ipairs(response.results) do
			TriggerEvent(Versions.ResultEvent, result)
		end
	end, "GET")
end

---Waits for this resource's own result, wherever the request was made from.
---@param slug string
function Versions.Listen(slug)
	AddEventHandler(Versions.ResultEvent, function(result)
		if type(result) == "table" and result.slug == slug then
			Versions.Report(result)
		end
	end)
end

---Claims the bulk check for this resource. Resources loading in the same tick all read an unset key
---and all claim it, so the claim is re-tested after the delay, once the writes have landed and one
---name has won. Only that resource makes the request.
---@param bridge BridgeLib.Bridge
---@param settings BridgeLib.Versions.Settings
function Versions.Elect(bridge, settings)
	local resourceName = GetCurrentResourceName()
	local leader = GlobalState[Versions.LeaderKey]

	if leader and leader ~= resourceName then
		return
	end

	GlobalState[Versions.LeaderKey] = resourceName

	CreateThread(function()
		Wait(settings.delay or Versions.Delay)

		if GlobalState[Versions.LeaderKey] ~= resourceName then
			return
		end

		Versions.Check(bridge, settings)
	end)
end

---Enlists the current resource for the startup update check. Called by `BridgeLib.New` for every
---server bridge; calling it again for the same resource is a no-op.
---@param bridge BridgeLib.Bridge
function Versions.Register(bridge)
	local resourceName = GetCurrentResourceName()
	local slug = resourceName:lower()

	if Versions.registered[slug] then
		return
	end
	Versions.registered[slug] = true

	---@type BridgeLib.Versions.Settings
	local settings = bridge:GetModuleConfig("versions")
	if settings.enabled == false then
		return
	end

	local currentVersion = GetResourceMetadata(resourceName, "version", 0)
	if not currentVersion then
		bridge:Verbose("No version declared in fxmanifest.lua, skipping the update check")
		return
	end

	Versions.Listen(slug)
	Versions.Enlist(slug, currentVersion)
	Versions.Elect(bridge, settings)
end

return Versions
