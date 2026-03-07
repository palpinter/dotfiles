local wezterm = require("wezterm")
local config = wezterm.config_builder()
local tabline = wezterm.plugin.require(
                    "https://github.com/michaelbrusegard/tabline.wez")

-- Globális változó az egyéni window title tárolására
local custom_window_title = nil

-- Egyéni komponens: tab title ha van, különben csak a könyvtár neve
local function smart_title(tab)
    -- Ha van beállított tab title, azt használjuk
    local title = tab.tab_title
    if title and #title > 0 then return title end

    -- Különben a working directory nevét vesszük (csak az utolsó részt)
    local cwd = tab.active_pane.current_working_dir
    if cwd then
        local path = cwd:gsub("file://[^/]*/", "/") -- URL formátum tisztítása
        local dir_name = path:match("([^/]+)/?$") -- Utolsó könyvtár neve
        return dir_name or "~"
    end

    return "~"
end

tabline.setup({
    options = {
        theme = 'nord',
        theme_overrides = {
            tab = {
                active = {fg = '#88C0D0', bg = '#3B4252'},
                inactive = {fg = '#D8DEE9', bg = '#2E3440'},
                inactive_hover = {fg = '#ECEFF4', bg = '#3B4252'}
            }
        },
        tab_separators = {
            left = wezterm.nerdfonts.pl_left_hard_divider,
            right = wezterm.nerdfonts.pl_right_hard_divider
        }
    },
    sections = {
        tabline_a = {'workspace'},
        tabline_b = {},
        tabline_c = {' '},
        tab_active = {
            {smart_title, padding = {left = 0, right = 1}},
            {'zoomed', padding = 0}
        },
        tab_inactive = {
            {smart_title, padding = {left = 0, right = 1}},
            {'zoomed', padding = 0}
        },
        tabline_x = {},
        tabline_y = {},
        tabline_z = {'hostname'}
    },
    extensions = {}
})

config.initial_cols = 120
config.initial_rows = 40

config.font = wezterm.font 'Hack Nerd Font Mono'
config.font_size = 11

config.window_background_opacity = 0.95
config.color_scheme = "nord"
config.hide_tab_bar_if_only_one_tab = false

config.ssh_domains = {
    {
        name = "gadamer",
        remote_address = "100.83.216.109:38338",
        username = "palpinter"
    }
}

-- Leader key beállítása: Ctrl+Space
config.leader = {key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000}

-- Billentyűzet hozzárendelések
config.keys = {
    -- Tab navigáció (leader nélkül)
    {
        key = 'LeftArrow',
        mods = 'SHIFT',
        action = wezterm.action.ActivateTabRelative(-1)
    }, {
        key = 'RightArrow',
        mods = 'SHIFT',
        action = wezterm.action.ActivateTabRelative(1)
    }, -- Pane navigáció Alt+arrow keys (prefix nélkül, mint tmux-ban)
    {
        key = 'LeftArrow',
        mods = 'ALT',
        action = wezterm.action.ActivatePaneDirection 'Left'
    }, {
        key = 'RightArrow',
        mods = 'ALT',
        action = wezterm.action.ActivatePaneDirection 'Right'
    }, {
        key = 'UpArrow',
        mods = 'ALT',
        action = wezterm.action.ActivatePaneDirection 'Up'
    }, {
        key = 'DownArrow',
        mods = 'ALT',
        action = wezterm.action.ActivatePaneDirection 'Down'
    }, -- Leader + vim style pane navigáció (h,j,k,l)
    {
        key = 'h',
        mods = 'LEADER',
        action = wezterm.action.ActivatePaneDirection 'Left'
    }, {
        key = 'j',
        mods = 'LEADER',
        action = wezterm.action.ActivatePaneDirection 'Down'
    }, {
        key = 'k',
        mods = 'LEADER',
        action = wezterm.action.ActivatePaneDirection 'Up'
    }, {
        key = 'l',
        mods = 'LEADER',
        action = wezterm.action.ActivatePaneDirection 'Right'
    }, -- Leader + pane split (mint tmux-ban)
    {
        key = '-',
        mods = 'LEADER',
        action = wezterm.action.SplitPane {
            direction = 'Down',
            size = {Percent = 50}
        }
    }, {
        key = '|',
        mods = 'LEADER',
        action = wezterm.action.SplitPane {
            direction = 'Right',
            size = {Percent = 50}
        }
    }, -- Leader + pane move
    {
        key = '{',
        mods = 'LEADER|SHIFT',
        action = wezterm.action.PaneSelect {mode = 'SwapWithActive'}
    }, {
        key = '}',
        mods = 'LEADER|SHIFT',
        action = wezterm.action.PaneSelect {mode = 'SwapWithActive'}
    }, -- Leader + c = új tab (mint tmux new-window)
    {
        key = 'c',
        mods = 'LEADER',
        action = wezterm.action.SpawnTab 'CurrentPaneDomain'
    }, -- Leader + r = Tab átnevezése
    {
        key = 'r',
        mods = 'LEADER',
        action = wezterm.action.PromptInputLine {
            description = 'Tab név megadása:',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        window:active_tab():set_title(line)
                    end
                end)
        }
    }, -- Leader + w = Window title átnevezése
    {
        key = 'w',
        mods = 'LEADER',
        action = wezterm.action.PromptInputLine {
            description = 'Window cím megadása:',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        custom_window_title = line
                        -- Force window title update
                        window:set_title(line)
                    end
                end)
        }
    }
}

-- Window title kezelés
wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
    local zoomed = ''
    if tab.active_pane.is_zoomed then zoomed = '[Z] ' end

    local index = ''
    if #tabs > 1 then
        index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
    end

    -- Ha van egyéni window title beállítva, azt használjuk
    if custom_window_title and #custom_window_title > 0 then
        return zoomed .. index .. custom_window_title
    end

    -- Különben az aktív tab title-jét használjuk
    local tab_title = tab.tab_title
    if tab_title and #tab_title > 0 then return zoomed .. index .. tab_title end

    -- Végső fallback: working directory
    local cwd = tab.active_pane.current_working_dir
    if cwd then
        local path = cwd:gsub("file://[^/]*/", "/")
        local dir_name = path:match("([^/]+)/?$")
        return zoomed .. index .. (dir_name or "WezTerm")
    end

    return zoomed .. index .. "WezTerm"
end)

return config
