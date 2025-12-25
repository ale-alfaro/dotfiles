set shell := ["zsh", "-uc"]

supported_langs := "python|cpp|lua|bash"
agents-md-repo := home_dir() / "dotfiles" / "common" / "llm_memory" / "tech_stacks"
codex_home := env('CODEX_HOME')

[default]
@list:
    just --list --justfile {{ source_file() }}

[group('agents-md')]
global-override sysprompt_path:
    ln -sf {{ sysprompt_path }} {{ codex_home / "AGENTS.override.md" }}

symlink := 'ln -sf "$1" "$2"'

[group('agents-md')]
ln_file file_path loc=(invocation_directory() / "AGENTS.md"):
    {{ if path_exists(loc) == "true" { shell('rm "$1"', loc) } else { "" } }}
    {{ shell(symlink, agents-md-repo / file_path / "AGENTS.md", loc) }}

[group('agents-md')]
ln_tech_stack_file lang: (ln_file lang "TECH_STACK.md")

[group('prompts')]
[no-cd]
prompt target=invocation_directory() label="note":
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    printf "### %s — %s\n\n" "{{ label }}" "$timestamp" >> {{ target / "AGENTS.md" }}
    cat >> {{ target / "AGENTS.md" }}
