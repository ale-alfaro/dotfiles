#!/usr/bin/env just --justfile
set shell := ["bash", "-euo", "pipefail", "-c"]


plugins_export_file := join(justfile_directory() , "plugins.sh")

default:
    echo "Looking at {{plugins_export_file}}"
    source {{plugins_export_file}}
    for i in ${!PLUGINS[@]}; do \
        echo "${PLUGINS[$i]}"; \
    done

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
    wasm_file=$(gh release view "${tag_arg[@]}" -R "$repo_owner" --json assets --jq '.assets[] | select(.name | contains("wasm")).name')

    if [ -z "$wasm_file" ]; then
        echo "No wasm file found for $repo_owner@$version"
        exit 1
    fi
    echo "Downloading $wasm_file"
    gh release download "${tag_arg[@]}" -R "$repo_owner" --pattern '*.wasm' --clobber


update_plugins:
    source {{plugins_export_file}}
    echo "$PLUGINS" | tr ':' '\n' | while read -r repo; do \
        if [ -n "$repo" ]; then \
            just -f {{justfile()}} update_plugin "$repo"; \
        fi; \
    done
