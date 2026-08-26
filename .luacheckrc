std = "lua51"
self = false

max_line_length = false
max_code_line_length = false
max_string_line_length = false
max_comment_line_length = false

exclude_files = {
    "Libs/",
    ".luacheckrc"
}

ignore = {
    "211", -- Unused local variable
    "212", -- Unused argument
    "213", -- Unused loop variable
    "311", -- Value assigned to a local variable is unused
    "432", -- Shadowing an upvalue argument
    "512", -- Loop is executed at most once
    "542", -- empty if branch
}

-- Globals this addon itself defines/mutates fields on (not just reads).
globals = {
    "PersonalPlayerNotes",

    -- Legacy Shitlist addon SavedVariables: migration clears old fields.
    "ShitlistDB",

    -- Blizzard's static popup registry: this addon registers its own dialog.
    "StaticPopupDialogs",
}

-- WoW client API / Ace3 environment globals this addon reads. Kept explicit
-- (rather than ignoring 111/112/113 project-wide) so Luacheck can still catch
-- real typos in global names elsewhere in the code.
read_globals = {
    -- Lua/WoW runtime extras (not part of vanilla Lua 5.1 std)
    "time",
    "tinsert",
    "tremove",

    -- Client/build identification
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",

    -- Modern namespaced APIs
    "C_AddOns",
    "C_UI",

    -- Legacy equivalents of the namespaced APIs above (older clients)
    "LoadAddOn",
    "DisableAddOn",
    "ReloadUI",

    -- Ace3 library loader (provided by Libs/LibStub, embedded via embeds.xml)
    "LibStub",

    -- Menu / dropdown / unit popup APIs (modern and legacy)
    "Menu",
    "UnitPopup_ShowMenu",
    "UIDROPDOWNMENU_MENU_LEVEL",
    "UIDROPDOWNMENU_MENU_VALUE",
    "UIDropDownMenu_AddButton",
    "UIDropDownMenu_CreateInfo",

    -- Tooltip APIs (modern and legacy)
    "TooltipDataProcessor",
    "Enum",
    "GameTooltip",

    -- Unit/realm info
    "UnitIsPlayer",
    "UnitName",
    "UnitFullName",
    "GetRealmName",

    -- Static popups
    "StaticPopup_Show",

    -- Settings/options panel
    "Settings",
    "SettingsPanel",
    "GameMenuFrame",
    "HideUIPanel",

    -- Input state
    "IsShiftKeyDown",
    "IsControlKeyDown",

    -- Sound
    "PlaySoundFile",
}

-- The Tests/ suite intentionally pokes _G to stub out WoW/Ace3 globals so
-- the addon's pure-logic helpers can be exercised with plain lua5.1, outside
-- of the WoW client. Scope those mock globals to the test files only,
-- instead of loosening the rules for the whole project.
files["Tests/"] = {
    globals = {
        "LibStub",
        "PersonalPlayerNotes",
        "Menu",
        "TooltipDataProcessor",
        "Enum",
        "Settings",
        "C_AddOns",
        "C_UI",
        "ShitlistDB",
        "StaticPopupDialogs",
        "StaticPopup_Show",
        "PlaySoundFile",
        "tinsert",
        "tremove",
    },
}

