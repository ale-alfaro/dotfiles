local M = {}

local null_ls = require 'null-ls'
local uv = require 'custom.python.uv'

local h = require 'null-ls.helpers'
local methods = require 'null-ls.methods'
local u = require 'null-ls.utils'

local FORMATTING = methods.internal.FORMATTING

local fmt = h.make_builtin {
  name = 'isort',
  meta = {
    url = 'https://github.com/PyCQA/isort',
    description = 'Python utility / library to sort imports alphabetically and automatically separate them into sections and by type.',
  },
  method = FORMATTING,
  filetypes = { 'python' },
  generator_opts = {
    command = 'isort',
    args = {
      '--stdout',
      '--filename',
      '$FILENAME',
      '-',
    },
    to_stdin = true,
    cwd = h.cache.by_bufnr(function(params)
      return u.root_pattern(
        -- isort will detect files in the CWD as first-party
        -- https://pycqa.github.io/isort/docs/configuration/config_files.html
        '.isort.cfg',
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'tox.ini',
        '.editorconfig'
      )(params.bufname)
    end),
  },
  factory = h.formatter_factory,
}

local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local diag = h.make_builtin {
  name = 'pylint',
  meta = {
    url = 'https://github.com/PyCQA/pylint',
    description = [[
Pylint is a Python static code analysis tool which looks for programming
errors, helps enforcing a coding standard, sniffs for code smells and offers
simple refactoring suggestions.

If you prefer to use the older "message-id" names for these errors (i.e.
"W0612" instead of "unused-variable"), you can customize pylint's resulting
diagnostics like so:

```lua
null_ls = require("null-ls")
null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.pylint.with({
      diagnostics_postprocess = function(diagnostic)
        diagnostic.code = diagnostic.message_id
      end,
    }),
    null_ls.builtins.formatting.isort,
    null_ls.builtins.formatting.black,
    ...,
  },
})
```
]],
  },
  method = DIAGNOSTICS,
  filetypes = { 'python' },
  generator_opts = {
    command = 'pylint',
    to_stdin = true,
    args = { '--from-stdin', '$FILENAME', '-f', 'json' },
    format = 'json',
    check_exit_code = function(code)
      return code ~= 32
    end,
    on_output = h.diagnostics.from_json {
      attributes = {
        row = 'line',
        col = 'column',
        code = 'symbol',
        severity = 'type',
        message = 'message',
        message_id = 'message-id',
        symbol = 'symbol',
        source = 'pylint',
      },
      severities = {
        convention = h.diagnostics.severities['information'],
        refactor = h.diagnostics.severities['information'],
      },
      offsets = {
        col = 1,
        end_col = 1,
      },
    },
    cwd = h.cache.by_bufnr(function(params)
      return u.root_pattern(
        -- https://pylint.readthedocs.io/en/latest/user_guide/usage/run.html#command-line-options
        'pylintrc',
        '.pylintrc',
        'pyproject.toml',
        'setup.cfg',
        'tox.ini'
      )(params.bufname)
    end),
  },
  factory = h.generator_factory,
}

function M.get_sources()
  return {
    fmt,
    diag,
    uv.null_ls_sources.diagnostics.ruff_check,
    uv.null_ls_sources.diagnostics.ty_check,
    uv.null_ls_sources.formatting.ruff_format,
  }
end

return M
