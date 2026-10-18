# RobloxClientFlight

A handy-dandy client-side flight tool for Roblox that acts as a safety-first flight system for players and developers. Designed to be lightweight, modular, and easy to integrate — with a focus on control, observability, and safe recovery when something goes wrong.

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
