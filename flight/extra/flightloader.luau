local UIS = game:GetService("UserInputService")

local mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local url = mobile
    and "https://raw.githubusercontent.com/sspeth000/robloxclientflight/main/flight/mobileflight.luau"
    or "https://raw.githubusercontent.com/sspeth000/robloxclientflight/main/flight/pcflight.luau"

loadstring(game:HttpGet(url))()
