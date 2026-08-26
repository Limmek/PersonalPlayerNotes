local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Current SavedVariables schema version. Bump this and extend
-- MigrateSavedVariablesSchema() whenever the profile table shape changes
-- in a way that requires converting existing user data.
PersonalPlayerNotes.SCHEMA_VERSION = 1

--#region Client feature detection

--[[
    Client capabilities are feature-detected instead of branched on
    WOW_PROJECT_ID/flavor, since Classic clients have progressively picked up
    modern Retail APIs and this avoids hardcoding assumptions per client.
]]
function PersonalPlayerNotes:HasModernMenuAPI()
    return type(Menu) == "table" and type(Menu.ModifyMenu) == "function"
end

function PersonalPlayerNotes:HasModernTooltipAPI()
    return type(TooltipDataProcessor) == "table"
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
        and type(Enum) == "table"
        and Enum.TooltipDataType ~= nil
end

function PersonalPlayerNotes:HasModernSettingsAPI()
    return type(Settings) == "table" and type(Settings.OpenToCategory) == "function"
end

--[[
    Some Classic clients don't expose the C_AddOns/C_UI namespaces yet, still
    relying on the older global LoadAddOn/DisableAddOn/ReloadUI functions.
    Confirmed via live testing on Wrath Classic.
]]
function PersonalPlayerNotes:HasModernAddOnAPI()
    return type(C_AddOns) == "table"
        and type(C_AddOns.LoadAddOn) == "function"
        and type(C_AddOns.DisableAddOn) == "function"
end

function PersonalPlayerNotes:HasModernUIReloadAPI()
    return type(C_UI) == "table" and type(C_UI.Reload) == "function"
end

--[[
    Opens the Blizzard options window to this addon's category, falling back
    to opening the Ace3 config dialog directly on clients without the modern
    Settings API.

    Settings.OpenToCategory() expects the numeric/category-object ID returned
    by AceConfigDialog:AddToBlizOptions() (stored in
    self.blizOptionsCategoryID during OnInitialize), NOT the addon name
    string - passing the string throws "bad argument #1 to
    'OpenSettingsPanel' (outside of expected range)" on modern clients.
]]
function PersonalPlayerNotes:OpenBlizzardOptions()
    if self:HasModernSettingsAPI() and self.blizOptionsCategoryID then
        Settings.OpenToCategory(self.blizOptionsCategoryID)
    else
        AceConfigDialog:Open("PersonalPlayerNotesSettings Info")
    end
end

--#endregion

--#region SavedVariables migration

--[[
    Parses a legacy Shitlist "Name-Realm" key into separate name/realm values.
    Kept as a pure string function (no SavedVariables/WoW API access) so it
    can be unit tested outside of WoW, see Tests/test_utils.lua.
]]
function PersonalPlayerNotes:ParseLegacyPlayerKey(key)
    if type(key) ~= "string" then
        return nil, nil
    end
    return key:match("([^-]+)-([^-]+)")
end

--[[
    Runs once per login after the AceDB profile is loaded. AceDB-3.0 already
    fills in missing fields from PersonalPlayerNotes.defaults, so this only
    needs to handle actual structural changes between schema versions.
]]
function PersonalPlayerNotes:MigrateSavedVariablesSchema()
    local profile = self.db.profile
    local fromVersion = profile.schemaVersion or 0

    if fromVersion < 1 then
        -- Initial schema version, nothing to convert yet.
    end

    profile.schemaVersion = PersonalPlayerNotes.SCHEMA_VERSION
end

--#endregion

function PersonalPlayerNotes:GetVersion()
    return tostring(C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Version")) or L["PPN_NA"]
end

function PersonalPlayerNotes:GetTitle()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Title") or L["PPN_NA"]
end

function PersonalPlayerNotes:GetAuthor()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Author") or L["PPN_NA"]
end

function PersonalPlayerNotes:GetNotes()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Notes") or L["PPN_NA"]
end

function PersonalPlayerNotes:GetLocalizations()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Localizations") or L["PPN_NA"]
end

function PersonalPlayerNotes:GetCategory()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Category") or L["PPN_NA"]
end

function PersonalPlayerNotes:GetWebsite()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Website") or L["PPN_NA"]
end

function PersonalPlayerNotes:GetLicense()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-License") or L["PPN_NA"]
end

function PersonalPlayerNotes:AceGUIDefaults()
    local aceGUI = LibStub("AceGUI-3.0"):Create("Frame")
    aceGUI:SetCallback("OnClose", function(widget)
        aceGUI:Release()
    end)
    aceGUI:SetLayout("Fill")
    aceGUI:SetStatusText(nil)
    aceGUI.statustext:Hide()
    aceGUI.statustext:GetParent():Hide()
    aceGUI:Hide()
    return aceGUI
end

function PersonalPlayerNotes:Print(...)
    if self.db and self.db.profile.debug then
        return print(L["PPN_DEBUG"], ...)
    end
    return print(L["PPN_PRINT"], ...)
end

function PersonalPlayerNotes:PrintDebug(...)
    if self.db and self.db.profile.debug then
        self:Print(...)
    end
end
