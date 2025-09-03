#!/usr/bin/env just --justfile
set shell := ["bash", "-euo", "pipefail", "-c"]


plugins_export_file := join(justfile_directory() , "plugins.sh")

default:
    @just --list

update_plugin repo_spec:
    #!/usr/bin/env bash
    set -euxo pipefail

    repo_spec="{{repo_spec}}"
    repo_owner="${repo_spec%@*}"
    version="${repo_spec#*@}"
    if [ "$repo_owner" = "$version" ]; then
        version="latest"
    fi

    tag_arg=()
    if [ "$version" != "latest" ]; then
        tag_arg=("$version")
    fi

    echo "Updating $repo_owner (version: $version)"
    release_name=$(gh release view "${tag_arg[@]}" -R "$repo_owner" --json name --jq '.name')
    wasm_files=$(gh release view "${tag_arg[@]}" -R "$repo_owner" --json assets --jq '.assets[] | select(.name | contains("wasm")).name')

    if [ -z "$wasm_files" ]; then
        echo "No wasm file found for $repo_owner@$version"
        exit 1
    fi
    echo "Downloading $wasm_files"
    gh release download "${tag_arg[@]}" -R "$repo_owner" --pattern '*.wasm' --clobber


update_plugins:
    #!/usr/bin/env bash
    pluginRepos=("karimould/zellij-forgot" "fresh2dev/zellij-autolock" "dj95/zjstatus" "rvcas/room")
    echo "Plugins to update: $pluginRepos"
    for repo in "${pluginRepos[@]}"; do \
        if [ -n "$repo" ]; then \
            just -f {{justfile()}} update_plugin "$repo"; \
        fi; \
    done

