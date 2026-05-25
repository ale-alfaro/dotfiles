## Templates (Tera)

- Templates are supported in `mise.toml` values (not in the file itself).
- Delimiters: `{{ }}` expressions, `{% %}` statements, `{# #}` comments.
- Useful variables: `env`, `cwd`, `config_root`, `xdg_cache_home`, `xdg_config_home`, `xdg_data_home`.
- Task scripts with usage spec expose `usage` map (e.g., `{{ usage.verbose }}`).
- Built-in functions: `exec`, `arch`, `os`, `os_family`, `num_cpus`, `read_file`.
