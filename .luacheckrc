std = "lua51"
self = false

max_line_length = false
max_code_line_length = false
max_string_line_length = false
max_comment_line_length = false

exclude_files = {
    "libs/",
    ".luacheckrc"
}

ignore = {
    "111", -- Setting an undefined global variable.
    "112", -- Mutating an undefined global variable.
    "113", -- Accessing an undefined global variable.
    "211", -- Unused local variable
    "212", -- Unused argument
    "213", -- Unused loop variable
    "311", -- Value assigned to a local variable is unused
    "432", -- Shadowing an upvalue argument
    "512", -- Loop is executed at most once
    "542", -- empty if branch
}

globals = {}

read_globals = {}
