# RobloxClientFlight

A handy-dandy client-side flight tool for Roblox that acts as a safety-first flight system for players and developers. Designed to be lightweight, modular, and easy to integrate — with a focus on control, observability, and safe recovery when something goes wrong.

## Features
- Simple flight controls (start/stop)
- Emergency Panic / Stop to immediately restore a safe state
- Speed slider and presets (Slow / Cruise / Fast)
- Altitude Lock (hold a target height while flying)
- Soft‑Landing / Return to Ground with cancel
- Auto‑stabilize toggle to smooth rotations and velocity
- Save / Restore snapshot for manual rollback
- Small Status & Log panel (last N messages, IsRunning, LastError)
- Modular API (Config, Logger, FlightManager) so other scripts can subscribe to events

## Quickstart

1. Clone or download the repository and put the modules under `ReplicatedStorage` or a `Modules` folder in your place.
2. Place client UI (LocalScript + ScreenGui) into `StarterPlayerScripts` or an appropriate client container.
3. Require and instantiate the `FlightManager` from a LocalScript and wire it to the GUI controls.

Example starter usage:
```lua
local FlightManager = require(game.ReplicatedStorage.Modules.FlightManager)
local player = game.Players.LocalPlayer

local impl = {
  primary = function()
    -- primary flight implementation (e.g., apply body velocity/gyro)
  end,
  fallback = function()
    -- optional fallback method
  end,
}

local fm = FlightManager.new(player, impl)

-- wire UI buttons / sliders to these:
fm:start()
fm:stop()
fm:on("Failure", function(err) print("Flight failure:", err) end)