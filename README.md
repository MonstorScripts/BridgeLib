# bridgelib

A resource-agnostic bridge layer for FiveM Lua resources.

It ships a **catalog** of adapters — `qb-core`, `es_extended`, `ox_inventory`, `qb-inventory`,
`ox_target`, `qb-target`, `rcore_fuel`, `LegacyFuel`, `qb-vehiclekeys`, `cd_dispatch`, `lb-phone` —
grouped into modules (`framework`, `inventory`, `target`, `fuel`, `vehiclekeys`, `dispatch`,
`phone`). Your resource asks for the modules it needs, bridgelib picks whichever supported resource
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
git submodule add <repo-url> bridgelib
```

Then make sure the files reach the client — in `fxmanifest.lua`:

```lua
shared_scripts({
    "@ox_lib/init.lua",
    "bridgelib/**.lua",
    -- your files
})
```

One glob in `shared_scripts` keeps the manifest maintenance-free as the catalog grows, at the cost
of shipping the server adapters to clients as well. They contain no secrets — keep it that way when
adding adapters, or split the globs per context.

No file in this library `require`s another, so it can be mounted at any path. If you mount it
somewhere other than `bridgelib/`, tell it where it lives so it can find its own modules:

```lua
local BridgeLib = require("vendor.bridgelib.init")
BridgeLib.SetRoot("vendor.bridgelib")
```

## Usage

```lua
local BridgeLib = require("bridgelib.init")

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
| `inventory`   | client / server          | `qb-inventory`, `ox_inventory`   |
| `target`      | client                   | `qb-target`, `ox_target`         |
| `society`     | server                   | `esx_addonaccount`, `qb-management` |
| `multijob`    | server                   | `al-multijob`                    |
| `bossmenu`    | client / server          | `al-bossmenu`                    |
| `fuel`        | client                   | `rcore_fuel`, `LegacyFuel`       |
| `vehiclekeys` | client                   | `qb-vehiclekeys`, `wasabi_carlock` |
| `dispatch`    | client                   | `cd_dispatch`                    |
| `phone`       | client                   | `lb-phone`                       |

`multijob` and `bossmenu` are single-provider modules for resources that have no established
alternative. Declare them through `optionalModules`, since their fallback stubs are written to be
safe: a player holds only the job the framework itself reports, the reads come back empty and the
writes are no-ops.

The `framework` module also emits lifecycle events, so adapters never call into your code directly:

| event               | context         | payload                 |
| ------------------- | --------------- | ----------------------- |
| `playerLoaded`      | client / server | `source`                |
| `playerUnloaded`    | client / server | `source` (server only)  |
| `jobUpdated`        | client / server | `job` / `source, job`   |
| `playerDataUpdated` | client          | `playerData`            |

Job payloads are normalised before they are emitted, so handlers see the same shape on either
framework: `{ name, label, grade, gradeName, gradeSalary, onDuty }`. `GetJobs` normalises the job
catalog the same way, into `{ [name] = { name, label, grades = { [gradeString] = { grade, name,
label, salary } } } }`.

`GetPlayer`, `GetPlayerByIdentifier` and `GetPlayers` return a framework-neutral player: `UniqueId`,
`Source`, `Name`, `JobName`, `JobLabel`, `JobGrade`, `JobGradeName`, `JobGradeSalary`, `JobOnDuty`,
plus `SetOnDuty`, `SetJob`, `GetAccountMoney`, `AddAccountMoney` and `RemoveAccountMoney`.

`GetOfflinePlayerName` and `SetOfflinePlayerJob` reach past the framework into its player table, so
the consuming resource has to load oxmysql for them to work.

## Layout

```
bridgelib/
  init.lua                                 core: New, Use, Load, logging, events
  modules/<module>/<context>.lua           schema + provider list + required keys
  providers/<module>/<context>/<name>.lua  one file per supported resource
```

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

Provider order in the descriptor is priority order — the first one that is running wins.

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
- `BridgeLib.SetRoot(path)` — where the library is mounted. Defaults to `"bridgelib"`.
- `BridgeLib.RegisterModule(module)` — add or override a module descriptor.
- `BridgeLib.HasResource(name)` — true when the resource is `started` or `starting`.
- `BridgeLib.Unimplemented(name)` — a stub that fatals when called.
