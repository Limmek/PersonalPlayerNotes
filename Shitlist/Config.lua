local _, config = ...;

ShitlistDB = {}
ShitlistSettings = {}

config.Reasons = {"Ninja Looting", "Kill Stealing", "Spamming"}

config.ListedPlayers = {}

config.AlertLastSentName = ""
config.Start = 0
config.IgnoreTime = 30
config.AlertEnable = false

config.SoundChannel = "Master"
config.Sound = "Interface\\AddOns\\Shitlist\\Sounds\\alarmbuzz.ogg"
config.SoundID = 2
config.Sounds = {
    ["alarmbeep"] = "Interface\\AddOns\\Shitlist\\Sounds\\alarmbeep.ogg",
    ["alarmbuzz"] = "Interface\\AddOns\\Shitlist\\Sounds\\alarmbuzz.ogg",
    ["alarmbuzzer"] = "Interface\\AddOns\\Shitlist\\Sounds\\alarmbuzzer.ogg",
    ["alarmdouble"] = "Interface\\AddOns\\Shitlist\\Sounds\\alarmdouble.ogg"
}

config.PartyAlertLastSentName = ""
config.PartyStart = 0
config.PartyIgnoreTime = 30
config.PartyAlertEnable = false

config.TooltipTitle = "#Shitlist"
config.TooltipTitleColor = "Red"
config.TooltipTitleColorID = 1

config.ReasonColor = "Gold"
config.ReasonColorID = 7

config.DefaultColor = "White"
config.DefaultColorID = 4

config.Colors = {
    ["Red"] = {red = 1, green = 0, blue = 0, alpha = 1},
    ["Green"] = {red = 0, green = 1, blue = 0, alpha = 1},
    ["Blue"] = {red = 0, green = 0, blue = 1, alpha = 1},
    ["White"] = {red = 1, green = 1, blue = 1, alpha = 1},
    ["Black"] = {red = 0, green = 0, blue = 0, alpha = 1},
    ["Grey"] = {red = 0.9, green = 0.9, blue = 0.9, alpha = 1},
    ["Yellow"] = {red = 1, green = 1, blue = 0, alpha = 1},
    ["Gold"] = {red = 1, green = 0.82, blue = 0, alpha = 1},
    ["Light_Blue"] = {red = 0, green = 0.44, blue = 0.87, alpha = 1}
}

config.Font = "Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf"

config.Backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = false,
    tileEdge = true,
    tileSize = 0,
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
}

config.Icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8.png"

config.MenuOptions = {
    ["icon"] = true,
    ["add_color"] = "|cffff0000",
    ["remove_color"] = "|cff00ff00"
}

config.PopupMenus = {["target"] = true, ["chat"] = true}

function getConfigColors(color)
    for k, v in pairs(config.Colors) do
        if color == k then return v.red, v.green, v.blue, v.alpha end
    end
    return 1, 1, 1, 1
end
