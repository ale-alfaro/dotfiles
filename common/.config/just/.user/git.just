git-submodule-sync:
    @git submodule update --init --recursive

git-sparse-checkout user repo subdir branch="main":
    @git clone --no-checkout https://github.com/{{ user }}/{{ repo }}.git && cd {{ repo }} 
    @git sparse-checkout init --cone
    @git sparse-checkout set {{ subdir }}
    @git checkout {{ branch }}

gh-folder-fetch repo path branch='main':
    uvx gh-folder-download --url {{ f'https://github.com/{{repo}}/tree/{{branch}}/{{path}}' }} --output tmp
    mv tmp/{{ path }} {{ file_stem(path) }}
    rm -r tmp

# STALE_DELETE := '0'
# STALE_DAYS_LIMIT := '360'
# CUTOFF_DATE := shell('date -d "$1 days ago" +%s', STALE_DAYS_LIMIT)

git-prune-stale-remotes remote="origin" count='50':
    #!/usr/bin/env bash
    set -euo pipefail

    stale_days_limit="${STALE_DAYS_LIMIT:-360}"
    stale_delete="${STALE_DELETE:-0}"

    cutoff_date="$(date -d "${stale_days_limit} days ago" +%s)"

    stale_refs="$(
      git for-each-ref "refs/remotes/{{ remote }}" \
        --exclude="refs/remotes/{{ remote }}/HEAD" \
        --exclude="refs/remotes/{{ remote }}/main" \
        --exclude="refs/remotes/{{ remote }}/develop" \
        --format='%(refname:lstrip=3)|%(committerdate:unix)' \
        --sort='committerdate' \
        --count={{ count }} \
        | while IFS='|' read -r branch ts; do
                    [[ "$ts" -lt "$cutoff_date" ]] && echo "$ts|$branch"
                done \
                | head -n "{{ count }}"
    )"

    if [[ -z "${stale_refs}" ]]; then
      echo "No stale branches found on {{ remote }} (>${stale_days_limit} days)."
      exit 0
    fi
    echo "Stale branches (branch | last commit date):"
    while IFS='|' read -r ts branch; do
        printf '%s | %s\n' "$(date -d "@$ts" '+%Y-%m-%d')" "$branch"
    done <<< "${stale_refs}"

    branches="$(printf '%s\n' "${stale_refs}" | cut -d'|' -f2)"

    if [[ "${stale_delete}" == "1" ]]; then
      echo "${branches}" | xargs -r -n1 git push "{{ remote }}" --delete
    else
      echo "Preview only. Set STALE_DELETE=1 to delete."
    fi
