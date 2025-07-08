local colors = {
  darkgray     = "#303030",
  gray         = "#4e4e4e",
  lightpurple  = "#8787b2",
  white        = "#dadada",
}

-- normal sets the color scheme for normal mode, etc.
-- a,b,c sets the color scheme for left components
-- x,y,z sets the color scheme for left components
local invzn = {
  normal = {
    a = {bg = colors.lightpurple, fg = colors.darkgray, gui = "bold"},
    b = {bg = colors.gray, fg = colors.white},
    c = {bg = colors.darkgray, fg = colors.white},
    x = {bg = colors.darkgray, fg = colors.white},
    y = {bg = colors.gray, fg = colors.white},
    z = {bg = colors.lightpurple, fg = colors.darkgray},
  },
  insert = {
    a = {bg = colors.lightpurple, fg = colors.darkgray, gui = "bold"},
    b = {bg = colors.gray, fg = colors.white},
    c = {bg = colors.darkgray, fg = colors.white},
    x = {bg = colors.darkgray, fg = colors.white},
    y = {bg = colors.gray, fg = colors.white},
    z = {bg = colors.lightpurple, fg = colors.darkgray},
  },
  visual = {
    a = {bg = colors.lightpurple, fg = colors.darkgray, gui = "bold"},
    b = {bg = colors.gray, fg = colors.white},
    c = {bg = colors.darkgray, fg = colors.white},
    x = {bg = colors.darkgray, fg = colors.white},
    y = {bg = colors.gray, fg = colors.white},
    z = {bg = colors.lightpurple, fg = colors.darkgray},
  },
  replace = {
    a = {bg = colors.lightpurple, fg = colors.darkgray, gui = "bold"},
    b = {bg = colors.gray, fg = colors.white},
    c = {bg = colors.darkgray, fg = colors.white},
    x = {bg = colors.darkgray, fg = colors.white},
    y = {bg = colors.gray, fg = colors.white},
    z = {bg = colors.lightpurple, fg = colors.darkgray},
  },
  command = {
    a = {bg = colors.lightpurple, fg = colors.darkgray, gui = "bold"},
    b = {bg = colors.gray, fg = colors.white},
    c = {bg = colors.darkgray, fg = colors.white},
    x = {bg = colors.darkgray, fg = colors.white},
    y = {bg = colors.gray, fg = colors.white},
    z = {bg = colors.lightpurple, fg = colors.darkgray},
  },
  inactive = {
    a = {bg = colors.lightpurple, fg = colors.darkgray, gui = "bold"},
    b = {bg = colors.gray, fg = colors.white},
    c = {bg = colors.darkgray, fg = colors.white},
    x = {bg = colors.darkgray, fg = colors.white},
    y = {bg = colors.gray, fg = colors.white},
    z = {bg = colors.lightpurple, fg = colors.darkgray},
  }
}

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = invzn,
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
      refresh_time = 16, -- ~60fps
      events = {
        'WinEnter',
        'BufEnter',
        'BufWritePost',
        'SessionLoadPost',
        'FileChangedShellPost',
        'VimResized',
        'Filetype',
        'CursorMoved',
        'CursorMovedI',
        'ModeChanged',
      },
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}
