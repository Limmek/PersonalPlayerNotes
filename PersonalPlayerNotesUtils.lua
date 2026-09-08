local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Current SavedVariables schema version. Bump this and extend
-- MigrateSavedVariablesSchema() whenever the profile table shape changes
-- in a way that requires converting existing user data.
PersonalPlayerNotes.SCHEMA_VERSION = 2

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
    Patch 12.0.0 (Midnight) "secret values" (e.g. world cursor tooltip units)
    throw a hard Lua error if passed to an API like UnitIsPlayer(), so they
    must be detected and skipped rather than caught after the fact.
    issecretvalue() may not exist on older clients, hence the feature check.
    https://warcraft.wiki.gg/wiki/Secret_Values
]]
function PersonalPlayerNotes:IsSecretUnit(unit)
    return type(issecretvalue) == "function" and issecretvalue(unit) == true
end

--[[
    Opens the Blizzard options window to this addon's category, falling back
    to opening the Ace3 config dialog directly on clients without the modern
    Settings API. Settings.OpenToCategory() needs the numeric category ID
    from AceConfigDialog:AddToBlizOptions() (self.blizOptionsCategoryID),
    not the addon name string.
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

    if fromVersion < 2 then
        -- alert.sound used to be a 1-4 index into alert.sounds; sounds are
        -- now selected by filename from PersonalPlayerNotes.SoundManifest
        -- instead, so reset everyone to the new default and drop the array.
        profile.alert.sound = "default.mp3"
        profile.alert.sounds = nil
        -- customSoundFile was superseded by customSounds before shipping;
        -- just make sure both new fields exist.
        profile.alert.customSoundFile = nil
        profile.alert.customSounds = profile.alert.customSounds or {}
        profile.alert.newCustomSound = profile.alert.newCustomSound or ""
    end

    profile.schemaVersion = PersonalPlayerNotes.SCHEMA_VERSION
end

--#endregion

--#region Addon metadata

--[[
    Each of the following reads one .toc metadata field via
    C_AddOns.GetAddOnMetadata(), falling back to L["PPN_NA"] if unset.
    GetVersion() wraps the result in tostring() since GetAddOnMetadata() can
    hand back a bare number for numeric-looking version strings.
]]
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

--#endregion

-- AceConfigDialog-3.0 uses 170px per `width = 1` unit for a forced-row group
-- (see DialogWidthForUnits() below). WIDTH_OVERHEAD accounts for the Frame's
-- own border, ScrollFrame scrollbar gutter, and named-inline-group border
-- that eat into that content width; WIDTH_SAFETY_MARGIN is an empirical,
-- in-game-tested correction on top of that (see DIALOG_WIDTH_ADJUSTMENT
-- below for the one window that needs it added back instead).
local WIDTH_MULTIPLIER = 170
local WIDTH_OVERHEAD = 74
local WIDTH_SAFETY_MARGIN = -9

--[[
    Converts a forced-row width (in width_multiplier units, see above) into
    the Frame width needed to show it without wrapping.
]]
function PersonalPlayerNotes:DialogWidthForUnits(units)
    return math.ceil(units * WIDTH_MULTIPLIER + WIDTH_OVERHEAD + WIDTH_SAFETY_MARGIN)
end

-- Width (in width_multiplier units, see above) of the widest forced row
-- each option window (keyed by appName) deliberately puts on one line, so
-- each window gets just enough width for its own content instead of one
-- blanket width sized for the widest window overall.
PersonalPlayerNotes.DIALOG_WIDTH_UNITS = {
    ["PersonalPlayerNotesSettings Options"] = 3,
    ["PersonalPlayerNotesSettings Reasons"] = 2.5,
    ["PersonalPlayerNotesSettings Listed_Players"] = 2.5,
}
-- Fallback for any appName not listed above.
PersonalPlayerNotes.DEFAULT_DIALOG_WIDTH_UNITS = 3
-- Per-appName pixel adjustment on top of DialogWidthForUnits() above, for
-- windows whose nested sub-rows need more width than the bare formula
-- gives (in-game tested).
PersonalPlayerNotes.DIALOG_WIDTH_ADJUSTMENT = {
    ["PersonalPlayerNotesSettings Options"] = 75,
}
-- Generic first-paint width for AceGUIDefaults(), before EnforceDialogWidth()
-- (which knows the appName) narrows it to the window's real width.
PersonalPlayerNotes.MIN_DIALOG_WIDTH =
    PersonalPlayerNotes:DialogWidthForUnits(PersonalPlayerNotes.DEFAULT_DIALOG_WIDTH_UNITS)
-- Shared min/max height (pixels) for every option window - see
-- ResizeDialogToContent() below. A window auto-wraps to fit its content
-- below MAX_DIALOG_HEIGHT, and scrolls instead of growing past it.
PersonalPlayerNotes.MIN_DIALOG_HEIGHT = 200
PersonalPlayerNotes.MAX_DIALOG_HEIGHT = 800
-- Extra headroom on top of the exact-fit height ResizeDialogToContent()
-- computes - the exact-fit math still left the frame a few pixels too
-- short in practice, clipping the last row of content.
local HEIGHT_SAFETY_MARGIN = 12

--[[
    Creates a bare AceGUI-3.0 Frame widget preconfigured the way this addon's
    dropdown/minimap-icon "Add"/"Edit" popups expect it: releases itself on
    close, fills its container, and hides the (unused) status bar text/frame.
    Callers are expected to still call :SetTitle() before showing it.
]]
function PersonalPlayerNotes:AceGUIDefaults()
    local aceGUI = LibStub("AceGUI-3.0"):Create("Frame")
    -- Hide BEFORE registering OnClose: :Hide() fires OnClose synchronously,
    -- and an already-registered release callback would release this
    -- brand-new widget before the caller gets to configure/show it.
    aceGUI:Hide()
    aceGUI:SetCallback("OnClose", function(widget)
        aceGUI:Release()
    end)
    aceGUI:SetLayout("Fill")
    -- Generic first-paint size; EnforceDialogWidth()/ResizeDialogToContent()
    -- narrow this down to the window's real size right after.
    local minWidth = PersonalPlayerNotes.MIN_DIALOG_WIDTH
    local minHeight = PersonalPlayerNotes.MIN_DIALOG_HEIGHT
    aceGUI:SetWidth(minWidth)
    if aceGUI.frame.SetResizeBounds then -- WoW 10.0+
        aceGUI.frame:SetResizeBounds(minWidth, minHeight)
    else
        aceGUI.frame:SetMinResize(minWidth, minHeight)
    end
    aceGUI:SetStatusText(nil)
    aceGUI.statustext:Hide()
    aceGUI.statustext:GetParent():Hide()
    return aceGUI
end

--[[
    Overwrites AceConfigDialog's own per-appName status table width (and the
    frame's resize floor) to match this window's own required width (see
    DIALOG_WIDTH_UNITS/DIALOG_WIDTH_ADJUSTMENT above), then reapplies it.
    Needed because AceConfigDialog:Open() always reapplies its own
    remembered status.width via ApplyStatus() (defaulting to 700),
    overwriting whatever width AceGUIDefaults() set - without this, a
    window would only ever show its correct width after the user manually
    resized it. Call this AFTER every AceConfigDialog:Open(appName, frame).
]]
function PersonalPlayerNotes:EnforceDialogWidth(appName, frame)
    local status = AceConfigDialog:GetStatusTable(appName)
    if not status then
        return
    end
    local units = PersonalPlayerNotes.DIALOG_WIDTH_UNITS[appName] or PersonalPlayerNotes.DEFAULT_DIALOG_WIDTH_UNITS
    local adjustment = PersonalPlayerNotes.DIALOG_WIDTH_ADJUSTMENT[appName] or 0
    local width = PersonalPlayerNotes:DialogWidthForUnits(units) + adjustment
    if frame.frame then
        if frame.frame.SetResizeBounds then -- WoW 10.0+
            frame.frame:SetResizeBounds(width, PersonalPlayerNotes.MIN_DIALOG_HEIGHT)
        else
            frame.frame:SetMinResize(width, PersonalPlayerNotes.MIN_DIALOG_HEIGHT)
        end
    end
    if status.width ~= width then
        status.width = width
        frame:ApplyStatus()
    end
end

--[[
    Resizes frame to exactly fit its content (clamped between
    MIN_DIALOG_HEIGHT and MAX_DIALOG_HEIGHT), and persists that height into
    AceConfigDialog's own per-appName status table so it sticks. Call this
    AFTER every AceConfigDialog:Open(appName, frame)/EnforceDialogWidth().

    Growing to MAX_DIALOG_HEIGHT before measuring (instead of measuring at
    the frame's current height) forces the ScrollFrame to re-check whether
    it still needs a scrollbar - it only does that during a layout pass, so
    without this a window opened once at a too-short height would keep
    showing a scrollbar forever even after correctly resizing.

    Writing the result into AceConfigDialog:GetStatusTable(appName).height
    (rather than just SetHeight()) is required because AceConfigDialog's
    ActivateControl reruns Open() on this same frame on almost every widget
    interaction (dropdown selects, button clicks, ...), which reapplies
    status.height and would otherwise snap the window back to its old size.
]]
function PersonalPlayerNotes:ResizeDialogToContent(appName, frame)
    local scrollChild = frame.children and frame.children[1]
    local content = scrollChild and scrollChild.content
    if not content then
        return
    end
    frame:SetHeight(PersonalPlayerNotes.MAX_DIALOG_HEIGHT)
    scrollChild:FixScroll()

    -- 57px is the Frame widget's own title bar/chrome overhead subtracted
    -- from its height to get its content area (see OnHeightSet in
    -- AceGUIContainer-Frame.lua). The "Fill" layout stretches the
    -- ScrollFrame to exactly that content area with 0 extra padding (see
    -- the "Fill" layout registration in AceGUI-3.0.lua), so
    -- content height + 57 (+ HEIGHT_SAFETY_MARGIN, see above) is the Frame
    -- height needed to show it all without scrolling.
    local desiredHeight = (content:GetHeight() or 0) + 57 + HEIGHT_SAFETY_MARGIN
    if desiredHeight < PersonalPlayerNotes.MIN_DIALOG_HEIGHT then
        desiredHeight = PersonalPlayerNotes.MIN_DIALOG_HEIGHT
    elseif desiredHeight > PersonalPlayerNotes.MAX_DIALOG_HEIGHT then
        desiredHeight = PersonalPlayerNotes.MAX_DIALOG_HEIGHT
    end
    frame:SetHeight(desiredHeight)
    scrollChild:FixScroll()

    local status = AceConfigDialog:GetStatusTable(appName)
    if status then
        status.height = desiredHeight
    end
end

--[[
    Opens an AceConfig options table (appName) inside a frame built by
    AceGUIDefaults(), instead of letting AceConfigDialog:Open() create its
    own bare Frame widget (which shows an unstyled status bar strip along
    the bottom that none of this addon's other windows have).

    self.customDialogFrames caches one frame per appName so repeat opens
    reuse/refeed the same frame instead of creating a new untracked one
    each time (AceConfigDialog:Open() only de-dupes frames it created
    itself). The cache entry is cleared when the frame closes.
]]
function PersonalPlayerNotes:OpenDialog(appName)
    self.customDialogFrames = self.customDialogFrames or {}
    local frame = self.customDialogFrames[appName]
    if not frame then
        frame = self:AceGUIDefaults()
        frame:SetCallback("OnClose", function(widget)
            if PersonalPlayerNotes.customDialogFrames[appName] == widget then
                PersonalPlayerNotes.customDialogFrames[appName] = nil
            end
            widget:Release()
        end)
        self.customDialogFrames[appName] = frame
    end
    AceConfigDialog:Open(appName, frame)
    self:EnforceDialogWidth(appName, frame)
    self:ResizeDialogToContent(appName, frame)
    frame:Show()
end

--[[
    Closes every dialog opened via OpenDialog() above. AceConfigDialog:CloseAll()
    only knows about frames it created itself (self.OpenFrames), so it can't
    see or close these custom AceGUIDefaults()-backed containers - callers
    that used to rely on :CloseAll() to reset to a clean slate before opening
    a different window need to call this too.
]]
function PersonalPlayerNotes:CloseAllDialogs()
    if not self.customDialogFrames then
        return
    end
    for _, frame in pairs(self.customDialogFrames) do
        frame:Hide()
    end
end

--[[
    Re-feeds a dialog previously opened via OpenDialog(), if it's currently
    open, so option widgets whose displayed value changed elsewhere (e.g. the
    Icon label after OpenIconPicker()) refresh immediately. AceConfigRegistry's
    own NotifyChange() auto-refresh only sees frames it tracks itself, not
    our custom containers, so callers must call this alongside it.
]]
function PersonalPlayerNotes:RefreshDialog(appName)
    local frame = self.customDialogFrames and self.customDialogFrames[appName]
    if frame then
        AceConfigDialog:Open(appName, frame)
        self:EnforceDialogWidth(appName, frame)
        self:ResizeDialogToContent(appName, frame)
    end
end

--[[
    Prints to the default chat frame, prefixed with L["PPN_DEBUG"] instead of
    L["PPN_PRINT"] when debug mode is on (self.db.profile.debug). Safe to
    call before self.db exists (e.g. very early during load).
]]
function PersonalPlayerNotes:Print(...)
    if self.db and self.db.profile.debug then
        return print(L["PPN_DEBUG"], ...)
    end
    return print(L["PPN_PRINT"], ...)
end

--[[
    Forwards to Print() only while debug mode is enabled; a no-op otherwise.
    Used for verbose logging that shouldn't show up for regular users.
]]
function PersonalPlayerNotes:PrintDebug(...)
    if self.db and self.db.profile.debug then
        self:Print(...)
    end
end
