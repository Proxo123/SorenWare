# SorenWare - Generator Hub

Modular Roblox script for the Velocity executor (or any UNC-compliant executor).

## Quick Start

Paste this into your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Proxo123/SorenWare/main/loader.lua"))()
```

## Features

| Feature | Description |
|---------|-------------|
| **Auto Generator** | Completes generators automatically on interact, with configurable cooldown |
| **Generator ESP** | Highlights incomplete generators with customizable colors and transparency |
| **Killer ESP** | Drawing-based ESP with box, name, distance, and tracer |
| **Infinite Stamina** | Client-side stamina spoof — sprint never stops |
| **Custom Drain Rate** | Control how fast stamina drains (0-100%) |
| **Custom Max Stamina** | Override max stamina value (50-500) |
| **Persistent Config** | Settings saved to executor filesystem between sessions |
| **Config Profiles** | Save/load named setting presets |
| **Custom UI (SorenUI)** | Glassmorphism UI with purple accent, smooth animations, search bar |

## Project Structure

```
SorenWare/
├── loader.lua              ← Entry point (loadstring target)
├── main.lua                ← Orchestrator — loads & wires modules
├── modules/
│   ├── config.lua          ← Persistent settings + profile system
│   ├── state.lua           ← Shared runtime state & connection management
│   ├── logger.lua          ← Debug logging
│   ├── helpers.lua         ← Color helpers & cached math functions
│   ├── gen_esp.lua         ← Generator highlight ESP
│   ├── killer_esp.lua      ← Killer drawing ESP + render loop
│   ├── auto_gen.lua        ← Auto generator completion
│   ├── stamina.lua         ← Stamina spoofing via hookmetamethod
│   ├── gen_tracking.lua    ← Generator proximity prompt tracking
│   ├── killer_tracking.lua ← Killer folder watcher
│   ├── round_manager.lua   ← Round start/end detection
│   ├── ui_lib.lua          ← SorenUI — custom glassmorphism UI library
│   └── ui.lua              ← Application UI (uses SorenUI)
└── README.md
```

## How It Works

1. **loader.lua** is fetched via `loadstring` — it downloads `main.lua` from GitHub
2. **main.lua** fetches each module from `modules/` and injects dependencies
3. Each module is self-contained and receives only the dependencies it needs
4. Updates are instant — push to GitHub and re-execute the loadstring

## Updating

Just push changes to `main` branch. The loader always fetches the latest version from GitHub on each execution. No need to redistribute scripts.
