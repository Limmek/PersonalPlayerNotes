local L = LibStub("AceLocale-3.0"):NewLocale("PersonalPlayerNotes", "zhCN")
if not L then
    return
end

-- White        |cffffffff
-- Red          |cffff0000
-- Light Blue   |c0000ffff
-- Yellow       |cffffd700
-- Orange       |cffff8c00
-- Black        |c00000000
-- GOLDENROD    |cFFDAA520
-- TAN          |cFFD2B48C

L["PPN"] = "关注名单"
L["PPN_DEBUG"] = "|cffff0000[关注名单]|cffffffff"
L["PPN_PRINT"] = "|cffffd700[关注名单]|cffffffff"

L["PPN_NA"] = "不适用"

L["PPN_DISABLE"] = "正在禁用..."

L["PPN_MENU_TITLE"] = "Personal Player Notes"
L["PPN_MENU_SETTINGS"] = "设置选项"
L["PPN_MENU_REASONS"] = "分组分类设置"
L["PPN_MENU_LISTED_PLAYERS"] = "已关注的玩家"
L["PPN_MENU_PROFILES"] = "配置文件"
L["PPN_MENU_CHANGELOG"] = "更新日志"

L["PPN_CONFIG_VERSION"] = "版本:"
L["PPN_CONFIG_REASONS"] = "分组分类:"
L["PPN_CONFIG_LISTEDPLAYERS"] = "玩家名字:"
L["PPN_CONFIG_REFRESH"] = "正在重新加载配置..."
L["PPN_CONFIG_CHECK_OLD_DATA"] = "正在检查历史数据..."
L["PPN_CONFIG_ADDED_OLD_DATA"] = "已添加历史数据:"
L["PPN_CONFIG_DUPLICATE_DATA"] = "找到重复数据:"
L["PPN_CONFIG_MIGRATE"] =
    "ShitList插件现已更名为Personal Player Notes. 你想把原Shitlist插件的配置文件迁移至Personal Player Notes吗?"
L["PPN_CONFIG_MIGRATE_YES"] = "是"
L["PPN_CONFIG_MIGRATE_NO"] = "否"
L["PPN_CONFIG_MIGRATE_DONE"] = "Shitlist配置文件已迁移至Personal Player Notes."

L["PPN_INFO_COMMANDS_TITLE"] = "命令"
L["PPN_INFO_COMMANDS_DESC"] = "所有可用的斜杠命令"
L["PPN_INFO_COMMANDS_1"] = "|cFFD2B48C/ppn|cffffffff - Open Blizzard options."
L["PPN_INFO_COMMANDS_2"] = "|cFFD2B48C/ppno|cffffffff or |cFFD2B48C/ppnoptions|cffffffff - 更改选项."
L["PPN_INFO_COMMANDS_3"] = "|cFFD2B48C/ppnr|cffffffff or |cFFD2B48C/ppnreasons|cffffffff - 编辑分组分类."
L["PPN_INFO_COMMANDS_4"] = "|cFFD2B48C/ppnp|cffffffff or |cFFD2B48C/ppnplayers|cffffffff - 编辑玩家信息."
L["PPN_INFO_COMMANDS_5"] = "|cFFD2B48C/ppnm|cffffffff or |cFFD2B48C/ppnminimap|cffffffff - 小地图图标开关."
L["PPN_INFO_COMMANDS_6"] = "|cFFD2B48C/ppnc|cffffffff or |cFFD2B48C/ppnchangelog|cffffffff - 显示更新日志."
L["PPN_INFO_ABOUT_TITLE"] = "关于"
L["PPN_INFO_ABOUT_VERSION"] = "版本"
L["PPN_INFO_ABOUT_AUTHOR"] = "作者"
L["PPN_INFO_ABOUT_CATEGORY"] = "插件类型"
L["PPN_INFO_ABOUT_LOCALIZATION"] = "本地化"
L["PPN_INFO_ABOUT_LICENSE"] = "许可证"
L["PPN_INFO_ABOUT_WEB"] = "发布网站"

L["PPN_SETTINGS"] = "设置选项"
L["PPN_SETTINGS_TITLE"] = "关注名单 - 设置选项"
L["PPN_SETTINGS_MINIMAP"] = "小地图图标"
L["PPN_SETTINGS_MINIMAP_ICON"] = "隐藏图标"
L["PPN_SETTINGS_MINIMAP_ICON_DESC"] = "显示或隐藏小地图图标"
L["PPN_SETTINGS_MINIMAP_POS"] = "图标位置"
L["PPN_SETTINGS_MINIMAP_POS_DESC"] = "调整小地图图标位置"

L["PPN_SETTINGS_ALERT"] = "提示音"
L["PPN_SETTINGS_ALERT_DESC"] = "配置当发现已关注的玩家时播放的提示音"
L["PPN_SETTINGS_ALERT_ENABLED"] = "启用提示音"
L["PPN_SETTINGS_ALERT_ENABLED_DESC"] =
    "勾选此选项以启用提示音功能. 当发现已关注的玩家时, 将播放配置的提示音."
L["PPN_SETTINGS_ALERT_SESSION_ONLY"] = "每次会话仅一次"
L["PPN_SETTINGS_ALERT_SESSION_ONLY_DESC"] =
    "每个已关注的玩家在本次会话中只提示一次, 而不是每隔提示间隔秒数重复提示. 在 /reload 或切换配置文件后重置."
L["PPN_SETTINGS_ALERT_SOUNDS"] = "声音列表"
L["PPN_SETTINGS_ALERT_SOUNDS_DESC"] =
    "选择全局默认要播放的声音. 分组分类和已关注的玩家可以各自设置自己的声音来覆盖此设置."
L["PPN_SETTINGS_ALERT_CUSTOM_SOUND"] = "添加自定义声音"
L["PPN_SETTINGS_ALERT_CUSTOM_SOUND_DESC"] =
    "输入你自行放入本插件 Sounds 文件夹内的声音文件名(需带 .mp3 或 .ogg 后缀). 确认后即可在任意声音下拉菜单中选择."
L["PPN_SOUND_TEST"] = "试听"
L["PPN_SOUND_TEST_DESC"] = "试听此处实际会播放的声音."
L["PPN_SOUND_REMOVE_CUSTOM"] = "删除"
L["PPN_SOUND_REMOVE_CUSTOM_DESC"] =
    "从自定义声音中删除当前选中的声音. 仅在选中了自定义声音时可用."
L["PPN_SOUND_INHERIT"] = "使用默认"
L["PPN_SETTINGS_ALERT_DELAY"] = "提示间隔"
L["PPN_SETTINGS_ALERT_DELAY_DESC"] =
    "设置在为同一玩家播放下一个提示音之前需要等待的时间(秒). 这有助于防止在短时间内重复播放相同的提示音."

L["PPN_SETTINGS_ICONS"] = "自定义图标"
L["PPN_SETTINGS_ICONS_DESC"] =
    "为分组分类和已关注的玩家添加你自己的图标. 将图标图片文件(.blp, .jpg/.jpeg, .png 或 .tga, 尺寸需为2的幂, 例如 32x32 或 64x64)放入本插件的 Images 文件夹, 然后在下方输入其文件名, 即可在图标选择器中选择它."
L["PPN_SETTINGS_ICON_ADD"] = "添加自定义图标"
L["PPN_SETTINGS_ICON_ADD_DESC"] =
    "输入你自行放入本插件 Images 文件夹内的图标图片文件名(需带扩展名). 确认后即可在图标选择器中选择."
L["PPN_SETTINGS_ICON_SELECT"] = "你的自定义图标"
L["PPN_ICON_REMOVE_CUSTOM"] = "删除"
L["PPN_ICON_REMOVE_CUSTOM_DESC"] = "从自定义图标列表中删除选中的条目."

L["PPN_REASONS_TITLE"] = "关注名单 - 分组分类设置"
L["PPN_REASONS"] = "现有分组分类"
L["PPN_REASON"] = "添加或编辑分组分类"
L["PPN_REASON_DESCRIPTION"] = "添加,编辑或删除关注名单分组分类\n"
L["PPN_REASON_REMOVE"] = "删除分组"
L["PPN_REASON_REMOVE_CONFIRMATION"] = "您确定要删除:\n|cffffd700"
L["PPN_REASON_COLOR"] = "选择颜色(此分组在鼠标提示中的颜色)"
L["PPN_REASON_ALERT_ENABLED"] = "启用分组提示音"
L["PPN_REASON_ALERT_ENABLED_DESC"] =
    "当前分组提示音效开关. 启用后, 当发现此分组内的玩家时, 将播放配置的提示音."
L["PPN_REASON_SOUND"] = "声音"
L["PPN_REASON_SOUND_DESC"] =
    '为此分组内的所有玩家设置专属提示音, 覆盖全局声音. 保持"使用默认"则使用全局提示音.'
L["PPN_REASON_ICON"] = "图标"
L["PPN_REASON_ICON_DESC"] =
    "点击打开游戏内图标选择器. 点击其中的 无 按钮可清除图标. 当玩家未设置专属图标时, 会回退使用该分组图标."
L["PPN_DEFAULT_REASON"] = "默认"

L["PPN_LISTED_PLAYERS_TITLE"] = "关注名单 - 已关注的玩家"
L["PPN_LISTED_PLAYERS"] = "已关注的玩家"
L["PPN_LISTED_PLAYER"] = "已关注的玩家"
L["PPN_LISTED_PLAYER_REMOVE"] = "取消关注玩家"
L["PPN_LISTED_PLAYER_REMOVE_CONFIRMATION"] = "你确定要从关注名单里删除:\n|cffffd700"
L["PPN_LISTED_PLAYER_NAME"] = "玩家名称"
L["PPN_LISTED_PLAYER_REALM"] = "所在服务器"
L["PPN_LISTED_PLAYER_REASON"] = "分组分类"
L["PPN_LISTED_PLAYER_DESCRIPTION"] = "附加描述"
L["PPN_LISTED_PLAYER_COLOR"] = "文字颜色(此附加描述在鼠标提示中的颜色)"
L["PPN_LISTED_PLAYER_ALERT_ENABLED"] = "启用玩家提示音"
L["PPN_LISTED_PLAYER_ALERT_ENABLED_DESC"] =
    "为该玩家启用或禁用提示音. 如果该玩家所在的分组分类已禁用了提示音, 则不能开启."
L["PPN_LISTED_PLAYER_SOUND"] = "声音"
L["PPN_LISTED_PLAYER_SOUND_DESC"] =
    '为该玩家设置专属提示音, 覆盖分组分类(或全局)的声音, 优先级最高. 保持"使用默认"则不覆盖.'
L["PPN_LISTED_PLAYER_ICON"] = "图标"
L["PPN_LISTED_PLAYER_ICON_DESC"] = "点击打开游戏内图标选择器. 点击其中的 无 按钮可清除图标."
L["PPN_LISTED_PLAYERS_EXAMPLE_NAME"] = "变异骷髅"
L["PPN_LISTED_PLAYERS_EXAMPLE_REALM"] = "灰烬使者"
L["PPN_LISTED_PLAYERS_EXAMPLE_DESC"] = "关注名单汉化先行者!RESPECT!"

L["PPN_POPUP_ADD"] = "添加到关注名单"
L["PPN_POPUP_EDIT"] = "编辑关注信息"
L["PPN_POPUP_NEW_ADDED"] = "已成功添加到关注名单"
L["PPN_ICON_PICKER_TITLE"] = "选择图标"
L["PPN_ICON_PICKER_NONE"] = "无"

L["PPN_MINIMAP_TOOLTIP_TITLE"] = "关注名单"
L["PPN_MINIMAP_TOOLTIP_RIGHT_CLICK"] = "|cFFD2B48C 右键点击|cff00ff00 打开插件选项."
L["PPN_MINIMAP_TOOLTIP_LEFT_CLICK"] = "|cFFD2B48C 左键点击|cff00ff00 打开全局设置."
L["PPN_MINIMAP_TOOLTIP_SHIFT_LEFT_CLICK"] = "|cFFD2B48C SHIFT+左键点击|cff00ff00 管理分组分类."
L["PPN_MINIMAP_TOOLTIP_CTRL_LEFT_CLICK"] = "|cFFD2B48C CTRL+左键点击|cff00ff00 查看已关注的玩家."
