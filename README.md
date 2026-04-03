# SorenWare - Generator Hub

Modular Roblox script for Velocity, Synapse, or any **UNC-compliant** executor with `HttpGet` / `request`.

## Quick start

Paste into your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Proxo123/SorenWare/main/loader.lua"))()
```

The loader downloads `main.lua` and all `modules/*` from this repo on each run (always latest `main`).

## Features

| Feature | Description |
|---------|-------------|
| **Auto generator** | Multi-stage puzzle firing with burst count, delay, optional wave mode, cooldown |
| **Generator ESP** | Highlights incomplete generators; customizable fill/outline; **max distance** slider; tracks **late-spawned** `ProximityPrompt`s |
| **Instant proximity hold** | Client-side `HoldDuration = 0` on prompts under the active map (server may still validate) |
| **Objective ESP** | Optional **battery** and **fusebox** highlights (name heuristics); fusebox can require **battery equipped**; objective max distance |
| **Killer ESP** | Drawing ESP: box, name, distance, tracer; color and max distance (large range) |
| **Survivor ESP** | Same style as killer ESP, **green** default; optional world **health** text; **max distance** |
| **Survivor health sidebar** | ScreenGui list of `PLAYERS.ALIVE` with HP text and bars |
| **Infinite stamina** | Client-side stamina spoof |
| **Custom drain / max stamina** | Tunable drain % and max value |
| **Persistent config** | `GenHub_settings.json` on the executor filesystem |
| **Config profiles** | Save/load/delete named presets |
| **Interface (Fluent)** | Window loaded from [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent); theme, acrylic, transparency, window size, minimize key |

## UI tabs

1. **Generators** — Auto gen, generator ESP + distance, instant proximity, objective ESP toggles  
2. **Killer ESP** — Toggles, color, components, max distance  
3. **Survivor ESP** — Same class of options + health sidebar and “show self”  
4. **Player** — Stamina options  
5. **Settings** — Fluent look, debug, reset, unload  

Unload: **Settings → Unload Hub**, or `getgenv().GenHub.Unload()` if exposed.

## Project structure

```
SorenWare/
├── loader.lua                 ← Entry (raw GitHub URL for loadstring)
├── main.lua                   ← Orchestrator
├── modules/
│   ├── config.lua             ← Defaults, save/load, profiles
│   ├── state.lua              ← Runtime flags & connection buckets
│   ├── logger.lua
│   ├── helpers.lua            ← Colors (gen, killer, survivor)
│   ├── gen_esp.lua            ← Highlights + distance loop
│   ├── gen_tracking.lua       ← Per-gen prompts + completion
│   ├── objective_esp.lua      ← Battery / fusebox highlights
│   ├── prox_hold.lua          ← Instant hold sweep on map
│   ├── killer_esp.lua
│   ├── killer_tracking.lua    ← PLAYERS.KILLER
│   ├── survivor_esp.lua
│   ├── survivor_tracking.lua  ← PLAYERS.ALIVE
│   ├── survivor_sidebar.lua   ← Teammate HP panel
│   ├── auto_gen.lua
│   ├── stamina.lua
│   ├── round_manager.lua      ← GAME MAP / round lifecycle
│   ├── ui.lua                 ← Fluent UI (fetches library at runtime)
│   └── ui_lib.lua             ← SorenUI-style widgets (in repo; not used by default loader path)
└── README.md
```

## How it works

1. **loader.lua** resolves the raw `main.lua` URL and runs it with a small `fetch(path)` helper.  
2. **main.lua** loads each module from `modules/<file>` via the same fetcher and injects dependencies.  
3. **round_manager** watches `workspace.MAPS` for `GAME MAP`, starts generator/survivor/killer/objective hooks, and cleans up when the map unloads.  

Push to `main` and re-execute; no file redistribution needed.

## Notes

- **Objective ESP** uses **name patterns** (e.g. `battery`, `fusebox`). If a game uses different names, adjust heuristics in `modules/objective_esp.lua` or open an issue with instance paths.  
- **Instant proximity** only affects what replicates to your client; anti-cheat or server checks may still block abuse.
