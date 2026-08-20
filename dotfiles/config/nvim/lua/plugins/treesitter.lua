return {
  "nvim-treesitter/nvim-treesitter",
  branch = 'main',
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "elixir", "eex", "heex", -- ensures Elixir parsers are installed
      "go",
      "lua",
      "c", "cpp",
      "json",
      "toml", "yaml",
      "gotmpl", "helm",
    })

    -- main branch no longer enables highlighting/indent itself; do it per buffer
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "elixir", "eelixir", "heex",
        "go",
        "lua",
        "c", "cpp",
        "json",
        "toml", "yaml",
        "gotmpl", "helm",
      },
      callback = function(ev)
        -- pcall: skip buffers whose parser isn't installed yet
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
