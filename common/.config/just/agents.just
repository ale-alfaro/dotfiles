set shell := ["zsh", "-uc"]

supported_langs := "python|cpp|lua|bash"
agents-md-repo := home_dir() / "dotfiles" / "common" / "llm_memory"
tech-stack-agents-md := agents-md-repo / "tech_stacks"
codex_home := env('CODEX_HOME')

default:
    @just --list

[group('agents-md')]
global-override sysprompt_path:
    ln -sf {{ sysprompt_path }} {{ codex_home / "AGENTS.override.md" }}

[group('agents-md')]
project lang dst="AGENTS.md":
    ln -sf {{ if lang =~ supported_langs { tech-stack-agents-md / lang / "AGENTS.md" } else { error("Unsupported language") } }} {{ if is_dependency() == "true" { invocation_directory() / dst } else { dst } }}

supported_tech_stacks := "python|just"

[group('agents-md')]
tech-stack stack dst="TECH_STACK.md":
    ln -sf {{ if stack =~ supported_tech_stacks { tech-stack-agents-md / stack / "TECH_STACK.md" } else { error("Unsupported language") } }} {{ if is_dependency() == "true" { invocation_directory() / dst } else { dst } }}

[group('prompts')]
[no-cd]
prompt target=invocation_directory() label="note":
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    printf "### %s — %s\n\n" "{{ label }}" "$timestamp" >> {{ target / "AGENTS.md" }}
    cat >> {{ target / "AGENTS.md" }}
