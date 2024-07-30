local prettier = require("prettier")

prettier.setup({
  bin = 'prettierd',
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
  -- set Prettier options. They are passed to the prettier CLI. By default these options are only used if prettier config file is not found.
  -- cli_options = {
  --   single_quote = false,
  --   trailing_comma = "es5",
  --   use_tabs = false,
  --   print_width = 100,
  --   tab_width = 2,
  -- },
})

