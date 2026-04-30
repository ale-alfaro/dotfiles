-- Install with: rustup component add rust-analyzer

---@type vim.lsp.Config
return {
    cmd = { 'rust-analyzer' },
    filetypes = { 'rust' },
    root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
    settings = {
        ['rust-analyzer'] = {
            cargo = {allFeatures = true},
            formatting = {  command = {'rustfmt'}},
            inlayHints = {
                -- These are a bit too much.
                chainingHints = { enable = false },
            },
        },
    },
}
