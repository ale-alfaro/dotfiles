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

ncs_base_dir := home_dir() / 'ncs' / 'sdk'
toolchain_base_dir := ncs_base_dir / 'toolchains'
ncs_download_dir := ncs_base_dir / 'downloads'
version := 'v3.0.2'
toolchain_tarball := ncs_download_dir / f'{{toolchain_pkg_prefix}}-v{{version}}.tar.gz'
toolchain_dst_dir := toolchain_base_dir / f'v{{version}}'
jq_query := f'.[] | select(has("key")) | select(.key|test("v\\d.\\d.\\d$")) | {version:.key[1:], hash: .metadata.version} | select(.version == "{{version}}").hash'

toolchain_download:
    {{ if path_exists(toolchain_tarball) == 'true' { f'echo  {{BOLD}}"Toolchain already downloaded at {{toolchain_tarball}}"{{NORMAL}}' } else { 'wget ' + shell(f"curl -s {{toolchain_index_url}} | jq -r '{{jq_query}}'") + ' -O ' + toolchain_tarball } }}

[arg('ver', pattern='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?(?:\+(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?$')]
toolchain_install ver:
    if [[ ! -f {{ ncs_download_dir / f'{{toolchain_pkg_prefix}}-v{{ver}}.tar.gz' }} ]]; then \
      curl -s {{ toolchain_index_url }} | \
        jq -r '.[] | select(has("key")) | select(.key|test("v\\d.\\d.\\d$")) | {version:.key[1:], hash: .metadata.version} | select(.version == "{{ ver }}").hash' | \
        xargs -I '{}' wget "{{ toolchain_base_url / toolchain_pkg_prefix }}-{}.tar.gz" -O {{ ncs_download_dir / f'{{toolchain_pkg_prefix}}-v{{ver}}.tar.gz' }}; \
    fi
    if [[ ! -d  {{ toolchain_base_dir / f'v{{ver}}' }} ]]; then mkdir {{ toolchain_base_dir / f'v{{ver}}' }}; else echo '{{ BOLD }}"Toolchain already downloaded at {{ toolchain_base_dir }}. If you want to reinstall the toolchain, delete or move the toolchain folder v{{ ver }} in {{ toolchain_base_dir }}"{{ NORMAL }}' && exit 0; fi
    tar -xzf {{ ncs_download_dir / f'{{toolchain_pkg_prefix}}-v{{ver}}.tar.gz' }} -C {{ toolchain_base_dir / f'v{{ver}}' }}

toolchain_custom:
    {{ nrfutil }} config package-index remove {{ package_index_config }}
    {{ nrfutil }} config package-index add {{ package_index_config }} {{ package_index_url }}
    {{ nrfutil }} install --force --package-index-name {{ package_index_config }} toolchain-manager device
    {{ nrfutil }} toolchain-manager config --set toolchain-index="{{ toolchain_index_url }}"
