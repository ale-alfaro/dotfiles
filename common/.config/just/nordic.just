sdk-download-url-base := 'https://files.nordicsemi.com/artifactory/ncs-src-mirror/external/'
sdk-types := "sdk-nrf-bm sdk-nrf"
nrfutil := require('nrfutil')

@_:
    just --list --justfile {{ source_file() }}

[arg('type', pattern='baremetal|zephyr')]
download_sdk type version:
    @wget  {{ sdk-download-url-base / type / version / "src.tar.gz" }} -O {{ f'{{version}}.tar.gz' }}
    @tar -xzf {{ f'{{version}}.tar.gz' }} {{ version }}

nrfutil_executable_platform := if os() == "linux" { "x86_64-unknown-linux-gnu" } else if os() == "macos" { "universal-apple-darwin" } else { "x86_64-pc-windows-msvc" }
artifactory_base_url := "https://files.nordicsemi.com/artifactory"
toolchain_base_url := "https://files.nordicsemi.com/NCS/external/bundles/v3"
toolchain_index_url := toolchain_base_url / f"index-{{os()}}-{{arch()}}.json"
toolchain_pkg_prefix := f"ncs-toolchain-{{arch()}}-{{os()}}"
nrfutil_base_url := artifactory_base_url / "swtools" / "external" / "nrfutil"
nrfutil_url := "nrfutil_base_url" / "executables" / "nrfutil_executable_platform" / "nrfutil"
package_index_url := f'{{nrfutil_base_url}}/index/init.json'
package_index_config := "nordic-external-production"

# nrfutil_install:
#     curl $_retry --proto '=https' --tlsv1.2 --show-error --silent --fail --location "{{url}}" --output "{{temp_output}}"
#     local nrfutil="{{nrfutil_dir}}/nrfutil${ext}"
#   https://files.nordicsemi.com/artifactory/NCS/external/bundles/v3/ncs-toolchain-x86_64-linux-11349092be.tar.gz
#     chmod u+x {nrfutil} https://files.nordicsemi.com/artifactory/NCS/external/bundles/v3/ncs-toolchain-aarch64-macos-8934b18d70.tar.gz
#     rm $HOME/.nrfutil/bin/nrfutil > /dev/null 2>&1 || true

tmp_index := / "tmp" / "toolchain_index.json"

toolchain_index_ls:
    curl -s {{ toolchain_index_url }} | jq -r '.[] | select(has("key")).key | scan("v\\d.\\d.\\d")[0:]'

toolchain_index_jqp:
    curl -s {{ toolchain_index_url }} | jqp

ncs_base_dir := env('NCS_SDK_HOME', join(home_dir(), 'ncs', 'sdk'))
toolchain_base_dir := ncs_base_dir / 'toolchains'
ncs_download_dir := ncs_base_dir / 'downloads'
version := 'v3.0.2'
toolchain_tarball := ncs_download_dir / f'{{toolchain_pkg_prefix}}-v{{version}}.tar.gz'
jq_query := f'.[] | select(has("key")) | select(.key|test("v\\d.\\d.\\d$")) | {version:.key[1:], hash: .metadata.version} | select(.version == "{{version}}").hash'
master_toolchain_has_query := 'jq .. | .ncs_versions?|arrays[] | contains("$1")'
master_toolchain_add_entry := f'jq [.[].toolchains[] | ., {"identifier": {"bundle_id" : "$1" },  ncs_versions": [ "$2" ] } ]'

toolchain_download:
    {{ if path_exists(toolchain_tarball) == 'true' { f'echo  {{BOLD}}"Toolchain already downloaded at {{toolchain_tarball}}"{{NORMAL}}' } else { 'wget ' + shell(f"curl -s {{toolchain_index_url}} | jq -r '{{jq_query}}'") + ' -O ' + toolchain_tarball } }}

[arg('ver', pattern='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?(?:\+(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?$')]
toolchain_install ver:
    #!/usr/bin/env zsh
    local version="v{{ ver }}"
    local toolchain_hash=$( curl -s {{ toolchain_index_url }} | \
        jq -r '.[] | select(has("key")) | select(.key|test("v\\d.\\d.\\d$")) | {version:.key[1:], hash: .metadata.version} | select(.version == "{{ ver }}").hash' )
    [[ -z $toolchain_hash ]] && echo "{{ style('error') }}Failed to obtain toolchain hash with version $version{{ NORMAL }}" && exit 0
    echo "{{ f'{{BOLD + GREEN}} Found toolchain with hash: ' + "$toolchain_hash" + f' {{NORMAL}}' }}"

    local toolchain_download_path="{{ ncs_download_dir }}/{{ toolchain_pkg_prefix + '-${toolchain_hash}.tar.gz' }}"
    local toolchain_install_path="{{ toolchain_base_dir }}/${toolchain_hash}/"
    if [[ -f $toolchain_download_path ]]; then
      echo '{{ BOLD + MAGENTA }} Toolchain already downloaded {{ NORMAL }}'
    else
      print '{{ BOLD + MAGENTA }} Downloading toolchain in {{ NORMAL }}: ' $toolchain_download_path
      wget {{ f"{{toolchain_base_url}}/{{toolchain_pkg_prefix}}-${toolchain_hash}.tar.gz" }} -O $toolchain_download_path
    fi
    if [[ ! -f ${toolchain_install_path}/manifest.json ]]; then
      echo '{{ BOLD + MAGENTA }} Installing toolchain at $toolchain_install_path {{ NORMAL }}'
      [[ ! -d $toolchain_install_path ]] && mkdir $toolchain_install_path
      tar -xzf $toolchain_download_path -C $toolchain_install_path
      echo '{{ BOLD + MAGENTA }} Installed toolchain! {{ NORMAL }}'
    else
      echo '{{ style('error') }}"Toolchain already installed at $toolchain_install_path. If you want to reinstall the toolchain, delete or move the toolchain folder to {{ toolchain_base_dir }}"{{ NORMAL }}'
    fi

    jq {{ master_toolchain_has_query }}

toolchain_custom:
    {{ nrfutil }} config package-index remove {{ package_index_config }}
    {{ nrfutil }} config package-index add {{ package_index_config }} {{ package_index_url }}
    {{ nrfutil }} install --force --package-index-name {{ package_index_config }} toolchain-manager device
    {{ nrfutil }} toolchain-manager config --set toolchain-index="{{ toolchain_index_url }}"
