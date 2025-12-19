#######################
# Direnv Extensions
#
# Primarily to workout direnv limitations:
# - DIRENV_* vars are always included in the export
# - layout related vars are included as well
# - Path modifications are included
# - There is not an intuitive way to export a specific env file as json
#
# The logic here requires RENDER_DIRENV logic in the top-level .envrc
#
#######################

jq_script := '''
with_entries(
	select((
		(.key | startswith("DIRENV_") | not)
		and (.key | IN("VIRTUAL_ENV", "VENV_ACTIVE", "UV_ACTIVE", "PATH", "OP_SERVICE_ACCOUNT_TOKEN") | not)
	))
) | to_entries[] | "\(.key)=\(.value | @sh)"
'''

# TODO report this upstream to direnv, this is an insane workaround :/

# target a specific .env file (supports direnv features!) for export as a JSON blob
@_export target="":
    ([ ! -n "{{ target }}" ] || [ -f "{{ target }}" ]) || (echo "{{ target }} does not exist"; exit 1)
    [ "{{ target }}" != ".envrc" ] || (echo "You cannot use .envrc as a target"; exit 1)

    # without a clear env (env -i), any variables set in your shell (via ~/.exports or similar) will *not* be included
    # in `direnv export`. I originally discovered this because PYTHON* vars were not being exported because they were set
    # globally. To work around this we clear the environment, outside of the PATH + HOME required for direnv configuration.
    # OP_SERVICE_ACCOUNT_TOKEN is also included since on CI this is effectively global state that enables 1p access.
    # When run on your local machine, 1p global state may be persisted elsewhere, so this would be a noop.
    env -i HOME="$HOME" PATH="$PATH" OP_SERVICE_ACCOUNT_TOKEN="${OP_SERVICE_ACCOUNT_TOKEN:-}" op daemon -d
    # OP_* variables are passed through to avoid having to hardcode the account token or vault uid
    # depending on your secret setup, you may want to use a different approach
    env -i HOME="$HOME" PATH="$PATH" \
    	OP_SERVICE_ACCOUNT_TOKEN="${OP_SERVICE_ACCOUNT_TOKEN:-}" OP_VAULT_UID="${OP_VAULT_UID:-}" \
    	RENDER_DIRENV="{{ target }}" \
    	direnv export json | jq -r '{{ jq_script }}'

    # TODO the `op daemon -d` hack above is to workaround a op bug:
    # https://1password-devs.slack.com/archives/C03NJV34SSC/p1733771530356779
    # https://github.com/direnv/direnv/issues/662

# JSON dump of the test environment secrets, used for local pytest runs (direnv.py for more details)

[doc("Export as docker '-e' params: --params\nExport as shell: --shell\nExport as dokku: --dokku")]
@export_docker target *flag:
    # NOTE @sh below does NOT handle newlines, tabs, etc in ANSI-C format like direnv does
    #      https://github.com/iloveitaly/direnv/blob/1a39d968c165fddff3b9a4c5538025d71f73ee43/internal/cmd/shell_bash.go#L97
    #      this could cause issues for us, although it seems as though @sh just includes the literal newline or tab char
    # 		 instead of the escaped version, which is most likely fine.
    # dokku wants all environment variables on a single line, which is why we join them with a space

    if {{ if flag == "--params" { "true" } else { "false" } }}; then; \
    	just direnv_export "{{ target }}" | jq -r 'to_entries | map("-e \(.key)=\(.value)") | join(" ")'; \
    elif {{ if flag == "--shell" { "true" } else { "false" } }}; then; \
    	just direnv_export "{{ target }}" | jq -r 'to_entries[] | "export \(.key)=\(.value | @sh)"'; \
    else; \
    	just direnv_export "{{ target }}" | jq -r 'to_entries[] | "\(.key)=\(.value)"'; \
    fi

    # last case is exporting as a docker file (i.e. no export)
    # TODO note this is not currently in use, so we'll probably have to tweak it in the future

[no-cd]
export envrc_path save_dotenv='':
    {{ if envrc_path != invocation_dir() { "cd " + envrc_path + ";" } else { "" } }} direnv exec / direnv export json | jq -r '{{ jq_script }}' {{ if path_exists(save_dotenv) == "true" { ">> " + save_dotenv / ".env" } else { "" } }}

# export direnv variables as a bash script to avoid using direnv and mutating your environment configuration
[no-cd]
[script]
dotenv_export envrc_dir=invocation_dir() target_loc=(invocation_dir() / "envs"):
    {{ if path_exists(target_loc) != "true" { shell('mkdir "$1"', target_loc) } else if path_exists(target_loc / ".env") == "true" { shell('rm "$1"', target_loc / ".env") } else { "" } }}

    just -g direnv::export {{ envrc_dir }} {{ target_loc }}
    echo "File generated:" {{ target_loc / ".env" }}
