return {
  {
    "wtfox/jellybeans.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      flat_ui = false,
      on_colors = function(c)
        local light_bg = "#ffffff"
        local dark_bg = "#000000"
        c.background = vim.o.background == "light" and light_bg or dark_bg
        c.float_bg = vim.o.background == "light" and light_bg or dark_bg
      end,
    }
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      no_italic = true,
      term_colors = true,
      transparent_background = false,
      styles = {
        comments = {},
        conditionals = {},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
      },
      color_overrides = {
        mocha = {
          text = "#feffff",
          base = "#000000",
          mantle = "#000000",
          crust = "#000000",
        },
        frappe = {
          text = "#feffff",
          base = "#000000",
          mantle = "#000000",
          crust = "#000000",
        },
        macchiato = {
          text = "#feffff",
          base = "#000000",
          mantle = "#000000",
          crust = "#000000",
        },
      },
      integrations = {
        telescope = {
          enabled = true,
          --style = "nvchad",
        },
        dropbar = {
          enabled = true,
          color_mode = true,
        },
      },
    },
  },
}
