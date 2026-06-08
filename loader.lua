--[[
	NullFire Hub v2.0
	Loader for executor scripts
	Repository: https://github.com/Unwalker1337/Nullfire-rework
]]

local REPO = "Unwalker1337/Nullfire-rework"
local BRANCH = "main"
local CONFIG_URL = string.format("https://raw.githubusercontent.com/%s/%s/places.json", REPO, BRANCH)

local function fetch(url)
	local success, result = pcall(function()
		return game:HttpGet(url)
	end)
	return success and result or nil
end

local function loadScript(path)
	local url = string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, BRANCH, path)
	local code = fetch(url)
	if code then
		local ok, err = pcall(loadstring, code)
		if ok then
			-- execute
			local s, e = pcall(err)
			if not s then warn("NullFire: exec error:", e) end
		else
			warn("NullFire: loadstring failed:", err)
		end
	else
		warn("NullFire: failed to fetch:", url)
	end
end

-- main
local configText = fetch(CONFIG_URL)
if not configText then
	warn("NullFire: failed to fetch config")
	return
end

local config = game:GetService("HttpService"):JSONDecode(configText)
local placeId = tostring(game.PlaceId)
local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"

print(string.format("NullFire Hub v%s loaded", config.loaderVersion or "?"))
print("Place:", placeName, "(" .. placeId .. ")")

-- check if this place has scripts
local placeConfig = config.places[placeId] or config.places["template"]
if placeConfig then
	for _, scriptName in ipairs(placeConfig.scripts or {}) do
		local scriptInfo = config.scripts[scriptName]
		if scriptInfo then
			print("Loading:", scriptInfo.name)
			loadScript(scriptInfo.path)
		end
	end
else
	print("No scripts configured for this place. Edit places.json")
	-- fallback: load default
	local default = config.scripts[config.defaultScript]
	if default then
		loadScript(default.path)
	end
end
