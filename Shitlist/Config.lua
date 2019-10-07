local _, config = ...;

ShitlistDB = {}

config.Reasons = {
    "Ninja Looting",
    "Kill Stealing",
    "Spamming",
}
config.ListedPlayers = {}

config.TooltipTitle = "#Shitlist"

config.globals = {
    ["ShowIcon"] = true,
    ["Colored"] = true,
}

config.AlertEnable = true
config.PartyAlertEnable = true

config.Colors = {
    ["Red"] = {red=1, green=0, blue=0, alpha=1},
    ["Green"] = {red=0, green=1, blue=0, alpha=1},
    ["Blue"] = {red=0, green=0, blue=1, alpha=1},
    ["White"] = {red=1, green=1, blue=1, alpha=1},
    ["Black"] = {red=0, green=0, blue=0, alpha=1},
    ["Yellow"] = {red=1, green=0.82, blue=0, alpha=1},
    ["Dark_Blue"] = {red=0, green=0.44, blue=0.87, alpha=1},
}

function getConfigColors(color)
    for k,v in pairs(config.Colors) do
        if color == k then
            return v.red, v.green, v.blue
        end
    end
    return 1, 1, 1
end
