---Startup update check against the monstor-versions API, batched into one request per server.

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

---Prefix for a per-resource key, never a shared table: a state bag write lands only on the next tick.
Versions.StateKey = "bridgeLibVersions"

Versions.LeaderKey = "bridgeLibVersionsLeader"

---Marks the startup request as gone out, so anything enlisting later is a live restart.
Versions.CheckedKey = "bridgeLibVersionsChecked"

---Deliberately not a net event: nothing outside the server can raise it.
Versions.ResultEvent = "BridgeLib:versions:result"

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

---@param slug string
---@param version string
function Versions.Enlist(slug, version)
	GlobalState[Versions.StateKeyFor(slug)] = version
end

---Every enlisted resource as `slug@version`. State bags cannot be enumerated, so names are walked.
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

---Checks every `slug@version` entry in one request, handing each result to the resource it belongs to.
---@param bridge BridgeLib.Bridge
---@param settings BridgeLib.Versions.Settings
---@param entries string[]
function Versions.Check(bridge, settings, entries)
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

---@param resourceName string?
---@return boolean
function Versions.IsRunning(resourceName)
	if not resourceName then
		return false
	end

	local state = GetResourceState(resourceName)
	return state == "started" or state == "starting"
end

---Checks this resource alone, for a restart into a server whose startup request has already gone out.
---@param bridge BridgeLib.Bridge
---@param settings BridgeLib.Versions.Settings
---@param slug string
---@param version string
function Versions.CheckAlone(bridge, settings, slug, version)
	CreateThread(function()
		Wait(settings.delay or Versions.Delay)

		Versions.Check(bridge, settings, { ("%s@%s"):format(slug, version) })
	end)
end

---Claims the bulk check, re-testing the claim after the delay since same-tick writes all win at first.
---@param bridge BridgeLib.Bridge
---@param settings BridgeLib.Versions.Settings
function Versions.Elect(bridge, settings)
	local resourceName = GetCurrentResourceName()
	local leader = GlobalState[Versions.LeaderKey]

	if leader and leader ~= resourceName and Versions.IsRunning(leader) then
		return
	end

	GlobalState[Versions.LeaderKey] = resourceName

	CreateThread(function()
		Wait(settings.delay or Versions.Delay)

		if GlobalState[Versions.LeaderKey] ~= resourceName then
			return
		end

		GlobalState[Versions.CheckedKey] = true

		Versions.Check(bridge, settings, Versions.Enlisted())
	end)
end

---Called by `BridgeLib.New` for every server bridge; a repeat call for the same resource is a no-op.
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

	if GlobalState[Versions.CheckedKey] then
		Versions.CheckAlone(bridge, settings, slug, currentVersion)
		return
	end

	Versions.Elect(bridge, settings)
end

return Versions
