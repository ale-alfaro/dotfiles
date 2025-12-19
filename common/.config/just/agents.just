set shell := ["zsh", "-uc"]

supported_langs := "python|cpp|lua|bash"
agents-md-repo := home_dir() / "dotfiles" / "common" / "llm_memory" / "tech_stacks"
codex_home := env('CODEX_HOME')

@_:
    just --list

[group('agents-md')]
global-override sysprompt_path:
    ln -sf {{ sysprompt_path }} {{ codex_home / "AGENTS.override.md" }}

symlink := 'ln -sf "$1" "$2"'

[group('agents-md')]
ln_file file_path agents_file="AGENTS.md":
    {{ if path_exists(invocation_directory() / agents_file) == "true" { shell('rm "$1"', invocation_directory() / agents_file) } else { "" } }}
    {{ shell(symlink, agents-md-repo / file_path / agents_file, invocation_directory() / agents_file) }}

[group('agents-md')]
ln_tech_stack_file lang: (ln_file lang "TECH_STACK.md")

[group('prompts')]
[no-cd]
prompt target=invocation_directory() label="note":
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    printf "### %s — %s\n\n" "{{ label }}" "$timestamp" >> {{ target / "AGENTS.md" }}
    cat >> {{ target / "AGENTS.md" }}
