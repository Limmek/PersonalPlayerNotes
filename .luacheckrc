globals = {
    "_G",
    "Shitlist",
    "ShitlistDB",
    "ShitlistSettings",
    "GameTooltip",
}
max_line_length = 2823 -- fixme
ignore = {
	"11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
	"11./BINDING_.*", -- Setting an undefined (Keybinding header) global variable
	"113/LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
	"113/NUM_LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
	"211", -- Unused local variable
	"211/L", -- Unused local variable "CL"
	"211/CL", -- Unused local variable "CL"
	"212", -- Unused argument
	"213", -- Unused loop variable
	-- "231", -- Set but never accessed
	"311", -- Value assigned to a local variable is unused
	"314", -- Value of a field in a table literal is unused
	"42.", -- Shadowing a local variable, an argument, a loop variable.
	"43.", -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
	"542", -- An empty if branch
	"611", -- A line consists of nothing but whitespace.
	"612", -- A line contains trailing whitespace.
	"613", -- Trailing whitespace in a string.
	"614", -- Trailing whitespace in a comment.
}
self=false
global=false
