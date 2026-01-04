set shell := ["zsh", "-uc"]

supported_langs := "python|cpp|lua|bash"
agents-md-repo := home_dir() / "dotfiles" / "common" / "llm_memory" / "tech_stacks"
symlink := 'ln -sf "$1" "$2"'

agentmd_ls:
    eza -T -L 3 {{ agents-md-repo }}

agentmd_ln file_path loc=(invocation_directory() / "AGENTS.md"):
    {{ if path_exists(loc) == "true" { shell('rm "$1"', loc) } else { "" } }}
    {{ shell(symlink, agents-md-repo / file_path / "AGENTS.md", loc) }}
