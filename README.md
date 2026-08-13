# BridgeLib

A resource-agnostic bridge layer for FiveM Lua resources.

It ships a **catalog** of adapters — `qb-core`, `es_extended`, `ox_inventory`, `qb-inventory`,
`ox_target`, `qb-target`, `rcore_fuel`, `LegacyFuel`, `qb-vehiclekeys`, `cd_dispatch`, `lb-phone`,
`npwd` —
grouped into modules (`framework`, `inventory`, `target`, `fuel`, `vehiclekeys`, `dispatch`,
`phone`). Your resource asks for the modules it needs, BridgeLib picks whichever supported resource
is actually running, and you get one flat table of functions to call. Adding support for a new
resource means adding one file here, and every consuming resource gets it.

Nothing in this library knows about the resource consuming it: no globals, no namespace
assumptions, and the only FiveM natives it touches are `GetResourceState` and event registration
inside the adapters themselves.

## Install

### As its own resource

Drop the folder in your resources and `ensure` it before its consumers. Its `fxmanifest.lua` only
declares `files`, so nothing is executed on start — the consuming resource pulls what it needs
through ox_lib's cross-resource `require`:

```lua
local BridgeLib = require("@BridgeLib.init")
BridgeLib.SetRoot("@BridgeLib")
```

The consumer needs `@ox_lib/init.lua` in its own `shared_scripts` for `require` to exist, and
`BridgeLib` must be started, or the client never receives the files.

### As a submodule

Add it at the root of your resource:

```bash
git submodule add <repo-url> BridgeLib
```

Then make sure the files reach the client — in `fxmanifest.lua`:

```lua
shared_scripts({
    "@ox_lib/init.lua",
    "BridgeLib/**.lua",
    -- your files
})
```

One glob in `shared_scripts` keeps the manifest maintenance-free as the catalog grows, at the cost
of shipping the server adapters to clients as well. They contain no secrets — keep it that way when
adding adapters, or split the globs per context.

No file in this library `require`s another, so it can be mounted at any path. If you mount it
somewhere other than `BridgeLib/`, tell it where it lives so it can find its own modules:

```lua
local BridgeLib = require("vendor.BridgeLib.init")
BridgeLib.SetRoot("vendor.BridgeLib")
```

## Usage

```lua
local BridgeLib = require("BridgeLib.init")

BridgeLib.SetLogger({
    debug = function(message) print(message) end,
    verbose = function() end,
    fatal = function(message) error(message) end,
})

local exports = {}

local bridge = BridgeLib.New({
    context = "client",
    schema = exports,
    modules = { "framework", "inventory", "target" },
    optionalModules = { "fuel", "phone" },
})

bridge:On("playerLoaded", function() ... end)
bridge:On("jobUpdated", function(job) ... end)

CreateThread(function()
    bridge:LoadAll()
end)

return exports
```

Declaring modules in `New` installs their schemas immediately, so `exports` has its full shape
before anything is loaded. `LoadAll` then picks a provider per module and calls `Verify`. Resource
detection has to happen once the server is up, which is why it belongs in a thread rather than at
file scope.

`exports` now holds `GetLocalPlayerData`, `LocalNotify`, `Progressbar`, `HasItem`, `AddBoxZone`,
`SetVehicleFuel`, `FormatNumber`, ... — a merged, framework-neutral API.

`Use` fatals when none of a module's providers is running, and again if the provider it picked is
missing one of the module's `required` functions. `UseOptional` instead leaves the module's fallback
stubs in place (`SetVehicleFuel` no-ops, `FormatNumber` falls back to `tostring`), so callers of an
optional module must tolerate a no-op.

## Catalog

| module        | context                  | providers                        |
| ------------- | ------------------------ | -------------------------------- |
| `framework`   | client / server / shared | `qb-core`, `es_extended`         |
| `inventory`   | client / server          | `qb-inventory`, `ox_inventory`, `codem-inventory`, `qs-inventory-pro`, `qs-inventory`, `origen_inventory`, `tgiann-inventory`, `jaksam_inventory`, `core_inventory`, `one_inventory`, and client only `lj-inventory`, `ps-inventory` |
| `target`      | client                   | `qb-target`, `ox_target`, `qtarget` |
| `zones`       | client                   | `ox_lib`, `PolyZone`             |
| `society`     | server                   | `esx_addonaccount`, `qb-management`, `Renewed-Banking`, `qb-banking`, `okokBanking`, `snipe-banking`, `tgiann-bank`, `kartik-banking` |
| `multijob`    | server                   | `monstor-multijob`               |
| `bossmenu`    | client / server          | `monstor-bossmenu`               |
| `fuel`        | client                   | `rcore_fuel`, `LegacyFuel`, `cdn-fuel`, `okokGasStation`, `ox_fuel` |
| `vehiclekeys` | client                   | `qb-vehiclekeys`, `wasabi_carlock`, `qs-vehiclekeys`, `vehicles_keys` |
| `clothing`    | client                   | `illenium-appearance`, `fivem-appearance`, `tgiann-clothing`, `rcore_clothing`, `qb-clothing`, `esx_skin` |
| `playerstatus`| client / server          | `esx_status`, `qb-core`          |
| `dispatch`    | client                   | `cd_dispatch`, `linden_outlawalert`, `fd_dispatch`, `ps-dispatch`, `qs-dispatch`, `core_dispatch`, `origen_police`, `codem-dispatch`, `tk_dispatch`, `aty_dispatch`, `rcore_dispatch`, `Opto_dispatch` |
| `doorlock`    | client / server          | `ox_doorlock`, `qb-doorlock`, `nui-doorlock`, `cd_doorlock`, `doors_creator` |
| `phone`       | client / server          | `lb-phone`, `npwd`, `sql`        |
| `email`       | client / server          | `qb-phone`, `qs-smartphone-pro`, `qs-smartphone`, `gksphone`, `roadphone`, `npwd`, `lb-phone`, `high-phone`, `yseries`, `yflip-phone`, `okokPhone`, and server only `npwd_qbx_mail`, `npwd_qb_mail` |
| `ui`          | client                   | `lation_ui`, `ox_lib`, `cd_drawtextui`, `qb-core`, `esx_progressbar`, `jg-textui`, `esx_textui`, `brutal_textui`, `esx_notify`, `okokNotify`, `wasabi_notify`, `brutal_notify`, `mythic_notify` |
| `minigames`   | client                   | `BridgeLib`                      |
| `logging`     | server                   | `fmsdk`, `fm-logs`, `loki`, `BridgeLib` |

`zones` prefers `ox_lib`, which every consumer already runs, so the `PolyZone` adapter is only
reached when ox_lib is absent. PolyZone ships no exports — its zone classes are globals — so that
adapter additionally needs `@PolyZone/client.lua` and `@PolyZone/CircleZone.lua` in the consumer's
`shared_scripts`, and fatals when they are missing. The ox_lib adapter approximates PolyZone's
unbounded height with a 10000 unit thickness and its 2D circles with spheres.

`multijob` and `bossmenu` are single-provider modules for resources that have no established
alternative. Declare them through `optionalModules`, since their fallback stubs are written to be
safe: a player holds only the job the framework itself reports, the reads come back empty and the
writes are no-ops.

`inventory` treats item handling as the contract every inventory has to meet — `HasItem`,
`GetItemCount`, `AddItem`, `RemoveItem`, `CanAddItem` and `CanCarryItem` on the server, `HasItem` on
the client. Everything else it defines is `ox_inventory` and `qb-inventory` only, since no other
inventory exposes stashes, slot metadata or an item catalog through comparable exports. A provider
that omits one of those keeps the schema stub, so `GetItemSlots` on a `codem-inventory` server reads
as nothing rather than fatalling. `lj-inventory` and `ps-inventory` are `qb-inventory` forks and are
adapted as such, on the client only. `origen_inventory` publishes no NUI image directory, so
`GetImagePath` is the one stub it leaves in place.

`dispatch` composes its own alert on every provider but `cd_dispatch`, which is the only one that
tells the caller who is calling. The rest read caller details from the module's own fallback, so
`GetAlertPlayerInfo` returns the local street and coordinates and a `sex` of `person` there. An
alert carries more than the providers can all use — `code`, `codeName`, `description` and
`priority` alongside the blip fields — and each adapter takes the ones its resource asks for.

`doorlock` is split by where the door is actually resolved. `qb-doorlock` and `nui-doorlock` key
doors by an id the caller already holds, so they appear in both contexts. `ox_doorlock` and
`doors_creator` look a door up by name — through an export and through `doorscreator_doors`
respectively — and `cd_doorlock` pushes the new state out to clients, so those three are server
only. A client on one of them calls the server bridge instead.

`email` is split the same way, by where a mailbox is addressed from. The phones on the client send
to whoever is holding the phone; the ones on the server look the mailbox up from a source, so
`SendEmail` there takes one. `yflip-phone` maps a framework identifier to a phone number, so it also
needs the `framework` module on the same bridge and logs rather than sending when it is absent.
`npwd` ships no mail app of its own, so its mailbox is whichever community app is running alongside
it: `npwd_qbx_mail` or `npwd_qb_mail`, both of which kept qb-phone's mail events. The server adapter
is registered against those two resources rather than `npwd`, and sends through the event that names
a recipient, so it needs the `framework` module on the same bridge for the character identifier. The
client adapter sends through the event that reads `source` when one of those apps is installed, and
falls back to a notification in npwd's email app when none is.

`ui` covers the parts of a UI resource that are not a framework's: notifications, a blocking
progress bar, and persistent on-screen text. It is separate from `framework`, whose `Progressbar` is
callback shaped and whose `LocalNotify` always exists — `ui` is what a server adds on top when it
runs `ox_lib` or `lation_ui`. Only `lation_ui` and `ox_lib` cover the whole module: `cd_drawtextui`,
`jg-textui`, `esx_textui` and `brutal_textui` only draw text, `esx_progressbar` only runs a progress
bar, and `esx_notify`, `okokNotify`, `wasabi_notify`, `brutal_notify` and `mythic_notify` only
notify, so each leaves the rest of the module on its stubs. One provider is picked per module, so a
server that wants its notifications from one resource and its text from another declares the module
it prefers and calls the other resource itself.

`clothing` dresses a player in a uniform and puts them back afterwards. A uniform names only the
pieces it replaces, so a provider leaves the rest of the character alone. `illenium-appearance`,
`fivem-appearance` and `esx_skin` snapshot the player before the first uniform goes on and restore
that snapshot on `RevertUniform`; `qb-clothing`, `rcore_clothing` and `tgiann-clothing` store the
player's own skin themselves, so those reload it instead and reverting works even across a restart.

`playerstatus` is hunger and thirst, which both frameworks own rather than a separate resource, so
its providers are the framework itself. `AddPlayerStatus` tops a player up rather than setting a
level, capped at 100, so a meal is worth the same whether the player was full or starving. The
values are percentages on either framework, although esx_status stores them on a 0 to 1,000,000
scale underneath.

`minigames` is the one module that is not a choice between interchangeable resources: a caller names
the exact minigame, and a server can run several of the resources at once. So the library hosts the
whole catalog itself and checks `GetResourceState` per call. `GetHacks` lists every name it knows,
`HasHack` reports whether that one's resource is running, and `StartHack` calls back with `false`
rather than blocking when it is not.

`logging` defaults to posting structured embeds to Discord itself, rather than through a framework. A category
names one destination, and its URL is resolved in order from `SetWebhookUrl`, the matching key under
`logging.webhooks` in `config.lua`, then `logging.webhooks.default`. A category that resolves to no
URL is dropped, so a server that configures nothing logs nothing. `logging.username`,
`logging.avatarUrl` and `logging.footer` decorate every payload when set. This is the only place the
library logs from — the `framework` module deliberately exposes no logging of its own, so what a
server sees never depends on which framework it runs.

`logging.service` sends the same calls somewhere else instead: `fivemanage` through the `fmsdk`
resource, `fivemerr` through `fm-logs`, and `loki` or `grafana` straight to a Loki push endpoint
described by `logging.loki`. Each of those adapters opts out unless `service` names it, so a server
running `fmsdk` for its own reasons keeps logging to its webhooks until it says otherwise. None of
them has webhooks, so `SetWebhookUrl` and `SendWebhook` are no-ops there and `GetWebhookUrl` reads
as nil — only `LogFields` and `LogMessage` are required of a log service. Grafana Cloud and a
self-hosted Loki speak the same API and share the one `logging.loki` section, told apart by whether
it carries an `apiKey` or a `user` and `password`.

`phone` on the server reads stored messages straight out of the database, since no phone resource
exposes an export for it, so the consuming resource must load `@oxmysql/lib/MySQL.lua` before its
bridge. Its last-resort `sql` provider is a generic adapter for any phone the library does not ship
a provider for: everything it needs comes out of `phone.database` in `config.lua`, so a new phone is
a configuration change rather than a code change, and leaving that section out keeps the module on
its fallback stubs. It supports two conversation layouts — `members`, a join table with one row per
participant (the shape lb-phone and its relatives use), and `pair`, one conversation row holding
both numbers in two columns. A phone that stores threads any other way needs a provider file of its
own.

`FindNumberOwner` is the one lookup that runs the other way, from a number to the character
identifier it is registered to, which is how a feature turns a number a player typed into a player
through `GetPlayerByIdentifier`. lb-phone reads its `phone_phones` table for it; the `sql` provider
needs `phonesTable`, `phoneNumberColumn` and `ownerColumn` naming wherever the phone records the same
thing, and resolves to nothing until all three are set. npwd keeps a number on the framework's own
player row rather than a table of its own, so its lookup walks the players currently loaded and an
offline owner resolves to nothing there.

The `npwd` provider reads npwd's own `npwd_messages_participants`, `npwd_messages_conversations` and
`npwd_messages` tables, and calls are placed with npwd's `startPhoneCall` export. Neither phone
formats a number outside its own interface, so `FormatNumber` there is `tostring`. npwd exposes no
server side hook for a sent message, so `messageSent` rides the net event its interface sends on:
that payload originates on a client, so the provider only reports it once it checks out as a one to
one thread and the sender it claims matches the number the caller actually owns, and nothing that
reads stored history goes through it. That number comes from npwd's own `getPlayerData` export, so a
caller npwd has no player loaded for drops the event rather than being trusted on its payload.

The `framework` module also emits lifecycle events, so adapters never call into your code directly:

| event               | context         | payload                 |
| ------------------- | --------------- | ----------------------- |
| `playerLoaded`      | client / server | `source`                |
| `playerUnloaded`    | client / server | `source` (server only)  |
| `jobUpdated`        | client / server | `job` / `source, job`   |
| `playerDataUpdated` | client          | `playerData`            |

Job payloads are normalised before they are emitted, so handlers see the same shape on either
framework: `{ name, label, grade, gradeName, gradeSalary, onDuty }`. `GetJobs` normalises the job
catalog the same way, into `{ [name] = { name, label, supportsDuty, grades = { [gradeString] =
{ grade, name, label, salary } } } }`. `supportsDuty` is true for qb-core jobs carrying
`defaultDuty` and always false on ESX, which models off duty as a separate `off_` job instead.

`GetPlayer`, `GetPlayerByIdentifier` and `GetPlayers` return a framework-neutral player: `UniqueId`,
`Source`, `Name`, `JobName`, `JobLabel`, `JobGrade`, `JobGradeName`, `JobGradeSalary`, `JobOnDuty`,
plus `SetOnDuty`, `SetJob`, `GetAccountMoney`, `AddAccountMoney` and `RemoveAccountMoney`.

`GetOfflinePlayerName`, `SetOfflinePlayerJob` and `DeleteCharacter` reach past the framework into its
player table, so the consuming resource has to load oxmysql for them to work.

`DeleteCharacter(identifier, kickReason?)` wipes a character out of the database and returns
`wiped, wipe`, where `wipe` counts `columnsVisited`, `rowsUpdated` and `rowsDeleted`. A JSON column
has the identifier stripped out of the blob and the row rewritten; a column that is the identifier
outright has its row deleted. The framework's own tables are built into its adapter, everything else
comes from `framework.characterTables` in `config.lua`.

A connected player is dropped before any row is touched, and the wipe waits for the framework to
save them before starting - both frameworks write a player out on drop, so the other order would
watch the rows come straight back. A player still loaded ten seconds later abandons the wipe rather
than racing their save, so the call can block for that long. It is destructive, immediate, and
deliberately not bound to a command - wire it to whatever admin path you already restrict.

## Layout

```
BridgeLib/
  init.lua                                 core: New, Use, Load, logging, events
  config.lua                               server-only settings, one section per module
  modules/<module>/<context>.lua           schema + provider list + required keys
  providers/<module>/<context>/<name>.lua  one file per supported resource
```

`config.lua` is the only file kept out of the manifest's `files()`. Clients download everything
listed there, so a webhook URL written into a shipped file is a webhook URL handed to every player
who connects. Keep secrets in `config.lua` (or pass them to `SetConfig` from a server script), and
do not add it to `files()` — only server contexts need to read it.

### Adding a provider

Drop a file at `providers/<module>/<context>/<resource-name>.lua` — the filename must match the
FiveM resource name — and add that name to the module descriptor's `providers` list. The file
returns a table of implementations, or a function taking the bridge when it needs to emit events or
log:

```lua
-- providers/inventory/client/my_inventory.lua
return function(bridge)
    return {
        HasItem = function(name, amount)
            local count = exports["my_inventory"]:GetCount(name)
            if not count then
                bridge:Fatal("my_inventory returned no count")
            end
            return count >= (amount or 1)
        end,
    }
end
```

Provider order in the descriptor is priority order — the first one that is running wins. Resource
names are matched with `GetResourceState`, which is case sensitive, so the filename and the entry in
`providers` must both match the resource folder's name exactly.

A provider entry may also be a table, for an adapter whose file is not named after its resource:

```lua
providers = {
    "lb-phone",
    { resource = "some_resource", adapter = "shared_adapter" },
}
```

### Self-hosted providers

An adapter that speaks to no particular resource — one the library implements itself, like
`logging`'s Discord webhooks or `phone`'s raw SQL fallback — omits `resource` and names only its
`adapter`:

```lua
providers = {
    { adapter = "BridgeLib" },
}
```

Nothing is checked with `GetResourceState` for these: the adapter ships with the library, so it is
available wherever the library is. Do not name the library as a resource instead. Its code runs
inside the *consuming* resource through ox_lib's cross-resource require — BridgeLib starts no
scripts of its own — so neither a hardcoded name nor `GetCurrentResourceName()` describes what is
really running, and on an optional module a mismatch fails silently.

Since such an entry always matches, list it last. An adapter that cannot work in the current setup
returns nothing, which leaves the module on its schema stubs.

### Adding a module

Add `modules/<name>/<context>.lua`:

```lua
return {
    name = "banking",
    context = "server",
    providers = { "qb-banking", "okokBanking" },
    required = { "GetBalance", "AddMoney" },
    schema = {
        GetBalance = function(account) end,
        AddMoney = function(account, amount) end,
    },
}
```

`schema` entries are documented stubs and fallbacks; `required` lists the keys a provider must
implement. Keys in `schema` but not in `required` keep their stub when a provider omits them.

Consumers can register project-specific modules without touching the library:

```lua
BridgeLib.RegisterModule(require("myresource.bridge.modules.banking"))
bridge:Use("banking")
```

## Update checks

Building a **server** bridge also enlists that resource with the
[monstor-versions](https://versions.monstorscripts.com) API. The slug is `GetCurrentResourceName()`
lowercased and the version is the `version` from the resource's own `fxmanifest.lua`, so a resource
opts in by having a server bridge — there is nothing to call and nothing to keep in sync. A resource
that declares no `version` is skipped.

Enlisted resources collect in `GlobalState`, which every resource on the server shares. The first
bridge to claim the job waits out the delay and then asks
`/v1/scripts/check?scripts=slug@version,slug@version` about all of them at once, so a server running
fifteen resources still makes **one request**. Each result is handed back over the
`BridgeLib:versions:result` server event to the resource it belongs to, so every resource prints its
own line and the console attributes it correctly — up to date, or what it is behind on with a
warning when one of the missed releases is breaking. Nothing but the slugs and versions leaves the
server, and a failed request is silent.

A `restart <resource>` on a running server is not part of that boot, so the resource checks itself
alone rather than waiting for a batch that has already gone out — one restart is one entry, and it
prints the same line it would have at startup.

The `versions` section of `config.lua` controls it:

| key      | default                                | description                                     |
| -------- | -------------------------------------- | ----------------------------------------------- |
| `enabled`| `true`                                 | Set to `false` to never contact the API.        |
| `apiUrl` | `https://versions.monstorscripts.com`  | Point at your own deployment.                   |
| `delay`  | `5000`                                 | Milliseconds to wait after startup, which is also the window resources have to enlist. |

## Translations

Building **any** bridge also sets that resource up for translation and installs `Locale` on it:

```lua
Bridge.Notify(playerId, Bridge.Locale('shop.tooFar'), 'error')
Bridge.Notify(playerId, Bridge.Locale('shop.purchased', { amount = 2, item = 'Water', price = 40 }))
```

Keys are dot paths into the resource's own `locales/en.json`, and substitutions replace `%{name}`
placeholders. A key nothing translates renders as the key itself, so a missing string shows up
rather than notifying an empty message.

`locales/en.json` ships with the resource, so a server with no internet and nothing downloaded still
reads correctly. Whatever language is configured is then pulled from
[monstor-versions](https://versions.monstorscripts.com) at
`/v1/scripts/<slug>/locales/<language>?shape=nested` on every start and written to
`locales/<language>.json` in the resource - **English included**, so a wording fix on the API reaches
a server without a resource update. The write is a full replace of that one file, never a merge, so a
key the API has dropped stops being cached rather than lingering.

English is the one language whose download lands in the file the resource shipped. Any other language
is an overlay merged over English, leaving a key it has not translated yet reading in English. Files
are i18next shaped, which is both what the API serves and what `ox_lib` reads, so every one of them is
a normal locale file that can also be edited by hand.

On top of both sits `locales/<language>.local.json`, the server owner's own file. The API never
writes it and a download never replaces it, so any key put in it wins over the shipped and downloaded
strings for that language and stays won across updates. A key left out of it changes nothing, so
rewording one notification is a two-key file rather than a fork of the whole locale:

```json
{ "shop": { "tooFar": "Step closer to the counter." } }
```

An English server uses `locales/en.local.json`; a French one uses `locales/fr.local.json`. The file
is picked up by the same `locales/*.json` manifest glob, so it needs a resource restart to take
effect, not just a file save.

The **server** owns the fetch. A file written at runtime is not in the resource's manifest for that
session, so clients cannot download it until the next restart; instead the server hands its merged
strings to each client that asks over `BridgeLib:locales:request` / `BridgeLib:locales:deliver`, and
pushes them again when a fetch changes something. Clients render what they have on file until that
lands, which is the same second their bridge comes up. Every client asks, English servers included,
since an English server can also be rendering strings the API changed after the client's files were
built.

Every resource prints what it did, so a server can see the download working:

```
[monstor-shop] fr: 2 strings replaced from locales/fr.local.json
  2 of them replace a shipped string.
    shop.tooFar = Approchez-vous du comptoir.
    shop.purchased = Vous avez acheté %{amount}x %{item}.
[monstor-shop] fr: using 12 strings from file, checking the API for changes
[monstor-shop] fr: downloaded 12 strings, 12 of 12 keys translated, cached in locales/fr.json
  3 strings now read differently than they did before the download.
    shop.closed = Le magasin est fermé.
    shop.noRoom = Vous n'avez pas assez de place.
    shop.sold = Vendu pour $%{price}.
  2 downloaded strings stay replaced by locales/fr.local.json.
    shop.tooFar = Approchez-vous du comptoir.
    shop.purchased = Vous avez acheté %{amount}x %{item}.
```

Every counted line then prints its keys with the string each one ends up rendering, so a string that
reads wrong can be traced to the layer that set it straight from the console. A key in the override
file that no shipped file has is called out separately - nothing asks for it, so it is nearly always
a typo in the key path.

Unlike the update check this reports its failures too - a server wants to know when a language did
not arrive, and silence would look the same as quietly running on the shipped strings.

The `locales` section of `config.lua` controls it:

| key       | default                               | description                                             |
| --------- | ------------------------------------- | ------------------------------------------------------- |
| `enabled` | `true`                                | Set to `false` to use only the shipped and cached files. |
| `language`| `"en"`                                | Language code as the API stores it: `fr`, `de`, `pt-BR`. |
| `apiUrl`  | `https://versions.monstorscripts.com` | Point at your own deployment.                            |
| `delay`   | `5000`                                | Milliseconds to wait after startup before fetching.      |

A resource opts in by shipping `locales/en.json` and listing `locales/*.json` in its manifest's
`files`. One that ships nothing still gets `Bridge.Locale`, which then returns whatever key it was
given, and makes no requests.

## API

### `BridgeLib.New(options) -> Bridge`

| option            | type       | description                                                          |
| ----------------- | ---------- | -------------------------------------------------------------------- |
| `context`         | `string`   | Required. `"client"`, `"server"` or `"shared"`; selects module files. |
| `schema`          | `table`    | Table modules are merged into. Becomes `bridge.exports`.              |
| `modules`         | `string[]` | Catalog modules to declare; loaded by `LoadAll`.                      |
| `optionalModules` | `string[]` | Same, but tolerated when no provider is running.                      |
| `label`           | `string`   | Prefixed to log lines. Defaults to `context`.                         |
| `optional`        | `string[]` | Keys of your own that `Verify` should not report.                     |
| `logger`          | `Logger`   | Overrides the library default for this bridge.                        |
| `require`         | `function` | Module loader. Defaults to the ambient `require` (ox_lib's).          |

### Bridge methods

- `bridge:LoadAll()` — load every declared module, then `Verify`.
- `bridge:Use(name)` — declare and load one catalog module now; fatal if no provider is running.
- `bridge:UseOptional(name)` — same, but keep the fallback stubs when none is running.
- `bridge:Declare(name, isOptional)` — install a module's schema without loading it yet.
- `bridge:On(event, handler)` / `bridge:Emit(event, ...)` — lifecycle events.
- `bridge:Load(providers, pathPrefix)` / `bridge:LoadOptional(...)` — the raw loader, for providers
  outside the catalog.
- `bridge:Verify()` — fatal for any schema function nothing implemented. Call it last.
- `bridge:MarkImplemented(keys)`, `bridge:Install(schema)` — manual schema wiring.
- `bridge:Debug(msg)` / `bridge:Verbose(msg)` / `bridge:Fatal(msg)` — logging, for adapters.
- `bridge.loaded` — `{ [module] = resourceName }` of what was picked.

### Library functions

- `BridgeLib.SetLogger(logger)` — `{ debug, verbose, fatal }`, each taking a string. `fatal` is
  expected not to return.
- `BridgeLib.SetRoot(path)` — where the library is mounted. Defaults to `"BridgeLib"`.
- `BridgeLib.RegisterModule(module)` — add or override a module descriptor.
- `BridgeLib.HasResource(name)` — true when the resource is `started` or `starting`.
- `BridgeLib.Unimplemented(name)` — a stub that fatals when called.
