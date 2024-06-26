-- Standard awesome library
local gears = require "gears"
local awful = require "awful"
local beautiful = require "beautiful"
require "awful.autofocus"

-- Widgets
local bat_arc = require "awesome-wm-widgets.batteryarc-widget.batteryarc"

-- Widget and layout library
local wibox = require "wibox"

-- Load theme
require "themes.default"

-- Notification library
local naughty = require "naughty"
local menubar = require "menubar"
local hotkeys_popup = require "awful.hotkeys_popup"

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require "awful.hotkeys_popup.keys"

-- Enable awesome-client
require "awful.remote"

function has_battery ()
    local handle, err = io.popen("ls /sys/class/power_supply/ | grep '^BAT'")
    if err or not handle then
        return false
    end

    local result = handle:read("*a")
    handle:close()

    return result ~= ""
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify(
        {
            preset = naughty.config.presets.critical,
            title = "Oops, there were errors during startup!",
            text = awesome.startup_errors
        }
    )
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal(
        "debug::error",
        function(err)
            -- Make sure we don't go into an endless error loop
            if in_error then
                return
            end
            in_error = true

            naughty.notify(
                {
                    preset = naughty.config.presets.critical,
                    title = "Oops, an error happened!",
                    text = tostring(err)
                }
            )
            in_error = false
        end
    )
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.

-- This is used later as the default terminal and editor to run.
local terminal = "alacritty"
local editor = os.getenv("EDITOR") or "nvim"
local editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.max
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
local myawesomemenu = {
    {
        "hotkeys",
        function()
            hotkeys_popup.show_help(nil, awful.screen.focused())
        end
    },
    {"manual", terminal .. " -e man awesome"},
    {"edit config", editor_cmd .. " " .. awesome.conffile},
    {"restart", awesome.restart},
    {"sleep", terminal .. " -e systemctl suspend"},
    {
        "quit",
        function()
            awesome.quit()
        end
    }
}

local mymainmenu =
    awful.menu(
    {
        items = {
            {"awesome", myawesomemenu, beautiful.awesome_icon},
            {"open terminal", terminal}
        }
    }
)

local mylauncher = awful.widget.launcher({image = beautiful.awesome_icon, menu = mymainmenu})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons =
    gears.table.join(
    awful.button(
        {},
        1,
        function(t)
            t:view_only()
        end
    ),
    awful.button(
        {modkey},
        1,
        function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end
    ),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button(
        {modkey},
        3,
        function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end
    ),
    awful.button(
        {},
        4,
        function(t)
            awful.tag.viewnext(t.screen)
        end
    ),
    awful.button(
        {},
        5,
        function(t)
            awful.tag.viewprev(t.screen)
        end
    )
)

local tasklist_buttons =
    gears.table.join(
    awful.button(
        {},
        1,
        function(c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal("request::activate", "tasklist", {raise = true})
            end
        end
    ),
    awful.button(
        {},
        3,
        function()
            awful.menu.client_list({theme = {width = 250}})
        end
    ),
    awful.button(
        {},
        4,
        function()
            awful.client.focus.byidx(1)
        end
    ),
    awful.button(
        {},
        5,
        function()
            awful.client.focus.byidx(-1)
        end
    )
)

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(
    function(s)
        -- Wallpaper
        set_wallpaper(s)

        -- Each screen has its own tag table.
        awful.tag({"一", "二", "三", "四", "五"}, s, awful.layout.layouts[1])

        -- Create a promptbox for each screen
        s.mypromptbox = awful.widget.prompt()
        -- Create an imagebox widget which will contain an icon indicating which layout we're using.
        -- We need one layoutbox per screen.
        s.mylayoutbox = awful.widget.layoutbox(s)
        s.mylayoutbox:buttons(
            gears.table.join(
                awful.button(
                    {},
                    1,
                    function()
                        awful.layout.inc(1)
                    end
                ),
                awful.button(
                    {},
                    3,
                    function()
                        awful.layout.inc(-1)
                    end
                ),
                awful.button(
                    {},
                    4,
                    function()
                        awful.layout.inc(1)
                    end
                ),
                awful.button(
                    {},
                    5,
                    function()
                        awful.layout.inc(-1)
                    end
                )
            )
        )
        -- Create a taglist widget
        s.mytaglist =
            awful.widget.taglist {
            screen = s,
            filter = awful.widget.taglist.filter.all,
            buttons = taglist_buttons
        }

        -- Create a tasklist widget
        s.mytasklist =
            awful.widget.tasklist {
            screen = s,
            filter = awful.widget.tasklist.filter.currenttags,
            buttons = tasklist_buttons
        }

        -- Create the wibox
        s.mywibox = awful.wibar({position = "top", screen = s})

        -- Add widgets to the wibox
        local left_widgets = {
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox
        }
        local right_widgets = {
            -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
        }
        if has_battery() then
            right_widgets[#right_widgets+1] = bat_arc()
        end

        local right_widgets_extra = {
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox
        }

        for _, w in ipairs(right_widgets_extra) do
            right_widgets[#right_widgets+1] = w
        end

        local common_widgets = {
            layout = wibox.layout.align.horizontal,
            left_widgets,
            s.mytasklist, -- Middle widget
            right_widgets
        }

        s.mywibox:setup(common_widgets)
    end
)
-- }}}

-- {{{ Mouse bindings
root.buttons(
    gears.table.join(
        awful.button(
            {},
            3,
            function()
                mymainmenu:toggle()
            end
        ),
        awful.button({}, 4, awful.tag.viewnext),
        awful.button({}, 5, awful.tag.viewprev)
    )
)
-- }}}

-- {{{ Key bindings
local globalkeys =
    gears.table.join(
    awful.key({modkey}, "s", hotkeys_popup.show_help, {description = "show help", group = "awesome"}),
    awful.key(
        {modkey},
        "w",
        function()
            mymainmenu:show()
        end,
        {description = "show main menu", group = "awesome"}
    ),
    awful.key({modkey}, "u", awful.client.urgent.jumpto, {description = "jump to urgent client", group = "client"}),
    awful.key(
        {modkey},
        "Tab",
        function()
            awful.client.next(1):raise()
        end,
        {description = "next client tab (max)", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "Tab",
        function()
            awful.client.next(-1):raise()
        end,
        {description = "previous client tab (max)", group = "client"}
    ),
    -- Standard program
    awful.key(
        {modkey},
        "Return",
        function()
            awful.spawn(terminal)
        end,
        {description = "open a terminal", group = "launcher"}
    ),
    awful.key({modkey, "Control"}, "r", awesome.restart, {description = "reload awesome", group = "awesome"}),
    awful.key({modkey, "Shift"}, "q", awesome.quit, {description = "quit awesome", group = "awesome"}),
    -- TODO Put hjkl keys in their own for loop
    -- TODO Put up down left right int their own for loop
    -- TODO Create keybindings to increment/decrement window's size
    -- awful.key(
    --     {modkey},
    --     "l",
    --     function()
    --         awful.tag.incmwfact(0.05)
    --     end,
    --     {description = "increase master width factor", group = "layout"}
    -- ),
    -- awful.key(
    --     {modkey},
    --     "h",
    --     function()
    --         awful.tag.incmwfact(-0.05)
    --     end,
    --     {description = "decrease master width factor", group = "layout"}
    -- ),
    -- awful.key(
    --     {modkey, "Shift"},
    --     "h",
    --     function()
    --         awful.tag.incnmaster(1, nil, true)
    --     end,
    --     {description = "increase the number of master clients", group = "layout"}
    -- ),
    -- awful.key(
    --     {modkey, "Shift"},
    --     "l",
    --     function()
    --         awful.tag.incnmaster(-1, nil, true)
    --     end,
    --     {description = "decrease the number of master clients", group = "layout"}
    -- ),
    -- Moving window focus works between desktops
    awful.key(
        {modkey},
        "j",
        function(c)
            awful.client.focus.global_bydirection("down")
            if c then
                c:lower()
            end
        end,
        {description = "focus next window up", group = "client"}
    ),
    awful.key(
        {modkey},
        "k",
        function(c)
            awful.client.focus.global_bydirection("up")
            if c then
                c:lower()
            end
        end,
        {description = "focus next window down", group = "client"}
    ),
    awful.key(
        {modkey},
        "l",
        function(c)
            awful.client.focus.global_bydirection("right")
            if c then
                c:lower()
            end
        end,
        {description = "focus next window right", group = "client"}
    ),
    awful.key(
        {modkey},
        "h",
        function(c)
            awful.client.focus.global_bydirection("left")
            if c then
                c:lower()
            end
        end,
        {description = "focus next window left", group = "client"}
    ),
    -- Moving windows between positions works between desktops
    awful.key(
        {modkey, "Shift"},
        "h",
        function(c)
            awful.client.swap.bydirection("left")
            if c then
                c:raise()
            end
        end,
        {description = "swap with left client", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "l",
        function(c)
            awful.client.swap.bydirection("right")
            if c then
                c:raise()
            end
        end,
        {description = "swap with right client", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "j",
        function(c)
            awful.client.swap.bydirection("down")
            if c then
                c:raise()
            end
        end,
        {description = "swap with down client", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "k",
        function(c)
            awful.client.swap.bydirection("up")
            if c then
                c:raise()
            end
        end,
        {description = "swap with up client", group = "client"}
    ),
    awful.key(
        {modkey, "Control"},
        "h",
        function()
            awful.tag.incncol(1, nil, true)
        end,
        {description = "increase the number of columns", group = "layout"}
    ),
    awful.key(
        {modkey, "Control"},
        "l",
        function()
            awful.tag.incncol(-1, nil, true)
        end,
        {description = "decrease the number of columns", group = "layout"}
    ),
    awful.key(
        {modkey},
        "space",
        function()
            awful.layout.inc(1)
        end,
        {description = "select next", group = "layout"}
    ),
    awful.key(
        {modkey, "Shift"},
        "space",
        function()
            awful.layout.inc(-1)
        end,
        {description = "select previous", group = "layout"}
    ),
    awful.key(
        {modkey, "Control"},
        "n",
        function()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal("request::activate", "key.unminimize", {raise = true})
            end
        end,
        {description = "restore minimized", group = "client"}
    ),
    -- Prompt
    awful.key(
        {modkey},
        "r",
        function()
            awful.screen.focused().mypromptbox:run()
        end,
        {description = "run prompt", group = "launcher"}
    ),
    awful.key(
        {modkey},
        "x",
        function()
            awful.prompt.run {
                prompt = "Run Lua code: ",
                textbox = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            }
        end,
        {description = "lua execute prompt", group = "awesome"}
    ),
    -- Menubar
    awful.key(
        {modkey},
        "p",
        function()
            menubar.show()
        end,
        {description = "show the menubar", group = "launcher"}
    ),
    -- Audio
    awful.key(
        {},
        "XF86AudioRaiseVolume",
        function()
            awful.spawn("pulsemixer --change-volume +5")
        end,
        {description = "Raise audio volume", group = "audio"}
    ),
    awful.key(
        {},
        "XF86AudioLowerVolume",
        function()
            awful.spawn("pulsemixer --change-volume -5")
        end,
        {description = "Lower audio volume", group = "audio"}
    ),
    awful.key(
        {},
        "XF86AudioMute",
        function()
            awful.spawn("pulsemixer --toggle-mute")
        end,
        {description = "Toggle mute", group = "audio"}
    ),
    -- Apps
    awful.key(
        {modkey, "Shift"},
        "e",
        function()
            awful.spawn("doom everywhere")
        end,
        {description = "edit with emacs", group = "utils"}
    ),
    awful.key(
        {modkey},
        "e",
        function()
            awful.spawn("emacsclient -c -a 'emacs'")
        end,
        {description = "the one true editor", group = "utils"}
    ),
    awful.key(
        {modkey},
        "b",
        function()
            awful.spawn("brave")
        end,
        {description = "the one browser", group = "utils"}
    )
)

local clientkeys =
    gears.table.join(
    awful.key(
        {modkey},
        "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "c",
        function(c)
            c:kill()
        end,
        {description = "close", group = "client"}
    ),
    awful.key(
        {modkey, "Control"},
        "space",
        awful.client.floating.toggle,
        {description = "toggle floating", group = "client"}
    ),
    awful.key(
        {modkey, "Control"},
        "Return",
        function(c)
            c:swap(awful.client.getmaster())
        end,
        {description = "move to master", group = "client"}
    ),
    awful.key(
        {modkey},
        "o",
        function(c)
            c:move_to_screen()
            c:raise()
        end,
        {description = "move to next screen", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "o",
        function(c)
            c:move_to_screen(c.screen.index - 1)
            c:raise()
        end,
        {description = "move to previous screen", group = "client"}
    ),
    awful.key(
        {modkey},
        "t",
        function(c)
            c.ontop = not c.ontop
        end,
        {description = "toggle keep on top", group = "client"}
    ),
    awful.key(
        {modkey},
        "n",
        function(c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        {description = "minimize", group = "client"}
    ),
    awful.key(
        {modkey},
        "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        {description = "(un)maximize", group = "client"}
    ),
    awful.key(
        {modkey, "Control"},
        "m",
        function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end,
        {description = "(un)maximize vertically", group = "client"}
    ),
    awful.key(
        {modkey, "Shift"},
        "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end,
        {description = "(un)maximize horizontally", group = "client"}
    )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys =
        gears.table.join(
        globalkeys,
        -- View tag only.
        awful.key(
            {modkey},
            "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            {description = "view tag #" .. i, group = "tag"}
        ),
        -- Toggle tag display.
        awful.key(
            {modkey, "Control"},
            "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            {description = "toggle tag #" .. i, group = "tag"}
        ),
        -- Move client to tag.
        awful.key(
            {modkey, "Shift"},
            "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            {description = "move focused client to tag #" .. i, group = "tag"}
        ),
        -- Toggle tag on focused client.
        awful.key(
            {modkey, "Control", "Shift"},
            "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            {description = "toggle focused client on tag #" .. i, group = "tag"}
        )
    )
end

-- Jump to specfic screen with mod + , . /
for i, l in ipairs({",", ".", "/"}) do
    clientkeys =
        gears.table.join(
        clientkeys,
        awful.key(
            {modkey},
            l,
            function(c)
                awful.screen.focus(i)
                if c then
                    c:lower()
                end
            end,
            {description = "jump to screen " .. i, group = "screen"}
        ),
        awful.key(
            {modkey, "Shift"},
            l,
            function(c)
                if c then
                    c:move_to_screen(i)
                    c:lower()
                end
            end,
            {description = "move client to screen " .. i, group = "screen"}
        )
    )
end

local clientbuttons =
    gears.table.join(
    awful.button(
        {},
        1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
        end
    ),
    awful.button(
        {modkey},
        1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.move(c)
        end
    ),
    awful.button(
        {modkey},
        3,
        function(c)
            c:emit_signal("request::activate", "mouse_click", {raise = true})
            awful.mouse.client.resize(c)
        end
    )
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },
    -- Floating clients.
    {
        rule_any = {
            instance = {},
            class = {
                ".arandr-wrapped",
                ".blueman-manager-wrapped"
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {},
            role = {}
        },
        properties = {floating = true}
    },
    -- Remove titlebars to normal clients and dialogs
    {
        rule_any = {
            type = {"normal", "dialog"}
        },
        properties = {titlebars_enabled = false}
    }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal(
    "manage",
    function(c)
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- if not awesome.startup then awful.client.setslave(c) end

        if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
            -- Prevent clients from being unreachable after screen count changes.
            awful.placement.no_offscreen(c)
        end
    end
)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal(
    "request::titlebars",
    function(c)
        -- buttons for the titlebar
        local buttons =
            gears.table.join(
            awful.button(
                {},
                1,
                function()
                    c:emit_signal("request::activate", "titlebar", {raise = true})
                    awful.mouse.client.move(c)
                end
            ),
            awful.button(
                {},
                3,
                function()
                    c:emit_signal("request::activate", "titlebar", {raise = true})
                    awful.mouse.client.resize(c)
                end
            )
        )

        awful.titlebar(c):setup {
            {
                -- Left
                awful.titlebar.widget.iconwidget(c),
                buttons = buttons,
                layout = wibox.layout.fixed.horizontal
            },
            {
                -- Middle
                {
                    -- Title
                    align = "center",
                    widget = awful.titlebar.widget.titlewidget(c)
                },
                buttons = buttons,
                layout = wibox.layout.flex.horizontal
            },
            {
                -- Right
                awful.titlebar.widget.floatingbutton(c),
                awful.titlebar.widget.maximizedbutton(c),
                awful.titlebar.widget.stickybutton(c),
                awful.titlebar.widget.ontopbutton(c),
                awful.titlebar.widget.closebutton(c),
                layout = wibox.layout.fixed.horizontal()
            },
            layout = wibox.layout.align.horizontal
        }
    end
)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal(
    "mouse::enter",
    function(c)
        c:emit_signal("request::activate", "mouse_enter", {raise = false})
    end
)

client.connect_signal(
    "focus",
    function(c)
        c.border_color = beautiful.border_focus
    end
)
client.connect_signal(
    "unfocus",
    function(c)
        c.border_color = beautiful.border_normal
    end
)
-- }}}
