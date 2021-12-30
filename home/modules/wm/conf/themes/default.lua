local gears = require "gears"
local beautiful = require "beautiful"

beautiful.init(gears.filesystem.get_themes_dir() .. "gtk/theme.lua")

-- REFERENCE: https://awesomewm.org/doc/api/documentation/06-appearance.md.html

-- TODO: Use QS logo
-- Generate Awesome icon:
-- theme.awesome_icon = theme_assets.awesome_icon(
--     theme.menu_height, theme.bg_focus, theme.fg_focus
-- )
beautiful.awesome_icon = nil
beautiful.font = "Sarasa UI J 10"
beautiful.notification_icon_size = 150

-- local default_wallpaper = -- TODO: Randomized wallpaper
