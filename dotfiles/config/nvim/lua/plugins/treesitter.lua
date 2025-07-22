return {
  "nvim-treesitter/nvim-treesitter",
  branch = 'master',
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "elixir", "eex", "heex", -- ensures Elixir parsers are installed
        "go",
        "lua",
        "c", "cpp",
        "json",
        "toml", "yaml",
        "gotmpl", "helm",
      },
      highlight = { enable = true }, -- enables Tree-sitter highlighting
      indent = { enable = true },
    })
  end,
}
